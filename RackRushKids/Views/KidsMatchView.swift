import SwiftUI

struct KidsMatchView: View {
    @ObservedObject var gameState: KidsGameState
    @State private var showTutorial = false
    
    var body: some View {
        ZStack {
            // Background handled by KidsContentView
            
            VStack(spacing: 16) {
            // Header
                ZStack {
                    // Centered score display
                    HStack(spacing: 12) {
                        ScoreDisplay(label: "YOU", score: gameState.myScore, isSelf: true)
                        
                        VStack(spacing: 2) {
                            Text("ROUND")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(KidsTheme.textMuted)
                            Text("\(gameState.currentRound)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(KidsTheme.textPrimary)
                        }
                        .frame(width: 50)
                        
                        ScoreDisplay(label: gameState.opponentName.uppercased(), score: gameState.oppScore, isSelf: false)
                    }
                    
                    // Back to home (matches adult style)
                    HStack {
                        Button(action: {
                            KidsAudioManager.shared.playTap()
                            gameState.goHome()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Home")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(KidsTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(KidsTheme.surface)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        }
                        
                        Spacer()
                        
                        // Pause button (bot matches only)
                        if gameState.matchType == .bot {
                            Button(action: {
                                gameState.pauseGame()
                            }) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(KidsTheme.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(KidsTheme.surface)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            
            // Timer
            ZStack {
                Circle()
                    .stroke(KidsTheme.surface, lineWidth: 8)
                    .frame(width: 90, height: 90)
                
                Circle()
                    .trim(from: 0, to: CGFloat(gameState.timeRemaining) / CGFloat(gameState.selectedAgeGroup.timerSeconds))
                    .stroke(
                        gameState.timeRemaining <= 10
                            ? LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing)
                            : KidsTheme.playButtonGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: gameState.timeRemaining)
                
                Text("\(gameState.timeRemaining)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(gameState.timeRemaining <= 10 ? .red : KidsTheme.textPrimary)
            }
            
            // Built word display
            HStack(spacing: 6) {
                if gameState.currentWord.isEmpty {
                    Text("Tap letters to build a word")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                } else {
                    ForEach(Array(gameState.currentWord.enumerated()), id: \.offset) { idx, char in
                        Text(String(char).uppercased())
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 48)
                            .background(KidsTheme.tileColor(for: String(char)))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: KidsTheme.tileColor(for: String(char)).opacity(0.4), radius: 4, y: 2)
                    }
                }
            }
            .frame(height: 56)
            .animation(.spring(response: 0.2), value: gameState.currentWord)
            
            // Rejection message
            if gameState.wordRejected {
                Text(gameState.rejectionMessage)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Opponent status
            if gameState.opponentSubmitted && !gameState.hasSubmitted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(gameState.opponentName) submitted!")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(KidsTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Spacer()
            
            // Shuffle (reorder only)
            HStack {
                Spacer()
                let canShuffle = gameState.selectedIndices.isEmpty && !gameState.hasSubmitted && !gameState.letters.isEmpty
                Button(action: {
                    guard canShuffle else { return }
                    KidsAudioManager.shared.playPop()
                    HapticManager.shared.selection()
                    gameState.shuffleRack()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Shuffle")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(KidsTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(KidsTheme.surface)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                }
                .disabled(!canShuffle)
                .opacity(canShuffle ? 1 : 0.45)
                .accessibilityLabel("Shuffle letters")
                .accessibilityHint("Reorders the letters without changing them")
            }
            .padding(.horizontal, 24)

            // Letter tiles
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: min(gameState.letters.count, 5)),
                spacing: 10
            ) {
                ForEach(Array(gameState.letters.enumerated()), id: \.offset) { index, letter in
                    LetterTile(
                        letter: letter,
                        isSelected: gameState.selectedIndices.contains(index),
                        selectionOrder: gameState.selectedIndices.firstIndex(of: index).map { $0 + 1 },
                        action: { 
                            KidsAudioManager.shared.playPop()
                            HapticManager.shared.selection()
                            gameState.selectLetter(at: index) 
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 14) {
                Button(action: { 
                    KidsAudioManager.shared.playDelete()
                    gameState.clearWord() 
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Clear")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(KidsTheme.textSecondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(KidsTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Button(action: { 
                    KidsAudioManager.shared.playSubmit()
                    HapticManager.shared.impact(style: .medium)
                    gameState.submitWord()
                }) {

                    HStack(spacing: 6) {
                        Text(gameState.hasSubmitted ? "Waiting..." : "Submit")
                        if !gameState.hasSubmitted {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        gameState.currentWord.count >= 2 && !gameState.hasSubmitted
                            ? KidsTheme.playButtonGradient
                            : LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(gameState.currentWord.count < 2 || gameState.hasSubmitted)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .padding(.top, 8)
        .padding(.top, 8)
        .overlay(
            Group {
                if showTutorial {
                    KidsTutorialOverlay(isShowing: $showTutorial)
                }
                
                if gameState.isOpponentReconnecting {
                    KidsReconnectionOverlay(timeRemaining: gameState.reconnectionTimeRemaining)
                }
                
                if gameState.isPaused {
                    KidsPauseOverlay(gameState: gameState)
                }
            }
        )
        .onAppear {
            // Keep screen awake during gameplay
            UIApplication.shared.isIdleTimerDisabled = true
            
            if !gameState.hasSeenTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTutorial = true
                    gameState.hasSeenTutorial = true
                }
            }
        }
        .onDisappear {
            // Re-enable screen sleep when leaving match
            UIApplication.shared.isIdleTimerDisabled = false
        }
        }
    }
}

// MARK: - Score Display
struct ScoreDisplay: View {
    let label: String
    let score: Int
    let isSelf: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            if !isSelf {
                Text("\(score)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(label.prefix(8).description)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.2))
                .clipShape(Capsule())
            
            if isSelf {
                Text("\(score)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isSelf ? KidsTheme.playerSelfGradient : KidsTheme.playerOpponentGradient)
                .shadow(color: (isSelf ? Color.orange : Color.blue).opacity(0.3), radius: 6, y: 3)
        )
    }
}

// MARK: - Letter Tile
struct LetterTile: View {
    let letter: String
    let isSelected: Bool
    let selectionOrder: Int?
    let action: () -> Void
    var tileSize: CGFloat? = nil  // Optional - auto-calculates if nil
    
    // Calculate responsive tile size based on screen width
    private var size: CGFloat {
        if let tileSize { return tileSize }
        let screenWidth = UIScreen.main.bounds.width
        // Scale: iPhone SE = 64, iPhone Pro Max = 80, iPad = 100
        return min(max(screenWidth * 0.16, 64), 100)
    }
    
    private var fontSize: CGFloat {
        size * 0.5  // Font is half the tile size
    }
    
    private var cornerRadius: CGFloat {
        size * 0.22
    }
    
    private var badgeOffset: CGFloat {
        size * 0.34
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Text(letter.uppercased())
                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: size, height: size)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(KidsTheme.tileColor(for: letter))
                            .shadow(color: KidsTheme.tileColor(for: letter).opacity(0.5), radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .scaleEffect(isSelected ? 0.92 : 1.0)
                
                // Selection order badge
                if let order = selectionOrder {
                    Text("\(order)")
                        .font(.system(size: size * 0.17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: size * 0.31, height: size * 0.31)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                        .offset(x: badgeOffset, y: -badgeOffset)
                }
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
    }
}

#Preview {
    ZStack {
        KidsTheme.backgroundGradient.ignoresSafeArea()
        KidsMatchView(gameState: {
            let state = KidsGameState()
            state.letters = ["C", "A", "T", "S", "D", "O"]
            state.currentWord = "CAT"
            state.selectedIndices = [0, 1, 2]
            return state
        }())
    }
}

struct KidsReconnectionOverlay: View {
    let timeRemaining: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("✋")
                    .font(.system(size: 80))
                    .shadow(color: .orange.opacity(0.5), radius: 20)
                
                VStack(spacing: 8) {
                    Text("Friend Disconnected")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Waiting for them to come back...")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    if #available(iOS 16.0, *) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .contentTransition(.numericText())
                    } else {
                        Text("\(timeRemaining)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.top, 12)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "2D1B69")) // Deep purple
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30)
            )
        }
        .transition(.opacity)
        .zIndex(100)
    }
}

// MARK: - Pause Overlay
struct KidsPauseOverlay: View {
    @ObservedObject var gameState: KidsGameState
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Pause icon
                ZStack {
                    Circle()
                        .fill(KidsTheme.playButtonGradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: Color(hex: "667eea").opacity(0.5), radius: 20)
                    
                    Image(systemName: "pause.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 12) {
                    Text("PAUSED")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Take a break! 😊")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                VStack(spacing: 16) {
                    // Resume button
                    Button(action: {
                        gameState.resumeGame()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("RESUME")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(KidsTheme.playButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
                    }
                    
                    // Quit button
                    Button(action: {
                        gameState.isPaused = false
                        gameState.goHome()
                    }) {
                        Text("Quit to Home")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(KidsTheme.textMuted)
                            .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "2D1B69")) // Deep purple
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30)
            )
        }
        .transition(.opacity)
        .zIndex(101)
    }
}
