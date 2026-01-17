import SwiftUI

@main
struct RackRushKidsApp: App {
    
    init() {
        // Pre-warm services in background for faster responsiveness
        DispatchQueue.global(qos: .userInitiated).async {
            // Warm up audio manager (deferred initialization)
            _ = KidsAudioManager.shared
            
            // Pre-warm TTS synthesizer so pronunciation is instant
            Task { @MainActor in
                KidsTTSService.shared.warmUp()
            }
        }
        
        // Pre-authenticate Game Center IMMEDIATELY on main thread
        // This ensures the authentication handler is set up right away
        Task { @MainActor in
            GameCenterService.shared.authenticate()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            KidsContentView()
        }
    }
}
