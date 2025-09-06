import SwiftUI

struct LeaderboardView: View {
    @StateObject private var predictionService = PredictionService.shared
    @State private var selectedPeriod: LeaderboardPeriod = .weekly
    @State private var selectedCategory: PredictionType? = nil
    @State private var isLoading = false
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Period selector
                PeriodSelector(selectedPeriod: $selectedPeriod)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Category filter
                CategoryFilter(selectedCategory: $selectedCategory)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Leaderboard content
                if isLoading {
                    LoadingView()
                } else if leaderboardEntries.isEmpty {
                    EmptyLeaderboardView()
                } else {
                    LeaderboardList(entries: leaderboardEntries)
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilters = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onAppear {
                loadLeaderboard()
            }
            .onChange(of: selectedPeriod) { _ in
                loadLeaderboard()
            }
            .onChange(of: selectedCategory) { _ in
                loadLeaderboard()
            }
            .sheet(isPresented: $showingFilters) {
                LeaderboardFiltersView(
                    selectedPeriod: $selectedPeriod,
                    selectedCategory: $selectedCategory
                )
            }
        }
    }
    
    private func loadLeaderboard() {
        isLoading = true
        
        predictionService.fetchLeaderboard(
            period: selectedPeriod,
            category: selectedCategory
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let entries):
                    leaderboardEntries = entries
                case .failure(let error):
                    print("Error loading leaderboard: \(error)")
                    leaderboardEntries = []
                }
            }
        }
    }
}

// MARK: - Period Selector
struct PeriodSelector: View {
    @Binding var selectedPeriod: LeaderboardPeriod
    
    var body: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

// MARK: - Category Filter
struct CategoryFilter: View {
    @Binding var selectedCategory: PredictionType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button(action: {
                    selectedCategory = nil
                }) {
                    Text("All")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == nil ? Color.wweBlue : Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                ForEach(PredictionType.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: category.iconName)
                                .font(.caption)
                            Text(category.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == category ? Color.wweBlue : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Leaderboard List
struct LeaderboardList: View {
    let entries: [LeaderboardEntry]
    
    var body: some View {
        List {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(
                    entry: entry,
                    rank: index + 1,
                    isCurrentUser: false // TODO: Check if current user
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            VStack {
                Text("\(rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor)
                
                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.caption)
                        .foregroundColor(rankColor)
                }
            }
            .frame(width: 40)
            
            // Profile image
            AsyncImage(url: URL(string: entry.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(isCurrentUser ? Color.wweBlue : Color.clear, lineWidth: 2)
            )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if isCurrentUser {
                        Text("You")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.wweBlue)
                            .cornerRadius(4)
                    }
                }
                
                Text("@\(entry.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 16) {
                    StatItem(
                        title: "Points",
                        value: "\(entry.points)",
                        color: .wweBlue
                    )
                    
                    StatItem(
                        title: "Accuracy",
                        value: "\(Int(entry.accuracy * 100))%",
                        color: accuracyColor
                    )
                }
                
                HStack(spacing: 16) {
                    StatItem(
                        title: "Predictions",
                        value: "\(entry.totalPredictions)",
                        color: .secondary
                    )
                    
                    StatItem(
                        title: "Streak",
                        value: "\(entry.currentStreak)",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(isCurrentUser ? Color.wweBlue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "trophy.fill"
        default: return ""
        }
    }
    
    private var accuracyColor: Color {
        if entry.accuracy >= 0.8 {
            return .green
        } else if entry.accuracy >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading leaderboard...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Leaderboard View
struct EmptyLeaderboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Leaderboard Data")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Be the first to make predictions and climb the leaderboard!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Leaderboard Filters View
struct LeaderboardFiltersView: View {
    @Binding var selectedPeriod: LeaderboardPeriod
    @Binding var selectedCategory: PredictionType?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time Period") {
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                }
                
                Section("Prediction Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(PredictionType?.none)
                        ForEach(PredictionType.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(PredictionType?.some(category))
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Prediction Service Extension
extension PredictionService {
    func fetchLeaderboard(
        period: LeaderboardPeriod,
        category: PredictionType?,
        completion: @escaping (Result<[LeaderboardEntry], Error>) -> Void
    ) {
        // TODO: Implement actual leaderboard fetching from Firestore
        // For now, return mock data
        let mockEntries = [
            LeaderboardEntry(
                userId: "user1",
                username: "wrestlingfan1",
                displayName: "Wrestling Fan 1",
                profileImageURL: nil,
                rank: 1,
                points: 1250,
                accuracy: 0.85,
                totalPredictions: 50,
                correctPredictions: 43,
                currentStreak: 8,
                longestStreak: 12,
                period: period
            ),
            LeaderboardEntry(
                userId: "user2",
                username: "predictionmaster",
                displayName: "Prediction Master",
                profileImageURL: nil,
                rank: 2,
                points: 1180,
                accuracy: 0.82,
                totalPredictions: 45,
                correctPredictions: 37,
                currentStreak: 5,
                longestStreak: 10,
                period: period
            ),
            LeaderboardEntry(
                userId: "user3",
                username: "wrestlingexpert",
                displayName: "Wrestling Expert",
                profileImageURL: nil,
                rank: 3,
                points: 1100,
                accuracy: 0.78,
                totalPredictions: 40,
                correctPredictions: 31,
                currentStreak: 3,
                longestStreak: 8,
                period: period
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(mockEntries))
        }
    }
}

#Preview {
    LeaderboardView()
}
