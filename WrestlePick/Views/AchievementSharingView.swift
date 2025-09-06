import SwiftUI

struct AchievementSharingView: View {
    @StateObject private var socialService = SocialService.shared
    @State private var achievements: [Achievement] = []
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var selectedRarity: AchievementRarity? = nil
    @State private var isLoading = false
    @State private var showingCreateAward = false
    @State private var selectedAchievement: Achievement?
    
    var filteredAchievements: [Achievement] {
        var filtered = achievements
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let rarity = selectedRarity {
            filtered = filtered.filter { $0.rarity == rarity }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                HeaderView(
                    totalAchievements: achievements.count,
                    unlockedAchievements: achievements.filter { $0.isUnlocked }.count,
                    totalPoints: achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.points }
                )
                .padding()
                
                // Filters
                FilterBar(
                    selectedCategory: $selectedCategory,
                    selectedRarity: $selectedRarity
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Content
                if isLoading {
                    LoadingView()
                } else if filteredAchievements.isEmpty {
                    EmptyStateView()
                } else {
                    AchievementsGrid(achievements: filteredAchievements)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateAward = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadAchievements()
            }
            .sheet(isPresented: $showingCreateAward) {
                CreateAwardView()
            }
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailView(achievement: achievement)
            }
        }
    }
    
    private func loadAchievements() {
        isLoading = true
        // TODO: Load achievements from service
        achievements = [
            Achievement(
                name: "Prediction Master",
                description: "Make 100 correct predictions",
                iconName: "crystal.ball.fill",
                category: .prediction,
                rarity: .legendary,
                points: 1000,
                isUnlocked: true,
                unlockedAt: Date(),
                progress: 1.0
            ),
            Achievement(
                name: "Social Butterfly",
                description: "Get 500 likes on your posts",
                iconName: "heart.fill",
                category: .social,
                rarity: .epic,
                points: 500,
                isUnlocked: true,
                unlockedAt: Date(),
                progress: 1.0
            ),
            Achievement(
                name: "League Champion",
                description: "Win a league competition",
                iconName: "trophy.fill",
                category: .league,
                rarity: .rare,
                points: 250,
                isUnlocked: false,
                progress: 0.6
            ),
            Achievement(
                name: "Community Helper",
                description: "Help 50 users with their questions",
                iconName: "hand.raised.fill",
                category: .community,
                rarity: .uncommon,
                points: 100,
                isUnlocked: true,
                unlockedAt: Date(),
                progress: 1.0
            )
        ]
        isLoading = false
    }
}

// MARK: - Header View
struct HeaderView: View {
    let totalAchievements: Int
    let unlockedAchievements: Int
    let totalPoints: Int
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Total",
                value: "\(totalAchievements)",
                color: .blue
            )
            
            StatCard(
                title: "Unlocked",
                value: "\(unlockedAchievements)",
                color: .green
            )
            
            StatCard(
                title: "Points",
                value: "\(totalPoints)",
                color: .orange
            )
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Filter Bar
struct FilterBar: View {
    @Binding var selectedCategory: AchievementCategory?
    @Binding var selectedRarity: AchievementRarity?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Category filter
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(AchievementCategory?.none)
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(AchievementCategory?.some(category))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Rarity filter
                Picker("Rarity", selection: $selectedRarity) {
                    Text("All Rarities").tag(AchievementRarity?.none)
                    ForEach(AchievementRarity.allCases, id: \.self) { rarity in
                        Text(rarity.rawValue.capitalized).tag(AchievementRarity?.some(rarity))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading achievements...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Achievements")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Start using the app to unlock achievements!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Achievements Grid
struct AchievementsGrid: View {
    let achievements: [Achievement]
    @State private var selectedAchievement: Achievement?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        onTap: {
                            selectedAchievement = achievement
                        }
                    )
                }
            }
            .padding()
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement)
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? rarityColor : Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.iconName)
                        .font(.title2)
                        .foregroundColor(achievement.isUnlocked ? .white : .gray)
                }
                
                // Info
                VStack(spacing: 4) {
                    Text(achievement.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    
                    // Rarity badge
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(rarityColor)
                        
                        Text(achievement.rarity.rawValue.capitalized)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(rarityColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(rarityColor.opacity(0.2))
                    .cornerRadius(8)
                    
                    // Progress bar
                    if !achievement.isUnlocked {
                        VStack(spacing: 4) {
                            ProgressView(value: achievement.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: rarityColor))
                            
                            Text("\(Int(achievement.progress * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Points
                    Text("\(achievement.points) pts")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.wweBlue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Achievement Detail View
struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Achievement icon
                    ZStack {
                        Circle()
                            .fill(achievement.isUnlocked ? rarityColor : Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: achievement.iconName)
                            .font(.system(size: 50))
                            .foregroundColor(achievement.isUnlocked ? .white : .gray)
                    }
                    
                    // Achievement info
                    VStack(spacing: 12) {
                        Text(achievement.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(achievement.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Rarity and points
                        HStack(spacing: 16) {
                            RarityBadge(rarity: achievement.rarity)
                            
                            PointsBadge(points: achievement.points)
                        }
                    }
                    
                    // Progress section
                    if !achievement.isUnlocked {
                        VStack(spacing: 12) {
                            Text("Progress")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 8) {
                                ProgressView(value: achievement.progress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: rarityColor))
                                    .scaleEffect(1.2)
                                
                                Text("\(Int(achievement.progress * 100))% Complete")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Unlock info
                    if achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
                        VStack(spacing: 8) {
                            Text("Unlocked")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Share button
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Achievement")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.wweBlue)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [shareText, shareImage])
            }
        }
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    private var shareText: String {
        if achievement.isUnlocked {
            return "I just unlocked the '\(achievement.name)' achievement in WrestlePick! 🏆"
        } else {
            return "Check out this achievement I'm working towards: '\(achievement.name)' in WrestlePick! 🏆"
        }
    }
    
    private var shareImage: UIImage {
        // TODO: Generate achievement image
        return UIImage()
    }
}

// MARK: - Rarity Badge
struct RarityBadge: View {
    let rarity: AchievementRarity
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
            
            Text(rarity.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(rarityColor)
        .cornerRadius(8)
    }
    
    private var rarityColor: Color {
        switch rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Points Badge
struct PointsBadge: View {
    let points: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.circle.fill")
                .font(.caption)
            
            Text("\(points) pts")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.wweBlue)
        .cornerRadius(8)
    }
}

// MARK: - Create Award View
struct CreateAwardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socialService = SocialService.shared
    
    @State private var name = ""
    @State private var description = ""
    @State private var category: AwardCategory = .custom
    @State private var criteria: [String] = []
    @State private var newCriterion = ""
    @State private var votingEndsAt = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    @State private var isPublic = true
    @State private var isCreating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Award Information") {
                    TextField("Award Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $category) {
                        ForEach(AwardCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section("Criteria") {
                    ForEach(Array(criteria.enumerated()), id: \.offset) { index, criterion in
                        HStack {
                            Text(criterion)
                            Spacer()
                            Button("Remove") {
                                criteria.remove(at: index)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add criterion", text: $newCriterion)
                        Button("Add") {
                            if !newCriterion.isEmpty {
                                criteria.append(newCriterion)
                                newCriterion = ""
                            }
                        }
                        .disabled(newCriterion.isEmpty)
                    }
                }
                
                Section("Settings") {
                    DatePicker("Voting Ends", selection: $votingEndsAt, in: Date()...)
                    Toggle("Public Award", isOn: $isPublic)
                }
            }
            .navigationTitle("Create Award")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createAward()
                    }
                    .disabled(name.isEmpty || description.isEmpty || isCreating)
                }
            }
            .alert("Award Creation", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func createAward() {
        isCreating = true
        
        let award = UserAward(
            creatorId: "current_user", // TODO: Get from auth service
            creatorUsername: "current_user",
            name: name,
            description: description,
            category: category,
            criteria: criteria,
            votingEndsAt: votingEndsAt,
            isPublic: isPublic
        )
        
        socialService.createUserAward(award) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success:
                    alertMessage = "Award created successfully!"
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                case .failure(let error):
                    alertMessage = "Failed to create award: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AchievementSharingView()
}
