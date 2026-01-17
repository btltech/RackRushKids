import SpriteKit
import SwiftUI

// MARK: - Ambient Particle Scene
/// GPU-accelerated floating particle background
class AmbientParticleScene: SKScene {
    
    private var emitters: [SKEmitterNode] = []
    
    // Configuration
    var particleColors: [UIColor] = [
        .white,
        UIColor(red: 0.5, green: 0.3, blue: 1.0, alpha: 0.5),  // Purple
        UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.3)   // Cyan
    ]
    
    var isKidsMode: Bool = false {
        didSet {
            if isKidsMode {
                particleColors = [
                    UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 0.4), // Pink
                    UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.4), // Light blue
                    UIColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 0.4)  // Cream
                ]
            }
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        
        createAmbientEmitters()
    }
    
    private func createAmbientEmitters() {
        // Create multiple layers for depth
        for (index, color) in particleColors.enumerated() {
            let emitter = createFloatingEmitter(color: color, layer: index)
            emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(emitter)
            emitters.append(emitter)
        }
    }
    
    private func createFloatingEmitter(color: UIColor, layer: Int) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        // Particle appearance
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.particleTexture = createGlowTexture()
        
        // Continuous emission
        emitter.particleBirthRate = 2.0 + Double(layer) * 0.5
        emitter.numParticlesToEmit = 0  // Infinite
        emitter.particleLifetime = 15.0
        emitter.particleLifetimeRange = 5.0
        
        // Position - spread across entire screen
        emitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        
        // Very slow, drifting movement
        emitter.particleSpeed = 8
        emitter.particleSpeedRange = 5
        emitter.emissionAngle = .pi / 2  // Upward drift
        emitter.emissionAngleRange = .pi  // All directions
        
        // Gentle physics
        emitter.yAcceleration = 2  // Slight upward drift
        emitter.xAcceleration = CGFloat.random(in: -2...2)
        
        // Size based on layer (back = smaller, front = larger)
        let baseSize: CGFloat = 20 + CGFloat(layer) * 15
        emitter.particleSize = CGSize(width: baseSize, height: baseSize)
        emitter.particleScaleRange = 0.5
        emitter.particleScaleSpeed = -0.01
        
        // Alpha - visible but not intrusive
        emitter.particleAlpha = 0.15 + CGFloat(layer) * 0.08
        emitter.particleAlphaRange = 0.05
        emitter.particleAlphaSpeed = 0  // Maintain alpha
        
        return emitter
    }
    
    private func createGlowTexture() -> SKTexture {
        let size: CGFloat = 64
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2
            
            // Radial gradient for soft glow
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
            
            context.cgContext.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: radius,
                options: []
            )
        }
        return SKTexture(image: image)
    }
}

// MARK: - SwiftUI Wrapper
struct SKAmbientParticlesView: View {
    var isKidsMode: Bool = false
    @State private var scene: AmbientParticleScene?
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            let newScene = AmbientParticleScene(size: UIScreen.main.bounds.size)
            newScene.isKidsMode = isKidsMode
            scene = newScene
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Pause scene when backgrounded to prevent GPU errors
            switch newPhase {
            case .active:
                scene?.isPaused = false
            case .inactive, .background:
                scene?.isPaused = true
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SKAmbientParticlesView()
    }
}
