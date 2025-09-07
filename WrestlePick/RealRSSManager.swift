import Foundation
import Combine

class RealRSSManager: ObservableObject {
    static let shared = RealRSSManager()
    
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // Real RSS Feed Sources with actual URLs
    private let rssFeeds: [RSSFeedSource] = [
        // Tier 1 - Gold Standard Sources
        RSSFeedSource(
            name: "Wrestling Observer / F4W Online",
            url: "https://www.f4wonline.com/rss",
            reliability: .tier1,
            category: .general,
            promotions: [.wwe, .aew, .njpw, .impact, .indie],
            notes: "Dave Meltzer's Wrestling Observer, most respected source"
        ),
        RSSFeedSource(
            name: "PWTorch",
            url: "https://pwtorch.com/feed",
            reliability: .tier1,
            category: .analysis,
            promotions: [.wwe, .aew],
            notes: "Wade Keller's operation, very reliable"
        ),
        RSSFeedSource(
            name: "Fightful",
            url: "https://www.fightful.com/rss",
            reliability: .tier1,
            category: .general,
            promotions: [.wwe, .aew],
            notes: "Sean Ross Sapp, breaking news specialist"
        ),
        
        // Additional Tier 1 Sources
        RSSFeedSource(
            name: "WWE Official",
            url: "https://www.wwe.com/rss",
            reliability: .tier1,
            category: .general,
            promotions: [.wwe],
            notes: "Official WWE news and updates"
        ),
        RSSFeedSource(
            name: "AEW Official",
            url: "https://www.allelitewrestling.com/rss",
            reliability: .tier1,
            category: .general,
            promotions: [.aew],
            notes: "Official AEW news and updates"
        ),
        RSSFeedSource(
            name: "NJPW Official",
            url: "https://www.njpw1972.com/rss",
            reliability: .tier1,
            category: .general,
            promotions: [.njpw],
            notes: "Official NJPW news and updates"
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
                        print("Failed to fetch \(feed.name): \(error.localizedDescription)")
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
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(RSSError.noData))
                return
            }
            
            // Parse RSS XML
            let parser = XMLParser(data: data)
            let rssParser = RSSParser(source: source)
            parser.delegate = rssParser
            
            if parser.parse() {
                completion(.success(rssParser.articles))
            } else {
                completion(.failure(RSSError.parsingFailed))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Private Methods
    private func startPeriodicRefresh() {
        // Refresh every 15 minutes for Tier 1 sources
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            self?.refreshAllFeeds()
        }
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
            print("📢 Breaking News: \(article.title)")
        }
    }
    
    private func cacheArticles(_ articles: [NewsArticle]) {
        // Cache articles for offline access
        if let data = try? JSONEncoder().encode(articles) {
            UserDefaults.standard.set(data, forKey: "cached_news_articles")
        }
    }
    
    private func loadCachedArticles() {
        if let data = UserDefaults.standard.data(forKey: "cached_news_articles"),
           let cachedArticles = try? JSONDecoder().decode([NewsArticle].self, from: data) {
            articles = cachedArticles
        }
    }
}

// MARK: - RSS Parser
class RSSParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentItem: [String: String] = [:]
    var articles: [NewsArticle] = []
    private let source: RSSFeedSource
    
    init(source: RSSFeedSource) {
        self.source = source
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            currentItem = [:]
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedString.isEmpty else { return }
        
        switch currentElement {
        case "title":
            currentItem["title"] = (currentItem["title"] ?? "") + trimmedString
        case "description":
            currentItem["description"] = (currentItem["description"] ?? "") + trimmedString
        case "content:encoded":
            currentItem["content"] = (currentItem["content"] ?? "") + trimmedString
        case "link":
            currentItem["link"] = (currentItem["link"] ?? "") + trimmedString
        case "guid":
            currentItem["guid"] = (currentItem["guid"] ?? "") + trimmedString
        case "pubDate":
            currentItem["pubDate"] = (currentItem["pubDate"] ?? "") + trimmedString
        case "author":
            currentItem["author"] = (currentItem["author"] ?? "") + trimmedString
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item", !currentItem.isEmpty {
            if let article = createArticle(from: currentItem) {
                articles.append(article)
            }
            currentItem = [:]
        }
        currentElement = ""
    }
    
    private func createArticle(from item: [String: String]) -> NewsArticle? {
        guard let title = item["title"],
              let link = item["link"],
              let pubDateString = item["pubDate"] else { return nil }
        
        let content = item["content"] ?? item["description"] ?? ""
        let author = item["author"] ?? source.name
        
        // Parse date
        let pubDate = parseDate(pubDateString) ?? Date()
        
        // Categorize content
        let category = categorizeContent(title: title, content: content)
        
        // Extract promotions
        let promotions = extractPromotions(from: title, content: content)
        
        // Detect breaking news
        let isBreaking = detectBreakingNews(title: title, content: content)
        
        // Extract image URL
        let imageURL = extractImageURL(from: content)
        
        // Generate tags
        let tags = generateTags(from: title, content: content, category: category)
        
        return NewsArticle(
            title: title,
            content: content,
            source: NewsSource(name: source.name, url: source.url, reliability: source.reliability),
            category: category,
            promotions: promotions,
            author: author,
            imageURL: imageURL,
            tags: tags,
            isBreaking: isBreaking,
            isVerified: source.reliability == .tier1
        )
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for formatter in formatters {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = formatter
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func categorizeContent(title: String, content: String) -> NewsCategory {
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
        
        return .general
    }
    
    private func extractPromotions(from title: String, content: String) -> [WrestlingPromotion] {
        let text = "\(title) \(content)".lowercased()
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
    
    private func generateTags(from title: String, content: String, category: NewsCategory) -> [String] {
        var tags: Set<String> = []
        
        // Add category as tag
        tags.insert(category.rawValue)
        
        // Add common wrestling terms
        let wrestlingTerms = ["championship", "title", "match", "wrestler", "promotion", "event", "show"]
        let text = "\(title) \(content)".lowercased()
        
        for term in wrestlingTerms {
            if text.contains(term) {
                tags.insert(term)
            }
        }
        
        return Array(tags)
    }
}

// MARK: - Supporting Types
struct RSSFeedSource {
    let name: String
    let url: String
    let reliability: ReliabilityTier
    let category: NewsCategory
    let promotions: [WrestlingPromotion]
    let notes: String
}

enum RSSError: LocalizedError {
    case invalidURL
    case noData
    case parsingFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RSS feed URL"
        case .noData:
            return "No data received from RSS feed"
        case .parsingFailed:
            return "Failed to parse RSS feed"
        case .networkError:
            return "Network error while fetching RSS feed"
        }
    }
}
