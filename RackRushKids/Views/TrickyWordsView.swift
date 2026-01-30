import SwiftUI

/// Parent-only view showing today's "tricky words" the child struggled with.
/// Accessible only from Parental Controls (PIN-gated).
struct TrickyWordsView: View {
    @ObservedObject private var trickyWords = TrickyWordsManager.shared
    @ObservedObject private var featureFlags = KidsFeatureFlags.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                KidsTheme.backgroundGradient.ignoresSafeArea()
                
                if !featureFlags.trickyWordsEnabled {
                    // Feature disabled
                    VStack(spacing: 20) {
                        Image(systemName: "flask")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Coming Soon!")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("This feature is not yet enabled.")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else if trickyWords.totalAttemptsToday == 0 {
                    // No data today
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No Words Yet")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Play some games to see today's words!")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Today's Stats Card
                            statsCard
                            
                            // Tricky Words List
                            if !trickyWords.trickyWords.isEmpty {
                                trickyWordsSection
                            }
                            
                            // All Words
                            allWordsSection
                            
                            // Reset button
                            resetButton
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Today's Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 30) {
                statItem(value: "\(trickyWords.totalAttemptsToday)", label: "Words Tried")
                statItem(value: "\(Int(trickyWords.correctRateToday * 100))%", label: "Accuracy")
                statItem(value: "\(trickyWords.trickyWords.count)", label: "Tricky")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Tricky Words Section
    
    private var trickyWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚠️ Tricky Words")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.orange)
                
                Spacer()
            }
            
            Text("Words your child missed today:")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(trickyWords.trickyWords, id: \.self) { word in
                    Text(word)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.orange.opacity(0.3)))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - All Words Section
    
    private var allWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📚 All Words Today")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            ForEach(trickyWords.allWordsWithStats, id: \.word) { item in
                HStack {
                    Text(item.word)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(item.correct)/\(item.attempts)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(item.correct == item.attempts ? .green : .orange)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        Button(action: { trickyWords.resetToday() }) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("Reset Today's Data")
            }
            .font(.system(.body, design: .rounded))
            .foregroundColor(.red.opacity(0.8))
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    TrickyWordsView()
}
