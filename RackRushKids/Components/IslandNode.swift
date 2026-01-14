import SwiftUI

struct IslandNode: View {
    let level: LevelDef
    let isUnlocked: Bool
    let isNext: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Island Icon
                ZStack {
                    Circle()
                        .fill(islandColor.gradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: islandColor.opacity(0.3), radius: 5, x: 0, y: 5)
                    
                    if isUnlocked {
                        Image(systemName: level.islandIcon)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Selection indicator
                    if isNext {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 4)
                            .frame(width: 90, height: 90)
                            .scaleEffect(pulsing ? 1.1 : 1.0)
                    }
                }
                
                // Level Name
                Text(level.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.2))
                    )
            }
        }
        .disabled(!isUnlocked)
        .opacity(isUnlocked || isNext ? 1.0 : 0.6)
        .onAppear {
            if isNext {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
        }
    }
    
    @State private var pulsing = false
    
    private var islandColor: Color {
        if isUnlocked {
            switch level.ageGroup {
            case .young: return Color.green
            case .medium: return Color.blue
            case .older: return Color.purple
            }
        } else {
            return Color.gray
        }
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        HStack(spacing: 40) {
            IslandNode(level: KidsGameState.levels[0], isUnlocked: true, isNext: false, action: {})
            IslandNode(level: KidsGameState.levels[1], isUnlocked: false, isNext: true, action: {})
        }
    }
}
