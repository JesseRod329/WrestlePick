import Foundation
import FirebaseFirestore

// MARK: - Subscription Plan
struct SubscriptionPlan: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let duration: SubscriptionDuration
    let features: [PremiumFeature]
    let isPopular: Bool
    let isActive: Bool
    let productId: String // StoreKit product identifier
    
    init(id: String, name: String, description: String, price: Double, currency: String = "USD", duration: SubscriptionDuration, features: [PremiumFeature], isPopular: Bool = false, isActive: Bool = true, productId: String) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.currency = currency
        self.duration = duration
        self.features = features
        self.isPopular = isPopular
        self.isActive = isActive
        self.productId = productId
    }
}

// MARK: - Subscription Duration
enum SubscriptionDuration: String, CaseIterable, Codable {
    case monthly = "monthly"
    case yearly = "yearly"
    case lifetime = "lifetime"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }
    
    var savings: Double? {
        switch self {
        case .monthly: return nil
        case .yearly: return 0.17 // 17% savings
        case .lifetime: return 0.50 // 50% savings
        }
    }
}

// MARK: - Premium Feature
struct PremiumFeature: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let category: FeatureCategory
    let isEnabled: Bool
    
    init(name: String, description: String, iconName: String, category: FeatureCategory, isEnabled: Bool = true) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.isEnabled = isEnabled
    }
}

// MARK: - Feature Category
enum FeatureCategory: String, CaseIterable, Codable {
    case predictions = "predictions"
    case fantasy = "fantasy"
    case analytics = "analytics"
    case content = "content"
    case community = "community"
    case support = "support"
    
    var displayName: String {
        switch self {
        case .predictions: return "Predictions"
        case .fantasy: return "Fantasy Booking"
        case .analytics: return "Analytics"
        case .content: return "Content"
        case .community: return "Community"
        case .support: return "Support"
        }
    }
    
    var color: String {
        switch self {
        case .predictions: return "blue"
        case .fantasy: return "purple"
        case .analytics: return "green"
        case .content: return "orange"
        case .community: return "red"
        case .support: return "gray"
        }
    }
}

// MARK: - User Subscription
struct UserSubscription: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let planId: String
    let status: SubscriptionStatus
    let startDate: Date
    let endDate: Date?
    let autoRenew: Bool
    let trialEndDate: Date?
    let isTrial: Bool
    let originalTransactionId: String
    let productId: String
    let price: Double
    let currency: String
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: String, planId: String, status: SubscriptionStatus, startDate: Date, endDate: Date? = nil, autoRenew: Bool = true, trialEndDate: Date? = nil, isTrial: Bool = false, originalTransactionId: String, productId: String, price: Double, currency: String = "USD") {
        self.userId = userId
        self.planId = planId
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.autoRenew = autoRenew
        self.trialEndDate = trialEndDate
        self.isTrial = isTrial
        self.originalTransactionId = originalTransactionId
        self.productId = productId
        self.price = price
        self.currency = currency
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Subscription Status
enum SubscriptionStatus: String, CaseIterable, Codable {
    case active = "active"
    case expired = "expired"
    case cancelled = "cancelled"
    case pending = "pending"
    case trial = "trial"
    case gracePeriod = "gracePeriod"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        case .pending: return "Pending"
        case .trial: return "Trial"
        case .gracePeriod: return "Grace Period"
        }
    }
    
    var color: String {
        switch self {
        case .active: return "green"
        case .expired: return "red"
        case .cancelled: return "gray"
        case .pending: return "yellow"
        case .trial: return "blue"
        case .gracePeriod: return "orange"
        }
    }
}

// MARK: - Revenue Tracking
struct RevenueTracking: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let revenueType: RevenueType
    let amount: Double
    let currency: String
    let source: String
    let description: String
    let transactionId: String?
    let affiliateId: String?
    let commissionRate: Double
    let commissionAmount: Double
    let createdAt: Date
    
    init(userId: String, revenueType: RevenueType, amount: Double, currency: String = "USD", source: String, description: String, transactionId: String? = nil, affiliateId: String? = nil, commissionRate: Double = 0.0, commissionAmount: Double = 0.0) {
        self.userId = userId
        self.revenueType = revenueType
        self.amount = amount
        self.currency = currency
        self.source = source
        self.description = description
        self.transactionId = transactionId
        self.affiliateId = affiliateId
        self.commissionRate = commissionRate
        self.commissionAmount = commissionAmount
        self.createdAt = Date()
    }
}

// MARK: - Revenue Type
enum RevenueType: String, CaseIterable, Codable {
    case subscription = "subscription"
    case affiliate = "affiliate"
    case sponsored = "sponsored"
    case tournament = "tournament"
    case customLeague = "customLeague"
    case inAppPurchase = "inAppPurchase"
    
    var displayName: String {
        switch self {
        case .subscription: return "Subscription"
        case .affiliate: return "Affiliate"
        case .sponsored: return "Sponsored Content"
        case .tournament: return "Tournament"
        case .customLeague: return "Custom League"
        case .inAppPurchase: return "In-App Purchase"
        }
    }
    
    var iconName: String {
        switch self {
        case .subscription: return "creditcard"
        case .affiliate: return "link"
        case .sponsored: return "megaphone"
        case .tournament: return "trophy"
        case .customLeague: return "person.2"
        case .inAppPurchase: return "cart"
        }
    }
}

// MARK: - Affiliate Link
struct AffiliateLink: Codable, Identifiable {
    let id: String
    let storeName: String
    let url: String
    let productName: String
    let productImage: String?
    let price: Double
    let currency: String
    let commissionRate: Double
    let isActive: Bool
    let clickCount: Int
    let conversionCount: Int
    let revenue: Double
    let createdAt: Date
    let updatedAt: Date
    
    init(storeName: String, url: String, productName: String, productImage: String? = nil, price: Double, currency: String = "USD", commissionRate: Double, isActive: Bool = true, clickCount: Int = 0, conversionCount: Int = 0, revenue: Double = 0.0) {
        self.id = UUID().uuidString
        self.storeName = storeName
        self.url = url
        self.productName = productName
        self.productImage = productImage
        self.price = price
        self.currency = currency
        self.commissionRate = commissionRate
        self.isActive = isActive
        self.clickCount = clickCount
        self.conversionCount = conversionCount
        self.revenue = revenue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Sponsored Content
struct SponsoredContent: Codable, Identifiable {
    @DocumentID var id: String?
    let sponsorName: String
    let sponsorLogo: String?
    let title: String
    let content: String
    let imageURL: String?
    let linkURL: String?
    let ctaText: String
    let targetAudience: [String]
    let budget: Double
    let impressions: Int
    let clicks: Int
    let conversions: Int
    let revenue: Double
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let createdAt: Date
    
    init(sponsorName: String, sponsorLogo: String? = nil, title: String, content: String, imageURL: String? = nil, linkURL: String? = nil, ctaText: String, targetAudience: [String] = [], budget: Double, impressions: Int = 0, clicks: Int = 0, conversions: Int = 0, revenue: Double = 0.0, startDate: Date, endDate: Date, isActive: Bool = true) {
        self.sponsorName = sponsorName
        self.sponsorLogo = sponsorLogo
        self.title = title
        self.content = content
        self.imageURL = imageURL
        self.linkURL = linkURL
        self.ctaText = ctaText
        self.targetAudience = targetAudience
        self.budget = budget
        self.impressions = impressions
        self.clicks = clicks
        self.conversions = conversions
        self.revenue = revenue
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.createdAt = Date()
    }
}

// MARK: - Premium Tournament
struct PremiumTournament: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let entryFee: Double
    let currency: String
    let prizePool: Double
    let maxParticipants: Int
    let currentParticipants: Int
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let isPremiumOnly: Bool
    let rules: [String]
    let prizes: [TournamentPrize]
    let participants: [TournamentParticipant]
    let createdAt: Date
    
    init(name: String, description: String, entryFee: Double, currency: String = "USD", prizePool: Double, maxParticipants: Int, currentParticipants: Int = 0, startDate: Date, endDate: Date, isActive: Bool = true, isPremiumOnly: Bool = true, rules: [String] = [], prizes: [TournamentPrize] = [], participants: [TournamentParticipant] = []) {
        self.name = name
        self.description = description
        self.entryFee = entryFee
        self.currency = currency
        self.prizePool = prizePool
        self.maxParticipants = maxParticipants
        self.currentParticipants = currentParticipants
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.isPremiumOnly = isPremiumOnly
        self.rules = rules
        self.prizes = prizes
        self.participants = participants
        self.createdAt = Date()
    }
}

// MARK: - Tournament Prize
struct TournamentPrize: Codable, Identifiable {
    let id: String
    let position: Int
    let prizeType: PrizeType
    let value: Double
    let currency: String
    let description: String
    let isClaimed: Bool
    let claimedBy: String?
    let claimedAt: Date?
    
    init(position: Int, prizeType: PrizeType, value: Double, currency: String = "USD", description: String, isClaimed: Bool = false, claimedBy: String? = nil, claimedAt: Date? = nil) {
        self.id = UUID().uuidString
        self.position = position
        self.prizeType = prizeType
        self.value = value
        self.currency = currency
        self.description = description
        self.isClaimed = isClaimed
        self.claimedBy = claimedBy
        self.claimedAt = claimedAt
    }
}

// MARK: - Prize Type
enum PrizeType: String, CaseIterable, Codable {
    case cash = "cash"
    case merchandise = "merchandise"
    case subscription = "subscription"
    case giftCard = "giftCard"
    case experience = "experience"
    
    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .merchandise: return "Merchandise"
        case .subscription: return "Subscription"
        case .giftCard: return "Gift Card"
        case .experience: return "Experience"
        }
    }
}

// MARK: - Tournament Participant
struct TournamentParticipant: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let avatarURL: String?
    let entryDate: Date
    let currentRank: Int
    let totalPoints: Int
    let isEliminated: Bool
    let eliminatedAt: Date?
    
    init(userId: String, username: String, displayName: String, avatarURL: String? = nil, entryDate: Date = Date(), currentRank: Int = 0, totalPoints: Int = 0, isEliminated: Bool = false, eliminatedAt: Date? = nil) {
        self.id = UUID().uuidString
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.entryDate = entryDate
        self.currentRank = currentRank
        self.totalPoints = totalPoints
        self.isEliminated = isEliminated
        self.eliminatedAt = eliminatedAt
    }
}

// MARK: - Custom League Hosting
struct CustomLeagueHosting: Codable, Identifiable {
    @DocumentID var id: String?
    let hostId: String
    let hostName: String
    let leagueName: String
    let description: String
    let maxMembers: Int
    let entryFee: Double
    let currency: String
    let platformFee: Double
    let totalRevenue: Double
    let isActive: Bool
    let startDate: Date
    let endDate: Date
    let participants: [LeagueParticipant]
    let createdAt: Date
    
    init(hostId: String, hostName: String, leagueName: String, description: String, maxMembers: Int, entryFee: Double, currency: String = "USD", platformFee: Double, totalRevenue: Double = 0.0, isActive: Bool = true, startDate: Date, endDate: Date, participants: [LeagueParticipant] = []) {
        self.hostId = hostId
        self.hostName = hostName
        self.leagueName = leagueName
        self.description = description
        self.maxMembers = maxMembers
        self.entryFee = entryFee
        self.currency = currency
        self.platformFee = platformFee
        self.totalRevenue = totalRevenue
        self.isActive = isActive
        self.startDate = startDate
        self.endDate = endDate
        self.participants = participants
        self.createdAt = Date()
    }
}

// MARK: - League Participant
struct LeagueParticipant: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let avatarURL: String?
    let joinedAt: Date
    let paidFee: Double
    let currentRank: Int
    let totalPoints: Int
    
    init(userId: String, username: String, displayName: String, avatarURL: String? = nil, joinedAt: Date = Date(), paidFee: Double, currentRank: Int = 0, totalPoints: Int = 0) {
        self.id = UUID().uuidString
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.joinedAt = joinedAt
        self.paidFee = paidFee
        self.currentRank = currentRank
        self.totalPoints = totalPoints
    }
}

// MARK: - Usage Limits
struct UsageLimits: Codable {
    let predictionsPerPPV: Int
    let predictionsPerMonth: Int
    let fantasyBookingsPerMonth: Int
    let customAwardsPerMonth: Int
    let leagueCreationsPerMonth: Int
    let adFreeExperience: Bool
    let prioritySupport: Bool
    let advancedAnalytics: Bool
    let customCategories: Bool
    let earlyAccess: Bool
    
    init(predictionsPerPPV: Int = 5, predictionsPerMonth: Int = 20, fantasyBookingsPerMonth: Int = 3, customAwardsPerMonth: Int = 1, leagueCreationsPerMonth: Int = 1, adFreeExperience: Bool = false, prioritySupport: Bool = false, advancedAnalytics: Bool = false, customCategories: Bool = false, earlyAccess: Bool = false) {
        self.predictionsPerPPV = predictionsPerPPV
        self.predictionsPerMonth = predictionsPerMonth
        self.fantasyBookingsPerMonth = fantasyBookingsPerMonth
        self.customAwardsPerMonth = customAwardsPerMonth
        self.leagueCreationsPerMonth = leagueCreationsPerMonth
        self.adFreeExperience = adFreeExperience
        self.prioritySupport = prioritySupport
        self.advancedAnalytics = advancedAnalytics
        self.customCategories = customCategories
        self.earlyAccess = earlyAccess
    }
}

// MARK: - Extensions
extension SubscriptionPlan {
    var monthlyPrice: Double {
        switch duration {
        case .monthly: return price
        case .yearly: return price / 12
        case .lifetime: return price / 120 // Assuming 10 years
        }
    }
    
    var savingsText: String? {
        guard let savings = duration.savings else { return nil }
        return "Save \(Int(savings * 100))%"
    }
}

extension UserSubscription {
    var isActive: Bool {
        return status == .active || status == .trial || status == .gracePeriod
    }
    
    var daysRemaining: Int {
        guard let endDate = endDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }
}

extension AffiliateLink {
    var conversionRate: Double {
        guard clickCount > 0 else { return 0 }
        return Double(conversionCount) / Double(clickCount)
    }
    
    var totalCommission: Double {
        return revenue * commissionRate
    }
}
