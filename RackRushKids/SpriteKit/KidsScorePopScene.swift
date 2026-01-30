import SpriteKit
import SwiftUI

// MARK: - Kids Score Pop Scene
/// Colorful floating score numbers for kids with fun animations
class KidsScorePopScene: SKScene {
    
    private let funColors: [UIColor] = [
        .systemYellow, .systemGreen, .systemCyan, .systemPink,
        .systemOrange, .systemPurple, .magenta
    ]
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }
    
    // MARK: - Public API
    
    func showScore(_ score: Int, at position: CGPoint) {
        let color = funColors.randomElement() ?? .systemYellow
        
        // Big bouncy score
        let scoreText = score >= 0 ? "+\(score)" : "\(score)"
        let label = SKLabelNode(text: scoreText)
        label.position = position
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 48  // Bigger for kids!
        label.fontColor = color
        label.alpha = 0
        label.setScale(0.3)
        label.zPosition = 100
        
        // Fun emoji decoration
        let emoji = ["⭐", "🌟", "✨", "💫", "🎉"].randomElement() ?? "⭐"
        let emojiLabel = SKLabelNode(text: emoji)
        emojiLabel.fontSize = 28
        emojiLabel.position = CGPoint(x: 40, y: 5)
        label.addChild(emojiLabel)
        
        addChild(label)
        
        // Bouncy animation
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.2)
        scaleUp.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        scaleDown.timingMode = .easeIn
        let bounce = SKAction.scale(to: 1.1, duration: 0.1)
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.5)
        let moveUp = SKAction.moveBy(x: 0, y: 80, duration: 0.8)
        moveUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        
        label.run(.sequence([
            .group([fadeIn, scaleUp]),
            scaleDown,
            bounce,
            settle,
            wait,
            .group([moveUp, fadeOut]),
            .removeFromParent()
        ]))
        
        // Fun sparkle burst
        createSparkles(at: position, color: color)
        
        // Celebration sound would go here
    }
    
    func showWordScore(_ score: Int, word: String, at position: CGPoint) {
        showScore(score, at: position)
        
        // Show word with fun letters
        let wordLabel = SKLabelNode(text: word.uppercased())
        wordLabel.position = CGPoint(x: position.x, y: position.y - 40)
        wordLabel.fontName = "AvenirNext-Bold"
        wordLabel.fontSize = 22
        wordLabel.fontColor = .white
        wordLabel.alpha = 0
        
        addChild(wordLabel)
        
        wordLabel.run(.sequence([
            .fadeIn(withDuration: 0.2),
            .wait(forDuration: 1.0),
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))
    }
    
    private func createSparkles(at position: CGPoint, color: UIColor) {
        for i in 0..<12 {
            let angle = (CGFloat(i) / 12.0) * .pi * 2
            let distance: CGFloat = 50
            
            let sparkle = SKShapeNode(circleOfRadius: 6)
            sparkle.position = position
            sparkle.fillColor = [color, .yellow, .white].randomElement() ?? color
            sparkle.strokeColor = .clear
            sparkle.alpha = 1.0
            sparkle.zPosition = 90
            
            addChild(sparkle)
            
            let endX = position.x + cos(angle) * distance
            let endY = position.y + sin(angle) * distance
            
            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.4)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.3)
            let scale = SKAction.scale(to: 0.3, duration: 0.4)
            
            sparkle.run(.sequence([
                .group([move, scale]),
                fade,
                .removeFromParent()
            ]))
        }
    }
}

// MARK: - SwiftUI Wrapper
struct SKKidsScorePopView: View {
    @Binding var scoreToShow: Int?
    @Binding var showPosition: CGPoint
    
    @State private var scene: KidsScorePopScene?
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        let isPaused = scenePhase != .active
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, isPaused: isPaused, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            scene = KidsScorePopScene(size: UIScreen.main.bounds.size)
        }
        .onChange(of: scoreToShow) { _, score in
            if let score = score, let scene = scene {
                scene.showScore(score, at: showPosition)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scoreToShow = nil
                }
            }
        }
    }
}
