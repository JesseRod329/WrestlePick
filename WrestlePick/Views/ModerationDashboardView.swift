import SwiftUI

struct ModerationDashboardView: View {
    @StateObject private var socialService = SocialService.shared
    @State private var selectedTab: ModerationTab = .reports
    @State private var selectedReport: ModerationReport?
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                HeaderView(
                    totalReports: socialService.moderationReports.count,
                    pendingReports: socialService.moderationReports.filter { $0.status == .pending }.count,
                    resolvedReports: socialService.moderationReports.filter { $0.status == .resolved }.count
                )
                .padding()
                
                // Tab selector
                Picker("Moderation Tab", selection: $selectedTab) {
                    ForEach(ModerationTab.allCases, id: \.self) { tab in
                        Text(tab.displayName).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content
                if isLoading {
                    LoadingView()
                } else {
                    TabContentView(
                        selectedTab: selectedTab,
                        reports: socialService.moderationReports,
                        onReportSelected: { report in
                            selectedReport = report
                        }
                    )
                }
            }
            .navigationTitle("Moderation")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadModerationData()
            }
            .sheet(item: $selectedReport) { report in
                ReportDetailView(report: report)
            }
            .alert("Moderation", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadModerationData() {
        isLoading = true
        socialService.loadModerationReports()
        isLoading = false
    }
}

// MARK: - Moderation Tab
enum ModerationTab: String, CaseIterable {
    case reports = "reports"
    case content = "content"
    case users = "users"
    case analytics = "analytics"
    
    var displayName: String {
        switch self {
        case .reports: return "Reports"
        case .content: return "Content"
        case .users: return "Users"
        case .analytics: return "Analytics"
        }
    }
    
    var iconName: String {
        switch self {
        case .reports: return "exclamationmark.triangle"
        case .content: return "doc.text"
        case .users: return "person.2"
        case .analytics: return "chart.bar"
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let totalReports: Int
    let pendingReports: Int
    let resolvedReports: Int
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Total Reports",
                value: "\(totalReports)",
                color: .blue
            )
            
            StatCard(
                title: "Pending",
                value: "\(pendingReports)",
                color: .orange
            )
            
            StatCard(
                title: "Resolved",
                value: "\(resolvedReports)",
                color: .green
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

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading moderation data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab Content View
struct TabContentView: View {
    let selectedTab: ModerationTab
    let reports: [ModerationReport]
    let onReportSelected: (ModerationReport) -> Void
    
    var body: some View {
        switch selectedTab {
        case .reports:
            ReportsView(
                reports: reports,
                onReportSelected: onReportSelected
            )
        case .content:
            ContentModerationView()
        case .users:
            UserModerationView()
        case .analytics:
            ModerationAnalyticsView()
        }
    }
}

// MARK: - Reports View
struct ReportsView: View {
    let reports: [ModerationReport]
    let onReportSelected: (ModerationReport) -> Void
    
    var body: some View {
        if reports.isEmpty {
            EmptyReportsView()
        } else {
            List {
                ForEach(reports) { report in
                    ReportCard(
                        report: report,
                        onTap: {
                            onReportSelected(report)
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - Empty Reports View
struct EmptyReportsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("No Reports")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Great! No moderation reports to review at the moment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Report Card
struct ReportCard: View {
    let report: ModerationReport
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.reason.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(report.contentType.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: report.status)
                }
                
                // Description
                if !report.description.isEmpty {
                    Text(report.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Footer
                HStack {
                    Text("Reported \(report.createdAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let moderatorId = report.moderatorId {
                        Text("Assigned to moderator")
                            .font(.caption)
                            .foregroundColor(.wweBlue)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ReportStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption)
            
            Text(status.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor)
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch status {
        case .pending: return "clock"
        case .underReview: return "eye"
        case .resolved: return "checkmark"
        case .dismissed: return "xmark"
        case .escalated: return "exclamationmark.triangle"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .yellow
        case .underReview: return .blue
        case .resolved: return .green
        case .dismissed: return .gray
        case .escalated: return .red
        }
    }
}

// MARK: - Report Detail View
struct ReportDetailView: View {
    let report: ModerationReport
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socialService = SocialService.shared
    
    @State private var moderatorNotes = ""
    @State private var selectedAction: ModerationAction = .approve
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Report info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Report Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        InfoRow(title: "Reason", value: report.reason.displayName)
                        InfoRow(title: "Content Type", value: report.contentType.displayName)
                        InfoRow(title: "Reported By", value: report.reporterId)
                        InfoRow(title: "Reported User", value: report.reportedUserId)
                        InfoRow(title: "Content ID", value: report.reportedContentId)
                        InfoRow(title: "Reported At", value: report.createdAt.formatted())
                        
                        if let resolvedAt = report.resolvedAt {
                            InfoRow(title: "Resolved At", value: resolvedAt.formatted())
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(report.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Moderator notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Moderator Notes")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Add notes...", text: $moderatorNotes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Action selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Action")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Action", selection: $selectedAction) {
                            ForEach(ModerationAction.allCases, id: \.self) { action in
                                Text(action.rawValue.capitalized).tag(action)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Process button
                    Button(action: processReport) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Process Report")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedAction == .approve ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                }
                .padding()
            }
            .navigationTitle("Report Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Moderation", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func processReport() {
        isProcessing = true
        
        socialService.moderateContent(
            report.reportedContentId,
            action: selectedAction,
            moderatorId: "current_moderator", // TODO: Get from auth service
            notes: moderatorNotes.isEmpty ? nil : moderatorNotes
        ) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success:
                    alertMessage = "Report processed successfully!"
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                case .failure(let error):
                    alertMessage = "Failed to process report: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Content Moderation View
struct ContentModerationView: View {
    @State private var contentItems: [ContentItem] = []
    @State private var isLoading = false
    @State private var selectedFilter: ContentFilter = .all
    
    var body: some View {
        VStack(spacing: 16) {
            // Filter selector
            Picker("Content Filter", selection: $selectedFilter) {
                ForEach(ContentFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Content list
            if isLoading {
                LoadingView()
            } else if contentItems.isEmpty {
                EmptyContentView()
            } else {
                List {
                    ForEach(contentItems) { item in
                        ContentItemRow(item: item)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            loadContentItems()
        }
    }
    
    private func loadContentItems() {
        isLoading = true
        // TODO: Load content items for moderation
        contentItems = []
        isLoading = false
    }
}

// MARK: - Content Filter
enum ContentFilter: String, CaseIterable {
    case all = "all"
    case pending = "pending"
    case flagged = "flagged"
    case underReview = "underReview"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .flagged: return "Flagged"
        case .underReview: return "Under Review"
        }
    }
}

// MARK: - Content Item
struct ContentItem: Identifiable {
    let id: String
    let type: ContentType
    let content: String
    let author: String
    let status: ModerationStatus
    let createdAt: Date
}

// MARK: - Content Item Row
struct ContentItemRow: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.type.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                StatusBadge(status: item.status)
            }
            
            Text(item.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text("by \(item.author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(item.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Empty Content View
struct EmptyContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Content to Moderate")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("No content items require moderation at the moment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - User Moderation View
struct UserModerationView: View {
    @State private var users: [ModeratedUser] = []
    @State private var isLoading = false
    
    var body: some View {
        if isLoading {
            LoadingView()
        } else if users.isEmpty {
            EmptyUsersView()
        } else {
            List {
                ForEach(users) { user in
                    UserModerationRow(user: user)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(PlainListStyle())
        }
        .onAppear {
            loadUsers()
        }
    }
    
    private func loadUsers() {
        isLoading = true
        // TODO: Load users for moderation
        users = []
        isLoading = false
    }
}

// MARK: - Moderated User
struct ModeratedUser: Identifiable {
    let id: String
    let username: String
    let displayName: String
    let avatarURL: String?
    let reportCount: Int
    let status: UserModerationStatus
    let lastActiveAt: Date
}

// MARK: - User Moderation Status
enum UserModerationStatus: String, CaseIterable {
    case active = "active"
    case restricted = "restricted"
    case suspended = "suspended"
    case banned = "banned"
    
    var color: String {
        switch self {
        case .active: return "green"
        case .restricted: return "yellow"
        case .suspended: return "orange"
        case .banned: return "red"
        }
    }
}

// MARK: - User Moderation Row
struct UserModerationRow: View {
    let user: ModeratedUser
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(user.reportCount) reports")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: user.status)
                
                Text(user.lastActiveAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Empty Users View
struct EmptyUsersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Users to Moderate")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("No users require moderation at the moment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Moderation Analytics View
struct ModerationAnalyticsView: View {
    @State private var analytics: ModerationAnalytics?
    @State private var isLoading = false
    
    var body: some View {
        if isLoading {
            LoadingView()
        } else if let analytics = analytics {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Reports Today",
                                value: "\(analytics.reportsToday)",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Resolved Today",
                                value: "\(analytics.resolvedToday)",
                                color: .green
                            )
                        }
                    }
                    
                    // Content breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content Breakdown")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(analytics.contentBreakdown, id: \.type) { breakdown in
                            ContentBreakdownRow(breakdown: breakdown)
                        }
                    }
                    
                    // Reason breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Report Reasons")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(analytics.reasonBreakdown, id: \.reason) { breakdown in
                            ReasonBreakdownRow(breakdown: breakdown)
                        }
                    }
                }
                .padding()
            }
        } else {
            EmptyAnalyticsView()
        }
        .onAppear {
            loadAnalytics()
        }
    }
    
    private func loadAnalytics() {
        isLoading = true
        // TODO: Load moderation analytics
        analytics = ModerationAnalytics(
            reportsToday: 0,
            resolvedToday: 0,
            contentBreakdown: [],
            reasonBreakdown: []
        )
        isLoading = false
    }
}

// MARK: - Moderation Analytics
struct ModerationAnalytics {
    let reportsToday: Int
    let resolvedToday: Int
    let contentBreakdown: [ContentBreakdown]
    let reasonBreakdown: [ReasonBreakdown]
}

// MARK: - Content Breakdown
struct ContentBreakdown {
    let type: ContentType
    let count: Int
    let percentage: Double
}

// MARK: - Reason Breakdown
struct ReasonBreakdown {
    let reason: ReportReason
    let count: Int
    let percentage: Double
}

// MARK: - Content Breakdown Row
struct ContentBreakdownRow: View {
    let breakdown: ContentBreakdown
    
    var body: some View {
        HStack {
            Text(breakdown.type.displayName)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(breakdown.count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.wweBlue)
            
            Text("(\(Int(breakdown.percentage))%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Reason Breakdown Row
struct ReasonBreakdownRow: View {
    let breakdown: ReasonBreakdown
    
    var body: some View {
        HStack {
            Text(breakdown.reason.displayName)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(breakdown.count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.wweBlue)
            
            Text("(\(Int(breakdown.percentage))%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Empty Analytics View
struct EmptyAnalyticsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Analytics Data")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Analytics data will appear here once moderation activity begins.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ModerationDashboardView()
}
