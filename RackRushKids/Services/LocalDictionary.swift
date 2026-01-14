import Foundation

/// Local Dictionary for offline word validation
/// Loads words from bundled enable.txt and validates against blocklist
@MainActor
class LocalDictionary: ObservableObject {
    static let shared = LocalDictionary()
    
    private var adultWords: Set<String> = []
    private var kidsWords: Set<String> = []
    
    private var adultSignatures: [String: [String]] = [:]
    private var kidsSignatures: [String: [String]] = [:]
    
    private var blockedWords: Set<String> = []
    
    @Published private(set) var isLoaded = false
    @Published private(set) var currentModeIsKids = true
    @Published private(set) var wordCount = 0
    
    private init() {
        Task {
            await load()
        }
    }
    
    /// Load dictionary from app bundle
    func load() async {
        guard !isLoaded else { return }
        
        // Load blocklist first
        if let blockURL = Bundle.main.url(forResource: "blocklist", withExtension: "txt"),
           let blockContent = try? String(contentsOf: blockURL, encoding: .utf8) {
            blockContent
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
                .filter { !$0.isEmpty }
                .forEach { blockedWords.insert($0) }
        }
        
        // Load adult dictionary
        if let enableURL = Bundle.main.url(forResource: "enable", withExtension: "txt"),
           let content = try? String(contentsOf: enableURL, encoding: .utf8) {
            let allWords = content
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
                .filter { $0.count >= 3 && !blockedWords.contains($0) }
            
            for word in allWords {
                adultWords.insert(word)
                let sig = getSignature(word)
                adultSignatures[sig, default: []].append(word)
            }
        }
        
        // Load kids dictionary
        if let kidsURL = Bundle.main.url(forResource: "kids_enable", withExtension: "txt"),
           let content = try? String(contentsOf: kidsURL, encoding: .utf8) {
            let allWords = content
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
                .filter { $0.count >= 2 && !blockedWords.contains($0) }  // Allow 2-letter words for young kids
            
            for word in allWords {
                kidsWords.insert(word)
                let sig = getSignature(word)
                kidsSignatures[sig, default: []].append(word)
            }
        } else {
            // Fallback to adult if kids list not available
            kidsWords = adultWords
            kidsSignatures = adultSignatures
        }
        
        isLoaded = true
        updateMode(isKids: true) // Default to kids for this app
    }
    
    /// Switch dictionary mode
    func updateMode(isKids: Bool) {
        currentModeIsKids = isKids
        wordCount = isKids ? kidsWords.count : adultWords.count
        print("LocalDictionary mode set to \(isKids ? "KIDS" : "ADULT"): \(wordCount) words")
    }
    
    /// Get signature for a word (sorted letters)
    /// E.g., "APPLE" -> "AELPP"
    private func getSignature(_ word: String) -> String {
        String(word.sorted())
    }
    
    /// Check if word is in dictionary
    func isValid(_ word: String) -> Bool {
        let upper = word.uppercased()
        return currentModeIsKids ? kidsWords.contains(upper) : adultWords.contains(upper)
    }
    
    /// Check if word is blocked (profanity)
    func isBlocked(_ word: String) -> Bool {
        blockedWords.contains(word.uppercased())
    }
    
    /// Validate word with reason
    func validate(_ word: String, rack: [String]) -> (valid: Bool, reason: String?) {
        let upper = word.uppercased()
        
        if word.isEmpty {
            return (false, "No word submitted")
        }
        
        // Young kids can use 2-letter words, older kids need 3+
        let minLength = 2
        if upper.count < minLength {
            return (false, "Word must be at least \(minLength) letters")
        }
        
        if !canBuildFromRack(upper, rack: rack) {
            return (false, "Word cannot be built from available letters")
        }
        
        if isBlocked(upper) {
            return (false, "Word is not allowed")
        }
        
        // Check kids dictionary first, then fallback to adult
        if !isValid(upper) {
            // Fallback: if it's a real word in adult dictionary, accept it
            if !adultWords.contains(upper) {
                return (false, "Word not in dictionary")
            }
        }
        
        return (true, nil)
    }
    
    /// Check if word can be built from rack letters
    private func canBuildFromRack(_ word: String, rack: [String]) -> Bool {
        var available: [Character: Int] = [:]
        for letter in rack {
            for char in letter.uppercased() {
                available[char, default: 0] += 1
            }
        }
        
        for char in word {
            guard let count = available[char], count > 0 else {
                return false
            }
            available[char] = count - 1
        }
        
        return true
    }
    
    /// Find all valid words that can be built from given letters (for bot)
    func findValidWords(letters: [String]) -> [String] {
        let upperLetters = letters.map { $0.uppercased() }
        var validWords: [String] = []
        var seenSignatures: Set<String> = []
        
        let targetSignatures = currentModeIsKids ? kidsSignatures : adultSignatures
        
        // Generate all subsets of letters (length 3+)
        generateSubsets(upperLetters, index: 0, current: []) { subset in
            guard subset.count >= 3 else { return }
            
            let sig = subset.sorted().joined()
            guard !seenSignatures.contains(sig) else { return }
            seenSignatures.insert(sig)
            
            if let matches = targetSignatures[sig] {
                validWords.append(contentsOf: matches)
            }
        }
        
        return validWords
    }
    
    /// Generate all subsets recursively
    private func generateSubsets(_ letters: [String], index: Int, current: [String], callback: ([String]) -> Void) {
        if index == letters.count {
            callback(current)
            return
        }
        
        // Include current letter
        var withCurrent = current
        withCurrent.append(letters[index])
        generateSubsets(letters, index: index + 1, current: withCurrent, callback: callback)
        
        // Exclude current letter
        generateSubsets(letters, index: index + 1, current: current, callback: callback)
    }
}
