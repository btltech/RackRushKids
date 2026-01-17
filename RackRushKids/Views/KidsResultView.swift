import SwiftUI
import AVFoundation

// MARK: - Round Result View
struct KidsResultView: View {
    @ObservedObject var gameState: KidsGameState
    @State private var showContent = false
    @State private var showStars = false
    @State private var scoreToShow: Int? = nil
    @State private var scorePosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: 200)
    
    var isWinner: Bool {
        gameState.roundWinner == "you" || gameState.roundWinner == "me"
    }
    
    var body: some View {
        ZStack {
            // Background handled by KidsContentView
            
            VStack(spacing: 24) {
                Spacer()
                
            
            // Result icon
            ZStack {
                if isWinner {
                    Circle()
                        .fill(KidsTheme.winGradient)
                        .frame(width: 100, height: 100)
                } else {
                    Circle()
                        .fill(KidsTheme.surface)
                        .frame(width: 100, height: 100)
                }
                
                Image(systemName: isWinner ? "star.fill" : (gameState.roundWinner == "tie" ? "equal" : "arrow.down"))
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showContent)
            
            // Result text
            Text(isWinner ? "Round Won!" : (gameState.roundWinner == "tie" ? "It's a Tie!" : "Keep Going!"))
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(KidsTheme.textPrimary)
            
            Text(gameState.encouragement)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(KidsTheme.textSecondary)
            
            Spacer()
            
            // Word comparison
            HStack(spacing: 16) {
                WordCard(
                    label: "Your Word",
                    word: gameState.lastWord,
                    score: gameState.lastWordScore,
                    isSelf: true,
                    definition: gameState.myWordDefinition
                )
                
                WordCard(
                    label: gameState.opponentName,
                    word: gameState.oppWord,
                    score: gameState.oppWordScore,
                    isSelf: false,
                    definition: gameState.oppWordDefinition
                )
            }
            .padding(.horizontal, 20)
            
            // Score summary
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("YOU")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                    Text("\(gameState.myScore)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(KidsTheme.playerSelfGradient)
                                .shadow(color: Color.orange.opacity(0.3), radius: 4)
                        )
                }
                
                Text("\(gameState.currentRound)/\(gameState.totalRounds)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
                
                VStack(spacing: 4) {
                    Text(gameState.opponentName.uppercased().prefix(6).description)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                    Text("\(gameState.oppScore)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(KidsTheme.playerOpponentGradient)
                                .shadow(color: Color.blue.opacity(0.3), radius: 4)
                        )
                }
            }
            .padding()
            .glassCard()
            
            Spacer()
            
            // Next round button
            Button(action: { gameState.nextRound() }) {
                HStack {
                    Text("Next Round")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(KidsTheme.playButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
        }
        .overlay {
            // Star burst effect on wins
            if isWinner {
                SKKidsStarBurstView(trigger: $showStars)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            // Score popup
            SKKidsScorePopView(scoreToShow: $scoreToShow, showPosition: $scorePosition)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear { 
            showContent = true
            
            // Trigger effects after a short delay
            if isWinner {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showStars = true
                    scoreToShow = gameState.lastWordScore
                }
            }
        }
        }
    }
}

// MARK: - Match Result View
struct KidsMatchResultView: View {
    @ObservedObject var gameState: KidsGameState
    @State private var showTrophy = false
    
    var isWinner: Bool {
        gameState.matchWinner == "you" || gameState.matchWinner == "me"
    }
    
    var body: some View {
        ZStack {
            // Background handled by KidsContentView
            
            VStack(spacing: 28) {
            Spacer()
            
            // Trophy / Result
            ZStack {
                if isWinner {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 20)
                    
                    Text("🏆")
                        .font(.system(size: 70))
                } else if gameState.matchWinner == "tie" {
                    Circle()
                        .fill(KidsTheme.surface)
                        .frame(width: 140, height: 140)
                    
                    Text("🤝")
                        .font(.system(size: 70))
                } else {
                    Circle()
                        .fill(KidsTheme.surface)
                        .frame(width: 140, height: 140)
                    
                    Text("💪")
                        .font(.system(size: 70))
                }
            }
            .scaleEffect(showTrophy ? 1.0 : 0.3)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: showTrophy)
            
            // New Sticker Earned Message
            if let sticker = gameState.lastEarnedSticker {
                VStack(spacing: 8) {
                    Text("NEW STICKER!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text(sticker)
                        .font(.system(size: 60))
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 80, height: 80)
                        )
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
                .padding(.top, -20)
                .onAppear {
                    KidsAudioManager.shared.playSuccess() // Play sound for sticker
                }
            }
            
            // Result text
            VStack(spacing: 8) {
                Text(isWinner ? "VICTORY!" : (gameState.matchWinner == "tie" ? "IT'S A TIE!" : "GOOD GAME!"))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        isWinner
                            ? LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [KidsTheme.textPrimary], startPoint: .leading, endPoint: .trailing)
                    )
                
                if isWinner {
                    Text("You defeated \(gameState.opponentName)!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textSecondary)
                } else if gameState.matchWinner == "tie" {
                    Text("Evenly matched!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textSecondary)
                } else {
                    Text("Practice makes perfect!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Final scores
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("YOU")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                    
                    Text("\(gameState.myScore)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(KidsTheme.playerSelfGradient)
                        )
                    
                    Text("rounds")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                }
                
                Text("vs")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
                
                VStack(spacing: 8) {
                    Text(gameState.opponentName.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                        .lineLimit(1)
                    
                    Text("\(gameState.oppScore)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(KidsTheme.playerOpponentGradient)
                        )
                    
                    Text("rounds")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                }
            }
            .padding(24)
            .glassCard()
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                if gameState.matchType == .online {
                    Button(action: {
                        gameState.requestRematch()
                    }) {
                        HStack {
                            if gameState.rematchSent && !gameState.rematchReceived {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                                Text("Waiting for Opponent...")
                            } else {
                                Image(systemName: gameState.rematchReceived ? "hand.thumbsup.fill" : "arrow.clockwise")
                                Text(gameState.rematchReceived ? "Accept Rematch!" : "Request Rematch")
                            }
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Group {
                                if gameState.rematchSent && !gameState.rematchReceived {
                                    Color.gray
                                } else {
                                    KidsTheme.playButtonGradient
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(gameState.rematchSent && !gameState.rematchReceived)
                }
 else {
                    Button(action: {
                        if let level = gameState.selectedLevel {
                            gameState.startLevel(level)
                        } else {
                            gameState.startBotMatch()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Play Again")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(KidsTheme.playButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                
                Button(action: { gameState.goToMap() }) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Back to Islands")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(KidsTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
                }
                
                Button(action: { gameState.goHome() }) {
                    Text("Settings & Home")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .overlay(
            Group {
                if isWinner {
                    SKKidsConfettiView()
                        .allowsHitTesting(false)
                }
            }
        )
        }
        .onAppear { 
            showTrophy = true 
            if isWinner {
                KidsAudioManager.shared.playWin()
            } else if gameState.matchWinner != "tie" {
                KidsAudioManager.shared.playError() // "Uh oh" for loss
            }
        }
    }
}

// MARK: - Word Card
struct WordCard: View {
    let label: String
    let word: String
    let score: Int
    let isSelf: Bool
    var definition: String? = nil
    @ObservedObject private var ttsService = KidsTTSService.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
            
            // Word with pronunciation button
            HStack(spacing: 8) {
                Text(word.isEmpty ? "-" : word.uppercased())
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                // Pronunciation button (ear/speaker icon)
                if !word.isEmpty {
                    Button(action: { ttsService.speak(word) }) {
                        Image(systemName: ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(6)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .disabled(ttsService.isSpeaking)
                }
            }
            
            Text("\(score) pts")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if let def = definition {
                Text(def)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelf ? KidsTheme.playerSelfGradient : KidsTheme.playerOpponentGradient)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
    }
}

#Preview {
    ZStack {
        KidsTheme.backgroundGradient.ignoresSafeArea()
        KidsResultView(gameState: {
            let state = KidsGameState()
            state.lastWord = "CAT"
            state.lastWordScore = 5
            state.oppWord = "DOG"
            state.oppWordScore = 5
            state.roundWinner = "you"
            state.encouragement = "Brilliant! 🎯"
            state.myScore = 2
            state.oppScore = 1
            return state
        }())
    }
}
