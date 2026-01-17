import Foundation

/// Local Bot Player for offline gameplay
/// Matches server-side BotPlayer.ts logic
class LocalBotPlayer {
    enum Difficulty: String, CaseIterable {
        case veryEasy = "very_easy"
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
    }
    
    let id: String
    let name: String
    let skillLevel: Double // 0.0 to 1.0
    
    init(name: String, skillLevel: Double) {
        self.id = "bot-\(UUID().uuidString)"
        self.name = name
        self.skillLevel = skillLevel
    }
    
    /// Schedule bot submission with callback
    func scheduleSubmission(letters: [String], bonuses: [(index: Int, type: String)], onSubmit: @escaping (String, Int) -> Void) {
        let delay = getDelay()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            // Find valid words using local dictionary
            let validWords = LocalDictionary.shared.findValidWords(letters: letters)
            
            if validWords.isEmpty {
                onSubmit("", 0)
                return
            }
            
            // Score all words with length consideration
            let scoredWords = validWords.map { word -> (word: String, score: Int, length: Int) in
                let score = LocalScorer.shared.calculate(word: word, rack: letters, bonuses: bonuses)
                return (word, score, word.count)
            }.sorted { 
                // Sort by score, then length as tiebreaker
                if $0.score != $1.score {
                    return $0.score > $1.score
                }
                return $0.length > $1.length
            }
            
            // Pick word based on skill level
            let (word, score, _) = self.pickWord(scoredWords)
            onSubmit(word, score)
        }
    }
    
    /// Pick word based on skillLevel - kid-friendly logic
    private func pickWord(_ scoredWords: [(word: String, score: Int, length: Int)]) -> (String, Int, Int) {
        let total = scoredWords.count
        guard total > 0 else { return ("", 0, 0) }
        
        // Map skillLevel (0.0-1.0) to an index. 
        // 1.0 = index 0 (best word), 0.0 = index total-1 (worst word)
        // Add some randomness so it's not perfect
        let baseIndex = Int(Double(total - 1) * (1.0 - skillLevel))
        let variance = Int(Double(total) * 0.2) // 20% variance
        let minIdx = max(0, baseIndex - variance)
        let maxIdx = min(total - 1, baseIndex + variance)
        
        let pickIndex = Int.random(in: minIdx...maxIdx)
        
        return scoredWords[pickIndex]
    }
    
    /// Get random delay based on skillLevel
    private func getDelay() -> Double {
        // Higher skill = faster response
        // 0.0 = 8.0-12.0s, 1.0 = 2.0-4.0s
        let minDelay = 12.0 - (skillLevel * 10.0) // 12 -> 2
        let maxDelay = minDelay + 4.0
        return Double.random(in: minDelay...maxDelay)
    }
    
    // MARK: - Name Generation
    
    private static let adjectives = [
        "Swift", "Clever", "Quick", "Sharp", "Bright", "Bold", "Keen", "Witty",
        "Smart", "Agile", "Noble", "Grand", "Prime", "Elite", "Alpha", "Mega"
    ]
    
    private static let nouns = [
        "Fox", "Hawk", "Wolf", "Bear", "Lion", "Tiger", "Eagle", "Falcon",
        "Raven", "Cobra", "Viper", "Phoenix", "Dragon", "Knight", "Wizard", "Ninja"
    ]
    
    private static let kidsAdjectives = [
        "Happy", "Brave", "Clever", "Quick", "Bright", "Cool", "Swift", "Lucky"
    ]
    
    private static let kidsNouns = [
        "Panda", "Tiger", "Eagle", "Dolphin", "Fox", "Owl", "Wolf", "Bear"
    ]
    
    static func generateRandomName() -> String {
        let adj = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        let num = Int.random(in: 0...99)
        return "\(adj)\(noun)\(num) (Bot)"
    }
    
    static func generateKidsName() -> String {
        let adj = kidsAdjectives.randomElement()!
        let noun = kidsNouns.randomElement()!
        return "\(adj)\(noun)"
    }
}
