import Foundation
import FirebaseFirestore

struct NewsArticle: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let content: String
    let excerpt: String
    let author: String
    let authorId: String?
    let source: String
    let sourceURL: String?
    let publishDate: Date
    let lastUpdated: Date
    let category: NewsCategory
    let subcategory: String?
    let tags: [String]
    let isRumor: Bool
    let isSpoiler: Bool
    let isBreaking: Bool
    let isVerified: Bool
    let reliabilityScore: Double // 0.0 to 1.0
    let credibilityScore: Double // 0.0 to 1.0
    let engagement: ArticleEngagement
    let media: ArticleMedia
    let relatedArticles: [String] // Article IDs
    let status: ArticleStatus
    let createdAt: Date
    let updatedAt: Date
    
    init(title: String, content: String, author: String, source: String, category: NewsCategory) {
        self.title = title
        self.content = content
        self.excerpt = String(content.prefix(200)) + "..."
        self.author = author
        self.authorId = nil
        self.source = source
        self.sourceURL = nil
        self.publishDate = Date()
        self.lastUpdated = Date()
        self.category = category
        self.subcategory = nil
        self.tags = []
        self.isRumor = false
        self.isSpoiler = false
        self.isBreaking = false
        self.isVerified = false
        self.reliabilityScore = 0.5
        self.credibilityScore = 0.5
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

// RSS Feed related models
struct RSSFeed: Identifiable, Codable {
    @DocumentID var id: String?
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
    @DocumentID var id: String?
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