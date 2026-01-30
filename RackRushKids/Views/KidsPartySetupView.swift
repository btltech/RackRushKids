import SwiftUI

/// Kids Party Setup - Pick players and start the party!
struct KidsPartySetupView: View {
    @ObservedObject var gameState: KidsGameState
    @StateObject private var partyState = KidsPartyGameState()
    
    @State private var playerCount: Int = 2
    @State private var playerNames: [String] = ["", "", "", ""]
    @State private var selectedRounds: Int = 5
    @State private var showingGame = false
    @State private var partySessionId = UUID()
    
    var body: some View {
        ZStack {
            // Fun gradient background
            KidsTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                headerSection
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Player count
                        playerCountSection
                        
                        // Player names with emojis
                        playerNamesSection
                        
                        // Rounds
                        roundsSection
                        
                        // Start button
                        startButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showingGame) {
            KidsPartyCoordinator(partyState: partyState, gameState: gameState)
                .id(partySessionId)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { gameState.screen = .home }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Home")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(KidsTheme.textSecondary)
                }
                .minimumTouchTarget()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            Text("🎈")
                .font(.system(size: 70))
            
            Text("PARTY TIME!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(KidsTheme.partyGradient)
            
            Text("Pass the device to play!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
            
            // Network mode button
            Button(action: {
                guard gameState.onlinePlayAllowed else {
                    gameState.screen = .settings
                    return
                }
                gameState.screen = .networkParty
            }) {
                HStack(spacing: 8) {
                    Image(systemName: gameState.onlinePlayAllowed ? "wifi" : "lock.fill")
                    Text(gameState.onlinePlayAllowed ? "Play on Different Devices!" : "Play on Different Devices (Parent Only)")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(KidsTheme.accent.opacity(0.15))
                .clipShape(Capsule())
            }
            .disabled(!gameState.onlinePlayAllowed)
            .opacity(gameState.onlinePlayAllowed ? 1.0 : 0.6)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Player Count
    
    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW MANY FRIENDS?")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
            
            HStack(spacing: 16) {
                ForEach(2...4, id: \.self) { count in
                    Button(action: {
                        playerCount = count
                        KidsAudioManager.shared.playPop()
                    }) {
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text("Players")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(playerCount == count ? .white : KidsTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(playerCount == count ? AnyShapeStyle(KidsTheme.playButtonGradient) : AnyShapeStyle(KidsTheme.surface))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Player Names
    
    private var playerNamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLAYER NAMES")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
            
            VStack(spacing: 12) {
                ForEach(0..<playerCount, id: \.self) { index in
                    HStack(spacing: 12) {
                        // Emoji avatar
                        Text(KidsPartyGameState.playerEmojis[index])
                            .font(.system(size: 36))
                            .frame(width: 50, height: 50)
                            .background(Color(hex: KidsPartyGameState.playerColors[index]).opacity(0.3))
                            .clipShape(Circle())
                        
                        // Name input
                        TextField("Player \(index + 1)", text: $playerNames[index])
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(KidsTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }
    
    // MARK: - Rounds
    
    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ROUNDS")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
            
            HStack(spacing: 14) {
                Button(action: {
                    selectedRounds = max(5, selectedRounds - 1)
                    KidsAudioManager.shared.playPop()
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 60)
                        .background(KidsTheme.surface.opacity(selectedRounds <= 5 ? 0.5 : 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedRounds <= 5)
                
                Text("\(selectedRounds)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 90, height: 60)
                    .background(KidsTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                Button(action: {
                    selectedRounds = min(15, selectedRounds + 1)
                    KidsAudioManager.shared.playPop()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 60)
                        .background(KidsTheme.surface.opacity(selectedRounds >= 15 ? 0.5 : 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedRounds >= 15)
                
                Text("games")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(KidsTheme.textSecondary)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button(action: startParty) {
            HStack(spacing: 12) {
                Text("🎉")
                    .font(.system(size: 28))
                Text("LET'S PLAY!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(KidsTheme.partyGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color(hex: "FF6B6B").opacity(0.4), radius: 10, y: 5)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Actions
    
    private func startParty() {
        KidsAudioManager.shared.playSuccess()
        partySessionId = UUID()
        partyState.resetParty()
        
        let names = (0..<playerCount).map { idx in
            playerNames[idx].isEmpty ? "Player \(idx + 1)" : playerNames[idx]
        }
        
        partyState.setupParty(
            playerNames: names,
            ageGroup: KidsAgeGroup(rawValue: gameState.ageGroup) ?? .medium,
            rounds: selectedRounds
        )
        
        showingGame = true
    }
}

#Preview {
    KidsPartySetupView(gameState: KidsGameState())
}
