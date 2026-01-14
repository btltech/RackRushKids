import SwiftUI

struct StickerBookView: View {
    @ObservedObject var gameState: KidsGameState
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 20)
    ]
    
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
                        LazyVGrid(columns: columns, spacing: 30) {
                            ForEach(gameState.collectedStickers, id: \.self) { sticker in
                                StickerView(sticker: sticker)
                            }
                        }
                        .padding(30)
                    }
                }
            }
        }
    }
}

struct StickerView: View {
    let sticker: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Text(sticker)
                    .font(.system(size: 50))
                    .shadow(radius: 3)
            }
            .background(
                Circle()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 4)
            )
            
            // Optional name or date earned could go here
        }
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    StickerBookView(gameState: KidsGameState())
}
