import SwiftUI

struct NewsView: View {
    @StateObject private var newsService = NewsService()
    @State private var showingFilters = false
    @State private var showingSearch = false
    @State private var selectedArticle: NewsArticle?
    @State private var showingArticleDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                if showingSearch {
                    SearchBar(text: $newsService.searchText)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Filter Bar
                FilterBar(
                    selectedCategory: $newsService.selectedCategory,
                    selectedPromotion: $newsService.selectedPromotion,
                    showOnlyRumors: $newsService.showOnlyRumors,
                    showOnlyBreaking: $newsService.showOnlyBreaking,
                    sortBy: $newsService.sortBy
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Content
                if newsService.isLoading && newsService.articles.isEmpty {
                    LoadingView()
                } else if newsService.articles.isEmpty {
                    EmptyStateView()
                } else {
                    ArticlesListView(
                        articles: newsService.articles,
                        onArticleTap: { article in
                            selectedArticle = article
                            showingArticleDetail = true
                        },
                        onShare: { article in
                            newsService.shareArticle(article)
                        },
                        onBookmark: { article in
                            newsService.bookmarkArticle(article.id ?? "")
                        },
                        onLike: { article in
                            newsService.likeArticle(article.id ?? "")
                        }
                    )
                }
            }
            .navigationTitle("News")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                showingSearch.toggle()
                            }
                        }) {
                            Image(systemName: showingSearch ? "xmark" : "magnifyingglass")
                        }
                        
                        Button(action: {
                            showingFilters = true
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            .refreshable {
                newsService.pullToRefresh()
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(
                    selectedCategory: $newsService.selectedCategory,
                    selectedPromotion: $newsService.selectedPromotion,
                    showOnlyRumors: $newsService.showOnlyRumors,
                    showOnlyBreaking: $newsService.showOnlyBreaking,
                    sortBy: $newsService.sortBy
                )
            }
            .sheet(isPresented: $showingArticleDetail) {
                if let article = selectedArticle {
                    ArticleDetailView(article: article)
                }
            }
            .onAppear {
                newsService.loadOfflineArticles()
                if newsService.articles.isEmpty {
                    newsService.fetchArticles()
                }
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search news...", text: $text)
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

// MARK: - Filter Bar
struct FilterBar: View {
    @Binding var selectedCategory: NewsCategory
    @Binding var selectedPromotion: String
    @Binding var showOnlyRumors: Bool
    @Binding var showOnlyBreaking: Bool
    @Binding var sortBy: NewsSortOption
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(NewsCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Promotion Filter
                Picker("Promotion", selection: $selectedPromotion) {
                    ForEach(NewsCategory.promotions, id: \.self) { promotion in
                        Text(promotion).tag(promotion)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Rumor Toggle
                Button(action: {
                    showOnlyRumors.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showOnlyRumors ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                        Text("Rumors")
                    }
                    .font(.caption)
                    .foregroundColor(showOnlyRumors ? .orange : .secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(showOnlyRumors ? Color.orange.opacity(0.2) : Color(.systemGray6))
                .cornerRadius(8)
                
                // Breaking News Toggle
                Button(action: {
                    showOnlyBreaking.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showOnlyBreaking ? "flame.fill" : "flame")
                        Text("Breaking")
                    }
                    .font(.caption)
                    .foregroundColor(showOnlyBreaking ? .red : .secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(showOnlyBreaking ? Color.red.opacity(0.2) : Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Articles List
struct ArticlesListView: View {
    let articles: [NewsArticle]
    let onArticleTap: (NewsArticle) -> Void
    let onShare: (NewsArticle) -> Void
    let onBookmark: (NewsArticle) -> Void
    let onLike: (NewsArticle) -> Void
    
    var body: some View {
        List {
            ForEach(articles) { article in
                NewsCardView(
                    article: article,
                    onTap: {
                        onArticleTap(article)
                    },
                    onShare: {
                        onShare(article)
                    },
                    onBookmark: {
                        onBookmark(article)
                    },
                    onLike: {
                        onLike(article)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading latest news...")
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
            Image(systemName: "newspaper")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No articles found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try adjusting your filters or check back later for new content")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Binding var selectedCategory: NewsCategory
    @Binding var selectedPromotion: String
    @Binding var showOnlyRumors: Bool
    @Binding var showOnlyBreaking: Bool
    @Binding var sortBy: NewsSortOption
    
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
                }
                
                Section("Promotion") {
                    Picker("Promotion", selection: $selectedPromotion) {
                        ForEach(NewsCategory.promotions, id: \.self) { promotion in
                            Text(promotion).tag(promotion)
                        }
                    }
                }
                
                Section("Content Type") {
                    Toggle("Show only rumors", isOn: $showOnlyRumors)
                    Toggle("Show only breaking news", isOn: $showOnlyBreaking)
                }
                
                Section("Sort By") {
                    Picker("Sort By", selection: $sortBy) {
                        ForEach(NewsSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resetFilters() {
        selectedCategory = .general
        selectedPromotion = "All"
        showOnlyRumors = false
        showOnlyBreaking = false
        sortBy = .date
    }
}

// MARK: - Article Detail View
struct ArticleDetailView: View {
    let article: NewsArticle
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text(article.source)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(article.publishDate, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Content
                    Text(article.content)
                        .font(.body)
                        .lineSpacing(4)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Article")
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
