import Foundation
import FirebaseFirestore

// MARK: - Merch Item
struct MerchItem: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let brand: String
    let category: MerchCategory
    let wrestler: String
    let promotion: String
    let imageURLs: [String]
    let currentPrice: Double
    let originalPrice: Double?
    let currency: String
    let availability: AvailabilityStatus
    let regions: [String] // Available regions
    let tags: [String]
    let affiliateLinks: [AffiliateLink]
    let popularity: PopularityMetrics
    let priceHistory: [PricePoint]
    let socialSentiment: SocialSentiment
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, description: String, brand: String, category: MerchCategory, wrestler: String, promotion: String, imageURLs: [String] = [], currentPrice: Double, originalPrice: Double? = nil, currency: String = "USD", availability: AvailabilityStatus = .inStock, regions: [String] = [], tags: [String] = [], affiliateLinks: [AffiliateLink] = [], popularity: PopularityMetrics = PopularityMetrics(), priceHistory: [PricePoint] = [], socialSentiment: SocialSentiment = SocialSentiment()) {
        self.name = name
        self.description = description
        self.brand = brand
        self.category = category
        self.wrestler = wrestler
        self.promotion = promotion
        self.imageURLs = imageURLs
        self.currentPrice = currentPrice
        self.originalPrice = originalPrice
        self.currency = currency
        self.availability = availability
        self.regions = regions
        self.tags = tags
        self.affiliateLinks = affiliateLinks
        self.popularity = popularity
        self.priceHistory = priceHistory
        self.socialSentiment = socialSentiment
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Merch Category
enum MerchCategory: String, CaseIterable, Codable {
    case tshirt = "T-Shirt"
    case hoodie = "Hoodie"
    case hat = "Hat"
    case poster = "Poster"
    case actionFigure = "Action Figure"
    case autograph = "Autograph"
    case championship = "Championship Belt"
    case accessory = "Accessory"
    case collectible = "Collectible"
    case digital = "Digital"
    case custom = "Custom"
    
    var iconName: String {
        switch self {
        case .tshirt: return "tshirt"
        case .hoodie: return "hoodie"
        case .hat: return "hat"
        case .poster: return "photo"
        case .actionFigure: return "figure.stand"
        case .autograph: return "signature"
        case .championship: return "crown"
        case .accessory: return "bag"
        case .collectible: return "star"
        case .digital: return "iphone"
        case .custom: return "wrench"
        }
    }
    
    var color: String {
        switch self {
        case .tshirt: return "blue"
        case .hoodie: return "purple"
        case .hat: return "orange"
        case .poster: return "red"
        case .actionFigure: return "green"
        case .autograph: return "yellow"
        case .championship: return "gold"
        case .accessory: return "gray"
        case .collectible: return "pink"
        case .digital: return "cyan"
        case .custom: return "brown"
        }
    }
}

// MARK: - Availability Status
enum AvailabilityStatus: String, CaseIterable, Codable {
    case inStock = "In Stock"
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
    case discontinued = "Discontinued"
    case preOrder = "Pre-Order"
    case limitedEdition = "Limited Edition"
    
    var color: String {
        switch self {
        case .inStock: return "green"
        case .lowStock: return "yellow"
        case .outOfStock: return "red"
        case .discontinued: return "gray"
        case .preOrder: return "blue"
        case .limitedEdition: return "purple"
        }
    }
    
    var iconName: String {
        switch self {
        case .inStock: return "checkmark.circle.fill"
        case .lowStock: return "exclamationmark.triangle.fill"
        case .outOfStock: return "xmark.circle.fill"
        case .discontinued: return "minus.circle.fill"
        case .preOrder: return "clock.fill"
        case .limitedEdition: return "star.fill"
        }
    }
}

// MARK: - Affiliate Link
struct AffiliateLink: Codable, Identifiable {
    let id: String
    let storeName: String
    let url: String
    let price: Double
    let currency: String
    let isActive: Bool
    let commissionRate: Double
    let lastChecked: Date
    
    init(storeName: String, url: String, price: Double, currency: String = "USD", isActive: Bool = true, commissionRate: Double = 0.0) {
        self.id = UUID().uuidString
        self.storeName = storeName
        self.url = url
        self.price = price
        self.currency = currency
        self.isActive = isActive
        self.commissionRate = commissionRate
        self.lastChecked = Date()
    }
}

// MARK: - Popularity Metrics
struct PopularityMetrics: Codable {
    let score: Double
    let rank: Int
    let views: Int
    let likes: Int
    let shares: Int
    let reports: Int
    let searchCount: Int
    let socialMentions: Int
    let velocity: Double // Sales velocity
    let trend: TrendDirection
    let lastUpdated: Date
    
    init(score: Double = 0.0, rank: Int = 0, views: Int = 0, likes: Int = 0, shares: Int = 0, reports: Int = 0, searchCount: Int = 0, socialMentions: Int = 0, velocity: Double = 0.0, trend: TrendDirection = .stable) {
        self.score = score
        self.rank = rank
        self.views = views
        self.likes = likes
        self.shares = shares
        self.reports = reports
        self.searchCount = searchCount
        self.socialMentions = socialMentions
        self.velocity = velocity
        self.trend = trend
        self.lastUpdated = Date()
    }
}

// MARK: - Trend Direction
enum TrendDirection: String, CaseIterable, Codable {
    case rising = "Rising"
    case falling = "Falling"
    case stable = "Stable"
    case volatile = "Volatile"
    
    var iconName: String {
        switch self {
        case .rising: return "arrow.up"
        case .falling: return "arrow.down"
        case .stable: return "minus"
        case .volatile: return "arrow.up.arrow.down"
        }
    }
    
    var color: String {
        switch self {
        case .rising: return "green"
        case .falling: return "red"
        case .stable: return "gray"
        case .volatile: return "orange"
        }
    }
}

// MARK: - Price Point
struct PricePoint: Codable, Identifiable {
    let id: String
    let price: Double
    let currency: String
    let date: Date
    let store: String
    let availability: AvailabilityStatus
    let source: PriceSource
    
    init(price: Double, currency: String = "USD", date: Date = Date(), store: String, availability: AvailabilityStatus = .inStock, source: PriceSource = .userReport) {
        self.id = UUID().uuidString
        self.price = price
        self.currency = currency
        self.date = date
        self.store = store
        self.availability = availability
        self.source = source
    }
}

// MARK: - Price Source
enum PriceSource: String, CaseIterable, Codable {
    case userReport = "User Report"
    case api = "API"
    case webScraping = "Web Scraping"
    case partner = "Partner"
    case manual = "Manual"
    
    var iconName: String {
        switch self {
        case .userReport: return "person"
        case .api: return "network"
        case .webScraping: return "spider"
        case .partner: return "handshake"
        case .manual: return "pencil"
        }
    }
}

// MARK: - Social Sentiment
struct SocialSentiment: Codable {
    let overall: SentimentScore
    let twitter: SentimentScore
    let instagram: SentimentScore
    let reddit: SentimentScore
    let youtube: SentimentScore
    let lastUpdated: Date
    
    init(overall: SentimentScore = SentimentScore(), twitter: SentimentScore = SentimentScore(), instagram: SentimentScore = SentimentScore(), reddit: SentimentScore = SentimentScore(), youtube: SentimentScore = SentimentScore()) {
        self.overall = overall
        self.twitter = twitter
        self.instagram = instagram
        self.reddit = reddit
        self.youtube = youtube
        self.lastUpdated = Date()
    }
}

// MARK: - Sentiment Score
struct SentimentScore: Codable {
    let positive: Double
    let negative: Double
    let neutral: Double
    let mentions: Int
    let engagement: Double
    
    init(positive: Double = 0.0, negative: Double = 0.0, neutral: Double = 0.0, mentions: Int = 0, engagement: Double = 0.0) {
        self.positive = positive
        self.negative = negative
        self.neutral = neutral
        self.mentions = mentions
        self.engagement = engagement
    }
    
    var overall: Double {
        return (positive - negative) / max(mentions, 1)
    }
}

// MARK: - User Report
struct UserReport: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let itemId: String
    let reportType: ReportType
    let price: Double?
    let currency: String
    let store: String
    let location: String?
    let availability: AvailabilityStatus
    let notes: String?
    let images: [String]
    let verified: Bool
    let createdAt: Date
    
    init(userId: String, itemId: String, reportType: ReportType, price: Double? = nil, currency: String = "USD", store: String, location: String? = nil, availability: AvailabilityStatus = .inStock, notes: String? = nil, images: [String] = [], verified: Bool = false) {
        self.userId = userId
        self.itemId = itemId
        self.reportType = reportType
        self.price = price
        self.currency = currency
        self.store = store
        self.location = location
        self.availability = availability
        self.notes = notes
        self.images = images
        self.verified = verified
        self.createdAt = Date()
    }
}

// MARK: - Report Type
enum ReportType: String, CaseIterable, Codable {
    case price = "Price"
    case availability = "Availability"
    case newItem = "New Item"
    case restock = "Restock"
    case sale = "Sale"
    case discontinued = "Discontinued"
    
    var iconName: String {
        switch self {
        case .price: return "dollarsign.circle"
        case .availability: return "checkmark.circle"
        case .newItem: return "plus.circle"
        case .restock: return "arrow.clockwise.circle"
        case .sale: return "percent"
        case .discontinued: return "xmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .price: return "blue"
        case .availability: return "green"
        case .newItem: return "purple"
        case .restock: return "orange"
        case .sale: return "red"
        case .discontinued: return "gray"
        }
    }
}

// MARK: - Price Alert
struct PriceAlert: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let itemId: String
    let targetPrice: Double
    let currency: String
    let alertType: AlertType
    let isActive: Bool
    let createdAt: Date
    let triggeredAt: Date?
    
    init(userId: String, itemId: String, targetPrice: Double, currency: String = "USD", alertType: AlertType, isActive: Bool = true, triggeredAt: Date? = nil) {
        self.userId = userId
        self.itemId = itemId
        self.targetPrice = targetPrice
        self.currency = currency
        self.alertType = alertType
        self.isActive = isActive
        self.createdAt = Date()
        self.triggeredAt = triggeredAt
    }
}

// MARK: - Alert Type
enum AlertType: String, CaseIterable, Codable {
    case priceDrop = "Price Drop"
    case priceRise = "Price Rise"
    case restock = "Restock"
    case newItem = "New Item"
    case sale = "Sale"
    
    var iconName: String {
        switch self {
        case .priceDrop: return "arrow.down.circle"
        case .priceRise: return "arrow.up.circle"
        case .restock: return "arrow.clockwise.circle"
        case .newItem: return "plus.circle"
        case .sale: return "percent.circle"
        }
    }
}

// MARK: - Merch Leaderboard Entry
struct MerchLeaderboardEntry: Codable, Identifiable {
    let id: String
    let itemId: String
    let itemName: String
    let wrestler: String
    let promotion: String
    let category: MerchCategory
    let currentPrice: Double
    let popularityScore: Double
    let rank: Int
    let trend: TrendDirection
    let velocity: Double
    let imageURL: String?
    
    init(itemId: String, itemName: String, wrestler: String, promotion: String, category: MerchCategory, currentPrice: Double, popularityScore: Double, rank: Int, trend: TrendDirection, velocity: Double, imageURL: String? = nil) {
        self.id = itemId
        self.itemId = itemId
        self.itemName = itemName
        self.wrestler = wrestler
        self.promotion = promotion
        self.category = category
        self.currentPrice = currentPrice
        self.popularityScore = popularityScore
        self.rank = rank
        self.trend = trend
        self.velocity = velocity
        self.imageURL = imageURL
    }
}

// MARK: - Trending Item
struct TrendingItem: Codable, Identifiable {
    let id: String
    let itemId: String
    let itemName: String
    let wrestler: String
    let promotion: String
    let category: MerchCategory
    let currentPrice: Double
    let trendScore: Double
    let socialMentions: Int
    let searchCount: Int
    let velocity: Double
    let imageURL: String?
    let hashtags: [String]
    
    init(itemId: String, itemName: String, wrestler: String, promotion: String, category: MerchCategory, currentPrice: Double, trendScore: Double, socialMentions: Int, searchCount: Int, velocity: Double, imageURL: String? = nil, hashtags: [String] = []) {
        self.id = itemId
        self.itemId = itemId
        self.itemName = itemName
        self.wrestler = wrestler
        self.promotion = promotion
        self.category = category
        self.currentPrice = currentPrice
        self.trendScore = trendScore
        self.socialMentions = socialMentions
        self.velocity = velocity
        self.imageURL = imageURL
        self.hashtags = hashtags
    }
}

// MARK: - Store
struct Store: Codable, Identifiable {
    let id: String
    let name: String
    let website: String
    let logoURL: String?
    let isPartner: Bool
    let commissionRate: Double
    let regions: [String]
    let categories: [MerchCategory]
    let isActive: Bool
    
    init(name: String, website: String, logoURL: String? = nil, isPartner: Bool = false, commissionRate: Double = 0.0, regions: [String] = [], categories: [MerchCategory] = [], isActive: Bool = true) {
        self.id = UUID().uuidString
        self.name = name
        self.website = website
        self.logoURL = logoURL
        self.isPartner = isPartner
        self.commissionRate = commissionRate
        self.regions = regions
        self.categories = categories
        self.isActive = isActive
    }
}

// MARK: - Extensions
extension MerchItem {
    var isOnSale: Bool {
        guard let originalPrice = originalPrice else { return false }
        return currentPrice < originalPrice
    }
    
    var discountPercentage: Double {
        guard let originalPrice = originalPrice, originalPrice > 0 else { return 0 }
        return ((originalPrice - currentPrice) / originalPrice) * 100
    }
    
    var bestPrice: Double {
        return affiliateLinks.map { $0.price }.min() ?? currentPrice
    }
    
    var bestStore: AffiliateLink? {
        return affiliateLinks.min { $0.price < $1.price }
    }
}

extension PopularityMetrics {
    var calculatedScore: Double {
        let baseScore = Double(views) * 0.1
        let engagementScore = Double(likes + shares) * 0.5
        let reportScore = Double(reports) * 0.3
        let searchScore = Double(searchCount) * 0.2
        let socialScore = Double(socialMentions) * 0.4
        let velocityScore = velocity * 0.6
        
        return baseScore + engagementScore + reportScore + searchScore + socialScore + velocityScore
    }
}
