import SwiftUI

struct NewsView: View {
    @State private var newsItems: [NewsItem] = []
    @State private var isLoading = false
    @State private var selectedCategory: NewsCategory = .all
    
    var body: some View {
        NavigationView {
            VStack {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(NewsCategory.allCases, id: \.self) { category in
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
                
                // News List
                if isLoading {
                    ProgressView("Loading wrestling news...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredNews) { item in
                        NewsCardView(item: item)
                    }
                    .refreshable {
                        await loadNews()
                    }
                }
            }
            .navigationTitle("Wrestling News")
            .task {
                await loadNews()
            }
        }
    }
    
    private var filteredNews: [NewsItem] {
        if selectedCategory == .all {
            return newsItems
        }
        return newsItems.filter { $0.category == selectedCategory }
    }
    
    private func loadNews() async {
        isLoading = true
        // Simulate loading delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock data for now
        newsItems = [
            NewsItem(
                id: "1",
                title: "Roman Reigns Retains Universal Championship at WrestleMania",
                content: "The Tribal Chief successfully defended his title against Cody Rhodes in a thrilling main event.",
                source: "WWE.com",
                category: .results,
                reliabilityScore: 1.0,
                timestamp: Date(),
                imageURL: nil
            ),
            NewsItem(
                id: "2",
                title: "Rumors: CM Punk's Return to WWE Imminent",
                content: "Sources close to the situation suggest Punk may be making his return to WWE programming soon.",
                source: "Fightful",
                category: .rumors,
                reliabilityScore: 0.6,
                timestamp: Date().addingTimeInterval(-3600),
                imageURL: nil
            ),
            NewsItem(
                id: "3",
                title: "AEW Dynamite Ratings Continue to Climb",
                content: "Wednesday night's episode drew strong numbers, continuing the promotion's upward trend.",
                source: "Cageside Seats",
                category: .analysis,
                reliabilityScore: 0.9,
                timestamp: Date().addingTimeInterval(-7200),
                imageURL: nil
            )
        ]
        isLoading = false
    }
}

// MARK: - Models

struct NewsItem: Identifiable {
    let id: String
    let title: String
    let content: String
    let source: String
    let category: NewsCategory
    let reliabilityScore: Double
    let timestamp: Date
    let imageURL: String?
}

enum NewsCategory: String, CaseIterable {
    case all = "All"
    case breaking = "Breaking"
    case rumors = "Rumors"
    case results = "Results"
    case analysis = "Analysis"
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let category: NewsCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

struct NewsCardView: View {
    let item: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ReliabilityBadge(score: item.reliabilityScore)
                    Text(item.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(item.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(item.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ReliabilityBadge: View {
    let score: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundColor(reliabilityColor)
            
            Text(reliabilityText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(reliabilityColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(reliabilityColor.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var reliabilityColor: Color {
        switch score {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var reliabilityText: String {
        switch score {
        case 0.8...1.0:
            return "Tier 1"
        case 0.6..<0.8:
            return "Tier 2"
        default:
            return "Speculation"
        }
    }
}

#Preview {
    NewsView()
}