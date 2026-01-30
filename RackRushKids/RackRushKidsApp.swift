import SwiftUI

@main
struct RackRushKidsApp: App {
    
    init() {
        // Defer all service initialization to onAppear to avoid @MainActor isolation issues
        // GameCenter authentication is handled in KidsContentView.onAppear() via gameState.connect()
    }
    
    var body: some Scene {
        WindowGroup {
            KidsContentView()
                .onAppear {
                    // Pre-warm services on main thread
                    // CRITICAL: KidsAudioManager uses @AppStorage which requires main thread access
                    Task { @MainActor in
                        // Warm up audio manager (uses @AppStorage, must be on main thread)
                        KidsAudioManager.shared.prewarm()
                        
                        // TTS warm-up
                        KidsTTSService.shared.warmUp()
                    }
                }
        }
    }
}
