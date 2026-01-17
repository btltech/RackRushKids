import AVFoundation
import AudioToolbox
import SwiftUI

/// Kids Audio Manager - Synthesized sound effects for a playful experience
class KidsAudioManager: ObservableObject {
    static let shared = KidsAudioManager()
    
    @AppStorage("kidsSoundEnabled") var isSoundEnabled = true
    @AppStorage("kidsHapticsEnabled") var isHapticsEnabled = true
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    private var isSetupComplete = false
    
    // MARK: - Throttling (max 10 sounds per second)
    private var lastSoundTime: Date = .distantPast
    private let minSoundInterval: TimeInterval = 0.1
    
    private init() {
        // Defer audio setup to background thread to speed up app launch
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupAudioEngine()
        }
    }
    
    private func setupAudioEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            
            guard let engine = audioEngine, let player = playerNode else { return }
            
            engine.attach(player)
            
            let mixerFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            audioFormat = mixerFormat
            
            engine.connect(player, to: engine.mainMixerNode, format: mixerFormat)
            
            try engine.start()
            
            // K8 Fix: Handle audio session interruptions
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let info = notification.userInfo,
                      let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
                
                if type == .ended {
                    try? self?.audioEngine?.start()
                }
            }
        } catch {
            print("Audio engine setup failed: \(error)")
        }
    }
    
    // MARK: - Sound Effects (Cuter/Higher Pitch for Kids)
    
    func playPop() {
        if isSoundEnabled {
            // High pitched pop
            playTone(frequency: 880, duration: 0.05, volume: 0.3) // A5
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    func playDelete() {
        if isSoundEnabled {
            // Quick swoop down
            playTone(frequency: 600, duration: 0.05, volume: 0.25)
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    func playSubmit() {
        if isSoundEnabled {
            // Happy rising chime
            playTone(frequency: 880, duration: 0.08, volume: 0.4) // A5
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                self.playTone(frequency: 1109, duration: 0.1, volume: 0.4) // C#6
            }
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    func playWin() {
        if isSoundEnabled {
            // Victory fanfare (Major triad)
            playTone(frequency: 784, duration: 0.15, volume: 0.5)  // G5
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.playTone(frequency: 988, duration: 0.15, volume: 0.5)  // B5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.playTone(frequency: 1175, duration: 0.3, volume: 0.5)  // D6
            }
        }
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    func playSuccess() {
        if isSoundEnabled {
            // Sparkling chime
            playTone(frequency: 1046, duration: 0.1, volume: 0.4) // C6
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playTone(frequency: 1318, duration: 0.1, volume: 0.4) // E6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.playTone(frequency: 1568, duration: 0.2, volume: 0.4) // G6
            }
        }
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    func playError() {
        if isSoundEnabled {
            // "Uh oh" sound (Low-High-Low)
            playTone(frequency: 400, duration: 0.1, volume: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playTone(frequency: 300, duration: 0.2, volume: 0.3)
            }
        }
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    func playNavigation() {
        if isSoundEnabled {
            playTone(frequency: 700, duration: 0.04, volume: 0.2)
        }
        if isHapticsEnabled {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    
    // =========================================================================
    // MARK: - CORE GAMEPLAY SOUNDS
    // =========================================================================
    
    /// Tile tap - light "tick" (throttled)
    func playTileTap() {
        guard isSoundEnabled, shouldPlaySound() else { return }
        playTone(frequency: 880, duration: 0.035, volume: 0.25)
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    /// Tile shuffle - fast "rattle"
    func playTileShuffle() {
        guard isSoundEnabled else { return }
        playTone(frequency: 700, duration: 0.03, volume: 0.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            self.playTone(frequency: 600, duration: 0.03, volume: 0.2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playTone(frequency: 800, duration: 0.04, volume: 0.22)
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    /// Valid word submit - "click + sparkle"
    func playSubmitValid() {
        guard isSoundEnabled else { return }
        playTone(frequency: 1000, duration: 0.05, volume: 0.35)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.playTone(frequency: 1400, duration: 0.08, volume: 0.25)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.playTone(frequency: 1600, duration: 0.06, volume: 0.2)
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    /// Invalid word - soft "buzz"
    func playSubmitInvalid() {
        guard isSoundEnabled else { return }
        playTone(frequency: 200, duration: 0.12, volume: 0.22)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playTone(frequency: 170, duration: 0.1, volume: 0.18)
        }
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    /// Countdown beep
    func playCountdownBeep() {
        guard isSoundEnabled else { return }
        playTone(frequency: 1000, duration: 0.08, volume: 0.3)
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    /// Countdown GO! - "whoosh"
    func playCountdownGo() {
        guard isSoundEnabled else { return }
        playTone(frequency: 700, duration: 0.05, volume: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            self.playTone(frequency: 1000, duration: 0.08, volume: 0.35)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playTone(frequency: 1200, duration: 0.1, volume: 0.4)
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    /// Timer warning tick
    func playTimerTick() {
        guard isSoundEnabled else { return }
        playTone(frequency: 1100, duration: 0.03, volume: 0.18)
    }
    
    /// Time out - "whoomp"
    func playTimeOut() {
        guard isSoundEnabled else { return }
        playTone(frequency: 150, duration: 0.2, volume: 0.3)
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    // =========================================================================
    // MARK: - PARTY MODE SOUNDS
    // =========================================================================
    
    /// Pass device transition - soft "whoosh"
    func playPassDevice() {
        guard isSoundEnabled else { return }
        playTone(frequency: 500, duration: 0.1, volume: 0.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.playTone(frequency: 700, duration: 0.12, volume: 0.22)
        }
    }
    
    /// Ready pop
    func playReadyPop() {
        guard isSoundEnabled else { return }
        playTone(frequency: 800, duration: 0.05, volume: 0.3)
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    /// Turn swap - "slide + click"
    func playTurnSwap() {
        guard isSoundEnabled else { return }
        playTone(frequency: 400, duration: 0.08, volume: 0.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playTone(frequency: 1000, duration: 0.04, volume: 0.28)
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    /// Reveal word - small pop
    func playRevealWord() {
        guard isSoundEnabled else { return }
        playTone(frequency: 850, duration: 0.04, volume: 0.22)
    }
    
    /// Winner reveal - "ding + sparkle burst"
    func playWinnerReveal() {
        guard isSoundEnabled else { return }
        playTone(frequency: 1000, duration: 0.12, volume: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playTone(frequency: 1400, duration: 0.08, volume: 0.3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            self.playTone(frequency: 1700, duration: 0.06, volume: 0.25)
        }
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    /// Round winner - "trophy chime"
    func playRoundWinner() {
        guard isSoundEnabled else { return }
        playTone(frequency: 659, duration: 0.1, volume: 0.35)  // E5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playTone(frequency: 784, duration: 0.1, volume: 0.35)  // G5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.playTone(frequency: 988, duration: 0.15, volume: 0.4)  // B5
        }
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    /// Rematch - "boom + whoosh"
    func playRematch() {
        guard isSoundEnabled else { return }
        playTone(frequency: 250, duration: 0.08, volume: 0.35)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playTone(frequency: 600, duration: 0.06, volume: 0.3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            self.playTone(frequency: 900, duration: 0.08, volume: 0.35)
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    // =========================================================================
    // MARK: - EXTRA POLISH SOUNDS
    // =========================================================================
    
    /// Confetti pop
    func playConfettiPop() {
        guard isSoundEnabled else { return }
        playTone(frequency: 600, duration: 0.03, volume: 0.2)
        playTone(frequency: 900, duration: 0.025, volume: 0.18)
    }
    
    /// Combo chime (escalating)
    func playComboChime(level: Int) {
        guard isSoundEnabled else { return }
        let baseFreq = 700.0 + Double(level * 100)
        playTone(frequency: baseFreq, duration: 0.08, volume: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.playTone(frequency: baseFreq * 1.25, duration: 0.1, volume: 0.28)
        }
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    /// Special word (long word) - extra sparkle
    func playSpecialWord() {
        guard isSoundEnabled else { return }
        playSubmitValid()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            self.playTone(frequency: 1800, duration: 0.08, volume: 0.2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            self.playTone(frequency: 2100, duration: 0.1, volume: 0.18)
        }
    }
    
    // =========================================================================
    // MARK: - UI & TRANSITIONS (Premium Polish)
    // =========================================================================
    
    /// UI Button tap - distinct from tile tap
    func playUIButtonTap() {
        guard isSoundEnabled else { return }
        playTone(frequency: 750, duration: 0.04, volume: 0.22)
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    /// Submit click only (no sparkle) - for normal words
    func playSubmitClick() {
        guard isSoundEnabled else { return }
        playTone(frequency: 1000, duration: 0.05, volume: 0.35)
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    /// Screen transition whoosh
    func playScreenWhoosh() {
        guard isSoundEnabled else { return }
        playTone(frequency: 400, duration: 0.08, volume: 0.18)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            self.playTone(frequency: 600, duration: 0.1, volume: 0.2)
        }
    }
    
    // MARK: - Throttle Helper
    
    private func shouldPlaySound() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastSoundTime) >= minSoundInterval {
            lastSoundTime = now
            return true
        }
        return false
    }
    
    // =========================================================================
    // MARK: - LEGACY COMPATIBILITY
    // =========================================================================
    
    // Alias old names to new ones
    func playTap() { playTileTap() }
    func playTick() { playTimerTick() }
    
    // MARK: - Tone Generator
    
    private func playTone(frequency: Double, duration: Double, volume: Float) {
        guard let engine = audioEngine,
              let player = playerNode,
              let format = audioFormat else { return }
        
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        let channelCount = Int(format.channelCount)
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let wave = sin(2.0 * .pi * frequency * time)
            
            // Smoother envelope
            let envelope: Float
            let attackTime = 0.01
            let releaseTime = 0.02
            
            if time < attackTime {
                envelope = Float(time / attackTime)
            } else if time > duration - releaseTime {
                envelope = Float((duration - time) / releaseTime)
            } else {
                envelope = 1.0
            }
            
            let sample = Float(wave) * envelope * volume
            
            for channel in 0..<channelCount {
                buffer.floatChannelData?[channel][frame] = sample
            }
        }
        
        if !engine.isRunning {
            try? engine.start()
        }
        
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
}
