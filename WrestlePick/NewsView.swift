import SwiftUI
import Combine

// MARK: - Missing Type Definitions
enum WrestlingPromotion: String, CaseIterable, Codable {
    case wwe = "WWE"
    case aew = "AEW"
    case njpw = "NJPW"
    case impact = "Impact"
    case roh = "ROH"
    case indie = "Independent"
    
    var color: Color {
        switch self {
        case .wwe: return .blue
        case .aew: return .red
        case .njpw: return .orange
        case .impact: return .purple
        case .roh: return .green
        case .indie: return .gray
        }
    }
}

struct NewsSource: Codable {
    let name: String
    let url: String
    let reliability: ReliabilityTier
    let isVerified: Bool
    let establishedDate: Date
    let contactInfo: String?
    
    init(name: String, url: String, reliability: ReliabilityTier) {
        self.name = name
        self.url = url
        self.reliability = reliability
        self.isVerified = reliability == .tier1
        self.establishedDate = Date()
        self.contactInfo = nil
    }
}

// MARK: - News View
struct NewsView: View {
    @StateObject private var rssManager = RSSFeedManager.shared
    @State private var selectedCategory: NewsCategory = .general
    @State private var searchText = ""
    @State private var showingFilters = false
    
    var filteredArticles: [NewsArticle] {
        var articles = rssManager.articles
        
        // Filter by category
        if selectedCategory != .general {
            articles = articles.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            articles = articles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                article.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return articles
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(NewsCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Articles List
                if rssManager.isLoading {
                    LoadingView()
                } else if filteredArticles.isEmpty {
                    EmptyStateView(
                        title: "No Articles Found",
                        message: searchText.isEmpty ? 
                            "No articles available. Pull to refresh." : 
                            "No articles match your search criteria.",
                        systemImage: "newspaper"
                    )
                } else {
                    List(filteredArticles) { article in
                        NewsArticleRow(article: article)
                            .onTapGesture {
                                // Handle article tap
                            }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        rssManager.refreshAllFeeds()
                    }
                }
            }
            .navigationTitle("Wrestling News")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                NewsFiltersView(
                    selectedCategory: $selectedCategory,
                    searchText: $searchText
                )
            }
        }
        .onAppear {
            if rssManager.articles.isEmpty {
                rssManager.refreshAllFeeds()
            }
        }
    }
}

// MARK: - Supporting Views
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search articles...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct NewsArticleRow: View {
    let article: NewsArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(article.excerpt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ReliabilityBadge(tier: article.reliabilityScore)
                    
                    Text(article.publishDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(article.source)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if article.isBreaking {
                    Text("BREAKING")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ReliabilityBadge: View {
    let tier: Double
    
    private var tierColor: Color {
        switch tier {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
    
    private var tierText: String {
        switch tier {
        case 0.8...1.0: return "Tier 1"
        case 0.6..<0.8: return "Tier 2"
        case 0.4..<0.6: return "Speculation"
        default: return "Unverified"
        }
    }
    
    var body: some View {
        Text(tierText)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(tierColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tierColor.opacity(0.1))
            .cornerRadius(4)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading wrestling news...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NewsFiltersView: View {
    @Binding var selectedCategory: NewsCategory
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(NewsCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Search") {
                    TextField("Search articles...", text: $searchText)
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

#Preview {
    NewsView()
}