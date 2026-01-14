import SwiftUI

struct KidsTutorialOverlay: View {
    @Binding var isShowing: Bool
    
    @State private var handOffset: CGSize = CGSize(width: -50, height: 20)
    @State private var isTapping = false
    
    var body: some View {
        ZStack {
            backgroundLayer
            
            VStack(spacing: 30) {
                Spacer()
                
                tutorialContent
                
                animationDemo
                
                Spacer()
                
                readyButton
                    .padding(.bottom, 50)
            }
            .padding()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private var backgroundLayer: some View {
        Color.black.opacity(0.7).ignoresSafeArea()
            .onTapGesture {
                withAnimation { isShowing = false }
            }
    }
    
    private var tutorialContent: some View {
        VStack(spacing: 20) {
            Text("Let's Play!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .purple, radius: 2, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    Text("Tap letters to build words")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Tap Submit to send!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.2))
            )
        }
    }
    
    private var animationDemo: some View {
        ZStack {
            HStack(spacing: 15) {
                ForEach(0..<3, id: \.self) { i in
                    tile(at: i)
                }
            }
            
            handCursor
        }
        .frame(height: 100)
    }
    
    private func tile(at index: Int) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(index == 1 && isTapping ? Color.orange.opacity(0.8) : Color.orange)
            .frame(width: 60, height: 60)
            .overlay(
                Text(String("CAT".map{$0}[index]))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            )
            .scaleEffect(index == 1 && isTapping ? 0.9 : 1.0)
    }
    
    private var handCursor: some View {
        Image(systemName: "hand.point.up.fill")
            .font(.system(size: 50))
            .foregroundColor(.white)
            .shadow(radius: 5)
            .offset(x: handOffset.width, y: handOffset.height)
            .scaleEffect(isTapping ? 0.8 : 1.0)
            .rotationEffect(.degrees(isTapping ? -10 : 0))
    }
    
    private var readyButton: some View {
        Button(action: {
            KidsAudioManager.shared.playNavigation()
            withAnimation { isShowing = false }
        }) {
            Text("I'm Ready!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(radius: 10)
                .scaleEffect(isTapping ? 1.05 : 1.0)
        }
    }
    
    func startAnimation() {
        // Simple breathing animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            isTapping = true
            handOffset = CGSize(width: -10, height: 10) // Small movement
        }
    }
}
