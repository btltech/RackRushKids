import Foundation

private struct LocalDictionaryLoadedData {
    let adultWords: Set<String>
    let kidsWords: Set<String>
    let adultSignatures: [String: [String]]
    let kidsSignatures: [String: [String]]
    let blockedWords: Set<String>
    let didLoadKidsList: Bool
}

private enum LocalDictionaryLoader {
    static func loadFromBundle() -> LocalDictionaryLoadedData {
        var blockedWords: Set<String> = []

        if let blockURL = Bundle.main.url(forResource: "blocklist", withExtension: "txt"),
           let blockContent = try? String(contentsOf: blockURL, encoding: .utf8) {
            blockContent.enumerateLines { line, _ in
                let word = line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                if !word.isEmpty {
                    blockedWords.insert(word)
                }
            }
        }

        func signature(_ word: String) -> String {
            String(word.sorted())
        }

        // Kids app allows 2-letter words for young players.
        func loadWordList(resource: String) -> (words: Set<String>, signatures: [String: [String]], didLoadFile: Bool) {
            guard let url = Bundle.main.url(forResource: resource, withExtension: "txt"),
                  let content = try? String(contentsOf: url, encoding: .utf8) else {
                return ([], [:], false)
            }

            var words: Set<String> = []
            var signatures: [String: [String]] = [:]

            content.enumerateLines { line, _ in
                let word = line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                guard word.count >= 2, !blockedWords.contains(word) else { return }
                words.insert(word)
                let sig = signature(word)
                signatures[sig, default: []].append(word)
            }

            return (words, signatures, true)
        }

        let adult = loadWordList(resource: "enable")
        let kids = loadWordList(resource: "kids_enable")

        if kids.didLoadFile {
            return .init(
                adultWords: adult.words,
                kidsWords: kids.words,
                adultSignatures: adult.signatures,
                kidsSignatures: kids.signatures,
                blockedWords: blockedWords,
                didLoadKidsList: true
            )
        }

        return .init(
            adultWords: adult.words,
            kidsWords: adult.words,
            adultSignatures: adult.signatures,
            kidsSignatures: adult.signatures,
            blockedWords: blockedWords,
            didLoadKidsList: false
        )
    }
}

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

    private var loadingTask: Task<LocalDictionaryLoadedData, Never>?
    
    private init() {
        // Start loading without blocking app launch
        Task { await load() }
    }
    
    /// Load dictionary from app bundle (async version for compatibility)
    func load() async {
        guard !isLoaded else { return }

        let task = loadingTask ?? Task.detached(priority: .userInitiated) {
            LocalDictionaryLoader.loadFromBundle()
        }
        loadingTask = task

        let loaded = await task.value
        applyLoadedDataIfNeeded(loaded)

        if loadingTask?.isCancelled == false {
            loadingTask = nil
        }
    }

    private func applyLoadedDataIfNeeded(_ loaded: LocalDictionaryLoadedData) {
        guard !isLoaded else { return }

        adultWords = loaded.adultWords
        kidsWords = loaded.kidsWords
        adultSignatures = loaded.adultSignatures
        kidsSignatures = loaded.kidsSignatures
        blockedWords = loaded.blockedWords

        print("LocalDictionary: Loaded \(adultWords.count) adult words")
        if loaded.didLoadKidsList {
            print("LocalDictionary: Loaded \(kidsWords.count) kids words")
        } else {
            print("LocalDictionary: No kids_enable.txt found, using adult dictionary fallback")
        }

        isLoaded = true
        updateMode(isKids: true) // Default to kids for this app
    }

    private func ensureLoadedSync() {
        guard !isLoaded else { return }
        applyLoadedDataIfNeeded(LocalDictionaryLoader.loadFromBundle())
    }
    
    /// Switch dictionary mode
    func updateMode(isKids: Bool) {
        currentModeIsKids = isKids
        wordCount = isKids ? kidsWords.count : adultWords.count
        if isLoaded {
            print("LocalDictionary mode set to \(isKids ? "KIDS" : "ADULT"): \(wordCount) words")
        }
    }
    
    /// Get signature for a word (sorted letters)
    /// E.g., "APPLE" -> "AELPP"
    private func getSignature(_ word: String) -> String {
        String(word.sorted())
    }
    
    /// Check if word is in dictionary
    func isValid(_ word: String) -> Bool {
        ensureLoadedSync()
        let upper = word.uppercased()
        return currentModeIsKids ? kidsWords.contains(upper) : adultWords.contains(upper)
    }
    
    /// Check if word is blocked (profanity)
    func isBlocked(_ word: String) -> Bool {
        ensureLoadedSync()
        return blockedWords.contains(word.uppercased())
    }
    
    /// Validate word with reason
    func validate(_ word: String, rack: [String], minLength: Int = 2) -> (valid: Bool, reason: String?) {
        ensureLoadedSync()
        let upper = word.uppercased()
        
        if word.isEmpty {
            return (false, "No word submitted")
        }
        
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
    func findValidWords(letters: [String], minLength: Int = 3) -> [String] {
        ensureLoadedSync()
        let upperLetters = letters.map { $0.uppercased() }
        var validWords: [String] = []
        var seenSignatures: Set<String> = []
        
        let targetSignatures = currentModeIsKids ? kidsSignatures : adultSignatures
        
        // Generate all subsets of letters (length minLength+)
        generateSubsets(upperLetters, index: 0, current: []) { subset in
            guard subset.count >= minLength else { return }
            
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
