import SwiftUI

struct KidsMapView: View {
    @ObservedObject var gameState: KidsGameState
    @ObservedObject private var featureFlags = KidsFeatureFlags.shared
    @State private var selectedPage: KidsAgeGroup

    init(gameState: KidsGameState) {
        self.gameState = gameState
        _selectedPage = State(initialValue: gameState.selectedAgeGroup)
    }
    
    var body: some View {
        ZStack {
            // Background Layer - uses biome gradient if feature enabled
            featureFlags.biomeGradient(for: selectedPage).ignoresSafeArea()
            
            // Parallax Background Layer
            ParallaxBackgroundLayer(ageGroup: selectedPage)
            
            // Floating Particles (Visual Polish)
            AmbientParticlesView()

            TabView(selection: $selectedPage) {
                ForEach(KidsAgeGroup.allCases, id: \.self) { ageGroup in
                    KidsMapAgeGroupPage(gameState: gameState, ageGroup: ageGroup)
                        .tag(ageGroup)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .onChange(of: selectedPage) { _, newValue in
                // Keep the app's selected age group in sync with the visible page.
                if gameState.selectedAgeGroup != newValue {
                    gameState.ageGroup = newValue.rawValue
                }
            }
            .onChange(of: gameState.ageGroup) { _, _ in
                // If age group is changed elsewhere (e.g. Settings), jump to that page.
                let newValue = gameState.selectedAgeGroup
                if selectedPage != newValue {
                    selectedPage = newValue
                }
            }
            
            // Top Bar
            VStack {
                HStack {
                    Button(action: { gameState.screen = .home }) {
                        Image(systemName: "house.fill")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                    
                    Spacer()
                    
                    Button(action: { gameState.screen = .stickers }) {
                        HStack {
                            Text("✨")
                            Text("Stickers")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.black)
                            
                            // Badge count
                            if !gameState.collectedStickers.isEmpty {
                                Text("\(gameState.collectedStickers.count)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.orange.gradient))
                        .shadow(color: .orange.opacity(0.3), radius: 5)
                    }
                    
                    Button(action: { gameState.screen = .settings }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
}

// MARK: - Map Page Per Age Group
private struct KidsMapAgeGroupPage: View {
    @ObservedObject var gameState: KidsGameState
    let ageGroup: KidsAgeGroup

    private var levels: [LevelDef] {
        KidsGameState.levels.filter { $0.ageGroup == ageGroup }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: IslandConfig.nodeSpacing) {
                Spacer(minLength: IslandConfig.topPadding)

                ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                    let trackIndex = KidsGameState.trackIndex(for: level)
                    let unlockedIndex = gameState.unlockedIndex(for: ageGroup)
                    let isUnlocked = trackIndex <= unlockedIndex
                    let isNext = trackIndex == unlockedIndex
                    let isAgeGroupMatch = gameState.selectedAgeGroup == ageGroup
                    let starCount = gameState.stars(for: level.id)

                    VStack(spacing: 0) {
                        // Path connector (before each island except first)
                        if index > 0 {
                            PathConnector(
                                fromRight: (index - 1) % 2 == 0,
                                isActive: isAgeGroupMatch && isUnlocked
                            )
                        }

                        // Alternate alignment
                        HStack {
                            if index % 2 == 1 { Spacer() }

                            IslandNode(
                                level: level,
                                isUnlocked: isUnlocked,
                                isNext: isNext,
                                isAgeGroupMatch: isAgeGroupMatch,
                                starCount: starCount
                            ) {
                                gameState.startLevel(level)
                            }

                            if index % 2 == 0 { Spacer() }
                        }
                        .padding(.horizontal, IslandConfig.horizontalPadding)
                    }
                }

                Spacer(minLength: IslandConfig.bottomPadding)
            }
        }
    }
}

// MARK: - Path Connector
/// Visual path connecting islands in the map
struct PathConnector: View {
    let fromRight: Bool  // Direction the path starts from
    let isActive: Bool   // Whether this path segment is "unlocked"
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width - (IslandConfig.horizontalPadding * 2)
                let height = geo.size.height
                let midY = height / 2
                
                if fromRight {
                    // Path from right island to left island
                    path.move(to: CGPoint(x: width * 0.7, y: 0))
                    path.addCurve(
                        to: CGPoint(x: width * 0.3, y: height),
                        control1: CGPoint(x: width * 0.7, y: midY),
                        control2: CGPoint(x: width * 0.3, y: midY)
                    )
                } else {
                    // Path from left island to right island
                    path.move(to: CGPoint(x: width * 0.3, y: 0))
                    path.addCurve(
                        to: CGPoint(x: width * 0.7, y: height),
                        control1: CGPoint(x: width * 0.3, y: midY),
                        control2: CGPoint(x: width * 0.7, y: midY)
                    )
                }
            }
            .stroke(
                isActive ? Color.white.opacity(0.5) : Color.white.opacity(0.15),
                style: StrokeStyle(
                    lineWidth: 4,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [8, 8]
                )
            )
            .padding(.horizontal, IslandConfig.horizontalPadding)
        }
        .frame(height: 40)
    }
}

// MARK: - Parallax Background Layer
/// Floating decorations that add depth to the map
struct ParallaxBackgroundLayer: View {
    let ageGroup: KidsAgeGroup
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<decorationCount, id: \.self) { index in
                    decoration(for: index)
                        .position(
                            x: decorationX(index: index, width: geo.size.width),
                            y: decorationY(index: index, height: geo.size.height) + offset * IslandConfig.backgroundParallaxFactor
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: true)) {
                offset = 100
            }
        }
    }
    
    private var decorationCount: Int { 8 }
    
    private func decorationX(index: Int, width: CGFloat) -> CGFloat {
        let positions: [CGFloat] = [0.1, 0.85, 0.15, 0.9, 0.05, 0.95, 0.2, 0.8]
        return width * positions[index % positions.count]
    }
    
    private func decorationY(index: Int, height: CGFloat) -> CGFloat {
        CGFloat(index) * (height / CGFloat(decorationCount)) + 50
    }
    
    @ViewBuilder
    private func decoration(for index: Int) -> some View {
        switch ageGroup {
        case .young:
            // Forest decorations: leaves, flowers, butterflies
            Group {
                if index % 3 == 0 {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green.opacity(0.3))
                        .font(.system(size: 20))
                } else if index % 3 == 1 {
                    Text("🦋")
                        .font(.system(size: 16))
                        .opacity(0.4)
                } else {
                    Image(systemName: "sparkle")
                        .foregroundColor(.yellow.opacity(0.3))
                        .font(.system(size: 12))
                }
            }
            
        case .medium:
            // Ocean decorations: bubbles, fish, waves
            Group {
                if index % 3 == 0 {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 12, height: 12)
                } else if index % 3 == 1 {
                    Text("🐠")
                        .font(.system(size: 14))
                        .opacity(0.3)
                } else {
                    Image(systemName: "water.waves")
                        .foregroundColor(.cyan.opacity(0.2))
                        .font(.system(size: 16))
                }
            }
            
        case .older:
            // Space decorations: stars, planets, nebula
            Group {
                if index % 3 == 0 {
                    Image(systemName: "star.fill")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: CGFloat.random(in: 8...14)))
                } else if index % 3 == 1 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow.opacity(0.25))
                        .font(.system(size: 10))
                }
            }
        }
    }
}

// Note: AmbientParticlesView is used from KidsEffects.swift

#Preview {
    KidsMapView(gameState: KidsGameState())
}
