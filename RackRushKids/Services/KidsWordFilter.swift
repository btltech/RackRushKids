import Foundation

// MARK: - Kids Word Filter
/// Safe word filter for kids - uses exact match only to avoid false positives.
/// Incorporates UK DfE Key Stage 2 (KS2) statutory spelling lists for age-appropriate suggestions.
/// Implements strict safety filtering for "Kids Mode".

@MainActor
class KidsWordFilter {
    static let shared = KidsWordFilter()
    
    // MARK: - Blocklist (Exact Match Only)
    
    /// Words blocked for all kids - strict safety filter.
    /// Covers profanity, violence, adult concepts, and bullying.
    private let blockedWords: Set<String> = [
        // Common profanity
        "ass", "damn", "hell", "crap", "shit", "fuck",
        "bitch", "slut", "dick", "cock", "piss", "bastard", "wanker", "bollocks", "bugger", "twat", "arse",
        
        // Slurs (Race/Gender/Orientation)
        "fag", "homo", "nigger", "paki", "spic", "chink", "dyke", "tranny", "retard", "spastic",
        
        // Violence / Weapons
        "kill", "murder", "die", "dead", "blood", "bleed",
        "gun", "shoot", "bomb", "knife", "stab", "weapon", "terror", "terrorist",
        "war", "fight", "attack", "hurt", "pain", "suicide",
        
        // Sexual / Adult
        "sex", "porn", "nude", "naked", "breast", "boob", "boobs", "penis", "vagina", "anus", "rectum",
        "rape", "incest", "molest", "pedophile", "paedophile", "groom", "lube", "condom", "erotic",
        
        // Drugs / Alcohol
        "drug", "weed", "drunk", "beer", "wine", "vodka", "cocaine", "heroin", "meth", "high", "stoned",
        
        // Bullying / Negative
        "hate", "stupid", "dumb", "ugly", "fat", "loser", "idiot", "smell", "stink", "crazy", "mad"
    ]
    
    /// Additional words blocked for younger kids (4-6) - "Scary/Complex"
    private let blockedForYoung: Set<String> = [
        // Scary concepts
        "monster", "ghost", "zombie", "witch", "demon", "devil", "skeleton", "vampire",
        
        // Mildly scary / Dark
        "scary", "dark", "afraid", "scream", "nightmare", "shadow", "fear", "dread",
        
        // Negative emotions
        "sad", "angry", "cry", "fear", "lonely"
    ]
    
    // MARK: - Safe Vocabulary (UK DfE KS2 Standard)
    
    /// Foundation words (KS1 & Early Years) - Simple CVC and common words
    private let foundationWords: Set<String> = [
        "cat", "dog", "bat", "rat", "pig", "cow", "hen", "bee", "ant", "bug",
        "fish", "bird", "duck", "frog", "goat", "lion", "bear", "deer", "wolf",
        "sun", "sky", "sea", "tree", "leaf", "rain", "snow", "wind", "star", "moon",
        "apple", "cake", "pie", "egg", "milk", "rice", "corn", "bean", "pea",
        "ball", "toy", "book", "cup", "hat", "bed", "box", "bag", "key", "pen",
        "run", "jump", "hop", "sit", "eat", "play", "read", "sing", "draw", "swim",
        "red", "blue", "pink", "gold", "tan",
        "big", "top", "hot", "new", "old", "fun", "good", "nice", "cool", "best",
        // Common short words to ensure playability
        "is", "it", "at", "to", "in", "on", "no", "go", "my", "by", "up", "us",
        "am", "an", "as", "be", "do", "he", "hi", "if", "me", "of", "or", "so", "we"
    ]

    /// Key Stage 2 (Years 3 & 4) Statutory Spelling List
    private let ks2Year34Words: Set<String> = [
        "accident", "actual", "address", "answer", "appear", "arrive", "believe", "bicycle", "breath", "build",
        "busy", "calendar", "caught", "centre", "century", "certain", "circle", "complete", "consider", "continue",
        "decide", "describe", "different", "difficult", "disappear", "early", "earth", "eight", "enough", "exercise",
        "experience", "experiment", "extreme", "famous", "favorite", "february", "forward", "fruit", "grammar", "group",
        "guard", "guide", "heard", "heart", "height", "history", "imagine", "increase", "important", "interest",
        "island", "knowledge", "learn", "length", "library", "material", "medicine", "mention", "minute", "natural",
        "naughty", "notice", "occasion", "often", "opposite", "ordinary", "particular", "peculiar", "perhaps", "popular",
        "position", "possess", "possible", "potatoes", "pressure", "probably", "promise", "purpose", "quarter", "question",
        "recent", "regular", "reign", "remember", "sentence", "separate", "special", "straight", "strange", "strength",
        "suppose", "surprise", "therefore", "though", "thought", "through", "various", "weight", "woman", "women"
    ]
    
    /// Key Stage 2 (Years 5 & 6) Statutory Spelling List
    private let ks2Year56Words: Set<String> = [
        "accommodate", "accompany", "according", "achieve", "aggressive", "amateur", "ancient", "apparent", "appreciate",
        "attached", "available", "average", "awkward", "bargain", "bruise", "category", "cemetery", "committee",
        "communicate", "community", "competition", "conscience", "conscious", "controversy", "convenience", "correspond",
        "criticise", "curiosity", "definite", "desperate", "determined", "develop", "dictionary", "disastrous", "embarrass",
        "environment", "equip", "especially", "exaggerate", "excellent", "existence", "explanation", "familiar",
        "foreign", "forty", "frequently", "government", "guarantee", "harass", "hindrance", "identity", "immediate",
        "individual", "interfere", "interrupt", "language", "leisure", "lightning", "marvellous", "mischievous",
        "muscle", "necessary", "neighbour", "nuisance", "occupy", "occur", "opportunity", "parliament", "persuade",
        "physical", "prejudice", "privilege", "profession", "programme", "pronunciation", "queue", "recognise",
        "recommend", "relevant", "restaurant", "rhyme", "rhythm", "sacrifice", "secretary", "shoulder", "signature",
        "sincere", "soldier", "stomach", "sufficient", "suggest", "symbol", "system", "temperature", "thorough",
        "twelfth", "variety", "vegetable", "vehicle", "yacht"
    ]
    
    // MARK: - Validation
    
    /// Check if a word is appropriate for kids (strict exact match filtering)
    func isAppropriate(_ word: String, forAge ageGroup: KidsAgeGroup) -> Bool {
        let lowercased = word.lowercased().trimmingCharacters(in: .whitespaces)
        
        // 1. Check strict universal blocklist (Safety)
        if blockedWords.contains(lowercased) {
            return false
        }
        
        // 2. Additional age-specific filtering
        if ageGroup == .young { // Ages 4-6
            // Block scary/complex negative concepts
            if blockedForYoung.contains(lowercased) {
                return false
            }
        }
        
        // Word is considered safe
        return true
    }

    /// Best-effort safety check for externally sourced definition text.
    func isSafeDefinitionText(_ text: String, forAge ageGroup: KidsAgeGroup) -> Bool {
        let tokens = text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        if tokens.contains(where: { blockedWords.contains($0) }) {
            return false
        }

        if ageGroup == .young, tokens.contains(where: { blockedForYoung.contains($0) }) {
            return false
        }

        return true
    }
    
    /// Generate a kid-friendly rejection message based on age
    func rejectionMessage(for ageGroup: KidsAgeGroup) -> String {
        switch ageGroup {
        case .young:
            return "Try another word! 🌟"
        case .medium:
            return "Let's try a different word! ✨"
        case .older:
            return "That word isn't available. Try another!"
        }
    }
    
    // MARK: - Word Suggestions (Educational)
    
    /// Get random safe word suggestions appropriate for the age group
    /// Uses UK DfE KS2 standards for older groups
    func getSuggestions(for ageGroup: KidsAgeGroup, count: Int = 3) -> [String] {
        var wordPool: Set<String>
        
        switch ageGroup {
        case .young:
            // Foundation words only (Simple CVC, Animals, Colors)
            wordPool = foundationWords
            
        case .medium:
            // Foundation + Year 3/4 words
            wordPool = foundationWords.union(ks2Year34Words)
            
        case .older:
            // Year 3/4 + Year 5/6 words (Challenging)
            wordPool = ks2Year34Words.union(ks2Year56Words)
            // Add some foundation words for variety but focus on curriculum
            wordPool.formUnion(foundationWords)
        }
        
        // Filter out any accidentally blocked words (just in case lists overlap, though they shouldn't)
        let safePool = wordPool.filter { !blockedWords.contains($0) }
        
        return Array(safePool.shuffled().prefix(count))
    }
    
    // MARK: - Bot Logic
    
    /// Find a valid word from the safe dictionary that can be formed with the given letters, respecting skill level
    func getPossibleWord(from letters: [String], for ageGroup: KidsAgeGroup, skillLevel: Double = 0.5) -> String? {
        // Find all valid words in the current (kids) dictionary
        let validWords = LocalDictionary.shared.findValidWords(letters: letters)
        guard !validWords.isEmpty else { return nil }
        
        // Score them to rank by difficulty
        let scored = validWords.map { word -> (word: String, score: Int) in
            let score = LocalScorer.shared.calculate(word: word, rack: letters, bonuses: [])
            return (word, score)
        }.sorted { $0.score > $1.score }
        
        // Pick based on skill level
        let targetIdx = Int(Double(scored.count - 1) * (1.0 - skillLevel))
        let variance = max(1, Int(Double(scored.count) * 0.2))
        let minIdx = max(0, targetIdx - variance)
        let maxIdx = min(scored.count - 1, targetIdx + variance)
        
        return scored[Int.random(in: minIdx...maxIdx)].word
    }
    
    private func getLexicon(for ageGroup: KidsAgeGroup) -> Set<String> {
        switch ageGroup {
        case .young: return foundationWords
        case .medium: return foundationWords.union(ks2Year34Words)
        case .older: return ks2Year34Words.union(ks2Year56Words).union(foundationWords)
        }
    }
    
    private func canMake(word: String, with letterCounts: [Character: Int]) -> Bool {
        var counts = letterCounts
        for char in word.uppercased() {
            if let count = counts[char], count > 0 {
                counts[char] = count - 1
            } else {
                return false
            }
        }
        return true
    }
}
