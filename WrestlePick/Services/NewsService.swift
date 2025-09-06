import Foundation
import Combine
import FirebaseFirestore
import UserNotifications

class NewsService: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var breakingNews: [NewsArticle] = []
    @Published var rumors: [NewsArticle] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var selectedCategory: NewsCategory = .general
    @Published var selectedPromotion: String = "All"
    @Published var searchText = ""
    @Published var showOnlyRumors = false
    @Published var showOnlyBreaking = false
    @Published var sortBy: NewsSortOption = .date
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    private let rssService = RSSFeedService()
    private let notificationService = PushNotificationService.shared
    private var refreshTimer: Timer?
    
    // RSS Feed Sources with reliability scores
    private let rssFeeds: [RSSFeedSource] = [
        RSSFeedSource(
            name: "Wrestling Observer",
            url: "https://www.f4wonline.com/feeds/all",
            category: .general,
            reliabilityTier: .tier1,
            isActive: true
        ),
        RSSFeedSource(
            name: "Fightful",
            url: "https://www.fightful.com/rss.xml",
            category: .general,
            reliabilityTier: .tier1,
            isActive: true
        ),
        RSSFeedSource(
            name: "Cageside Seats",
            url: "https://www.cagesideseats.com/rss/index.xml",
            category: .general,
            reliabilityTier: .tier2,
            isActive: true
        ),
        RSSFeedSource(
            name: "WWE News",
            url: "https://www.wwe.com/news/rss.xml",
            category: .wwe,
            reliabilityTier: .tier1,
            isActive: true
        ),
        RSSFeedSource(
            name: "AEW News",
            url: "https://www.allelitewrestling.com/news/rss.xml",
            category: .aew,
            reliabilityTier: .tier1,
            isActive: true
        )
    ]
    
    init() {
        setupRSSFeeds()
        setupRefreshTimer()
        setupSearchFiltering()
        fetchArticles()
    }
    
    // MARK: - Setup Methods
    private func setupRSSFeeds() {
        for feed in rssFeeds {
            let rssFeed = RSSFeed(
                name: feed.name,
                url: feed.url,
                description: "\(feed.name) RSS Feed",
                category: feed.category
            )
            rssService.addFeed(rssFeed)
        }
    }
    
    private func setupRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refreshFeeds()
        }
    }
    
    private func setupSearchFiltering() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        $selectedCategory
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        $selectedPromotion
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        $showOnlyRumors
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        $showOnlyBreaking
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Fetching
    func fetchArticles(limit: Int = 50) {
        isLoading = true
        error = nil
        
        var query = db.collection(FirestoreCollections.newsArticles)
            .whereField("status", isEqualTo: "published")
            .order(by: sortBy.sortKey, descending: true)
            .limit(to: limit)
        
        // Apply filters
        if selectedCategory != .general {
            query = query.whereField("category", isEqualTo: selectedCategory.rawValue)
        }
        
        if selectedPromotion != "All" {
            query = query.whereField("tags", arrayContains: selectedPromotion)
        }
        
        if showOnlyRumors {
            query = query.whereField("isRumor", isEqualTo: true)
        }
        
        if showOnlyBreaking {
            query = query.whereField("isBreaking", isEqualTo: true)
        }
        
        query.getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error
                } else {
                    let fetchedArticles = snapshot?.documents.compactMap { document in
                        try? document.data(as: NewsArticle.self)
                    } ?? []
                    
                    self?.articles = fetchedArticles
                    self?.categorizeArticles(fetchedArticles)
                    self?.cacheArticlesForOffline(fetchedArticles)
                }
                self?.isLoading = false
            }
        }
    }
    
    func refreshFeeds() {
        isRefreshing = true
        rssService.processAllFeeds()
        
        // Fetch updated articles after processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.fetchArticles()
            self.isRefreshing = false
        }
    }
    
    func pullToRefresh() {
        refreshFeeds()
    }
    
    func fetchArticlesByCategory(_ category: NewsCategory, limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("category", isEqualTo: category.rawValue)
            .whereField("status", isEqualTo: "published")
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func searchArticles(query: String, limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("title", isGreaterThanOrEqualTo: query)
            .whereField("title", isLessThan: query + "\u{f8ff}")
            .whereField("status", isEqualTo: "published")
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchRumorArticles(limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("isRumor", isEqualTo: true)
            .whereField("status", isEqualTo: "published")
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchBreakingNews(limit: Int = 20) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("isBreaking", isEqualTo: true)
            .whereField("status", isEqualTo: "published")
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchHighReliabilityArticles(minScore: Double = 0.7, limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("reliabilityScore", isGreaterThanOrEqualTo: minScore)
            .whereField("status", isEqualTo: "published")
            .order(by: "reliabilityScore", descending: true)
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func likeArticle(_ articleId: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let likeData = [
            "userId": currentUser.id ?? "",
            "articleId": articleId,
            "timestamp": Date()
        ] as [String : Any]
        
        db.collection("likes")
            .addDocument(data: likeData) { error in
                if let error = error {
                    print("Error liking article: \(error)")
                }
            }
    }
    
    func bookmarkArticle(_ articleId: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let bookmarkData = [
            "userId": currentUser.id ?? "",
            "articleId": articleId,
            "timestamp": Date()
        ] as [String : Any]
        
        db.collection("bookmarks")
            .addDocument(data: bookmarkData) { error in
                if let error = error {
                    print("Error bookmarking article: \(error)")
                }
            }
    }
    
    func shareArticle(_ articleId: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let shareData = [
            "userId": currentUser.id ?? "",
            "articleId": articleId,
            "timestamp": Date()
        ] as [String : Any]
        
        db.collection("shares")
            .addDocument(data: shareData) { error in
                if let error = error {
                    print("Error sharing article: \(error)")
                }
            }
    }
    
    func reportArticle(_ articleId: String, reason: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let reportData = [
            "userId": currentUser.id ?? "",
            "articleId": articleId,
            "reason": reason,
            "timestamp": Date(),
            "status": "pending"
        ] as [String : Any]
        
        db.collection("reports")
            .addDocument(data: reportData) { error in
                if let error = error {
                    print("Error reporting article: \(error)")
                }
            }
    }
    
    // MARK: - Filtering and Search
    private func applyFilters() {
        var filteredArticles = articles
        
        // Apply search filter
        if !searchText.isEmpty {
            filteredArticles = filteredArticles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                article.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply category filter
        if selectedCategory != .general {
            filteredArticles = filteredArticles.filter { $0.category == selectedCategory }
        }
        
        // Apply promotion filter
        if selectedPromotion != "All" {
            filteredArticles = filteredArticles.filter { article in
                article.tags.contains(selectedPromotion) || article.category.promotionName == selectedPromotion
            }
        }
        
        // Apply rumor filter
        if showOnlyRumors {
            filteredArticles = filteredArticles.filter { $0.isRumor }
        }
        
        // Apply breaking news filter
        if showOnlyBreaking {
            filteredArticles = filteredArticles.filter { $0.isBreaking }
        }
        
        // Apply sorting
        filteredArticles = sortArticles(filteredArticles, by: sortBy)
        
        self.articles = filteredArticles
        categorizeArticles(filteredArticles)
    }
    
    private func sortArticles(_ articles: [NewsArticle], by sortOption: NewsSortOption) -> [NewsArticle] {
        switch sortOption {
        case .date:
            return articles.sorted { $0.publishDate > $1.publishDate }
        case .reliability:
            return articles.sorted { $0.reliabilityScore > $1.reliabilityScore }
        case .popularity:
            return articles.sorted { $0.engagement.views > $1.engagement.views }
        case .trending:
            return articles.sorted { $0.engagement.shares > $1.engagement.shares }
        }
    }
    
    private func categorizeArticles(_ articles: [NewsArticle]) {
        breakingNews = articles.filter { $0.isBreaking }
        rumors = articles.filter { $0.isRumor }
    }
    
    // MARK: - Offline Support
    private func cacheArticlesForOffline(_ articles: [NewsArticle]) {
        let cache = OfflineNewsCache(articles: articles)
        UserDefaults.standard.set(try? JSONEncoder().encode(cache), forKey: "offline_news_cache")
    }
    
    func loadOfflineArticles() {
        guard let data = UserDefaults.standard.data(forKey: "offline_news_cache"),
              let cache = try? JSONDecoder().decode(OfflineNewsCache.self, from: data),
              !cache.isExpired else { return }
        
        articles = cache.articles
        categorizeArticles(cache.articles)
    }
    
    // MARK: - Push Notifications
    func checkForBreakingNews() {
        fetchBreakingNews { [weak self] breakingArticles in
            for article in breakingArticles {
                self?.sendBreakingNewsNotification(article)
            }
        }
    }
    
    private func sendBreakingNewsNotification(_ article: NewsArticle) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 Breaking News"
        content.body = article.title
        content.sound = .default
        content.userInfo = [
            "type": "breaking_news",
            "articleId": article.id ?? "",
            "category": article.category.rawValue
        ]
        
        let request = UNNotificationRequest(
            identifier: "breaking_\(article.id ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending breaking news notification: \(error)")
            }
        }
    }
    
    // MARK: - Share Functionality
    func shareArticle(_ article: NewsArticle) -> NewsShareData {
        return NewsShareData(from: article)
    }
    
    func generateShareLink(for article: NewsArticle) -> String {
        let baseURL = "https://wrestlepick.app/news"
        let articleId = article.id ?? UUID().uuidString
        return "\(baseURL)/\(articleId)"
    }
    
    // MARK: - Reliability Scoring
    func calculateReliabilityScore(for article: NewsArticle) -> Double {
        var score = 0.5 // Base score
        
        // Source reliability
        if let sourceTier = rssFeeds.first(where: { $0.name == article.source })?.reliabilityTier {
            score = sourceTier.score
        }
        
        // Content indicators
        if article.isVerified {
            score += 0.2
        }
        
        if article.isBreaking {
            score += 0.1
        }
        
        if article.isRumor {
            score -= 0.3
        }
        
        // Engagement quality
        let engagementScore = min(article.engagement.likes / max(article.engagement.views, 1), 0.1)
        score += engagementScore
        
        return max(0.0, min(1.0, score))
    }
    
    // MARK: - Cleanup
    deinit {
        refreshTimer?.invalidate()
    }
}
