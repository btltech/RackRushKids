import Foundation
import SwiftUI
import Combine

/// Manages behavioral achievements and sticker rewards for the Kids app
@MainActor
class KidsAchievementManager: ObservableObject {
    static let shared = KidsAchievementManager()
    
    // MARK: - Achievements
    enum Achievement: String, CaseIterable {
        case firstWord = "first_word"
        case speedySpeller = "speedy_speller"
        case longWord = "long_word"
        case bearBuddy = "bear_buddy"
        case dailyComplete = "daily_complete"
        case winningStreak = "winning_streak"
        
        var sticker: String {
            switch self {
            case .firstWord: return "🎈"
            case .speedySpeller: return "⚡"
            case .longWord: return "🦕"
            case .bearBuddy: return "🧸"
            case .dailyComplete: return "🌟"
            case .winningStreak: return "🔥"
            }
        }
        
        var title: String {
            switch self {
            case .firstWord: return "First Word!"
            case .speedySpeller: return "Speedy Speller"
            case .longWord: return "Word Wizard"
            case .bearBuddy: return "Bear Buddy"
            case .dailyComplete: return "Daily Champion"
            case .winningStreak: return "Winning Streak"
            }
        }
    }
    
    // MARK: - Published State
    @Published var lastUnlockedSticker: String?
    
    // MARK: - Persistence
    @AppStorage("kidsUnlockedAchievements") private var unlockedAchievementsData: Data = Data()
    
    private init() {}
    
    var unlockedAchievements: Set<String> {
        get {
            guard !unlockedAchievementsData.isEmpty else { return [] }
            return (try? JSONDecoder().decode(Set<String>.self, from: unlockedAchievementsData)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                unlockedAchievementsData = data
            }
        }
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func checkAchievement(_ achievement: Achievement, in gameState: KidsGameState) {
        guard !unlockedAchievements.contains(achievement.rawValue) else { return }
        
        // Add to unlocked
        var current = unlockedAchievements
        current.insert(achievement.rawValue)
        unlockedAchievements = current
        
        // Add sticker to game state
        gameState.addSticker(achievement.sticker)
        
        // Trigger notification
        lastUnlockedSticker = achievement.sticker
        
        // Save haptic feedback
        HapticManager.shared.notification(type: .success)
    }
}
