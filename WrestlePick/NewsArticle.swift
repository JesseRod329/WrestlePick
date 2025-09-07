import Foundation
// import FirebaseFirestore

struct NewsArticle: Identifiable, Codable {
    // @DocumentID var id: String?
    let id: String
    let title: String
    let summary: String
    let content: String?
    let author: String?
    let authorId: String?
    let source: String
    let sourceId: String
    let sourceURL: String
    let articleURL: String?
    let pubDate: Date
    let lastUpdated: Date
    let category: NewsCategory
    let subcategory: String?
    let tags: [String]
    let isRumor: Bool
    let isSpoiler: Bool
    let isBreaking: Bool
    let isVerified: Bool
    let reliability: ReliabilityTier
    let reliabilityScore: Double // 0.0 to 1.0
    let credibilityScore: Double // 0.0 to 1.0
    let engagement: ArticleEngagement
    let media: ArticleMedia
    let relatedArticles: [String] // Article IDs
    let status: ArticleStatus
    let createdAt: Date
    let updatedAt: Date
    
    init(title: String, summary: String, content: String?, author: String?, source: String, sourceId: String, sourceURL: String, articleURL: String?, pubDate: Date, category: NewsCategory, isBreaking: Bool = false, reliability: ReliabilityTier = .tier2, tags: [String] = []) {
        self.id = UUID().uuidString
        self.title = title
        self.summary = summary
        self.content = content
        self.author = author
        self.authorId = nil
        self.source = source
        self.sourceId = sourceId
        self.sourceURL = sourceURL
        self.articleURL = articleURL
        self.pubDate = pubDate
        self.lastUpdated = Date()
        self.category = category
        self.subcategory = nil
        self.tags = tags
        self.isRumor = category == .rumors
        self.isSpoiler = false
        self.isBreaking = isBreaking
        self.isVerified = reliability == .tier1
        self.reliability = reliability
        self.reliabilityScore = reliability == .tier1 ? 0.9 : (reliability == .tier2 ? 0.7 : 0.4)
        self.credibilityScore = reliability == .tier1 ? 0.9 : (reliability == .tier2 ? 0.7 : 0.4)
        self.engagement = ArticleEngagement()
        self.media = ArticleMedia()
        self.relatedArticles = []
        self.status = .published
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct ArticleEngagement: Codable {
    let views: Int
    let likes: Int
    let dislikes: Int
    let shares: Int
    let comments: Int
    let bookmarks: Int
    let clickThroughRate: Double
    let timeOnPage: Double // in seconds
    
    init() {
        self.views = 0
        self.likes = 0
        self.dislikes = 0
        self.shares = 0
        self.comments = 0
        self.bookmarks = 0
        self.clickThroughRate = 0.0
        self.timeOnPage = 0.0
    }
}

struct ArticleMedia: Codable {
    let imageURL: String?
    let videoURL: String?
    let thumbnailURL: String?
    let imageAlt: String?
    let videoDuration: Double? // in seconds
    let mediaType: MediaType
    
    init() {
        self.imageURL = nil
        self.videoURL = nil
        self.thumbnailURL = nil
        self.imageAlt = nil
        self.videoDuration = nil
        self.mediaType = .none
    }
}

enum MediaType: String, CaseIterable, Codable {
    case none = "none"
    case image = "image"
    case video = "video"
    case gif = "gif"
    case audio = "audio"
}

enum ArticleStatus: String, CaseIterable, Codable {
    case draft = "draft"
    case pending = "pending"
    case published = "published"
    case archived = "archived"
    case deleted = "deleted"
}

// MARK: - Reliability Tiers
enum ReliabilityTier: String, CaseIterable, Codable {
    case tier1 = "Tier 1"
    case tier2 = "Tier 2"
    case tier3 = "Tier 3"
    
    var color: String {
        switch self {
        case .tier1: return "green"
        case .tier2: return "orange"
        case .tier3: return "red"
        }
    }
    
    var description: String {
        switch self {
        case .tier1: return "Gold Standard - Highest Reliability"
        case .tier2: return "Good Reliability - Usually Accurate"
        case .tier3: return "Speculation - Verify Information"
        }
    }
}

// MARK: - News Categories
enum NewsCategory: String, CaseIterable, Codable {
    case general = "General"
    case breaking = "Breaking"
    case results = "Results"
    case rumors = "Rumors"
    case analysis = "Analysis"
    case injuries = "Injuries"
    case contracts = "Contracts"
    
    var icon: String {
        switch self {
        case .general: return "newspaper"
        case .breaking: return "exclamationmark.triangle"
        case .results: return "trophy"
        case .rumors: return "questionmark.circle"
        case .analysis: return "chart.bar"
        case .injuries: return "cross"
        case .contracts: return "doc.text"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "blue"
        case .breaking: return "red"
        case .results: return "green"
        case .rumors: return "orange"
        case .analysis: return "purple"
        case .injuries: return "red"
        case .contracts: return "blue"
        }
    }
}

// RSS Feed related models
struct RSSFeed: Identifiable, Codable {
    // @DocumentID var id: String?
    let id: String?
    let name: String
    let url: String
    let description: String
    let category: NewsCategory
    let isActive: Bool
    let lastFetched: Date?
    let fetchInterval: Int // in minutes
    let reliabilityScore: Double
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, url: String, description: String, category: NewsCategory) {
        self.id = UUID().uuidString
        self.name = name
        self.url = url
        self.description = description
        self.category = category
        self.isActive = true
        self.lastFetched = nil
        self.fetchInterval = 30
        self.reliabilityScore = 0.5
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct RSSFeedItem: Identifiable, Codable {
    // @DocumentID var id: String?
    let id: String?
    let feedId: String
    let title: String
    let description: String
    let content: String
    let link: String
    let guid: String
    let pubDate: Date
    let author: String?
    let categories: [String]
    let isProcessed: Bool
    let createdAt: Date
    
    init(feedId: String, title: String, description: String, content: String, link: String, guid: String, pubDate: Date) {
        self.id = UUID().uuidString
        self.feedId = feedId
        self.title = title
        self.description = description
        self.content = content
        self.link = link
        self.guid = guid
        self.pubDate = pubDate
        self.author = nil
        self.categories = []
        self.isProcessed = false
        self.createdAt = Date()
    }
}