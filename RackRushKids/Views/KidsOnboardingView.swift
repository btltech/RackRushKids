import SwiftUI

struct KidsOnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    
    let contents: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome! 🧸",
            description: "Hi, I'm Benny the Bear! I'm so excited to help you play RackRush Kids!",
            image: "sparkles",
            color: Color(hex: "667eea"),
            mascotEmoji: "🐻"
        ),
        OnboardingStep(
            title: "Make Words! 🔤",
            description: "You get 7 letters. Tap them to spell words! The longer your word, the more points you get!",
            image: "character.textbox",
            color: Color(hex: "00d2ff"),
            mascotEmoji: nil
        ),
        OnboardingStep(
            title: "Take Turns 🎲",
            description: "You and a friend take turns making words. Try to score more points to win!",
            image: "arrow.left.arrow.right",
            color: Color(hex: "f093fb"),
            mascotEmoji: nil
        ),
        OnboardingStep(
            title: "Earn Stars! ⭐",
            description: "Win games to earn stars on your islands. Get 3 stars by scoring lots of points!",
            image: "star.fill",
            color: Color(hex: "FFD700"),
            mascotEmoji: nil
        ),
        OnboardingStep(
            title: "Collect Stickers! 🎨",
            description: "Win games to fill your sticker book with animals, food, and fun stuff!",
            image: "sparkles.rectangle.stack",
            color: Color(hex: "FF6B6B"),
            mascotEmoji: nil
        ),
        OnboardingStep(
            title: "Build Your Streak! 🔥",
            description: "Play every day to build your streak! Can you play for 7 days in a row?",
            image: "flame.fill",
            color: Color(hex: "FF9500"),
            mascotEmoji: nil
        ),
        OnboardingStep(
            title: "Pick Your Avatar 🦊",
            description: "Choose a fun character! Win more games to unlock special avatars!",
            image: "person.crop.circle.fill",
            color: Color(hex: "5AC8FA"),
            mascotEmoji: "🦊"
        ),
        OnboardingStep(
            title: "Learn New Words 📖",
            description: "Every day there's a new Word of the Day. Learn what it means!",
            image: "book.fill",
            color: Color(hex: "34C759"),
            mascotEmoji: nil
        ),
        OnboardingStep(
            title: "Need Help? 💡",
            description: "Stuck on a word? Use a hint coin! You earn hint coins by playing games.",
            image: "lightbulb.fill",
            color: Color(hex: "FFCC00"),
            mascotEmoji: nil
        ),
        OnboardingStep(
            title: "Let's Go! 🚀",
            description: "You're ready to play! Spell words, win games, and have fun!",
            image: "rocket.fill",
            color: Color(hex: "667eea"),
            mascotEmoji: "🐻"
        )
    ]
    
    var body: some View {
        ZStack {
            KidsTheme.backgroundGradient.ignoresSafeArea()
            
            VStack {
                HStack {
                    // Page indicator text
                    Text("\(currentPage + 1) of \(contents.count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 24)
                    
                    Spacer()
                    
                    Button(action: { hasSeenOnboarding = true }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .frame(minWidth: 80, minHeight: 44)
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
                
                // Progress dots (custom, larger)
                HStack(spacing: 8) {
                    ForEach(0..<contents.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 12 : 8, height: index == currentPage ? 12 : 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    // Back button (hidden on first page)
                    Button(action: {
                        withAnimation {
                            currentPage = max(0, currentPage - 1)
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                    .opacity(currentPage > 0 ? 1 : 0)
                    .disabled(currentPage == 0)
                    
                    // Next/Start button
                    Button(action: {
                        if currentPage < contents.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            hasSeenOnboarding = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentPage == contents.count - 1 ? "Let's Play!" : "Next")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                            
                            if currentPage < contents.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(currentPage == contents.count - 1 ? KidsTheme.winGradient : KidsTheme.playButtonGradient)
                                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                        )
                    }
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
    var mascotEmoji: String? = nil
}

struct OnboardingCard: View {
    let step: OnboardingStep
    @State private var bounceAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Background circle
                Circle()
                    .fill(step.color.opacity(0.2))
                    .frame(width: 160, height: 160)
                
                // Icon or mascot
                if let mascot = step.mascotEmoji {
                    Text(mascot)
                        .font(.system(size: 80))
                        .scaleEffect(bounceAnimation ? 1.1 : 1.0)
                } else {
                    Image(systemName: step.image)
                        .font(.system(size: 70))
                        .foregroundColor(step.color)
                        .shadow(color: step.color.opacity(0.5), radius: 10)
                        .scaleEffect(bounceAnimation ? 1.05 : 1.0)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    bounceAnimation = true
                }
            }
            
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(step.description)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 20)
    }
}

#Preview {
    KidsOnboardingView()
}
