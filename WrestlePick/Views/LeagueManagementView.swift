import SwiftUI

struct LeagueManagementView: View {
    @StateObject private var socialService = SocialService.shared
    @State private var selectedTab: LeagueTab = .myLeagues
    @State private var showingCreateLeague = false
    @State private var showingJoinLeague = false
    @State private var selectedLeague: League?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with tabs
                HeaderView(
                    selectedTab: $selectedTab,
                    showingCreateLeague: $showingCreateLeague,
                    showingJoinLeague: $showingJoinLeague
                )
                
                // Content
                if isLoading {
                    LoadingView()
                } else {
                    TabContentView(
                        selectedTab: selectedTab,
                        leagues: socialService.leagues,
                        onLeagueSelected: { league in
                            selectedLeague = league
                        }
                    )
                }
            }
            .navigationTitle("Leagues")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadLeagues()
            }
            .sheet(isPresented: $showingCreateLeague) {
                CreateLeagueView()
            }
            .sheet(isPresented: $showingJoinLeague) {
                JoinLeagueView()
            }
            .sheet(item: $selectedLeague) { league in
                LeagueDetailView(league: league)
            }
        }
    }
    
    private func loadLeagues() {
        isLoading = true
        socialService.loadLeagues()
        isLoading = false
    }
}

// MARK: - League Tab
enum LeagueTab: String, CaseIterable {
    case myLeagues = "myLeagues"
    case publicLeagues = "publicLeagues"
    case leaderboard = "leaderboard"
    
    var displayName: String {
        switch self {
        case .myLeagues: return "My Leagues"
        case .publicLeagues: return "Public Leagues"
        case .leaderboard: return "Leaderboard"
        }
    }
    
    var iconName: String {
        switch self {
        case .myLeagues: return "person.2"
        case .publicLeagues: return "globe"
        case .leaderboard: return "trophy"
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var selectedTab: LeagueTab
    @Binding var showingCreateLeague: Bool
    @Binding var showingJoinLeague: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Tab selector
            Picker("League Tab", selection: $selectedTab) {
                ForEach(LeagueTab.allCases, id: \.self) { tab in
                    Text(tab.displayName).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    showingCreateLeague = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create League")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.wweBlue)
                    .cornerRadius(20)
                }
                
                Button(action: {
                    showingJoinLeague = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join League")
                    }
                    .font(.subheadline)
                    .foregroundColor(.wweBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.wweBlue.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading leagues...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab Content View
struct TabContentView: View {
    let selectedTab: LeagueTab
    let leagues: [League]
    let onLeagueSelected: (League) -> Void
    
    var body: some View {
        switch selectedTab {
        case .myLeagues:
            MyLeaguesView(
                leagues: leagues.filter { $0.creatorId == "current_user" },
                onLeagueSelected: onLeagueSelected
            )
        case .publicLeagues:
            PublicLeaguesView(
                leagues: leagues,
                onLeagueSelected: onLeagueSelected
            )
        case .leaderboard:
            LeagueLeaderboardView()
        }
    }
}

// MARK: - My Leagues View
struct MyLeaguesView: View {
    let leagues: [League]
    let onLeagueSelected: (League) -> Void
    
    var body: some View {
        if leagues.isEmpty {
            EmptyMyLeaguesView()
        } else {
            List {
                ForEach(leagues) { league in
                    LeagueCard(
                        league: league,
                        onTap: {
                            onLeagueSelected(league)
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

// MARK: - Empty My Leagues View
struct EmptyMyLeaguesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Leagues Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create your first league or join an existing one to start competing!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Public Leagues View
struct PublicLeaguesView: View {
    let leagues: [League]
    let onLeagueSelected: (League) -> Void
    
    var body: some View {
        if leagues.isEmpty {
            EmptyPublicLeaguesView()
        } else {
            List {
                ForEach(leagues) { league in
                    LeagueCard(
                        league: league,
                        onTap: {
                            onLeagueSelected(league)
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

// MARK: - Empty Public Leagues View
struct EmptyPublicLeaguesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Public Leagues")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("No public leagues available at the moment. Check back later!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - League Card
struct LeagueCard: View {
    let league: League
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(league.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("by \(league.creatorUsername)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: league.status)
                }
                
                // Description
                if !league.description.isEmpty {
                    Text(league.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Stats
                HStack {
                    StatItem(
                        title: "Members",
                        value: "\(league.currentMembers)/\(league.maxMembers)",
                        icon: "person.2"
                    )
                    
                    Spacer()
                    
                    StatItem(
                        title: "Season",
                        value: league.season.name,
                        icon: "calendar"
                    )
                    
                    Spacer()
                    
                    StatItem(
                        title: "Rules",
                        value: "\(league.rules.count)",
                        icon: "list.bullet"
                    )
                }
                
                // Progress bar
                ProgressView(value: Double(league.currentMembers), total: Double(league.maxMembers))
                    .progressViewStyle(LinearProgressViewStyle(tint: .wweBlue))
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
    let status: LeagueStatus
    
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
        case .active: return "play.circle.fill"
        case .paused: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .active: return .green
        case .paused: return .yellow
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.wweBlue)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - League Leaderboard View
struct LeagueLeaderboardView: View {
    @State private var selectedLeague: League?
    @State private var leaderboard: [LeagueMember] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            // League selector
            if selectedLeague == nil {
                LeagueSelectorView { league in
                    selectedLeague = league
                    loadLeaderboard(for: league)
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text(selectedLeague?.name ?? "")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Change") {
                            selectedLeague = nil
                        }
                        .font(.caption)
                        .foregroundColor(.wweBlue)
                    }
                    
                    if isLoading {
                        ProgressView()
                    } else if leaderboard.isEmpty {
                        Text("No leaderboard data available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        LeaderboardList(members: leaderboard)
                    }
                }
                .padding()
            }
        }
    }
    
    private func loadLeaderboard(for league: League) {
        isLoading = true
        leaderboard = league.members.sorted { $0.stats.totalPoints > $1.stats.totalPoints }
        isLoading = false
    }
}

// MARK: - League Selector View
struct LeagueSelectorView: View {
    let onLeagueSelected: (League) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Select a League")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Choose a league to view its leaderboard")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Leaderboard List
struct LeaderboardList: View {
    let members: [LeagueMember]
    
    var body: some View {
        List {
            ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                LeaderboardRow(
                    member: member,
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
    let member: LeagueMember
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
            
            // Avatar
            AsyncImage(url: URL(string: member.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Member info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if member.isAdmin {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                
                Text("@\(member.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(member.stats.totalPoints)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.wweBlue)
                
                Text("points")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(member.stats.accuracy * 100))%")
                    .font(.caption)
                    .foregroundColor(.green)
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

// MARK: - Create League View
struct CreateLeagueView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socialService = SocialService.shared
    
    @State private var name = ""
    @State private var description = ""
    @State private var maxMembers = 20
    @State private var isPublic = true
    @State private var rules: [String] = []
    @State private var newRule = ""
    @State private var isCreating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("League Information") {
                    TextField("League Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Settings") {
                    HStack {
                        Text("Max Members")
                        Spacer()
                        Stepper("\(maxMembers)", value: $maxMembers, in: 2...50)
                    }
                    
                    Toggle("Public League", isOn: $isPublic)
                }
                
                Section("Rules") {
                    ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                        HStack {
                            Text(rule)
                            Spacer()
                            Button("Remove") {
                                rules.remove(at: index)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add a rule", text: $newRule)
                        Button("Add") {
                            if !newRule.isEmpty {
                                rules.append(newRule)
                                newRule = ""
                            }
                        }
                        .disabled(newRule.isEmpty)
                    }
                }
            }
            .navigationTitle("Create League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createLeague()
                    }
                    .disabled(name.isEmpty || isCreating)
                }
            }
            .alert("League Creation", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func createLeague() {
        isCreating = true
        
        let league = League(
            name: name,
            description: description,
            creatorId: "current_user", // TODO: Get from auth service
            creatorUsername: "current_user",
            isPublic: isPublic,
            maxMembers: maxMembers,
            rules: rules
        )
        
        socialService.createLeague(league) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success:
                    alertMessage = "League created successfully!"
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                case .failure(let error):
                    alertMessage = "Failed to create league: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Join League View
struct JoinLeagueView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socialService = SocialService.shared
    
    @State private var searchText = ""
    @State private var leagues: [League] = []
    @State private var isLoading = false
    
    var filteredLeagues: [League] {
        if searchText.isEmpty {
            return leagues
        } else {
            return leagues.filter { league in
                league.name.localizedCaseInsensitiveContains(searchText) ||
                league.description.localizedCaseInsensitiveContains(searchText) ||
                league.creatorUsername.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search leagues...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Leagues list
                if isLoading {
                    LoadingView()
                } else if filteredLeagues.isEmpty {
                    EmptyLeaguesView()
                } else {
                    List {
                        ForEach(filteredLeagues) { league in
                            LeagueCard(
                                league: league,
                                onTap: {
                                    joinLeague(league)
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Join League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadLeagues()
            }
        }
    }
    
    private func loadLeagues() {
        isLoading = true
        leagues = socialService.leagues.filter { $0.isPublic && $0.currentMembers < $0.maxMembers }
        isLoading = false
    }
    
    private func joinLeague(_ league: League) {
        socialService.joinLeague(league.id ?? "", userId: "current_user") { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    print("Failed to join league: \(error)")
                }
            }
        }
    }
}

// MARK: - Empty Leagues View
struct EmptyLeaguesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Leagues Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try searching with different keywords")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - League Detail View
struct LeagueDetailView: View {
    let league: League
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // League header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(league.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("by \(league.creatorUsername)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if !league.description.isEmpty {
                            Text(league.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // League stats
                    HStack(spacing: 20) {
                        StatCard(
                            title: "Members",
                            value: "\(league.currentMembers)/\(league.maxMembers)",
                            icon: "person.2"
                        )
                        
                        StatCard(
                            title: "Season",
                            value: league.season.name,
                            icon: "calendar"
                        )
                        
                        StatCard(
                            title: "Status",
                            value: league.status.rawValue.capitalized,
                            icon: "circle.fill"
                        )
                    }
                    
                    // Rules
                    if !league.rules.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rules")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(Array(league.rules.enumerated()), id: \.offset) { index, rule in
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    Text(rule)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Members
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Members")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(league.members) { member in
                            MemberRow(member: member)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("League Details")
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

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.wweBlue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
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

// MARK: - Member Row
struct MemberRow: View {
    let member: LeagueMember
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: member.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(member.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if member.isAdmin {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Text("@\(member.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(member.stats.totalPoints)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.wweBlue)
                
                Text("points")
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
    LeagueManagementView()
}
