import Foundation
import FirebaseFirestore

struct Award: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let category: AwardCategory
    let subcategory: String?
    let year: Int
    let createdBy: String
    let createdByUsername: String
    let isPublic: Bool
    let isOfficial: Bool
    let status: AwardStatus
    let votingPeriod: VotingPeriod
    let nominees: [AwardNominee]
    let winner: AwardWinner?
    let results: AwardResults?
    let engagement: AwardEngagement
    let rules: AwardRules
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, description: String, category: AwardCategory, year: Int, createdBy: String, createdByUsername: String) {
        self.name = name
        self.description = description
        self.category = category
        self.subcategory = nil
        self.year = year
        self.createdBy = createdBy
        self.createdByUsername = createdByUsername
        self.isPublic = true
        self.isOfficial = false
        self.status = .draft
        self.votingPeriod = VotingPeriod()
        self.nominees = []
        self.winner = nil
        self.results = nil
        self.engagement = AwardEngagement()
        self.rules = AwardRules()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct AwardNominee: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let imageURL: String?
    let category: String
    let subcategory: String?
    let votes: Int
    let percentage: Double
    let isWinner: Bool
    let addedBy: String
    let addedDate: Date
    
    init(name: String, description: String, category: String, addedBy: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.imageURL = nil
        self.category = category
        self.subcategory = nil
        self.votes = 0
        self.percentage = 0.0
        self.isWinner = false
        self.addedBy = addedBy
        self.addedDate = Date()
    }
}

struct AwardWinner: Codable {
    let nomineeId: String
    let name: String
    let votes: Int
    let percentage: Double
    let announcedDate: Date
    let announcedBy: String
    let acceptanceSpeech: String?
    let imageURL: String?
    
    init(nomineeId: String, name: String, votes: Int, percentage: Double, announcedBy: String) {
        self.nomineeId = nomineeId
        self.name = name
        self.votes = votes
        self.percentage = percentage
        self.announcedDate = Date()
        self.announcedBy = announcedBy
        self.acceptanceSpeech = nil
        self.imageURL = nil
    }
}

struct AwardResults: Codable {
    let totalVotes: Int
    let totalVoters: Int
    let votingDuration: TimeInterval
    let results: [AwardResult]
    let announcedDate: Date
    let announcedBy: String
    
    init(totalVotes: Int, totalVoters: Int, votingDuration: TimeInterval, announcedBy: String) {
        self.totalVotes = totalVotes
        self.totalVoters = totalVoters
        self.votingDuration = votingDuration
        self.results = []
        self.announcedDate = Date()
        self.announcedBy = announcedBy
    }
}

struct AwardResult: Codable {
    let nomineeId: String
    let name: String
    let votes: Int
    let percentage: Double
    let rank: Int
    let isWinner: Bool
}

struct AwardEngagement: Codable {
    let views: Int
    let votes: Int
    let comments: Int
    let shares: Int
    let bookmarks: Int
    let discussions: Int
    
    init() {
        self.views = 0
        self.votes = 0
        self.comments = 0
        self.shares = 0
        self.bookmarks = 0
        self.discussions = 0
    }
}

struct AwardRules: Codable {
    let votingType: VotingType
    let maxVotesPerUser: Int
    let allowMultipleVotes: Bool
    let requireVerification: Bool
    let minVotesToWin: Int
    let tieBreaker: TieBreaker
    let eligibilityCriteria: [String]
    let disqualificationRules: [String]
    
    init() {
        self.votingType = .single
        self.maxVotesPerUser = 1
        self.allowMultipleVotes = false
        self.requireVerification = false
        self.minVotesToWin = 1
        self.tieBreaker = .firstToReach
        self.eligibilityCriteria = []
        self.disqualificationRules = []
    }
}

struct VotingPeriod: Codable {
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let duration: TimeInterval
    let timeRemaining: TimeInterval
    
    init() {
        self.startDate = Date()
        self.endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        self.isActive = false
        self.duration = 7 * 24 * 60 * 60 // 7 days in seconds
        self.timeRemaining = self.duration
    }
}

enum AwardCategory: String, CaseIterable, Codable {
    case wrestler = "Wrestler of the Year"
    case match = "Match of the Year"
    case feud = "Feud of the Year"
    case moment = "Moment of the Year"
    case promo = "Promo of the Year"
    case show = "Show of the Year"
    case ppv = "PPV of the Year"
    case title = "Title of the Year"
    case entrance = "Entrance of the Year"
    case finisher = "Finisher of the Year"
    case tagTeam = "Tag Team of the Year"
    case faction = "Faction of the Year"
    case manager = "Manager of the Year"
    case commentator = "Commentator of the Year"
    case referee = "Referee of the Year"
    case backstage = "Backstage Moment of the Year"
    case return = "Return of the Year"
    case debut = "Debut of the Year"
    case release = "Release of the Year"
    case other = "Other"
}

enum AwardStatus: String, CaseIterable, Codable {
    case draft = "draft"
    case open = "open"
    case voting = "voting"
    case closed = "closed"
    case announced = "announced"
    case archived = "archived"
}

enum VotingType: String, CaseIterable, Codable {
    case single = "single"
    case multiple = "multiple"
    case ranked = "ranked"
    case approval = "approval"
}

enum TieBreaker: String, CaseIterable, Codable {
    case firstToReach = "first_to_reach"
    case mostVotes = "most_votes"
    case random = "random"
    case creatorDecides = "creator_decides"
}

// Vote model
struct Vote: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let awardId: String
    let nomineeId: String
    let voteType: VoteType
    let rank: Int? // For ranked voting
    let weight: Double // For weighted voting
    let timestamp: Date
    let ipAddress: String?
    let userAgent: String?
    
    init(userId: String, awardId: String, nomineeId: String, voteType: VoteType, rank: Int? = nil, weight: Double = 1.0) {
        self.userId = userId
        self.awardId = awardId
        self.nomineeId = nomineeId
        self.voteType = voteType
        self.rank = rank
        self.weight = weight
        self.timestamp = Date()
        self.ipAddress = nil
        self.userAgent = nil
    }
}

enum VoteType: String, CaseIterable, Codable {
    case approval = "approval"
    case ranked = "ranked"
    case weighted = "weighted"
    case single = "single"
}