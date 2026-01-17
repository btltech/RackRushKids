import SpriteKit
import SwiftUI

// MARK: - Balloon Scene
/// Colorful balloons rising slowly in the background - tap to pop!
class BalloonScene: SKScene {
    
    private var balloonTimer: Timer?
    private let balloonColors: [UIColor] = [
        .systemRed, .systemBlue, .systemGreen, .systemYellow,
        .systemOrange, .systemPink, .systemPurple, .systemCyan
    ]
    
    // Track active balloons for tap detection
    private var balloons: [SKNode] = []
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        startBalloons()
    }
    
    override func willMove(from view: SKView) {
        balloonTimer?.invalidate()
        balloonTimer = nil
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            var poppedBalloon = false
            
            // Check if we tapped a balloon
            for balloon in balloons {
                // Use a generous hit area (balloon body is about 40x50)
                let hitArea = CGRect(
                    x: balloon.position.x - 30,
                    y: balloon.position.y - 40,
                    width: 60,
                    height: 80
                )
                
                if hitArea.contains(location) {
                    popBalloon(balloon)
                    poppedBalloon = true
                    break
                }
            }
            
            // If no balloon was popped, create sparkles
            if !poppedBalloon {
                createSparkles(at: location, count: 8)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            // Create fewer sparkles on move for trail effect
            createSparkles(at: location, count: 3)
        }
    }
    
    // MARK: - Public API
    
    func startBalloons() {
        // Spawn a balloon every 2 seconds
        balloonTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.spawnBalloon()
        }
        
        // Spawn a few initial balloons
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) { [weak self] in
                self?.spawnBalloon()
            }
        }
    }
    
    func stopBalloons() {
        balloonTimer?.invalidate()
        balloonTimer = nil
    }
    
    private func spawnBalloon() {
        let color = balloonColors.randomElement()!
        let startX = CGFloat.random(in: 40...(size.width - 40))
        let balloon = createBalloon(color: color)
        balloon.position = CGPoint(x: startX, y: -50)
        balloon.zPosition = 1
        balloon.alpha = 0.7
        balloon.name = "balloon"
        
        // Store color for pop effect
        balloon.userData = ["color": color]
        
        addChild(balloon)
        balloons.append(balloon)
        
        // Rise animation with sway
        let duration = Double.random(in: 8...12)
        let rise = SKAction.moveBy(x: 0, y: size.height + 100, duration: duration)
        
        // Gentle sway
        let swayAmount: CGFloat = 30
        let swayDuration = 2.0
        let swayRight = SKAction.moveBy(x: swayAmount, y: 0, duration: swayDuration)
        swayRight.timingMode = .easeInEaseOut
        let swayLeft = SKAction.moveBy(x: -swayAmount, y: 0, duration: swayDuration)
        swayLeft.timingMode = .easeInEaseOut
        let sway = SKAction.repeatForever(.sequence([swayRight, swayLeft]))
        
        // Slight rotation
        let rotateRight = SKAction.rotate(byAngle: 0.1, duration: 1.5)
        let rotateLeft = SKAction.rotate(byAngle: -0.1, duration: 1.5)
        let rotate = SKAction.repeatForever(.sequence([rotateRight, rotateLeft]))
        
        balloon.run(.group([rise, sway, rotate]))
        
        // Remove when off screen
        balloon.run(.sequence([
            .wait(forDuration: duration),
            SKAction.run { [weak self] in
                self?.balloons.removeAll { $0 == balloon }
            },
            .removeFromParent()
        ]))
    }
    
    private func popBalloon(_ balloon: SKNode) {
        // Remove from tracking
        balloons.removeAll { $0 == balloon }
        
        let position = balloon.position
        let color = (balloon.userData?["color"] as? UIColor) ?? .white
        
        // Stop all animations
        balloon.removeAllActions()
        
        // Quick pop effect - scale up then disappear instantly
        let pop = SKAction.sequence([
            .scale(to: 1.4, duration: 0.03),
            .removeFromParent()
        ])
        balloon.run(pop)
        
        // Create awesome pop explosion!
        createPopEffect(at: position, color: color)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    private func createPopEffect(at position: CGPoint, color: UIColor) {
        // Layer 1: Big shockwave ring
        createShockwave(at: position)
        
        // Layer 2: Central flash burst
        createFlashBurst(at: position, color: color)
        
        // Layer 3: Main balloon pieces (rubber fragments)
        createBalloonFragments(at: position, color: color)
        
        // Layer 4: Confetti celebration
        createConfetti(at: position)
        
        // Layer 5: Ribbon streamers
        createRibbons(at: position, color: color)
    }
    
    private func createShockwave(at position: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.strokeColor = .white
        ring.fillColor = .clear
        ring.lineWidth = 4
        ring.position = position
        ring.zPosition = 15
        ring.alpha = 0.9
        addChild(ring)
        
        let expand = SKAction.scale(to: 8, duration: 0.35)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.35)
        let thin = SKAction.customAction(withDuration: 0.35) { node, time in
            if let shape = node as? SKShapeNode {
                shape.lineWidth = max(0.5, 4 - (time / 0.35) * 3.5)
            }
        }
        
        ring.run(.sequence([
            .group([expand, fade, thin]),
            .removeFromParent()
        ]))
    }
    
    private func createFlashBurst(at position: CGPoint, color: UIColor) {
        // Inner bright flash
        let innerFlash = SKShapeNode(circleOfRadius: 30)
        innerFlash.fillColor = .white
        innerFlash.strokeColor = .clear
        innerFlash.position = position
        innerFlash.zPosition = 14
        innerFlash.alpha = 1.0
        addChild(innerFlash)
        
        innerFlash.run(.sequence([
            .group([
                .scale(to: 3, duration: 0.15),
                .fadeOut(withDuration: 0.15)
            ]),
            .removeFromParent()
        ]))
        
        // Colored glow
        let glow = SKShapeNode(circleOfRadius: 40)
        glow.fillColor = color
        glow.strokeColor = .clear
        glow.position = position
        glow.zPosition = 13
        glow.alpha = 0.6
        addChild(glow)
        
        glow.run(.sequence([
            .group([
                .scale(to: 4, duration: 0.25),
                .fadeOut(withDuration: 0.25)
            ]),
            .removeFromParent()
        ]))
    }
    
    private func createBalloonFragments(at position: CGPoint, color: UIColor) {
        // More pieces, bigger explosion!
        let pieceCount = 24
        
        for i in 0..<pieceCount {
            // Varied shapes - irregular rubber fragments
            let size = CGFloat.random(in: 6...18)
            let piece: SKShapeNode
            
            if i % 3 == 0 {
                // Curved rubber piece
                piece = SKShapeNode(ellipseOf: CGSize(width: size * 1.5, height: size * 0.6))
            } else if i % 3 == 1 {
                // Triangular shard
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: -size * 0.5, y: -size * 0.3))
                path.addLine(to: CGPoint(x: size * 0.5, y: -size * 0.3))
                path.close()
                piece = SKShapeNode(path: path.cgPath)
            } else {
                // Round piece
                piece = SKShapeNode(circleOfRadius: size * 0.5)
            }
            
            // Vary the color slightly
            let brightness = CGFloat.random(in: 0.8...1.2)
            piece.fillColor = color.withAlphaComponent(brightness)
            piece.strokeColor = color.withAlphaComponent(0.5)
            piece.lineWidth = 1
            piece.position = position
            piece.zPosition = 12
            addChild(piece)
            
            // Explode outward with physics-like motion
            let angle = (CGFloat(i) / CGFloat(pieceCount)) * .pi * 2 + CGFloat.random(in: -0.3...0.3)
            let speed = CGFloat.random(in: 150...350)  // Much bigger!
            let duration = Double.random(in: 0.5...0.9)
            
            // Initial velocity
            let velocityX = cos(angle) * speed
            let velocityY = sin(angle) * speed
            
            // Apply gravity (pieces fall down)
            let gravity: CGFloat = -400
            
            // Custom physics action
            let physicsMove = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let t = CGFloat(elapsedTime)
                let x = position.x + velocityX * t
                let y = position.y + velocityY * t + 0.5 * gravity * t * t
                node.position = CGPoint(x: x, y: y)
            }
            
            let spin = SKAction.rotate(byAngle: .pi * CGFloat.random(in: 2...6), duration: duration)
            let fade = SKAction.sequence([
                .wait(forDuration: duration * 0.5),
                .fadeOut(withDuration: duration * 0.5)
            ])
            let shrink = SKAction.scale(to: 0.3, duration: duration)
            
            piece.run(.sequence([
                .group([physicsMove, spin, fade, shrink]),
                .removeFromParent()
            ]))
        }
    }
    
    private func createConfetti(at position: CGPoint) {
        let confettiColors: [UIColor] = [.systemYellow, .systemPink, .systemCyan, .systemGreen, .white]
        let confettiCount = 16
        
        for _ in 0..<confettiCount {
            let size = CGFloat.random(in: 4...10)
            let confetti = SKShapeNode(rectOf: CGSize(width: size, height: size * 0.4), cornerRadius: 1)
            confetti.fillColor = confettiColors.randomElement()!
            confetti.strokeColor = .clear
            confetti.position = position
            confetti.zPosition = 11
            addChild(confetti)
            
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: 100...250)
            let duration = Double.random(in: 0.6...1.2)
            
            let velocityX = cos(angle) * speed
            let velocityY = sin(angle) * speed + 100  // Extra upward boost
            let gravity: CGFloat = -300
            
            let physicsMove = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let t = CGFloat(elapsedTime)
                let x = position.x + velocityX * t
                let y = position.y + velocityY * t + 0.5 * gravity * t * t
                node.position = CGPoint(x: x, y: y)
            }
            
            // Flutter rotation
            let flutter = SKAction.repeatForever(.sequence([
                .rotate(byAngle: .pi * 0.3, duration: 0.1),
                .rotate(byAngle: -.pi * 0.3, duration: 0.1)
            ]))
            
            let fade = SKAction.sequence([
                .wait(forDuration: duration * 0.6),
                .fadeOut(withDuration: duration * 0.4)
            ])
            
            confetti.run(flutter)
            confetti.run(.sequence([
                .group([physicsMove, fade]),
                .removeFromParent()
            ]))
        }
    }
    
    private func createRibbons(at position: CGPoint, color: UIColor) {
        let ribbonCount = 6
        
        for _ in 0..<ribbonCount {
            // Create a wavy ribbon path
            let ribbonLength: CGFloat = CGFloat.random(in: 20...40)
            let path = UIBezierPath()
            path.move(to: .zero)
            path.addCurve(
                to: CGPoint(x: 0, y: -ribbonLength),
                controlPoint1: CGPoint(x: 8, y: -ribbonLength * 0.3),
                controlPoint2: CGPoint(x: -8, y: -ribbonLength * 0.6)
            )
            
            let ribbon = SKShapeNode(path: path.cgPath)
            ribbon.strokeColor = color.withAlphaComponent(0.8)
            ribbon.lineWidth = 2
            ribbon.position = position
            ribbon.zPosition = 10
            addChild(ribbon)
            
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: 80...180)
            let duration = Double.random(in: 0.8...1.4)
            
            let velocityX = cos(angle) * speed
            let velocityY = sin(angle) * speed
            let gravity: CGFloat = -150
            
            let physicsMove = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let t = CGFloat(elapsedTime)
                let x = position.x + velocityX * t
                let y = position.y + velocityY * t + 0.5 * gravity * t * t
                node.position = CGPoint(x: x, y: y)
            }
            
            let wiggle = SKAction.repeatForever(.sequence([
                .rotate(byAngle: .pi * 0.2, duration: 0.15),
                .rotate(byAngle: -.pi * 0.4, duration: 0.15),
                .rotate(byAngle: .pi * 0.2, duration: 0.15)
            ]))
            
            let fade = SKAction.sequence([
                .wait(forDuration: duration * 0.5),
                .fadeOut(withDuration: duration * 0.5)
            ])
            
            ribbon.run(wiggle)
            ribbon.run(.sequence([
                .group([physicsMove, fade]),
                .removeFromParent()
            ]))
        }
    }
    
    // MARK: - Sparkle Effect (for non-balloon taps)
    
    private let sparkleColors: [UIColor] = [
        .yellow, .cyan, .magenta, .white, .orange
    ]
    
    private func createSparkles(at position: CGPoint, count: Int) {
        for i in 0..<count {
            let color = sparkleColors.randomElement()!
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) { [weak self] in
                self?.createSingleSparkle(at: position, color: color)
            }
        }
    }
    
    private func createSingleSparkle(at position: CGPoint, color: UIColor) {
        let sparkle = createSparkleShape()
        sparkle.position = position
        sparkle.fillColor = color
        sparkle.strokeColor = .clear
        sparkle.alpha = 1.0
        sparkle.zPosition = 100
        sparkle.setScale(0.8)
        
        // Random offset
        let offsetX = CGFloat.random(in: -20...20)
        let offsetY = CGFloat.random(in: -20...20)
        sparkle.position = CGPoint(x: position.x + offsetX, y: position.y + offsetY)
        
        addChild(sparkle)
        
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
    
    private func createSparkleShape() -> SKShapeNode {
        let size: CGFloat = 16
        let path = UIBezierPath()
        let center = CGPoint(x: 0, y: 0)
        let outerRadius = size / 2
        let innerRadius = size / 6
        
        // 4-pointed star
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
        
        return SKShapeNode(path: path.cgPath)
    }
    
    private func createBalloon(color: UIColor) -> SKNode {
        let container = SKNode()
        
        // Balloon body
        let balloonSize = CGSize(width: 40, height: 50)
        let balloon = SKShapeNode(ellipseOf: balloonSize)
        balloon.fillColor = color
        balloon.strokeColor = color.withAlphaComponent(0.8)
        balloon.lineWidth = 2
        
        // Highlight
        let highlight = SKShapeNode(ellipseOf: CGSize(width: 15, height: 20))
        highlight.position = CGPoint(x: -8, y: 10)
        highlight.fillColor = .white.withAlphaComponent(0.4)
        highlight.strokeColor = .clear
        balloon.addChild(highlight)
        
        // String
        let stringPath = UIBezierPath()
        stringPath.move(to: CGPoint(x: 0, y: -25))
        stringPath.addCurve(
            to: CGPoint(x: 5, y: -60),
            controlPoint1: CGPoint(x: -5, y: -35),
            controlPoint2: CGPoint(x: 10, y: -50)
        )
        
        let string = SKShapeNode(path: stringPath.cgPath)
        string.strokeColor = .gray
        string.lineWidth = 1
        balloon.addChild(string)
        
        container.addChild(balloon)
        
        return container
    }
}

// MARK: - SwiftUI Wrapper
struct SKBalloonView: View {
    @State private var scene: BalloonScene?
    
    var body: some View {
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .allowsHitTesting(true)  // Enable tapping to pop!
            }
        }
        .onAppear {
            scene = BalloonScene(size: UIScreen.main.bounds.size)
        }
        .onDisappear {
            scene?.stopBalloons()
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        SKBalloonView()
        
        Text("Tap the balloons!")
            .foregroundColor(.white)
            .font(.title)
    }
}

