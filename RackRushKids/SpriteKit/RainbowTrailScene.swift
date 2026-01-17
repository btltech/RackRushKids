import SpriteKit
import SwiftUI

// MARK: - Rainbow Trail Scene
/// Rainbow gradient follows finger during tile selection
class RainbowTrailScene: SKScene {
    
    private var trailPoints: [CGPoint] = []
    private let maxTrailPoints = 30
    private var trailNode: SKShapeNode?
    
    private let rainbowColors: [UIColor] = [
        .systemRed, .systemOrange, .systemYellow,
        .systemGreen, .systemCyan, .systemBlue, .systemPurple
    ]
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        trailPoints.removeAll()
        for touch in touches {
            let location = touch.location(in: self)
            trailPoints.append(location)
            createSparkle(at: location)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            trailPoints.append(location)
            
            // Limit trail length
            if trailPoints.count > maxTrailPoints {
                trailPoints.removeFirst()
            }
            
            updateTrail()
            
            // Occasional sparkle
            if Int.random(in: 0...3) == 0 {
                createSparkle(at: location)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fadeOutTrail()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        fadeOutTrail()
    }
    
    // MARK: - Public API
    
    func addPoint(_ point: CGPoint) {
        trailPoints.append(point)
        if trailPoints.count > maxTrailPoints {
            trailPoints.removeFirst()
        }
        updateTrail()
    }
    
    func clearTrail() {
        fadeOutTrail()
    }
    
    // MARK: - Trail Drawing
    
    private func updateTrail() {
        trailNode?.removeFromParent()
        
        guard trailPoints.count >= 2 else { return }
        
        let path = UIBezierPath()
        path.move(to: trailPoints[0])
        
        for i in 1..<trailPoints.count {
            path.addLine(to: trailPoints[i])
        }
        
        // Create gradient-like effect with multiple lines
        for (i, _) in rainbowColors.enumerated() {
            let offset = CGFloat(i) * 2 - 6
            createColoredTrailSegment(path: path, color: rainbowColors[i], offset: offset, alpha: 0.8 - CGFloat(i) * 0.08)
        }
    }
    
    private func createColoredTrailSegment(path: UIBezierPath, color: UIColor, offset: CGFloat, alpha: CGFloat) {
        let node = SKShapeNode(path: path.cgPath)
        node.strokeColor = color.withAlphaComponent(alpha)
        node.lineWidth = 8
        node.lineCap = .round
        node.lineJoin = .round
        node.zPosition = 10 + offset
        node.position = CGPoint(x: 0, y: offset)
        node.glowWidth = 3
        
        addChild(node)
        
        // Auto-fade old segments
        node.run(.sequence([
            .wait(forDuration: 0.3),
            .fadeOut(withDuration: 0.2),
            .removeFromParent()
        ]))
    }
    
    private func fadeOutTrail() {
        trailPoints.removeAll()
        
        for child in children {
            if child is SKShapeNode {
                child.run(.sequence([
                    .fadeOut(withDuration: 0.3),
                    .removeFromParent()
                ]))
            }
        }
    }
    
    private func createSparkle(at position: CGPoint) {
        let color = rainbowColors.randomElement()!
        
        let sparkle = SKShapeNode(circleOfRadius: 5)
        sparkle.position = position
        sparkle.fillColor = color
        sparkle.strokeColor = .white
        sparkle.lineWidth = 1
        sparkle.alpha = 1.0
        sparkle.zPosition = 50
        
        addChild(sparkle)
        
        let scale = SKAction.scale(to: 2, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        
        sparkle.run(.sequence([
            .group([scale, fade]),
            .removeFromParent()
        ]))
    }
}

// MARK: - SwiftUI Wrapper
struct SKRainbowTrailView: View {
    var allowInteraction: Bool = true
    
    @State private var scene: RainbowTrailScene?
    
    var body: some View {
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .allowsHitTesting(allowInteraction)
            }
        }
        .onAppear {
            scene = RainbowTrailScene(size: UIScreen.main.bounds.size)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        SKRainbowTrailView()
        
        Text("Draw with your finger!")
            .foregroundColor(.white)
            .font(.title)
    }
}
