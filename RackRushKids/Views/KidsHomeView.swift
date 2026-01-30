import SwiftUI

struct KidsHomeView: View {
    @ObservedObject var gameState: KidsGameState
    @StateObject private var streakManager = KidsStreakManager.shared
    @StateObject private var wotdManager = KidsWordOfTheDayManager.shared
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var showPersonaPicker = false
    @State private var showAvatarPicker = false
    @State private var showBadges = false
    
    var body: some View {
        ZStack {
            // Background handled by KidsContentView
            
            // GPU-accelerated ambient particles (SpriteKit Kids Mode)
            SKAmbientParticlesView(isKidsMode: true)
                .ignoresSafeArea()
            
            // Floating balloons with sparkles - tap balloons to pop, tap elsewhere for sparkles!
            SKBalloonView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with streak and avatar
                HomeTopBar(gameState: gameState, showAvatarPicker: $showAvatarPicker, showBadges: $showBadges)
                
                // Streak badge
                if streakManager.currentStreak > 0 {
                    StreakBadge()
                        .padding(.top, 8)
                }
                
                Spacer()
                
                // Logo (matching adult style)
                LogoView(logoScale: logoScale, logoOpacity: logoOpacity)
                
                // Connection status
                ConnectionStatusView(isConnected: gameState.isConnected)
                
                // Word of the Day card (collapsed)
                WordOfTheDayCard()
                    .padding(.top, 16)
                
                Spacer()
                
                // Age Group Selector
                AgeGroupSelector(gameState: gameState)
                
                Spacer()
                
                // Menu buttons (matching adult style)
                MenuSection(gameState: gameState, buttonsOpacity: buttonsOpacity)
            }
            
            // Sticker Notification Overlay
            if let sticker = gameState.lastEarnedSticker {
                StickerToast(sticker: sticker)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
            
            // Streak celebration overlay
            StreakCelebration()
            
            // Word of the Day popup (on first launch of day)
            WordOfTheDayPopup()
            
            // New badge popup
            NewBadgePopup()
        }
        .sheet(isPresented: $showPersonaPicker) {
            PersonaPickerSheet(gameState: gameState)
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerView()
        }
        .sheet(isPresented: $showBadges) {
            BadgeCollectionView()
        }
        .onAppear {
            // Connect on appear
            gameState.connect()
            
            // Start session tracking
            KidsStatsManager.shared.startSession()
            
            // Check word of the day
            wotdManager.checkForNewWord()
            
            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                buttonsOpacity = 1.0
            }
        }
        .onDisappear {
            KidsStatsManager.shared.endSession()
        }
    }
}

// MARK: - Home Top Bar with Avatar and Badges
struct HomeTopBar: View {
    @ObservedObject var gameState: KidsGameState
    @ObservedObject var avatarManager = KidsAvatarManager.shared
    @Binding var showAvatarPicker: Bool
    @Binding var showBadges: Bool
    
    var body: some View {
        HStack {
            // Avatar button
            Button(action: { showAvatarPicker = true }) {
                Text(avatarManager.selectedAvatar.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(KidsTheme.surface)
                    .clipShape(Circle())
            }
            
            // Badges button
            Button(action: { showBadges = true }) {
                HStack(spacing: 4) {
                    Text("🏅")
                        .font(.system(size: 16))
                    Text("\(KidsBadgeManager.shared.unlockedBadgeIds.count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KidsTheme.surface)
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Hint coins
            HintCoinBadge()
            
            Button(action: { gameState.screen = .settings }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(KidsTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(KidsTheme.surface)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

// MARK: - Sub-views for KidsHomeView (Legacy TopBar removed)
struct TopBar: View {
    @ObservedObject var gameState: KidsGameState
    var body: some View {
        HStack {
            Spacer()
            Button(action: { gameState.screen = .settings }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(KidsTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(KidsTheme.surface)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

struct LogoView: View {
    let logoScale: CGFloat
    let logoOpacity: Double
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: -6) {
                Text("RACK")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 20, y: 8)
                
                Text("RUSH")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00d2ff"), Color(hex: "3a7bd5")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "3a7bd5").opacity(0.4), radius: 20, y: 8)
            }
            .shimmer(duration: 3, delay: 1)
            
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "FFD700"))
                Text("KIDS EDITION")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(KidsTheme.textSecondary)
                    .tracking(4)
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "FFD700"))
            }
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }
}

struct ConnectionStatusView: View {
    let isConnected: Bool
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? Color.green : Color.blue)
                .frame(width: 8, height: 8)
            Text(isConnected ? "Online" : "Offline Ready")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(KidsTheme.surface)
        .clipShape(Capsule())
        .padding(.top, 20)
    }
}

struct AgeGroupSelector: View {
    @ObservedObject var gameState: KidsGameState
    var body: some View {
        VStack(spacing: 12) {
            Text("SELECT YOUR AGE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(2)
            HStack(spacing: 10) {
                ForEach(KidsAgeGroup.allCases, id: \.self) { age in
                    AgeGroupButton(
                        ageGroup: age,
                        isSelected: gameState.ageGroup == age.rawValue,
                        action: { gameState.ageGroup = age.rawValue }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct MenuSection: View {
    @ObservedObject var gameState: KidsGameState
    let buttonsOpacity: Double
    var body: some View {
        VStack(spacing: 12) {
            // Primary action
            MenuButton(
                label: "PLAY ONLINE",
                icon: "globe",
                gradient: KidsTheme.playButtonGradient,
                isEnabled: gameState.onlinePlayAllowed,
                action: { gameState.startOnlineMatch() }
            )
            
            // Secondary row: Word Islands + Party Time
            HStack(spacing: 12) {
                MenuButtonCompact(
                    label: "ISLANDS",
                    icon: "map.fill",
                    gradient: LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    action: { gameState.screen = .map }
                )
                
                MenuButtonCompact(
                    label: "PARTY!",
                    icon: "person.3.fill",
                    gradient: KidsTheme.partyGradient,
                    action: { gameState.screen = .partySetup }
                )
            }
            
            DailyChallengeCard(gameState: gameState)
                .padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .opacity(buttonsOpacity)
    }
}

// Compact button for side-by-side layout
struct MenuButtonCompact: View {
    let label: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            KidsAudioManager.shared.playNavigation()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.2), radius: 6, y: 3)
        }
    }
}

// MARK: - Age Group Button
struct AgeGroupButton: View {
    let ageGroup: KidsAgeGroup
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            KidsAudioManager.shared.playNavigation()
            action()
        }) {
            VStack(spacing: 4) {
                Text(ageGroup.rawValue)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : KidsTheme.textSecondary)
                
                Text("\(ageGroup.letterCount) letters")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : KidsTheme.textMuted)
            }
            .frame(width: 95, height: 60)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(KidsTheme.playButtonGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(KidsTheme.surface)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color(hex: "667eea").opacity(0.5) : .clear, radius: 8, y: 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Menu Button (matching adult style)
struct MenuButton: View {
    let label: String
    let icon: String
    let gradient: LinearGradient
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            KidsAudioManager.shared.playNavigation()
            action()
        }) {
            HStack(spacing: 12) {
                // Show lock icon when disabled
                if !isEnabled {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .semibold))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .tracking(1)
                    
                    // Show parent-only hint when disabled
                    if !isEnabled {
                        Text("Parent Only")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .opacity(0.7)
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Queued View
struct KidsQueuedView: View {
    @ObservedObject var gameState: KidsGameState
    @State private var rotation = 0.0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Spinner
            ZStack {
                Circle()
                    .stroke(KidsTheme.surface, lineWidth: 6)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(KidsTheme.playButtonGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(rotation))
            }
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            VStack(spacing: 8) {
                Text("Finding opponent...")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(KidsTheme.textPrimary)
                
                Text("\(gameState.queueTime)s")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(KidsTheme.textMuted)
            }
            
            Spacer()
            
            Button(action: { gameState.cancelQueue() }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(KidsTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Persona Picker Sheet
struct PersonaPickerSheet: View {
    @ObservedObject var gameState: KidsGameState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            PersonaPickerContent(gameState: gameState, dismiss: { dismiss() })
                .navigationTitle("Character Practice")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") { dismiss() }
                            .foregroundColor(KidsTheme.textPrimary)
                    }
                }
        }
    }
}

struct PersonaPickerContent: View {
    @ObservedObject var gameState: KidsGameState
    let dismiss: () -> Void
    
    var body: some View {
        ZStack {
            KidsTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("CHOOSING AN OPPONENT")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                        .tracking(2)
                        .padding(.top, 20)
                    
                    ForEach(KidsGameState.botPersonas) { persona in
                        PersonaButton(persona: persona, gameState: gameState, dismiss: dismiss)
                    }
                }
                .padding(20)
            }
        }
    }
}

struct PersonaButton: View {
    let persona: BotPersona
    @ObservedObject var gameState: KidsGameState
    let dismiss: () -> Void
    
    var body: some View {
        Button(action: {
            gameState.startBotMatch(persona: persona)
            dismiss()
        }) {
            HStack(spacing: 20) {
                Text(persona.icon)
                    .font(.system(size: 50))
                    .frame(width: 80, height: 80)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(persona.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(KidsTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}
// MARK: - Daily Challenge Card
struct DailyChallengeCard: View {
    @ObservedObject var gameState: KidsGameState
    
    var body: some View {
        Button(action: {
            if !gameState.hasCompletedDaily {
                gameState.startDailyChallenge()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DAILY GOAL")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(KidsTheme.textMuted)
                            .tracking(2)
                        
                        Text(gameState.hasCompletedDaily ? "Challenge Done! ✨" : "Today's Secret Letters")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Sticker reward hint
                        if !gameState.hasCompletedDaily {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "FFD700"))
                                Text("Earn a sticker when complete!")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: "FFD700").opacity(0.8))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Progress ring or completion checkmark
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 50, height: 50)
                        
                        if gameState.hasCompletedDaily {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 50, height: 50)
                            Image(systemName: "checkmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .trim(from: 0, to: 0.0) // 0% progress before playing
                                .stroke(KidsTheme.playButtonGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                            Text("🎁")
                                .font(.system(size: 24))
                        }
                    }
                }
                
                if !gameState.hasCompletedDaily {
                    // Letter preview
                    HStack(spacing: 8) {
                        ForEach(gameState.todayDailyChallenge?.letters ?? [], id: \.self) { letter in
                            Text(letter)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        Spacer()
                        
                        // Play hint
                        Text("TAP TO PLAY")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(gameState.hasCompletedDaily ? Color.green.opacity(0.15) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(gameState.hasCompletedDaily ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .disabled(gameState.hasCompletedDaily)
        .opacity(gameState.hasCompletedDaily ? 0.9 : 1.0)
    }
}

// MARK: - Sticker Toast
struct StickerToast: View {
    let sticker: String
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                Text(sticker)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEW STICKER!")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "FFD700"))
                    
                    Text("Added to your Sticker Book")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.85))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
            .padding(.top, 60)
            
            Spacer()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Community Goal View
struct CommunityGoalView: View {
    @ObservedObject var communityManager = KidsCommunityManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .foregroundColor(Color(hex: "00d2ff"))
            
            Text("KIDS FOUND")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(1)
            
            Text(communityManager.formattedCount)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            Text("WORDS TODAY! 🌟")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }
}

#Preview {
    KidsHomeView(gameState: KidsGameState())
}
