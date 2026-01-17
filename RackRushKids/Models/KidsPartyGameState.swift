import SwiftUI

/// Manages Party Mode state for Kids - simplified for children
@MainActor
class KidsPartyGameState: ObservableObject {
    
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
    @Published var totalRounds: Int = 3
    
    var letterCount: Int {
        ageGroup.letterCount
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
    
    func setupParty(playerNames: [String], ageGroup: KidsAgeGroup, rounds: Int = 3) {
        self.ageGroup = ageGroup
        self.totalRounds = rounds
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
    
    // MARK: - Submission
    
    func submitWord(timeout: Bool = false) {
        guard !hasSubmitted else { return }
        hasSubmitted = true
        stopTimer()
        
        let timeToSubmit = Date().timeIntervalSince(roundStartTime)
        
        // Use kids dictionary for age-appropriate validation
        let isValid = LocalDictionary.shared.isValid(currentWord) && !currentWord.isEmpty
        let score = isValid ? currentWord.count * 10 : 0  // Simple scoring for kids
        
        let result = KidsPartyResult(
            word: currentWord.uppercased(),
            score: score,
            timeToSubmit: timeToSubmit,
            isValid: isValid,
            reason: timeout ? "Time's up!" : (!isValid && !currentWord.isEmpty ? "Try again!" : nil)
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
