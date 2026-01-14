import Foundation

/// Thread-safe actor for fetching word definitions
/// Uses bundled local definitions first, falls back to API for unknown words
actor KidsDictionaryService {
    static let shared = KidsDictionaryService()
    
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    private var cache: [String: WordDefinition] = [:]
    private var localDefinitions: [String: String] = [:]
    private var isLocalLoaded = false
    
    struct WordDefinition: Sendable {
        let word: String
        let phonetic: String?
        let partOfSpeech: String
        let definition: String
        let example: String?
    }
    
    /// Load local definitions from bundled JSON file
    private func loadLocalDefinitions() {
        guard !isLocalLoaded else { return }
        isLocalLoaded = true
        
        guard let url = Bundle.main.url(forResource: "kids_definitions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            print("KidsDictionaryService: Could not load local definitions")
            return
        }
        
        localDefinitions = json
        print("KidsDictionaryService: Loaded \(localDefinitions.count) local definitions")
    }
    
    func fetchDefinition(for word: String) async -> WordDefinition? {
        let normalizedWord = word.lowercased()
        let upperWord = word.uppercased()
        
        // Check cache first
        if let cached = cache[normalizedWord] {
            return cached
        }
        
        // Load local definitions if not yet loaded
        loadLocalDefinitions()
        
        // Check local definitions (bundled in app - works offline)
        if let localDef = localDefinitions[upperWord] {
            let wordDef = WordDefinition(
                word: upperWord,
                phonetic: nil,
                partOfSpeech: "word",
                definition: localDef,
                example: nil
            )
            cache[normalizedWord] = wordDef
            return wordDef
        }
        
        // Fall back to API for words not in local dictionary
        return await fetchFromAPI(word: normalizedWord, upperWord: upperWord)
    }
    
    /// Fetch definition from external API (requires internet)
    private func fetchFromAPI(word: String, upperWord: String) async -> WordDefinition? {
        guard let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: baseURL + encoded) else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let firstResult = json.first else {
                return nil
            }
            
            let phonetic = firstResult["phonetic"] as? String
            
            // Get first meaning
            guard let meanings = firstResult["meanings"] as? [[String: Any]],
                  let firstMeaning = meanings.first,
                  let partOfSpeech = firstMeaning["partOfSpeech"] as? String,
                  let definitions = firstMeaning["definitions"] as? [[String: Any]],
                  let firstDef = definitions.first,
                  let definition = firstDef["definition"] as? String else {
                return nil
            }
            
            let example = firstDef["example"] as? String
            
            let wordDef = WordDefinition(
                word: upperWord,
                phonetic: phonetic,
                partOfSpeech: partOfSpeech,
                definition: definition,
                example: example
            )
            
            cache[word] = wordDef
            return wordDef
        } catch {
            return nil
        }
    }
}

