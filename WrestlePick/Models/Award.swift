import Foundation

struct Award: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: AwardCategory
    let year: Int
    let winner: String?
    let nominees: [String]
    let createdBy: String
    let createdDate: Date
    let isPublic: Bool
    let votes: [Vote]
    
    enum AwardCategory: String, CaseIterable, Codable {
        case wrestler = "Wrestler of the Year"
        case match = "Match of the Year"
        case feud = "Feud of the Year"
        case moment = "Moment of the Year"
        case promo = "Promo of the Year"
        case show = "Show of the Year"
        case other = "Other"
    }
}

struct Vote: Identifiable, Codable {
    let id: String
    let userId: String
    let awardId: String
    let nominee: String
    let voteDate: Date
}
