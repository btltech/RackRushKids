import SwiftUI
import Combine

// MARK: - Game Screen
enum KidsScreen {
    case home
    case map
    case queued
    case playing
    case result
    case matchResult
    case settings
    case stickers
}

// MARK: - Match Type
enum KidsMatchType {
    case online
    case bot
}

// MARK: - Age Group
enum KidsAgeGroup: String, CaseIterable, Codable {
    case young = "4-6"
    case medium = "7-9"
    case older = "10-12"
    
    var displayName: String {
        switch self {
        case .young: return "Ages 4-6"
        case .medium: return "Ages 7-9"
        case .older: return "Ages 10-12"
        }
    }
    
    var timerSeconds: Int {
        return 30  // 30 seconds for all age groups
    }
    
    var letterCount: Int {
        switch self {
        case .young: return 5
        case .medium: return 6
        case .older: return 7
        }
    }
}

// MARK: - Level Definition
struct LevelDef: Identifiable, Codable {
    let id: Int
    let name: String
    let ageGroup: KidsAgeGroup
    let stickerReward: String
    let islandIcon: String // systemName
}

// MARK: - Kids Game State
@MainActor
class KidsGameState: ObservableObject {
    static let levels: [LevelDef] = [
        LevelDef(id: 1, name: "Apple Bay", ageGroup: .young, stickerReward: "🍎", islandIcon: "leaf.fill"),
        LevelDef(id: 2, name: "Bee Beach", ageGroup: .young, stickerReward: "🐝", islandIcon: "sun.max.fill"),
        LevelDef(id: 3, name: "Cat Cove", ageGroup: .young, stickerReward: "🐱", islandIcon: "water.waves"),
        LevelDef(id: 4, name: "Dino Dunes", ageGroup: .medium, stickerReward: "🦖", islandIcon: "mountain.2.fill"),
        LevelDef(id: 5, name: "Eagle Edge", ageGroup: .medium, stickerReward: "🦅", islandIcon: "cloud.fill"),
        LevelDef(id: 6, name: "Frog Forest", ageGroup: .medium, stickerReward: "🐸", islandIcon: "tree.fill"),
        LevelDef(id: 7, name: "Galaxy Gulf", ageGroup: .older, stickerReward: "🚀", islandIcon: "sparkles"),
        LevelDef(id: 8, name: "Hippos Hills", ageGroup: .older, stickerReward: "🦛", islandIcon: "cloud.rain.fill"),
        LevelDef(id: 9, name: "Icy Island", ageGroup: .older, stickerReward: "❄️", islandIcon: "snowflake")
    ]
    
    @Published var screen: KidsScreen = .home
    @Published var matchType: KidsMatchType = .online
    @Published var isConnected = false
    
    // Queue state
    @Published var queueTime = 0
    
    // Game state
    @Published var letters: [String] = []
    @Published var currentWord = ""
    @Published var selectedIndices: [Int] = []  // Ordered for word building
    @Published var timeRemaining = 45
    @Published var hasSubmitted = false
    @Published var opponentSubmitted = false
    
    // Round info
    @Published var currentRound = 1
    @Published var totalRounds = 7
    @Published var myScore = 0
    @Published var oppScore = 0
    @Published var opponentName = "Opponent"
    
    // Result
    @Published var lastWord = ""
    @Published var lastWordScore = 0
    @Published var oppWord = ""
    @Published var oppWordScore = 0
    @Published var roundWinner = ""
    @Published var matchWinner = ""
    @Published var encouragement = ""
    @Published var myWordDefinition: String?
    @Published var oppWordDefinition: String?
    
    // Rejection
    @Published var wordRejected = false
    @Published var rejectionMessage = ""
    
    // Settings & Progression
    @AppStorage("kidsAgeGroup") var ageGroup: String = KidsAgeGroup.medium.rawValue
    @AppStorage("kidsSoundEnabled") var soundEnabled = true
    @AppStorage("kidsHasSeenTutorial") var hasSeenTutorial = false
    @AppStorage("kidsUnlockedLevel") var unlockedLevel: Int = 1
    @AppStorage("kidsCollectedStickers") private var collectedStickersData: Data = Data()
    
    @Published var selectedLevel: LevelDef?
    @Published var lastEarnedSticker: String?
    
    var collectedStickers: [String] {
        get {
            guard !collectedStickersData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([String].self, from: collectedStickersData)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                collectedStickersData = data
            }
        }
    }
    
    var selectedAgeGroup: KidsAgeGroup {
        KidsAgeGroup(rawValue: ageGroup) ?? .medium
    }
    
    private var socketService = KidsSocketService.shared
    private var gameCenterService = GameCenterService.shared
    private var timer: Timer?
    private var queueTimer: Timer?
    private var definitionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupGameCenterBinding()
        setupSocketCallbacks()
    }
    
    deinit {
        timer?.invalidate()
        queueTimer?.invalidate()
        definitionTask?.cancel()
    }
    
    private func setupGameCenterBinding() {
        // Bind connection state to Game Center auth
        gameCenterService.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] authenticated in
                self?.isConnected = authenticated
            }
            .store(in: &cancellables)
            
        // Trigger auth
        gameCenterService.authenticate()
    }

    private func setupSocketCallbacks() {
        // Socket callbacks no longer control isConnected for Game Center mode
        /*
        socketService.onConnect = { [weak self] in
            self?.isConnected = true
        }
        
        socketService.onDisconnect = { [weak self] in
            self?.isConnected = false
        }
        */
        
        socketService.onMatchFound = { [weak self] roomId, opponent, letters in
            guard let self = self else { return }
            self.queueTimer?.invalidate()
            self.opponentName = opponent
            self.letters = letters.isEmpty ? self.generateLetters() : letters
            self.timeRemaining = self.selectedAgeGroup.timerSeconds
            self.currentRound = 1
            self.myScore = 0
            self.oppScore = 0
            self.screen = .playing
            self.startTimer()
        }
        
        socketService.onRoundStart = { [weak self] round, letters, timer in
            guard let self = self else { return }
            self.currentRound = round
            self.letters = letters.isEmpty ? self.generateLetters() : letters
            self.timeRemaining = timer
            self.currentWord = ""
            self.selectedIndices = []
            self.hasSubmitted = false
            self.opponentSubmitted = false
            self.screen = .playing
            self.startTimer()
        }
        
        socketService.onOpponentSubmitted = { [weak self] in
            self?.opponentSubmitted = true
        }
        
        socketService.onRoundResult = { [weak self] myWord, myScoreVal, oppWord, oppScoreVal, winner in
            guard let self = self else { return }
            self.timer?.invalidate()
            self.lastWord = myWord
            self.lastWordScore = myScoreVal
            self.oppWord = oppWord
            self.oppWordScore = oppScoreVal
            self.roundWinner = winner
            
            if winner == "you" || winner == "me" {
                self.myScore += 1
                self.encouragement = KidsTheme.randomEncouragement()
            } else if winner == "opp" || winner == "opponent" {
                self.oppScore += 1
                self.encouragement = "Good effort! Keep going! 💪"
            } else {
                self.encouragement = "It's a tie! ⭐"
            }
            
            self.myWordDefinition = nil
            self.oppWordDefinition = nil
            
            // Cancel previous task and start new one
            self.definitionTask?.cancel()
            self.definitionTask = Task {
                if let def = await KidsDictionaryService.shared.fetchDefinition(for: myWord) {
                    await MainActor.run { self.myWordDefinition = def.definition }
                }
                if let def = await KidsDictionaryService.shared.fetchDefinition(for: oppWord) {
                    await MainActor.run { self.oppWordDefinition = def.definition }
                }
            }
            
            self.screen = .result
        }
        
        socketService.onMatchEnd = { [weak self] myTotal, oppTotal, winner in
            guard let self = self else { return }
            self.myScore = myTotal
            self.oppScore = oppTotal
            self.matchWinner = winner
            self.screen = .matchResult
        }
        
        socketService.onOpponentLeft = { [weak self] in
            self?.handleOpponentLeft()
        }
    }
    
    func connect() {
        // Connection state is bound to Game Center auth in setupGameCenterBinding()
        // No socket connection needed - Game Center handles it all
        // isConnected automatically updates when Game Center authenticates
    }
    
    // MARK: - Game Actions
    
    func startOnlineMatch() {
        matchType = .online
        queueTime = 0
        screen = .queued
        
        // Setup Game Center callbacks
        setupGameCenterCallbacks()
        
        // Authenticate if needed
        if !gameCenterService.isAuthenticated {
            gameCenterService.authenticate()
        }
        
        // Start matchmaking after short delay for auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.gameCenterService.isAuthenticated {
                self.gameCenterService.findMatch()
            } else {
                // Wait more for auth
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if self.gameCenterService.isAuthenticated {
                        self.gameCenterService.findMatch()
                    } else {
                        // Auth failed - go back home
                        self.screen = .home
                    }
                }
            }
        }
        
        // Queue timer
        queueTimer?.invalidate()
        queueTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.queueTime += 1
            }
        }
    }
    
    private func setupGameCenterCallbacks() {
        gameCenterService.onMatchFound = { [weak self] in
            guard let self = self else { return }
            self.queueTimer?.invalidate()
            self.opponentName = self.gameCenterService.opponentName
            self.isConnected = true
        }
        
        gameCenterService.onRoundStart = { [weak self] in
            guard let self = self else { return }
            let gc = self.gameCenterService
            self.letters = gc.letters
            self.currentWord = ""
            self.selectedIndices = []
            self.hasSubmitted = false
            self.opponentSubmitted = false
            self.currentRound = gc.currentRound
            self.timeRemaining = self.selectedAgeGroup.timerSeconds
            self.screen = .playing
            self.startTimer()
        }
        
        gameCenterService.onOpponentSubmitted = { [weak self] in
            self?.opponentSubmitted = true
        }
        
        gameCenterService.onRoundEnd = { [weak self] result in
            guard let self = self else { return }
            self.timer?.invalidate()
            self.lastWord = result.yourWord
            self.lastWordScore = result.yourScore
            self.oppWord = result.oppWord
            self.oppWordScore = result.oppScore
            self.myScore = result.yourTotalScore
            self.oppScore = result.oppTotalScore
            self.roundWinner = result.winner
            self.encouragement = result.winner == "you" ? "Great job! 🌟" : (result.winner == "tie" ? "It's a tie! ⭐" : "Keep trying! 💪")
            self.screen = .result
        }
        
        gameCenterService.onMatchEnd = { [weak self] winner in
            guard let self = self else { return }
            self.matchWinner = winner
            self.screen = .matchResult
        }
    }
    
    func startBotMatch() {
        matchType = .bot
        letters = generateLetters()
        currentWord = ""
        selectedIndices = []
        hasSubmitted = false
        opponentSubmitted = false
        timeRemaining = selectedAgeGroup.timerSeconds
        currentRound = 1
        myScore = 0
        oppScore = 0
        opponentName = generateBotName()
        screen = .playing
        startTimer()
    }
    
    func startLevel(_ level: LevelDef) {
        selectedLevel = level
        ageGroup = level.ageGroup.rawValue
        startBotMatch()
    }
    
    func cancelQueue() {
        queueTimer?.invalidate()
        socketService.leave()
        screen = .home
    }
    
    func selectLetter(at index: Int) {
        guard !hasSubmitted else { return }
        guard index >= 0 && index < letters.count else { return }  // K10 Fix: Bounds check
        
        if let existingIndex = selectedIndices.firstIndex(of: index) {
            // Deselect - remove from position and all after
            selectedIndices.removeSubrange(existingIndex...)
            currentWord = selectedIndices.compactMap { idx in
                idx < letters.count ? letters[idx] : nil
            }.joined()
        } else {
            // Select
            selectedIndices.append(index)
            currentWord = selectedIndices.compactMap { idx in
                idx < letters.count ? letters[idx] : nil
            }.joined()
        }
    }
    
    func clearWord() {
        currentWord = ""
        selectedIndices = []
    }
    
    func submitWord() {
        guard currentWord.count >= 2, !hasSubmitted else { return }
        
        // Check word filter
        let filter = KidsWordFilter.shared
        if !filter.isAppropriate(currentWord, forAge: selectedAgeGroup) {
            wordRejected = true
            rejectionMessage = filter.rejectionMessage(for: selectedAgeGroup)
            clearWord()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.wordRejected = false
            }
            return
        }
        
        hasSubmitted = true
        
        if matchType == .online {
            // Use Game Center for online matches
            gameCenterService.submitWord(currentWord)
        } else {
            // Bot match - simulate result
            simulateBotResult()
        }
    }
    
    func nextRound() {
        if currentRound >= totalRounds {
            checkMatchEnd()
            return
        }
        
        if matchType == .bot {
            currentRound += 1
            letters = generateLetters()
            currentWord = ""
            selectedIndices = []
            hasSubmitted = false
            opponentSubmitted = false
            timeRemaining = selectedAgeGroup.timerSeconds
            screen = .playing
            startTimer()
        }
        // Online next round is handled by server
    }
    
    func goHome() {
        timer?.invalidate()
        queueTimer?.invalidate()
        socketService.leave()
        screen = .home
    }
    
    func goToMap() {
        timer?.invalidate()
        queueTimer?.invalidate()
        socketService.leave()
        screen = .map
    }
    
    // MARK: - Private
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.invalidate()
                    if !self.hasSubmitted {
                        self.submitWord()
                    }
                }
            }
        }
    }
    
    private func simulateBotResult() {
        timer?.invalidate()
        
        lastWord = currentWord
        lastWordScore = calculateScore(word: currentWord)
        
        // Bot plays a reasonable word based on age group
        // Use dictionary to find a word that can be made from available letters
        if let botWord = KidsWordFilter.shared.getPossibleWord(from: letters, for: selectedAgeGroup) {
            oppWord = botWord.uppercased()
        } else {
            oppWord = ""
        }
        oppWordScore = calculateScore(word: oppWord)
        
        if lastWordScore > oppWordScore {
            roundWinner = "you"
            myScore += 1
            encouragement = KidsTheme.randomEncouragement()
        } else if lastWordScore < oppWordScore {
            roundWinner = "opp"
            oppScore += 1
            encouragement = "Good effort! Keep going! 💪"
        } else {
            roundWinner = "tie"
            self.encouragement = "It's a tie! ⭐"
        }
        
        self.myWordDefinition = nil
        self.oppWordDefinition = nil
        
        // Cancel previous task and start new one
        definitionTask?.cancel()
        definitionTask = Task {
            if let def = await KidsDictionaryService.shared.fetchDefinition(for: self.lastWord) {
                await MainActor.run { self.myWordDefinition = def.definition }
            }
            if let def = await KidsDictionaryService.shared.fetchDefinition(for: self.oppWord) {
                await MainActor.run { self.oppWordDefinition = def.definition }
            }
        }
        
        screen = .result
    }
    
    private func checkMatchEnd() {
        if myScore > oppScore {
            matchWinner = "you"
            handleVictory()
        } else if oppScore > myScore {
            matchWinner = "opp"
        } else {
            matchWinner = "tie"
        }
        screen = .matchResult
    }
    
    private func handleVictory() {
        lastEarnedSticker = nil
        
        // Unlock next level if this was the current unlocked level
        if let current = selectedLevel, current.id == unlockedLevel {
            unlockedLevel += 1
            
            // Add sticker if not already earned
            if !collectedStickers.contains(current.stickerReward) {
                var stickers = collectedStickers
                stickers.append(current.stickerReward)
                collectedStickers = stickers
                lastEarnedSticker = current.stickerReward
            }
        }
    }
    
    private func calculateScore(word: String) -> Int {
        guard !word.isEmpty else { return 0 }
        
        // Validate word is real using LocalDictionary
        let validation = LocalDictionary.shared.validate(word, rack: letters)
        if !validation.valid {
            return 0  // Invalid word gets 0 points
        }
        
        // Use LocalScorer for consistent scoring with main app
        return LocalScorer.shared.calculate(word: word, rack: letters, bonuses: [])
    }
    
    private func handleOpponentLeft() {
        timer?.invalidate()
        matchWinner = "you"
        screen = .matchResult
    }
    
    private func generateLetters() -> [String] {
        let vowels = ["A", "E", "I", "O", "U"]
        let consonants = ["B", "C", "D", "F", "G", "H", "L", "M", "N", "P", "R", "S", "T", "W"]
        
        var result: [String] = []
        let count = selectedAgeGroup.letterCount
        
        let vowelCount = Int.random(in: 2...3)
        for _ in 0..<vowelCount {
            result.append(vowels.randomElement()!)
        }
        
        while result.count < count {
            result.append(consonants.randomElement()!)
        }
        
        return result.shuffled()
    }
    
    private func generateBotName() -> String {
        let names = ["Alex", "Sam", "Jordan", "Taylor", "Casey", "Morgan", "Riley", "Quinn"]
        return names.randomElement() ?? "Alex"
    }
}
