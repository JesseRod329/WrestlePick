import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var selectedCategory: AnalyticsCategory = .overview
    @State private var analytics: AnalyticsData?
    @State private var isLoading = false
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with filters
                HeaderView(
                    selectedTimeRange: $selectedTimeRange,
                    selectedCategory: $selectedCategory
                )
                
                // Content
                if isLoading {
                    LoadingView()
                } else if subscriptionService.isSubscribed {
                    AnalyticsContentView(
                        analytics: analytics,
                        selectedTimeRange: selectedTimeRange,
                        selectedCategory: selectedCategory
                    )
                } else {
                    PremiumRequiredView(
                        onUpgrade: {
                            showingPaywall = true
                        }
                    )
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadAnalytics()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
    
    private func loadAnalytics() {
        isLoading = true
        
        // TODO: Load analytics data
        analytics = AnalyticsData(
            overview: OverviewAnalytics(
                totalPredictions: 156,
                correctPredictions: 98,
                accuracy: 0.628,
                streak: 12,
                rank: 45,
                points: 1250
            ),
            predictions: PredictionAnalytics(
                totalPredictions: 156,
                correctPredictions: 98,
                accuracy: 0.628,
                averageConfidence: 7.2,
                bestCategory: "PPV Matches",
                worstCategory: "Storylines"
            ),
            social: SocialAnalytics(
                postsCount: 23,
                likesReceived: 456,
                commentsReceived: 89,
                sharesReceived: 34,
                followersCount: 156,
                followingCount: 89
            ),
            revenue: RevenueAnalytics(
                totalRevenue: 0.0,
                subscriptionRevenue: 0.0,
                affiliateRevenue: 0.0,
                sponsoredRevenue: 0.0,
                tournamentRevenue: 0.0,
                customLeagueRevenue: 0.0,
                monthlyRevenue: 0.0,
                yearlyRevenue: 0.0
            )
        )
        
        isLoading = false
    }
}

// MARK: - Time Range
enum TimeRange: String, CaseIterable {
    case last7Days = "last7Days"
    case last30Days = "last30Days"
    case last90Days = "last90Days"
    case lastYear = "lastYear"
    case allTime = "allTime"
    
    var displayName: String {
        switch self {
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        case .lastYear: return "Last Year"
        case .allTime: return "All Time"
        }
    }
}

// MARK: - Analytics Category
enum AnalyticsCategory: String, CaseIterable {
    case overview = "overview"
    case predictions = "predictions"
    case social = "social"
    case revenue = "revenue"
    
    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .predictions: return "Predictions"
        case .social: return "Social"
        case .revenue: return "Revenue"
        }
    }
    
    var iconName: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .predictions: return "crystal.ball.fill"
        case .social: return "person.2.fill"
        case .revenue: return "dollarsign.circle.fill"
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var selectedTimeRange: TimeRange
    @Binding var selectedCategory: AnalyticsCategory
    
    var body: some View {
        VStack(spacing: 16) {
            // Time range picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Category picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(AnalyticsCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading analytics...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Premium Required View
struct PremiumRequiredView: View {
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Premium Feature")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Advanced analytics are available with Premium. Get detailed insights about your predictions and performance.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onUpgrade) {
                Text("Upgrade to Premium")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.wweBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Analytics Content View
struct AnalyticsContentView: View {
    let analytics: AnalyticsData?
    let selectedTimeRange: TimeRange
    let selectedCategory: AnalyticsCategory
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let analytics = analytics {
                    switch selectedCategory {
                    case .overview:
                        OverviewAnalyticsView(analytics: analytics.overview)
                    case .predictions:
                        PredictionAnalyticsView(analytics: analytics.predictions)
                    case .social:
                        SocialAnalyticsView(analytics: analytics.social)
                    case .revenue:
                        RevenueAnalyticsView(analytics: analytics.revenue)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Analytics Data
struct AnalyticsData {
    let overview: OverviewAnalytics
    let predictions: PredictionAnalytics
    let social: SocialAnalytics
    let revenue: RevenueAnalytics
}

// MARK: - Overview Analytics
struct OverviewAnalytics {
    let totalPredictions: Int
    let correctPredictions: Int
    let accuracy: Double
    let streak: Int
    let rank: Int
    let points: Int
}

// MARK: - Overview Analytics View
struct OverviewAnalyticsView: View {
    let analytics: OverviewAnalytics
    
    var body: some View {
        VStack(spacing: 20) {
            // Key metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Total Predictions",
                    value: "\(analytics.totalPredictions)",
                    icon: "crystal.ball.fill",
                    color: .blue
                )
                
                MetricCard(
                    title: "Correct Predictions",
                    value: "\(analytics.correctPredictions)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Accuracy",
                    value: "\(Int(analytics.accuracy * 100))%",
                    icon: "target",
                    color: .orange
                )
                
                MetricCard(
                    title: "Current Streak",
                    value: "\(analytics.streak)",
                    icon: "flame.fill",
                    color: .red
                )
                
                MetricCard(
                    title: "Global Rank",
                    value: "#\(analytics.rank)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                MetricCard(
                    title: "Total Points",
                    value: "\(analytics.points)",
                    icon: "star.fill",
                    color: .purple
                )
            }
            
            // Accuracy chart
            if #available(iOS 16.0, *) {
                AccuracyChartView(analytics: analytics)
            }
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Accuracy Chart View
@available(iOS 16.0, *)
struct AccuracyChartView: View {
    let analytics: OverviewAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accuracy Trend")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Chart {
                BarMark(
                    x: .value("Week", "Week 1"),
                    y: .value("Accuracy", 65)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value("Week", "Week 2"),
                    y: .value("Accuracy", 72)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value("Week", "Week 3"),
                    y: .value("Accuracy", 58)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value("Week", "Week 4"),
                    y: .value("Accuracy", 68)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .percent)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Prediction Analytics
struct PredictionAnalytics {
    let totalPredictions: Int
    let correctPredictions: Int
    let accuracy: Double
    let averageConfidence: Double
    let bestCategory: String
    let worstCategory: String
}

// MARK: - Prediction Analytics View
struct PredictionAnalyticsView: View {
    let analytics: PredictionAnalytics
    
    var body: some View {
        VStack(spacing: 20) {
            // Key metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Total Predictions",
                    value: "\(analytics.totalPredictions)",
                    icon: "crystal.ball.fill",
                    color: .blue
                )
                
                MetricCard(
                    title: "Accuracy",
                    value: "\(Int(analytics.accuracy * 100))%",
                    icon: "target",
                    color: .green
                )
                
                MetricCard(
                    title: "Avg Confidence",
                    value: String(format: "%.1f", analytics.averageConfidence),
                    icon: "star.fill",
                    color: .orange
                )
                
                MetricCard(
                    title: "Best Category",
                    value: analytics.bestCategory,
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
            
            // Category breakdown
            VStack(alignment: .leading, spacing: 16) {
                Text("Category Performance")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    CategoryPerformanceRow(
                        category: "PPV Matches",
                        accuracy: 0.75,
                        predictions: 45
                    )
                    
                    CategoryPerformanceRow(
                        category: "Storylines",
                        accuracy: 0.45,
                        predictions: 23
                    )
                    
                    CategoryPerformanceRow(
                        category: "Championships",
                        accuracy: 0.68,
                        predictions: 34
                    )
                    
                    CategoryPerformanceRow(
                        category: "Returns",
                        accuracy: 0.82,
                        predictions: 12
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Category Performance Row
struct CategoryPerformanceRow: View {
    let category: String
    let accuracy: Double
    let predictions: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(predictions) predictions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(accuracy * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(accuracyColor)
                
                ProgressView(value: accuracy)
                    .progressViewStyle(LinearProgressViewStyle(tint: accuracyColor))
                    .frame(width: 80)
            }
        }
    }
    
    private var accuracyColor: Color {
        if accuracy >= 0.7 {
            return .green
        } else if accuracy >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Social Analytics
struct SocialAnalytics {
    let postsCount: Int
    let likesReceived: Int
    let commentsReceived: Int
    let sharesReceived: Int
    let followersCount: Int
    let followingCount: Int
}

// MARK: - Social Analytics View
struct SocialAnalyticsView: View {
    let analytics: SocialAnalytics
    
    var body: some View {
        VStack(spacing: 20) {
            // Key metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Posts",
                    value: "\(analytics.postsCount)",
                    icon: "square.and.pencil",
                    color: .blue
                )
                
                MetricCard(
                    title: "Likes Received",
                    value: "\(analytics.likesReceived)",
                    icon: "heart.fill",
                    color: .red
                )
                
                MetricCard(
                    title: "Comments",
                    value: "\(analytics.commentsReceived)",
                    icon: "bubble.left.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Shares",
                    value: "\(analytics.sharesReceived)",
                    icon: "square.and.arrow.up.fill",
                    color: .purple
                )
                
                MetricCard(
                    title: "Followers",
                    value: "\(analytics.followersCount)",
                    icon: "person.2.fill",
                    color: .orange
                )
                
                MetricCard(
                    title: "Following",
                    value: "\(analytics.followingCount)",
                    icon: "person.badge.plus",
                    color: .cyan
                )
            }
            
            // Engagement rate
            VStack(alignment: .leading, spacing: 16) {
                Text("Engagement Rate")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                let totalEngagement = analytics.likesReceived + analytics.commentsReceived + analytics.sharesReceived
                let engagementRate = analytics.postsCount > 0 ? Double(totalEngagement) / Double(analytics.postsCount) : 0.0
                
                HStack {
                    Text("\(String(format: "%.1f", engagementRate))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.wweBlue)
                    
                    Text("engagements per post")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Revenue Analytics View
struct RevenueAnalyticsView: View {
    let analytics: RevenueAnalytics
    
    var body: some View {
        VStack(spacing: 20) {
            // Key metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Total Revenue",
                    value: "$\(String(format: "%.2f", analytics.totalRevenue))",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Monthly Revenue",
                    value: "$\(String(format: "%.2f", analytics.monthlyRevenue))",
                    icon: "calendar",
                    color: .blue
                )
                
                MetricCard(
                    title: "Affiliate Revenue",
                    value: "$\(String(format: "%.2f", analytics.affiliateRevenue))",
                    icon: "link",
                    color: .orange
                )
                
                MetricCard(
                    title: "Sponsored Revenue",
                    value: "$\(String(format: "%.2f", analytics.sponsoredRevenue))",
                    icon: "megaphone.fill",
                    color: .purple
                )
            }
            
            // Revenue breakdown
            VStack(alignment: .leading, spacing: 16) {
                Text("Revenue Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    RevenueBreakdownRow(
                        source: "Subscriptions",
                        amount: analytics.subscriptionRevenue,
                        percentage: analytics.totalRevenue > 0 ? analytics.subscriptionRevenue / analytics.totalRevenue : 0
                    )
                    
                    RevenueBreakdownRow(
                        source: "Affiliate",
                        amount: analytics.affiliateRevenue,
                        percentage: analytics.totalRevenue > 0 ? analytics.affiliateRevenue / analytics.totalRevenue : 0
                    )
                    
                    RevenueBreakdownRow(
                        source: "Sponsored",
                        amount: analytics.sponsoredRevenue,
                        percentage: analytics.totalRevenue > 0 ? analytics.sponsoredRevenue / analytics.totalRevenue : 0
                    )
                    
                    RevenueBreakdownRow(
                        source: "Tournaments",
                        amount: analytics.tournamentRevenue,
                        percentage: analytics.totalRevenue > 0 ? analytics.tournamentRevenue / analytics.totalRevenue : 0
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Revenue Breakdown Row
struct RevenueBreakdownRow: View {
    let source: String
    let amount: Double
    let percentage: Double
    
    var body: some View {
        HStack {
            Text(source)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", amount))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(Int(percentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    AnalyticsView()
}
