import Foundation

struct User: Identifiable, Codable {
    let id: String
    let username: String
    let email: String
    let joinDate: Date
    let predictionAccuracy: Double
    let totalPredictions: Int
    let correctPredictions: Int
    let awards: [Award]
    
    init(id: String, username: String, email: String) {
        self.id = id
        self.username = username
        self.email = email
        self.joinDate = Date()
        self.predictionAccuracy = 0.0
        self.totalPredictions = 0
        self.correctPredictions = 0
        self.awards = []
    }
}
