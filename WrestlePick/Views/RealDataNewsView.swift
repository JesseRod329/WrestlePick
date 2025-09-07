import SwiftUI

struct RealDataNewsView: View {
    @EnvironmentObject var rssManager: RSSFeedManager
    @EnvironmentObject var breakingNewsDetector: BreakingNewsDetector
    @State private var selectedCategory: NewsCategory = .all
    @State private var searchText = ""
    @State private var showingBreakingNews = false
    
    var filteredArticles: [NewsArticle] {
        var articles = rssManager.articles
        
        // Filter by category
        if selectedCategory != .all {
            articles = articles.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            articles = articles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                article.author?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return articles
    }
    
    var breakingNewsArticles: [NewsArticle] {
        rssManager.articles.filter { $0.isBreaking }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Breaking News Banner
                if !breakingNewsArticles.isEmpty {
                    BreakingNewsBanner(articles: breakingNewsArticles)
                        .onTapGesture {
                            showingBreakingNews = true
                        }
                }
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Category Filter
                CategoryFilter(selectedCategory: $selectedCategory)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Articles List
                if rssManager.isLoading {
                    LoadingView()
                } else if filteredArticles.isEmpty {
                    EmptyStateView(
                        title: "No Articles Found",
                        message: searchText.isEmpty ? "No articles available at the moment." : "No articles match your search.",
                        systemImage: "newspaper"
                    )
                } else {
                    ArticlesList(articles: filteredArticles)
                }
            }
            .navigationTitle("Wrestling News")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        rssManager.refreshAllFeeds()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(rssManager.isLoading)
                }
            }
            .sheet(isPresented: $showingBreakingNews) {
                BreakingNewsView(articles: breakingNewsArticles)
            }
        }
    }
}

struct BreakingNewsBanner: View {
    let articles: [NewsArticle]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("BREAKING NEWS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                Spacer()
                Text("\(articles.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            if let latestBreaking = articles.first {
                Text(latestBreaking.title)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.red),
            alignment: .bottom
        )
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search articles...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
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

struct CategoryFilter: View {
    @Binding var selectedCategory: NewsCategory
    
    let categories: [NewsCategory] = [.all, .breaking, .news, .rumors, .results, .analysis, .injuries, .contracts]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryButton(
                        title: category.displayName,
                        isSelected: selectedCategory == category,
                        action: {
                            selectedCategory = category
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ArticlesList: View {
    let articles: [NewsArticle]
    
    var body: some View {
        List(articles) { article in
            ArticleRow(article: article)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(PlainListStyle())
    }
}

struct ArticleRow: View {
    let article: NewsArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    if let author = article.author {
                        Text("By \(author)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ReliabilityBadge(reliability: article.source.reliability)
                    
                    Text(article.publishDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(article.content)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            HStack {
                CategoryTag(category: article.category)
                
                if !article.promotions.isEmpty {
                    PromotionTags(promotions: article.promotions)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        // Toggle like
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: article.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(article.isLiked ? .red : .secondary)
                            Text("\(article.likes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // Toggle bookmark
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(article.isBookmarked ? .blue : .secondary)
                        }
                    }
                    
                    Button(action: {
                        // Share
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.secondary)
                            Text("\(article.shares)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CategoryTag: View {
    let category: NewsCategory
    
    var body: some View {
        Text(category.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(category.color.opacity(0.2))
            .foregroundColor(category.color)
            .clipShape(Capsule())
    }
}

struct PromotionTags: View {
    let promotions: [WrestlingPromotion]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(promotions.prefix(3), id: \.self) { promotion in
                Text(promotion.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(promotion.color.opacity(0.2))
                    .foregroundColor(promotion.color)
                    .clipShape(Capsule())
            }
            
            if promotions.count > 3 {
                Text("+\(promotions.count - 3)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BreakingNewsView: View {
    let articles: [NewsArticle]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(articles) { article in
                ArticleRow(article: article)
            }
            .navigationTitle("Breaking News")
            .navigationBarTitleDisplayMode(.large)
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

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading latest wrestling news...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Extensions
extension NewsCategory {
    var displayName: String {
        switch self {
        case .all: return "All"
        case .breaking: return "Breaking"
        case .news: return "News"
        case .rumors: return "Rumors"
        case .results: return "Results"
        case .analysis: return "Analysis"
        case .injuries: return "Injuries"
        case .contracts: return "Contracts"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .breaking: return .red
        case .news: return .blue
        case .rumors: return .orange
        case .results: return .green
        case .analysis: return .purple
        case .injuries: return .red
        case .contracts: return .yellow
        }
    }
}

extension WrestlingPromotion {
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

#Preview {
    RealDataNewsView()
        .environmentObject(RSSFeedManager.shared)
        .environmentObject(BreakingNewsDetector.shared)
}
