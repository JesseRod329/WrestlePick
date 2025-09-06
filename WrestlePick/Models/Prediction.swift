import Foundation

struct Prediction: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let description: String
    let category: PredictionCategory
    let eventDate: Date
    let createdDate: Date
    let status: PredictionStatus
    let confidence: Int // 1-10 scale
    let tags: [String]
    let isPublic: Bool
    
    enum PredictionCategory: String, CaseIterable, Codable {
        case match = "Match"
        case storyline = "Storyline"
        case title = "Title Change"
        case debut = "Debut"
        case return = "Return"
        case release = "Release"
        case other = "Other"
    }
    
    enum PredictionStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case correct = "Correct"
        case incorrect = "Incorrect"
        case cancelled = "Cancelled"
    }
}
