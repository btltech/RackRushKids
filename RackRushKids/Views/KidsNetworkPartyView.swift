import SwiftUI
import MultipeerConnectivity

/// Kids Network Party - Host or join a party with friends!
struct KidsNetworkPartyView: View {
    @ObservedObject var gameState: KidsGameState
    @ObservedObject var multipeerService = MultipeerService.shared
    
    @State private var playerName: String = ""
    @State private var mode: LobbyMode = .select
    @State private var showingGame = false
    @StateObject private var partyState = KidsPartyGameState()
    
    enum LobbyMode {
        case select
        case hosting
        case browsing
    }
    
    var body: some View {
        ZStack {
            // Fun gradient background
            KidsTheme.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                headerSection
                
                switch mode {
                case .select:
                    modeSelectSection
                case .hosting:
                    hostingSection
                case .browsing:
                    browsingSection
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .onAppear {
            playerName = UserDefaults.standard.string(forKey: "kidsPlayerName") ?? ""
        }
        .onDisappear {
            multipeerService.disconnect()
        }
        .fullScreenCover(isPresented: $showingGame) {
            KidsNetworkPartyGameView(partyState: partyState, gameState: gameState)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    if mode == .select {
                        gameState.screen = .home
                    } else {
                        multipeerService.stopAll()
                        mode = .select
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(KidsTheme.textSecondary)
                }
                Spacer()
            }
            
            Text("📡")
                .font(.system(size: 70))
            
            Text("PLAY WITH FRIENDS!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(KidsTheme.partyGradient)
            
            Text("On different devices")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
        }
    }
    
    // MARK: - Mode Select
    
    private var modeSelectSection: some View {
        VStack(spacing: 20) {
            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR NAME")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
                
                TextField("Enter your name", text: $playerName)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(KidsTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            // Host button
            Button(action: startHosting) {
                HStack(spacing: 16) {
                    Text("🏠")
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("START A PARTY")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Friends can join you")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                }
                .foregroundColor(.white)
                .padding(20)
                .background(KidsTheme.playButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            // Join button
            Button(action: startBrowsing) {
                HStack(spacing: 16) {
                    Text("🎯")
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("JOIN A PARTY")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Find a friend's party")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                }
                .foregroundColor(.white)
                .padding(20)
                .background(KidsTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                )
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Hosting
    
    private var hostingSection: some View {
        VStack(spacing: 20) {
            // Status
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                Text("Party is ready!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(KidsTheme.textSecondary)
            }
            
            // Players list
            VStack(alignment: .leading, spacing: 12) {
                Text("PLAYERS (\(multipeerService.lobbyPlayers.count)/4)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
                
                ForEach(Array(multipeerService.lobbyPlayers.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 12) {
                        Text(KidsPartyGameState.playerEmojis[min(index, 3)])
                            .font(.system(size: 36))
                        
                        Text(player.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if player.isHost {
                            Text("HOST")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(KidsTheme.accent)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(KidsTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            
            // Start button
            if multipeerService.lobbyPlayers.count >= 2 {
                Button(action: startNetworkGame) {
                    HStack(spacing: 12) {
                        Text("🎉")
                            .font(.system(size: 28))
                        Text("LET'S PLAY!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(KidsTheme.partyGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            } else {
                Text("Waiting for friends to join...")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Browsing
    
    private var browsingSection: some View {
        VStack(spacing: 20) {
            // Status
            HStack {
                ProgressView()
                    .tint(.white)
                Text("Looking for parties...")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(KidsTheme.textSecondary)
            }
            
            // Available hosts
            if multipeerService.availableHosts.isEmpty {
                VStack(spacing: 12) {
                    Text("🔍")
                        .font(.system(size: 50))
                    Text("No parties found yet")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                }
                .padding(.top, 40)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PARTIES NEARBY")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                    
                    ForEach(multipeerService.availableHosts, id: \.displayName) { host in
                        Button(action: { joinParty(host) }) {
                            HStack {
                                Text("🏠")
                                    .font(.system(size: 36))
                                
                                Text(host.displayName)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("JOIN")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(KidsTheme.accent)
                                    .clipShape(Capsule())
                            }
                            .padding(16)
                            .background(KidsTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            
            // Show lobby if connected
            if multipeerService.isConnected {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🎉 JOINED!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.green)
                    
                    ForEach(Array(multipeerService.lobbyPlayers.enumerated()), id: \.element.id) { index, player in
                        HStack(spacing: 12) {
                            Text(KidsPartyGameState.playerEmojis[min(index, 3)])
                                .font(.system(size: 30))
                            
                            Text(player.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(KidsTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text("Waiting for host to start...")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Actions
    
    private func startHosting() {
        let name = playerName.isEmpty ? "Player 1" : playerName
        let colorHex = KidsPartyGameState.playerColors[0]
        multipeerService.setup(playerName: name, colorHex: colorHex)
        multipeerService.startHosting()
        mode = .hosting
        
        multipeerService.onMessageReceived = { message, peer in
            handleMessage(message, from: peer)
        }
        
        KidsAudioManager.shared.playPop()
    }
    
    private func startBrowsing() {
        let name = playerName.isEmpty ? "Player" : playerName
        let colorHex = KidsPartyGameState.playerColors[1]
        multipeerService.setup(playerName: name, colorHex: colorHex)
        multipeerService.startBrowsing()
        mode = .browsing
        
        multipeerService.onMessageReceived = { message, peer in
            handleMessage(message, from: peer)
        }
        
        KidsAudioManager.shared.playPop()
    }
    
    private func joinParty(_ host: MCPeerID) {
        multipeerService.joinHost(host)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            multipeerService.send(.playerJoined(name: playerName, colorHex: KidsPartyGameState.playerColors[1]))
        }
        
        KidsAudioManager.shared.playSuccess()
    }
    
    private func startNetworkGame() {
        let names = multipeerService.lobbyPlayers.map { $0.name }
        partyState.setupParty(
            playerNames: names,
            ageGroup: KidsAgeGroup(rawValue: gameState.ageGroup) ?? .medium,
            rounds: 3
        )
        partyState.isNetworkGame = true
        
        multipeerService.send(.startGame)
        
        showingGame = true
        KidsAudioManager.shared.playSuccess()
    }
    
    private func handleMessage(_ message: PartyMultipeerMessage, from peer: MCPeerID) {
        switch message {
        case .startGame:
            let names = multipeerService.lobbyPlayers.map { $0.name }
            partyState.setupParty(
                playerNames: names,
                ageGroup: KidsAgeGroup(rawValue: gameState.ageGroup) ?? .medium,
                rounds: 3
            )
            partyState.isNetworkGame = true
            showingGame = true
            
        default:
            break
        }
    }
}

// MARK: - Kids Network Party Game View
struct KidsNetworkPartyGameView: View {
    @ObservedObject var partyState: KidsPartyGameState
    @ObservedObject var gameState: KidsGameState
    @ObservedObject var multipeerService = MultipeerService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Game phases
    enum GamePhase {
        case waitingForRound
        case playing
        case waitingForOthers
        case showingResults
        case gameOver
    }
    
    @State private var phase: GamePhase = .waitingForRound
    @State private var currentRound = 1
    @State private var totalRounds = 3
    @State private var rack: [String] = []
    @State private var bonuses: [(Int, String)] = []
    @State private var selectedIndices: [Int] = []
    @State private var currentWord = ""
    @State private var timeRemaining = 30
    @State private var timer: Timer?
    @State private var hasSubmitted = false
    @State private var myPlayerId: String = ""
    @State private var submissions: [String: (playerName: String, word: String, score: Int)] = [:]
    @State private var showingExit = false
    
    var body: some View {
        ZStack {
            KidsTheme.background.ignoresSafeArea()
            
            VStack(spacing: 16) {
                headerView
                
                switch phase {
                case .waitingForRound:
                    waitingView
                case .playing:
                    playingView
                case .waitingForOthers:
                    waitingForOthersView
                case .showingResults:
                    resultsView
                case .gameOver:
                    gameOverView
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear { setupGame() }
        .onDisappear { timer?.invalidate() }
        .alert("Leave Party?", isPresented: $showingExit) {
            Button("Stay", role: .cancel) { }
            Button("Leave", role: .destructive) {
                multipeerService.disconnect()
                dismiss()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { showingExit = true }) {
                Image(systemName: "xmark")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(KidsTheme.textSecondary)
            }
            
            Spacer()
            
            Text("ROUND \(currentRound)/\(totalRounds)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                Text("\(timeRemaining)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
            }
            .foregroundColor(timeRemaining <= 5 ? .red : .white)
        }
        .padding(.top, 16)
    }
    
    private var waitingView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("⏳").font(.system(size: 80))
            Text("Get Ready!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    private var playingView: some View {
        VStack(spacing: 20) {
            // Current word
            HStack(spacing: 8) {
                ForEach(Array(currentWord.enumerated()), id: \.offset) { _, letter in
                    Text(letter.uppercased())
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 50)
                        .background(KidsTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .frame(height: 60)
            
            Spacer()
            
            // Letter rack
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(0..<min(4, rack.count), id: \.self) { index in
                        letterTile(at: index)
                    }
                }
                if rack.count > 4 {
                    HStack(spacing: 10) {
                        ForEach(4..<rack.count, id: \.self) { index in
                            letterTile(at: index)
                        }
                    }
                }
            }
            
            // Buttons
            HStack(spacing: 16) {
                Button(action: clearWord) {
                    Text("Clear")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(KidsTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Button(action: submitWord) {
                    Text("✓ Submit")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(KidsTheme.playButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    private func letterTile(at index: Int) -> some View {
        let letter = rack[index]
        let isSelected = selectedIndices.contains(index)
        
        return Button(action: { toggleLetter(at: index) }) {
            Text(letter.uppercased())
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 56, height: 64)
                .background(isSelected ? KidsTheme.accent : KidsTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var waitingForOthersView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("✅").font(.system(size: 80))
            Text("You submitted!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color.green)
            Text("Waiting for friends...")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
            Spacer()
        }
    }
    
    private var resultsView: some View {
        VStack(spacing: 24) {
            Text("ROUND \(currentRound) RESULTS")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            ForEach(Array(submissions.values.sorted { $0.score > $1.score }), id: \.playerName) { sub in
                HStack {
                    Text(sub.playerName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text(sub.word.uppercased())
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(KidsTheme.accent)
                    Text("+\(sub.score)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(16)
                .background(KidsTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
            
            if multipeerService.isHosting {
                Button(action: startNextRound) {
                    Text(currentRound >= totalRounds ? "FINISH" : "NEXT ROUND")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(KidsTheme.playButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
    
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🏆").font(.system(size: 100))
            Text("AMAZING!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(KidsTheme.partyGradient)
            
            if let winner = partyState.partyWinner {
                Text("\(winner.name) wins!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                multipeerService.disconnect()
                dismiss()
            }) {
                Text("Go Home")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(KidsTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Game Logic
    
    private func setupGame() {
        // Find my player ID
        if multipeerService.isHosting {
            myPlayerId = multipeerService.lobbyPlayers.first { $0.isHost }?.id ?? ""
        } else {
            myPlayerId = multipeerService.lobbyPlayers.first { !$0.isHost }?.id ?? ""
        }
        
        print("🎈 KidsNetworkPartyGame setupGame - myPlayerId: \(myPlayerId), isHosting: \(multipeerService.isHosting)")
        
        // Set up message handler FIRST
        multipeerService.onMessageReceived = { [self] message, peer in
            DispatchQueue.main.async {
                self.handleMessage(message)
            }
        }
        
        // If host, start first round after a delay to ensure all clients are ready
        if multipeerService.isHosting {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                print("🎈 Host starting first round...")
                self.startRound()
            }
        }
    }
    
    private func startRound() {
        let generated = LocalRackGenerator.shared.generate(letterCount: partyState.letterCount)
        rack = generated.0
        bonuses = generated.1
        
        print("🎈 Host generated rack: \(rack.joined(separator: ","))")
        
        multipeerService.send(.roundStart(roundNumber: currentRound, rack: rack, bonuses: bonuses))
        beginRound(rack: rack, bonuses: bonuses)
    }
    
    private func beginRound(rack: [String], bonuses: [(Int, String)]) {
        self.rack = rack
        self.bonuses = bonuses
        self.selectedIndices = []
        self.currentWord = ""
        self.hasSubmitted = false
        self.submissions = [:]
        self.timeRemaining = partyState.roundDuration
        self.phase = .playing
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else if !hasSubmitted {
                submitWord()
            }
        }
    }
    
    private func toggleLetter(at index: Int) {
        if let idx = selectedIndices.firstIndex(of: index) {
            selectedIndices.remove(at: idx)
        } else {
            selectedIndices.append(index)
        }
        currentWord = selectedIndices.map { rack[$0] }.joined()
        KidsAudioManager.shared.playPop()
    }
    
    private func clearWord() {
        selectedIndices = []
        currentWord = ""
    }
    
    private func submitWord() {
        guard !hasSubmitted else { return }
        hasSubmitted = true
        timer?.invalidate()
        
        let validation = LocalDictionary.shared.validate(currentWord, rack: rack)
        let score = validation.valid ? LocalScorer.shared.calculate(word: currentWord, rack: rack, bonuses: bonuses) : 0
        let time = Double(partyState.roundDuration - timeRemaining)
        
        let playerName = multipeerService.lobbyPlayers.first { $0.id == myPlayerId }?.name ?? "Me"
        submissions[myPlayerId] = (playerName: playerName, word: currentWord.uppercased(), score: score)
        
        if let idx = partyState.players.firstIndex(where: { $0.name == playerName }) {
            partyState.players[idx].totalScore += score
        }
        
        multipeerService.send(.wordSubmitted(playerId: myPlayerId, word: currentWord, score: score, time: time, isValid: validation.valid))
        
        phase = .waitingForOthers
        checkAllSubmitted()
        KidsAudioManager.shared.playSuccess()
    }
    
    private func checkAllSubmitted() {
        let allPlayers = Set(multipeerService.lobbyPlayers.map { $0.id })
        let submitted = Set(submissions.keys)
        
        if allPlayers == submitted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { phase = .showingResults }
        }
    }
    
    private func startNextRound() {
        if currentRound >= totalRounds {
            multipeerService.send(.gameEnd)
            phase = .gameOver
        } else {
            currentRound += 1
            multipeerService.send(.roundEnd)
            startRound()
        }
    }
    
    private func handleMessage(_ message: PartyMultipeerMessage) {
        switch message {
        case .roundStart(let roundNumber, let rack, let bonuses):
            currentRound = roundNumber
            beginRound(rack: rack, bonuses: bonuses)
            
        case .wordSubmitted(let playerId, let word, let score, _, _):
            let playerName = multipeerService.lobbyPlayers.first { $0.id == playerId }?.name ?? playerId
            submissions[playerId] = (playerName: playerName, word: word.uppercased(), score: score)
            
            if let idx = partyState.players.firstIndex(where: { $0.name == playerName }) {
                partyState.players[idx].totalScore += score
            }
            checkAllSubmitted()
            
        case .roundEnd:
            if currentRound < totalRounds { phase = .waitingForRound }
            
        case .gameEnd:
            phase = .gameOver
            
        default:
            break
        }
    }
}

#Preview {
    KidsNetworkPartyView(gameState: KidsGameState())
}
