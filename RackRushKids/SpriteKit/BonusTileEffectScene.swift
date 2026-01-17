import SpriteKit
import SwiftUI

// MARK: - Bonus Tile Effect Scene
/// Power-up style effects when bonus tiles are activated
class BonusTileEffectScene: SKScene {
    
    enum BonusType: String {
        case doubleLetter = "DL"
        case tripleLetter = "TL"
        case doubleWord = "DW"
        
        var color: UIColor {
            switch self {
            case .doubleLetter: return UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)  // Cyan
            case .tripleLetter: return UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)  // Orange
            case .doubleWord: return UIColor(red: 1.0, green: 0.2, blue: 0.4, alpha: 1.0)    // Pink/Red
            }
        }
        
        var secondaryColor: UIColor {
            switch self {
            case .doubleLetter: return UIColor(red: 0.5, green: 0.9, blue: 1.0, alpha: 1.0)
            case .tripleLetter: return UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
            case .doubleWord: return UIColor(red: 1.0, green: 0.5, blue: 0.6, alpha: 1.0)
            }
        }
    }
    
    private var sparkEmitter: SKEmitterNode?
    private var burstEmitter: SKEmitterNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }
    
    // MARK: - Public API
    
    func triggerBonusEffect(type: BonusType, at position: CGPoint) {
        // 1. Spark burst
        createSparkBurst(at: position, color: type.color)
        
        // 2. Ring expansion
        createRingExpansion(at: position, color: type.secondaryColor)
        
        // 3. Label stamp
        createBonusLabel(type: type, at: position)
        
        // 4. Screen shake
        triggerScreenShake()
    }
    
    private func createSparkBurst(at position: CGPoint, color: UIColor) {
        let emitter = SKEmitterNode()
        emitter.position = position
        
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.particleTexture = createSparkTexture()
        
        emitter.particleBirthRate = 200
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2
        
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 100
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2  // All directions
        
        emitter.particleSize = CGSize(width: 6, height: 6)
        emitter.particleScaleSpeed = -1.5
        
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.5
        
        addChild(emitter)
        
        // Remove after particles die
        emitter.run(.sequence([
            .wait(forDuration: 1.0),
            .removeFromParent()
        ]))
    }
    
    private func createRingExpansion(at position: CGPoint, color: UIColor) {
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.position = position
        ring.strokeColor = color
        ring.fillColor = .clear
        ring.lineWidth = 4
        ring.alpha = 0.8
        
        addChild(ring)
        
        // Expand and fade
        let expand = SKAction.scale(to: 8, duration: 0.4)
        let fade = SKAction.fadeOut(withDuration: 0.4)
        let group = SKAction.group([expand, fade])
        
        ring.run(.sequence([
            group,
            .removeFromParent()
        ]))
    }
    
    private func createBonusLabel(type: BonusType, at position: CGPoint) {
        let label = SKLabelNode(text: type.rawValue)
        label.position = CGPoint(x: position.x, y: position.y + 30)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 24
        label.fontColor = type.color
        label.alpha = 0
        
        addChild(label)
        
        // Pop in, hold, fade out
        let fadeIn = SKAction.fadeIn(withDuration: 0.15)
        let setInitialScale = SKAction.scale(to: 0.5, duration: 0)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.5)
        let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        label.run(.sequence([
            setInitialScale,
            .group([fadeIn, scaleUp]),
            scaleDown,
            wait,
            .group([moveUp, fadeOut]),
            .removeFromParent()
        ]))
    }
    
    private func triggerScreenShake() {
        guard self.view != nil else { return }
        
        let shakeAmount: CGFloat = 8
        let shakeDuration: TimeInterval = 0.4
        let shakeCount = 6
        
        var actions: [SKAction] = []
        for i in 0..<shakeCount {
            let direction: CGFloat = i % 2 == 0 ? 1 : -1
            let offset = shakeAmount * CGFloat(shakeCount - i) / CGFloat(shakeCount)
            
            actions.append(.moveBy(x: offset * direction, y: offset * direction * 0.5, duration: shakeDuration / Double(shakeCount)))
        }
        actions.append(.move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: 0.05))
        
        // Apply to camera or scene position
        if let camera = self.camera {
            camera.run(.sequence(actions))
        }
    }
    
    private func createSparkTexture() -> SKTexture {
        let size: CGFloat = 16
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2
            
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
struct SKBonusBurstView: View {
    let bonusType: String  // "DL", "TL", "DW"
    let triggerPosition: CGPoint
    @Binding var isTriggered: Bool
    
    @State private var scene: BonusTileEffectScene?
    
    var body: some View {
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            scene = BonusTileEffectScene(size: UIScreen.main.bounds.size)
        }
        .onChange(of: isTriggered) { _, triggered in
            if triggered, let scene = scene {
                let type = BonusTileEffectScene.BonusType(rawValue: bonusType) ?? .doubleLetter
                scene.triggerBonusEffect(type: type, at: triggerPosition)
                
                // Reset trigger
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTriggered = false
                }
            }
        }
    }
}
