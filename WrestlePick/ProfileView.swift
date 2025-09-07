import SwiftUI

struct ProfileView: View {
    @State private var user = User.sample
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentColor)
                            )
                        
                        VStack(spacing: 4) {
                            Text(user.username)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(user.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Edit Profile") {
                            showingEditProfile = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Stats")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Predictions Made",
                                value: "\(user.predictionStats.totalPredictions)",
                                icon: "crystal.ball"
                            )
                            
                            StatCard(
                                title: "Accuracy Rate",
                                value: "\(Int(user.predictionStats.accuracy * 100))%",
                                icon: "target"
                            )
                            
                            StatCard(
                                title: "Points",
                                value: "\(user.predictionStats.points)",
                                icon: "trophy"
                            )
                            
                            StatCard(
                                title: "Streak",
                                value: "\(user.predictionStats.currentStreak) days",
                                icon: "flame"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            // Mock recent activity for now
                            ActivityRow(
                                activity: Activity(
                                    id: "1",
                                    type: .prediction,
                                    title: "Made prediction for Roman vs Cody",
                                    timestamp: Date().addingTimeInterval(-3600)
                                )
                            )
                            ActivityRow(
                                activity: Activity(
                                    id: "2",
                                    type: .award,
                                    title: "Created 'Match of the Year' award",
                                    timestamp: Date().addingTimeInterval(-7200)
                                )
                            )
                            ActivityRow(
                                activity: Activity(
                                    id: "3",
                                    type: .news,
                                    title: "Read breaking news about CM Punk",
                                    timestamp: Date().addingTimeInterval(-10800)
                                )
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(user: $user)
            }
        }
    }
}

// MARK: - Supporting Models

struct Activity: Identifiable {
    let id: String
    let type: ActivityType
    let title: String
    let timestamp: Date
}

enum ActivityType {
    case prediction
    case award
    case news
    case achievement
}

// MARK: - Supporting Views


struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForActivity(activity.type))
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func iconForActivity(_ type: ActivityType) -> String {
        switch type {
        case .prediction:
            return "crystal.ball"
        case .award:
            return "trophy"
        case .news:
            return "newspaper"
        case .achievement:
            return "star"
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var user: User
    
    @State private var username: String
    @State private var displayName: String
    
    init(user: Binding<User>) {
        self._user = user
        self._username = State(initialValue: user.wrappedValue.username)
        self._displayName = State(initialValue: user.wrappedValue.displayName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    TextField("Username", text: $username)
                    TextField("Display Name", text: $displayName)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Update user with new values
                        user = User(
                            username: username,
                            email: user.email,
                            displayName: displayName,
                            profileImageURL: user.profileImageURL
                        )
                        dismiss()
                    }
                    .disabled(username.isEmpty || displayName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}