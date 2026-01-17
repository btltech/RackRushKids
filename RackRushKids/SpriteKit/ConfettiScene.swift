import SpriteKit
import SwiftUI

// MARK: - Confetti Scene
/// High-performance confetti effect using SKEmitterNode
class ConfettiScene: SKScene {
    
    private var emitters: [SKEmitterNode] = []
    
    // Configuration
    var confettiColors: [UIColor] = [
        UIColor(red: 1.0, green: 0.85, blue: 0.24, alpha: 1.0),   // Gold
        UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0),   // Coral
        UIColor(red: 0.49, green: 0.36, blue: 0.98, alpha: 1.0),  // Purple
        UIColor(red: 0.0, green: 0.83, blue: 0.67, alpha: 1.0),   // Teal
        UIColor(red: 1.0, green: 0.56, blue: 0.33, alpha: 1.0),   // Orange
        .white
    ]
    
    var isKidsMode: Bool = false {
        didSet {
            if isKidsMode {
                confettiColors = [
                    .systemRed, .systemOrange, .systemYellow,
                    .systemGreen, .systemBlue, .systemPurple, .systemPink
                ]
            }
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        
        // Create multiple emitters for variety
        createConfettiEmitters()
    }
    
    private func createConfettiEmitters() {
        // Main burst emitter
        for (index, color) in confettiColors.enumerated() {
            let emitter = createEmitter(color: color, delay: Double(index) * 0.05)
            emitter.position = CGPoint(x: size.width / 2, y: size.height + 20)
            addChild(emitter)
            emitters.append(emitter)
        }
        
        // Side bursts for fuller effect
        let leftBurst = createSideBurst(at: CGPoint(x: size.width * 0.2, y: size.height + 20))
        let rightBurst = createSideBurst(at: CGPoint(x: size.width * 0.8, y: size.height + 20))
        addChild(leftBurst)
        addChild(rightBurst)
    }
    
    private func createEmitter(color: UIColor, delay: Double) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        // Particle appearance
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .alpha
        
        // Use a simple shape
        emitter.particleTexture = createConfettiTexture()
        
        // Emission
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 40
        emitter.particleLifetime = 4.0
        emitter.particleLifetimeRange = 1.0
        
        // Position variance
        emitter.particlePositionRange = CGVector(dx: size.width * 0.8, dy: 0)
        
        // Speed
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 100
        emitter.emissionAngle = -.pi / 2  // Downward
        emitter.emissionAngleRange = .pi / 4
        
        // Physics
        emitter.yAcceleration = -150
        emitter.xAcceleration = 0
        
        // Rotation
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 3
        
        // Size
        emitter.particleSize = CGSize(width: 10, height: 12)
        emitter.particleScaleRange = 0.5
        
        // Alpha
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.2
        
        // Delayed start
        if delay > 0 {
            emitter.particleBirthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                emitter.particleBirthRate = 80
            }
        }
        
        return emitter
    }
    
    private func createSideBurst(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        
        emitter.particleColor = confettiColors.randomElement() ?? .white
        emitter.particleColorBlendFactor = 1.0
        emitter.particleTexture = createConfettiTexture()
        
        emitter.particleBirthRate = 60
        emitter.numParticlesToEmit = 25
        emitter.particleLifetime = 3.5
        
        emitter.particleSpeed = 180
        emitter.particleSpeedRange = 80
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 3
        
        emitter.particlePositionRange = CGVector(dx: 50, dy: 0)
        emitter.yAcceleration = -120
        
        emitter.particleRotationSpeed = 2.5
        emitter.particleSize = CGSize(width: 8, height: 10)
        emitter.particleScaleRange = 0.4
        emitter.particleAlphaSpeed = -0.25
        
        return emitter
    }
    
    private func createConfettiTexture() -> SKTexture {
        let size = CGSize(width: 12, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 2)
            UIColor.white.setFill()
            path.fill()
        }
        return SKTexture(image: image)
    }
    
    // MARK: - Public API
    
    func triggerBurst() {
        // Reset and re-trigger all emitters
        for emitter in emitters {
            emitter.resetSimulation()
        }
    }
}

// MARK: - SwiftUI Wrapper
struct SKConfettiView: View {
    var isKidsMode: Bool = false
    @State private var scene: ConfettiScene?
    
    var body: some View {
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            let newScene = ConfettiScene(size: UIScreen.main.bounds.size)
            newScene.isKidsMode = isKidsMode
            scene = newScene
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SKConfettiView()
    }
}
