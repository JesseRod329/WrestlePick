import SwiftUI

struct MerchLeaderboardView: View {
    @StateObject private var merchService = MerchService.shared
    @State private var selectedCategory: MerchCategory? = nil
    @State private var selectedPromotion: String? = nil
    @State private var selectedTimeRange: TimeRange = .allTime
    @State private var isLoading = false
    @State private var showingFilters = false
    
    var filteredLeaderboard: [MerchLeaderboardEntry] {
        var filtered = merchService.leaderboard
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let promotion = selectedPromotion {
            filtered = filtered.filter { $0.promotion == promotion }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                HeaderView(
                    totalItems: merchService.merchItems.count,
                    totalReports: merchService.userReports.count
                )
                .padding()
                
                // Filters
                FilterBar(
                    selectedCategory: $selectedCategory,
                    selectedPromotion: $selectedPromotion,
                    onShowFilters: { showingFilters = true }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Content
                if isLoading {
                    LoadingView()
                } else if filteredLeaderboard.isEmpty {
                    EmptyStateView()
                } else {
                    LeaderboardList(entries: filteredLeaderboard)
                }
            }
            .navigationTitle("Merch Leaderboard")
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
            .sheet(isPresented: $showingFilters) {
                LeaderboardFiltersView(
                    selectedCategory: $selectedCategory,
                    selectedPromotion: $selectedPromotion,
                    selectedTimeRange: $selectedTimeRange
                )
            }
        }
    }
    
    private func loadLeaderboard() {
        isLoading = true
        
        merchService.fetchLeaderboard(
            category: selectedCategory,
            promotion: selectedPromotion,
            limit: 100
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let entries):
                    // Update the service's leaderboard
                    merchService.leaderboard = entries
                case .failure(let error):
                    print("Error loading leaderboard: \(error)")
                }
            }
        }
    }
}

// MARK: - Time Range
enum TimeRange: String, CaseIterable {
    case allTime = "allTime"
    case lastWeek = "lastWeek"
    case lastMonth = "lastMonth"
    case lastYear = "lastYear"
    
    var displayName: String {
        switch self {
        case .allTime: return "All Time"
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .lastYear: return "Last Year"
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let totalItems: Int
    let totalReports: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(totalItems) Items")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(totalReports)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.wweBlue)
                
                Text("User Reports")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Filter Bar
struct FilterBar: View {
    @Binding var selectedCategory: MerchCategory?
    @Binding var selectedPromotion: String?
    let onShowFilters: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Category filter
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(MerchCategory?.none)
                    ForEach(MerchCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(MerchCategory?.some(category))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Promotion filter
                Picker("Promotion", selection: $selectedPromotion) {
                    Text("All Promotions").tag(String?.none)
                    ForEach(uniquePromotions, id: \.self) { promotion in
                        Text(promotion).tag(String?.some(promotion))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // More filters button
                Button(action: onShowFilters) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("More")
                    }
                    .font(.caption)
                    .foregroundColor(.wweBlue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.wweBlue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
    
    private var uniquePromotions: [String] {
        return ["WWE", "AEW", "NJPW", "Impact", "Independent"]
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

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Items Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try adjusting your filters or check back later")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Leaderboard List
struct LeaderboardList: View {
    let entries: [MerchLeaderboardEntry]
    
    var body: some View {
        List {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(
                    entry: entry,
                    rank: index + 1
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
    let entry: MerchLeaderboardEntry
    let rank: Int
    
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
            
            // Item image
            AsyncImage(url: URL(string: entry.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: entry.category.iconName)
                    .foregroundColor(.gray)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            
            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.itemName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack {
                    Text(entry.wrestler)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(entry.promotion)
                        .font(.subheadline)
                        .foregroundColor(.wweBlue)
                }
                
                HStack {
                    CategoryBadge(category: entry.category)
                    
                    TrendBadge(trend: entry.trend)
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("$\(String(format: "%.2f", entry.currentPrice))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.wweBlue)
                }
                
                HStack(spacing: 8) {
                    StatItem(
                        title: "Score",
                        value: "\(Int(entry.popularityScore))",
                        color: .green
                    )
                    
                    StatItem(
                        title: "Velocity",
                        value: "\(String(format: "%.1f", entry.velocity))",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
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
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let category: MerchCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.iconName)
                .font(.caption)
            
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(categoryColor)
        .cornerRadius(4)
    }
    
    private var categoryColor: Color {
        switch category {
        case .tshirt: return .blue
        case .hoodie: return .purple
        case .hat: return .orange
        case .poster: return .red
        case .actionFigure: return .green
        case .autograph: return .yellow
        case .championship: return .yellow
        case .accessory: return .gray
        case .collectible: return .pink
        case .digital: return .cyan
        case .custom: return .brown
        }
    }
}

// MARK: - Trend Badge
struct TrendBadge: View {
    let trend: TrendDirection
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.iconName)
                .font(.caption2)
            
            Text(trend.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendColor)
        .cornerRadius(4)
    }
    
    private var trendColor: Color {
        switch trend {
        case .rising: return .green
        case .falling: return .red
        case .stable: return .gray
        case .volatile: return .orange
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
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Leaderboard Filters View
struct LeaderboardFiltersView: View {
    @Binding var selectedCategory: MerchCategory?
    @Binding var selectedPromotion: String?
    @Binding var selectedTimeRange: TimeRange
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(MerchCategory?.none)
                        ForEach(MerchCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(MerchCategory?.some(category))
                        }
                    }
                }
                
                Section("Promotion") {
                    Picker("Promotion", selection: $selectedPromotion) {
                        Text("All Promotions").tag(String?.none)
                        ForEach(uniquePromotions, id: \.self) { promotion in
                            Text(promotion).tag(String?.some(promotion))
                        }
                    }
                }
                
                Section("Time Range") {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
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
    
    private var uniquePromotions: [String] {
        return ["WWE", "AEW", "NJPW", "Impact", "Independent"]
    }
}

#Preview {
    MerchLeaderboardView()
}
