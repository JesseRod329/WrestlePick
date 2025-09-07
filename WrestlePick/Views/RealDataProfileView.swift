import SwiftUI

struct RealDataProfileView: View {
    @EnvironmentObject var wrestlerService: WrestlerDataService
    @EnvironmentObject var merchService: MerchandiseDataService
    @State private var selectedTab: ProfileTab = .overview
    @State private var showingEditProfile = false
    
    var user: User {
        // Mock user data - in real implementation, this would come from AuthService
        generateMockUser()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Profile Header
                ProfileHeader(user: user)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Tab Selector
                TabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    OverviewTab(user: user)
                        .tag(ProfileTab.overview)
                    
                    PredictionsTab(user: user)
                        .tag(ProfileTab.predictions)
                    
                    MerchandiseTab(user: user)
                        .tag(ProfileTab.merchandise)
                    
                    SettingsTab(user: user)
                        .tag(ProfileTab.settings)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(user: user)
            }
        }
    }
}

struct ProfileHeader: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture and Basic Info
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let bio = user.bio {
                        Text(bio)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            
            // Stats
            HStack(spacing: 24) {
                StatItem(title: "Predictions", value: "\(user.predictionStats.totalPredictions)")
                StatItem(title: "Accuracy", value: "\(Int(user.predictionStats.accuracy * 100))%")
                StatItem(title: "Streak", value: "\(user.predictionStats.currentStreak)")
                StatItem(title: "Rank", value: "#\(user.predictionStats.rank)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TabSelector: View {
    @Binding var selectedTab: ProfileTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Text(tab.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .bold : .medium)
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? .blue : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct OverviewTab: View {
    let user: User
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(user.recentActivity.prefix(5)) { activity in
                        ActivityRow(activity: activity)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Achievements
                VStack(alignment: .leading, spacing: 12) {
                    Text("Achievements")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(user.achievements.prefix(6)) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct PredictionsTab: View {
    let user: User
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Prediction Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prediction Statistics")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        StatCard(title: "Total Predictions", value: "\(user.predictionStats.totalPredictions)", color: .blue)
                        StatCard(title: "Correct Predictions", value: "\(user.predictionStats.correctPredictions)", color: .green)
                        StatCard(title: "Accuracy Rate", value: "\(Int(user.predictionStats.accuracy * 100))%", color: .orange)
                        StatCard(title: "Current Streak", value: "\(user.predictionStats.currentStreak)", color: .purple)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Recent Predictions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Predictions")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(user.recentPredictions.prefix(5)) { prediction in
                        PredictionRow(prediction: prediction)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct MerchandiseTab: View {
    let user: User
    @EnvironmentObject var merchService: MerchandiseDataService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Merchandise Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Merchandise Collection")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        StatCard(title: "Total Items", value: "\(user.merchandiseStats.totalItems)", color: .blue)
                        StatCard(title: "Total Spent", value: "$\(user.merchandiseStats.totalSpent)", color: .green)
                        StatCard(title: "Favorite Brand", value: user.merchandiseStats.favoriteBrand, color: .orange)
                        StatCard(title: "Last Purchase", value: user.merchandiseStats.lastPurchaseDate, color: .purple)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Recent Purchases
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Purchases")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(user.recentPurchases.prefix(5)) { purchase in
                        PurchaseRow(purchase: purchase)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct SettingsTab: View {
    let user: User
    
    var body: some View {
        List {
            Section("Account") {
                SettingsRow(title: "Edit Profile", icon: "person.circle", action: {})
                SettingsRow(title: "Privacy Settings", icon: "lock.circle", action: {})
                SettingsRow(title: "Notification Settings", icon: "bell.circle", action: {})
            }
            
            Section("Preferences") {
                SettingsRow(title: "Theme", icon: "paintbrush", action: {})
                SettingsRow(title: "Language", icon: "globe", action: {})
                SettingsRow(title: "Units", icon: "ruler", action: {})
            }
            
            Section("Data") {
                SettingsRow(title: "Export Data", icon: "square.and.arrow.up", action: {})
                SettingsRow(title: "Clear Cache", icon: "trash", action: {})
            }
            
            Section("Support") {
                SettingsRow(title: "Help Center", icon: "questionmark.circle", action: {})
                SettingsRow(title: "Contact Us", icon: "envelope", action: {})
                SettingsRow(title: "Rate App", icon: "star", action: {})
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .foregroundColor(activity.type.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.color)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct PredictionRow: View {
    let prediction: Prediction
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(prediction.event.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(prediction.prediction)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(prediction.confidence.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(prediction.confidence.color.opacity(0.2))
                    .foregroundColor(prediction.confidence.color)
                    .clipShape(Capsule())
                
                Text(prediction.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PurchaseRow: View {
    let purchase: MerchandisePurchase
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: purchase.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(purchase.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("$\(purchase.price, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(purchase.purchaseDate, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Types
enum ProfileTab: CaseIterable {
    case overview
    case predictions
    case merchandise
    case settings
    
    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .predictions: return "Predictions"
        case .merchandise: return "Merchandise"
        case .settings: return "Settings"
        }
    }
}

// MARK: - Mock Data
private func generateMockUser() -> User {
    return User(
        id: "user-1",
        username: "wrestlingfan123",
        displayName: "Wrestling Fan",
        email: "fan@example.com",
        profileImageURL: "https://example.com/profile.jpg",
        bio: "Passionate wrestling fan and prediction enthusiast",
        isVerified: false,
        followerCount: 150,
        followingCount: 75,
        predictionStats: PredictionStats(
            totalPredictions: 45,
            correctPredictions: 32,
            accuracy: 0.71,
            currentStreak: 5,
            longestStreak: 12,
            rank: 23
        ),
        merchandiseStats: MerchandiseStats(
            totalItems: 25,
            totalSpent: 450.00,
            favoriteBrand: "WWE",
            lastPurchaseDate: "2 days ago"
        ),
        recentActivity: [
            Activity(id: "activity-1", type: .prediction, description: "Made a prediction for WrestleMania", timestamp: Date()),
            Activity(id: "activity-2", type: .achievement, description: "Earned 'Prediction Master' badge", timestamp: Date().addingTimeInterval(-3600)),
            Activity(id: "activity-3", type: .purchase, description: "Bought Roman Reigns T-shirt", timestamp: Date().addingTimeInterval(-7200))
        ],
        achievements: [
            Achievement(id: "achievement-1", title: "Prediction Master", description: "Made 50 predictions", icon: "crystal.ball", color: .blue),
            Achievement(id: "achievement-2", title: "Accuracy Expert", description: "Achieved 80% accuracy", icon: "target", color: .green),
            Achievement(id: "achievement-3", title: "Streak King", description: "10 correct predictions in a row", icon: "flame", color: .orange)
        ],
        recentPredictions: [
            Prediction(id: "pred-1", event: WrestlingEvent(id: "event-1", name: "WrestleMania 40", promotion: .wwe, date: Date(), venue: Venue(name: "Lincoln Financial Field", city: "Philadelphia", state: "Pennsylvania", country: "United States", capacity: 70000), eventType: .ppv, matches: [], ticketInfo: nil, streamingInfo: nil, status: .scheduled, description: "", imageURL: nil, socialMedia: nil), prediction: "Roman Reigns will retain", confidence: .high, isCorrect: nil, createdAt: Date()),
            Prediction(id: "pred-2", event: WrestlingEvent(id: "event-2", name: "AEW Revolution", promotion: .aew, date: Date(), venue: Venue(name: "Greensboro Coliseum", city: "Greensboro", state: "North Carolina", country: "United States", capacity: 23500), eventType: .ppv, matches: [], ticketInfo: nil, streamingInfo: nil, status: .scheduled, description: "", imageURL: nil, socialMedia: nil), prediction: "Jon Moxley will win", confidence: .medium, isCorrect: nil, createdAt: Date().addingTimeInterval(-3600))
        ],
        recentPurchases: [
            MerchandisePurchase(id: "purchase-1", name: "Roman Reigns T-shirt", price: 29.99, imageURL: "https://example.com/tshirt.jpg", purchaseDate: Date()),
            MerchandisePurchase(id: "purchase-2", name: "AEW Hoodie", price: 59.99, imageURL: "https://example.com/hoodie.jpg", purchaseDate: Date().addingTimeInterval(-86400))
        ]
    )
}

#Preview {
    RealDataProfileView()
        .environmentObject(WrestlerDataService.shared)
        .environmentObject(MerchandiseDataService.shared)
}
