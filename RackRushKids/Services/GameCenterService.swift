import Foundation
import GameKit
import SwiftUI

/// Game Center Service for Apple matchmaking and real-time PvP
@MainActor
class GameCenterService: NSObject, ObservableObject {
    static let shared = GameCenterService()
    
    @Published var isAuthenticated = false
    @Published var localPlayerName = "Player"
    @Published var localPlayerId = ""
    @Published var currentMatch: GKMatch?
    @Published var matchState: MatchState = .idle
    @Published var error: String?
    
    // Match data
    @Published var opponentName = ""
    @Published var opponentId = ""
    @Published var isHost = false  // Host generates letters and manages rounds
    
    // Round data
    @Published var currentRound = 0
    @Published var letters: [String] = []
    @Published var bonuses: [(index: Int, type: String)] = []
    @Published var roundEndsAt: Int = 0
    @Published var submitted = false
    @Published var opponentSubmitted = false
    private var hasStartedFirstRound = false // Prevent duplicate starts
    @Published var myWord = ""
    @Published var myScore = 0
    @Published var oppWord = ""
    @Published var oppScore = 0
    
    // Scores
    @Published var myTotalScore = 0
    @Published var oppTotalScore = 0
    @Published var roundHistory: [RoundResultData] = []
    @Published var matchWinner: String?
    @Published var isRematchRequested = false
    @Published var opponentRematchRequested = false
    
    // Callbacks for GameState integration
    var onMatchFound: (() -> Void)?
    var onRoundStart: (() -> Void)?
    var onOpponentSubmitted: (() -> Void)?
    var onRoundEnd: ((RoundResultData) -> Void)?
    var onMatchEnd: ((String) -> Void)?  // winner: "you", "opp", "tie"
    
    enum MatchState: String {
        case idle
        case authenticating
        case finding
        case matched
        case countdown
        case playing
        case roundEnded
        case matchEnded
    }
    
    struct RoundResultData {
        let yourWord: String
        let yourScore: Int
        let oppWord: String
        let oppScore: Int
        let winner: String
        let yourTotalScore: Int
        let oppTotalScore: Int
        let roundNumber: Int
        let totalRounds: Int
    }
    
    private var roundTimer: Timer?
    private var totalRounds: Int { configuredTotalRounds }  // Use configured value
    private let roundDurationSeconds = 30
    
    // Idempotency guard for endRound race condition
    private var isEndingRound = false
    
    // Configurable match settings (set before finding match)
    var configuredLetterCount: Int = 8
    var configuredTotalRounds: Int = 7  // Default 7, can be set to 5 for younger kids
    
    override private init() {
        super.init()
    }
    
    // MARK: - Authentication
    
    func authenticate() {
        guard !isAuthenticated else { return }
        matchState = .authenticating
        
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let error = error {
                    self?.error = "Game Center: \(error.localizedDescription)"
                    self?.matchState = .idle
                    return
                }
                
                if viewController != nil {
                    // System will show Game Center login UI
                    return
                }
                
                if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.localPlayerName = GKLocalPlayer.local.displayName
                    self?.localPlayerId = GKLocalPlayer.local.gamePlayerID
                    self?.matchState = .idle
                    print("Game Center authenticated: \(GKLocalPlayer.local.displayName)")
                } else {
                    self?.error = "Game Center authentication failed"
                    self?.matchState = .idle
                }
            }
        }
    }
    
    // MARK: - Matchmaking
    
    func findMatch(minPlayers: Int = 2, maxPlayers: Int = 2) {
        guard isAuthenticated else {
            error = "Not authenticated with Game Center"
            return
        }
        
        matchState = .finding
        resetMatchData()
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        request.inviteMessage = "Let's play RackRush!"
        // Set delegate to suppress warning (we handle async matchmaking, not invites)
        request.recipientResponseHandler = { _, _ in }
        
        GKMatchmaker.shared().findMatch(for: request) { [weak self] match, error in
            Task { @MainActor in
                if let error = error {
                    self?.error = "Matchmaking failed: \(error.localizedDescription)"
                    self?.matchState = .idle
                    return
                }
                
                guard let match = match else {
                    self?.error = "No match found"
                    self?.matchState = .idle
                    return
                }
                
                self?.setupMatch(match)
            }
        }
    }
    
    private func setupMatch(_ match: GKMatch) {
        currentMatch = match
        match.delegate = self
        matchState = .matched
        
        // Get opponent info (may be populated later via delegate)
        updateOpponentInfo(from: match)
        
        print("Match found! Opponent: \(opponentName), I am host: \(isHost)")
        
        onMatchFound?()
        
        // If host, start the first round after a delay
        // REDUNDANT: Moved to didChange (state: .connected) to ensure peer is ready
        /*
        if isHost {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.startRound()
            }
        }
        */
    }
    
    private func updateOpponentInfo(from match: GKMatch) {
        // Try to get opponent from players array
        for player in match.players {
            if player.gamePlayerID != localPlayerId {
                opponentName = player.displayName
                opponentId = player.gamePlayerID
                
                // Determine host (player with "lower" ID is host)
                isHost = localPlayerId < opponentId
                
                print("Opponent updated: \(opponentName), I am host: \(isHost)")
                break
            }
        }
    }
    
    func cancelMatchmaking() {
        GKMatchmaker.shared().cancel()
        matchState = .idle
    }
    
    // MARK: - Round Management (Host Only)
    
    private func startRound() {
        guard isHost else { return }
        
        // Reset idempotency guard for new round
        isEndingRound = false
        
        currentRound += 1
        
        print("🎮 Starting round \(currentRound)")
        
        // Kids app always uses the configured letter count (set from age group)
        let letterCount = configuredLetterCount
        print("🎮 startRound: currentRound=\(currentRound), configuredCount=\(configuredLetterCount), usingCount=\(letterCount)")
        let (generatedLetters, generatedBonuses) = LocalRackGenerator.shared.generate(letterCount: letterCount)
        
        letters = generatedLetters
        bonuses = generatedBonuses
        
        print("🎮 Generated letters (\(letters.count)): \(letters)")
        
        // Calculate round end time
        // Only show 3-2-1 countdown for first round, others start immediately
        let now = Int(Date().timeIntervalSince1970 * 1000)
        let delayMs = currentRound == 1 ? 3000 : 0
        let delaySeconds = Double(delayMs) / 1000.0
        roundEndsAt = now + delayMs + (roundDurationSeconds * 1000)
        
        print("🎮 Round \(currentRound) will end at \(roundEndsAt) (in \(roundDurationSeconds)s)")
        
        // Reset submission state
        submitted = false
        opponentSubmitted = false
        myWord = ""
        myScore = 0
        oppWord = ""
        oppScore = 0
        
        // Send round start to opponent
        let data = GameData(
            type: .roundStart,
            letters: letters,
            bonuses: bonuses.map { GameData.BonusData(index: $0.index, type: $0.type) },
            roundNumber: currentRound,
            endsAt: roundEndsAt
        )
        sendData(data)
        
        print("🎮 Sent round data to opponent, delay: \(delayMs)ms")
        
        // First round shows countdown, others go straight to playing
        if currentRound == 1 {
            matchState = .countdown
            DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) { [weak self] in
                guard let self = self else { return }
                print("🎮 Countdown done, starting play!")
                self.matchState = .playing
                self.onRoundStart?()
            }
        } else {
            matchState = .playing
            onRoundStart?()
        }
        
        // Schedule round end
        let totalDelay = Double(delayMs + (roundDurationSeconds * 1000)) / 1000.0
        roundTimer?.invalidate()
        roundTimer = Timer.scheduledTimer(withTimeInterval: totalDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.endRound()
            }
        }
    }
    
    // MARK: - Submissions
    
    func submitWord(_ word: String) {
        guard !submitted else { return }
        
        myWord = word.uppercased()
        
        // Validate and score locally
        let validation = LocalDictionary.shared.validate(word, rack: letters)
        myScore = validation.valid ? LocalScorer.shared.calculate(
            word: word,
            rack: letters,
            bonuses: bonuses
        ) : 0
        
        submitted = true
        
        // Send submission to opponent
        let data = GameData(type: .submission, word: myWord, score: myScore)
        sendData(data)
        
        // Check if both submitted
        checkBothSubmitted()
    }
    
    private func checkBothSubmitted() {
        if submitted && opponentSubmitted {
            print("🎮 Both submitted! Ending round \(currentRound) early.")
            roundTimer?.invalidate()
            endRound()
        }
    }
    
    private func endRound() {
        print("🎮 endRound called: matchState=\(matchState.rawValue), round=\(currentRound)")
        
        // Idempotency guard - prevent double execution
        guard !isEndingRound else {
            print("🎮 endRound ignored: already ending round")
            return
        }
        isEndingRound = true
        
        guard matchState == .playing || matchState == .countdown else { 
            print("🎮 endRound ignored: matchState is \(matchState.rawValue)")
            isEndingRound = false
            return 
        }
        
        roundTimer?.invalidate()
        
        // Determine round winner
        let winner: String
        if myScore > oppScore {
            winner = "you"
        } else if oppScore > myScore {
            winner = "opp"
        } else {
            winner = "tie"
        }
        
        // Update totals
        myTotalScore += myScore
        oppTotalScore += oppScore
        
        // Create result
        let result = RoundResultData(
            yourWord: myWord,
            yourScore: myScore,
            oppWord: oppWord,
            oppScore: oppScore,
            winner: winner,
            yourTotalScore: myTotalScore,
            oppTotalScore: oppTotalScore,
            roundNumber: currentRound,
            totalRounds: totalRounds
        )
        roundHistory.append(result)
        
        matchState = .roundEnded
        onRoundEnd?(result)
        
        // If host, send result to opponent (from their perspective)
        if isHost {
            let oppResult = GameData(
                type: .roundResult,
                roundResult: GameData.RoundResultPayload(
                    yourWord: oppWord,
                    yourScore: oppScore,
                    oppWord: myWord,
                    oppScore: myScore,
                    winner: winner == "you" ? "opp" : (winner == "opp" ? "you" : "tie"),
                    yourTotalScore: oppTotalScore,
                    oppTotalScore: myTotalScore,
                    roundNumber: currentRound,
                    totalRounds: totalRounds
                )
            )
            sendData(oppResult)
        }
        
        // Check if match is over
        if currentRound >= totalRounds {
            endMatch()
        } else if isHost {
            // Start next round after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.startRound()
            }
        }
    }
    
    private func endMatch() {
        matchState = .matchEnded
        
        if myTotalScore > oppTotalScore {
            matchWinner = "you"
        } else if oppTotalScore > myTotalScore {
            matchWinner = "opp"
        } else {
            matchWinner = "tie"
        }
        
        onMatchEnd?(matchWinner ?? "tie")
        
        // Clean up after 10 seconds if no rematch requested
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            if !self.isRematchRequested && !self.opponentRematchRequested {
                self.disconnect()
            }
        }
    }
    
    func resetForRematch() {
        currentRound = 0
        letters = []
        bonuses = []
        roundEndsAt = 0
        submitted = false
        opponentSubmitted = false
        hasStartedFirstRound = false
        myWord = ""
        myScore = 0
        oppWord = ""
        oppScore = 0
        myTotalScore = 0
        oppTotalScore = 0
        roundHistory = []
        matchWinner = nil
        isRematchRequested = false
        opponentRematchRequested = false
        matchState = .idle // Ready to be started by host
    }
    
    func requestRematch() {
        guard matchState == .matchEnded else { return }
        isRematchRequested = true
        sendData(GameData(type: .rematchRequest))
        
        if opponentRematchRequested {
            acceptRematch()
        }
    }
    
    func acceptRematch() {
        guard opponentRematchRequested else { return }
        sendData(GameData(type: .rematchRequest)) // Send confirmation
        
        // Both want rematch!
        resetForRematch()
        
        if isHost {
            // Host starts after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startRound()
            }
        }
    }
    
    // MARK: - Data Exchange
    
    func sendData(_ data: GameData) {
        guard let match = currentMatch else { return }
        
        do {
            let encoded = try JSONEncoder().encode(data)
            try match.sendData(toAllPlayers: encoded, with: .reliable)
        } catch {
            print("Failed to send data: \(error)")
        }
    }
    
    private func handleReceivedData(_ data: GameData) {
        switch data.type {
        case .roundStart:
            // Received from host
            if let receivedLetters = data.letters,
               let receivedBonuses = data.bonuses,
               let roundNum = data.roundNumber,
               let endsAt = data.endsAt {
                currentRound = roundNum
                letters = receivedLetters
                bonuses = receivedBonuses.map { ($0.index, $0.type) }
                roundEndsAt = endsAt
                submitted = false
                opponentSubmitted = false
                myWord = ""
                myScore = 0
                oppScore = 0
                
                print("🎮 handleReceivedData: received roundStart \(roundNum), letters=\(receivedLetters.count)")
                
                // Only show countdown for round 1, others start immediately
                if roundNum == 1 {
                    matchState = .countdown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                        guard let self = self else { return }
                        self.matchState = .playing
                        self.onRoundStart?()
                    }
                } else {
                    matchState = .playing
                    onRoundStart?()
                }
            }
            
        case .submission:
            // Opponent submitted
            opponentSubmitted = true
            oppWord = data.word ?? ""
            oppScore = data.score ?? 0
            onOpponentSubmitted?()
            checkBothSubmitted()
            
        case .roundResult:
            // Received from host (for non-host player)
            if let result = data.roundResult {
                myTotalScore = result.yourTotalScore
                oppTotalScore = result.oppTotalScore
                
                let roundResult = RoundResultData(
                    yourWord: result.yourWord,
                    yourScore: result.yourScore,
                    oppWord: result.oppWord,
                    oppScore: result.oppScore,
                    winner: result.winner,
                    yourTotalScore: result.yourTotalScore,
                    oppTotalScore: result.oppTotalScore,
                    roundNumber: result.roundNumber,
                    totalRounds: result.totalRounds
                )
                roundHistory.append(roundResult)
                matchState = .roundEnded
                onRoundEnd?(roundResult)
                
                if result.roundNumber >= result.totalRounds {
                    endMatch()
                }
            }
            
        case .matchResult:
            matchState = .matchEnded
            
        case .rematchRequest:
            opponentRematchRequested = true
            if isRematchRequested {
                // We've both requested, so accept/start
                resetForRematch()
                if isHost {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.startRound()
                    }
                }
            }
        }
    }
    
    // MARK: - Cleanup
    
    func disconnect() {
        roundTimer?.invalidate()
        currentMatch?.disconnect()
        currentMatch = nil
        matchState = .idle
        resetMatchData()
    }
    
    private func resetMatchData() {
        opponentName = ""
        opponentId = ""
        isHost = false
        currentRound = 0
        letters = []
        bonuses = []
        roundEndsAt = 0
        submitted = false
        opponentSubmitted = false
        hasStartedFirstRound = false
        myWord = ""
        myScore = 0
        oppWord = ""
        oppScore = 0
        myTotalScore = 0
        oppTotalScore = 0
        roundHistory = []
        matchWinner = nil
        isRematchRequested = false
        opponentRematchRequested = false
    }
}

// MARK: - GKMatchDelegate

extension GameCenterService: GKMatchDelegate {
    nonisolated func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        Task { @MainActor in
            do {
                let gameData = try JSONDecoder().decode(GameData.self, from: data)
                handleReceivedData(gameData)
            } catch {
                print("Failed to decode game data: \(error)")
            }
        }
    }
    
    nonisolated func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                print("Player connected: \(player.displayName)")
                // Update opponent info
                if player.gamePlayerID != self.localPlayerId {
                    self.opponentName = player.displayName
                    self.opponentId = player.gamePlayerID
                    self.isHost = self.localPlayerId < self.opponentId
                    print("Opponent set: \(self.opponentName), I am host: \(self.isHost)")
                    
                    // If we're now the host and haven't started, start the round
                    if self.isHost && self.currentRound == 0 && !self.hasStartedFirstRound {
                        self.hasStartedFirstRound = true
                        print("🎮 Host detected peer connected. Starting first round...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                            self?.startRound()
                        }
                    }
                }
            case .disconnected:
                print("Player disconnected: \(player.displayName)")
                self.error = "Opponent disconnected"
                self.matchWinner = "you"  // Win by forfeit
                self.matchState = .matchEnded
                onMatchEnd?("you")
            default:
                break
            }
        }
    }
    
    nonisolated func match(_ match: GKMatch, didFailWithError error: Error?) {
        Task { @MainActor in
            self.error = "Match error: \(error?.localizedDescription ?? "Unknown")"
            self.matchState = .idle
        }
    }
}

// MARK: - Game Data Types

struct GameData: Codable {
    enum DataType: String, Codable {
        case roundStart
        case submission
        case roundResult
        case matchResult
        case rematchRequest
    }
    
    let type: DataType
    var letters: [String]?
    var bonuses: [BonusData]?
    var word: String?
    var score: Int?
    var roundNumber: Int?
    var endsAt: Int?
    var roundResult: RoundResultPayload?
    
    struct BonusData: Codable {
        let index: Int
        let type: String
    }
    
    struct RoundResultPayload: Codable {
        let yourWord: String
        let yourScore: Int
        let oppWord: String
        let oppScore: Int
        let winner: String
        let yourTotalScore: Int
        let oppTotalScore: Int
        let roundNumber: Int
        let totalRounds: Int
    }
}
