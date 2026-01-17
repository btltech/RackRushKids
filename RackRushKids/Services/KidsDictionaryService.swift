import Foundation

/// Thread-safe actor for fetching word definitions in Kids app.
/// Uses bundled local kids definitions first (works offline).
/// This is a simplified version for the standalone Kids app.
actor KidsDictionaryService {
    static let shared = KidsDictionaryService()
    
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    private var cache: [String: WordDefinition] = [:]
    private var localKidsDefinitions: [String: String] = [:]
    private var isLocalKidsLoaded = false
    
    struct WordDefinition: Sendable {
        let word: String
        let phonetic: String?
        let partOfSpeech: String
        let definition: String
        let example: String?
        let isVerified: Bool  // Indicates if from verified source
        let source: DefinitionSource  // Source of the definition
    }
    
    enum DefinitionSource: String, Sendable {
        case curatedKids = "Kids Dictionary"  // Hand-curated, most reliable
        case dictionaryAPI = "Dictionary API"  // Free Dictionary API - verified
        case stemmed = "Related Word"  // Derived from base word - lower confidence
    }
    
    /// Load local kids definitions from bundled JSON file
    private func loadLocalKidsDefinitions() {
        guard !isLocalKidsLoaded else { return }
        isLocalKidsLoaded = true
        
        guard let url = Bundle.main.url(forResource: "kids_definitions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            print("KidsDictionaryService: Could not load local kids definitions")
            return
        }
        
        localKidsDefinitions = json
        print("KidsDictionaryService: Loaded \(localKidsDefinitions.count) local kids definitions")
    }
    
    func fetchDefinition(for word: String, ageGroup: KidsAgeGroup = .medium) async -> WordDefinition? {
        let normalizedWord = word.lowercased()
        let upperWord = word.uppercased()
        
        // Check cache first (actor-isolated, so thread-safe)
        if let cached = cache[normalizedWord] {
            return cached
        }
        
        // Check local definitions first (works offline, always preferred for kids)
        loadLocalKidsDefinitions()
        
        if let localDef = localKidsDefinitions[upperWord] {
            let wordDef = WordDefinition(
                word: upperWord,
                phonetic: nil,
                partOfSpeech: "word",
                definition: localDef,
                example: nil,
                isVerified: true,  // Curated definitions are verified
                source: .curatedKids
            )
            cache[normalizedWord] = wordDef
            return wordDef
        }

        // Online definition lookup (with safety filtering)
        if let apiDef = await fetchFromDictionaryAPI(for: normalizedWord, originalWord: word),
           let def = await sanitizeForKids(apiDef, ageGroup: ageGroup) {
            cache[normalizedWord] = def
            return def
        }

        // Fallback: try stemming to improve hit rate (marked as lower confidence)
        if let stemmedDef = await tryStemmedWord(normalizedWord),
           let def = await sanitizeForKids(stemmedDef, ageGroup: ageGroup) {
            cache[normalizedWord] = def
            return def
        }

        return nil
    }

    private func sanitizeForKids(_ definition: WordDefinition, ageGroup: KidsAgeGroup) async -> WordDefinition? {
        // Never show examples in Kids app
        let safeCandidate = WordDefinition(
            word: definition.word,
            phonetic: nil,
            partOfSpeech: definition.partOfSpeech,
            definition: definition.definition,
            example: nil,
            isVerified: definition.isVerified,
            source: definition.source
        )

        // Best-effort safety filter on definition text using provided age group
        let isSafe = await MainActor.run {
            KidsWordFilter.shared.isSafeDefinitionText(safeCandidate.definition, forAge: ageGroup)
        }
        guard isSafe else {
            return nil
        }

        return safeCandidate
    }

    // MARK: - Dictionary API
    private func fetchFromDictionaryAPI(for normalizedWord: String, originalWord: String) async -> WordDefinition? {
        guard let encoded = normalizedWord.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: baseURL + encoded) else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let firstResult = json.first else {
                return nil
            }

            return parseDictionaryAPIResponse(firstResult, originalWord: originalWord, normalizedWord: normalizedWord)
        } catch {
            return nil
        }
    }

    private func parseDictionaryAPIResponse(_ result: [String: Any], originalWord: String, normalizedWord: String) -> WordDefinition? {
        // VERIFY: API returns the exact word we requested
        if let returnedWord = result["word"] as? String,
           returnedWord.lowercased() != normalizedWord {
            // API returned a different word - reject to avoid misleading definitions
            print("KidsDictionaryService: Word mismatch - requested '\(normalizedWord)', got '\(returnedWord)'")
            return nil
        }
        
        let phonetic = result["phonetic"] as? String

        guard let meanings = result["meanings"] as? [[String: Any]],
              let firstMeaning = meanings.first,
              let partOfSpeech = firstMeaning["partOfSpeech"] as? String,
              let definitions = firstMeaning["definitions"] as? [[String: Any]],
              let firstDef = definitions.first,
              let definition = firstDef["definition"] as? String else {
            return nil
        }

        // Don't use examples from API for kids - may not be age-appropriate
        return WordDefinition(
            word: originalWord.uppercased(),
            phonetic: phonetic,
            partOfSpeech: partOfSpeech,
            definition: definition,
            example: nil,
            isVerified: true,  // Dictionary API is a verified source
            source: .dictionaryAPI
        )
    }

    // MARK: - Stemming fallback (lower confidence)
    private func tryStemmedWord(_ word: String) async -> WordDefinition? {
        let suffixes = ["s", "es", "ed", "ing", "ly"]

        for suffix in suffixes where word.hasSuffix(suffix) {
            let stem = String(word.dropLast(suffix.count))
            if stem.count >= 3, let def = await fetchFromDictionaryAPI(for: stem, originalWord: word) {
                return WordDefinition(
                    word: word.uppercased(),
                    phonetic: def.phonetic,
                    partOfSpeech: def.partOfSpeech,
                    definition: "(Form of \(stem.uppercased())): \(def.definition)",
                    example: nil,
                    isVerified: false,  // Stemmed definitions are lower confidence
                    source: .stemmed
                )
            }
        }
        return nil
    }
    
    func fetchDefinitions(for words: [String]) async -> [String: WordDefinition] {
        var results: [String: WordDefinition] = [:]
        
        await withTaskGroup(of: (String, WordDefinition?).self) { group in
            for word in words where !word.isEmpty {
                group.addTask {
                    let definition = await self.fetchDefinition(for: word)
                    return (word, definition)
                }
            }
            
            for await (word, definition) in group {
                if let def = definition {
                    results[word.uppercased()] = def
                }
            }
        }
        
        return results
    }
    
    /// Clear the cache (useful for testing or memory pressure)
    func clearCache() {
        cache.removeAll()
    }
}
