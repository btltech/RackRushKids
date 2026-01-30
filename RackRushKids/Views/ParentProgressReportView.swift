import SwiftUI

// MARK: - Parent Progress Report View
struct ParentProgressReportView: View {
    @ObservedObject var statsManager = KidsStatsManager.shared
    @ObservedObject var streakManager = KidsStreakManager.shared
    @ObservedObject var badgeManager = KidsBadgeManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header stats
                        headerSection
                        
                        // Time played
                        statCard(
                            icon: "clock.fill",
                            iconColor: .blue,
                            title: "Time Played",
                            value: statsManager.formattedPlayTime,
                            subtitle: "Total play time"
                        )
                        
                        // Words section
                        wordsSection
                        
                        // Accuracy
                        accuracySection
                        
                        // Achievements
                        achievementsSection
                        
                        // Reset button (with confirmation)
                        resetButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Progress Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 20) {
            StatBox(
                value: "\(statsManager.totalGamesPlayed)",
                label: "Games",
                color: .purple
            )
            StatBox(
                value: "\(statsManager.totalWins)",
                label: "Wins",
                color: .green
            )
            StatBox(
                value: "\(streakManager.currentStreak)",
                label: "Streak",
                color: .orange
            )
        }
    }
    
    private func statCard(icon: String, iconColor: Color, title: String, value: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Words")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                MiniStatBox(value: "\(statsManager.totalWordsPlayed)", label: "Total", color: .blue)
                MiniStatBox(value: "\(statsManager.correctWords)", label: "Correct", color: .green)
                MiniStatBox(value: "\(statsManager.incorrectAttempts)", label: "Rejected", color: .red)
            }
            
            if !statsManager.longestWord.isEmpty {
                HStack {
                    Text("Longest word:")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    Text(statsManager.longestWord)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                    Text("(\(statsManager.longestWord.count) letters)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var accuracySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accuracy")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%.0f%%", statsManager.accuracy))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(accuracyColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accuracyColor)
                        .frame(width: geo.size.width * CGFloat(statsManager.accuracy / 100), height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var accuracyColor: Color {
        switch statsManager.accuracy {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges Earned")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(badgeManager.unlockedBadgeIds.count) / \(KidsBadgeManager.allBadges.count)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if badgeManager.unlockedBadges.isEmpty {
                Text("No badges yet - keep playing!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(badgeManager.unlockedBadges) { badge in
                            VStack(spacing: 4) {
                                Text(badge.emoji)
                                    .font(.system(size: 30))
                                Text(badge.name)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    @State private var showResetConfirmation = false
    
    private var resetButton: some View {
        Button(action: { showResetConfirmation = true }) {
            Text("Reset All Stats")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.red.opacity(0.8))
        }
        .padding(.top, 20)
        .alert("Reset Statistics?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                statsManager.resetStats()
            }
        } message: {
            Text("This will clear all gameplay statistics. Stickers and badges will be kept.")
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.3))
        )
    }
}

struct MiniStatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
    }
}

#Preview {
    ParentProgressReportView()
}
