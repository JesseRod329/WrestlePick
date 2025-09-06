import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isGuest = false
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    self?.isAuthenticated = true
                    self?.isGuest = false
                    self?.fetchUserData(uid: firebaseUser.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                    self?.isGuest = false
                }
            }
        }
    }
    
    // MARK: - Email/Password Authentication
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                    completion(.failure(error))
                } else if result != nil {
                    completion(.success(()))
                }
            }
        }
    }
    
    func signUp(email: String, password: String, username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                    completion(.failure(error))
                } else if let result = result {
                    self?.createUserProfile(uid: result.user.uid, email: email, username: username) { profileResult in
                        completion(profileResult)
                    }
                }
            }
        }
    }
    
    // MARK: - Social Authentication
    func signInWithCredential(_ credential: AuthCredential, username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                    completion(.failure(error))
                } else if let result = result {
                    // Check if user profile exists
                    self?.checkUserProfileExists(uid: result.user.uid) { exists in
                        if exists {
                            completion(.success(()))
                        } else {
                            // Create profile for new social user
                            self?.createUserProfile(uid: result.user.uid, email: result.user.email ?? "", username: username) { profileResult in
                                completion(profileResult)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Guest Mode
    func signInAsGuest(completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        // Create anonymous user
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                    completion(.failure(error))
                } else if let result = result {
                    self?.isGuest = true
                    self?.createGuestProfile(uid: result.user.uid) { profileResult in
                        completion(profileResult)
                    }
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
            isGuest = false
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Password Reset
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Profile Management
    func updateProfile(displayName: String?, bio: String?, profileImageURL: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(AuthError.noCurrentUser))
            return
        }
        
        isLoading = true
        error = nil
        
        let updateData: [String: Any] = [
            "displayName": displayName ?? currentUser.displayName,
            "bio": bio ?? currentUser.bio,
            "profileImageURL": profileImageURL ?? currentUser.profileImageURL as Any,
            "updatedAt": Date()
        ]
        
        db.collection(FirestoreCollections.users)
            .document(currentUser.id ?? "")
            .updateData(updateData) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.error = error
                        completion(.failure(error))
                    } else {
                        self?.fetchUserData(uid: currentUser.id ?? "")
                        completion(.success(()))
                    }
                }
            }
    }
    
    func updateNotificationPreferences(_ preferences: NotificationSettings, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(AuthError.noCurrentUser))
            return
        }
        
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.users)
            .document(currentUser.id ?? "")
            .updateData([
                "preferences.notificationSettings": preferences.dictionary,
                "updatedAt": Date()
            ]) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.error = error
                        completion(.failure(error))
                    } else {
                        self?.fetchUserData(uid: currentUser.id ?? "")
                        completion(.success(()))
                    }
                }
            }
    }
    
    func updatePrivacySettings(_ settings: PrivacySettings, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(AuthError.noCurrentUser))
            return
        }
        
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.users)
            .document(currentUser.id ?? "")
            .updateData([
                "preferences.privacySettings": settings.dictionary,
                "updatedAt": Date()
            ]) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.error = error
                        completion(.failure(error))
                    } else {
                        self?.fetchUserData(uid: currentUser.id ?? "")
                        completion(.success(()))
                    }
                }
            }
    }
    
    // MARK: - Data Export
    func exportUserData(completion: @escaping (Result<Data, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(AuthError.noCurrentUser))
            return
        }
        
        isLoading = true
        error = nil
        
        // Fetch all user data
        let group = DispatchGroup()
        var userData: [String: Any] = [:]
        var predictions: [Prediction] = []
        var awards: [Award] = []
        
        // Fetch user profile
        group.enter()
        db.collection(FirestoreCollections.users)
            .document(currentUser.id ?? "")
            .getDocument { document, error in
                if let document = document, document.exists {
                    userData = document.data() ?? [:]
                }
                group.leave()
            }
        
        // Fetch predictions
        group.enter()
        db.collection(FirestoreCollections.predictions)
            .whereField("userId", isEqualTo: currentUser.id ?? "")
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    predictions = documents.compactMap { try? $0.data(as: Prediction.self) }
                }
                group.leave()
            }
        
        // Fetch awards
        group.enter()
        db.collection(FirestoreCollections.awards)
            .whereField("createdByUserId", isEqualTo: currentUser.id ?? "")
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    awards = documents.compactMap { try? $0.data(as: Award.self) }
                }
                group.leave()
            }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            
            let exportData = [
                "user": userData,
                "predictions": predictions.map { $0.dictionary },
                "awards": awards.map { $0.dictionary },
                "exportDate": Date(),
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                completion(.success(jsonData))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    private func checkUserProfileExists(uid: String, completion: @escaping (Bool) -> Void) {
        db.collection(FirestoreCollections.users)
            .document(uid)
            .getDocument { document, error in
                completion(document?.exists ?? false)
            }
    }
    
    private func createUserProfile(uid: String, email: String, username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let user = User(
            username: username,
            email: email,
            displayName: username,
            bio: "",
            profileImageURL: nil,
            joinDate: Date(),
            lastActiveDate: Date(),
            preferences: UserPreferences(),
            predictionStats: PredictionStats(),
            socialStats: SocialStats(),
            isVerified: false,
            isPremium: false,
            subscriptionTier: .free
        )
        
        db.collection(FirestoreCollections.users)
            .document(uid)
            .setData(user.dictionary) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                        completion(.failure(error))
                    } else {
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        completion(.success(()))
                    }
                }
            }
    }
    
    private func createGuestProfile(uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let guestUser = User(
            username: "Guest_\(uid.prefix(8))",
            email: "",
            displayName: "Guest User",
            bio: "Guest user with limited features",
            profileImageURL: nil,
            joinDate: Date(),
            lastActiveDate: Date(),
            preferences: UserPreferences(),
            predictionStats: PredictionStats(),
            socialStats: SocialStats(),
            isVerified: false,
            isPremium: false,
            subscriptionTier: .free
        )
        
        db.collection(FirestoreCollections.users)
            .document(uid)
            .setData(guestUser.dictionary) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                        completion(.failure(error))
                    } else {
                        self?.currentUser = guestUser
                        self?.isAuthenticated = true
                        self?.isGuest = true
                        completion(.success(()))
                    }
                }
            }
    }
    
    private func fetchUserData(uid: String) {
        db.collection(FirestoreCollections.users)
            .document(uid)
            .getDocument { [weak self] document, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else if let document = document, document.exists {
                        do {
                            let user = try document.data(as: User.self)
                            self?.currentUser = user
                        } catch {
                            self?.error = error
                        }
                    }
                }
            }
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case noCurrentUser
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No current user found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyInUse:
            return "Email is already in use"
        case .weakPassword:
            return "Password is too weak"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - Extensions
extension User {
    var dictionary: [String: Any] {
        return [
            "username": username,
            "email": email,
            "displayName": displayName,
            "bio": bio,
            "profileImageURL": profileImageURL as Any,
            "joinDate": joinDate,
            "lastActiveDate": lastActiveDate,
            "preferences": preferences.dictionary,
            "predictionStats": predictionStats.dictionary,
            "socialStats": socialStats.dictionary,
            "isVerified": isVerified,
            "isPremium": isPremium,
            "subscriptionTier": subscriptionTier.rawValue,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

extension UserPreferences {
    var dictionary: [String: Any] {
        return [
            "favoritePromotions": favoritePromotions,
            "favoriteWrestlers": favoriteWrestlers,
            "favoriteCategories": favoriteCategories.map { $0.rawValue },
            "notificationSettings": notificationSettings.dictionary,
            "privacySettings": privacySettings.dictionary,
            "displaySettings": displaySettings.dictionary
        ]
    }
}

extension PredictionStats {
    var dictionary: [String: Any] {
        return [
            "totalPredictions": totalPredictions,
            "correctPredictions": correctPredictions,
            "accuracy": accuracy,
            "currentStreak": currentStreak,
            "longestStreak": longestStreak,
            "rank": rank,
            "points": points,
            "badges": badges.map { $0.dictionary }
        ]
    }
}

extension SocialStats {
    var dictionary: [String: Any] {
        return [
            "followers": followers,
            "following": following,
            "posts": posts,
            "likes": likes,
            "comments": comments,
            "reputation": reputation
        ]
    }
}

extension Badge {
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "description": description,
            "iconName": iconName,
            "earnedDate": earnedDate,
            "rarity": rarity.rawValue
        ]
    }
}

extension NotificationSettings {
    var dictionary: [String: Any] {
        return [
            "pushNotifications": pushNotifications,
            "emailNotifications": emailNotifications,
            "predictionReminders": predictionReminders,
            "newsAlerts": newsAlerts,
            "socialUpdates": socialUpdates,
            "weeklyDigest": weeklyDigest
        ]
    }
}

extension PrivacySettings {
    var dictionary: [String: Any] {
        return [
            "isPublic": isPublic,
            "showPredictions": showPredictions,
            "showStats": showStats,
            "showActivity": showActivity,
            "allowMessages": allowMessages,
            "dataSharing": dataSharing
        ]
    }
}