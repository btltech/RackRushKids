import SwiftUI

/// Custom avatar system for kids
@MainActor
class KidsAvatarManager: ObservableObject {
    static let shared = KidsAvatarManager()
    
    @AppStorage("kidsSelectedAvatar") private var selectedAvatarId: String = "bear"
    @AppStorage("kidsUnlockedAvatars") private var unlockedAvatarsData: Data = Data()
    
    struct Avatar: Identifiable {
        let id: String
        let emoji: String
        let name: String
        let unlockCondition: String
        let isDefault: Bool
    }
    
    static let allAvatars: [Avatar] = [
        // Default avatars (unlocked from start)
        Avatar(id: "bear", emoji: "🐻", name: "Benny Bear", unlockCondition: "Default", isDefault: true),
        Avatar(id: "bunny", emoji: "🐰", name: "Bailey Bunny", unlockCondition: "Default", isDefault: true),
        Avatar(id: "cat", emoji: "🐱", name: "Cleo Cat", unlockCondition: "Default", isDefault: true),
        Avatar(id: "dog", emoji: "🐶", name: "Duke Dog", unlockCondition: "Default", isDefault: true),
        
        // Unlockable avatars
        Avatar(id: "lion", emoji: "🦁", name: "Leo Lion", unlockCondition: "Win 5 games", isDefault: false),
        Avatar(id: "owl", emoji: "🦉", name: "Oliver Owl", unlockCondition: "Win 10 games", isDefault: false),
        Avatar(id: "penguin", emoji: "🐧", name: "Penny Penguin", unlockCondition: "Win 20 games", isDefault: false),
        Avatar(id: "unicorn", emoji: "🦄", name: "Unity Unicorn", unlockCondition: "Win 50 games", isDefault: false),
        Avatar(id: "dragon", emoji: "🐉", name: "Drake Dragon", unlockCondition: "Win 100 games", isDefault: false),
        Avatar(id: "star", emoji: "⭐", name: "Starry", unlockCondition: "Get all 3 stars on any island", isDefault: false),
        Avatar(id: "rocket", emoji: "🚀", name: "Rocky Rocket", unlockCondition: "7-day streak", isDefault: false),
        Avatar(id: "rainbow", emoji: "🌈", name: "Rainbow Ray", unlockCondition: "Collect 15 stickers", isDefault: false),
    ]
    
    private init() {}
    
    var selectedAvatar: Avatar {
        Self.allAvatars.first { $0.id == selectedAvatarId } ?? Self.allAvatars[0]
    }
    
    var unlockedAvatarIds: Set<String> {
        get {
            var base = Set(Self.allAvatars.filter { $0.isDefault }.map { $0.id })
            if !unlockedAvatarsData.isEmpty,
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: unlockedAvatarsData) {
                base.formUnion(decoded)
            }
            return base
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                unlockedAvatarsData = data
            }
        }
    }
    
    func selectAvatar(_ id: String) {
        guard unlockedAvatarIds.contains(id) else { return }
        selectedAvatarId = id
        HapticManager.shared.selection()
    }
    
    func unlockAvatar(_ id: String) {
        var current = unlockedAvatarIds
        current.insert(id)
        unlockedAvatarIds = current
        HapticManager.shared.notification(type: .success)
    }
    
    /// Check unlock conditions after game events
    func checkUnlocks(wins: Int, streak: Int, stickers: Int, hasThreeStars: Bool) {
        if wins >= 5 { unlockAvatar("lion") }
        if wins >= 10 { unlockAvatar("owl") }
        if wins >= 20 { unlockAvatar("penguin") }
        if wins >= 50 { unlockAvatar("unicorn") }
        if wins >= 100 { unlockAvatar("dragon") }
        if hasThreeStars { unlockAvatar("star") }
        if streak >= 7 { unlockAvatar("rocket") }
        if stickers >= 15 { unlockAvatar("rainbow") }
    }
}

/// Enhanced achievement badges system
@MainActor
class KidsBadgeManager: ObservableObject {
    static let shared = KidsBadgeManager()
    
    @AppStorage("kidsUnlockedBadges") private var unlockedBadgesData: Data = Data()
    @Published var newlyUnlockedBadge: Badge?
    
    struct Badge: Identifiable, Codable {
        let id: String
        let emoji: String
        let name: String
        let description: String
        let category: Category
        
        enum Category: String, Codable {
            case words
            case speed
            case streak
            case collection
            case skill
        }
    }
    
    static let allBadges: [Badge] = [
        // Words
        Badge(id: "first_word", emoji: "🎈", name: "First Word!", description: "Spell your first word", category: .words),
        Badge(id: "word_10", emoji: "📚", name: "Bookworm", description: "Spell 10 words", category: .words),
        Badge(id: "word_50", emoji: "📖", name: "Word Collector", description: "Spell 50 words", category: .words),
        Badge(id: "word_100", emoji: "🐝", name: "Spelling Bee", description: "Spell 100 words", category: .words),
        Badge(id: "word_500", emoji: "🎓", name: "Word Master", description: "Spell 500 words", category: .words),
        
        // Speed
        Badge(id: "speed_5sec", emoji: "⚡", name: "Speed Demon", description: "Submit a word in under 5 seconds", category: .speed),
        Badge(id: "speed_3sec", emoji: "💨", name: "Lightning Fast", description: "Submit a word in under 3 seconds", category: .speed),
        
        // Streak
        Badge(id: "streak_3", emoji: "🔥", name: "On Fire!", description: "3-day play streak", category: .streak),
        Badge(id: "streak_7", emoji: "🌟", name: "Week Warrior", description: "7-day play streak", category: .streak),
        Badge(id: "streak_14", emoji: "💎", name: "Super Star", description: "14-day play streak", category: .streak),
        Badge(id: "streak_30", emoji: "👑", name: "Champion", description: "30-day play streak", category: .streak),
        
        // Collection
        Badge(id: "sticker_5", emoji: "✨", name: "Collector", description: "Collect 5 stickers", category: .collection),
        Badge(id: "sticker_15", emoji: "🌈", name: "Rainbow Collector", description: "Collect 15 stickers", category: .collection),
        Badge(id: "sticker_30", emoji: "🏆", name: "Sticker Champion", description: "Collect all 30 stickers", category: .collection),
        
        // Skill
        Badge(id: "long_word_5", emoji: "🦕", name: "Big Word!", description: "Spell a 5-letter word", category: .skill),
        Badge(id: "long_word_6", emoji: "🦖", name: "Dino Speller", description: "Spell a 6-letter word", category: .skill),
        Badge(id: "long_word_7", emoji: "🐋", name: "Word Whale", description: "Spell a 7-letter word", category: .skill),
        Badge(id: "perfect_game", emoji: "💯", name: "Perfect Game", description: "Win all 7 rounds in a match", category: .skill),
        Badge(id: "three_stars", emoji: "⭐", name: "Three Stars!", description: "Get 3 stars on any island", category: .skill),
    ]
    
    private init() {}
    
    var unlockedBadgeIds: Set<String> {
        get {
            guard !unlockedBadgesData.isEmpty else { return [] }
            return (try? JSONDecoder().decode(Set<String>.self, from: unlockedBadgesData)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                unlockedBadgesData = data
            }
        }
    }
    
    var unlockedBadges: [Badge] {
        Self.allBadges.filter { unlockedBadgeIds.contains($0.id) }
    }
    
    func unlockBadge(_ id: String) {
        guard !unlockedBadgeIds.contains(id) else { return }
        var current = unlockedBadgeIds
        current.insert(id)
        unlockedBadgeIds = current
        
        if let badge = Self.allBadges.first(where: { $0.id == id }) {
            newlyUnlockedBadge = badge
            HapticManager.shared.notification(type: .success)
        }
    }
    
    /// Check conditions and unlock appropriate badges
    func checkBadges(
        totalWords: Int,
        lastWordTime: TimeInterval?,
        streak: Int,
        stickers: Int,
        longestWordLength: Int,
        roundsWonInMatch: Int,
        hasThreeStars: Bool
    ) {
        // Words
        if totalWords >= 1 { unlockBadge("first_word") }
        if totalWords >= 10 { unlockBadge("word_10") }
        if totalWords >= 50 { unlockBadge("word_50") }
        if totalWords >= 100 { unlockBadge("word_100") }
        if totalWords >= 500 { unlockBadge("word_500") }
        
        // Speed
        if let time = lastWordTime {
            if time < 5 { unlockBadge("speed_5sec") }
            if time < 3 { unlockBadge("speed_3sec") }
        }
        
        // Streak
        if streak >= 3 { unlockBadge("streak_3") }
        if streak >= 7 { unlockBadge("streak_7") }
        if streak >= 14 { unlockBadge("streak_14") }
        if streak >= 30 { unlockBadge("streak_30") }
        
        // Collection
        if stickers >= 5 { unlockBadge("sticker_5") }
        if stickers >= 15 { unlockBadge("sticker_15") }
        if stickers >= 30 { unlockBadge("sticker_30") }
        
        // Skill
        if longestWordLength >= 5 { unlockBadge("long_word_5") }
        if longestWordLength >= 6 { unlockBadge("long_word_6") }
        if longestWordLength >= 7 { unlockBadge("long_word_7") }
        if roundsWonInMatch >= 7 { unlockBadge("perfect_game") }
        if hasThreeStars { unlockBadge("three_stars") }
    }
}
