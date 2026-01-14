import SwiftUI

struct KidsMapView: View {
    @ObservedObject var gameState: KidsGameState
    
    var body: some View {
        ZStack {
            // Background Layer
            KidsTheme.backgroundGradient.ignoresSafeArea()
            
            // Floating Particles (Visual Polish)
            AmbientParticlesView()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 60) {
                    Spacer(minLength: 40)
                    
                    ForEach(Array(KidsGameState.levels.enumerated()), id: \.element.id) { index, level in
                        let isUnlocked = level.id <= gameState.unlockedLevel
                        let isNext = level.id == gameState.unlockedLevel
                        
                        // Alternate alignment
                        HStack {
                            if index % 2 == 1 { Spacer() }
                            
                            IslandNode(
                                level: level,
                                isUnlocked: isUnlocked,
                                isNext: isNext
                            ) {
                                gameState.startLevel(level)
                            }
                            
                            if index % 2 == 0 { Spacer() }
                        }
                        .padding(.horizontal, 40)
                        
                        // Connection Path logic can be added here if needed
                    }
                    
                    Spacer(minLength: 100)
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

// Note: AmbientParticlesView is used from KidsEffects.swift

#Preview {
    KidsMapView(gameState: KidsGameState())
}
