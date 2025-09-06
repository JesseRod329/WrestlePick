import SwiftUI

struct CommunityVotingView: View {
    @StateObject private var bookingEngine = BookingEngine.shared
    @State private var communityBookings: [CommunityBooking] = []
    @State private var selectedCategory: VotingCategory = .all
    @State private var selectedSort: VotingSort = .trending
    @State private var isLoading = false
    @State private var showingVotingDetails = false
    @State private var selectedBooking: CommunityBooking?
    
    var filteredBookings: [CommunityBooking] {
        var filtered = communityBookings
        
        // Filter by category
        switch selectedCategory {
        case .all:
            break
        case .wwe:
            filtered = filtered.filter { $0.promotion == "WWE" }
        case .aew:
            filtered = filtered.filter { $0.promotion == "AEW" }
        case .njpw:
            filtered = filtered.filter { $0.promotion == "NJPW" }
        case .ppv:
            filtered = filtered.filter { $0.showType == .ppv }
        case .weekly:
            filtered = filtered.filter { $0.showType == .raw || $0.showType == .smackdown || $0.showType == .aewDynamite }
        }
        
        // Sort bookings
        switch selectedSort {
        case .trending:
            filtered = filtered.sorted { $0.engagement.votes > $1.engagement.votes }
        case .newest:
            filtered = filtered.sorted { $0.createdAt > $1.createdAt }
        case .highestRated:
            filtered = filtered.sorted { $0.engagement.averageRating > $1.engagement.averageRating }
        case .mostCommented:
            filtered = filtered.sorted { $0.engagement.comments > $1.engagement.comments }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                HeaderView(
                    totalBookings: communityBookings.count,
                    totalVotes: communityBookings.reduce(0) { $0 + $1.engagement.votes }
                )
                .padding()
                
                // Filters and sort
                FilterAndSortBar(
                    selectedCategory: $selectedCategory,
                    selectedSort: $selectedSort
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Content
                if isLoading {
                    LoadingView()
                } else if filteredBookings.isEmpty {
                    EmptyStateView()
                } else {
                    CommunityBookingsList(
                        bookings: filteredBookings,
                        onTap: { booking in
                            selectedBooking = booking
                            showingVotingDetails = true
                        }
                    )
                }
            }
            .navigationTitle("Community Voting")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadCommunityBookings()
            }
            .sheet(isPresented: $showingVotingDetails) {
                if let booking = selectedBooking {
                    VotingDetailsView(
                        booking: booking,
                        onVote: { rating, comment in
                            submitVote(booking: booking, rating: rating, comment: comment)
                        }
                    )
                }
            }
        }
    }
    
    private func loadCommunityBookings() {
        isLoading = true
        
        // TODO: Load from Firestore
        let mockBookings = [
            CommunityBooking(
                id: "1",
                title: "WrestleMania 40 Fantasy Booking",
                description: "My take on what should happen at WrestleMania 40",
                createdByUserId: "user1",
                createdByUsername: "fantasybooker1",
                promotion: "WWE",
                showType: .ppv,
                date: Date(),
                matchCards: [],
                engagement: BookingEngagement(views: 1250, likes: 89, shares: 23, comments: 45, bookmarks: 12, votes: 156, averageRating: 4.2)
            ),
            CommunityBooking(
                id: "2",
                title: "AEW Revolution 2024",
                description: "Dream matches for AEW Revolution",
                createdByUserId: "user2",
                createdByUsername: "aewfan",
                promotion: "AEW",
                showType: .ppv,
                date: Date(),
                matchCards: [],
                engagement: BookingEngagement(views: 890, likes: 67, shares: 18, comments: 32, bookmarks: 8, votes: 98, averageRating: 4.5)
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            communityBookings = mockBookings
            isLoading = false
        }
    }
    
    private func submitVote(booking: CommunityBooking, rating: Int, comment: String?) {
        bookingEngine.submitVote(
            bookingId: booking.id,
            userId: "current_user", // TODO: Get from auth service
            rating: rating,
            comment: comment
        )
    }
}

// MARK: - Voting Category
enum VotingCategory: String, CaseIterable {
    case all = "all"
    case wwe = "wwe"
    case aew = "aew"
    case njpw = "njpw"
    case ppv = "ppv"
    case weekly = "weekly"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .wwe: return "WWE"
        case .aew: return "AEW"
        case .njpw: return "NJPW"
        case .ppv: return "PPV"
        case .weekly: return "Weekly"
        }
    }
    
    var iconName: String {
        switch self {
        case .all: return "globe"
        case .wwe: return "tv"
        case .aew: return "flame"
        case .njpw: return "globe"
        case .ppv: return "crown"
        case .weekly: return "calendar"
        }
    }
}

// MARK: - Voting Sort
enum VotingSort: String, CaseIterable {
    case trending = "trending"
    case newest = "newest"
    case highestRated = "highestRated"
    case mostCommented = "mostCommented"
    
    var displayName: String {
        switch self {
        case .trending: return "Trending"
        case .newest: return "Newest"
        case .highestRated: return "Highest Rated"
        case .mostCommented: return "Most Commented"
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let totalBookings: Int
    let totalVotes: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(totalBookings) Bookings")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Community Submissions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(totalVotes)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.wweBlue)
                
                Text("Total Votes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Filter and Sort Bar
struct FilterAndSortBar: View {
    @Binding var selectedCategory: VotingCategory
    @Binding var selectedSort: VotingSort
    
    var body: some View {
        VStack(spacing: 12) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(VotingCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: category.iconName)
                                    .font(.caption)
                                Text(category.displayName)
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
            
            // Sort picker
            HStack {
                Text("Sort by:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Sort", selection: $selectedSort) {
                    ForEach(VotingSort.allCases, id: \.self) { sort in
                        Text(sort.displayName).tag(sort)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading community bookings...")
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
            Image(systemName: "person.3")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Community Bookings")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Be the first to share your fantasy booking with the community")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Community Bookings List
struct CommunityBookingsList: View {
    let bookings: [CommunityBooking]
    let onTap: (CommunityBooking) -> Void
    
    var body: some View {
        List {
            ForEach(bookings) { booking in
                CommunityBookingCard(
                    booking: booking,
                    onTap: {
                        onTap(booking)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Community Booking Card
struct CommunityBookingCard: View {
    let booking: CommunityBooking
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(booking.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text("by @\(booking.createdByUsername)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(booking.promotion)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.wweBlue)
                        
                        Text(booking.showType.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Description
                if !booking.description.isEmpty {
                    Text(booking.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Stats
                HStack(spacing: 16) {
                    StatItem(
                        icon: "eye",
                        value: "\(booking.engagement.views)",
                        color: .secondary
                    )
                    
                    StatItem(
                        icon: "heart",
                        value: "\(booking.engagement.likes)",
                        color: .red
                    )
                    
                    StatItem(
                        icon: "bubble.left",
                        value: "\(booking.engagement.comments)",
                        color: .blue
                    )
                    
                    StatItem(
                        icon: "star",
                        value: String(format: "%.1f", booking.engagement.averageRating),
                        color: .yellow
                    )
                    
                    Spacer()
                    
                    Text("\(booking.engagement.votes) votes")
                        .font(.caption)
                        .foregroundColor(.wweBlue)
                }
                
                // Match count
                HStack {
                    Text("\(booking.matchCards.count) matches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(booking.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
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

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Voting Details View
struct VotingDetailsView: View {
    let booking: CommunityBooking
    let onVote: (Int, String?) -> Void
    
    @State private var selectedRating: Int = 0
    @State private var comment: String = ""
    @State private var showingVoteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Booking details
                    BookingDetailsView(booking: booking)
                    
                    // Rating section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rate This Booking")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            // Star rating
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        selectedRating = star
                                    }) {
                                        Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                            .font(.title2)
                                            .foregroundColor(star <= selectedRating ? .yellow : .gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(selectedRating)/5")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            // Comment
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Comment (Optional)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Share your thoughts...", text: $comment, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                        }
                    }
                    
                    // Vote button
                    Button(action: {
                        showingVoteConfirmation = true
                    }) {
                        Text("Submit Vote")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedRating > 0 ? Color.wweBlue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(selectedRating == 0)
                }
                .padding()
            }
            .navigationTitle("Vote on Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Submit Vote", isPresented: $showingVoteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Submit") {
                onVote(selectedRating, comment.isEmpty ? nil : comment)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to submit your vote?")
        }
    }
}

// MARK: - Booking Details View
struct BookingDetailsView: View {
    let booking: CommunityBooking
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("by @\(booking.createdByUsername)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(booking.promotion)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.wweBlue)
                    
                    Text(booking.showType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            if !booking.description.isEmpty {
                Text(booking.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Match cards
            if !booking.matchCards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Match Card")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(booking.matchCards) { match in
                        MatchCardSummary(match: match)
                    }
                }
            }
            
            // Engagement stats
            HStack(spacing: 20) {
                EngagementStat(
                    icon: "eye",
                    value: "\(booking.engagement.views)",
                    label: "Views"
                )
                
                EngagementStat(
                    icon: "heart",
                    value: "\(booking.engagement.likes)",
                    label: "Likes"
                )
                
                EngagementStat(
                    icon: "bubble.left",
                    value: "\(booking.engagement.comments)",
                    label: "Comments"
                )
                
                EngagementStat(
                    icon: "star",
                    value: String(format: "%.1f", booking.engagement.averageRating),
                    label: "Rating"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Match Card Summary
struct MatchCardSummary: View {
    let match: MatchCard
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.matchType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(match.participants.map { $0.name }.joined(separator: " vs "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let title = match.title {
                Text(title.name)
                    .font(.caption)
                    .foregroundColor(.wweBlue)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

// MARK: - Engagement Stat
struct EngagementStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(.wweBlue)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom Text Field Style
struct RoundedBorderTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

// MARK: - Community Booking Model
struct CommunityBooking: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let createdByUserId: String
    let createdByUsername: String
    let promotion: String
    let showType: ShowType
    let date: Date
    let matchCards: [MatchCard]
    let engagement: BookingEngagement
    
    init(id: String, title: String, description: String, createdByUserId: String, createdByUsername: String, promotion: String, showType: ShowType, date: Date, matchCards: [MatchCard], engagement: BookingEngagement) {
        self.id = id
        self.title = title
        self.description = description
        self.createdByUserId = createdByUserId
        self.createdByUsername = createdByUsername
        self.promotion = promotion
        self.showType = showType
        self.date = date
        self.matchCards = matchCards
        self.engagement = engagement
    }
}

#Preview {
    CommunityVotingView()
}
