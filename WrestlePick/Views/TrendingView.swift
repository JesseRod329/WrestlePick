import SwiftUI

struct TrendingView: View {
    @StateObject private var merchService = MerchService.shared
    @State private var trendingItems: [TrendingItem] = []
    @State private var selectedTimeRange: TrendingTimeRange = .today
    @State private var selectedPlatform: SocialPlatform? = nil
    @State private var isLoading = false
    @State private var showingFilters = false
    
    var filteredTrendingItems: [TrendingItem] {
        var filtered = trendingItems
        
        // Filter by time range
        let now = Date()
        let timeInterval = selectedTimeRange.timeInterval
        
        if timeInterval > 0 {
            let cutoffDate = now.addingTimeInterval(-timeInterval)
            // TODO: Filter by date when date field is added to TrendingItem
        }
        
        // Filter by platform
        if let platform = selectedPlatform {
            // TODO: Filter by platform when platform data is available
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                HeaderView(
                    totalItems: trendingItems.count,
                    totalMentions: trendingItems.reduce(0) { $0 + $1.socialMentions }
                )
                .padding()
                
                // Filters
                FilterBar(
                    selectedTimeRange: $selectedTimeRange,
                    selectedPlatform: $selectedPlatform,
                    onShowFilters: { showingFilters = true }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Content
                if isLoading {
                    LoadingView()
                } else if filteredTrendingItems.isEmpty {
                    EmptyStateView()
                } else {
                    TrendingList(items: filteredTrendingItems)
                }
            }
            .navigationTitle("Trending")
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
                loadTrendingItems()
            }
            .sheet(isPresented: $showingFilters) {
                TrendingFiltersView(
                    selectedTimeRange: $selectedTimeRange,
                    selectedPlatform: $selectedPlatform
                )
            }
        }
    }
    
    private func loadTrendingItems() {
        isLoading = true
        
        merchService.fetchTrendingItems { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let items):
                    trendingItems = items
                case .failure(let error):
                    print("Error loading trending items: \(error)")
                    trendingItems = []
                }
            }
        }
    }
}

// MARK: - Trending Time Range
enum TrendingTimeRange: String, CaseIterable {
    case today = "today"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case allTime = "allTime"
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .allTime: return "All Time"
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .today: return 86400 // 24 hours
        case .thisWeek: return 604800 // 7 days
        case .thisMonth: return 2592000 // 30 days
        case .allTime: return 0 // No filter
        }
    }
}

// MARK: - Social Platform
enum SocialPlatform: String, CaseIterable {
    case twitter = "twitter"
    case instagram = "instagram"
    case reddit = "reddit"
    case youtube = "youtube"
    case tiktok = "tiktok"
    
    var displayName: String {
        switch self {
        case .twitter: return "Twitter"
        case .instagram: return "Instagram"
        case .reddit: return "Reddit"
        case .youtube: return "YouTube"
        case .tiktok: return "TikTok"
        }
    }
    
    var iconName: String {
        switch self {
        case .twitter: return "bird"
        case .instagram: return "camera"
        case .reddit: return "globe"
        case .youtube: return "play.rectangle"
        case .tiktok: return "music.note"
        }
    }
    
    var color: Color {
        switch self {
        case .twitter: return .blue
        case .instagram: return .purple
        case .reddit: return .orange
        case .youtube: return .red
        case .tiktok: return .black
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let totalItems: Int
    let totalMentions: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(totalItems) Items")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Trending Now")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(totalMentions)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.wweBlue)
                
                Text("Social Mentions")
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
    @Binding var selectedTimeRange: TrendingTimeRange
    @Binding var selectedPlatform: SocialPlatform?
    let onShowFilters: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Time range filter
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TrendingTimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Platform filter
                Picker("Platform", selection: $selectedPlatform) {
                    Text("All Platforms").tag(SocialPlatform?.none)
                    ForEach(SocialPlatform.allCases, id: \.self) { platform in
                        Text(platform.displayName).tag(SocialPlatform?.some(platform))
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
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading trending items...")
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
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Trending Items")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Check back later for trending wrestling merchandise")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Trending List
struct TrendingList: View {
    let items: [TrendingItem]
    
    var body: some View {
        List {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                TrendingRow(
                    item: item,
                    rank: index + 1
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Trending Row
struct TrendingRow: View {
    let item: TrendingItem
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
            AsyncImage(url: URL(string: item.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: item.category.iconName)
                    .foregroundColor(.gray)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack {
                    Text(item.wrestler)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.promotion)
                        .font(.subheadline)
                        .foregroundColor(.wweBlue)
                }
                
                HStack {
                    CategoryBadge(category: item.category)
                    
                    TrendBadge(trendScore: item.trendScore)
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("$\(String(format: "%.2f", item.currentPrice))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.wweBlue)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .foregroundColor(.orange)
                        Text("\(Int(item.trendScore))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.blue)
                        Text("\(item.socialMentions)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.green)
                        Text("\(item.searchCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
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
    let trendScore: Double
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "arrow.up")
                .font(.caption2)
            
            Text("\(Int(trendScore))")
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
        if trendScore >= 80 {
            return .red
        } else if trendScore >= 60 {
            return .orange
        } else if trendScore >= 40 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Trending Filters View
struct TrendingFiltersView: View {
    @Binding var selectedTimeRange: TrendingTimeRange
    @Binding var selectedPlatform: SocialPlatform?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time Range") {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TrendingTimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                }
                
                Section("Social Platform") {
                    Picker("Platform", selection: $selectedPlatform) {
                        Text("All Platforms").tag(SocialPlatform?.none)
                        ForEach(SocialPlatform.allCases, id: \.self) { platform in
                            Text(platform.displayName).tag(SocialPlatform?.some(platform))
                        }
                    }
                }
                
                Section("Additional Filters") {
                    Toggle("High Velocity Only", isOn: .constant(false))
                    Toggle("Verified Items Only", isOn: .constant(false))
                    Toggle("In Stock Only", isOn: .constant(false))
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

// MARK: - Social Media Integration View
struct SocialMediaIntegrationView: View {
    let item: TrendingItem
    @State private var socialData: SocialMediaData?
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Media Buzz")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading social data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let data = socialData {
                VStack(spacing: 12) {
                    // Platform breakdown
                    ForEach(data.platforms, id: \.platform) { platformData in
                        SocialPlatformRow(data: platformData)
                    }
                    
                    // Hashtags
                    if !item.hashtags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trending Hashtags")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(item.hashtags, id: \.self) { hashtag in
                                        Text("#\(hashtag)")
                                            .font(.caption)
                                            .foregroundColor(.wweBlue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.wweBlue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            } else {
                Text("No social media data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            loadSocialData()
        }
    }
    
    private func loadSocialData() {
        isLoading = true
        
        // TODO: Load social media data from APIs
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            socialData = SocialMediaData(
                platforms: [
                    PlatformData(platform: .twitter, mentions: 45, engagement: 0.8),
                    PlatformData(platform: .instagram, mentions: 32, engagement: 0.9),
                    PlatformData(platform: .reddit, mentions: 18, engagement: 0.7),
                    PlatformData(platform: .youtube, mentions: 12, engagement: 0.6)
                ]
            )
            isLoading = false
        }
    }
}

// MARK: - Social Media Data
struct SocialMediaData {
    let platforms: [PlatformData]
}

struct PlatformData {
    let platform: SocialPlatform
    let mentions: Int
    let engagement: Double
}

// MARK: - Social Platform Row
struct SocialPlatformRow: View {
    let data: PlatformData
    
    var body: some View {
        HStack {
            Image(systemName: data.platform.iconName)
                .foregroundColor(data.platform.color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(data.platform.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(data.mentions) mentions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(data.engagement * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(data.platform.color)
                
                Text("Engagement")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    TrendingView()
}
