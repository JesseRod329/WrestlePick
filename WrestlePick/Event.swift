import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let type: EventType
    let promotion: String
    let venue: Venue
    let date: Date
    let timezone: String
    let duration: TimeInterval? // in seconds
    let status: EventStatus
    let card: [Match]
    let predictions: [String] // Prediction IDs
    let engagement: EventEngagement
    let media: EventMedia
    let tags: [String]
    let isPPV: Bool
    let isLive: Bool
    let isSpoilerFree: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, description: String, type: EventType, promotion: String, venue: Venue, date: Date) {
        self.name = name
        self.description = description
        self.type = type
        self.promotion = promotion
        self.venue = venue
        self.date = date
        self.timezone = "UTC"
        self.duration = nil
        self.status = .scheduled
        self.card = []
        self.predictions = []
        self.engagement = EventEngagement()
        self.media = EventMedia()
        self.tags = []
        self.isPPV = false
        self.isLive = false
        self.isSpoilerFree = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct Venue: Codable {
    let name: String
    let city: String
    let state: String?
    let country: String
    let capacity: Int?
    let address: String?
    let coordinates: Coordinates?
    
    init(name: String, city: String, country: String) {
        self.name = name
        self.city = city
        self.state = nil
        self.country = country
        self.capacity = nil
        self.address = nil
        self.coordinates = nil
    }
}

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct Match: Identifiable, Codable {
    let id: String
    let type: MatchType
    let title: String
    let description: String?
    let wrestlers: [Wrestler]
    let stipulations: [Stipulation]
    let title: Title?
    let order: Int
    let duration: TimeInterval?
    let result: MatchResult?
    let rating: Double? // 0.0 to 5.0
    let isMainEvent: Bool
    let isPreShow: Bool
    let predictions: [String] // Prediction IDs
    let createdAt: Date
    let updatedAt: Date
    
    init(type: MatchType, title: String, wrestlers: [Wrestler], order: Int) {
        self.id = UUID().uuidString
        self.type = type
        self.title = title
        self.description = nil
        self.wrestlers = wrestlers
        self.stipulations = []
        self.title = nil
        self.order = order
        self.duration = nil
        self.result = nil
        self.rating = nil
        self.isMainEvent = false
        self.isPreShow = false
        self.predictions = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct Wrestler: Identifiable, Codable {
    let id: String
    let name: String
    let ringName: String?
    let realName: String?
    let imageURL: String?
    let promotion: String?
    let isChampion: Bool
    let titles: [Title]
    let stats: WrestlerStats
    
    init(name: String, ringName: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.ringName = ringName
        self.realName = nil
        self.imageURL = nil
        self.promotion = nil
        self.isChampion = false
        self.titles = []
        self.stats = WrestlerStats()
    }
}

struct Title: Identifiable, Codable {
    let id: String
    let name: String
    let promotion: String
    let imageURL: String?
    let isActive: Bool
    let currentChampion: String?
    let history: [TitleReign]
    
    init(name: String, promotion: String) {
        self.id = UUID().uuidString
        self.name = name
        self.promotion = promotion
        self.imageURL = nil
        self.isActive = true
        self.currentChampion = nil
        self.history = []
    }
}

struct TitleReign: Codable {
    let champion: String
    let startDate: Date
    let endDate: Date?
    let days: Int
    let isCurrent: Bool
    
    init(champion: String, startDate: Date) {
        self.champion = champion
        self.startDate = startDate
        self.endDate = nil
        self.days = 0
        self.isCurrent = true
    }
}

struct WrestlerStats: Codable {
    let wins: Int
    let losses: Int
    let draws: Int
    let winPercentage: Double
    let averageMatchRating: Double
    let totalMatches: Int
    let championships: Int
    let yearsActive: Int
    
    init() {
        self.wins = 0
        self.losses = 0
        self.draws = 0
        self.winPercentage = 0.0
        self.averageMatchRating = 0.0
        self.totalMatches = 0
        self.championships = 0
        self.yearsActive = 0
    }
}

struct Stipulation: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let type: StipulationType
    
    init(name: String, description: String, type: StipulationType) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.type = type
    }
}

struct MatchResult: Codable {
    let winner: String
    let method: String
    let time: TimeInterval
    let rating: Double?
    let notes: String?
    
    init(winner: String, method: String, time: TimeInterval) {
        self.winner = winner
        self.method = method
        self.time = time
        self.rating = nil
        self.notes = nil
    }
}

struct EventEngagement: Codable {
    let views: Int
    let likes: Int
    let shares: Int
    let comments: Int
    let predictions: Int
    let liveViewers: Int
    let replayViews: Int
    let socialMentions: Int
    
    init() {
        self.views = 0
        self.likes = 0
        self.shares = 0
        self.comments = 0
        self.predictions = 0
        self.liveViewers = 0
        self.replayViews = 0
        self.socialMentions = 0
    }
}

struct EventMedia: Codable {
    let posterURL: String?
    let thumbnailURL: String?
    let videoURL: String?
    let highlights: [String] // Video URLs
    let photos: [String] // Image URLs
    let audioURL: String?
    
    init() {
        self.posterURL = nil
        self.thumbnailURL = nil
        self.videoURL = nil
        self.highlights = []
        self.photos = []
        self.audioURL = nil
    }
}

enum EventType: String, CaseIterable, Codable {
    case ppv = "PPV"
    case weekly = "Weekly Show"
    case special = "Special Event"
    case houseShow = "House Show"
    case tournament = "Tournament"
    case battleRoyal = "Battle Royal"
    case royalRumble = "Royal Rumble"
    case moneyInTheBank = "Money in the Bank"
    case eliminationChamber = "Elimination Chamber"
    case hellInACell = "Hell in a Cell"
    case other = "Other"
}

enum EventStatus: String, CaseIterable, Codable {
    case scheduled = "scheduled"
    case live = "live"
    case completed = "completed"
    case cancelled = "cancelled"
    case postponed = "postponed"
    case rescheduled = "rescheduled"
}

enum MatchType: String, CaseIterable, Codable {
    case singles = "Singles"
    case tagTeam = "Tag Team"
    case tripleThreat = "Triple Threat"
    case fatalFourWay = "Fatal Four Way"
    case battleRoyal = "Battle Royal"
    case royalRumble = "Royal Rumble"
    case ladder = "Ladder Match"
    case tables = "Tables Match"
    case chairs = "Chairs Match"
    case hardcore = "Hardcore Match"
    case noHoldsBarred = "No Holds Barred"
    case streetFight = "Street Fight"
    case cage = "Cage Match"
    case hellInACell = "Hell in a Cell"
    case eliminationChamber = "Elimination Chamber"
    case moneyInTheBank = "Money in the Bank"
    case ironMan = "Iron Man Match"
    case other = "Other"
}

enum StipulationType: String, CaseIterable, Codable {
    case title = "Title"
    case career = "Career"
    case hair = "Hair"
    case mask = "Mask"
    case retirement = "Retirement"
    case contract = "Contract"
    case other = "Other"
}
