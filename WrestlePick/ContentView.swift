import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .environmentObject(themeManager)
        .onAppear {
            // Check authentication status
            if authService.currentUser == nil && !authService.isAuthenticated {
                // User is not authenticated, show auth view
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        TabView {
            NewsView()
                .tabItem {
                    Image(systemName: "newspaper")
                    Text("News")
                }
            
            PredictionsView()
                .tabItem {
                    Image(systemName: "crystal.ball")
                    Text("Predictions")
                }
            
            AwardsView()
                .tabItem {
                    Image(systemName: "trophy")
                    Text("Awards")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .accentColor(.wweBlue)
    }
}

struct FeatureCard: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// NewsView is now implemented in its own file

struct PredictionsView: View {
    var body: some View {
        Text("Predictions View - Coming Soon")
            .navigationTitle("Predictions")
    }
}

struct CommunityView: View {
    var body: some View {
        Text("Community View - Coming Soon")
            .navigationTitle("Community")
    }
}

struct AwardsView: View {
    var body: some View {
        Text("Awards View - Coming Soon")
            .navigationTitle("Awards")
    }
}

#Preview {
    ContentView()
}
