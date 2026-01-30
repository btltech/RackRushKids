import SwiftUI

// MARK: - Accessibility System
/// Centralized accessibility utilities for RackRushKids

struct AccessibilityConfig {
    // MARK: - Environment Readers
    
    /// Check if user prefers reduced motion
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Check if user prefers increased contrast
    static var prefersHighContrast: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    /// Check if user prefers bold text
    static var prefersBoldText: Bool {
        UIAccessibility.isBoldTextEnabled
    }
    
    /// Check if user needs color alternatives (colorblind support)
    /// When true, don't rely on color alone to convey information
    static var differentiateWithoutColor: Bool {
        UIAccessibility.shouldDifferentiateWithoutColor
    }
    
    /// Convenience: Check if animations should be disabled entirely
    static var shouldDisableAnimations: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Check if Switch Control or other assistive tech is running
    static var isSwitchControlRunning: Bool {
        UIAccessibility.isSwitchControlRunning
    }
}

// MARK: - VoiceOver Labels for Game Elements
struct TileAccessibilityLabel {
    /// Generate VoiceOver label for a letter tile
    static func forTile(letter: String, value: Int) -> String {
        "\(letter), \(value) point\(value > 1 ? "s" : "")"
    }
    
    /// Generate hint for tile interaction
    static var tileHint: String {
        "Double tap to add to your word"
    }
}

struct TimerAccessibilityLabel {
    /// Generate VoiceOver label for timer
    static func forTimer(seconds: Int, isUrgent: Bool) -> String {
        if isUrgent {
            return "\(seconds) seconds remaining. Hurry!"
        }
        return "\(seconds) seconds remaining"
    }
}

// MARK: - Accessibility Announcements
class AccessibilityAnnouncer {
    static func announce(_ message: String) {
        // Only announce when VoiceOver is running
        guard AccessibilityConfig.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    static func announceTimerWarning(seconds: Int) {
        if seconds == 10 {
            announce("10 seconds remaining")
        } else if seconds == 5 {
            announce("5 seconds remaining. Hurry!")
        }
    }
    
    static func announceWordSubmitted(word: String) {
        announce("Word submitted: \(word)")
    }
    
    static func announceInvalidWord() {
        announce("Invalid word. Try again!")
    }
}

// MARK: - Dynamic Type Support
struct DynamicTypeModifier: ViewModifier {
    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    
    @Environment(\.sizeCategory) var sizeCategory
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize, weight: weight, design: design))
    }
    
    private var scaledSize: CGFloat {
        switch sizeCategory {
        case .extraSmall: return baseSize * 0.8
        case .small: return baseSize * 0.9
        case .medium: return baseSize
        case .large: return baseSize * 1.05
        case .extraLarge: return baseSize * 1.1
        case .extraExtraLarge: return baseSize * 1.15
        case .extraExtraExtraLarge: return baseSize * 1.2
        case .accessibilityMedium: return baseSize * 1.25
        case .accessibilityLarge: return baseSize * 1.35
        case .accessibilityExtraLarge: return baseSize * 1.45
        case .accessibilityExtraExtraLarge: return baseSize * 1.55
        case .accessibilityExtraExtraExtraLarge: return baseSize * 1.65
        @unknown default: return baseSize
        }
    }
}

extension View {
    /// Apply font that respects Dynamic Type settings
    func dynamicFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(DynamicTypeModifier(baseSize: size, weight: weight, design: design))
    }
    
    /// Mark as a header for VoiceOver navigation
    func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// Ensure minimum 44x44pt touch target (Apple HIG requirement)
    func minimumTouchTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}
