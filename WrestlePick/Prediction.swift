import Foundation
import FirebaseFirestore

struct Prediction: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let title: String
    let description: String
    let category: PredictionCategory
    let subcategory: String?
    let eventId: String?
    let eventName: String?
    let eventDate: Date
    let createdDate: Date
    let status: PredictionStatus
    let confidence: Int // 1-10 scale
    let tags: [String]
    let isPublic: Bool
    let picks: [PredictionPick]
    let accuracy: PredictionAccuracy?
    let engagement: PredictionEngagement
    let visibility: PredictionVisibility
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: String, username: String, title: String, description: String, category: PredictionCategory, eventDate: Date) {
        self.userId = userId
        self.username = username
        self.title = title
        self.description = description
        self.category = category
        self.subcategory = nil
        self.eventId = nil
        self.eventName = nil
        self.eventDate = eventDate
        self.createdDate = Date()
        self.status = .pending
        self.confidence = 5
        self.tags = []
        self.isPublic = true
        self.picks = []
        self.accuracy = nil
        self.engagement = PredictionEngagement()
        self.visibility = .public
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct PredictionPick: Identifiable, Codable {
    let id: String
    let type: PickType
    let title: String
    let description: String
    let options: [PickOption]
    let selectedOption: String?
    let isCorrect: Bool?
    let points: Int
    let weight: Double // 0.0 to 1.0 for scoring
    
    init(type: PickType, title: String, description: String, options: [PickOption], weight: Double = 1.0) {
        self.id = UUID().uuidString
        self.type = type
        self.title = title
        self.description = description
        self.options = options
        self.selectedOption = nil
        self.isCorrect = nil
        self.points = 0
        self.weight = weight
    }
}

struct PickOption: Identifiable, Codable {
    let id: String
    let text: String
    let description: String?
    let isCorrect: Bool?
    let odds: Double? // Decimal odds
    let probability: Double? // 0.0 to 1.0
    
    init(text: String, description: String? = nil, odds: Double? = nil, probability: Double? = nil) {
        self.id = UUID().uuidString
        self.text = text
        self.description = description
        self.isCorrect = nil
        self.odds = odds
        self.probability = probability
    }
}

enum PickType: String, CaseIterable, Codable {
    case winner = "winner"
    case method = "method"
    case time = "time"
    case stipulation = "stipulation"
    case appearance = "appearance"
    case titleChange = "title_change"
    case debut = "debut"
    case return = "return"
    case release = "release"
    case other = "other"
}

enum PredictionCategory: String, CaseIterable, Codable {
    case match = "Match"
    case storyline = "Storyline"
    case title = "Title Change"
    case debut = "Debut"
    case return = "Return"
    case release = "Release"
    case contract = "Contract"
    case backstage = "Backstage"
    case business = "Business"
    case other = "Other"
}

enum PredictionStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case correct = "Correct"
    case incorrect = "Incorrect"
    case cancelled = "Cancelled"
    case partial = "Partial"
    case disputed = "Disputed"
}

enum PredictionVisibility: String, CaseIterable, Codable {
    case `public` = "public"
    case friends = "friends"
    case private = "private"
    case followers = "followers"
}

struct PredictionAccuracy: Codable {
    let overallScore: Double // 0.0 to 1.0
    let correctPicks: Int
    let totalPicks: Int
    let accuracyPercentage: Double
    let pointsEarned: Int
    let bonusPoints: Int
    let streakBonus: Int
    let difficultyMultiplier: Double
    let calculatedAt: Date
    
    init(correctPicks: Int, totalPicks: Int, pointsEarned: Int, difficultyMultiplier: Double = 1.0) {
        self.correctPicks = correctPicks
        self.totalPicks = totalPicks
        self.accuracyPercentage = totalPicks > 0 ? Double(correctPicks) / Double(totalPicks) : 0.0
        self.overallScore = self.accuracyPercentage * difficultyMultiplier
        self.pointsEarned = pointsEarned
        self.bonusPoints = 0
        self.streakBonus = 0
        self.difficultyMultiplier = difficultyMultiplier
        self.calculatedAt = Date()
    }
}

struct PredictionEngagement: Codable {
    let views: Int
    let likes: Int
    let dislikes: Int
    let comments: Int
    let shares: Int
    let bookmarks: Int
    let reactions: [ReactionType: Int]
    
    init() {
        self.views = 0
        self.likes = 0
        self.dislikes = 0
        self.comments = 0
        self.shares = 0
        self.bookmarks = 0
        self.reactions = [:]
    }
}

enum ReactionType: String, CaseIterable, Codable {
    case like = "like"
    case love = "love"
    case laugh = "laugh"
    case wow = "wow"
    case sad = "sad"
    case angry = "angry"
    case fire = "fire"
    case thinking = "thinking"
}

// Prediction Leaderboard
struct PredictionLeaderboard: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let displayName: String
    let profileImageURL: String?
    let totalPredictions: Int
    let correctPredictions: Int
    let accuracy: Double
    let totalPoints: Int
    let rank: Int
    let tier: PredictionTier
    let badges: [Badge]
    let currentStreak: Int
    let longestStreak: Int
    let lastUpdated: Date
    
    init(userId: String, username: String, displayName: String) {
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.profileImageURL = nil
        self.totalPredictions = 0
        self.correctPredictions = 0
        self.accuracy = 0.0
        self.totalPoints = 0
        self.rank = 0
        self.tier = .rookie
        self.badges = []
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastUpdated = Date()
    }
}

enum PredictionTier: String, CaseIterable, Codable {
    case rookie = "rookie"
    case contender = "contender"
    case expert = "expert"
    case master = "master"
    case legend = "legend"
    case hallOfFame = "hall_of_fame"
}