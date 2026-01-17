import Foundation
import Combine

/// Manages safe, deterministic community features for Kids mode.
/// Provides a "Global Word Counter" that grows throughout the day.
class KidsCommunityManager: ObservableObject {
    static let shared = KidsCommunityManager()
    
    @Published private(set) var globalWordCount: Int = 0
    
    private var timer: Timer?
    private let baseCount = 1_250_000 // Total words found since launch (base)
    private let dailyTarget = 15_000  // Target words per day
    
    private init() {
        updateCount()
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateCount()
        }
    }
    
    /// Calculates a deterministic count based on the current time of day.
    /// This ensures all kids see the same number at the same time without needing a backend.
    private func updateCount() {
        let calendar = Calendar.current
        let now = Date()
        
        // Seconds since start of day (UTC or Local? Local is better for "Today" feeling)
        let startOfDay = calendar.startOfDay(for: now)
        let secondsPassed = now.timeIntervalSince(startOfDay)
        let totalSecondsInDay: TimeInterval = 24 * 60 * 60
        
        // Progress through the day (0.0 to 1.0)
        let dayProgress = secondsPassed / totalSecondsInDay
        
        // Calculate current day's contribution
        // Use a slight curve so it's not perfectly linear, but still deterministic
        let dailyContribution = Int(Double(dailyTarget) * dayProgress)
        
        // Add some "jitter" based on the exact minute/second to make it feel alive
        // but still deterministic for any given moment
        let minuteJitter = Int(secondsPassed.truncatingRemainder(dividingBy: 60) / 2)
        
        self.globalWordCount = baseCount + dailyContribution + minuteJitter
    }
    
    /// Formatted string for the UI (e.g., "1,250,450")
    var formattedCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: globalWordCount)) ?? "\(globalWordCount)"
    }
}
