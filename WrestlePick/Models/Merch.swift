import Foundation
import FirebaseFirestore

struct MerchItem: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let category: MerchCategory
    let subcategory: String?
    let brand: String
    let wrestler: String?
    let promotion: String?
    let price: Double
    let currency: String
    let originalPrice: Double?
    let discountPercentage: Double?
    let availability: AvailabilityStatus
    let stock: Int?
    let images: [String] // URLs
    let thumbnailURL: String?
    let popularityScore: Double // 0.0 to 1.0
    let trendingScore: Double // 0.0 to 1.0
    let rating: Double // 0.0 to 5.0
    let reviewCount: Int
    let tags: [String]
    let specifications: MerchSpecifications
    let shipping: ShippingInfo
    let engagement: MerchEngagement
    let isFeatured: Bool
    let isNew: Bool
    let isLimitedEdition: Bool
    let releaseDate: Date?
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, description: String, category: MerchCategory, brand: String, price: Double) {
        self.name = name
        self.description = description
        self.category = category
        self.subcategory = nil
        self.brand = brand
        self.wrestler = nil
        self.promotion = nil
        self.price = price
        self.currency = "USD"
        self.originalPrice = nil
        self.discountPercentage = nil
        self.availability = .inStock
        self.stock = nil
        self.images = []
        self.thumbnailURL = nil
        self.popularityScore = 0.0
        self.trendingScore = 0.0
        self.rating = 0.0
        self.reviewCount = 0
        self.tags = []
        self.specifications = MerchSpecifications()
        self.shipping = ShippingInfo()
        self.engagement = MerchEngagement()
        self.isFeatured = false
        self.isNew = true
        self.isLimitedEdition = false
        self.releaseDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct MerchSpecifications: Codable {
    let sizes: [String]
    let colors: [String]
    let materials: [String]
    let dimensions: Dimensions?
    let weight: Double? // in grams
    let careInstructions: [String]
    let countryOfOrigin: String?
    let warranty: String?
    
    init() {
        self.sizes = []
        self.colors = []
        self.materials = []
        self.dimensions = nil
        self.weight = nil
        self.careInstructions = []
        self.countryOfOrigin = nil
        self.warranty = nil
    }
}

struct Dimensions: Codable {
    let length: Double
    let width: Double
    let height: Double
    let unit: String // cm, inches, etc.
    
    init(length: Double, width: Double, height: Double, unit: String = "cm") {
        self.length = length
        self.width = width
        self.height = height
        self.unit = unit
    }
}

struct ShippingInfo: Codable {
    let freeShippingThreshold: Double?
    let shippingCost: Double
    let estimatedDelivery: String
    let shippingMethods: [ShippingMethod]
    let returnPolicy: String?
    let exchangePolicy: String?
    
    init() {
        self.freeShippingThreshold = nil
        self.shippingCost = 0.0
        self.estimatedDelivery = "5-7 business days"
        self.shippingMethods = []
        self.returnPolicy = nil
        self.exchangePolicy = nil
    }
}

struct ShippingMethod: Codable {
    let name: String
    let cost: Double
    let estimatedDays: Int
    let isExpress: Bool
    let isInternational: Bool
    
    init(name: String, cost: Double, estimatedDays: Int) {
        self.name = name
        self.cost = cost
        self.estimatedDays = estimatedDays
        self.isExpress = false
        self.isInternational = false
    }
}

struct MerchEngagement: Codable {
    let views: Int
    let likes: Int
    let shares: Int
    let wishlistAdds: Int
    let cartAdds: Int
    let purchases: Int
    let reviews: Int
    let questions: Int
    let clickThroughRate: Double
    let conversionRate: Double
    
    init() {
        self.views = 0
        self.likes = 0
        self.shares = 0
        self.wishlistAdds = 0
        self.cartAdds = 0
        self.purchases = 0
        self.reviews = 0
        self.questions = 0
        self.clickThroughRate = 0.0
        self.conversionRate = 0.0
    }
}

enum MerchCategory: String, CaseIterable, Codable {
    case apparel = "Apparel"
    case accessories = "Accessories"
    case collectibles = "Collectibles"
    case home = "Home & Living"
    case books = "Books & Media"
    case toys = "Toys & Games"
    case jewelry = "Jewelry"
    case bags = "Bags & Luggage"
    case footwear = "Footwear"
    case other = "Other"
}

enum AvailabilityStatus: String, CaseIterable, Codable {
    case inStock = "in_stock"
    case lowStock = "low_stock"
    case outOfStock = "out_of_stock"
    case discontinued = "discontinued"
    case preOrder = "pre_order"
    case comingSoon = "coming_soon"
}

// Merch Review
struct MerchReview: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let itemId: String
    let rating: Int // 1-5 stars
    let title: String
    let content: String
    let pros: [String]
    let cons: [String]
    let size: String?
    let color: String?
    let isVerifiedPurchase: Bool
    let helpfulVotes: Int
    let notHelpfulVotes: Int
    let images: [String]
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: String, username: String, itemId: String, rating: Int, title: String, content: String) {
        self.userId = userId
        self.username = username
        self.itemId = itemId
        self.rating = rating
        self.title = title
        self.content = content
        self.pros = []
        self.cons = []
        self.size = nil
        self.color = nil
        self.isVerifiedPurchase = false
        self.helpfulVotes = 0
        self.notHelpfulVotes = 0
        self.images = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// Wishlist
struct Wishlist: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let name: String
    let description: String?
    let isPublic: Bool
    let items: [WishlistItem]
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: String, name: String) {
        self.userId = userId
        self.name = name
        self.description = nil
        self.isPublic = false
        self.items = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct WishlistItem: Identifiable, Codable {
    let id: String
    let itemId: String
    let addedDate: Date
    let notes: String?
    let priority: WishlistPriority
    
    init(itemId: String) {
        self.id = UUID().uuidString
        self.itemId = itemId
        self.addedDate = Date()
        self.notes = nil
        self.priority = .medium
    }
}

enum WishlistPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
}
