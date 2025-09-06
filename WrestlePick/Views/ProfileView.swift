import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingAchievements = false
    @State private var showingDataExport = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView(
                        user: authService.currentUser,
                        isGuest: authService.isGuest,
                        onEditProfile: { showingEditProfile = true }
                    )
                    
                    // Stats Overview
                    if !authService.isGuest {
                        StatsOverviewView(user: authService.currentUser)
                    }
                    
                    // Quick Actions
                    QuickActionsView(
                        isGuest: authService.isGuest,
                        onSettings: { showingSettings = true },
                        onAchievements: { showingAchievements = true },
                        onDataExport: { showingDataExport = true }
                    )
                    
                    // Recent Activity
                    if !authService.isGuest {
                        RecentActivityView(user: authService.currentUser)
                    }
                    
                    // Guest Mode Notice
                    if authService.isGuest {
                        GuestModeNoticeView()
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
        }
        .alert("Profile Update", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    let user: User?
    let isGuest: Bool
    let onEditProfile: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: URL(string: user?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.wweBlue, lineWidth: 3)
            )
            
            // User Info
            VStack(spacing: 4) {
                Text(user?.displayName ?? "Guest User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("@\(user?.username ?? "guest")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let bio = user?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                
                if isGuest {
                    Text("Guest Mode")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(12)
                }
            }
            
            // Edit Profile Button
            if !isGuest {
                Button(action: onEditProfile) {
                    Text("Edit Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.wweBlue)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Stats Overview
struct StatsOverviewView: View {
    let user: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Predictions",
                    value: "\(user?.predictionStats.totalPredictions ?? 0)",
                    subtitle: "Total Made"
                )
                
                StatCard(
                    title: "Accuracy",
                    value: "\(Int((user?.predictionStats.accuracy ?? 0) * 100))%",
                    subtitle: "Success Rate"
                )
                
                StatCard(
                    title: "Current Streak",
                    value: "\(user?.predictionStats.currentStreak ?? 0)",
                    subtitle: "In a Row"
                )
                
                StatCard(
                    title: "Rank",
                    value: "#\(user?.predictionStats.rank ?? 0)",
                    subtitle: "Global Position"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.wweBlue)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Quick Actions
struct QuickActionsView: View {
    let isGuest: Bool
    let onSettings: () -> Void
    let onAchievements: () -> Void
    let onDataExport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                QuickActionButton(
                    title: "Settings",
                    icon: "gearshape",
                    color: .gray,
                    action: onSettings
                )
                
                if !isGuest {
                    QuickActionButton(
                        title: "Achievements",
                        icon: "trophy",
                        color: .yellow,
                        action: onAchievements
                    )
                    
                    QuickActionButton(
                        title: "Export Data",
                        icon: "square.and.arrow.up",
                        color: .green,
                        action: onDataExport
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Recent Activity
struct RecentActivityView: View {
    let user: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActivityItem(
                    icon: "crystal.ball",
                    title: "Made a prediction",
                    subtitle: "WWE Championship match",
                    time: "2 hours ago"
                )
                
                ActivityItem(
                    icon: "heart",
                    title: "Liked a news article",
                    subtitle: "Breaking: Major WWE announcement",
                    time: "5 hours ago"
                )
                
                ActivityItem(
                    icon: "trophy",
                    title: "Earned a badge",
                    subtitle: "Prediction Master",
                    time: "1 day ago"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Activity Item
struct ActivityItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.wweBlue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Guest Mode Notice
struct GuestModeNoticeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Guest Mode")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("You're using WrestlePick in guest mode. Sign up to unlock all features including predictions, achievements, and data sync across devices.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Sign Up") {
                // This would trigger the authentication flow
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.wweBlue)
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ProfileView()
}
