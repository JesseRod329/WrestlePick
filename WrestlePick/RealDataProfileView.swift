import SwiftUI

struct RealDataProfileView: View {
    @State private var user = User(
        id: "1",
        username: "WrestleFan123",
        email: "fan@example.com",
        displayName: "Wrestle Fan",
        joinDate: Date().addingTimeInterval(-86400 * 30),
        totalPredictions: 25,
        correctPredictions: 18,
        totalPoints: 1250
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(user.displayName.prefix(1))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text(user.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Member since \(user.joinDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Statistics")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Total Predictions",
                                value: "\(user.totalPredictions)",
                                icon: "crystal.ball"
                            )
                            
                            StatCard(
                                title: "Correct Predictions",
                                value: "\(user.correctPredictions)",
                                icon: "checkmark.circle"
                            )
                            
                            StatCard(
                                title: "Accuracy Rate",
                                value: "\(Int((Double(user.correctPredictions) / Double(user.totalPredictions)) * 100))%",
                                icon: "target"
                            )
                            
                            StatCard(
                                title: "Total Points",
                                value: "\(user.totalPoints)",
                                icon: "star"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ActivityRow(
                                icon: "crystal.ball.fill",
                                title: "Made a prediction",
                                subtitle: "Championship Match Winner",
                                time: "2 hours ago"
                            )
                            
                            ActivityRow(
                                icon: "checkmark.circle.fill",
                                title: "Prediction was correct",
                                subtitle: "Tag Team Championship",
                                time: "1 day ago"
                            )
                            
                            ActivityRow(
                                icon: "newspaper.fill",
                                title: "Read news article",
                                subtitle: "Breaking: Major Announcement",
                                time: "2 days ago"
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
}

struct User {
    let id: String
    let username: String
    let email: String
    let displayName: String
    let joinDate: Date
    let totalPredictions: Int
    let correctPredictions: Int
    let totalPoints: Int
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
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

#Preview {
    RealDataProfileView()
}