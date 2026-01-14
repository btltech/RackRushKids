import SwiftUI

struct KidsSettingsView: View {
    @ObservedObject var gameState: KidsGameState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { gameState.screen = .home }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(KidsTheme.textSecondary)
                }
                
                Spacer()
                
                Text("Settings")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(KidsTheme.textPrimary)
                
                Spacer()
                
                Color.clear.frame(width: 24)
            }
            .padding()
            .background(KidsTheme.surface)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Age Group
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AGE GROUP")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(KidsTheme.textMuted)
                            .tracking(1.5)
                        
                        VStack(spacing: 8) {
                            ForEach(KidsAgeGroup.allCases, id: \.self) { age in
                                SettingsAgeRow(
                                    ageGroup: age,
                                    isSelected: gameState.ageGroup == age.rawValue,
                                    action: { gameState.ageGroup = age.rawValue }
                                )
                            }
                        }
                    }
                    
                    // Game Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GAME SETTINGS")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(KidsTheme.textMuted)
                            .tracking(1.5)
                        
                        VStack(spacing: 0) {
                            SettingsInfoRow(icon: "clock", label: "Round Timer", value: "30 seconds")
                            Divider().background(Color.white.opacity(0.1))
                            SettingsInfoRow(icon: "number", label: "Rounds per Match", value: "7 rounds")
                            Divider().background(Color.white.opacity(0.1))
                            SettingsInfoRow(icon: "textformat.abc", label: "Letters", value: "\(gameState.selectedAgeGroup.letterCount) letters")
                        }
                        .background(KidsTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Sound
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AUDIO")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(KidsTheme.textMuted)
                            .tracking(1.5)
                        
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 18))
                                .foregroundColor(KidsTheme.textSecondary)
                                .frame(width: 28)
                            
                            Text("Sound Effects")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(KidsTheme.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $gameState.soundEnabled)
                                .tint(Color(hex: "3a7bd5"))
                        }
                        .padding()
                        .background(KidsTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // About
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ABOUT")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(KidsTheme.textMuted)
                            .tracking(1.5)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Word Rush Kids")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(KidsTheme.textPrimary)
                            
                            Text("An educational word game that helps children build vocabulary and spelling skills through fun competitive play.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(KidsTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Version 1.0")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(KidsTheme.textMuted)
                                .padding(.top, 4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KidsTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Parents Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PARENTS")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(KidsTheme.textMuted)
                            .tracking(1.5)
                        
                        VStack(spacing: 0) {
                            Link(destination: URL(string: "https://github.com/btltech/RackRushKids/blob/main/PRIVACY_POLICY.md")!) {
                                SettingsInfoRow(icon: "hand.raised.fill", label: "Privacy Policy", value: "View")
                            }
                            Divider().background(Color.white.opacity(0.1))
                            Link(destination: URL(string: "https://github.com/btltech/RackRushKids/blob/main/SUPPORT.md")!) {
                                SettingsInfoRow(icon: "envelope.fill", label: "Support", value: "Contact")
                            }
                        }
                        .background(KidsTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Settings Age Row
struct SettingsAgeRow: View {
    let ageGroup: KidsAgeGroup
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ageGroup.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(KidsTheme.textPrimary)
                    
                    Text("\(ageGroup.letterCount) letters")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(KidsTheme.textMuted)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(KidsTheme.playButtonGradient)
                } else {
                    Circle()
                        .stroke(KidsTheme.textMuted, lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? KidsTheme.surface : KidsTheme.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color(hex: "3a7bd5").opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(KidsTheme.textSecondary)
                .frame(width: 28)
            
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(KidsTheme.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
        }
        .padding()
    }
}

#Preview {
    ZStack {
        KidsTheme.backgroundGradient.ignoresSafeArea()
        KidsSettingsView(gameState: KidsGameState())
    }
}
