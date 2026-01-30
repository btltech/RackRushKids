import SpriteKit
import SwiftUI

// MARK: - Sparkle Touch Scene
/// Sparkles emit from touch points for magical interaction
class SparkleTouchScene: SKScene {
    
    private var lastTouchTime: TimeInterval = 0
    private let sparkleColors: [UIColor] = [
        .yellow, .cyan, .magenta, .white, .orange
    ]
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            createSparkles(at: location)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            createSparkles(at: location, count: 3)  // Fewer for move
        }
    }
    
    // MARK: - Public API (for programmatic triggers)
    
    func sparkle(at position: CGPoint) {
        createSparkles(at: position)
    }
    
    func sparkleTrail(from start: CGPoint, to end: CGPoint, steps: Int = 5) {
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps - 1)
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) { [weak self] in
                self?.createSparkles(at: CGPoint(x: x, y: y), count: 3)
            }
        }
    }
    
    // MARK: - Private
    
    private func createSparkles(at position: CGPoint, count: Int = 8) {
        for i in 0..<count {
            let color = sparkleColors.randomElement() ?? .yellow
            createSingleSparkle(at: position, color: color, delay: Double(i) * 0.02)
        }
    }
    
    private func createSingleSparkle(at position: CGPoint, color: UIColor, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            let sparkle = SKSpriteNode(texture: self.createSparkleTexture())
            sparkle.position = position
            sparkle.size = CGSize(width: 12, height: 12)
            sparkle.color = color
            sparkle.colorBlendFactor = 0.7
            sparkle.alpha = 1.0
            sparkle.zPosition = 100
            
            // Random offset
            let offsetX = CGFloat.random(in: -20...20)
            let offsetY = CGFloat.random(in: -20...20)
            sparkle.position = CGPoint(x: position.x + offsetX, y: position.y + offsetY)
            
            self.addChild(sparkle)
            
            // Animation
            let scale = SKAction.sequence([
                .scale(to: 1.3, duration: 0.1),
                .scale(to: 0.3, duration: 0.3)
            ])
            let move = SKAction.moveBy(x: offsetX * 2, y: offsetY * 2 + 30, duration: 0.4)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.3)
            let rotate = SKAction.rotate(byAngle: .pi / 2, duration: 0.4)
            
            sparkle.run(.sequence([
                .group([scale, move, fade, rotate]),
                .removeFromParent()
            ]))
        }
    }
    
    private func createSparkleTexture() -> SKTexture {
        let size: CGFloat = 16
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let center = CGPoint(x: size / 2, y: size / 2)
            
            // 4-pointed star
            let path = UIBezierPath()
            let outerRadius = size / 2
            let innerRadius = size / 6
            
            for i in 0..<8 {
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let angle = (CGFloat(i) / 8.0) * .pi * 2 - .pi / 2
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
}

// MARK: - SwiftUI Wrapper
struct SKSparkleTouchView: View {
    @Binding var sparklePosition: CGPoint?
    var allowInteraction: Bool = true
    
    @State private var scene: SparkleTouchScene?
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        let isPaused = scenePhase != .active
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, isPaused: isPaused, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .allowsHitTesting(allowInteraction)  // Allow touch-through when not interactive
            }
        }
        .onAppear {
            scene = SparkleTouchScene(size: UIScreen.main.bounds.size)
        }
        .onChange(of: sparklePosition) { oldValue, newValue in
            if let position = newValue {
                scene?.sparkle(at: position)
                
                // Reset after triggering
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    sparklePosition = nil
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        SKSparkleTouchView(sparklePosition: .constant(nil))
        
        Text("Tap anywhere!")
            .foregroundColor(.white)
    }
}
