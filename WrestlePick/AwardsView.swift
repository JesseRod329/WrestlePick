import SwiftUI

struct AwardsView: View {
    @State private var awards: [WrestlingAward] = []
    @State private var showingCreateAward = false
    @State private var selectedCategory: AwardCategory = .all
    
    var body: some View {
        NavigationView {
            VStack {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AwardCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Awards Grid
                if awards.isEmpty {
                    EmptyAwardsView {
                        showingCreateAward = true
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredAwards) { award in
                                AwardCardView(award: award)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Wrestling Awards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Award") {
                        showingCreateAward = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .sheet(isPresented: $showingCreateAward) {
                CreateAwardView { award in
                    awards.append(award)
                }
            }
            .onAppear {
                loadMockData()
            }
        }
    }
    
    private var filteredAwards: [WrestlingAward] {
        if selectedCategory == .all {
            return awards
        }
        return awards.filter { $0.category == selectedCategory }
    }
    
    private func loadMockData() {
        awards = [
            WrestlingAward(
                id: "1",
                title: "Match of the Year 2024",
                description: "The best wrestling match of 2024",
                category: .match,
                nominees: [
                    "Roman Reigns vs Cody Rhodes - WrestleMania 40",
                    "Kenny Omega vs Will Ospreay - Forbidden Door",
                    "Seth Rollins vs Drew McIntyre - SummerSlam"
                ],
                winner: "Roman Reigns vs Cody Rhodes - WrestleMania 40",
                creator: "WrestlePick User",
                timestamp: Date(),
                isVotingOpen: true
            ),
            WrestlingAward(
                id: "2",
                title: "Most Improved Wrestler",
                description: "Who has shown the most growth this year?",
                category: .wrestler,
                nominees: [
                    "Bron Breakker",
                    "Rhea Ripley",
                    "MJF",
                    "Gunther"
                ],
                winner: nil,
                creator: "WrestlePick User",
                timestamp: Date().addingTimeInterval(-86400),
                isVotingOpen: true
            )
        ]
    }
}

// MARK: - Models

struct WrestlingAward: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: AwardCategory
    let nominees: [String]
    let winner: String?
    let creator: String
    let timestamp: Date
    let isVotingOpen: Bool
}

enum AwardCategory: String, CaseIterable {
    case all = "All"
    case match = "Match"
    case wrestler = "Wrestler"
    case segment = "Segment"
    case promotion = "Promotion"
    case moment = "Moment"
}

// MARK: - Supporting Views

struct EmptyAwardsView: View {
    let onCreateAward: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("No Awards Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your own wrestling awards and let the community vote on the winners!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Create Your First Award") {
                onCreateAward()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct AwardCardView: View {
    let award: WrestlingAward
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(award.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(award.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(award.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    
                    if award.isVotingOpen {
                        Text("Voting Open")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("Voting Closed")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            if let winner = award.winner {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Winner:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(winner)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                }
            } else {
                Text("\(award.nominees.count) nominees")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("by \(award.creator)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if award.isVotingOpen {
                    Button("Vote") {
                        // Vote action
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CreateAwardView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (WrestlingAward) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: AwardCategory = .match
    @State private var nominees = [""]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Award Details") {
                    TextField("Award Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(AwardCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Nominees") {
                    ForEach(nominees.indices, id: \.self) { index in
                        TextField("Nominee \(index + 1)", text: $nominees[index])
                    }
                    .onDelete(perform: deleteNominee)
                    
                    Button("Add Nominee") {
                        nominees.append("")
                    }
                    .foregroundColor(.accentColor)
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
                        let newAward = WrestlingAward(
                            id: UUID().uuidString,
                            title: title,
                            description: description,
                            category: selectedCategory,
                            nominees: nominees.filter { !$0.isEmpty },
                            winner: nil,
                            creator: "You",
                            timestamp: Date(),
                            isVotingOpen: true
                        )
                        onSave(newAward)
                        dismiss()
                    }
                    .disabled(title.isEmpty || description.isEmpty || nominees.filter { !$0.isEmpty }.count < 2)
                }
            }
        }
    }
    
    private func deleteNominee(at offsets: IndexSet) {
        nominees.remove(atOffsets: offsets)
    }
}

#Preview {
    AwardsView()
}