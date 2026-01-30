import SwiftUI

/// Manages Party Mode state for Kids - simplified for children
@MainActor
class KidsPartyGameState: ObservableObject {

    @AppStorage("kidsExtraChallengeEnabled") private var extraChallengeEnabled: Bool = false
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Players
    @Published var players: [KidsPartyPlayer] = []
    @Published var currentPlayerIndex: Int = 0
    
    var currentPlayer: KidsPartyPlayer? {
        guard currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }
    
    // MARK: - Settings
    @Published var ageGroup: KidsAgeGroup = .medium
    @Published var totalRounds: Int = 5
    
    var letterCount: Int {
        // Keep network party stable across devices; apply Extra Challenge only locally.
        if isNetworkGame { return ageGroup.letterCount }
        return ageGroup.effectiveLetterCount(extraChallengeEnabled: extraChallengeEnabled)
    }
    
    // MARK: - Round State
    @Published var currentRound: Int = 0
    @Published var sharedRack: [String] = []
    @Published var sharedBonuses: [(index: Int, type: String)] = []
    @Published var roundStartTime: Date = Date()
    @Published var timeRemaining: Int = 30
    
    // MARK: - Current Turn
    @Published var currentWord: String = ""
    @Published var selectedIndices: [Int] = []
    @Published var hasSubmitted: Bool = false
    
    // MARK: - History
    @Published var roundHistory: [KidsPartyRound] = []
    private var currentRoundSubmissions: [UUID: KidsPartyResult] = [:]
    
    // MARK: - Timer
    private var timer: Timer?
    let roundDuration: Int = 30
    
    // MARK: - Network Mode
    @Published var isNetworkGame: Bool = false
    
    // MARK: - Kid-Friendly Colors (bright & fun!)
    static let playerColors: [String] = [
        "FF6B6B",  // Coral
        "4ECDC4",  // Teal
        "FFE66D",  // Sunshine Yellow
        "A78BFA",  // Purple
    ]
    
    static let playerEmojis: [String] = ["🦁", "🐸", "🐥", "🦄"]
    
    // MARK: - Setup
    
    func setupParty(playerNames: [String], ageGroup: KidsAgeGroup, rounds: Int = 5) {
        let clampedRounds = min(max(rounds, 5), 15)
        self.ageGroup = ageGroup
        self.totalRounds = clampedRounds
        self.currentRound = 0
        self.currentPlayerIndex = 0
        self.roundHistory = []
        
        players = playerNames.prefix(4).enumerated().map { index, name in
            KidsPartyPlayer(
                name: name.isEmpty ? "Player \(index + 1)" : name,
                colorHex: Self.playerColors[index % 4],
                emoji: Self.playerEmojis[index % 4]
            )
        }
        
        print("🎈 Kids Party setup: \(players.map { $0.name })")
    }
    
    func setupNetworkParty(networkPlayers: [NetworkPartyPlayer], ageGroup: KidsAgeGroup, rounds: Int = 5) {
        let clampedRounds = min(max(rounds, 5), 15)
        self.ageGroup = ageGroup
        self.totalRounds = clampedRounds
        self.currentRound = 0
        self.currentPlayerIndex = 0
        self.roundHistory = []
        
        players = networkPlayers.prefix(4).enumerated().map { index, player in
            KidsPartyPlayer(
                name: player.name.isEmpty ? "Player \(index + 1)" : player.name,
                colorHex: player.colorHex,
                emoji: Self.playerEmojis[index % 4],
                networkId: player.id
            )
        }
        
        print("🎈 Kids Network Party setup: \(players.map { $0.name })")
    }
    
    // MARK: - Round Flow
    
    func startNewRound() {
        currentRound += 1
        currentPlayerIndex = 0
        currentRoundSubmissions = [:]
        
        // Generate kid-friendly rack
        let generated = LocalRackGenerator.shared.generate(letterCount: letterCount)
        sharedRack = generated.0
        sharedBonuses = generated.1
        
        print("🎈 Kids Round \(currentRound) started")
    }
    
    func startCurrentPlayerTurn() {
        currentWord = ""
        selectedIndices = []
        hasSubmitted = false
        roundStartTime = Date()
        timeRemaining = roundDuration
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.submitWord(timeout: true)
                }
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Word Building
    
    func toggleLetter(at index: Int) {
        guard !hasSubmitted else { return }
        
        if let existingIndex = selectedIndices.firstIndex(of: index) {
            selectedIndices.removeSubrange(existingIndex...)
        } else {
            selectedIndices.append(index)
        }
        
        currentWord = selectedIndices.map { sharedRack[$0] }.joined()
    }
    
    func clearWord() {
        selectedIndices = []
        currentWord = ""
    }

    func shuffleRack() {
        guard !hasSubmitted else { return }
        guard selectedIndices.isEmpty else { return }
        guard !sharedRack.isEmpty else { return }
        // Avoid desync in network party unless we implement a broadcast.
        guard !isNetworkGame else { return }

        let bonusByIndex: [Int: String] = Dictionary(uniqueKeysWithValues: sharedBonuses.map { ($0.index, $0.type) })

        var items: [(letter: String, bonusType: String?)] = []
        items.reserveCapacity(sharedRack.count)
        for idx in sharedRack.indices {
            items.append((letter: sharedRack[idx], bonusType: bonusByIndex[idx]))
        }

        items.shuffle()
        sharedRack = items.map { $0.letter }
        sharedBonuses = items.enumerated().compactMap { newIndex, item in
            guard let type = item.bonusType else { return nil }
            return (index: newIndex, type: type)
        }
    }
    
    // MARK: - Submission
    
    func submitWord(timeout: Bool = false) {
        guard !hasSubmitted else { return }
        hasSubmitted = true
        stopTimer()
        
        let timeToSubmit = Date().timeIntervalSince(roundStartTime)
        
        // Validate and score (keep consistent with other Kids modes)
        let validation = LocalDictionary.shared.validate(currentWord, rack: sharedRack, minLength: ageGroup.minWordLength)
        let isValid = validation.valid && !currentWord.isEmpty
        let score: Int
        if isValid {
            score = LocalScorer.shared.calculate(word: currentWord, rack: sharedRack, bonuses: sharedBonuses)
        } else {
            score = 0
        }
        
        let result = KidsPartyResult(
            word: currentWord.uppercased(),
            score: score,
            timeToSubmit: timeToSubmit,
            isValid: isValid,
            reason: timeout ? "Time's up!" : (!isValid && !currentWord.isEmpty ? "Try again!" : (currentWord.isEmpty ? "No word submitted" : nil))
        )
        
        if let player = currentPlayer {
            currentRoundSubmissions[player.id] = result
            
            if let idx = players.firstIndex(where: { $0.id == player.id }) {
                players[idx].totalScore += score
                players[idx].wordsPlayed.append(result)
            }
        }
        
        print("🎈 \(currentPlayer?.name ?? "?") submitted '\(currentWord)' for \(score)")
    }
    
    // MARK: - Turn Progression
    
    func advanceToNextPlayer() -> Bool {
        currentPlayerIndex += 1
        
        if currentPlayerIndex >= players.count {
            finalizeRound()
            return false
        }
        return true
    }
    
    private func finalizeRound() {
        var highScore = -1
        var winnerName = ""
        
        for player in players {
            if let result = currentRoundSubmissions[player.id], result.score > highScore {
                highScore = result.score
                winnerName = player.name
            }
        }
        
        let round = KidsPartyRound(
            roundNumber: currentRound,
            rack: sharedRack,
            results: currentRoundSubmissions,
            winner: winnerName
        )
        roundHistory.append(round)
    }
    
    var isPartyComplete: Bool {
        currentRound >= totalRounds && currentPlayerIndex >= players.count
    }
    
    // MARK: - Stats
    
    var partyWinner: KidsPartyPlayer? {
        players.max(by: { $0.totalScore < $1.totalScore })
    }
    
    var tiedWinners: [KidsPartyPlayer] {
        guard let maxScore = players.map({ $0.totalScore }).max() else { return [] }
        return players.filter { $0.totalScore == maxScore }
    }
    
    var sortedPlayers: [KidsPartyPlayer] {
        players.sorted { $0.totalScore > $1.totalScore }
    }
    
    // MARK: - Reset
    
    func resetParty() {
        players = []
        currentPlayerIndex = 0
        currentRound = 0
        sharedRack = []
        roundHistory = []
        currentRoundSubmissions = [:]
        currentWord = ""
        selectedIndices = []
        hasSubmitted = false
        stopTimer()
    }
}

// MARK: - Data Models

struct KidsPartyPlayer: Identifiable {
    let id = UUID()
    var name: String
    var colorHex: String
    var emoji: String
    var totalScore: Int = 0
    var wordsPlayed: [KidsPartyResult] = []
    var networkId: String? = nil
    
    var color: Color {
        Color(hex: colorHex)
    }
}

struct KidsPartyResult: Equatable {
    let word: String
    let score: Int
    let timeToSubmit: Double
    let isValid: Bool
    let reason: String?
}

struct KidsPartyRound {
    let roundNumber: Int
    let rack: [String]
    let results: [UUID: KidsPartyResult]
    let winner: String
}
