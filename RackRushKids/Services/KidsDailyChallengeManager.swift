import Foundation
import SwiftUI
import Combine

/// Manages daily challenge state for the Kids app
class KidsDailyChallengeManager: ObservableObject {
    static let shared = KidsDailyChallengeManager()
    
    // MARK: - Published State
    @Published var todayChallenge: DailyChallenge?
    @Published var hasCompletedToday: Bool = false
    @Published var isLoading: Bool = false
    
    // MARK: - Persistence
    @AppStorage("kidsLastChallengeDate") private var lastChallengeDateString: String = ""
    @AppStorage("kidsDailyChallengeBestScore") private var storedBestScore: Int = 0
    
    private init() {
        loadTodayChallenge()
    }
    
    // MARK: - Public Methods
    
    /// UTC calendar for consistent daily challenge across timezones
    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
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
        
        // Generate 7 letters - kid-friendly (guaranteed 3-4 vowels)
        let letters = generateKidFriendlyLetters(using: &generator)
        
        // Bonus tiles for kids (more frequent, but simpler)
        let bonuses = generateKidBonuses(using: &generator)
        
        return DailyChallenge(
            id: "kids-daily-\(daysSince1970)",
            date: date,
            letters: letters,
            bonuses: bonuses,
            participantCount: nil // Would require backend to track
        )
    }
    
    private func generateKidFriendlyLetters(using generator: inout SeededRandomGenerator) -> [String] {
        let vowels = ["A", "E", "I", "O", "U"]
        let commonConsonants = ["B", "C", "D", "F", "G", "H", "L", "M", "N", "P", "R", "S", "T", "W"]
        
        var letters: [String] = []
        
        // Guaranteed 4 vowels for kids
        for _ in 0..<4 {
            letters.append(vowels[Int(generator.next() % UInt64(vowels.count))])
        }
        
        // Fill remaining with common consonants
        for _ in 0..<3 {
            letters.append(commonConsonants[Int(generator.next() % UInt64(commonConsonants.count))])
        }
        
        return letters.shuffled(using: &generator)
    }
    
    private func generateKidBonuses(using generator: inout SeededRandomGenerator) -> [BonusTile] {
        var bonuses: [BonusTile] = []
        let bonusTypes = ["DL", "TL", "DW"]
        
        // Kids get 3 bonus tiles for more fun
        let count = 3
        var usedIndices = Set<Int>()
        
        for _ in 0..<count {
            var index: Int
            repeat {
                index = Int(generator.next() % 7)
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
