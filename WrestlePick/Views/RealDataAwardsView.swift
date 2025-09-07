import SwiftUI

struct RealDataAwardsView: View {
    @EnvironmentObject var wrestlerService: WrestlerDataService
    @State private var selectedCategory: AwardCategory = .all
    @State private var searchText = ""
    @State private var showingNewAward = false
    
    var awards: [Award] {
        // Mock awards data - in real implementation, this would come from a service
        generateMockAwards()
    }
    
    var filteredAwards: [Award] {
        var filtered = awards
        
        // Filter by category
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { award in
                award.title.localizedCaseInsensitiveContains(searchText) ||
                award.description.localizedCaseInsensitiveContains(searchText) ||
                award.creator.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Category Filter
                CategoryFilter(selectedCategory: $selectedCategory)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Awards List
                if filteredAwards.isEmpty {
                    EmptyStateView(
                        title: "No Awards Found",
                        message: searchText.isEmpty ? "No awards available at the moment." : "No awards match your search.",
                        systemImage: "trophy"
                    )
                } else {
                    AwardsList(awards: filteredAwards)
                }
            }
            .navigationTitle("Wrestling Awards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewAward = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewAward) {
                NewAwardView()
            }
        }
    }
}

struct AwardsList: View {
    let awards: [Award]
    
    var body: some View {
        List(awards) { award in
            AwardRow(award: award)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(PlainListStyle())
    }
}

struct AwardRow: View {
    let award: Award
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(award.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(award.description)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    CategoryTag(category: award.category)
                    
                    Text("By \(award.creator)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Voting Period")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("\(award.votingPeriod.startDate, style: .date) - \(award.votingPeriod.endDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Votes")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("\(award.totalVotes)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            // Nominees Preview
            if !award.nominees.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nominees")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(award.nominees.prefix(3)) { nominee in
                            NomineeTag(nominee: nominee)
                        }
                        
                        if award.nominees.count > 3 {
                            Text("+ \(award.nominees.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    // Vote
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                        Text("Vote")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
                
                Button(action: {
                    // Share
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Ends in \(award.votingPeriod.endDate, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct NomineeTag: View {
    let nominee: AwardNominee
    
    var body: some View {
        Text(nominee.name)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .clipShape(Capsule())
    }
}

struct NewAwardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var category: AwardCategory = .match
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var nominees: [String] = []
    @State private var newNominee = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Award Details") {
                    TextField("Award Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $category) {
                        ForEach(AwardCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section("Voting Period") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Nominees") {
                    ForEach(nominees, id: \.self) { nominee in
                        Text(nominee)
                    }
                    .onDelete(perform: deleteNominee)
                    
                    HStack {
                        TextField("Add nominee", text: $newNominee)
                        Button("Add") {
                            if !newNominee.isEmpty {
                                nominees.append(newNominee)
                                newNominee = ""
                            }
                        }
                        .disabled(newNominee.isEmpty)
                    }
                }
            }
            .navigationTitle("New Award")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        // Create award
                        dismiss()
                    }
                    .disabled(title.isEmpty || description.isEmpty || nominees.isEmpty)
                }
            }
        }
    }
    
    private func deleteNominee(at offsets: IndexSet) {
        nominees.remove(atOffsets: offsets)
    }
}

// MARK: - Mock Data
private func generateMockAwards() -> [Award] {
    return [
        Award(
            id: "award-1",
            title: "Match of the Year 2024",
            description: "The best wrestling match of 2024",
            category: .match,
            creator: "WrestlePick Community",
            votingPeriod: VotingPeriod(
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                isActive: true
            ),
            nominees: [
                AwardNominee(id: "nominee-1", name: "Roman Reigns vs Cody Rhodes", votes: 150),
                AwardNominee(id: "nominee-2", name: "Jon Moxley vs Kenny Omega", votes: 120),
                AwardNominee(id: "nominee-3", name: "Kazuchika Okada vs Tetsuya Naito", votes: 100)
            ],
            totalVotes: 370,
            isActive: true,
            createdAt: Date()
        ),
        Award(
            id: "award-2",
            title: "Wrestler of the Year 2024",
            description: "The most outstanding wrestler of 2024",
            category: .wrestler,
            creator: "WrestlePick Community",
            votingPeriod: VotingPeriod(
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                isActive: true
            ),
            nominees: [
                AwardNominee(id: "nominee-4", name: "Roman Reigns", votes: 200),
                AwardNominee(id: "nominee-5", name: "Jon Moxley", votes: 180),
                AwardNominee(id: "nominee-6", name: "Kazuchika Okada", votes: 160)
            ],
            totalVotes: 540,
            isActive: true,
            createdAt: Date()
        ),
        Award(
            id: "award-3",
            title: "Promotion of the Year 2024",
            description: "The best wrestling promotion of 2024",
            category: .promotion,
            creator: "WrestlePick Community",
            votingPeriod: VotingPeriod(
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                isActive: true
            ),
            nominees: [
                AwardNominee(id: "nominee-7", name: "WWE", votes: 300),
                AwardNominee(id: "nominee-8", name: "AEW", votes: 250),
                AwardNominee(id: "nominee-9", name: "NJPW", votes: 200)
            ],
            totalVotes: 750,
            isActive: true,
            createdAt: Date()
        )
    ]
}

// MARK: - Extensions
extension AwardCategory {
    var displayName: String {
        switch self {
        case .all: return "All"
        case .match: return "Match"
        case .wrestler: return "Wrestler"
        case .promotion: return "Promotion"
        case .show: return "Show"
        case .moment: return "Moment"
        case .feud: return "Feud"
        case .championship: return "Championship"
        }
    }
}

#Preview {
    RealDataAwardsView()
        .environmentObject(WrestlerDataService.shared)
}
