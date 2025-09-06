import Foundation
import FirebaseFirestore

// MARK: - Social User
struct SocialUser: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let displayName: String
    let avatarURL: String?
    let bio: String
    let isVerified: Bool
    let followerCount: Int
    let followingCount: Int
    let predictionAccuracy: Double
    let totalPredictions: Int
    let achievements: [Achievement]
    let socialStats: SocialStats
    let privacySettings: PrivacySettings
    let createdAt: Date
    let lastActiveAt: Date
    
    init(userId: String, username: String, displayName: String, avatarURL: String? = nil, bio: String = "", isVerified: Bool = false, followerCount: Int = 0, followingCount: Int = 0, predictionAccuracy: Double = 0.0, totalPredictions: Int = 0, achievements: [Achievement] = [], socialStats: SocialStats = SocialStats(), privacySettings: PrivacySettings = PrivacySettings()) {
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
        self.isVerified = isVerified
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.predictionAccuracy = predictionAccuracy
        self.totalPredictions = totalPredictions
        self.achievements = achievements
        self.socialStats = socialStats
        self.privacySettings = privacySettings
        self.createdAt = Date()
        self.lastActiveAt = Date()
    }
}

// MARK: - Social Stats
struct SocialStats: Codable {
    let postsCount: Int
    let commentsCount: Int
    let likesReceived: Int
    let sharesReceived: Int
    let predictionsShared: Int
    let awardsCreated: Int
    let leagueWins: Int
    let reputationScore: Double
    let streakDays: Int
    let lastPostAt: Date?
    
    init(postsCount: Int = 0, commentsCount: Int = 0, likesReceived: Int = 0, sharesReceived: Int = 0, predictionsShared: Int = 0, awardsCreated: Int = 0, leagueWins: Int = 0, reputationScore: Double = 0.0, streakDays: Int = 0, lastPostAt: Date? = nil) {
        self.postsCount = postsCount
        self.commentsCount = commentsCount
        self.likesReceived = likesReceived
        self.sharesReceived = sharesReceived
        self.predictionsShared = predictionsShared
        self.awardsCreated = awardsCreated
        self.leagueWins = leagueWins
        self.reputationScore = reputationScore
        self.streakDays = streakDays
        self.lastPostAt = lastPostAt
    }
}

// MARK: - Privacy Settings
struct PrivacySettings: Codable {
    let isPublic: Bool
    let showPredictions: Bool
    let showAchievements: Bool
    let showActivity: Bool
    let allowMessages: Bool
    let allowFollows: Bool
    let showLocation: Bool
    let showEmail: Bool
    
    init(isPublic: Bool = true, showPredictions: Bool = true, showAchievements: Bool = true, showActivity: Bool = true, allowMessages: Bool = true, allowFollows: Bool = true, showLocation: Bool = false, showEmail: Bool = false) {
        self.isPublic = isPublic
        self.showPredictions = showPredictions
        self.showAchievements = showAchievements
        self.showActivity = showActivity
        self.allowMessages = allowMessages
        self.allowFollows = allowFollows
        self.showLocation = showLocation
        self.showEmail = showEmail
    }
}

// MARK: - Social Post
struct SocialPost: Codable, Identifiable {
    @DocumentID var id: String?
    let authorId: String
    let authorUsername: String
    let authorDisplayName: String
    let authorAvatarURL: String?
    let content: String
    let postType: PostType
    let mediaURLs: [String]
    let hashtags: [String]
    let mentions: [String]
    let linkedPredictionId: String?
    let linkedNewsId: String?
    let linkedAwardId: String?
    let engagement: PostEngagement
    let moderationStatus: ModerationStatus
    let createdAt: Date
    let updatedAt: Date
    
    init(authorId: String, authorUsername: String, authorDisplayName: String, authorAvatarURL: String? = nil, content: String, postType: PostType, mediaURLs: [String] = [], hashtags: [String] = [], mentions: [String] = [], linkedPredictionId: String? = nil, linkedNewsId: String? = nil, linkedAwardId: String? = nil, engagement: PostEngagement = PostEngagement(), moderationStatus: ModerationStatus = .pending) {
        self.authorId = authorId
        self.authorUsername = authorUsername
        self.authorDisplayName = authorDisplayName
        self.authorAvatarURL = authorAvatarURL
        self.content = content
        self.postType = postType
        self.mediaURLs = mediaURLs
        self.hashtags = hashtags
        self.mentions = mentions
        self.linkedPredictionId = linkedPredictionId
        self.linkedNewsId = linkedNewsId
        self.linkedAwardId = linkedAwardId
        self.engagement = engagement
        self.moderationStatus = moderationStatus
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Post Type
enum PostType: String, CaseIterable, Codable {
    case prediction = "prediction"
    case news = "news"
    case achievement = "achievement"
    case award = "award"
    case discussion = "discussion"
    case poll = "poll"
    case general = "general"
    
    var iconName: String {
        switch self {
        case .prediction: return "crystal.ball"
        case .news: return "newspaper"
        case .achievement: return "trophy"
        case .award: return "star"
        case .discussion: return "bubble.left.and.bubble.right"
        case .poll: return "chart.bar"
        case .general: return "text.bubble"
        }
    }
    
    var color: String {
        switch self {
        case .prediction: return "blue"
        case .news: return "green"
        case .achievement: return "yellow"
        case .award: return "purple"
        case .discussion: return "orange"
        case .poll: return "red"
        case .general: return "gray"
        }
    }
}

// MARK: - Post Engagement
struct PostEngagement: Codable {
    let likes: Int
    let comments: Int
    let shares: Int
    let views: Int
    let bookmarks: Int
    let reports: Int
    let isLiked: Bool
    let isBookmarked: Bool
    let isShared: Bool
    
    init(likes: Int = 0, comments: Int = 0, shares: Int = 0, views: Int = 0, bookmarks: Int = 0, reports: Int = 0, isLiked: Bool = false, isBookmarked: Bool = false, isShared: Bool = false) {
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.views = views
        self.bookmarks = bookmarks
        self.reports = reports
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.isShared = isShared
    }
}

// MARK: - Comment
struct Comment: Codable, Identifiable {
    @DocumentID var id: String?
    let postId: String
    let authorId: String
    let authorUsername: String
    let authorDisplayName: String
    let authorAvatarURL: String?
    let content: String
    let parentCommentId: String?
    let replies: [Comment]
    let engagement: CommentEngagement
    let moderationStatus: ModerationStatus
    let createdAt: Date
    let updatedAt: Date
    
    init(postId: String, authorId: String, authorUsername: String, authorDisplayName: String, authorAvatarURL: String? = nil, content: String, parentCommentId: String? = nil, replies: [Comment] = [], engagement: CommentEngagement = CommentEngagement(), moderationStatus: ModerationStatus = .pending) {
        self.postId = postId
        self.authorId = authorId
        self.authorUsername = authorUsername
        self.authorDisplayName = authorDisplayName
        self.authorAvatarURL = authorAvatarURL
        self.content = content
        self.parentCommentId = parentCommentId
        self.replies = replies
        self.engagement = engagement
        self.moderationStatus = moderationStatus
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Comment Engagement
struct CommentEngagement: Codable {
    let likes: Int
    let replies: Int
    let reports: Int
    let isLiked: Bool
    
    init(likes: Int = 0, replies: Int = 0, reports: Int = 0, isLiked: Bool = false) {
        self.likes = likes
        self.replies = replies
        self.reports = reports
        self.isLiked = isLiked
    }
}

// MARK: - League
struct League: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let creatorId: String
    let creatorUsername: String
    let isPublic: Bool
    let maxMembers: Int
    let currentMembers: Int
    let members: [LeagueMember]
    let rules: [String]
    let scoringSystem: ScoringSystem
    let season: LeagueSeason
    let status: LeagueStatus
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, description: String, creatorId: String, creatorUsername: String, isPublic: Bool = true, maxMembers: Int = 20, currentMembers: Int = 1, members: [LeagueMember] = [], rules: [String] = [], scoringSystem: ScoringSystem = ScoringSystem(), season: LeagueSeason = LeagueSeason(), status: LeagueStatus = .active) {
        self.name = name
        self.description = description
        self.creatorId = creatorId
        self.creatorUsername = creatorUsername
        self.isPublic = isPublic
        self.maxMembers = maxMembers
        self.currentMembers = currentMembers
        self.members = members
        self.rules = rules
        self.scoringSystem = scoringSystem
        self.season = season
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - League Member
struct LeagueMember: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let avatarURL: String?
    let joinedAt: Date
    let isAdmin: Bool
    let isActive: Bool
    let stats: LeagueMemberStats
    
    init(userId: String, username: String, displayName: String, avatarURL: String? = nil, isAdmin: Bool = false, isActive: Bool = true, stats: LeagueMemberStats = LeagueMemberStats()) {
        self.id = UUID().uuidString
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.joinedAt = Date()
        self.isAdmin = isAdmin
        self.isActive = isActive
        self.stats = stats
    }
}

// MARK: - League Member Stats
struct LeagueMemberStats: Codable {
    let totalPoints: Int
    let correctPredictions: Int
    let totalPredictions: Int
    let accuracy: Double
    let rank: Int
    let streak: Int
    let lastPredictionAt: Date?
    
    init(totalPoints: Int = 0, correctPredictions: Int = 0, totalPredictions: Int = 0, accuracy: Double = 0.0, rank: Int = 0, streak: Int = 0, lastPredictionAt: Date? = nil) {
        self.totalPoints = totalPoints
        self.correctPredictions = correctPredictions
        self.totalPredictions = totalPredictions
        self.accuracy = accuracy
        self.rank = rank
        self.streak = streak
        self.lastPredictionAt = lastPredictionAt
    }
}

// MARK: - Scoring System
struct ScoringSystem: Codable {
    let correctPrediction: Int
    let confidenceBonus: Int
    let streakBonus: Int
    let perfectWeek: Int
    let perfectMonth: Int
    let participation: Int
    
    init(correctPrediction: Int = 10, confidenceBonus: Int = 5, streakBonus: Int = 2, perfectWeek: Int = 50, perfectMonth: Int = 200, participation: Int = 1) {
        self.correctPrediction = correctPrediction
        self.confidenceBonus = confidenceBonus
        self.streakBonus = streakBonus
        self.perfectWeek = perfectWeek
        self.perfectMonth = perfectMonth
        self.participation = participation
    }
}

// MARK: - League Season
struct LeagueSeason: Codable {
    let name: String
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let totalWeeks: Int
    let currentWeek: Int
    
    init(name: String, startDate: Date, endDate: Date, isActive: Bool = true, totalWeeks: Int = 12, currentWeek: Int = 1) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.totalWeeks = totalWeeks
        self.currentWeek = currentWeek
    }
}

// MARK: - League Status
enum LeagueStatus: String, CaseIterable, Codable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var color: String {
        switch self {
        case .active: return "green"
        case .paused: return "yellow"
        case .completed: return "blue"
        case .cancelled: return "red"
        }
    }
}

// MARK: - User Award
struct UserAward: Codable, Identifiable {
    @DocumentID var id: String?
    let creatorId: String
    let creatorUsername: String
    let name: String
    let description: String
    let category: AwardCategory
    let criteria: [String]
    let nominees: [AwardNominee]
    let votingEndsAt: Date
    let isPublic: Bool
    let status: AwardStatus
    let createdAt: Date
    let updatedAt: Date
    
    init(creatorId: String, creatorUsername: String, name: String, description: String, category: AwardCategory, criteria: [String] = [], nominees: [AwardNominee] = [], votingEndsAt: Date, isPublic: Bool = true, status: AwardStatus = .open) {
        self.creatorId = creatorId
        self.creatorUsername = creatorUsername
        self.name = name
        self.description = description
        self.category = category
        self.criteria = criteria
        self.nominees = nominees
        self.votingEndsAt = votingEndsAt
        self.isPublic = isPublic
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Award Category
enum AwardCategory: String, CaseIterable, Codable {
    case matchOfTheYear = "matchOfTheYear"
    case wrestlerOfTheYear = "wrestlerOfTheYear"
    case feudOfTheYear = "feudOfTheYear"
    case momentOfTheYear = "momentOfTheYear"
    case promoOfTheYear = "promoOfTheYear"
    case tagTeamOfTheYear = "tagTeamOfTheYear"
    case newcomerOfTheYear = "newcomerOfTheYear"
    case comebackOfTheYear = "comebackOfTheYear"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .matchOfTheYear: return "Match of the Year"
        case .wrestlerOfTheYear: return "Wrestler of the Year"
        case .feudOfTheYear: return "Feud of the Year"
        case .momentOfTheYear: return "Moment of the Year"
        case .promoOfTheYear: return "Promo of the Year"
        case .tagTeamOfTheYear: return "Tag Team of the Year"
        case .newcomerOfTheYear: return "Newcomer of the Year"
        case .comebackOfTheYear: return "Comeback of the Year"
        case .custom: return "Custom Award"
        }
    }
    
    var iconName: String {
        switch self {
        case .matchOfTheYear: return "figure.wrestling"
        case .wrestlerOfTheYear: return "person.crop.circle"
        case .feudOfTheYear: return "person.2"
        case .momentOfTheYear: return "star"
        case .promoOfTheYear: return "mic"
        case .tagTeamOfTheYear: return "person.2.circle"
        case .newcomerOfTheYear: return "person.badge.plus"
        case .comebackOfTheYear: return "arrow.clockwise"
        case .custom: return "wrench"
        }
    }
}

// MARK: - Award Nominee
struct AwardNominee: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let imageURL: String?
    let votes: Int
    let percentage: Double
    
    init(name: String, description: String, imageURL: String? = nil, votes: Int = 0, percentage: Double = 0.0) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.votes = votes
        self.percentage = percentage
    }
}

// MARK: - Award Status
enum AwardStatus: String, CaseIterable, Codable {
    case open = "open"
    case voting = "voting"
    case closed = "closed"
    case cancelled = "cancelled"
    
    var color: String {
        switch self {
        case .open: return "green"
        case .voting: return "blue"
        case .closed: return "gray"
        case .cancelled: return "red"
        }
    }
}

// MARK: - Poll
struct Poll: Codable, Identifiable {
    @DocumentID var id: String?
    let creatorId: String
    let creatorUsername: String
    let question: String
    let options: [PollOption]
    let expiresAt: Date
    let isPublic: Bool
    let allowMultiple: Bool
    let totalVotes: Int
    let status: PollStatus
    let createdAt: Date
    
    init(creatorId: String, creatorUsername: String, question: String, options: [PollOption], expiresAt: Date, isPublic: Bool = true, allowMultiple: Bool = false, totalVotes: Int = 0, status: PollStatus = .active) {
        self.creatorId = creatorId
        self.creatorUsername = creatorUsername
        self.question = question
        self.options = options
        self.expiresAt = expiresAt
        self.isPublic = isPublic
        self.allowMultiple = allowMultiple
        self.totalVotes = totalVotes
        self.status = status
        self.createdAt = Date()
    }
}

// MARK: - Poll Option
struct PollOption: Codable, Identifiable {
    let id: String
    let text: String
    let votes: Int
    let percentage: Double
    
    init(text: String, votes: Int = 0, percentage: Double = 0.0) {
        self.id = UUID().uuidString
        self.text = text
        self.votes = votes
        self.percentage = percentage
    }
}

// MARK: - Poll Status
enum PollStatus: String, CaseIterable, Codable {
    case active = "active"
    case expired = "expired"
    case cancelled = "cancelled"
    
    var color: String {
        switch self {
        case .active: return "green"
        case .expired: return "gray"
        case .cancelled: return "red"
        }
    }
}

// MARK: - Moderation Report
struct ModerationReport: Codable, Identifiable {
    @DocumentID var id: String?
    let reporterId: String
    let reportedUserId: String
    let reportedContentId: String
    let contentType: ContentType
    let reason: ReportReason
    let description: String
    let status: ReportStatus
    let moderatorId: String?
    let moderatorNotes: String?
    let createdAt: Date
    let resolvedAt: Date?
    
    init(reporterId: String, reportedUserId: String, reportedContentId: String, contentType: ContentType, reason: ReportReason, description: String, status: ReportStatus = .pending, moderatorId: String? = nil, moderatorNotes: String? = nil, resolvedAt: Date? = nil) {
        self.reporterId = reporterId
        self.reportedUserId = reportedUserId
        self.reportedContentId = reportedContentId
        self.contentType = contentType
        self.reason = reason
        self.description = description
        self.status = status
        self.moderatorId = moderatorId
        self.moderatorNotes = moderatorNotes
        self.resolvedAt = resolvedAt
        self.createdAt = Date()
    }
}

// MARK: - Content Type
enum ContentType: String, CaseIterable, Codable {
    case post = "post"
    case comment = "comment"
    case prediction = "prediction"
    case award = "award"
    case poll = "poll"
    case user = "user"
    
    var displayName: String {
        switch self {
        case .post: return "Post"
        case .comment: return "Comment"
        case .prediction: return "Prediction"
        case .award: return "Award"
        case .poll: return "Poll"
        case .user: return "User"
        }
    }
}

// MARK: - Report Reason
enum ReportReason: String, CaseIterable, Codable {
    case spam = "spam"
    case harassment = "harassment"
    case hateSpeech = "hateSpeech"
    case inappropriateContent = "inappropriateContent"
    case falseInformation = "falseInformation"
    case impersonation = "impersonation"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .hateSpeech: return "Hate Speech"
        case .inappropriateContent: return "Inappropriate Content"
        case .falseInformation: return "False Information"
        case .impersonation: return "Impersonation"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .spam: return "exclamationmark.triangle"
        case .harassment: return "person.crop.circle.badge.exclamationmark"
        case .hateSpeech: return "exclamationmark.octagon"
        case .inappropriateContent: return "eye.slash"
        case .falseInformation: return "questionmark.circle"
        case .impersonation: return "person.crop.circle.badge.xmark"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Report Status
enum ReportStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case underReview = "underReview"
    case resolved = "resolved"
    case dismissed = "dismissed"
    case escalated = "escalated"
    
    var color: String {
        switch self {
        case .pending: return "yellow"
        case .underReview: return "blue"
        case .resolved: return "green"
        case .dismissed: return "gray"
        case .escalated: return "red"
        }
    }
}

// MARK: - Moderation Status
enum ModerationStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case flagged = "flagged"
    case underReview = "underReview"
    
    var color: String {
        switch self {
        case .pending: return "yellow"
        case .approved: return "green"
        case .rejected: return "red"
        case .flagged: return "orange"
        case .underReview: return "blue"
        }
    }
}

// MARK: - Achievement
struct Achievement: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let points: Int
    let isUnlocked: Bool
    let unlockedAt: Date?
    let progress: Double
    
    init(name: String, description: String, iconName: String, category: AchievementCategory, rarity: AchievementRarity, points: Int, isUnlocked: Bool = false, unlockedAt: Date? = nil, progress: Double = 0.0) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.rarity = rarity
        self.points = points
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.progress = progress
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String, CaseIterable, Codable {
    case prediction = "prediction"
    case social = "social"
    case league = "league"
    case community = "community"
    case special = "special"
    
    var displayName: String {
        switch self {
        case .prediction: return "Prediction"
        case .social: return "Social"
        case .league: return "League"
        case .community: return "Community"
        case .special: return "Special"
        }
    }
}

// MARK: - Achievement Rarity
enum AchievementRarity: String, CaseIterable, Codable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "green"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
}

// MARK: - Follow Relationship
struct FollowRelationship: Codable, Identifiable {
    @DocumentID var id: String?
    let followerId: String
    let followingId: String
    let createdAt: Date
    
    init(followerId: String, followingId: String) {
        self.followerId = followerId
        self.followingId = followingId
        self.createdAt = Date()
    }
}

// MARK: - Extensions
extension SocialUser {
    var displayNameOrUsername: String {
        return displayName.isEmpty ? username : displayName
    }
    
    var isOnline: Bool {
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        return lastActiveAt > fiveMinutesAgo
    }
}

extension SocialPost {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

extension Comment {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
