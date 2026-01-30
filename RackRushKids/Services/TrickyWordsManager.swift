import SwiftUI

/// Tracks "tricky words" that the child struggled with during gameplay.
/// - On-device only, no cloud sync
/// - Daily reset to avoid long-term profiling
/// - Parent-only access (PIN-gated)
@MainActor
class TrickyWordsManager: ObservableObject {
    static let shared = TrickyWordsManager()
    
    // MARK: - Data Model
    
    struct WordAttempt: Codable, Identifiable {
        let id: UUID
        let word: String
        let timestamp: Date
        let wasCorrect: Bool
        let ageGroup: String
    }
    
    struct DailySummary: Codable {
        let date: String  // "2026-01-24" format
        var attempts: [WordAttempt]
    }
    
    // MARK: - Storage
    
    @AppStorage("trickyWords_todayData") private var todayDataRaw: Data = Data()
    
    @Published private(set) var todaySummary: DailySummary?
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    private init() {
        loadToday()
    }
    
    // MARK: - Public API
    
    /// Records a word attempt (called after each word submission)
    func recordAttempt(word: String, wasCorrect: Bool, ageGroup: KidsAgeGroup) {
        guard KidsFeatureFlags.shared.trickyWordsEnabled else { return }
        
        ensureTodayExists()
        
        let attempt = WordAttempt(
            id: UUID(),
            word: word.uppercased(),
            timestamp: Date(),
            wasCorrect: wasCorrect,
            ageGroup: ageGroup.rawValue
        )
        
        todaySummary?.attempts.append(attempt)
        saveToday()
    }
    
    /// Returns today's tricky words (incorrect attempts only)
    var trickyWords: [String] {
        guard let summary = todaySummary else { return [] }
        
        // Get words that were missed at least once, sorted by frequency
        let missed = summary.attempts.filter { !$0.wasCorrect }
        
        let wordCounts = Dictionary(grouping: missed, by: { $0.word })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .map { $0.key }
        
        return Array(wordCounts.prefix(20))  // Max 20 words
    }
    
    /// Returns all words practiced today with stats
    var allWordsWithStats: [(word: String, attempts: Int, correct: Int)] {
        guard let summary = todaySummary else { return [] }
        
        let grouped = Dictionary(grouping: summary.attempts, by: { $0.word })
        
        return grouped.map { word, attempts in
            let correct = attempts.filter { $0.wasCorrect }.count
            return (word: word, attempts: attempts.count, correct: correct)
        }
        .sorted { $0.attempts > $1.attempts }
        .prefix(20)
        .map { $0 }
    }
    
    /// Total attempts today
    var totalAttemptsToday: Int {
        todaySummary?.attempts.count ?? 0
    }
    
    /// Correct rate today (0.0 - 1.0)
    var correctRateToday: Double {
        guard let summary = todaySummary, !summary.attempts.isEmpty else { return 0 }
        let correct = summary.attempts.filter { $0.wasCorrect }.count
        return Double(correct) / Double(summary.attempts.count)
    }
    
    /// Resets today's data (parent can use this)
    func resetToday() {
        let today = dateFormatter.string(from: Date())
        todaySummary = DailySummary(date: today, attempts: [])
        saveToday()
    }
    
    // MARK: - Private Helpers
    
    private func loadToday() {
        let today = dateFormatter.string(from: Date())
        
        guard !todayDataRaw.isEmpty,
              let decoded = try? JSONDecoder().decode(DailySummary.self, from: todayDataRaw) else {
            // No data or failed to decode - start fresh
            todaySummary = DailySummary(date: today, attempts: [])
            return
        }
        
        // Check if data is from today
        if decoded.date == today {
            todaySummary = decoded
        } else {
            // Different day - reset
            todaySummary = DailySummary(date: today, attempts: [])
            saveToday()
        }
    }
    
    private func ensureTodayExists() {
        let today = dateFormatter.string(from: Date())
        
        if todaySummary?.date != today {
            todaySummary = DailySummary(date: today, attempts: [])
        }
    }
    
    private func saveToday() {
        guard let summary = todaySummary,
              let data = try? JSONEncoder().encode(summary) else { return }
        todayDataRaw = data
    }
}
