import Foundation
import FirebaseFirestore

// MARK: - Fantasy Booking Models
struct FantasyBooking: Codable, Identifiable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let createdByUserId: String
    let createdByUsername: String
    let promotion: String
    let showType: ShowType
    let venue: Venue?
    let date: Date
    let matchCards: [MatchCard]
    let storylineArcs: [StorylineArc]
    let budget: Budget?
    let constraints: BookingConstraints
    let isPublic: Bool
    let isTemplate: Bool
    let tags: [String]
    let engagement: BookingEngagement
    let createdAt: Date
    let updatedAt: Date
    
    init(title: String, description: String, createdByUserId: String, createdByUsername: String, promotion: String, showType: ShowType, venue: Venue? = nil, date: Date, matchCards: [MatchCard] = [], storylineArcs: [StorylineArc] = [], budget: Budget? = nil, constraints: BookingConstraints = BookingConstraints(), isPublic: Bool = true, isTemplate: Bool = false, tags: [String] = []) {
        self.title = title
        self.description = description
        self.createdByUserId = createdByUserId
        self.createdByUsername = createdByUsername
        self.promotion = promotion
        self.showType = showType
        self.venue = venue
        self.date = date
        self.matchCards = matchCards
        self.storylineArcs = storylineArcs
        self.budget = budget
        self.constraints = constraints
        self.isPublic = isPublic
        self.isTemplate = isTemplate
        self.tags = tags
        self.engagement = BookingEngagement()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Show Types
enum ShowType: String, CaseIterable, Codable {
    case raw = "Raw"
    case smackdown = "SmackDown"
    case nxt = "NXT"
    case ppv = "Pay-Per-View"
    case special = "Special Event"
    case houseShow = "House Show"
    case aewDynamite = "AEW Dynamite"
    case aewRampage = "AEW Rampage"
    case njpw = "NJPW"
    case impact = "Impact Wrestling"
    case custom = "Custom"
    
    var iconName: String {
        switch self {
        case .raw: return "tv"
        case .smackdown: return "tv"
        case .nxt: return "star"
        case .ppv: return "crown"
        case .special: return "sparkles"
        case .houseShow: return "house"
        case .aewDynamite: return "flame"
        case .aewRampage: return "bolt"
        case .njpw: return "globe"
        case .impact: return "target"
        case .custom: return "wrench"
        }
    }
    
    var color: String {
        switch self {
        case .raw: return "red"
        case .smackdown: return "blue"
        case .nxt: return "gold"
        case .ppv: return "purple"
        case .special: return "pink"
        case .houseShow: return "gray"
        case .aewDynamite: return "orange"
        case .aewRampage: return "yellow"
        case .njpw: return "red"
        case .impact: return "blue"
        case .custom: return "green"
        }
    }
    
    var maxMatches: Int {
        switch self {
        case .raw, .smackdown: return 8
        case .nxt: return 6
        case .ppv: return 12
        case .special: return 10
        case .houseShow: return 6
        case .aewDynamite: return 7
        case .aewRampage: return 5
        case .njpw: return 8
        case .impact: return 6
        case .custom: return 15
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .raw, .smackdown: return 10800 // 3 hours
        case .nxt: return 7200 // 2 hours
        case .ppv: return 14400 // 4 hours
        case .special: return 10800 // 3 hours
        case .houseShow: return 9000 // 2.5 hours
        case .aewDynamite: return 7200 // 2 hours
        case .aewRampage: return 3600 // 1 hour
        case .njpw: return 10800 // 3 hours
        case .impact: return 7200 // 2 hours
        case .custom: return 18000 // 5 hours
        }
    }
}

// MARK: - Match Card
struct MatchCard: Codable, Identifiable {
    let id: String
    let matchType: MatchType
    let participants: [Wrestler]
    let title: Championship?
    let stipulation: Stipulation?
    let storyline: String?
    let estimatedDuration: TimeInterval
    let position: Int
    let isMainEvent: Bool
    let isOpener: Bool
    let notes: String?
    
    init(matchType: MatchType, participants: [Wrestler], title: Championship? = nil, stipulation: Stipulation? = nil, storyline: String? = nil, estimatedDuration: TimeInterval = 600, position: Int = 0, isMainEvent: Bool = false, isOpener: Bool = false, notes: String? = nil) {
        self.id = UUID().uuidString
        self.matchType = matchType
        self.participants = participants
        self.title = title
        self.stipulation = stipulation
        self.storyline = storyline
        self.estimatedDuration = estimatedDuration
        self.position = position
        self.isMainEvent = isMainEvent
        self.isOpener = isOpener
        self.notes = notes
    }
}

// MARK: - Match Types
enum MatchType: String, CaseIterable, Codable {
    case singles = "Singles"
    case tagTeam = "Tag Team"
    case tripleThreat = "Triple Threat"
    case fatalFourWay = "Fatal 4-Way"
    case ladder = "Ladder Match"
    case tables = "Tables Match"
    case chairs = "Chairs Match"
    case tlc = "TLC Match"
    case hellInACell = "Hell in a Cell"
    case eliminationChamber = "Elimination Chamber"
    case royalRumble = "Royal Rumble"
    case battleRoyal = "Battle Royal"
    case steelCage = "Steel Cage"
    case lastManStanding = "Last Man Standing"
    case noHoldsBarred = "No Holds Barred"
    case extremeRules = "Extreme Rules"
    case ironMan = "Iron Man Match"
    case submission = "Submission Match"
    case fallsCountAnywhere = "Falls Count Anywhere"
    case custom = "Custom"
    
    var iconName: String {
        switch self {
        case .singles: return "person.2"
        case .tagTeam: return "person.3"
        case .tripleThreat: return "person.3.fill"
        case .fatalFourWay: return "person.4"
        case .ladder: return "ladder"
        case .tables: return "table"
        case .chairs: return "chair"
        case .tlc: return "hammer"
        case .hellInACell: return "house"
        case .eliminationChamber: return "hexagon"
        case .royalRumble: return "crown"
        case .battleRoyal: return "person.2.circle"
        case .steelCage: return "square"
        case .lastManStanding: return "figure.stand"
        case .noHoldsBarred: return "exclamationmark.triangle"
        case .extremeRules: return "flame"
        case .ironMan: return "clock"
        case .submission: return "hand.raised"
        case .fallsCountAnywhere: return "globe"
        case .custom: return "wrench"
        }
    }
    
    var minParticipants: Int {
        switch self {
        case .singles: return 2
        case .tagTeam: return 4
        case .tripleThreat: return 3
        case .fatalFourWay: return 4
        case .ladder, .tables, .chairs, .tlc: return 2
        case .hellInACell: return 2
        case .eliminationChamber: return 6
        case .royalRumble: return 30
        case .battleRoyal: return 20
        case .steelCage, .lastManStanding, .noHoldsBarred, .extremeRules: return 2
        case .ironMan: return 2
        case .submission: return 2
        case .fallsCountAnywhere: return 2
        case .custom: return 1
        }
    }
    
    var maxParticipants: Int {
        switch self {
        case .singles: return 2
        case .tagTeam: return 4
        case .tripleThreat: return 3
        case .fatalFourWay: return 4
        case .ladder, .tables, .chairs, .tlc: return 2
        case .hellInACell: return 2
        case .eliminationChamber: return 6
        case .royalRumble: return 30
        case .battleRoyal: return 20
        case .steelCage, .lastManStanding, .noHoldsBarred, .extremeRules: return 2
        case .ironMan: return 2
        case .submission: return 2
        case .fallsCountAnywhere: return 2
        case .custom: return 10
        }
    }
}

// MARK: - Championship
struct Championship: Codable, Identifiable {
    let id: String
    let name: String
    let promotion: String
    let type: ChampionshipType
    let currentHolder: String?
    let lineage: [ChampionshipReign]
    let isActive: Bool
    let imageURL: String?
    
    init(name: String, promotion: String, type: ChampionshipType, currentHolder: String? = nil, lineage: [ChampionshipReign] = [], isActive: Bool = true, imageURL: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.promotion = promotion
        self.type = type
        self.currentHolder = currentHolder
        self.lineage = lineage
        self.isActive = isActive
        self.imageURL = imageURL
    }
}

// MARK: - Championship Types
enum ChampionshipType: String, CaseIterable, Codable {
    case world = "World"
    case secondary = "Secondary"
    case tagTeam = "Tag Team"
    case women = "Women's"
    case midcard = "Midcard"
    case cruiserweight = "Cruiserweight"
    case hardcore = "Hardcore"
    case custom = "Custom"
    
    var iconName: String {
        switch self {
        case .world: return "crown.fill"
        case .secondary: return "star.fill"
        case .tagTeam: return "person.2.fill"
        case .women: return "person.fill"
        case .midcard: return "medal.fill"
        case .cruiserweight: return "bolt.fill"
        case .hardcore: return "flame.fill"
        case .custom: return "wrench.fill"
        }
    }
}

// MARK: - Championship Reign
struct ChampionshipReign: Codable {
    let wrestler: String
    let startDate: Date
    let endDate: Date?
    let daysHeld: Int
    let isCurrent: Bool
    let notes: String?
    
    init(wrestler: String, startDate: Date, endDate: Date? = nil, daysHeld: Int = 0, isCurrent: Bool = false, notes: String? = nil) {
        self.wrestler = wrestler
        self.startDate = startDate
        self.endDate = endDate
        self.daysHeld = daysHeld
        self.isCurrent = isCurrent
        self.notes = notes
    }
}

// MARK: - Stipulation
struct Stipulation: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let type: StipulationType
    let isDangerous: Bool
    let requiresSpecialSetup: Bool
    
    init(name: String, description: String, type: StipulationType, isDangerous: Bool = false, requiresSpecialSetup: Bool = false) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.type = type
        self.isDangerous = isDangerous
        self.requiresSpecialSetup = requiresSpecialSetup
    }
}

// MARK: - Stipulation Types
enum StipulationType: String, CaseIterable, Codable {
    case title = "Title"
    case career = "Career"
    case retirement = "Retirement"
    case hair = "Hair"
    case mask = "Mask"
    case manager = "Manager"
    case contract = "Contract"
    case stipulation = "Stipulation"
    case custom = "Custom"
    
    var iconName: String {
        switch self {
        case .title: return "crown"
        case .career: return "briefcase"
        case .retirement: return "person.crop.circle.badge.xmark"
        case .hair: return "scissors"
        case .mask: return "theatermasks"
        case .manager: return "person.badge.plus"
        case .contract: return "doc.text"
        case .stipulation: return "list.bullet"
        case .custom: return "wrench"
        }
    }
}

// MARK: - Storyline Arc
struct StorylineArc: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let participants: [String] // Wrestler names
    let startDate: Date
    let endDate: Date?
    let shows: [String] // Show IDs
    let matches: [String] // Match IDs
    let status: StorylineStatus
    let intensity: StorylineIntensity
    let notes: String?
    
    init(title: String, description: String, participants: [String], startDate: Date, endDate: Date? = nil, shows: [String] = [], matches: [String] = [], status: StorylineStatus = .active, intensity: StorylineIntensity = .medium, notes: String? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.participants = participants
        self.startDate = startDate
        self.endDate = endDate
        self.shows = shows
        self.matches = matches
        self.status = status
        self.intensity = intensity
        self.notes = notes
    }
}

// MARK: - Storyline Status
enum StorylineStatus: String, CaseIterable, Codable {
    case active = "Active"
    case paused = "Paused"
    case concluded = "Concluded"
    case cancelled = "Cancelled"
    
    var color: String {
        switch self {
        case .active: return "green"
        case .paused: return "yellow"
        case .concluded: return "blue"
        case .cancelled: return "red"
        }
    }
}

// MARK: - Storyline Intensity
enum StorylineIntensity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case extreme = "Extreme"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .extreme: return "red"
        }
    }
}

// MARK: - Budget
struct Budget: Codable {
    let totalBudget: Double
    let usedBudget: Double
    let currency: String
    let categories: [BudgetCategory]
    
    var remainingBudget: Double {
        return totalBudget - usedBudget
    }
    
    var percentageUsed: Double {
        return totalBudget > 0 ? (usedBudget / totalBudget) * 100 : 0
    }
}

// MARK: - Budget Category
struct BudgetCategory: Codable, Identifiable {
    let id: String
    let name: String
    let allocatedAmount: Double
    let usedAmount: Double
    let description: String?
    
    var remainingAmount: Double {
        return allocatedAmount - usedAmount
    }
    
    init(name: String, allocatedAmount: Double, usedAmount: Double = 0, description: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.allocatedAmount = allocatedAmount
        self.usedAmount = usedAmount
        self.description = description
    }
}

// MARK: - Booking Constraints
struct BookingConstraints: Codable {
    let maxMatches: Int
    let maxDuration: TimeInterval
    let minDuration: TimeInterval
    let requireMainEvent: Bool
    let requireOpener: Bool
    let allowRepeatMatches: Bool
    let maxWrestlerAppearances: Int
    let requireStorylineConnection: Bool
    let budgetLimit: Double?
    let venueCapacity: Int?
    
    init(maxMatches: Int = 10, maxDuration: TimeInterval = 14400, minDuration: TimeInterval = 3600, requireMainEvent: Bool = true, requireOpener: Bool = true, allowRepeatMatches: Bool = false, maxWrestlerAppearances: Int = 2, requireStorylineConnection: Bool = false, budgetLimit: Double? = nil, venueCapacity: Int? = nil) {
        self.maxMatches = maxMatches
        self.maxDuration = maxDuration
        self.minDuration = minDuration
        self.requireMainEvent = requireMainEvent
        self.requireOpener = requireOpener
        self.allowRepeatMatches = allowRepeatMatches
        self.maxWrestlerAppearances = maxWrestlerAppearances
        self.requireStorylineConnection = requireStorylineConnection
        self.budgetLimit = budgetLimit
        self.venueCapacity = venueCapacity
    }
}

// MARK: - Booking Engagement
struct BookingEngagement: Codable {
    let views: Int
    let likes: Int
    let shares: Int
    let comments: Int
    let bookmarks: Int
    let votes: Int
    let averageRating: Double
    
    init(views: Int = 0, likes: Int = 0, shares: Int = 0, comments: Int = 0, bookmarks: Int = 0, votes: Int = 0, averageRating: Double = 0.0) {
        self.views = views
        self.likes = likes
        self.shares = shares
        self.comments = comments
        self.bookmarks = bookmarks
        self.votes = votes
        self.averageRating = averageRating
    }
}

// MARK: - Wrestler Availability
struct WrestlerAvailability: Codable {
    let wrestlerId: String
    let isAvailable: Bool
    let reason: AvailabilityReason?
    let startDate: Date?
    let endDate: Date?
    let notes: String?
    
    init(wrestlerId: String, isAvailable: Bool, reason: AvailabilityReason? = nil, startDate: Date? = nil, endDate: Date? = nil, notes: String? = nil) {
        self.wrestlerId = wrestlerId
        self.isAvailable = isAvailable
        self.reason = reason
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
    }
}

// MARK: - Availability Reasons
enum AvailabilityReason: String, CaseIterable, Codable {
    case injury = "Injury"
    case suspension = "Suspension"
    case wellness = "Wellness Policy"
    case contract = "Contract Issues"
    case personal = "Personal"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .injury: return "cross.case"
        case .suspension: return "exclamationmark.triangle"
        case .wellness: return "heart"
        case .contract: return "doc.text"
        case .personal: return "person"
        case .other: return "questionmark"
        }
    }
    
    var color: String {
        switch self {
        case .injury: return "red"
        case .suspension: return "orange"
        case .wellness: return "yellow"
        case .contract: return "blue"
        case .personal: return "purple"
        case .other: return "gray"
        }
    }
}

// MARK: - Community Vote
struct CommunityVote: Codable, Identifiable {
    @DocumentID var id: String?
    let bookingId: String
    let userId: String
    let rating: Int // 1-5 stars
    let comment: String?
    let createdAt: Date
    
    init(bookingId: String, userId: String, rating: Int, comment: String? = nil) {
        self.bookingId = bookingId
        self.userId = userId
        self.rating = rating
        self.comment = comment
        self.createdAt = Date()
    }
}

// MARK: - AI Booking Suggestion
struct AIBookingSuggestion: Codable, Identifiable {
    let id: String
    let type: SuggestionType
    let title: String
    let description: String
    let confidence: Double
    let reasoning: String
    let suggestedMatches: [MatchCard]
    let suggestedStorylines: [StorylineArc]
    let estimatedEngagement: Double
    
    init(type: SuggestionType, title: String, description: String, confidence: Double, reasoning: String, suggestedMatches: [MatchCard] = [], suggestedStorylines: [StorylineArc] = [], estimatedEngagement: Double = 0.0) {
        self.id = UUID().uuidString
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.reasoning = reasoning
        self.suggestedMatches = suggestedMatches
        self.suggestedStorylines = suggestedStorylines
        self.estimatedEngagement = estimatedEngagement
    }
}

// MARK: - Suggestion Types
enum SuggestionType: String, CaseIterable, Codable {
    case match = "Match"
    case storyline = "Storyline"
    case card = "Card"
    case booking = "Booking"
    case optimization = "Optimization"
    
    var iconName: String {
        switch self {
        case .match: return "person.2"
        case .storyline: return "book"
        case .card: return "rectangle.stack"
        case .booking: return "calendar"
        case .optimization: return "gear"
        }
    }
}
