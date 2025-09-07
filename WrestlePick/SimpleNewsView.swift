import SwiftUI
import Combine

struct SimpleNewsView: View {
    @StateObject private var rssManager = SimpleRSSManager.shared
    @State private var selectedCategory: NewsCategory = .general
    @State private var searchText = ""
    
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
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search articles...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(NewsCategory.allCases, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.accentColor : Color(.systemGray5))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Articles List
                if rssManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Loading wrestling news...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredArticles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Articles Found")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(searchText.isEmpty ? 
                            "No articles available. Pull to refresh." : 
                            "No articles match your search criteria.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredArticles) { article in
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
                                    // Reliability Badge
                                    Text(reliabilityText(for: article.reliabilityScore))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(reliabilityColor(for: article.reliabilityScore))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(reliabilityColor(for: article.reliabilityScore).opacity(0.1))
                                        .cornerRadius(4)
                                    
                                    Text(article.publishDate, style: .relative)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Text(article.source.name)
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
                    .listStyle(PlainListStyle())
                    .refreshable {
                        rssManager.refreshAllFeeds()
                    }
                }
            }
            .navigationTitle("Wrestling News")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if rssManager.articles.isEmpty {
                rssManager.refreshAllFeeds()
            }
        }
    }
    
    private func reliabilityText(for score: Double) -> String {
        switch score {
        case 0.8...1.0: return "Tier 1"
        case 0.6..<0.8: return "Tier 2"
        case 0.4..<0.6: return "Speculation"
        default: return "Unverified"
        }
    }
    
    private func reliabilityColor(for score: Double) -> Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

#Preview {
    SimpleNewsView()
}
