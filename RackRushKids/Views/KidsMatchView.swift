import SwiftUI

struct KidsMatchView: View {
    @ObservedObject var gameState: KidsGameState
    @State private var showTutorial = false
    
    var body: some View {
        ZStack {
            // Background handled by KidsContentView
            
            VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: { gameState.goHome() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(KidsTheme.textMuted)
                        .frame(width: 36, height: 36)
                        .background(KidsTheme.surface)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Score display
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
                
                Spacer()
                
                // Spacer for balance
                Color.clear.frame(width: 36, height: 36)
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
            }
        )
        .onAppear {
            if !gameState.hasSeenTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTutorial = true
                    gameState.hasSeenTutorial = true
                }
            }
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
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Text(letter.uppercased())
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(KidsTheme.tileColor(for: letter))
                            .shadow(color: KidsTheme.tileColor(for: letter).opacity(0.5), radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .scaleEffect(isSelected ? 0.92 : 1.0)
                
                // Selection order badge
                if let order = selectionOrder {
                    Text("\(order)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                        .offset(x: 22, y: -22)
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
