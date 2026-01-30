import Foundation
import SwiftUI
import Combine

/// Manages daily challenge state for the Kids app
@MainActor
class KidsDailyChallengeManager: ObservableObject {
    static let shared = KidsDailyChallengeManager()
    
    // MARK: - Published State
    @Published var todayChallenge: DailyChallenge?
    @Published var hasCompletedToday: Bool = false
    @Published var isLoading: Bool = false
    
    // MARK: - Persistence
    @AppStorage("kidsLastChallengeDate") private var lastChallengeDateString: String = ""
    @AppStorage("kidsDailyChallengeBestScore") private var storedBestScore: Int = 0
    
    // Access current age group from user settings
    @AppStorage("kidsAgeGroup") private var ageGroupString: String = KidsAgeGroup.medium.rawValue
    @AppStorage("kidsExtraChallengeEnabled") private var extraChallengeEnabled: Bool = false
    
    var selectedAgeGroup: KidsAgeGroup {
        KidsAgeGroup(rawValue: ageGroupString) ?? .medium
    }
    
    private init() {
        loadTodayChallenge()
    }
    
    // MARK: - Public Methods
    
    /// UTC calendar for consistent daily challenge across timezones
    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal
    }
    
    func loadTodayChallenge() {
        isLoading = true
        
        let today = utcCalendar.startOfDay(for: Date())
        todayChallenge = generateChallenge(for: today)
        
        // Check if already completed today
        if let lastDate = dateFromString(lastChallengeDateString),
           utcCalendar.isDate(lastDate, inSameDayAs: today) {
            hasCompletedToday = true
        } else {
            hasCompletedToday = false
        }
        
        isLoading = false
    }
    
    func submitCompletion() {
        guard !hasCompletedToday else { return }
        
        let today = utcCalendar.startOfDay(for: Date())
        hasCompletedToday = true
        lastChallengeDateString = stringFromDate(today)
    }
    
    // MARK: - Private Methods
    
    private func generateChallenge(for date: Date) -> DailyChallenge {
        let daysSince1970 = Int(date.timeIntervalSince1970 / 86400)
        var generator = SeededRandomGenerator(seed: UInt64(daysSince1970))
        
        // Generate letters based on age group
        let letterCount = selectedAgeGroup.effectiveLetterCount(extraChallengeEnabled: extraChallengeEnabled)
        let letters = generateKidFriendlyLetters(count: letterCount, using: &generator)
        
        // Bonus tiles - scale with letter count
        let bonusCount = max(1, letterCount - 4)  // 1 for 5 letters, 2 for 6, 3 for 7
        let bonuses = generateKidBonuses(count: bonusCount, maxIndex: letterCount, using: &generator)
        
        return DailyChallenge(
            id: "kids-daily-\(daysSince1970)",
            date: date,
            letters: letters,
            bonuses: bonuses,
            participantCount: nil
        )
    }
    
    private func generateKidFriendlyLetters(count: Int, using generator: inout SeededRandomGenerator) -> [String] {
        let vowels = ["A", "E", "I", "O", "U"]
        let commonConsonants = ["B", "C", "D", "F", "G", "H", "L", "M", "N", "P", "R", "S", "T", "W"]
        
        var letters: [String] = []
        
        // Guaranteed vowels (scale with letter count: 2 for 5, 3 for 6, 4 for 7)
        let vowelCount = max(2, count - 3)
        for _ in 0..<vowelCount {
            letters.append(vowels[Int(generator.next() % UInt64(vowels.count))])
        }
        
        // Fill remaining with common consonants
        let consonantCount = count - vowelCount
        for _ in 0..<consonantCount {
            letters.append(commonConsonants[Int(generator.next() % UInt64(commonConsonants.count))])
        }
        
        return letters.shuffled(using: &generator)
    }
    
    private func generateKidBonuses(count: Int, maxIndex: Int, using generator: inout SeededRandomGenerator) -> [BonusTile] {
        var bonuses: [BonusTile] = []
        let bonusTypes = ["DL", "TL", "DW"]
        
        var usedIndices = Set<Int>()
        
        for _ in 0..<count {
            var index: Int
            repeat {
                index = Int(generator.next() % UInt64(maxIndex))
            } while usedIndices.contains(index)
            
            usedIndices.insert(index)
            let type = bonusTypes[Int(generator.next() % UInt64(bonusTypes.count))]
            bonuses.append(BonusTile(index: index, type: type))
        }
        
        return bonuses
    }
    
    // MARK: - Date Helpers
    private func stringFromDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    private func dateFromString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}

// Reuse SeededRandomGenerator from adult app if possible, or redefine here
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
// MARK: - Models

struct BonusTile: Codable, Hashable {
    let index: Int
    let type: String // "DL", "TL", "DW", "TW"
}

struct DailyChallenge: Identifiable {
    let id: String
    let date: Date
    let letters: [String]
    let bonuses: [BonusTile]
    let participantCount: Int?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
