import SwiftUI

/// Centralized configuration for Island Map UI
enum IslandConfig {
    // MARK: - Sizing
    static let nodeSize: CGFloat = 80
    static let pulseSize: CGFloat = 90
    static let iconSize: CGFloat = 30
    static let starSize: CGFloat = 12
    
    // MARK: - Spacing
    static let nodeSpacing: CGFloat = 60
    static let horizontalPadding: CGFloat = 40
    static let topPadding: CGFloat = 40
    static let bottomPadding: CGFloat = 100
    
    // MARK: - Counts
    static let islandsPerAgeGroup = 10
    static let totalIslands = 30
    static let maxStars = 3
    
    // MARK: - Animation
    static let pulseDuration: Double = 1.0
    static let pathAnimationDuration: Double = 0.8
    static let microAnimationDuration: Double = 2.0
    
    // MARK: - Parallax
    static let backgroundParallaxFactor: CGFloat = 0.3
    static let foregroundParallaxFactor: CGFloat = 0.1
    
    // MARK: - Star Thresholds (based on score percentage of max possible)
    static let threeStarThreshold: Double = 0.8   // 80%+ = 3 stars
    static let twoStarThreshold: Double = 0.5     // 50%+ = 2 stars
    // Below 50% = 1 star (for winning)
}
