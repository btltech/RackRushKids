import AVFoundation

/// High-performance TTS service for Kids Mode with pre-warming for instant response
@MainActor
class KidsTTSService: NSObject, ObservableObject {
    static let shared = KidsTTSService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var isWarmedUp = false
    @Published var isSpeaking = false
    
    // Pre-loaded voice for faster access
    private var cachedVoice: AVSpeechSynthesisVoice?
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        
        // Pre-cache the voice
        cachedVoice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Pre-warm the synthesizer on init (silent utterance)
        warmUp()
    }
    
    // MARK: - Pre-warming
    
    /// Pre-warm the TTS engine with a silent utterance so first real speak is instant
    func warmUp() {
        guard !isWarmedUp else { return }
        
        // Configure audio session for low latency
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ TTS: Audio session setup failed: \(error)")
        }
        
        // Speak a silent/empty utterance to initialize the engine
        let silentUtterance = AVSpeechUtterance(string: " ")
        silentUtterance.volume = 0 // Completely silent
        silentUtterance.rate = AVSpeechUtteranceMaximumSpeechRate
        silentUtterance.voice = cachedVoice
        
        synthesizer.speak(silentUtterance)
        isWarmedUp = true
        
        print("🔊 TTS: Pre-warmed and ready")
    }
    
    // MARK: - Speaking
    
    /// Speak a word immediately with kid-friendly voice settings
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Stop any ongoing speech immediately
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        isSpeaking = true
        
        let utterance = AVSpeechUtterance(string: text.lowercased())
        
        // Optimized settings for responsiveness
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95  // Slightly slower for kids
        utterance.pitchMultiplier = 1.1  // Friendly, slightly higher pitch
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.0  // No delay - instant start
        utterance.postUtteranceDelay = 0.0
        utterance.voice = cachedVoice
        
        synthesizer.speak(utterance)
    }
    
    /// Stop any ongoing speech
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension KidsTTSService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
