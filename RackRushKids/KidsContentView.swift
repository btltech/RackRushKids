import SwiftUI

struct KidsContentView: View {
    @StateObject private var gameState = KidsGameState()
    
    var body: some View {
        ZStack {
            // Background
            KidsTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Content
            switch gameState.screen {
            case .home:
                KidsHomeView(gameState: gameState)
                
            case .map:
                KidsMapView(gameState: gameState)
                
            case .queued:
                KidsQueuedView(gameState: gameState)
                
            case .playing:
                KidsMatchView(gameState: gameState)
                
            case .result:
                KidsResultView(gameState: gameState)
                
            case .matchResult:
                KidsMatchResultView(gameState: gameState)
                
            case .settings:
                KidsSettingsView(gameState: gameState)
                
            case .stickers:
                StickerBookView(gameState: gameState)
            }
        }
        .onAppear {
            gameState.connect()
        }
    }
}

#Preview {
    KidsContentView()
}
