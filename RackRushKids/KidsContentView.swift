import SwiftUI

struct KidsContentView: View {
    @StateObject private var gameState = KidsGameState()
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            // Always present background to prevent white flash
            KidsTheme.backgroundGradient
                .ignoresSafeArea()
            
            if !hasSeenOnboarding {
                KidsOnboardingView()
                    .transition(.opacity)
            } else {
                // Content with transitions
                Group {
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
                        
                    case .partySetup:
                        KidsPartySetupView(gameState: gameState)
                        
                    case .networkParty:
                        KidsNetworkPartyView(gameState: gameState)
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: gameState.screen)
        .onAppear {
            gameState.connect()
        }
    }
}

#Preview {
    KidsContentView()
}
