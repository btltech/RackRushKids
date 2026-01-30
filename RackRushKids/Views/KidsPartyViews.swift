import SwiftUI

/// Kids Party flow coordinator
struct KidsPartyCoordinator: View {
    @ObservedObject var partyState: KidsPartyGameState
    @ObservedObject var gameState: KidsGameState
    
    @State private var phase: KidsPartyPhase = .passDevice
    @Environment(\.dismiss) private var dismiss
    
    enum KidsPartyPhase {
        case passDevice
        case playing
        case roundResult
        case summary
    }
    
    var body: some View {
        ZStack {
            KidsTheme.background.ignoresSafeArea()
            
            switch phase {
            case .passDevice:
                KidsPartyPassView(partyState: partyState) {
                    partyState.startCurrentPlayerTurn()
                    phase = .playing
                }
                
            case .playing:
                KidsPartyPlayView(partyState: partyState) {
                    handleSubmission()
                }
                
            case .roundResult:
                KidsPartyRoundView(partyState: partyState) {
                    partyState.startNewRound()
                    phase = .passDevice
                }
                
            case .summary:
                KidsPartySummaryView(partyState: partyState) {
                    partyState.resetParty()
                    dismiss()
                }
            }
        }
        .onAppear {
            phase = .passDevice
            partyState.startNewRound()
        }
        .onDisappear {
            partyState.stopTimer()
        }
    }
    
    private func handleSubmission() {
        let hasMore = partyState.advanceToNextPlayer()
        
        if hasMore {
            phase = .passDevice
        } else if partyState.isPartyComplete {
            phase = .summary
        } else {
            phase = .roundResult
        }
    }
}

// MARK: - Pass Device View
struct KidsPartyPassView: View {
    @ObservedObject var partyState: KidsPartyGameState
    let onReady: () -> Void
    
    @State private var countdown: Int? = nil
    @State private var showTap = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Current player info
            if let player = partyState.currentPlayer {
                VStack(spacing: 16) {
                    Text(player.emoji)
                        .font(.system(size: 100))
                    
                    Text("Pass to")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                    
                    Text(player.name)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(player.color)
                }
            }
            
            // Countdown or tap
            if let count = countdown {
                Text("\(count)")
                    .font(.system(size: 100, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            } else if showTap {
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 50))
                        .foregroundColor(KidsTheme.textMuted)
                    Text("TAP WHEN READY!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                }
            }
            
            Spacer()
            
            // Round info
            Text("Round \(partyState.currentRound) of \(partyState.totalRounds)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .padding(.bottom, 40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) { showTap = true }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard countdown == nil else { return }
            startCountdown()
        }
    }
    
    private func startCountdown() {
        showTap = false
        countdown = 3
        KidsAudioManager.shared.playPop()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            countdown = 2
            KidsAudioManager.shared.playPop()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            countdown = 1
            KidsAudioManager.shared.playPop()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            KidsAudioManager.shared.playSuccess()
            onReady()
        }
    }
}

// MARK: - Play View
struct KidsPartyPlayView: View {
    @ObservedObject var partyState: KidsPartyGameState
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                if let player = partyState.currentPlayer {
                    HStack(spacing: 8) {
                        Text(player.emoji)
                            .font(.system(size: 28))
                        Text(player.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(player.color)
                    }
                }
                
                Spacer()
                
                // Timer
                ZStack {
                    Circle()
                        .stroke(KidsTheme.surface, lineWidth: 6)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: CGFloat(partyState.timeRemaining) / CGFloat(max(1, partyState.roundDuration)))
                        .stroke(timerColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("\(partyState.timeRemaining)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(timerColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            // Word display
            wordDisplay
            
            Spacer()

            // Shuffle (reorder only; keeps bonus tiles attached)
            VStack(spacing: 6) {
                HStack {
                    Spacer()
                    let canShuffle = partyState.selectedIndices.isEmpty && !partyState.hasSubmitted && !partyState.sharedRack.isEmpty && !partyState.isNetworkGame
                    Button(action: {
                        guard canShuffle else { return }
                        KidsAudioManager.shared.playPop()
                        HapticManager.shared.selection()
                        partyState.shuffleRack()
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
                    .accessibilityHint(partyState.isNetworkGame ? "Not available in network party" : "Reorders the letters without changing them")
                }

                if partyState.isNetworkGame {
                    Text("Shuffle is local-only")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                        .accessibilityLabel("Shuffle is local only")
                }
            }
            .padding(.horizontal, 24)
            
            // Letter rack
            letterRack
            
            // Actions
            actionButtons
        }
        .onChange(of: partyState.hasSubmitted) { _, isSubmitted in
            // Auto-advance on timer-based submissions too (not just button tap)
            if isSubmitted {
                onSubmit()
            }
        }
    }
    
    private var timerColor: Color {
        partyState.timeRemaining <= 5 ? Color(hex: "FF6B6B") : KidsTheme.accent
    }
    
    private var wordDisplay: some View {
        HStack(spacing: 10) {
            if partyState.currentWord.isEmpty {
                Text("Tap letters!")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
            } else {
                ForEach(Array(partyState.currentWord.enumerated()), id: \.offset) { _, letter in
                    Text(String(letter))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 56)
                        .background(KidsTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(height: 70)
    }
    
    private var letterRack: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: min(partyState.sharedRack.count, 5)),
            spacing: 10
        ) {
            ForEach(Array(partyState.sharedRack.enumerated()), id: \.offset) { index, letter in
                letterTile(letter: letter, index: index)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func letterTile(letter: String, index: Int) -> some View {
        let isSelected = partyState.selectedIndices.contains(index)
        let selectionOrder = partyState.selectedIndices.firstIndex(of: index).map { $0 + 1 }
        let bonusType = partyState.sharedBonuses.first(where: { $0.index == index })?.type
        
        return LetterTile(
            letter: letter,
            isSelected: isSelected,
            selectionOrder: selectionOrder,
            action: {
                KidsAudioManager.shared.playPop()
                partyState.toggleLetter(at: index)
            }
        )
        .overlay(alignment: .topLeading) {
            if let bonusType {
                Text(bonusType)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(bonusColor(for: bonusType))
                    .clipShape(Capsule())
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private func bonusColor(for type: String) -> Color {
        switch type {
        case "DL":
            return Color(hex: "4ECDC4").opacity(0.9)
        case "TL":
            return Color(hex: "A78BFA").opacity(0.9)
        case "DW":
            return Color(hex: "FF8E53").opacity(0.9)
        default:
            return KidsTheme.surface
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                KidsAudioManager.shared.playPop()
                partyState.clearWord()
            }) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Clear")
                }
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(KidsTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(KidsTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Button(action: {
                KidsAudioManager.shared.playSuccess()
                partyState.submitWord()
            }) {
                HStack {
                    Text("Done!")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(KidsTheme.playButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - Round Result
struct KidsPartyRoundView: View {
    @ObservedObject var partyState: KidsPartyGameState
    let onContinue: () -> Void
    
    var body: some View {
        let lastRound = partyState.roundHistory.last
        let roundWinners: [KidsPartyPlayer] = {
            guard let lastRound else { return [] }
            guard let maxScore = lastRound.results.values.map({ $0.score }).max() else { return [] }
            return partyState.players.filter { lastRound.results[$0.id]?.score == maxScore }
        }()
        
        let roundWinnerScore: Int? = {
            guard let lastRound else { return nil }
            return lastRound.results.values.map({ $0.score }).max()
        }()
        
        VStack(spacing: 24) {
            Spacer()
            
            Text("🎉 Round Complete!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)

            if !roundWinners.isEmpty {
                VStack(spacing: 8) {
                    if roundWinners.count == 1, let winner = roundWinners.first {
                        HStack(spacing: 10) {
                            Text("🏅")
                                .font(.system(size: 26))
                            Text("\(winner.name) wins!")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(KidsTheme.partyGradient)
                        }
                    } else {
                        Text("It's a tie!")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(KidsTheme.partyGradient)

                        Text(roundWinners.map { $0.name }.joined(separator: " & "))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(KidsTheme.textSecondary)
                    }

                    if let roundWinnerScore {
                        Text("Top score: \(roundWinnerScore)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(KidsTheme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Player results
            VStack(spacing: 12) {
                ForEach(partyState.players) { player in
                    if let result = partyState.roundHistory.last?.results[player.id] {
                        HStack {
                            Text(player.emoji)
                                .font(.system(size: 32))
                            
                            Text(player.name)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(result.word.isEmpty ? "-" : result.word)
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(result.isValid ? .white : KidsTheme.textMuted)
                            
                            Text("+\(result.score)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(KidsTheme.accent)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(16)
                        .background(KidsTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                KidsAudioManager.shared.playSuccess()
                onContinue()
            }) {
                Text("Next Round! →")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(KidsTheme.playButtonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Summary
struct KidsPartySummaryView: View {
    @ObservedObject var partyState: KidsPartyGameState
    let onDismiss: () -> Void
    
    var body: some View {
        let winners = partyState.tiedWinners
        VStack(spacing: 24) {
            Spacer()
            
            // Winner
            if winners.count == 1, let winner = winners.first {
                VStack(spacing: 16) {
                    Text("🏆")
                        .font(.system(size: 80))
                    
                    Text("WINNER!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(KidsTheme.partyGradient)
                    
                    HStack(spacing: 12) {
                        Text(winner.emoji)
                            .font(.system(size: 50))
                        Text(winner.name)
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(winner.color)
                    }
                    
                    Text("\(winner.totalScore) points!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(KidsTheme.accent)
                }
            } else if winners.count > 1 {
                VStack(spacing: 16) {
                    Text("🏆")
                        .font(.system(size: 80))
                    
                    Text("IT'S A TIE!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(KidsTheme.partyGradient)
                    
                    HStack(spacing: 18) {
                        ForEach(winners) { winner in
                            VStack(spacing: 6) {
                                Text(winner.emoji)
                                    .font(.system(size: 44))
                                
                                Text(winner.name)
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(winner.color)
                            }
                        }
                    }
                    
                    Text("\(winners.first?.totalScore ?? 0) points each!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(KidsTheme.accent)
                }
            }
            
            // All players
            VStack(spacing: 10) {
                ForEach(Array(partyState.sortedPlayers.enumerated()), id: \.element.id) { index, player in
                    HStack {
                        Text(rankEmoji(index))
                            .font(.system(size: 28))
                        
                        Text(player.emoji)
                            .font(.system(size: 24))
                        
                        Text(player.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(player.totalScore)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(KidsTheme.accent)
                    }
                    .padding(14)
                    .background(KidsTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                KidsAudioManager.shared.playSuccess()
                onDismiss()
            }) {
                Text("Play Again! 🎈")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(KidsTheme.partyGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private func rankEmoji(_ index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "⭐"
        }
    }
}

#Preview {
    let party = KidsPartyGameState()
    party.setupParty(playerNames: ["Alex", "Sam"], ageGroup: .medium, rounds: 5)
    return KidsPartyCoordinator(partyState: party, gameState: KidsGameState())
}
