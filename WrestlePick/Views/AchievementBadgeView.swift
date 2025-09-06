import SwiftUI

struct AchievementBadgeView: View {
    let badge: Badge
    let isEarned: Bool
    let isAnimated: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Badge Icon
            ZStack {
                Circle()
                    .fill(badgeBackgroundColor)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(badgeBorderColor, lineWidth: 3)
                    )
                
                Image(systemName: badge.iconName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(badgeIconColor)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        isAnimated ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                        value: isAnimating
                    )
            }
            
            // Badge Info
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(badge.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if isEarned {
                    Text("Earned \(badge.earnedDate, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                } else {
                    Text("Not Earned")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        .opacity(isEarned ? 1.0 : 0.6)
        .onAppear {
            if isAnimated && isEarned {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Computed Properties
    private var badgeBackgroundColor: Color {
        if isEarned {
            switch badge.rarity {
            case .common: return Color.green.opacity(0.2)
            case .rare: return Color.blue.opacity(0.2)
            case .epic: return Color.purple.opacity(0.2)
            case .legendary: return Color.orange.opacity(0.2)
            }
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var badgeBorderColor: Color {
        if isEarned {
            switch badge.rarity {
            case .common: return Color.green
            case .rare: return Color.blue
            case .epic: return Color.purple
            case .legendary: return Color.orange
            }
        } else {
            return Color.gray
        }
    }
    
    private var badgeIconColor: Color {
        if isEarned {
            switch badge.rarity {
            case .common: return Color.green
            case .rare: return Color.blue
            case .epic: return Color.purple
            case .legendary: return Color.orange
            }
        } else {
            return Color.gray
        }
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    private let allBadges = BadgeType.allCases.map { Badge(
        id: UUID().uuidString,
        name: $0.name,
        description: $0.description,
        iconName: $0.iconName,
        earnedDate: nil,
        rarity: $0.rarity
    )}
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(allBadges, id: \.id) { badge in
                        let isEarned = authService.currentUser?.predictionStats.badges.contains { $0.name == badge.name } ?? false
                        
                        AchievementBadgeView(
                            badge: badge,
                            isEarned: isEarned,
                            isAnimated: isEarned
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Badge Types
enum BadgeType: CaseIterable {
    case firstPrediction
    case predictionStreak5
    case predictionStreak10
    case predictionStreak25
    case accuracy80
    case accuracy90
    case accuracy95
    case totalPredictions10
    case totalPredictions50
    case totalPredictions100
    case totalPredictions500
    case weeklyChampion
    case monthlyChampion
    case yearlyChampion
    case socialButterfly
    case newsJunkie
    case predictionMaster
    
    var name: String {
        switch self {
        case .firstPrediction: return "First Steps"
        case .predictionStreak5: return "Hot Streak"
        case .predictionStreak10: return "On Fire"
        case .predictionStreak25: return "Unstoppable"
        case .accuracy80: return "Accurate"
        case .accuracy90: return "Precise"
        case .accuracy95: return "Prophet"
        case .totalPredictions10: return "Getting Started"
        case .totalPredictions50: return "Regular"
        case .totalPredictions100: return "Dedicated"
        case .totalPredictions500: return "Veteran"
        case .weeklyChampion: return "Weekly Champion"
        case .monthlyChampion: return "Monthly Champion"
        case .yearlyChampion: return "Yearly Champion"
        case .socialButterfly: return "Social Butterfly"
        case .newsJunkie: return "News Junkie"
        case .predictionMaster: return "Prediction Master"
        }
    }
    
    var description: String {
        switch self {
        case .firstPrediction: return "Make your first prediction"
        case .predictionStreak5: return "Get 5 predictions correct in a row"
        case .predictionStreak10: return "Get 10 predictions correct in a row"
        case .predictionStreak25: return "Get 25 predictions correct in a row"
        case .accuracy80: return "Achieve 80% accuracy"
        case .accuracy90: return "Achieve 90% accuracy"
        case .accuracy95: return "Achieve 95% accuracy"
        case .totalPredictions10: return "Make 10 total predictions"
        case .totalPredictions50: return "Make 50 total predictions"
        case .totalPredictions100: return "Make 100 total predictions"
        case .totalPredictions500: return "Make 500 total predictions"
        case .weeklyChampion: return "Top predictor of the week"
        case .monthlyChampion: return "Top predictor of the month"
        case .yearlyChampion: return "Top predictor of the year"
        case .socialButterfly: return "Follow 50 users"
        case .newsJunkie: return "Read 100 news articles"
        case .predictionMaster: return "Master all prediction skills"
        }
    }
    
    var iconName: String {
        switch self {
        case .firstPrediction: return "star.fill"
        case .predictionStreak5: return "flame.fill"
        case .predictionStreak10: return "flame.circle.fill"
        case .predictionStreak25: return "flame.circle"
        case .accuracy80: return "target"
        case .accuracy90: return "scope"
        case .accuracy95: return "scope.fill"
        case .totalPredictions10: return "10.circle.fill"
        case .totalPredictions50: return "50.circle.fill"
        case .totalPredictions100: return "100.circle.fill"
        case .totalPredictions500: return "500.circle.fill"
        case .weeklyChampion: return "calendar"
        case .monthlyChampion: return "calendar.circle.fill"
        case .yearlyChampion: return "calendar.badge.plus"
        case .socialButterfly: return "person.2.fill"
        case .newsJunkie: return "newspaper.fill"
        case .predictionMaster: return "crown.fill"
        }
    }
    
    var rarity: BadgeRarity {
        switch self {
        case .firstPrediction, .totalPredictions10, .socialButterfly, .newsJunkie:
            return .common
        case .predictionStreak5, .accuracy80, .totalPredictions50, .weeklyChampion:
            return .rare
        case .predictionStreak10, .accuracy90, .totalPredictions100, .monthlyChampion:
            return .epic
        case .predictionStreak25, .accuracy95, .totalPredictions500, .yearlyChampion, .predictionMaster:
            return .legendary
        }
    }
}

#Preview {
    let sampleBadge = Badge(
        id: "1",
        name: "First Steps",
        description: "Make your first prediction",
        iconName: "star.fill",
        earnedDate: Date(),
        rarity: .common
    )
    
    return VStack {
        AchievementBadgeView(badge: sampleBadge, isEarned: true, isAnimated: true)
        AchievementBadgeView(badge: sampleBadge, isEarned: false, isAnimated: false)
    }
    .padding()
}
