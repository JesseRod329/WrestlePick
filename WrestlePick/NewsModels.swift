import Foundation

// RSS Feed Source Model
struct RSSFeedSource {
    let name: String
    let url: String
    let category: NewsCategory
    let reliabilityTier: ReliabilityTier
    let isActive: Bool
    let lastFetched: Date?
    let fetchInterval: TimeInterval
    
    init(name: String, url: String, category: NewsCategory, reliabilityTier: ReliabilityTier, isActive: Bool = true) {
        self.name = name
        self.url = url
        self.category = category
        self.reliabilityTier = reliabilityTier
        self.isActive = isActive
        self.lastFetched = nil
        self.fetchInterval = 1800 // 30 minutes
    }
}

// Reliability Tier System
enum ReliabilityTier: String, CaseIterable, Codable {
    case tier1 = "Tier 1"
    case tier2 = "Tier 2"
    case speculation = "Speculation"
    case unverified = "Unverified"
    
    var score: Double {
        switch self {
        case .tier1: return 0.9
        case .tier2: return 0.7
        case .speculation: return 0.4
        case .unverified: return 0.2
        }
    }
    
    var color: String {
        switch self {
        case .tier1: return "green"
        case .tier2: return "blue"
        case .speculation: return "orange"
        case .unverified: return "red"
        }
    }
}

// News Sort Options
enum NewsSortOption: String, CaseIterable, Codable {
    case date = "Date"
    case reliability = "Reliability"
    case popularity = "Popularity"
    case trending = "Trending"
    
    var sortKey: String {
        switch self {
        case .date: return "publishDate"
        case .reliability: return "reliabilityScore"
        case .popularity: return "engagement.views"
        case .trending: return "engagement.shares"
        }
    }
}

// News Filter Options
struct NewsFilter {
    let category: NewsCategory?
    let promotion: String?
    let isRumor: Bool?
    let isBreaking: Bool?
    let minReliabilityScore: Double?
    let dateRange: DateRange?
    
    init(category: NewsCategory? = nil, 
         promotion: String? = nil, 
         isRumor: Bool? = nil, 
         isBreaking: Bool? = nil, 
         minReliabilityScore: Double? = nil,
         dateRange: DateRange? = nil) {
        self.category = category
        self.promotion = promotion
        self.isRumor = isRumor
        self.isBreaking = isBreaking
        self.minReliabilityScore = minReliabilityScore
        self.dateRange = dateRange
    }
}

struct DateRange {
    let startDate: Date
    let endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init(daysAgo: Int) {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: endDate) ?? endDate
        self.init(startDate: startDate, endDate: endDate)
    }
}

// News Categories with Promotions
extension NewsCategory {
    static let promotions: [String] = ["All", "WWE", "AEW", "NJPW", "Impact", "Independent", "General"]
    
    var promotionName: String {
        switch self {
        case .wwe: return "WWE"
        case .aew: return "AEW"
        case .njpw: return "NJPW"
        case .impact: return "Impact"
        case .indie: return "Independent"
        case .general: return "General"
        case .rumors: return "Rumors"
        case .spoilers: return "Spoilers"
        case .backstage: return "Backstage"
        case .business: return "Business"
        }
    }
}

// Offline News Storage
struct OfflineNewsCache {
    let articles: [NewsArticle]
    let lastUpdated: Date
    let cacheExpiry: Date
    
    init(articles: [NewsArticle]) {
        self.articles = articles
        self.lastUpdated = Date()
        self.cacheExpiry = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
    }
    
    var isExpired: Bool {
        return Date() > cacheExpiry
    }
}

// News Share Data
struct NewsShareData {
    let title: String
    let url: String
    let description: String
    let imageURL: String?
    let source: String
    let category: NewsCategory
    
    init(from article: NewsArticle) {
        self.title = article.title
        self.url = article.sourceURL ?? ""
        self.description = article.excerpt
        self.imageURL = article.media.imageURL
        self.source = article.source
        self.category = article.category
    }
}
