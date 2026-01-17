import SpriteKit
import SwiftUI

// MARK: - Benny the Bear Mascot Scene
/// Animated mascot character for Kids Mode
class KidsMascotScene: SKScene {
    
    enum MascotState: String {
        case idle
        case happy
        case sad
        case cheering
        case thinking
    }
    
    private var mascotNode: SKSpriteNode?
    private var currentState: MascotState = .idle
    
    // Colors for dynamic glow effects
    private let happyColor = UIColor(red: 0.4, green: 0.85, blue: 0.4, alpha: 1.0)
    private let sadColor = UIColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0)
    private let cheerColor = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        
        createMascot()
        startIdleAnimation()
    }
    
    private func createMascot() {
        // Create Benny as a text-based emoji character (can be replaced with sprite assets)
        let benny = SKLabelNode(text: "🐻")
        benny.fontSize = 80
        benny.position = CGPoint(x: size.width / 2, y: size.height / 2)
        benny.name = "benny"
        
        mascotNode = SKSpriteNode()
        mascotNode?.addChild(benny)
        mascotNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        if let mascot = mascotNode {
            addChild(mascot)
        }
    }
    
    private func startIdleAnimation() {
        guard let mascot = mascotNode else { return }
        
        // Gentle floating bounce
        let moveUp = SKAction.moveBy(x: 0, y: 8, duration: 1.2)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = SKAction.moveBy(x: 0, y: -8, duration: 1.2)
        moveDown.timingMode = .easeInEaseOut
        
        let bounce = SKAction.sequence([moveUp, moveDown])
        mascot.run(.repeatForever(bounce), withKey: "idle")
    }
    
    // MARK: - Public API
    
    func setState(_ state: MascotState) {
        guard state != currentState else { return }
        currentState = state
        
        mascotNode?.removeAction(forKey: "idle")
        mascotNode?.removeAction(forKey: "reaction")
        
        switch state {
        case .idle:
            startIdleAnimation()
            
        case .happy:
            playHappyAnimation()
            
        case .sad:
            playSadAnimation()
            
        case .cheering:
            playCheeringAnimation()
            
        case .thinking:
            playThinkingAnimation()
        }
    }
    
    private func playHappyAnimation() {
        guard let mascot = mascotNode else { return }
        
        // Bounce up with scale
        let jump = SKAction.group([
            .moveBy(x: 0, y: 30, duration: 0.2),
            .scale(to: 1.2, duration: 0.2)
        ])
        let land = SKAction.group([
            .moveBy(x: 0, y: -30, duration: 0.2),
            .scale(to: 1.0, duration: 0.2)
        ])
        
        // Add sparkle particles
        createSparkles(color: happyColor)
        
        let resetAction = SKAction.run { [weak self] in
            self?.startIdleAnimation()
            self?.currentState = .idle
        }
        
        mascot.run(.sequence([jump, land, .wait(forDuration: 0.5), resetAction]), withKey: "reaction")
    }
    
    private func playSadAnimation() {
        guard let mascot = mascotNode else { return }
        
        // Shrink and droop
        let shrink = SKAction.scale(to: 0.85, duration: 0.3)
        let wait = SKAction.wait(forDuration: 1.0)
        let recover = SKAction.scale(to: 1.0, duration: 0.3)
        
        let resetAction = SKAction.run { [weak self] in
            self?.startIdleAnimation()
            self?.currentState = .idle
        }
        
        mascot.run(.sequence([shrink, wait, recover, resetAction]), withKey: "reaction")
    }
    
    private func playCheeringAnimation() {
        guard let mascot = mascotNode else { return }
        
        // Excited wiggles
        var actions: [SKAction] = []
        for _ in 0..<6 {
            actions.append(.rotate(byAngle: 0.15, duration: 0.1))
            actions.append(.rotate(byAngle: -0.15, duration: 0.1))
        }
        actions.append(.rotate(toAngle: 0, duration: 0.1))
        
        // Big jump
        let bigJump = SKAction.sequence([
            .group([.moveBy(x: 0, y: 50, duration: 0.25), .scale(to: 1.3, duration: 0.25)]),
            .group([.moveBy(x: 0, y: -50, duration: 0.25), .scale(to: 1.0, duration: 0.25)])
        ])
        
        // Confetti burst
        createSparkles(color: cheerColor)
        
        let resetAction = SKAction.run { [weak self] in
            self?.startIdleAnimation()
            self?.currentState = .idle
        }
        
        mascot.run(.sequence([.group([.sequence(actions), bigJump]), resetAction]), withKey: "reaction")
    }
    
    private func playThinkingAnimation() {
        guard let mascot = mascotNode else { return }
        
        // Tilt head
        let tilt = SKAction.rotate(byAngle: 0.2, duration: 0.3)
        let wait = SKAction.wait(forDuration: 1.5)
        let untilt = SKAction.rotate(toAngle: 0, duration: 0.3)
        
        let resetAction = SKAction.run { [weak self] in
            self?.startIdleAnimation()
            self?.currentState = .idle
        }
        
        mascot.run(.sequence([tilt, wait, untilt, resetAction]), withKey: "reaction")
    }
    
    private func createSparkles(color: UIColor) {
        let emitter = SKEmitterNode()
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 20
        emitter.particleLifetime = 0.8
        
        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        
        emitter.particleSize = CGSize(width: 8, height: 8)
        emitter.particleAlphaSpeed = -1.2
        
        // Create simple texture
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16))
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: CGSize(width: 16, height: 16))
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: rect)
        }
        emitter.particleTexture = SKTexture(image: image)
        
        addChild(emitter)
        
        emitter.run(.sequence([
            .wait(forDuration: 1.0),
            .removeFromParent()
        ]))
    }
}

// MARK: - Simple SwiftUI Benny Mascot
struct SKBennyView: View {
    @Binding var mascotState: KidsMascotScene.MascotState
    @State private var idlePivot = false
    
    // Timer for continuous idle bounce
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Sparkles for cheering
            if mascotState == .cheering {
                HStack(spacing: 8) {
                    Text("✨").font(.system(size: 20))
                    Text("✨").font(.system(size: 16)).offset(y: -10)
                }
                .offset(x: 30, y: -20)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Question mark for thinking
            if mascotState == .thinking {
                Text("❓")
                    .font(.system(size: 24))
                    .offset(x: 30, y: -20)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Main Benny emoji
            Text("🐻")
                .font(.system(size: 60))
                .scaleEffect(scaleForState)
                .offset(y: offsetForState + (mascotState == .idle ? (idlePivot ? -4 : 4) : 0))
                .rotationEffect(.degrees(rotationForState))
                .animation(.easeInOut(duration: 1.0), value: idlePivot)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: mascotState)
        }
        .frame(width: 120, height: 120)
        .onReceive(timer) { _ in
            if mascotState == .idle {
                idlePivot.toggle()
            }
        }
    }
    
    private var scaleForState: CGFloat {
        switch mascotState {
        case .idle: return 1.0
        case .happy: return 1.15
        case .sad: return 0.9
        case .cheering: return 1.3
        case .thinking: return 1.0
        }
    }
    
    private var offsetForState: CGFloat {
        switch mascotState {
        case .idle: return 0
        case .happy: return -10
        case .sad: return 10
        case .cheering: return -20
        case .thinking: return 0
        }
    }
    
    private var rotationForState: Double {
        switch mascotState {
        case .sad: return -8
        case .cheering: return 5
        case .thinking: return 2
        default: return 0
        }
    }
}

// MARK: - Kids SpriteKit Bridge
/// Convenience wrapper for Kids-specific SpriteKit effects

// Rainbow confetti for kids
struct SKKidsConfettiView: View {
    @State private var scene: ConfettiScene?
    
    var body: some View {
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            print("🎉 Kids confetti scene created")
            let newScene = ConfettiScene(size: UIScreen.main.bounds.size)
            newScene.isKidsMode = true
            scene = newScene
        }
    }
}

// Kids ambient particles (softer colors)
struct SKKidsAmbientParticlesView: View {
    @State private var scene: AmbientParticleScene?
    
    var body: some View {
        GeometryReader { geo in
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            print("✨ Kids ambient particles scene created")
            let newScene = AmbientParticleScene(size: UIScreen.main.bounds.size)
            newScene.isKidsMode = true
            scene = newScene
        }
    }
}

#Preview {
    ZStack {
        Color.purple.opacity(0.3).ignoresSafeArea()
        SKBennyView(mascotState: .constant(.idle))
            .frame(width: 200, height: 200)
    }
}
