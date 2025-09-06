import SwiftUI

struct BookingComparisonView: View {
    @StateObject private var bookingEngine = BookingEngine.shared
    @State private var fantasyBookings: [FantasyBooking] = []
    @State private var realResults: [RealResult] = []
    @State private var selectedBooking: FantasyBooking?
    @State private var selectedComparison: ComparisonType = .accuracy
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with comparison stats
                if let booking = selectedBooking {
                    ComparisonHeaderView(
                        booking: booking,
                        comparisonType: selectedComparison
                    )
                    .padding()
                }
                
                // Comparison type selector
                ComparisonTypeSelector(selectedType: $selectedComparison)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Content
                if isLoading {
                    LoadingView()
                } else if fantasyBookings.isEmpty {
                    EmptyStateView()
                } else {
                    ComparisonContent(
                        fantasyBookings: fantasyBookings,
                        realResults: realResults,
                        selectedBooking: $selectedBooking,
                        comparisonType: selectedComparison
                    )
                }
            }
            .navigationTitle("Booking Comparison")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        
        // Load fantasy bookings
        loadFantasyBookings { [self] result in
            switch result {
            case .success(let bookings):
                fantasyBookings = bookings
            case .failure(let error):
                print("Error loading fantasy bookings: \(error)")
            }
        }
        
        // Load real results
        loadRealResults { [self] result in
            switch result {
            case .success(let results):
                realResults = results
            case .failure(let error):
                print("Error loading real results: \(error)")
            }
            
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    private func loadFantasyBookings(completion: @escaping (Result<[FantasyBooking], Error>) -> Void) {
        // TODO: Load from Firestore
        let mockBookings = [
            FantasyBooking(
                title: "WrestleMania 40 Fantasy",
                description: "My fantasy booking for WrestleMania 40",
                createdByUserId: "user1",
                createdByUsername: "fantasybooker1",
                promotion: "WWE",
                showType: .ppv,
                date: Date()
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(mockBookings))
        }
    }
    
    private func loadRealResults(completion: @escaping (Result<[RealResult], Error>) -> Void) {
        // TODO: Load from Firestore
        let mockResults = [
            RealResult(
                eventName: "WrestleMania 40",
                date: Date(),
                matches: [
                    RealMatch(
                        matchType: "Singles",
                        participants: ["Roman Reigns", "Cody Rhodes"],
                        winner: "Cody Rhodes",
                        title: "WWE Universal Championship",
                        duration: 1200
                    )
                ]
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(mockResults))
        }
    }
}

// MARK: - Comparison Type
enum ComparisonType: String, CaseIterable {
    case accuracy = "accuracy"
    case engagement = "engagement"
    case creativity = "creativity"
    case realism = "realism"
    
    var displayName: String {
        switch self {
        case .accuracy: return "Accuracy"
        case .engagement: return "Engagement"
        case .creativity: return "Creativity"
        case .realism: return "Realism"
        }
    }
    
    var iconName: String {
        switch self {
        case .accuracy: return "target"
        case .engagement: return "heart"
        case .creativity: return "sparkles"
        case .realism: return "checkmark.shield"
        }
    }
}

// MARK: - Comparison Header View
struct ComparisonHeaderView: View {
    let booking: FantasyBooking
    let comparisonType: ComparisonType
    
    var body: some View {
        VStack(spacing: 16) {
            // Booking info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("by @\(booking.createdByUsername)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(booking.showType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.wweBlue)
                    
                    Text(booking.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Comparison stats
            HStack(spacing: 20) {
                StatItem(
                    title: "Accuracy",
                    value: "85%",
                    color: .green
                )
                
                StatItem(
                    title: "Engagement",
                    value: "4.2",
                    color: .blue
                )
                
                StatItem(
                    title: "Creativity",
                    value: "4.5",
                    color: .purple
                )
                
                StatItem(
                    title: "Realism",
                    value: "3.8",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Stat Item
struct StatItem: View {
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
    }
}

// MARK: - Comparison Type Selector
struct ComparisonTypeSelector: View {
    @Binding var selectedType: ComparisonType
    
    var body: some View {
        Picker("Comparison Type", selection: $selectedType) {
            ForEach(ComparisonType.allCases, id: \.self) { type in
                HStack {
                    Image(systemName: type.iconName)
                    Text(type.displayName)
                }
                .tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading comparison data...")
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
            Image(systemName: "chart.bar.compare")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Fantasy Bookings")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create fantasy bookings to compare with real results")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Comparison Content
struct ComparisonContent: View {
    let fantasyBookings: [FantasyBooking]
    let realResults: [RealResult]
    @Binding var selectedBooking: FantasyBooking?
    let comparisonType: ComparisonType
    
    var body: some View {
        VStack(spacing: 0) {
            // Fantasy bookings list
            FantasyBookingsList(
                fantasyBookings: fantasyBookings,
                selectedBooking: $selectedBooking
            )
            
            // Comparison details
            if let booking = selectedBooking {
                ComparisonDetailsView(
                    fantasyBooking: booking,
                    realResults: realResults,
                    comparisonType: comparisonType
                )
            }
        }
    }
}

// MARK: - Fantasy Bookings List
struct FantasyBookingsList: View {
    let fantasyBookings: [FantasyBooking]
    @Binding var selectedBooking: FantasyBooking?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fantasy Bookings")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(fantasyBookings) { booking in
                        FantasyBookingCard(
                            booking: booking,
                            isSelected: selectedBooking?.id == booking.id,
                            onTap: {
                                selectedBooking = booking
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Fantasy Booking Card
struct FantasyBookingCard: View {
    let booking: FantasyBooking
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(booking.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(booking.showType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.wweBlue)
                
                Text(booking.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(booking.matchCards.count) matches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(booking.engagement.averageRating))★")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            .frame(width: 200)
            .background(isSelected ? Color.wweBlue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Comparison Details View
struct ComparisonDetailsView: View {
    let fantasyBooking: FantasyBooking
    let realResults: [RealResult]
    let comparisonType: ComparisonType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison Details")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(fantasyBooking.matchCards) { match in
                        MatchComparisonCard(
                            fantasyMatch: match,
                            realResult: findRealMatch(for: match),
                            comparisonType: comparisonType
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func findRealMatch(for fantasyMatch: MatchCard) -> RealMatch? {
        // TODO: Implement real match finding logic
        return nil
    }
}

// MARK: - Match Comparison Card
struct MatchComparisonCard: View {
    let fantasyMatch: MatchCard
    let realResult: RealMatch?
    let comparisonType: ComparisonType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Match header
            HStack {
                Text(fantasyMatch.matchType.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let title = fantasyMatch.title {
                    Text(title.name)
                        .font(.subheadline)
                        .foregroundColor(.wweBlue)
                }
            }
            
            // Participants comparison
            VStack(alignment: .leading, spacing: 8) {
                Text("Participants")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    // Fantasy participants
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fantasy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(fantasyMatch.participants) { wrestler in
                            Text(wrestler.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // Comparison indicator
                    VStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Real participants
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Real")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let realResult = realResult {
                            ForEach(realResult.participants, id: \.self) { participant in
                                Text(participant)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        } else {
                            Text("No real match")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Winner comparison
            if let realResult = realResult {
                HStack {
                    Text("Winner")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Text("Fantasy: \(fantasyMatch.participants.first?.name ?? "Unknown")")
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Text("Real: \(realResult.winner)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Comparison score
            HStack {
                Text("Accuracy Score")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("85%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Real Result Models
struct RealResult: Codable, Identifiable {
    let id: String
    let eventName: String
    let date: Date
    let matches: [RealMatch]
    
    init(eventName: String, date: Date, matches: [RealMatch]) {
        self.id = UUID().uuidString
        self.eventName = eventName
        self.date = date
        self.matches = matches
    }
}

struct RealMatch: Codable, Identifiable {
    let id: String
    let matchType: String
    let participants: [String]
    let winner: String
    let title: String?
    let duration: TimeInterval
    
    init(matchType: String, participants: [String], winner: String, title: String? = nil, duration: TimeInterval) {
        self.id = UUID().uuidString
        self.matchType = matchType
        self.participants = participants
        self.winner = winner
        self.title = title
        self.duration = duration
    }
}

#Preview {
    BookingComparisonView()
}
