import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    
    init() {
        // Check system appearance
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            self.isDarkMode = windowScene.traitCollection.userInterfaceStyle == .dark
        }
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}

// MARK: - Color Extensions for Theme Support
extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    // Primary Colors
    let primary = Color("PrimaryColor")
    let secondary = Color("SecondaryColor")
    let accent = Color("AccentColor")
    
    // Background Colors
    let background = Color("BackgroundColor")
    let surface = Color("SurfaceColor")
    let cardBackground = Color("CardBackgroundColor")
    
    // Text Colors
    let textPrimary = Color("TextPrimaryColor")
    let textSecondary = Color("TextSecondaryColor")
    let textTertiary = Color("TextTertiaryColor")
    
    // Status Colors
    let success = Color("SuccessColor")
    let warning = Color("WarningColor")
    let error = Color("ErrorColor")
    let info = Color("InfoColor")
    
    // Wrestling Promotion Colors
    let wwe = Color("WWEColor")
    let aew = Color("AEWColor")
    let njpw = Color("NJPWColor")
    let impact = Color("ImpactColor")
    let indie = Color("IndieColor")
    
    // Reliability Tier Colors
    let tier1 = Color("Tier1Color")
    let tier2 = Color("Tier2Color")
    let speculation = Color("SpeculationColor")
    let unverified = Color("UnverifiedColor")
}

// MARK: - Custom Color Definitions
extension Color {
    // Wrestling Promotion Colors
    static let wweBlue = Color(red: 0.0, green: 0.4, blue: 0.8)
    static let aewRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    static let njpwPurple = Color(red: 0.4, green: 0.0, blue: 0.6)
    static let impactOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let indieGreen = Color(red: 0.0, green: 0.6, blue: 0.2)
    
    // Reliability Colors
    static let tier1Green = Color(red: 0.0, green: 0.7, blue: 0.0)
    static let tier2Blue = Color(red: 0.0, green: 0.5, blue: 1.0)
    static let speculationOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let unverifiedRed = Color(red: 0.8, green: 0.0, blue: 0.0)
    
    // Status Colors
    static let breakingRed = Color(red: 0.8, green: 0.0, blue: 0.0)
    static let rumorYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let spoilerPink = Color(red: 1.0, green: 0.4, blue: 0.8)
}

// MARK: - View Modifiers for Theme Support
struct ThemedCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(
                color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 1
            )
    }
}

struct ThemedButtonModifier: ViewModifier {
    let isSelected: Bool
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(8)
    }
}

// MARK: - View Extensions
extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }
    
    func themedButton(isSelected: Bool, color: Color = .blue) -> some View {
        modifier(ThemedButtonModifier(isSelected: isSelected, color: color))
    }
}

// MARK: - Preview Helper
struct ThemePreview: View {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Theme Preview")
                .font(.title)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Wrestling Promotion Colors")
                    .font(.headline)
                
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.wweBlue)
                        .frame(width: 30, height: 30)
                    Text("WWE")
                    
                    Circle()
                        .fill(Color.aewRed)
                        .frame(width: 30, height: 30)
                    Text("AEW")
                    
                    Circle()
                        .fill(Color.njpwPurple)
                        .frame(width: 30, height: 30)
                    Text("NJPW")
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Reliability Tiers")
                    .font(.headline)
                
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.tier1Green)
                        .frame(width: 30, height: 30)
                    Text("Tier 1")
                    
                    Circle()
                        .fill(Color.tier2Blue)
                        .frame(width: 30, height: 30)
                    Text("Tier 2")
                    
                    Circle()
                        .fill(Color.speculationOrange)
                        .frame(width: 30, height: 30)
                    Text("Speculation")
                }
            }
            
            Button("Toggle Theme") {
                themeManager.toggleTheme()
            }
            .themedButton(isSelected: true, color: .blue)
        }
        .padding()
        .environmentObject(themeManager)
    }
}

#Preview {
    ThemePreview()
}
