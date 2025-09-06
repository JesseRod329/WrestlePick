import Foundation
import Combine
import FirebaseFirestore

class PredictionService: ObservableObject {
    @Published var predictions: [Prediction] = []
    @Published var userPredictions: [Prediction] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    init() {
        // Initialize with empty data
    }
    
    func fetchPredictions(limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.predictions)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.predictions = snapshot?.documents.compactMap { document in
                            try? document.data(as: Prediction.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchUserPredictions(userId: String, limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.predictions)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.userPredictions = snapshot?.documents.compactMap { document in
                            try? document.data(as: Prediction.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchPredictionsByEvent(eventId: String, limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.predictions)
            .whereField("eventId", isEqualTo: eventId)
            .order(by: "createdDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.predictions = snapshot?.documents.compactMap { document in
                            try? document.data(as: Prediction.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchPredictionsByCategory(_ category: PredictionCategory, limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.predictions)
            .whereField("category", isEqualTo: category.rawValue)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.predictions = snapshot?.documents.compactMap { document in
                            try? document.data(as: Prediction.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func createPrediction(_ prediction: Prediction) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.predictions)
            .addDocument(data: prediction.dictionary) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.userPredictions.insert(prediction, at: 0)
                    }
                }
            }
    }
    
    func updatePrediction(_ prediction: Prediction) {
        guard let predictionId = prediction.id else { return }
        
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.predictions)
            .document(predictionId)
            .setData(prediction.dictionary, merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.error = error
                    } else {
                        // Update local array
                        if let index = self?.userPredictions.firstIndex(where: { $0.id == predictionId }) {
                            self?.userPredictions[index] = prediction
                        }
                    }
                }
            }
    }
    
    func updatePredictionStatus(_ predictionId: String, status: PredictionStatus) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.predictions)
            .document(predictionId)
            .updateData([
                "status": status.rawValue,
                "updatedAt": Date()
            ]) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.error = error
                    } else {
                        // Update local array
                        if let index = self?.userPredictions.firstIndex(where: { $0.id == predictionId }) {
                            self?.userPredictions[index].status = status
                        }
                    }
                }
            }
    }
    
    func deletePrediction(_ predictionId: String) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.predictions)
            .document(predictionId)
            .delete { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.userPredictions.removeAll { $0.id == predictionId }
                    }
                }
            }
    }
    
    func likePrediction(_ predictionId: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let likeData = [
            "userId": currentUser.id ?? "",
            "predictionId": predictionId,
            "timestamp": Date()
        ] as [String : Any]
        
        db.collection("likes")
            .addDocument(data: likeData) { error in
                if let error = error {
                    print("Error liking prediction: \(error)")
                }
            }
    }
    
    func sharePrediction(_ predictionId: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let shareData = [
            "userId": currentUser.id ?? "",
            "predictionId": predictionId,
            "timestamp": Date()
        ] as [String : Any]
        
        db.collection("shares")
            .addDocument(data: shareData) { error in
                if let error = error {
                    print("Error sharing prediction: \(error)")
                }
            }
    }
    
    func calculatePredictionAccuracy(_ prediction: Prediction) -> PredictionAccuracy? {
        guard !prediction.picks.isEmpty else { return nil }
        
        let correctPicks = prediction.picks.filter { $0.isCorrect == true }.count
        let totalPicks = prediction.picks.count
        let pointsEarned = prediction.picks.compactMap { $0.isCorrect == true ? $0.points : 0 }.reduce(0, +)
        
        return PredictionAccuracy(
            correctPicks: correctPicks,
            totalPicks: totalPicks,
            pointsEarned: pointsEarned
        )
    }
    
    func fetchLeaderboard(limit: Int = 100) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.leaderboards)
            .document("predictions")
            .collection("users")
            .order(by: "totalPoints", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        // Handle leaderboard data
                        self?.isLoading = false
                    }
                }
            }
    }
}

// MARK: - Extensions
extension Prediction {
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "username": username,
            "title": title,
            "description": description,
            "category": category.rawValue,
            "subcategory": subcategory as Any,
            "eventId": eventId as Any,
            "eventName": eventName as Any,
            "eventDate": eventDate,
            "createdDate": createdDate,
            "status": status.rawValue,
            "confidence": confidence,
            "tags": tags,
            "isPublic": isPublic,
            "picks": picks.map { $0.dictionary },
            "accuracy": accuracy?.dictionary as Any,
            "engagement": engagement.dictionary,
            "visibility": visibility.rawValue,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

extension PredictionPick {
    var dictionary: [String: Any] {
        return [
            "id": id,
            "type": type.rawValue,
            "title": title,
            "description": description,
            "options": options.map { $0.dictionary },
            "selectedOption": selectedOption as Any,
            "isCorrect": isCorrect as Any,
            "points": points,
            "weight": weight
        ]
    }
}

extension PickOption {
    var dictionary: [String: Any] {
        return [
            "id": id,
            "text": text,
            "description": description as Any,
            "isCorrect": isCorrect as Any,
            "odds": odds as Any,
            "probability": probability as Any
        ]
    }
}

extension PredictionAccuracy {
    var dictionary: [String: Any] {
        return [
            "overallScore": overallScore,
            "correctPicks": correctPicks,
            "totalPicks": totalPicks,
            "accuracyPercentage": accuracyPercentage,
            "pointsEarned": pointsEarned,
            "bonusPoints": bonusPoints,
            "streakBonus": streakBonus,
            "difficultyMultiplier": difficultyMultiplier,
            "calculatedAt": calculatedAt
        ]
    }
}

extension PredictionEngagement {
    var dictionary: [String: Any] {
        return [
            "views": views,
            "likes": likes,
            "dislikes": dislikes,
            "comments": comments,
            "shares": shares,
            "bookmarks": bookmarks,
            "reactions": reactions.mapValues { $0 }
        ]
    }
}
