import SwiftUI

struct StickerBookView: View {
    @ObservedObject var gameState: KidsGameState
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 20)
    ]
    
    private var hasMasterSticker: Bool {
        gameState.collectedStickers.contains(KidsGameState.masterSticker)
    }
    
    private var islandStickersOnly: [String] {
        gameState.collectedStickers.filter { $0 != KidsGameState.masterSticker }
    }
    
    var body: some View {
        ZStack {
            KidsTheme.backgroundGradient.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: { gameState.screen = .map }) {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                    .minimumTouchTarget()
                    
                    Spacer()
                    
                    Text("My Stickers")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear.frame(width: 50, height: 50)
                }
                .padding()
                
                // Content
                if gameState.collectedStickers.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("✨")
                            .font(.system(size: 80))
                        Text("Win games to collect stickers!")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 30) {
                            // Master Sticker Celebration (if earned)
                            if hasMasterSticker {
                                VStack(spacing: 16) {
                                    Text("🎉 CHAMPION! 🎉")
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundColor(Color(hex: "FFD700"))
                                        .shadow(color: .orange.opacity(0.5), radius: 10)
                                    
                                    MasterStickerView()
                                    
                                    Text("You collected all \(KidsGameState.totalIslandStickers) stickers!")
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .strokeBorder(Color(hex: "FFD700").opacity(0.5), lineWidth: 3)
                                        )
                                )
                                .padding(.horizontal)
                            }
                            
                            // Progress indicator
                            if !hasMasterSticker {
                                Text("\(islandStickersOnly.count) / \(KidsGameState.totalIslandStickers) stickers")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Sticker Grid
                            LazyVGrid(columns: columns, spacing: 30) {
                                ForEach(islandStickersOnly, id: \.self) { sticker in
                                    StickerView(sticker: sticker)
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

struct StickerView: View {
    let sticker: String
    @ObservedObject private var featureFlags = KidsFeatureFlags.shared
    @State private var isShining = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Text(sticker)
                    .font(.system(size: 50))
                    .shadow(radius: 3)
                
                // Shine overlay for long-press
                if isShining {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.6), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .allowsHitTesting(false)
                }
            }
            .background(
                Circle()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 4)
            )
            .onTapGesture {
                // Tap plays sticker sound if feature enabled
                if featureFlags.stickerSoundsEnabled {
                    featureFlags.playStickerSound(for: sticker)
                }
            }
            .onLongPressGesture(minimumDuration: 0.3) {
                // Long press shows shine animation
                if featureFlags.stickerSoundsEnabled {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShining = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeIn(duration: 0.2)) {
                            isShining = false
                        }
                    }
                    featureFlags.playStickerSound(for: sticker)
                }
            }
            
            // Island name (if we can find it)
            if let islandName = islandName(for: sticker) {
                Text(islandName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private func islandName(for sticker: String) -> String? {
        KidsGameState.levels.first { $0.stickerReward == sticker }?.name
    }
}

// MARK: - Master Sticker View (Special Gold Trophy)
struct MasterStickerView: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "FFD700").opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 40,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(isPulsing ? 1.1 : 1.0)
            
            // Gold circle background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 15)
            
            // Trophy emoji
            Text(KidsGameState.masterSticker)
                .font(.system(size: 70))
                .shadow(color: .black.opacity(0.3), radius: 3)
            
            // Gold ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), Color(hex: "FFD700")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 5
                )
                .frame(width: 130, height: 130)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    StickerBookView(gameState: KidsGameState())
}
