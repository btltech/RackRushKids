import SwiftUI

// MARK: - Kids Theme (Sophisticated)
/// Modern, polished theme for kids - not dumbed down
struct KidsTheme {
    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "667eea"),  // Deep purple
            Color(hex: "764ba2")   // Rich violet
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let playButtonGradient = LinearGradient(
        colors: [Color(hex: "00d2ff"), Color(hex: "3a7bd5")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let winGradient = LinearGradient(
        colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let partyGradient = LinearGradient(
        colors: [Color(hex: "FF6B6B"), Color(hex: "FFE66D")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Solid Colors
    static let accent = Color(hex: "00d2ff")
    static let background = Color(hex: "667eea")
    
    static let playerSelfGradient = LinearGradient(
        colors: [Color(hex: "FFD700"), Color(hex: "FF8C00")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let playerOpponentGradient = LinearGradient(
        colors: [Color(hex: "00E5FF"), Color(hex: "0091FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Colors
    static let surface = Color.white.opacity(0.18)
    static let surfaceCard = Color.white.opacity(0.25)
    static let tileDepth = Color.black.opacity(0.15)
    
    // Vibrant tiles
    static let tileRed = Color(hex: "FF6B6B")
    static let tileOrange = Color(hex: "FFA94D")
    static let tileYellow = Color(hex: "FFE066")
    static let tileGreen = Color(hex: "69DB7C")
    static let tileBlue = Color(hex: "4DABF7")
    static let tilePurple = Color(hex: "DA77F2")
    static let tilePink = Color(hex: "F783AC")
    static let tileCyan = Color(hex: "3BC9DB")
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.85)
    static let textMuted = Color.white.opacity(0.6)
    
    // Stars
    static let starFilled = Color(hex: "FFD43B")
    static let starEmpty = Color.white.opacity(0.3)
    
    // MARK: - Tile Colors
    static func tileColor(for letter: String) -> Color {
        switch letter.uppercased().first ?? "A" {
        case "A", "B": return tileRed
        case "C", "D": return tileOrange
        case "E", "F", "G": return tileYellow
        case "H", "I", "J", "K": return tileGreen
        case "L", "M", "N": return tileBlue
        case "O", "P", "Q", "R": return tilePurple
        case "S", "T", "U": return tilePink
        default: return tileCyan
        }
    }
    
    // MARK: - Encouragements
    static let encouragements = [
        "Brilliant! 🎯",
        "Excellent! ⚡",
        "Outstanding! 🌟",
        "Impressive! 💫",
        "Champion! 🏆",
        "Spectacular! ✨",
        "Genius! 🧠",
        "Incredible! 🚀"
    ]
    
    static func randomEncouragement() -> String {
        encouragements.randomElement() ?? "Well done! 🌟"
    }
}

// MARK: - Glass Card Style
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(KidsTheme.surfaceCard)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
