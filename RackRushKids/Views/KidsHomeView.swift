import SwiftUI

struct KidsHomeView: View {
    @ObservedObject var gameState: KidsGameState
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background (matching adult app)
            KidsTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Ambient Particles (Design Improvement)
            AmbientParticlesView(
                count: 15, // Fewer, larger particles for kids
                colors: [
                    Color.white,
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.3),
                    Color(hex: "FFD700").opacity(0.3) // Gold sparkles
                ]
            )
            .ignoresSafeArea()
            .blendMode(.overlay)
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    
                    // Settings button
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
                
                Spacer()
                
                // Logo (matching adult style)
                VStack(spacing: 12) {
                    VStack(spacing: -6) {
                        Text("WORD")
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
                    .shimmer(duration: 3, delay: 1) // Added shimmer effect
                    
                    // Subtitle
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
                
                // Connection status
                HStack(spacing: 8) {
                    Circle()
                        .fill(gameState.isConnected ? Color.green : Color.blue)
                        .frame(width: 8, height: 8)
                    
                    Text(gameState.isConnected ? "Online" : "Offline Ready")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(KidsTheme.surface)
                .clipShape(Capsule())
                .padding(.top, 20)
                
                Spacer()
                
                // Age Group Selector
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
                
                Spacer()
                
                // Menu buttons (matching adult style)
                VStack(spacing: 14) {
                    // Play Online
                    MenuButton(
                        label: "PLAY ONLINE",
                        icon: "globe",
                        gradient: KidsTheme.playButtonGradient,
                        isEnabled: gameState.isConnected,
                        action: { gameState.startOnlineMatch() }
                    )
                    
                    // Word Islands (Map)
                    MenuButton(
                        label: "WORD ISLANDS",
                        icon: "map.fill",
                        gradient: LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        isEnabled: true,
                        action: { gameState.screen = .map }
                    )
                    
                    // Practice (Legacy or Quick Play)
                    /*
                    MenuButton(
                        label: "PRACTICE",
                        icon: "cpu",
                        gradient: LinearGradient(
                            colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        isEnabled: true,
                        action: { gameState.startBotMatch() }
                    )
                    */
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(buttonsOpacity)
            }
        }
        .onAppear {
            // Connect on appear
            gameState.connect()
            
            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                buttonsOpacity = 1.0
            }
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
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            )
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
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .tracking(1)
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

#Preview {
    KidsHomeView(gameState: KidsGameState())
}
