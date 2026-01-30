import SwiftUI
import Foundation

/// Tracks daily play streaks for kids
@MainActor
class KidsStreakManager: ObservableObject {
    static let shared = KidsStreakManager()
    
    @AppStorage("kidsLastPlayDate") private var lastPlayDateString: String = ""
    @AppStorage("kidsCurrentStreak") private var currentStreakValue: Int = 0
    @AppStorage("kidsLongestStreak") private var longestStreakValue: Int = 0
    
    @Published var showStreakAnimation = false
    @Published var streakMilestone: Int? = nil
    
    private init() {
        checkStreakOnLaunch()
    }
    
    var currentStreak: Int { currentStreakValue }
    var longestStreak: Int { longestStreakValue }
    
    /// Call this when a game is completed
    func recordPlay() {
        let today = dateString(for: Date())
        
        if lastPlayDateString == today {
            // Already played today
            return
        }
        
        let yesterday = dateString(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        if lastPlayDateString == yesterday {
            // Consecutive day - extend streak
            currentStreakValue += 1
        } else {
            // Streak broken - start new
            currentStreakValue = 1
        }
        
        lastPlayDateString = today
        
        // Update longest streak
        if currentStreakValue > longestStreakValue {
            longestStreakValue = currentStreakValue
        }
        
        // Check for milestones (3, 7, 14, 30, 100)
        let milestones = [3, 7, 14, 30, 100]
        if milestones.contains(currentStreakValue) {
            streakMilestone = currentStreakValue
            showStreakAnimation = true
            HapticManager.shared.notification(type: .success)
        }
    }
    
    /// Check if streak is still valid on launch
    private func checkStreakOnLaunch() {
        let today = dateString(for: Date())
        let yesterday = dateString(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        // If last play was not today or yesterday, reset streak
        if lastPlayDateString != today && lastPlayDateString != yesterday {
            currentStreakValue = 0
        }
    }
    
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    var streakEmoji: String {
        switch currentStreak {
        case 0: return ""
        case 1...2: return "🔥"
        case 3...6: return "🔥🔥"
        case 7...13: return "🔥🔥🔥"
        case 14...29: return "⭐🔥🔥🔥"
        case 30...99: return "🌟🔥🔥🔥"
        default: return "🏆🔥🔥🔥"
        }
    }
}

/// Tracks gameplay statistics for parental progress reports
@MainActor
class KidsStatsManager: ObservableObject {
    static let shared = KidsStatsManager()
    
    @AppStorage("kidsTotalWordsPlayed") private var totalWordsPlayedValue: Int = 0
    @AppStorage("kidsTotalGamesPlayed") private var totalGamesPlayedValue: Int = 0
    @AppStorage("kidsTotalWins") private var totalWinsValue: Int = 0
    @AppStorage("kidsCorrectWords") private var correctWordsValue: Int = 0
    @AppStorage("kidsIncorrectAttempts") private var incorrectAttemptsValue: Int = 0
    @AppStorage("kidsTotalPlayTimeSeconds") private var totalPlayTimeValue: Int = 0
    @AppStorage("kidsLongestWord") private var longestWordValue: String = ""
    @AppStorage("kidsHighestScore") private var highestScoreValue: Int = 0
    
    private var sessionStartTime: Date?
    
    private init() {}
    
    // MARK: - Public Getters
    var totalWordsPlayed: Int { totalWordsPlayedValue }
    var totalGamesPlayed: Int { totalGamesPlayedValue }
    var totalWins: Int { totalWinsValue }
    var correctWords: Int { correctWordsValue }
    var incorrectAttempts: Int { incorrectAttemptsValue }
    var totalPlayTime: TimeInterval { TimeInterval(totalPlayTimeValue) }
    var longestWord: String { longestWordValue }
    var highestScore: Int { highestScoreValue }
    
    var accuracy: Double {
        let total = correctWordsValue + incorrectAttemptsValue
        return total > 0 ? Double(correctWordsValue) / Double(total) * 100 : 0
    }
    
    var formattedPlayTime: String {
        let hours = totalPlayTimeValue / 3600
        let minutes = (totalPlayTimeValue % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
    
    // MARK: - Recording Methods
    
    func startSession() {
        sessionStartTime = Date()
    }
    
    func endSession() {
        if let start = sessionStartTime {
            let duration = Int(Date().timeIntervalSince(start))
            totalPlayTimeValue += duration
            sessionStartTime = nil
        }
    }
    
    func recordWordSubmitted(word: String, accepted: Bool) {
        totalWordsPlayedValue += 1
        if accepted {
            correctWordsValue += 1
            if word.count > longestWordValue.count {
                longestWordValue = word
            }
        } else {
            incorrectAttemptsValue += 1
        }
    }
    
    func recordGameCompleted(won: Bool, score: Int, longestWordLength: Int = 0, lastWordTime: TimeInterval? = nil, roundsWon: Int = 0, gameState: KidsGameState? = nil) {
        totalGamesPlayedValue += 1
        if won {
            totalWinsValue += 1
            KidsStreakManager.shared.recordPlay()
        }
        if score > highestScoreValue {
            highestScoreValue = score
        }
        
        // Check for avatar unlocks based on current stats
        let stickerCount = gameState?.collectedStickers.count ?? 0
        let hasThreeStars = (gameState?.islandStars.values.contains(3)) ?? false
        
        KidsAvatarManager.shared.checkUnlocks(
            wins: totalWinsValue,
            streak: KidsStreakManager.shared.currentStreak,
            stickers: stickerCount,
            hasThreeStars: hasThreeStars
        )
        
        // Check for badge unlocks
        KidsBadgeManager.shared.checkBadges(
            totalWords: correctWordsValue,
            lastWordTime: lastWordTime,
            streak: KidsStreakManager.shared.currentStreak,
            stickers: stickerCount,
            longestWordLength: longestWordLength > 0 ? longestWordLength : longestWordValue.count,
            roundsWonInMatch: roundsWon,
            hasThreeStars: hasThreeStars
        )
    }
    
    func resetStats() {
        totalWordsPlayedValue = 0
        totalGamesPlayedValue = 0
        totalWinsValue = 0
        correctWordsValue = 0
        incorrectAttemptsValue = 0
        totalPlayTimeValue = 0
        longestWordValue = ""
        highestScoreValue = 0
    }
}

/// Manages hint coins for the hint system
@MainActor
class KidsHintManager: ObservableObject {
    static let shared = KidsHintManager()
    
    @AppStorage("kidsHintCoins") private var hintCoinsValue: Int = 5  // Start with 5 free hints
    @Published var lastHintWord: String?
    
    private init() {}
    
    var hintCoins: Int { hintCoinsValue }
    
    /// Award hint coins (e.g., for winning, streaks, watching optional content)
    func awardCoins(_ count: Int) {
        hintCoinsValue += count
        HapticManager.shared.notification(type: .success)
    }
    
    /// Use a hint coin (returns false if no coins available)
    func useHint() -> Bool {
        guard hintCoinsValue > 0 else { return false }
        hintCoinsValue -= 1
        HapticManager.shared.impact(style: .light)
        return true
    }
    
    /// Find a valid word hint from available letters
    func findHint(letters: [String], dictionary: Set<String>) -> String? {
        guard useHint() else { return nil }
        
        // Find the longest valid word that can be made
        let availableLetters = letters.map { $0.uppercased() }
        var validWords: [String] = []
        
        // Check 3-7 letter combinations
        for word in dictionary where word.count >= 3 && word.count <= letters.count {
            var lettersCopy = availableLetters
            var canMake = true
            for char in word {
                if let idx = lettersCopy.firstIndex(of: String(char)) {
                    lettersCopy.remove(at: idx)
                } else {
                    canMake = false
                    break
                }
            }
            if canMake {
                validWords.append(word)
            }
        }
        
        // Return a random medium-length word (not the longest, to keep it fun)
        let mediumWords = validWords.filter { $0.count >= 4 && $0.count <= 5 }
        let hint = mediumWords.randomElement() ?? validWords.randomElement()
        lastHintWord = hint
        return hint
    }
}

/// Word of the Day manager
@MainActor
class KidsWordOfTheDayManager: ObservableObject {
    static let shared = KidsWordOfTheDayManager()
    
    @AppStorage("kidsLastWotdDate") private var lastWotdDate: String = ""
    @AppStorage("kidsCurrentWotd") private var currentWotdData: Data = Data()
    
    @Published var showWordOfTheDay = false
    
    struct WordOfTheDay: Codable {
        let word: String
        let definition: String
        let example: String
    }
    
    private let words: [WordOfTheDay] = [
        WordOfTheDay(word: "ADVENTURE", definition: "An exciting experience", example: "Going to the zoo was a great adventure!"),
        WordOfTheDay(word: "CURIOUS", definition: "Wanting to learn or know more", example: "The curious cat explored every room."),
        WordOfTheDay(word: "BRILLIANT", definition: "Very bright or very smart", example: "The stars look brilliant tonight!"),
        WordOfTheDay(word: "IMAGINE", definition: "To picture something in your mind", example: "Can you imagine flying like a bird?"),
        WordOfTheDay(word: "DISCOVER", definition: "To find something new", example: "Let's discover what's in this box!"),
        WordOfTheDay(word: "CREATIVE", definition: "Good at making new things", example: "She made a creative drawing."),
        WordOfTheDay(word: "EXPLORE", definition: "To travel and look around", example: "We explored the forest trail."),
        WordOfTheDay(word: "CHAMPION", definition: "A winner", example: "You're a word game champion!"),
        WordOfTheDay(word: "PUZZLE", definition: "A game that makes you think", example: "This puzzle is tricky!"),
        WordOfTheDay(word: "EXCELLENT", definition: "Very, very good", example: "What an excellent idea!"),
        WordOfTheDay(word: "FRIENDLY", definition: "Kind and nice to others", example: "The new kid is very friendly."),
        WordOfTheDay(word: "GIGANTIC", definition: "Really, really big", example: "That dinosaur was gigantic!"),
        WordOfTheDay(word: "MYSTERY", definition: "Something secret or unknown", example: "It's a mystery who ate the cookies."),
        WordOfTheDay(word: "TREASURE", definition: "Something very valuable", example: "The pirates found treasure!"),
        WordOfTheDay(word: "WONDERFUL", definition: "Really great", example: "We had a wonderful day at the park.")
    ]
    
    private init() {
        checkForNewWord()
    }
    
    var todaysWord: WordOfTheDay? {
        guard !currentWotdData.isEmpty else { return nil }
        return try? JSONDecoder().decode(WordOfTheDay.self, from: currentWotdData)
    }
    
    func checkForNewWord() {
        let today = dateString(for: Date())
        if lastWotdDate != today {
            // Pick a new word
            selectNewWord()
            lastWotdDate = today
            showWordOfTheDay = true
        }
    }
    
    private func selectNewWord() {
        // Use day of year to pick a consistent word
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let word = words[dayOfYear % words.count]
        if let data = try? JSONEncoder().encode(word) {
            currentWotdData = data
        }
    }
    
    func dismissWordOfTheDay() {
        showWordOfTheDay = false
    }
    
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
