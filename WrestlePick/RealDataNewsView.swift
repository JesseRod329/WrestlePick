import SwiftUI

struct RealDataNewsView: View {
    @StateObject private var newsService = NewsService.shared
    @State private var selectedCategory: NewsCategory? = nil
    @State private var showingFilters = false
    
    var filteredArticles: [NewsArticle] {
        if let category = selectedCategory {
            return newsService.newsArticles.filter { $0.category == category }
        }
        return newsService.newsArticles
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if newsService.isLoading {
                    ProgressView("Loading wrestling news...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredArticles) { article in
                        NewsArticleRow(article: article)
                    }
                    .refreshable {
                        newsService.refreshNews()
                    }
                }
            }
            .navigationTitle("Wrestling News")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filter") {
                        showingFilters = true
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                NewsFilterView(selectedCategory: $selectedCategory)
            }
            .onAppear {
                newsService.loadNews()
            }
        }
    }
}

struct NewsArticleRow: View {
    let article: NewsArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if article.isBreaking {
                    Text("BREAKING")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)
                }
                
                Text(article.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(article.reliability.rawValue)
                    .font(.caption)
                    .foregroundColor(reliabilityColor)
            }
            
            Text(article.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(article.summary)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(article.source)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if !article.tags.isEmpty {
                    Text(article.tags.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text(article.pubDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var categoryColor: Color {
        switch article.category {
        case .breaking: return .red
        case .results: return .green
        case .rumors: return .orange
        case .analysis: return .purple
        case .injuries: return .red
        case .contracts: return .blue
        case .general: return .blue
        }
    }
    
    private var reliabilityColor: Color {
        switch article.reliability {
        case .tier1: return .green
        case .tier2: return .orange
        case .tier3: return .red
        }
    }
}

struct NewsFilterView: View {
    @Binding var selectedCategory: NewsCategory?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Categories") {
                    Button("All Categories") {
                        selectedCategory = nil
                        dismiss()
                    }
                    .foregroundColor(selectedCategory == nil ? .blue : .primary)
                    
                    ForEach(NewsCategory.allCases, id: \.self) { category in
                        Button(category.rawValue) {
                            selectedCategory = category
                            dismiss()
                        }
                        .foregroundColor(selectedCategory == category ? .blue : .primary)
                    }
                }
            }
            .navigationTitle("Filter News")
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
    RealDataNewsView()
}