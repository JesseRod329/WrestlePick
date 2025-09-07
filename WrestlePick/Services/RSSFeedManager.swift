import Foundation
import FeedKit
import Combine
import os.log

class RSSFeedManager: ObservableObject {
    static let shared = RSSFeedManager()
    
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var error: Error?
    
    private let logger = Logger(subsystem: "com.wrestlepick", category: "RSSFeed")
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // RSS Feed Sources with reliability tiers
    private let rssFeeds: [RSSFeedSource] = [
        // Tier 1 - High Reliability
        RSSFeedSource(
            name: "Wrestling Observer Newsletter",
            url: "https://www.f4wonline.com/rss",
            reliability: .tier1,
            category: .news,
            promotions: [.wwe, .aew, .njpw, .impact, .indie]
        ),
        RSSFeedSource(
            name: "PWTorch",
            url: "https://www.pwtorch.com/rss",
            reliability: .tier1,
            category: .news,
            promotions: [.wwe, .aew, .njpw, .impact, .indie]
        ),
        RSSFeedSource(
            name: "Fightful",
            url: "https://www.fightful.com/rss",
            reliability: .tier1,
            category: .news,
            promotions: [.wwe, .aew, .njpw, .impact, .indie]
        ),
        RSSFeedSource(
            name: "Wrestling Inc",
            url: "https://www.wrestlinginc.com/rss",
            reliability: .tier1,
            category: .news,
            promotions: [.wwe, .aew, .njpw, .impact, .indie]
        ),
        
        // Tier 2 - Medium Reliability
        RSSFeedSource(
            name: "Cageside Seats",
            url: "https://www.cagesideseats.com/rss",
            reliability: .tier2,
            category: .analysis,
            promotions: [.wwe, .aew, .njpw]
        ),
        RSSFeedSource(
            name: "WrestleTalk",
            url: "https://wrestletalk.com/rss",
            reliability: .tier2,
            category: .rumors,
            promotions: [.wwe, .aew, .njpw, .impact]
        ),
        RSSFeedSource(
            name: "POST Wrestling",
            url: "https://www.postwrestling.com/rss",
            reliability: .tier2,
            category: .analysis,
            promotions: [.wwe, .aew, .njpw, .impact]
        ),
        RSSFeedSource(
            name: "Wrestling News",
            url: "https://wrestlingnews.co/rss",
            reliability: .tier2,
            category: .rumors,
            promotions: [.wwe, .aew, .njpw, .impact, .indie]
        ),
        
        // Promotion-Specific Sources
        RSSFeedSource(
            name: "WWE Official",
            url: "https://www.wwe.com/rss",
            reliability: .tier1,
            category: .news,
            promotions: [.wwe]
        ),
        RSSFeedSource(
            name: "AEW Official",
            url: "https://www.allelitewrestling.com/rss",
            reliability: .tier1,
            category: .news,
            promotions: [.aew]
        ),
        RSSFeedSource(
            name: "NJPW Official",
            url: "https://www.njpw1972.com/rss",
            reliability: .tier1,
            category: .news,
            promotions: [.njpw]
        )
    ]
    
    private init() {
        startPeriodicRefresh()
        loadCachedArticles()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func refreshAllFeeds() {
        isLoading = true
        error = nil
        
        let group = DispatchGroup()
        var allArticles: [NewsArticle] = []
        let queue = DispatchQueue(label: "rss.parsing", qos: .utility)
        
        for feed in rssFeeds {
            group.enter()
            
            queue.async {
                self.fetchFeed(feed) { result in
                    switch result {
                    case .success(let articles):
                        allArticles.append(contentsOf: articles)
                    case .failure(let error):
                        self.logger.error("Failed to fetch \(feed.name): \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.processArticles(allArticles)
            self.isLoading = false
            self.lastUpdateTime = Date()
        }
    }
    
    func fetchFeed(_ source: RSSFeedSource, completion: @escaping (Result<[NewsArticle], Error>) -> Void) {
        guard let url = URL(string: source.url) else {
            completion(.failure(RSSError.invalidURL))
            return
        }
        
        let parser = FeedParser(URL: url)
        parser.parseAsync { result in
            switch result {
            case .success(let feed):
                let articles = self.parseFeed(feed, source: source)
                completion(.success(articles))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    private func startPeriodicRefresh() {
        // Refresh every 15 minutes for Tier 1 sources, every 30 minutes for others
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            self?.refreshAllFeeds()
        }
    }
    
    private func parseFeed(_ feed: Feed, source: RSSFeedSource) -> [NewsArticle] {
        var articles: [NewsArticle] = []
        
        switch feed {
        case .rss(let rssFeed):
            articles = parseRSSFeed(rssFeed, source: source)
        case .atom(let atomFeed):
            articles = parseAtomFeed(atomFeed, source: source)
        case .json(let jsonFeed):
            articles = parseJSONFeed(jsonFeed, source: source)
        }
        
        return articles
    }
    
    private func parseRSSFeed(_ feed: RSSFeed, source: RSSFeedSource) -> [NewsArticle] {
        guard let items = feed.items else { return [] }
        
        return items.compactMap { item in
            guard let title = item.title,
                  let link = item.link,
                  let pubDate = item.pubDate else { return nil }
            
            let content = item.description ?? item.content?.content ?? ""
            let categories = item.categories?.compactMap { $0.value } ?? []
            let author = item.author ?? source.name
            
            return NewsArticle(
                id: UUID().uuidString,
                title: title,
                content: content,
                source: NewsSource(
                    name: source.name,
                    url: source.url,
                    reliability: source.reliability
                ),
                category: categorizeContent(title: title, content: content, categories: categories),
                promotions: extractPromotions(from: title, content: content, categories: categories),
                publishDate: pubDate,
                author: author,
                imageURL: extractImageURL(from: content),
                tags: categories,
                isBreaking: detectBreakingNews(title: title, content: content),
                isVerified: source.reliability == .tier1,
                likes: 0,
                shares: 0,
                comments: 0,
                isLiked: false,
                isBookmarked: false,
                isShared: false
            )
        }
    }
    
    private func parseAtomFeed(_ feed: AtomFeed, source: RSSFeedSource) -> [NewsArticle] {
        guard let entries = feed.entries else { return [] }
        
        return entries.compactMap { entry in
            guard let title = entry.title?.value,
                  let link = entry.links?.first?.attributes?.href,
                  let published = entry.published else { return nil }
            
            let content = entry.content?.value ?? entry.summary?.value ?? ""
            let categories = entry.categories?.compactMap { $0.term } ?? []
            let author = entry.authors?.first?.name ?? source.name
            
            return NewsArticle(
                id: UUID().uuidString,
                title: title,
                content: content,
                source: NewsSource(
                    name: source.name,
                    url: source.url,
                    reliability: source.reliability
                ),
                category: categorizeContent(title: title, content: content, categories: categories),
                promotions: extractPromotions(from: title, content: content, categories: categories),
                publishDate: published,
                author: author,
                imageURL: extractImageURL(from: content),
                tags: categories,
                isBreaking: detectBreakingNews(title: title, content: content),
                isVerified: source.reliability == .tier1,
                likes: 0,
                shares: 0,
                comments: 0,
                isLiked: false,
                isBookmarked: false,
                isShared: false
            )
        }
    }
    
    private func parseJSONFeed(_ feed: JSONFeed, source: RSSFeedSource) -> [NewsArticle] {
        guard let items = feed.items else { return [] }
        
        return items.compactMap { item in
            guard let title = item.title,
                  let url = item.url,
                  let datePublished = item.datePublished else { return nil }
            
            let content = item.contentText ?? item.contentHtml ?? ""
            let categories = item.tags ?? []
            let author = item.authors?.first?.name ?? source.name
            
            return NewsArticle(
                id: UUID().uuidString,
                title: title,
                content: content,
                source: NewsSource(
                    name: source.name,
                    url: source.url,
                    reliability: source.reliability
                ),
                category: categorizeContent(title: title, content: content, categories: categories),
                promotions: extractPromotions(from: title, content: content, categories: categories),
                publishDate: datePublished,
                author: author,
                imageURL: item.imageURL,
                tags: categories,
                isBreaking: detectBreakingNews(title: title, content: content),
                isVerified: source.reliability == .tier1,
                likes: 0,
                shares: 0,
                comments: 0,
                isLiked: false,
                isBookmarked: false,
                isShared: false
            )
        }
    }
    
    private func categorizeContent(title: String, content: String, categories: [String]) -> NewsCategory {
        let text = "\(title) \(content)".lowercased()
        
        // Breaking news keywords
        if text.contains("breaking") || text.contains("exclusive") || text.contains("confirmed") {
            return .breaking
        }
        
        // Results keywords
        if text.contains("results") || text.contains("recap") || text.contains("review") {
            return .results
        }
        
        // Rumors keywords
        if text.contains("rumor") || text.contains("report") || text.contains("speculation") {
            return .rumors
        }
        
        // Analysis keywords
        if text.contains("analysis") || text.contains("opinion") || text.contains("editorial") {
            return .analysis
        }
        
        // Injury keywords
        if text.contains("injury") || text.contains("injured") || text.contains("medical") {
            return .injuries
        }
        
        // Contract keywords
        if text.contains("contract") || text.contains("signed") || text.contains("released") {
            return .contracts
        }
        
        return .news
    }
    
    private func extractPromotions(from title: String, content: String, categories: [String]) -> [WrestlingPromotion] {
        let text = "\(title) \(content) \(categories.joined(separator: " "))".lowercased()
        var promotions: Set<WrestlingPromotion> = []
        
        if text.contains("wwe") || text.contains("world wrestling entertainment") {
            promotions.insert(.wwe)
        }
        if text.contains("aew") || text.contains("all elite wrestling") {
            promotions.insert(.aew)
        }
        if text.contains("njpw") || text.contains("new japan") {
            promotions.insert(.njpw)
        }
        if text.contains("impact") || text.contains("tna") {
            promotions.insert(.impact)
        }
        if text.contains("roh") || text.contains("ring of honor") {
            promotions.insert(.roh)
        }
        if text.contains("indie") || text.contains("independent") {
            promotions.insert(.indie)
        }
        
        return Array(promotions)
    }
    
    private func extractImageURL(from content: String) -> String? {
        // Simple regex to extract image URLs from HTML content
        let pattern = #"<img[^>]+src="([^"]+)""#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range),
           let imageRange = Range(match.range(at: 1), in: content) {
            return String(content[imageRange])
        }
        
        return nil
    }
    
    private func detectBreakingNews(title: String, content: String) -> Bool {
        let text = "\(title) \(content)".lowercased()
        let breakingKeywords = ["breaking", "exclusive", "confirmed", "urgent", "just in"]
        
        return breakingKeywords.contains { text.contains($0) }
    }
    
    private func processArticles(_ newArticles: [NewsArticle]) {
        // Remove duplicates based on title similarity
        let uniqueArticles = removeDuplicates(newArticles)
        
        // Sort by publish date (newest first)
        let sortedArticles = uniqueArticles.sorted { $0.publishDate > $1.publishDate }
        
        // Update published articles
        DispatchQueue.main.async {
            self.articles = sortedArticles
            self.cacheArticles(sortedArticles)
            
            // Check for breaking news and send notifications
            self.checkForBreakingNews(sortedArticles)
        }
    }
    
    private func removeDuplicates(_ articles: [NewsArticle]) -> [NewsArticle] {
        var uniqueArticles: [NewsArticle] = []
        var seenTitles: Set<String> = []
        
        for article in articles {
            let normalizedTitle = article.title.lowercased()
                .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
            
            if !seenTitles.contains(normalizedTitle) {
                seenTitles.insert(normalizedTitle)
                uniqueArticles.append(article)
            }
        }
        
        return uniqueArticles
    }
    
    private func checkForBreakingNews(_ articles: [NewsArticle]) {
        let breakingArticles = articles.filter { $0.isBreaking }
        
        for article in breakingArticles {
            // Send push notification for breaking news
            PushNotificationService.shared.sendBreakingNewsNotification(article)
        }
    }
    
    private func cacheArticles(_ articles: [NewsArticle]) {
        // Cache articles for offline access
        NewsCache.shared.cacheArticles(articles)
    }
    
    private func loadCachedArticles() {
        if let cachedArticles = NewsCache.shared.getCachedArticles() {
            articles = cachedArticles
        }
    }
}

// MARK: - Supporting Types
struct RSSFeedSource {
    let name: String
    let url: String
    let reliability: ReliabilityTier
    let category: NewsCategory
    let promotions: [WrestlingPromotion]
}

enum RSSError: LocalizedError {
    case invalidURL
    case parsingFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RSS feed URL"
        case .parsingFailed:
            return "Failed to parse RSS feed"
        case .networkError:
            return "Network error while fetching RSS feed"
        }
    }
}

// MARK: - News Source Extension
extension NewsSource {
    init(name: String, url: String, reliability: ReliabilityTier) {
        self.name = name
        self.url = url
        self.reliability = reliability
        self.isVerified = reliability == .tier1
        self.establishedDate = Date()
        self.contactInfo = nil
    }
}
