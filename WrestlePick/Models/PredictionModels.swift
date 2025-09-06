import Foundation

// MARK: - Prediction Types
enum PredictionType: String, CaseIterable, Codable {
    case ppvMatch = "PPV Match"
    case monthlyAward = "Monthly Award"
    case storyline = "Storyline"
    case hotTake = "Hot Take"
    case safePick = "Safe Pick"
    case customContest = "Custom Contest"
    
    var iconName: String {
        switch self {
        case .ppvMatch: return "trophy"
        case .monthlyAward: return "calendar"
        case .storyline: return "book"
        case .hotTake: return "flame"
        case .safePick: return "shield"
        case .customContest: return "star"
        }
    }
    
    var color: String {
        switch self {
        case .ppvMatch: return "blue"
        case .monthlyAward: return "purple"
        case .storyline: return "green"
        case .hotTake: return "red"
        case .safePick: return "gray"
        case .customContest: return "orange"
        }
    }
}

// MARK: - Prediction Status
enum PredictionStatus: String, CaseIterable, Codable {
    case draft = "draft"
    case submitted = "submitted"
    case locked = "locked"
    case resolved = "resolved"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .locked: return "Locked"
        case .resolved: return "Resolved"
        case .cancelled: return "Cancelled"
        }
    }
    
    var canEdit: Bool {
        return self == .draft || self == .submitted
    }
}

// MARK: - Confidence Level
enum ConfidenceLevel: Int, CaseIterable, Codable {
    case veryLow = 1
    case low = 2
    case belowAverage = 3
    case average = 4
    case aboveAverage = 5
    case good = 6
    case veryGood = 7
    case excellent = 8
    case outstanding = 9
    case perfect = 10
    
    var displayName: String {
        switch self {
        case .veryLow: return "Very Low (1)"
        case .low: return "Low (2)"
        case .belowAverage: return "Below Average (3)"
        case .average: return "Average (4)"
        case .aboveAverage: return "Above Average (5)"
        case .good: return "Good (6)"
        case .veryGood: return "Very Good (7)"
        case .excellent: return "Excellent (8)"
        case .outstanding: return "Outstanding (9)"
        case .perfect: return "Perfect (10)"
        }
    }
    
    var color: String {
        switch self {
        case .veryLow, .low: return "red"
        case .belowAverage, .average: return "orange"
        case .aboveAverage, .good: return "yellow"
        case .veryGood, .excellent: return "green"
        case .outstanding, .perfect: return "blue"
        }
    }
    
    var multiplier: Double {
        return Double(rawValue) / 10.0
    }
}

// MARK: - Prediction Pick
struct PredictionPick: Codable, Identifiable {
    let id: String
    let wrestlerName: String
    let wrestlerImageURL: String?
    let position: Int // For ordering in drag-and-drop
    let isWinner: Bool?
    let notes: String?
    
    init(wrestlerName: String, wrestlerImageURL: String? = nil, position: Int = 0, isWinner: Bool? = nil, notes: String? = nil) {
        self.id = UUID().uuidString
        self.wrestlerName = wrestlerName
        self.wrestlerImageURL = wrestlerImageURL
        self.position = position
        self.isWinner = isWinner
        self.notes = notes
    }
}

// MARK: - Prediction Accuracy
struct PredictionAccuracy: Codable {
    let isCorrect: Bool
    let pointsEarned: Int
    let accuracyScore: Double
    let bonusMultiplier: Double
    let resolvedAt: Date?
    
    init(isCorrect: Bool, pointsEarned: Int, accuracyScore: Double, bonusMultiplier: Double = 1.0, resolvedAt: Date? = nil) {
        self.isCorrect = isCorrect
        self.pointsEarned = pointsEarned
        self.accuracyScore = accuracyScore
        self.bonusMultiplier = bonusMultiplier
        self.resolvedAt = resolvedAt
    }
}

// MARK: - Prediction Engagement
struct PredictionEngagement: Codable {
    let likes: Int
    let comments: Int
    let shares: Int
    let views: Int
    let bookmarks: Int
    
    init(likes: Int = 0, comments: Int = 0, shares: Int = 0, views: Int = 0, bookmarks: Int = 0) {
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.views = views
        self.bookmarks = bookmarks
    }
}

// MARK: - Group Prediction
struct GroupPrediction: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let createdByUserId: String
    let createdByUsername: String
    let participants: [String] // User IDs
    let predictionType: PredictionType
    let eventId: String?
    let deadline: Date
    let isPublic: Bool
    let maxParticipants: Int?
    let entryFee: Int? // Points required to join
    let prizePool: Int // Total points to distribute
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, description: String, createdByUserId: String, createdByUsername: String, participants: [String] = [], predictionType: PredictionType, eventId: String? = nil, deadline: Date, isPublic: Bool = true, maxParticipants: Int? = nil, entryFee: Int? = nil, prizePool: Int = 0) {
        self.name = name
        self.description = description
        self.createdByUserId = createdByUserId
        self.createdByUsername = createdByUsername
        self.participants = participants
        self.predictionType = predictionType
        self.eventId = eventId
        self.deadline = deadline
        self.isPublic = isPublic
        self.maxParticipants = maxParticipants
        self.entryFee = entryFee
        self.prizePool = prizePool
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let profileImageURL: String?
    let rank: Int
    let points: Int
    let accuracy: Double
    let totalPredictions: Int
    let correctPredictions: Int
    let currentStreak: Int
    let longestStreak: Int
    let period: LeaderboardPeriod
    
    init(userId: String, username: String, displayName: String, profileImageURL: String? = nil, rank: Int, points: Int, accuracy: Double, totalPredictions: Int, correctPredictions: Int, currentStreak: Int, longestStreak: Int, period: LeaderboardPeriod) {
        self.id = userId
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.rank = rank
        self.points = points
        self.accuracy = accuracy
        self.totalPredictions = totalPredictions
        self.correctPredictions = correctPredictions
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.period = period
    }
}

// MARK: - Leaderboard Period
enum LeaderboardPeriod: String, CaseIterable, Codable {
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "allTime"
    
    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .allTime: return "All Time"
        }
    }
}

// MARK: - Prediction Contest
struct PredictionContest: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let createdByUserId: String
    let predictionType: PredictionType
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let maxParticipants: Int?
    let entryRequirements: [String] // Requirements to join
    let prizes: [ContestPrize]
    let participants: [String] // User IDs
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, description: String, createdByUserId: String, predictionType: PredictionType, startDate: Date, endDate: Date, isActive: Bool = true, maxParticipants: Int? = nil, entryRequirements: [String] = [], prizes: [ContestPrize] = []) {
        self.name = name
        self.description = description
        self.createdByUserId = createdByUserId
        self.predictionType = predictionType
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.maxParticipants = maxParticipants
        self.entryRequirements = entryRequirements
        self.prizes = prizes
        self.participants = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Contest Prize
struct ContestPrize: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let points: Int
    let position: Int // 1st, 2nd, 3rd, etc.
    let isSpecial: Bool // Special badges, titles, etc.
    
    init(name: String, description: String, points: Int, position: Int, isSpecial: Bool = false) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.points = points
        self.position = position
        self.isSpecial = isSpecial
    }
}

// MARK: - Prediction Scoring
struct PredictionScoring {
    static func calculatePoints(
        isCorrect: Bool,
        confidenceLevel: ConfidenceLevel,
        predictionType: PredictionType,
        timeBonus: Bool = false,
        streakBonus: Int = 0
    ) -> Int {
        guard isCorrect else { return 0 }
        
        let basePoints = 10
        let confidenceMultiplier = confidenceLevel.multiplier
        let typeMultiplier = getTypeMultiplier(predictionType)
        let timeBonusMultiplier = timeBonus ? 1.2 : 1.0
        let streakMultiplier = 1.0 + (Double(streakBonus) * 0.1)
        
        let totalPoints = Int(Double(basePoints) * confidenceMultiplier * typeMultiplier * timeBonusMultiplier * streakMultiplier)
        
        return max(1, totalPoints)
    }
    
    static func getTypeMultiplier(_ type: PredictionType) -> Double {
        switch type {
        case .ppvMatch: return 1.0
        case .monthlyAward: return 1.2
        case .storyline: return 1.5
        case .hotTake: return 2.0
        case .safePick: return 0.8
        case .customContest: return 1.3
        }
    }
    
    static func calculateAccuracyScore(
        correctPredictions: Int,
        totalPredictions: Int,
        averageConfidence: Double
    ) -> Double {
        guard totalPredictions > 0 else { return 0.0 }
        
        let baseAccuracy = Double(correctPredictions) / Double(totalPredictions)
        let confidenceAdjustment = averageConfidence * 0.1 // Slight bonus for higher confidence
        
        return min(1.0, baseAccuracy + confidenceAdjustment)
    }
}

// MARK: - Extensions
extension Prediction {
    var isLocked: Bool {
        return status == .locked || Date() > deadline
    }
    
    var canEdit: Bool {
        return status.canEdit && !isLocked
    }
    
    var timeUntilDeadline: TimeInterval {
        return deadline.timeIntervalSinceNow
    }
    
    var isOverdue: Bool {
        return timeUntilDeadline < 0
    }
    
    var confidenceColor: String {
        return confidenceLevel.color
    }
    
    var typeColor: String {
        return predictionType.color
    }
}
