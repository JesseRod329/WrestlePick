import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let username: String
    let email: String
    let displayName: String
    let profileImageURL: String?
    let joinDate: Date
    let lastActiveDate: Date
    let preferences: UserPreferences
    let predictionStats: PredictionStats
    let socialStats: SocialStats
    let isVerified: Bool
    let isPremium: Bool
    let subscriptionTier: SubscriptionTier
    let createdAt: Date
    let updatedAt: Date
    
    init(username: String, email: String, displayName: String, profileImageURL: String? = nil) {
        self.username = username
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.joinDate = Date()
        self.lastActiveDate = Date()
        self.preferences = UserPreferences()
        self.predictionStats = PredictionStats()
        self.socialStats = SocialStats()
        self.isVerified = false
        self.isPremium = false
        self.subscriptionTier = .free
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct UserPreferences: Codable {
    let favoritePromotions: [String] // WWE, AEW, NJPW, etc.
    let favoriteWrestlers: [String]
    let favoriteCategories: [NewsCategory]
    let notificationSettings: NotificationSettings
    let privacySettings: PrivacySettings
    let displaySettings: DisplaySettings
    
    init() {
        self.favoritePromotions = []
        self.favoriteWrestlers = []
        self.favoriteCategories = []
        self.notificationSettings = NotificationSettings()
        self.privacySettings = PrivacySettings()
        self.displaySettings = DisplaySettings()
    }
}

struct PredictionStats: Codable {
    let totalPredictions: Int
    let correctPredictions: Int
    let accuracy: Double
    let currentStreak: Int
    let longestStreak: Int
    let rank: Int
    let points: Int
    let badges: [Badge]
    
    init() {
        self.totalPredictions = 0
        self.correctPredictions = 0
        self.accuracy = 0.0
        self.currentStreak = 0
        self.longestStreak = 0
        self.rank = 0
        self.points = 0
        self.badges = []
    }
}

struct SocialStats: Codable {
    let followers: Int
    let following: Int
    let posts: Int
    let likes: Int
    let comments: Int
    let reputation: Int
    
    init() {
        self.followers = 0
        self.following = 0
        self.posts = 0
        self.likes = 0
        self.comments = 0
        self.reputation = 0
    }
}

struct NotificationSettings: Codable {
    let pushNotifications: Bool
    let emailNotifications: Bool
    let predictionReminders: Bool
    let newsAlerts: Bool
    let socialUpdates: Bool
    let weeklyDigest: Bool
    
    init() {
        self.pushNotifications = true
        self.emailNotifications = true
        self.predictionReminders = true
        self.newsAlerts = true
        self.socialUpdates = true
        self.weeklyDigest = true
    }
}

struct PrivacySettings: Codable {
    let profileVisibility: ProfileVisibility
    let predictionVisibility: PredictionVisibility
    let showEmail: Bool
    let allowDirectMessages: Bool
    let showOnlineStatus: Bool
    
    init() {
        self.profileVisibility = .public
        self.predictionVisibility = .public
        self.showEmail = false
        self.allowDirectMessages = true
        self.showOnlineStatus = true
    }
}

struct DisplaySettings: Codable {
    let theme: AppTheme
    let fontSize: FontSize
    let showImages: Bool
    let autoPlayVideos: Bool
    let compactMode: Bool
    
    init() {
        self.theme = .system
        self.fontSize = .medium
        self.showImages = true
        self.autoPlayVideos = false
        self.compactMode = false
    }
}

enum ProfileVisibility: String, CaseIterable, Codable {
    case `public` = "public"
    case friends = "friends"
    case private = "private"
}

enum PredictionVisibility: String, CaseIterable, Codable {
    case `public` = "public"
    case friends = "friends"
    case private = "private"
}

enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

enum FontSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
}

enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "free"
    case premium = "premium"
    case vip = "vip"
}

struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let earnedDate: Date
    let rarity: BadgeRarity
}

enum BadgeRarity: String, CaseIterable, Codable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
}

enum NewsCategory: String, CaseIterable, Codable {
    case wwe = "WWE"
    case aew = "AEW"
    case njpw = "NJPW"
    case impact = "Impact"
    case indie = "Independent"
    case general = "General"
    case rumors = "Rumors"
    case spoilers = "Spoilers"
    case backstage = "Backstage"
    case business = "Business"
}

// MARK: - Sample Data
extension User {
    static let sample = User(
        username: "WrestleFan2024",
        email: "wrestlefan@example.com",
        displayName: "WrestleFan2024"
    )
}