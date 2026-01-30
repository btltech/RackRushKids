import SwiftUI

struct IslandNode: View {
    let level: LevelDef
    let isUnlocked: Bool
    let isNext: Bool
    let isAgeGroupMatch: Bool  // True if player's age group matches this island's age group
    let starCount: Int  // 0-3 stars earned
    let action: () -> Void
    
    @State private var pulsing = false
    @State private var microAnimationPhase: CGFloat = 0
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Island Icon with micro-animations
                ZStack {
                    // Micro-animation layer (behind the circle)
                    microAnimationLayer
                    
                    Circle()
                        .fill(islandColor.gradient)
                        .frame(width: IslandConfig.nodeSize, height: IslandConfig.nodeSize)
                        .shadow(color: islandColor.opacity(0.3), radius: 5, x: 0, y: 5)
                    
                    if isUnlocked && isAgeGroupMatch {
                        Image(systemName: level.islandIcon)
                            .font(.system(size: IslandConfig.iconSize, weight: .bold))
                            .foregroundColor(.white)
                    } else if !isAgeGroupMatch {
                        // Wrong age group - show age indicator
                        Text(level.ageGroup.rawValue)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: IslandConfig.iconSize, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Selection indicator
                    if isNext && isAgeGroupMatch {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 4)
                            .frame(width: IslandConfig.pulseSize, height: IslandConfig.pulseSize)
                            .scaleEffect(pulsing ? 1.1 : 1.0)
                    }
                    
                    // Star rating overlay (bottom-right)
                    if starCount > 0 && isAgeGroupMatch {
                        starRatingBadge
                            .offset(x: 30, y: 30)
                    }
                }
                
                // Level Name
                Text(level.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(isUnlocked && isAgeGroupMatch ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.2))
                    )
                
                // Unlock requirement or "Tap to play!" hint
                if !isAgeGroupMatch {
                    Text(ageGroupMessage)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.orange.opacity(0.8))
                        .multilineTextAlignment(.center)
                } else if isNext && isUnlocked {
                    Text("Tap to play!")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "FFD700"))
                } else if !isUnlocked {
                    Text(unlockRequirement)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .disabled(!isUnlocked || !isAgeGroupMatch)
        .opacity(isAgeGroupMatch ? (isUnlocked || isNext ? 1.0 : 0.6) : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isUnlocked && isAgeGroupMatch ? .isButton : [])
        .onAppear {
            if isNext && isAgeGroupMatch {
                withAnimation(.easeInOut(duration: IslandConfig.pulseDuration).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
            // Start micro-animation
            if isUnlocked && isAgeGroupMatch {
                withAnimation(.easeInOut(duration: IslandConfig.microAnimationDuration).repeatForever(autoreverses: true)) {
                    microAnimationPhase = 1
                }
            }
        }
    }
    
    // MARK: - Star Rating Badge
    @ViewBuilder
    private var starRatingBadge: some View {
        HStack(spacing: 2) {
            ForEach(0..<IslandConfig.maxStars, id: \.self) { index in
                Image(systemName: index < starCount ? "star.fill" : "star")
                    .font(.system(size: IslandConfig.starSize, weight: .bold))
                    .foregroundColor(index < starCount ? Color(hex: "FFD700") : .white.opacity(0.3))
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
        )
    }
    
    // MARK: - Micro-animation Layer
    @ViewBuilder
    private var microAnimationLayer: some View {
        switch level.islandIcon {
        case "water.waves", "drop.fill":
            // Wave animation
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: IslandConfig.nodeSize + 10, height: IslandConfig.nodeSize + 10)
                .scaleEffect(1.0 + Double(microAnimationPhase) * 0.1)
                .opacity(1.0 - Double(microAnimationPhase) * 0.5)
            
        case "snowflake":
            // Sparkle animation
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: CGFloat.random(in: -30...30),
                        y: -40 + microAnimationPhase * 20 + CGFloat(i) * 15
                    )
            }
            
        case "mountain.2.fill", "cloud.fill":
            // Floating cloud
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 20, height: 12)
                .offset(x: -20 + microAnimationPhase * 10, y: -45)
            
        case "flame.fill":
            // Flickering glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: IslandConfig.nodeSize + 20, height: IslandConfig.nodeSize + 20)
                .scaleEffect(1.0 + Double(microAnimationPhase) * 0.15)
                
        case "sparkles", "star.fill", "wand.and.stars":
            // Twinkling stars
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 8))
                    .foregroundColor(.yellow.opacity(0.6 + Double(microAnimationPhase) * 0.4))
                    .offset(
                        x: cos(Double(i) * .pi / 2) * 45,
                        y: sin(Double(i) * .pi / 2) * 45
                    )
                    .scaleEffect(0.8 + Double(microAnimationPhase) * 0.4)
            }
            
        default:
            EmptyView()
        }
    }
    
    private var unlockRequirement: String {
        let trackIndex = KidsGameState.trackIndex(for: level)
        let winsNeeded = trackIndex - 1
        if winsNeeded == 1 {
            return "Win 1 game to unlock"
        } else {
            return "Win \(winsNeeded) games to unlock"
        }
    }
    
    private var ageGroupMessage: String {
        switch level.ageGroup {
        case .young:
            return "For ages 4-6 🌟"
        case .medium:
            return "For ages 7-9 ⭐"
        case .older:
            return "For ages 10-12 🚀"
        }
    }
    
    private var islandColor: Color {
        if !isAgeGroupMatch {
            return Color.gray.opacity(0.7)
        } else if isUnlocked {
            switch level.ageGroup {
            case .young: return Color.green
            case .medium: return Color.blue
            case .older: return Color.purple
            }
        } else {
            return Color.gray
        }
    }
    
    // MARK: - Accessibility
    private var accessibilityLabel: String {
        var label = level.name
        if isUnlocked && isAgeGroupMatch {
            if starCount > 0 {
                label += ", \(starCount) of 3 stars"
            }
            label += ", unlocked"
        } else if !isAgeGroupMatch {
            label += ", \(ageGroupMessage)"
        } else {
            label += ", locked"
        }
        return label
    }
    
    private var accessibilityHint: String {
        if isUnlocked && isAgeGroupMatch {
            return isNext ? "Double tap to play this level" : "Double tap to replay"
        } else if !isAgeGroupMatch {
            return "Switch age group in settings to play"
        } else {
            return unlockRequirement
        }
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        HStack(spacing: 40) {
            IslandNode(level: KidsGameState.levels[0], isUnlocked: true, isNext: false, isAgeGroupMatch: true, starCount: 3, action: {})
            IslandNode(level: KidsGameState.levels[1], isUnlocked: true, isNext: true, isAgeGroupMatch: true, starCount: 1, action: {})
            IslandNode(level: KidsGameState.levels[3], isUnlocked: false, isNext: false, isAgeGroupMatch: false, starCount: 0, action: {})
        }
    }
}

