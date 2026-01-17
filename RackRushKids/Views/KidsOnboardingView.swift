import SwiftUI

struct KidsOnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    
    let contents: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome! 🧸",
            description: "Hi, I'm Benny! I'm so excited to help you play Word Rush Kids!",
            image: "sparkles",
            color: Color(hex: "667eea")
        ),
        OnboardingStep(
            title: "How to Play 🎯",
            description: "Connect letters to spell words. Longer words give you more points!",
            image: "hand.draw.fill",
            color: Color(hex: "00d2ff")
        ),
        OnboardingStep(
            title: "Earn Stickers! ✨",
            description: "Win games and complete daily challenges to fill your sticker book!",
            image: "star.fill",
            color: Color(hex: "FFD700")
        )
    ]
    
    var body: some View {
        ZStack {
            KidsTheme.backgroundGradient.ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { hasSeenOnboarding = true }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 20)
                
                TabView(selection: $currentPage) {
                    ForEach(0..<contents.count, id: \.self) { index in
                        OnboardingCard(step: contents[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                
                Spacer()
                
                // Action Button
                Button(action: {
                    if currentPage < contents.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        hasSeenOnboarding = true
                    }
                }) {
                    Text(currentPage == contents.count - 1 ? "Let's Play!" : "Next")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(currentPage == contents.count - 1 ? KidsTheme.winGradient : KidsTheme.playButtonGradient)
                                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                        )
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingStep {
    let title: String
    let description: String
    let image: String
    let color: Color
}

struct OnboardingCard: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.2))
                    .frame(width: 160, height: 160)
                
                Image(systemName: step.image)
                    .font(.system(size: 80))
                    .foregroundColor(step.color)
                    .shadow(color: step.color.opacity(0.5), radius: 10)
            }
            
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(step.description)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    KidsOnboardingView()
}
