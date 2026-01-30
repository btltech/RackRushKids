import SwiftUI

// MARK: - Streak Badge
struct StreakBadge: View {
    @ObservedObject var streakManager = KidsStreakManager.shared
    
    var body: some View {
        if streakManager.currentStreak > 0 {
            HStack(spacing: 6) {
                Text(streakManager.streakEmoji)
                    .font(.system(size: 16))
                Text("\(streakManager.currentStreak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("day\(streakManager.currentStreak == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .orange.opacity(0.4), radius: 5)
        }
    }
}

// MARK: - Streak Milestone Celebration
struct StreakCelebration: View {
    @ObservedObject var streakManager = KidsStreakManager.shared
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        if streakManager.showStreakAnimation, let milestone = streakManager.streakMilestone {
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(milestoneEmoji(for: milestone))
                        .font(.system(size: 80))
                    
                    Text("\(milestone)-Day Streak!")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(milestoneMessage(for: milestone))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        withAnimation {
                            streakManager.showStreakAnimation = false
                            streakManager.streakMilestone = nil
                        }
                    }) {
                        Text("Awesome!")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                            )
                    }
                    .padding(.top, 10)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(hex: "1a1a2e"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .strokeBorder(Color.orange.opacity(0.5), lineWidth: 3)
                        )
                )
                .scaleEffect(scale)
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
    
    private func milestoneEmoji(for days: Int) -> String {
        switch days {
        case 3: return "🔥"
        case 7: return "🌟"
        case 14: return "💎"
        case 30: return "👑"
        case 100: return "🏆"
        default: return "⭐"
        }
    }
    
    private func milestoneMessage(for days: Int) -> String {
        switch days {
        case 3: return "You're on fire! Keep it up!"
        case 7: return "A whole week! You're amazing!"
        case 14: return "Two weeks strong! Super star!"
        case 30: return "One month! You're a champion!"
        case 100: return "100 days! Incredible dedication!"
        default: return "Keep playing every day!"
        }
    }
}

// MARK: - Word of the Day Card
struct WordOfTheDayCard: View {
    @ObservedObject var wotdManager = KidsWordOfTheDayManager.shared
    @State private var isExpanded = false
    
    var body: some View {
        if let word = wotdManager.todaysWord {
            VStack(spacing: 0) {
                // Header
                Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                    HStack {
                        Text("📖")
                            .font(.system(size: 20))
                        Text("Word of the Day")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: isExpanded ? 16 : 16)
                            .fill(Color.purple.opacity(0.6))
                    )
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(word.word)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(word.definition)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack {
                            Text("Example:")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.yellow)
                            Text(word.example)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .italic()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purple.opacity(0.4))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Word of the Day Popup
struct WordOfTheDayPopup: View {
    @ObservedObject var wotdManager = KidsWordOfTheDayManager.shared
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        if wotdManager.showWordOfTheDay, let word = wotdManager.todaysWord {
            ZStack {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                
                VStack(spacing: 20) {
                    Text("📖")
                        .font(.system(size: 50))
                    
                    Text("Word of the Day")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(word.word)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(word.definition)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 4) {
                        Text("Example:")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                        Text("\"\(word.example)\"")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .italic()
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: dismiss) {
                        Text("Got it!")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                            )
                    }
                    .padding(.top, 10)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(hex: "1a1a2e"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .strokeBorder(Color.purple.opacity(0.5), lineWidth: 3)
                        )
                )
                .padding(.horizontal, 30)
                .scaleEffect(scale)
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            wotdManager.dismissWordOfTheDay()
        }
    }
}

// MARK: - Hint Coin Display
struct HintCoinBadge: View {
    @ObservedObject var hintManager = KidsHintManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 14))
            Text("\(hintManager.hintCoins)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.3))
        )
    }
}

// MARK: - Avatar Picker
struct AvatarPickerView: View {
    @ObservedObject var avatarManager = KidsAvatarManager.shared
    @Environment(\.dismiss) var dismiss
    
    let columns = [GridItem(.adaptive(minimum: 90), spacing: 16)]
    
    var body: some View {
        NavigationView {
            ZStack {
                KidsTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current avatar
                        VStack(spacing: 12) {
                            Text(avatarManager.selectedAvatar.emoji)
                                .font(.system(size: 80))
                            Text(avatarManager.selectedAvatar.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // Avatar grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(KidsAvatarManager.allAvatars) { avatar in
                                AvatarCell(
                                    avatar: avatar,
                                    isUnlocked: avatarManager.unlockedAvatarIds.contains(avatar.id),
                                    isSelected: avatarManager.selectedAvatar.id == avatar.id
                                ) {
                                    avatarManager.selectAvatar(avatar.id)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct AvatarCell: View {
    let avatar: KidsAvatarManager.Avatar
    let isUnlocked: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color.white.opacity(0.2) : Color.gray.opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    if isUnlocked {
                        Text(avatar.emoji)
                            .font(.system(size: 36))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.yellow, lineWidth: 3)
                            .frame(width: 76, height: 76)
                    }
                }
                
                Text(avatar.name)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                    .lineLimit(1)
                
                if !isUnlocked {
                    Text(avatar.unlockCondition)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .disabled(!isUnlocked)
    }
}

// MARK: - Badge Collection View
struct BadgeCollectionView: View {
    @ObservedObject var badgeManager = KidsBadgeManager.shared
    @Environment(\.dismiss) var dismiss
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]
    
    var body: some View {
        NavigationView {
            ZStack {
                KidsTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress
                        Text("\(badgeManager.unlockedBadgeIds.count) / \(KidsBadgeManager.allBadges.count) Badges")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 20)
                        
                        // Badge grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(KidsBadgeManager.allBadges) { badge in
                                BadgeCell(
                                    badge: badge,
                                    isUnlocked: badgeManager.unlockedBadgeIds.contains(badge.id)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("My Badges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct BadgeCell: View {
    let badge: KidsBadgeManager.Badge
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isUnlocked ? categoryColor.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if isUnlocked {
                    Text(badge.emoji)
                        .font(.system(size: 36))
                } else {
                    Text("?")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            Text(badge.name)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(isUnlocked ? .white : .white.opacity(0.4))
                .lineLimit(1)
            
            Text(badge.description)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100)
    }
    
    private var categoryColor: Color {
        switch badge.category {
        case .words: return .blue
        case .speed: return .yellow
        case .streak: return .orange
        case .collection: return .purple
        case .skill: return .green
        }
    }
}

// MARK: - New Badge Popup
struct NewBadgePopup: View {
    @ObservedObject var badgeManager = KidsBadgeManager.shared
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        if let badge = badgeManager.newlyUnlockedBadge {
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 40))
                    
                    Text("New Badge!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(badge.emoji)
                        .font(.system(size: 80))
                        .scaleEffect(scale)
                    
                    Text(badge.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(badge.description)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: {
                        withAnimation {
                            badgeManager.newlyUnlockedBadge = nil
                        }
                    }) {
                        Text("Awesome!")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing))
                            )
                    }
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(hex: "1a1a2e"))
                )
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    scale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring()) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}
