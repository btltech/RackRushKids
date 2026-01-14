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
    
    private init() {
        setupAudioEngine()
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
