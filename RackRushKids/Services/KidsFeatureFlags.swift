import SwiftUI

/// Centralized feature flags for post-launch features
/// All features ship disabled by default and can be enabled via:
/// - App update (change default value)
/// - Remote config (future)
/// - Developer toggle in Parental Controls (for testing)
@MainActor
class KidsFeatureFlags: ObservableObject {
    static let shared = KidsFeatureFlags()
    
    // MARK: - Feature Flags
    
    /// Themed background gradients per age track (Young=green, Medium=blue, Older=purple)
    @AppStorage("feature_themedBiomes") var themedBiomesEnabled = true
    
    /// Tap sticker to play island sound effect
    @AppStorage("feature_stickerSounds") var stickerSoundsEnabled = true
    
    /// Parent-only view of daily "tricky words" the child struggled with
    @AppStorage("feature_trickyWords") var trickyWordsEnabled = false
    
    private init() {}
}

// MARK: - Biome Themes
extension KidsFeatureFlags {
    /// Returns the appropriate background gradient for the given age group
    /// Falls back to default KidsTheme gradient if feature is disabled
    func biomeGradient(for ageGroup: KidsAgeGroup) -> LinearGradient {
        guard themedBiomesEnabled else {
            return KidsTheme.backgroundGradient
        }
        
        switch ageGroup {
        case .young:
            // Forest/Garden biome - greens
            return LinearGradient(
                colors: [
                    Color(hex: "1a472a"),  // Dark forest green
                    Color(hex: "2d5a27"),  // Forest green
                    Color(hex: "4a7c59")   // Sage green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .medium:
            // Ocean/Sky biome - blues
            return LinearGradient(
                colors: [
                    Color(hex: "0c2461"),  // Deep ocean blue
                    Color(hex: "1e3799"),  // Royal blue
                    Color(hex: "4a69bd")   // Sky blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .older:
            // Galaxy/Space biome - purples
            return LinearGradient(
                colors: [
                    Color(hex: "2c003e"),  // Deep purple
                    Color(hex: "512b58"),  // Royal purple
                    Color(hex: "7b4397")   // Violet
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    /// Biome name for display purposes
    func biomeName(for ageGroup: KidsAgeGroup) -> String {
        switch ageGroup {
        case .young: return "🌿 Forest Trail"
        case .medium: return "🌊 Ocean Quest"
        case .older: return "🌌 Galaxy Adventure"
        }
    }
}

// MARK: - Sticker Sounds
extension KidsFeatureFlags {
    /// Plays a short sound "sting" for the given sticker
    /// Different sounds per age track to reinforce biome themes
    func playStickerSound(for sticker: String) {
        guard stickerSoundsEnabled else { return }
        
        // Find the island for this sticker to determine age group
        let level = KidsGameState.levels.first { $0.stickerReward == sticker }
        let ageGroup = level?.ageGroup ?? .medium
        
        // Play different tones per biome
        // Young = bright/cheerful, Medium = adventurous, Older = cosmic
        let audioManager = KidsAudioManager.shared
        
        switch ageGroup {
        case .young:
            // Cheerful "boing" - higher pitch, playful
            audioManager.playPop()
        case .medium:
            // Adventure "whoosh" - medium, exciting
            audioManager.playNavigation()
        case .older:
            // Cosmic "sparkle" - mystical feel
            audioManager.playSuccess()
        }
    }
}
