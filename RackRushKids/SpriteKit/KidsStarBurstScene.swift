import SpriteKit
import SwiftUI

// MARK: - Kids Star Burst Scene
/// Fun colorful star explosion for round wins
class KidsStarBurstScene: SKScene {
    
    private let starColors: [UIColor] = [
        .systemYellow, .systemOrange, .systemPink, .systemCyan,
        .systemGreen, .systemPurple, .magenta
    ]
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }
    
    // MARK: - Public API
    
    func triggerBurst(at position: CGPoint? = nil) {
        let center = position ?? CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Big central flash
        createCentralFlash(at: center)
        
        // Colorful stars
        createColorfulStars(at: center)
        
        // Rainbow sparkles
        createRainbowSparkles(at: center)
        
        // Fun emoji burst
        createEmojiBurst(at: center)
    }
    
    private func createCentralFlash(at center: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.position = center
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 1.0
        flash.zPosition = 100
        
        addChild(flash)
        
        flash.run(.sequence([
            .group([
                .scale(to: 10, duration: 0.4),
                .fadeOut(withDuration: 0.4)
            ]),
            .removeFromParent()
        ]))
    }
    
    private func createColorfulStars(at center: CGPoint) {
        let starCount = 16
        
        for i in 0..<starCount {
            let angle = (CGFloat(i) / CGFloat(starCount)) * .pi * 2
            let color = starColors[i % starColors.count]
            let delay = Double(i) * 0.03
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.createStar(at: center, angle: angle, color: color)
            }
        }
    }
    
    private func createStar(at center: CGPoint, angle: CGFloat, color: UIColor) {
        let star = SKSpriteNode(texture: createStarTexture())
        star.position = center
        star.size = CGSize(width: 40, height: 40)  // Bigger for kids
        star.color = color
        star.colorBlendFactor = 0.6
        star.zPosition = 50
        
        addChild(star)
        
        let distance: CGFloat = 250 + CGFloat.random(in: 0...100)
        let endX = center.x + cos(angle) * distance
        let endY = center.y + sin(angle) * distance
        
        let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 1.0)
        move.timingMode = .easeOut
        let rotate = SKAction.rotate(byAngle: .pi * 3, duration: 1.0)
        let scale = SKAction.sequence([
            .scale(to: 1.8, duration: 0.3),
            .scale(to: 0.5, duration: 0.7)
        ])
        let fade = SKAction.sequence([
            .wait(forDuration: 0.6),
            .fadeOut(withDuration: 0.4)
        ])
        
        star.run(.sequence([
            .group([move, rotate, scale, fade]),
            .removeFromParent()
        ]))
    }
    
    private func createRainbowSparkles(at center: CGPoint) {
        let emitter = SKEmitterNode()
        emitter.position = center
        emitter.zPosition = 40
        
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [UIColor.red, .orange, .yellow, .green, .cyan, .blue, .purple],
            times: [0, 0.15, 0.3, 0.45, 0.6, 0.75, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.particleTexture = createSparkTexture()
        
        emitter.particleBirthRate = 200
        emitter.numParticlesToEmit = 80
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        
        emitter.particleSpeed = 250
        emitter.particleSpeedRange = 100
        emitter.emissionAngleRange = .pi * 2
        
        emitter.particleSize = CGSize(width: 8, height: 8)
        emitter.particleScaleSpeed = -1
        
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1
        
        addChild(emitter)
        
        emitter.run(.sequence([
            .wait(forDuration: 1.5),
            .removeFromParent()
        ]))
    }
    
    private func createEmojiBurst(at center: CGPoint) {
        let emojis = ["⭐", "🌟", "✨", "🎉", "🎊", "💫", "🏆"]
        
        for (i, emoji) in emojis.enumerated() {
            let angle = (CGFloat(i) / CGFloat(emojis.count)) * .pi * 2 + .pi / 8
            let delay = 0.1 + Double(i) * 0.05
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                let label = SKLabelNode(text: emoji)
                label.position = center
                label.fontSize = 36
                label.zPosition = 60
                
                self.addChild(label)
                
                let distance: CGFloat = 180
                let endX = center.x + cos(angle) * distance
                let endY = center.y + sin(angle) * distance
                
                let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.8)
                move.timingMode = .easeOut
                let scale = SKAction.sequence([
                    .scale(to: 1.5, duration: 0.2),
                    .scale(to: 0.8, duration: 0.6)
                ])
                let fade = SKAction.sequence([
                    .wait(forDuration: 0.5),
                    .fadeOut(withDuration: 0.3)
                ])
                
                label.run(.sequence([
                    .group([move, scale, fade]),
                    .removeFromParent()
                ]))
            }
        }
    }
    
    // MARK: - Textures
    
    private func createStarTexture() -> SKTexture {
        let size: CGFloat = 40
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let center = CGPoint(x: size / 2, y: size / 2)
            let outerRadius = size / 2
            let innerRadius = size / 5
            let points = 5
            
            let path = UIBezierPath()
            for i in 0..<points * 2 {
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let angle = (CGFloat(i) / CGFloat(points * 2)) * .pi * 2 - .pi / 2
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.close()
            
            UIColor.white.setFill()
            path.fill()
        }
        return SKTexture(image: image)
    }
    
    private func createSparkTexture() -> SKTexture {
        let size: CGFloat = 12
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: rect)
        }
        return SKTexture(image: image)
    }
}

// MARK: - SwiftUI Wrapper
struct SKKidsStarBurstView: View {
    @Binding var trigger: Bool
    var position: CGPoint? = nil
    
    @State private var scene: KidsStarBurstScene?
    
    var body: some View {
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            scene = KidsStarBurstScene(size: UIScreen.main.bounds.size)
        }
        .onChange(of: trigger) { _, shouldTrigger in
            if shouldTrigger {
                scene?.triggerBurst(at: position)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    trigger = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.purple.opacity(0.3).ignoresSafeArea()
        SKKidsStarBurstView(trigger: .constant(true))
    }
}
