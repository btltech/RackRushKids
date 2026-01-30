import SwiftUI
import CoreHaptics

@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Returns true if device supports haptics
    static var isSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    /// Check if haptics are enabled (device support + user preference)
    private var isEnabled: Bool {
        guard Self.isSupported else { return false }
        
        // Default to true when the key is missing
        if UserDefaults.standard.object(forKey: "kidsHapticsEnabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "kidsHapticsEnabled")
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

