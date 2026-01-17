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
    case partySetup
    case networkParty
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
        case .young: return "Ages 4-6 (Easiest)"
        case .medium: return "Ages 7-9 (Easy)"
        case .older: return "Ages 10-12 (Moderate)"
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
    
    var roundCount: Int {
        switch self {
        case .young: return 5      // Shorter games for younger kids
        case .medium: return 7
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

// MARK: - Bot Persona
struct BotPersona: Identifiable {
    let id: String
    let name: String
    let icon: String // Emoji
    let skillLevel: Double // 0.0 to 1.0 (0.0 = slow/simple, 1.0 = fast/complex)
    let description: String
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
    
    static let botPersonas: [BotPersona] = [
        BotPersona(id: "bear", name: "Benny Bear", icon: "🐻", skillLevel: 0.2, description: "Plays slowly and uses simple words. Great for beginners!"),
        BotPersona(id: "squirrel", name: "Sally Squirrel", icon: "🐿️", skillLevel: 0.5, description: "A quick thinker who loves medium-sized words."),
        BotPersona(id: "owl", name: "Oliver Owl", icon: "🦉", skillLevel: 0.8, description: "Very wise and finds long words quickly!")
    ]
    
    @Published var screen: KidsScreen = .home
    @Published var matchType: KidsMatchType = .online
    @Published var isConnected = false
    @Published var gameCenterError: String?  // Surface Game Center errors to UI
    
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
    
    // Rematch state
    @Published var rematchSent = false
    @Published var rematchReceived = false
    @Published var isDailyChallenge: Bool = false
    
    // Settings & Progression
    @AppStorage("kidsAgeGroup") var ageGroup: String = KidsAgeGroup.medium.rawValue
    @AppStorage("kidsSoundEnabled") var soundEnabled = true
    @AppStorage("kidsHasSeenTutorial") var hasSeenTutorial = false
    @AppStorage("kidsOnlinePlayAllowed") var onlinePlayAllowed: Bool = false
    @AppStorage("kidsUnlockedLevel") var unlockedLevel: Int = 1
    @AppStorage("kidsCollectedStickers") private var collectedStickersData: Data = Data()
    
    @Published var selectedLevel: LevelDef?
    @Published var lastEarnedSticker: String?
    @Published var selectedBotPersona: BotPersona = botPersonas[0]
    
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
    
    private var dailyChallengeManager = KidsDailyChallengeManager.shared
    private var achievementManager = KidsAchievementManager.shared
    private var socketService = KidsSocketService.shared
    private var gameCenterService = GameCenterService.shared
    private var timer: Timer?
    private var queueTimer: Timer?
    private var definitionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        dailyChallengeManager.loadTodayChallenge()
        setupSocketCallbacks()
    }
    
    deinit {
        timer?.invalidate()
        queueTimer?.invalidate()
        definitionTask?.cancel()
    }
    
    private func setupBindings() {
        // Bind connection state to Game Center auth
        gameCenterService.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] authenticated in
                self?.isConnected = authenticated
                print("🎮 GC Auth changed: \(authenticated)")
            }
            .store(in: &cancellables)
        
        // Bind errors so they surface to UI
        gameCenterService.$error
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                if let error = error {
                    print("🎮❌ GC Error: \(error)")
                    self?.gameCenterError = error
                }
            }
            .store(in: &cancellables)
        
        // Bind match state for debugging
        gameCenterService.$matchState
            .receive(on: RunLoop.main)
            .sink { state in
                print("🎮 GC MatchState: \(state.rawValue)")
                if state == .playing {
                    Task { @MainActor in
                        self.rematchSent = false
                        self.rematchReceived = false
                    }
                }
            }
            .store(in: &cancellables)
            
        gameCenterService.$isRematchRequested
            .receive(on: RunLoop.main)
            .assign(to: &$rematchSent)
            
        gameCenterService.$opponentRematchRequested
            .receive(on: RunLoop.main)
            .assign(to: &$rematchReceived)
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
                // Guard against cancellation for each async operation
                if let def = await KidsDictionaryService.shared.fetchDefinition(for: myWord, ageGroup: self.selectedAgeGroup) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self.myWordDefinition = def.definition }
                }
                if let def = await KidsDictionaryService.shared.fetchDefinition(for: oppWord, ageGroup: self.selectedAgeGroup) {
                    guard !Task.isCancelled else { return }
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
        // Authenticate only if a parent allowed online play; otherwise remain offline-ready.
        if onlinePlayAllowed {
            gameCenterService.authenticate()
        }
    }
    
    // MARK: - Game Actions
    
    func startOnlineMatch() {
        guard onlinePlayAllowed else {
            screen = .settings
            return
        }
        matchType = .online
        queueTime = 0
        screen = .queued
        gameCenterError = nil
        
        // Setup Game Center callbacks FIRST
        setupGameCenterCallbacks()
        
        // Configure match settings based on age group
        gameCenterService.configuredLetterCount = selectedAgeGroup.letterCount
        gameCenterService.configuredTotalRounds = selectedAgeGroup.roundCount
        totalRounds = selectedAgeGroup.roundCount
        
        // Start the matchmaking process
        attemptMatchmaking(retryCount: 0)
        
        // Queue timer for UI
        queueTimer?.invalidate()
        queueTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.queueTime += 1
            }
        }
    }
    
    /// Attempts to start matchmaking with exponential backoff for auth
    private func attemptMatchmaking(retryCount: Int) {
        // If already authenticated, start matchmaking immediately
        if gameCenterService.isAuthenticated {
            print("🎮 Game Center authenticated, finding match...")
            gameCenterService.findMatch()
            return
        }
        
        // Trigger authentication if not already in progress
        if gameCenterService.matchState != .authenticating {
            gameCenterService.authenticate()
        }
        
        // Maximum 5 retries (0.5s + 1s + 1.5s + 2s + 2.5s = 7.5s total wait)
        let maxRetries = 5
        
        if retryCount >= maxRetries {
            // Auth failed after multiple attempts
            print("🎮 Game Center auth failed after \(retryCount) attempts")
            gameCenterError = "Couldn't sign in to Game Center. Please check Settings > Game Center."
            queueTimer?.invalidate()
            screen = .home
            return
        }
        
        // Exponential backoff: 0.5s, 1.0s, 1.5s, 2.0s, 2.5s
        let delay = 0.5 + (Double(retryCount) * 0.5)
        print("🎮 Waiting \(delay)s for Game Center auth (attempt \(retryCount + 1)/\(maxRetries))...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            // Check if user cancelled (went back to home)
            guard self.screen == .queued else {
                print("🎮 User cancelled matchmaking")
                return
            }
            
            if self.gameCenterService.isAuthenticated {
                print("🎮 Game Center authenticated on attempt \(retryCount + 1), finding match...")
                self.gameCenterService.findMatch()
            } else {
                // Retry
                self.attemptMatchmaking(retryCount: retryCount + 1)
            }
        }
    }
    
    private func setupGameCenterCallbacks() {
        gameCenterService.onMatchFound = { [weak self] in
            guard let self = self else { return }
            print("🎮 Match Found callback triggered")
            // self.queueTimer?.invalidate() // Don't invalidate yet to avoid UI freeze
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
            
            // Fetch definitions for both words
            self.myWordDefinition = nil
            self.oppWordDefinition = nil
            self.definitionTask?.cancel()
            self.definitionTask = Task {
                // Guard against cancellation for each async operation
                if let def = await KidsDictionaryService.shared.fetchDefinition(for: result.yourWord, ageGroup: self.selectedAgeGroup) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self.myWordDefinition = def.definition }
                }
                if let def = await KidsDictionaryService.shared.fetchDefinition(for: result.oppWord, ageGroup: self.selectedAgeGroup) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self.oppWordDefinition = def.definition }
                }
            }
            
            self.screen = .result
        }
        
        gameCenterService.onMatchEnd = { [weak self] winner in
            guard let self = self else { return }
            self.matchWinner = winner
            self.screen = .matchResult
        }
    }
    
    func startBotMatch(persona: BotPersona? = nil) {
        matchType = .bot
        if let persona = persona {
            selectedBotPersona = persona
        }
        letters = generateLetters()
        currentWord = ""
        selectedIndices = []
        hasSubmitted = false
        opponentSubmitted = false
        timeRemaining = selectedAgeGroup.timerSeconds
        currentRound = 1
        totalRounds = selectedAgeGroup.roundCount  // Age-based round count
        myScore = 0
        oppScore = 0
        opponentName = selectedBotPersona.name
        
        // Achievement check
        if selectedBotPersona.id == "bear" {
            achievementManager.checkAchievement(.bearBuddy, in: self)
        }
        
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
        GameCenterService.shared.cancelMatchmaking()  // Stop Game Center matchmaking
        socketService.leave()
        rematchSent = false
        rematchReceived = false
        screen = .home
    }
    
    func requestRematch() {
        gameCenterService.requestRematch()
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
        
        // Track for achievements
        if collectedStickers.isEmpty {
            achievementManager.checkAchievement(.firstWord, in: self)
        }
        
        if currentWord.count >= 5 {
            achievementManager.checkAchievement(.longWord, in: self)
        }
        
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
        GameCenterService.shared.cancelMatchmaking()  // Stop any active matchmaking
        socketService.leave()
        screen = .home
    }
    
    func goToMap() {
        timer?.invalidate()
        queueTimer?.invalidate()
        GameCenterService.shared.cancelMatchmaking()  // Stop any active matchmaking
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
        
        // Bot plays a reasonable word based on persona
        // Use dictionary to find a word that can be made from available letters
        if let botWord = KidsWordFilter.shared.getPossibleWord(from: letters, for: selectedAgeGroup, skillLevel: selectedBotPersona.skillLevel) {
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
            // Guard against cancellation for each async operation
            if let def = await KidsDictionaryService.shared.fetchDefinition(for: self.lastWord, ageGroup: self.selectedAgeGroup) {
                guard !Task.isCancelled else { return }
                await MainActor.run { self.myWordDefinition = def.definition }
            }
            if let def = await KidsDictionaryService.shared.fetchDefinition(for: self.oppWord, ageGroup: self.selectedAgeGroup) {
                guard !Task.isCancelled else { return }
                await MainActor.run { self.oppWordDefinition = def.definition }
            }
        }
        
        screen = .result
        
        // Auto-complete daily if any word is found in a daily match
        if isDailyChallenge && lastWordScore > 0 {
            completeDailyChallenge()
        }
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
    
    func addSticker(_ sticker: String) {
        var current = collectedStickers
        if !current.contains(sticker) {
            current.append(sticker)
            collectedStickers = current
            lastEarnedSticker = sticker
            
            // Auto-clear after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if self?.lastEarnedSticker == sticker {
                    self?.lastEarnedSticker = nil
                }
            }
        }
    }
    
    // MARK: - Daily Challenge
    
    var todayDailyChallenge: DailyChallenge? {
        dailyChallengeManager.todayChallenge
    }
    
    var hasCompletedDaily: Bool {
        dailyChallengeManager.hasCompletedToday
    }
    
    func startDailyChallenge() {
        guard let challenge = todayDailyChallenge else { return }
        matchType = .bot // Daily is local
        isDailyChallenge = true
        
        // Setup daily letters from challenge
        letters = challenge.letters
        currentWord = ""
        selectedIndices = []
        hasSubmitted = false
        opponentSubmitted = false
        timeRemaining = selectedAgeGroup.timerSeconds
        currentRound = 1
        myScore = 0
        oppScore = 0
        opponentName = "Daily Goal"
        
        screen = .playing
        startTimer()
    }
    
    func completeDailyChallenge() {
        dailyChallengeManager.submitCompletion()
        achievementManager.checkAchievement(.dailyComplete, in: self)
    }
}
