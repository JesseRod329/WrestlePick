import Foundation
import SwiftUI

// MARK: - Wrestling Promotion
enum WrestlingPromotion: String, CaseIterable, Codable {
    case wwe = "WWE"
    case aew = "AEW"
    case njpw = "NJPW"
    case impact = "Impact"
    case roh = "ROH"
    case indie = "Independent"
    
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
    
    var logoURL: String? {
        switch self {
        case .wwe: return "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/WWE_logo.svg/200px-WWE_logo.svg.png"
        case .aew: return "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/AEW_Logo.png/200px-AEW_Logo.png"
        case .njpw: return "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/New_Japan_Pro-Wrestling_logo.svg/200px-New_Japan_Pro-Wrestling_logo.svg.png"
        case .impact: return "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Impact_Wrestling_logo.svg/200px-Impact_Wrestling_logo.svg.png"
        case .roh: return "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Ring_of_Honor_logo.svg/200px-Ring_of_Honor_logo.svg.png"
        case .indie: return nil
        }
    }
}

// MARK: - News Source
struct NewsSource: Codable, Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let reliability: ReliabilityTier
    let isVerified: Bool
    let establishedDate: Date
    let contactInfo: String?
    
    init(name: String, url: String, reliability: ReliabilityTier) {
        self.name = name
        self.url = url
        self.reliability = reliability
        self.isVerified = reliability == .tier1
        self.establishedDate = Date()
        self.contactInfo = nil
    }
}

// MARK: - News Article (Updated)
struct NewsArticle: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let excerpt: String
    let source: NewsSource
    let category: NewsCategory
    let promotions: [WrestlingPromotion]
    let publishDate: Date
    let author: String
    let imageURL: String?
    let tags: [String]
    let isBreaking: Bool
    let isVerified: Bool
    let likes: Int
    let shares: Int
    let comments: Int
    let isLiked: Bool
    let isBookmarked: Bool
    let isShared: Bool
    
    var reliabilityScore: Double {
        return source.reliability.score
    }
    
    init(title: String, content: String, source: NewsSource, category: NewsCategory, promotions: [WrestlingPromotion] = [], author: String = "", imageURL: String? = nil, tags: [String] = [], isBreaking: Bool = false, isVerified: Bool = false) {
        self.title = title
        self.content = content
        self.excerpt = String(content.prefix(200)) + (content.count > 200 ? "..." : "")
        self.source = source
        self.category = category
        self.promotions = promotions
        self.publishDate = Date()
        self.author = author
        self.imageURL = imageURL
        self.tags = tags
        self.isBreaking = isBreaking
        self.isVerified = isVerified
        self.likes = 0
        self.shares = 0
        self.comments = 0
        self.isLiked = false
        self.isBookmarked = false
        self.isShared = false
    }
}

// MARK: - News Category (Updated)
enum NewsCategory: String, CaseIterable, Codable {
    case general = "General"
    case breaking = "Breaking"
    case results = "Results"
    case rumors = "Rumors"
    case analysis = "Analysis"
    case injuries = "Injuries"
    case contracts = "Contracts"
    case wwe = "WWE"
    case aew = "AEW"
    case njpw = "NJPW"
    case impact = "Impact"
    case indie = "Independent"
    case spoilers = "Spoilers"
    case backstage = "Backstage"
    case business = "Business"
    
    var color: Color {
        switch self {
        case .general: return .gray
        case .breaking: return .red
        case .results: return .green
        case .rumors: return .orange
        case .analysis: return .blue
        case .injuries: return .red
        case .contracts: return .purple
        case .wwe: return .blue
        case .aew: return .red
        case .njpw: return .orange
        case .impact: return .purple
        case .indie: return .gray
        case .spoilers: return .yellow
        case .backstage: return .brown
        case .business: return .green
        }
    }
}

// MARK: - Reliability Tier
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
    
    var color: Color {
        switch self {
        case .tier1: return .green
        case .tier2: return .blue
        case .speculation: return .orange
        case .unverified: return .red
        }
    }
}


// MARK: - News Cache
class NewsCache {
    static let shared = NewsCache()
    private let cacheKey = "cached_news_articles"
    
    private init() {}
    
    func cacheArticles(_ articles: [NewsArticle]) {
        if let data = try? JSONEncoder().encode(articles) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
    
    func getCachedArticles() -> [NewsArticle]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let articles = try? JSONDecoder().decode([NewsArticle].self, from: data) else {
            return nil
        }
        return articles
    }
}

// MARK: - Push Notification Service (Mock)
class PushNotificationService {
    static let shared = PushNotificationService()
    
    private init() {}
    
    func sendBreakingNewsNotification(_ article: NewsArticle) {
        // Mock implementation - in real app, this would send actual push notifications
        print("📢 Breaking News: \(article.title)")
    }
}
