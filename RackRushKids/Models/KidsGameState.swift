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

// MARK: - Learning Tip
struct KidsTip {
    let word: String
    let score: Int
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

    func effectiveLetterCount(extraChallengeEnabled: Bool) -> Int {
        guard extraChallengeEnabled else { return letterCount }
        // Keep the youngest group stable; add +1 for older groups only.
        guard self != .young else { return letterCount }
        return letterCount + 1
    }
    
    var roundCount: Int {
        switch self {
        case .young: return 5      // Shorter games for younger kids
        case .medium: return 7
        case .older: return 7
        }
    }
    
    var minWordLength: Int {
        switch self {
        case .young: return 2
        case .medium: return 3
        case .older: return 4
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
    /// Special Master Sticker awarded when all 30 island stickers are collected
    static let masterSticker = "🏆"
    static let totalIslandStickers = 30
    
    static let levels: [LevelDef] = [
        // Young (4-6) - Simple, friendly themes
        LevelDef(id: 1, name: "Apple Bay", ageGroup: .young, stickerReward: "🍎", islandIcon: "leaf.fill"),
        LevelDef(id: 2, name: "Bee Beach", ageGroup: .young, stickerReward: "🐝", islandIcon: "sun.max.fill"),
        LevelDef(id: 3, name: "Cat Cove", ageGroup: .young, stickerReward: "🐱", islandIcon: "water.waves"),
        LevelDef(id: 4, name: "Duck Dock", ageGroup: .young, stickerReward: "🦆", islandIcon: "drop.fill"),
        LevelDef(id: 5, name: "Egg Isle", ageGroup: .young, stickerReward: "🥚", islandIcon: "circle.fill"),
        LevelDef(id: 6, name: "Fish Falls", ageGroup: .young, stickerReward: "🐟", islandIcon: "water.waves"),
        LevelDef(id: 7, name: "Goat Glen", ageGroup: .young, stickerReward: "🐐", islandIcon: "mountain.2.fill"),
        LevelDef(id: 8, name: "Hippo Harbor", ageGroup: .young, stickerReward: "🦛", islandIcon: "drop.fill"),
        LevelDef(id: 9, name: "Ice Island", ageGroup: .young, stickerReward: "🧊", islandIcon: "snowflake"),
        LevelDef(id: 10, name: "Jam Jungle", ageGroup: .young, stickerReward: "🍓", islandIcon: "tree.fill"),
        
        // Medium (7-9) - Adventure themes
        LevelDef(id: 11, name: "Kite Kingdom", ageGroup: .medium, stickerReward: "🪁", islandIcon: "wind"),
        LevelDef(id: 12, name: "Lion Lagoon", ageGroup: .medium, stickerReward: "🦁", islandIcon: "sun.max.fill"),
        LevelDef(id: 13, name: "Monkey Mountain", ageGroup: .medium, stickerReward: "🐵", islandIcon: "mountain.2.fill"),
        LevelDef(id: 14, name: "Narwhal Nook", ageGroup: .medium, stickerReward: "🦄", islandIcon: "water.waves"),
        LevelDef(id: 15, name: "Owl Outpost", ageGroup: .medium, stickerReward: "🦉", islandIcon: "moon.fill"),
        LevelDef(id: 16, name: "Penguin Peak", ageGroup: .medium, stickerReward: "🐧", islandIcon: "snowflake"),
        LevelDef(id: 17, name: "Quail Quarry", ageGroup: .medium, stickerReward: "🐦", islandIcon: "cloud.fill"),
        LevelDef(id: 18, name: "Rainbow Ridge", ageGroup: .medium, stickerReward: "🌈", islandIcon: "rainbow"),
        LevelDef(id: 19, name: "Snake Springs", ageGroup: .medium, stickerReward: "🐍", islandIcon: "drop.fill"),
        LevelDef(id: 20, name: "Tiger Town", ageGroup: .medium, stickerReward: "🐯", islandIcon: "leaf.fill"),
        
        // Older (10-12) - Epic/space/mystery themes
        LevelDef(id: 21, name: "Unicorn Universe", ageGroup: .older, stickerReward: "🦄", islandIcon: "sparkles"),
        LevelDef(id: 22, name: "Volcano Valley", ageGroup: .older, stickerReward: "🌋", islandIcon: "flame.fill"),
        LevelDef(id: 23, name: "Wizard Woods", ageGroup: .older, stickerReward: "🧙", islandIcon: "wand.and.stars"),
        LevelDef(id: 24, name: "X-Ray Xanadu", ageGroup: .older, stickerReward: "🔬", islandIcon: "magnifyingglass"),
        LevelDef(id: 25, name: "Yeti Yard", ageGroup: .older, stickerReward: "🏔️", islandIcon: "snowflake"),
        LevelDef(id: 26, name: "Zombie Zone", ageGroup: .older, stickerReward: "🧟", islandIcon: "moon.fill"),
        LevelDef(id: 27, name: "Galaxy Gulf", ageGroup: .older, stickerReward: "🚀", islandIcon: "sparkles"),
        LevelDef(id: 28, name: "Asteroid Atoll", ageGroup: .older, stickerReward: "☄️", islandIcon: "circle.fill"),
        LevelDef(id: 29, name: "Nebula Nook", ageGroup: .older, stickerReward: "🌌", islandIcon: "star.fill"),
        LevelDef(id: 30, name: "Champion's Crown", ageGroup: .older, stickerReward: "👑", islandIcon: "crown.fill")
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
    @Published var timeRemaining = 30  // Matches KidsAgeGroup.timerSeconds
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
    
    // Learning Tip - shows a better word the player could have made
    @Published var learningTip: KidsTip?
    
    // Tracking for unlocks
    @Published var longestWord: String = ""  // Longest word in this match
    @Published var lastSubmitTime: TimeInterval? = nil  // Time to submit last word
    

    // Rejection
    @Published var wordRejected = false
    @Published var rejectionMessage = ""
    

    // Rematch state
    @Published var rematchSent = false
    @Published var rematchReceived = false
    @Published var isDailyChallenge: Bool = false
    
    private var backgroundTimestamp: Date?
    
    // Reconnection state
    @Published var isOpponentReconnecting: Bool = false
    @Published var reconnectionTimeRemaining: Double = 0
    
    // Pause state (bot matches only)
    @Published var isPaused = false
    
    // Settings & Progression
    @AppStorage("kidsAgeGroup") var ageGroup: String = KidsAgeGroup.medium.rawValue
    @AppStorage("kidsSoundEnabled") var soundEnabled = true
    @AppStorage("kidsHasSeenTutorial") var hasSeenTutorial = false
    @AppStorage("kidsOnlinePlayAllowed") var onlinePlayAllowed: Bool = false
    @AppStorage("kidsExtraChallengeEnabled") var extraChallengeEnabled: Bool = false
    @AppStorage("kidsUnlockedLevel_4_6") private var unlockedYoungLevelIndex: Int = 1
    @AppStorage("kidsUnlockedLevel_7_9") private var unlockedMediumLevelIndex: Int = 1
    @AppStorage("kidsUnlockedLevel_10_12") private var unlockedOlderLevelIndex: Int = 1
    @AppStorage("kidsCollectedStickers") private var collectedStickersData: Data = Data()
    @AppStorage("kidsIslandStars") private var islandStarsData: Data = Data()
    
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
    
    /// Star ratings per island (levelId -> stars 1-3)
    var islandStars: [Int: Int] {
        get {
            guard !islandStarsData.isEmpty else { return [:] }
            return (try? JSONDecoder().decode([Int: Int].self, from: islandStarsData)) ?? [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                islandStarsData = data
            }
        }
    }
    
    /// Get star count for a specific level
    func stars(for levelId: Int) -> Int {
        islandStars[levelId] ?? 0
    }
    
    /// Award stars based on performance (keeps highest)
    func awardStars(for levelId: Int, scorePercentage: Double) {
        let newStars: Int
        if scorePercentage >= IslandConfig.threeStarThreshold {
            newStars = 3
        } else if scorePercentage >= IslandConfig.twoStarThreshold {
            newStars = 2
        } else {
            newStars = 1
        }
        
        // Only update if new score is better
        let currentStars = stars(for: levelId)
        if newStars > currentStars {
            var updated = islandStars
            updated[levelId] = newStars
            islandStars = updated
        }
    }
    
    var selectedAgeGroup: KidsAgeGroup {
        KidsAgeGroup(rawValue: ageGroup) ?? .medium
    }

    private var effectiveLocalLetterCount: Int {
        selectedAgeGroup.effectiveLetterCount(extraChallengeEnabled: extraChallengeEnabled)
    }
    
    private var dailyChallengeManager = KidsDailyChallengeManager.shared
    private var achievementManager = KidsAchievementManager.shared
    private var socketService = KidsSocketService.shared
    private let enableSocketMatchmaking = true
    private var gameCenterService = GameCenterService.shared
    private enum OnlineTransport {
        case gameCenter
        case socket
    }

    private var onlineTransport: OnlineTransport = .gameCenter
    private var timer: Timer?
    private var queueTimer: Timer?
    private var definitionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        migrateUnlockedLevelIfNeeded()
        setupBindings()
        dailyChallengeManager.loadTodayChallenge()
        if enableSocketMatchmaking {
            setupSocketCallbacks()
        }
        setupLifecycleObservers()
    }

    private func migrateUnlockedLevelIfNeeded() {
        let defaults = UserDefaults.standard
        let legacyKey = "kidsUnlockedLevel"
        let legacyValue = defaults.object(forKey: legacyKey) as? Int

        guard let legacyUnlockedLevel = legacyValue else { return }

        let youngKey = "kidsUnlockedLevel_4_6"
        let mediumKey = "kidsUnlockedLevel_7_9"
        let olderKey = "kidsUnlockedLevel_10_12"

        let hasYoung = defaults.object(forKey: youngKey) != nil
        let hasMedium = defaults.object(forKey: mediumKey) != nil
        let hasOlder = defaults.object(forKey: olderKey) != nil

        guard !(hasYoung && hasMedium && hasOlder) else { return }

        // Legacy semantics: levels with id <= legacyUnlockedLevel are unlocked.
        // New semantics: each age group has its own 1-based "next level" index.
        func migratedIndex(for ageGroup: KidsAgeGroup, trackStartId: Int, trackCount: Int) -> Int {
            let unlockedCountInTrack = max(0, min(trackCount, legacyUnlockedLevel - trackStartId + 1))
            // unlockedIndex is the "next" level to highlight; allow trackCount+1 when all are unlocked.
            return max(1, unlockedCountInTrack + 1)
        }

        // Current islands are 3 per age group.
        let youngIndex = migratedIndex(for: .young, trackStartId: 1, trackCount: 3)
        let mediumIndex = migratedIndex(for: .medium, trackStartId: 4, trackCount: 3)
        let olderIndex = migratedIndex(for: .older, trackStartId: 7, trackCount: 3)

        defaults.set(youngIndex, forKey: youngKey)
        defaults.set(mediumIndex, forKey: mediumKey)
        defaults.set(olderIndex, forKey: olderKey)
        // Keep legacyKey untouched for now to avoid unexpected regressions.
    }

    func unlockedIndex(for ageGroup: KidsAgeGroup) -> Int {
        switch ageGroup {
        case .young: return unlockedYoungLevelIndex
        case .medium: return unlockedMediumLevelIndex
        case .older: return unlockedOlderLevelIndex
        }
    }

    private func setUnlockedIndex(_ newValue: Int, for ageGroup: KidsAgeGroup) {
        switch ageGroup {
        case .young: unlockedYoungLevelIndex = newValue
        case .medium: unlockedMediumLevelIndex = newValue
        case .older: unlockedOlderLevelIndex = newValue
        }
    }

    static func trackIndex(for level: LevelDef) -> Int {
        let track = levels.filter { $0.ageGroup == level.ageGroup }.sorted { $0.id < $1.id }
        return (track.firstIndex { $0.id == level.id } ?? 0) + 1
    }

    static func trackCount(for ageGroup: KidsAgeGroup) -> Int {
        levels.filter { $0.ageGroup == ageGroup }.count
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        queueTimer?.invalidate()
        definitionTask?.cancel()
    }

    private func resetTransientMatchState() {
        timer?.invalidate()
        queueTimer?.invalidate()
        definitionTask?.cancel()
        definitionTask = nil

        backgroundTimestamp = nil

        isOpponentReconnecting = false
        reconnectionTimeRemaining = 0

        rematchSent = false
        rematchReceived = false

        isDailyChallenge = false
        isPaused = false

        // Clear in-round UI state so we don't carry it into the next match.
        currentWord = ""
        selectedIndices = []
        hasSubmitted = false
        opponentSubmitted = false
        wordRejected = false
        rejectionMessage = ""
    }
    
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleAppDidEnterBackground() {
        if screen == .playing || screen == .queued {
            backgroundTimestamp = Date()
            timer?.invalidate()
            queueTimer?.invalidate()
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        guard let backgroundTime = backgroundTimestamp else { return }
        let elapsed = Int(Date().timeIntervalSince(backgroundTime))
        backgroundTimestamp = nil
        
        if screen == .queued {
            // If a parent disabled online play while we were backgrounded, stop matchmaking.
            guard onlinePlayAllowed else {
                cancelQueue()
                return
            }
            queueTime += elapsed
            // Resume queue timer without resetting matchmaking state.
            queueTimer?.invalidate()
            queueTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.queueTime += 1
                }
            }

            // If matchmaking isn't actively running, kick it off again.
            if gameCenterService.currentMatch == nil && gameCenterService.matchState != .finding {
                attemptMatchmaking(retryCount: 0)
            }
        } else if screen == .playing {
            timeRemaining = max(0, timeRemaining - elapsed)
            if timeRemaining > 0 {
                startTimer()
            } else if !hasSubmitted {
                submitWord(force: true)
            }
        }
    }
    
    private func setupBindings() {
        // Connected if either Game Center is authenticated or the socket is connected.
        gameCenterService.$isAuthenticated
            .combineLatest(socketService.$isConnected)
            .map { $0 || $1 }
            .receive(on: RunLoop.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
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

        // Enforce parental controls at runtime: turning off online play immediately
        // disconnects/cancels any online activity.
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .map { _ in UserDefaults.standard.bool(forKey: "kidsOnlinePlayAllowed") }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] allowed in
                guard let self else { return }
                guard !allowed else { return }

                // Stop any active matchmaking / online sessions.
                if self.screen == .queued {
                    self.cancelQueue()
                }
                if self.screen == .networkParty {
                    self.screen = .home
                }

                self.gameCenterService.disconnect()
                self.socketService.leave()
                self.socketService.disconnect()
            }
            .store(in: &cancellables)
    }

    private func setupSocketCallbacks() {
        socketService.onConnect = { [weak self] in
            guard let self = self else { return }
            guard self.screen == .queued else { return }
            self.socketService.joinKidsQueue(ageGroup: self.selectedAgeGroup)
        }

        socketService.onDisconnect = { [weak self] in
            guard let self = self else { return }
            // If we were actively in an online socket match, return home.
            if self.matchType == .online, self.onlineTransport == .socket {
                self.gameCenterError = "Disconnected from server."
                self.screen = .home
            }
        }

        socketService.onError = { [weak self] message in
            guard let self = self else { return }
            self.gameCenterError = message
        }
        
        socketService.onMatchFound = { [weak self] roomId, opponent in
            guard let self = self else { return }
            self.queueTimer?.invalidate()
            self.opponentName = opponent
            self.currentRound = 0
            self.totalRounds = self.selectedAgeGroup.roundCount
            self.myScore = 0
            self.oppScore = 0
            self.screen = .playing
            // Wait for roundStart to arrive with letters/timing.
        }
        
        socketService.onRoundStart = { [weak self] round, letters, secondsRemaining in
            guard let self = self else { return }
            self.currentRound = round
            // Online matches must use the configured/base letter count.
            self.letters = letters.isEmpty ? self.generateLetters(count: self.selectedAgeGroup.letterCount) : letters
            self.timeRemaining = secondsRemaining
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
        
        socketService.onRoundResult = { [weak self] myWord, myScoreVal, oppWord, oppScoreVal, winner, myTotal, oppTotal, roundNumber, totalRounds, _ in
            guard let self = self else { return }
            self.timer?.invalidate()
            self.lastWord = myWord
            self.lastWordScore = myScoreVal
            self.oppWord = oppWord
            self.oppWordScore = oppScoreVal
            self.roundWinner = winner

            self.currentRound = roundNumber
            self.totalRounds = totalRounds
            self.myScore = myTotal
            self.oppScore = oppTotal
            
            self.encouragement = {
                if winner == "you" || winner == "me" { return KidsTheme.randomEncouragement() }
                if winner == "opp" || winner == "opponent" { return "Good effort! Keep going! 💪" }
                return "It's a tie! ⭐"
            }()
            
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

        socketService.onOpponentReconnecting = { [weak self] timeLeftSeconds in
            guard let self = self else { return }
            self.isOpponentReconnecting = true
            self.reconnectionTimeRemaining = Double(timeLeftSeconds)
        }

        socketService.onOpponentReconnected = { [weak self] in
            guard let self = self else { return }
            self.isOpponentReconnecting = false
            self.reconnectionTimeRemaining = 0
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
        
        // Ensure we never carry state from a previous online match.
        resetTransientMatchState()
        gameCenterService.disconnect()
        socketService.leave()
        socketService.disconnect()
        
        matchType = .online
        onlineTransport = enableSocketMatchmaking ? .socket : .gameCenter
        queueTime = 0
        screen = .queued
        gameCenterError = nil

        if onlineTransport == .socket {
            setupSocketCallbacks()
            totalRounds = selectedAgeGroup.roundCount
            socketService.connect()
        } else {
            // Setup Game Center callbacks FIRST
            setupGameCenterCallbacks()

            // Configure match settings based on age group
            gameCenterService.configuredLetterCount = selectedAgeGroup.letterCount
            gameCenterService.configuredTotalRounds = selectedAgeGroup.roundCount
            gameCenterService.configuredMinWordLength = selectedAgeGroup.minWordLength
            totalRounds = selectedAgeGroup.roundCount

            // Start the matchmaking process
            attemptMatchmaking(retryCount: 0)
        }
        
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
            self.totalRounds = gc.configuredTotalRounds
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
            self.isOpponentReconnecting = false // Ensure overlay is hidden
        }
        
        gameCenterService.onMatchEnd = { [weak self] winner in
            guard let self = self else { return }
            self.matchWinner = winner
            self.screen = .matchResult
        }
        
        gameCenterService.onReconnectionUpdate = { [weak self] isReconnecting, timeRemaining in
            self?.isOpponentReconnecting = isReconnecting
            self?.reconnectionTimeRemaining = timeRemaining
        }
    }
    
    func startBotMatch(persona: BotPersona? = nil) {
        matchType = .bot
        if let persona = persona {
            selectedBotPersona = persona
        }
        letters = generateLetters(count: effectiveLocalLetterCount)
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
        resetTransientMatchState()
        GameCenterService.shared.cancelMatchmaking()  // Stop Game Center matchmaking
        gameCenterService.disconnect()
        socketService.leave()
        socketService.disconnect()
        gameCenterError = nil
        screen = .home
    }
    
    func requestRematch() {
        guard onlineTransport == .gameCenter else { return }
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

    func shuffleRack() {
        guard !hasSubmitted else { return }
        guard selectedIndices.isEmpty else { return }
        guard !letters.isEmpty else { return }
        letters.shuffle()
    }
    
    func submitWord(force: Bool = false) {
        let minLength: Int = {
            if matchType != .online { return selectedAgeGroup.minWordLength }
            return onlineTransport == .gameCenter ? gameCenterService.configuredMinWordLength : selectedAgeGroup.minWordLength
        }()
        guard !hasSubmitted else { return }
        if !force {
            guard currentWord.count >= minLength else { return }
        }
        
        // Check word filter
        let filter = KidsWordFilter.shared
        if !currentWord.isEmpty && !filter.isAppropriate(currentWord, forAge: selectedAgeGroup) {
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
        if !currentWord.isEmpty {
            if collectedStickers.isEmpty {
                achievementManager.checkAchievement(.firstWord, in: self)
            }

            if currentWord.count >= 5 {
                achievementManager.checkAchievement(.longWord, in: self)
            }
            
            // Track longest word in this match
            if currentWord.count > longestWord.count {
                longestWord = currentWord
            }
            
            // Track submit time for speed badges
            let submitDuration = TimeInterval(selectedAgeGroup.timerSeconds - timeRemaining)
            lastSubmitTime = submitDuration
        }
        
        if matchType == .online {
            if onlineTransport == .gameCenter {
                gameCenterService.submitWord(currentWord)
            } else {
                socketService.submitWord(currentWord)
            }
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
            letters = generateLetters(count: effectiveLocalLetterCount)
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
        resetTransientMatchState()
        GameCenterService.shared.cancelMatchmaking()  // Stop any active matchmaking
        gameCenterService.disconnect()
        socketService.leave()
        socketService.disconnect()
        gameCenterError = nil
        screen = .home
    }
    
    func goToMap() {
        resetTransientMatchState()
        GameCenterService.shared.cancelMatchmaking()  // Stop any active matchmaking
        gameCenterService.disconnect()
        socketService.leave()
        socketService.disconnect()
        gameCenterError = nil
        screen = .map
    }
    
    // MARK: - Pause/Resume (Bot Matches Only)
    
    func pauseGame() {
        guard matchType == .bot else { return }  // Only for bot matches
        isPaused = true
        timer?.invalidate()
        KidsAudioManager.shared.playPop()
    }
    
    func resumeGame() {
        guard matchType == .bot else { return }
        isPaused = false
        KidsAudioManager.shared.playSuccess()
        
        // Restart timer if we're still playing and haven't submitted
        if screen == .playing && !hasSubmitted && timeRemaining > 0 {
            startTimer()
        }
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
                        self.submitWord(force: true)
                    }
                }
            }
        }
    }
    
    private func simulateBotResult() {
        timer?.invalidate()
        
        lastWord = currentWord
        lastWordScore = calculateScore(word: currentWord)
        
        // Track word attempt for Tricky Words feature (if enabled)
        let wasCorrect = lastWordScore > 0
        TrickyWordsManager.shared.recordAttempt(
            word: currentWord,
            wasCorrect: wasCorrect,
            ageGroup: selectedAgeGroup
        )
        
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
        
        // Calculate learning tip (find the best possible word from this rack)
        learningTip = calculateLearningTip()
        
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
    
    /// Calculate a learning tip - finds the best possible word from the rack
    /// Only shows if player scored 4+ points less than the best possible word
    private func calculateLearningTip() -> KidsTip? {
        // Find all valid words from the current rack
        let validWords = LocalDictionary.shared.findValidWords(letters: letters, minLength: selectedAgeGroup.minWordLength)
        
        guard !validWords.isEmpty else { return nil }
        
        // Score all valid words and find the best one
        var bestWord = ""
        var bestScore = 0
        
        for word in validWords {
            let score = calculateScore(word: word)
            if score > bestScore {
                bestScore = score
                bestWord = word
            }
        }
        
        // Only show tip if:
        // 1. Best word is different from what player submitted
        // 2. Player scored at least 4 points less than the best
        let minDifference = 4
        let scoreDifference = bestScore - lastWordScore
        
        guard !bestWord.isEmpty,
              bestWord.uppercased() != lastWord.uppercased(),
              scoreDifference >= minDifference else {
            return nil
        }
        
        return KidsTip(word: bestWord.uppercased(), score: bestScore)
    }
    
    private func checkMatchEnd() {
        let isWin = myScore > oppScore
        
        if isWin {
            matchWinner = "you"
            handleVictory()
        } else if oppScore > myScore {
            matchWinner = "opp"
        } else {
            matchWinner = "tie"
        }
        
        // Record game completion for stats and unlock checks
        KidsStatsManager.shared.recordGameCompleted(
            won: isWin,
            score: myScore,
            longestWordLength: longestWord.count,
            lastWordTime: lastSubmitTime,
            roundsWon: myScore,
            gameState: self
        )
        
        screen = .matchResult
    }
    
    private func handleVictory() {
        lastEarnedSticker = nil
        
        // Unlock next island within this age group's track.
        if let current = selectedLevel {
            let currentIndex = Self.trackIndex(for: current)
            let unlockIndex = unlockedIndex(for: current.ageGroup)

            if currentIndex == unlockIndex {
                setUnlockedIndex(unlockIndex + 1, for: current.ageGroup)
            }
            
            // Award stars based on performance (score percentage)
            // Calculate max possible score: 7 rounds × longest word bonus
            // Simplified: use ratio of myScore to (myScore + oppScore) as proxy
            let totalPoints = myScore + oppScore
            let scorePercentage = totalPoints > 0 ? Double(myScore) / Double(totalPoints) : 0.5
            awardStars(for: current.id, scorePercentage: scorePercentage)
            
            // Add sticker if not already earned
            if !collectedStickers.contains(current.stickerReward) {
                var stickers = collectedStickers
                stickers.append(current.stickerReward)
                collectedStickers = stickers
                lastEarnedSticker = current.stickerReward
                
                // Check for 100% completion - award Master Sticker
                checkAndAwardMasterSticker()
            }
        }
    }
    
    /// Awards the Master Sticker (🏆) if all 30 island stickers have been collected
    private func checkAndAwardMasterSticker() {
        // Count unique island stickers (excluding Master Sticker itself)
        let islandStickers = collectedStickers.filter { $0 != Self.masterSticker }
        let allLevelStickers = Set(Self.levels.map { $0.stickerReward })
        let collectedIslandStickers = Set(islandStickers).intersection(allLevelStickers)
        
        // Award Master Sticker if all 30 islands collected and not already awarded
        if collectedIslandStickers.count >= Self.totalIslandStickers 
            && !collectedStickers.contains(Self.masterSticker) {
            var stickers = collectedStickers
            stickers.append(Self.masterSticker)
            collectedStickers = stickers
            lastEarnedSticker = Self.masterSticker
        }
    }
    
    private func calculateScore(word: String) -> Int {
        guard !word.isEmpty else { return 0 }
        
        // Validate word is real using LocalDictionary
        let validation = LocalDictionary.shared.validate(word, rack: letters, minLength: selectedAgeGroup.minWordLength)
        if !validation.valid {
            return 0  // Invalid word gets 0 points
        }
        
        // Use LocalScorer for consistent scoring with main app
        return LocalScorer.shared.calculate(word: word, rack: letters, bonuses: [])
    }
    
    private func handleOpponentLeft() {
        resetTransientMatchState()
        socketService.leave()
        socketService.disconnect()
        matchWinner = "you"
        isConnected = false
        screen = .matchResult
    }
    
    private func generateLetters(count: Int) -> [String] {
        let vowels = ["A", "E", "I", "O", "U"]
        let consonants = ["B", "C", "D", "F", "G", "H", "L", "M", "N", "P", "R", "S", "T", "W"]
        
        var result: [String] = []
        let vowelCount = Int.random(in: 2...3)
        for _ in 0..<vowelCount {
            if let v = vowels.randomElement() {
                result.append(v)
            }
        }
        
        while result.count < count {
            if let c = consonants.randomElement() {
                result.append(c)
            } else {
                break
            }
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
