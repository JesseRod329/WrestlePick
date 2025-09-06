import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    self?.isAuthenticated = true
                    self?.fetchUserData(uid: firebaseUser.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        error = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                } else if let result = result {
                    self?.isAuthenticated = true
                    self?.fetchUserData(uid: result.user.uid)
                }
            }
        }
    }
    
    func signUp(email: String, password: String, username: String, displayName: String) {
        isLoading = true
        error = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                } else if let result = result {
                    self?.createUserProfile(uid: result.user.uid, email: email, username: username, displayName: displayName)
                }
            }
        }
    }
    
    func signInWithGoogle() {
        // TODO: Implement Google Sign-In
        // This would require GoogleSignIn SDK integration
    }
    
    func signInWithApple() {
        // TODO: Implement Apple Sign-In
        // This would require Sign in with Apple integration
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            self.error = error
        }
    }
    
    func resetPassword(email: String) {
        isLoading = true
        error = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                }
            }
        }
    }
    
    func updateProfile(displayName: String?, profileImageURL: String?) {
        guard let currentUser = currentUser else { return }
        
        isLoading = true
        error = nil
        
        let updateData: [String: Any] = [
            "displayName": displayName ?? currentUser.displayName,
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
                    } else {
                        self?.fetchUserData(uid: currentUser.id ?? "")
                    }
                }
            }
    }
    
    func updateNotificationPreferences(_ preferences: NotificationSettings) {
        guard let currentUser = currentUser else { return }
        
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
                    } else {
                        self?.fetchUserData(uid: currentUser.id ?? "")
                    }
                }
            }
    }
    
    private func createUserProfile(uid: String, email: String, username: String, displayName: String) {
        let user = User(username: username, email: email, displayName: displayName)
        
        db.collection(FirestoreCollections.users)
            .document(uid)
            .setData(user.dictionary) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.currentUser = user
                        self?.isAuthenticated = true
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

// MARK: - Extensions
extension User {
    var dictionary: [String: Any] {
        return [
            "username": username,
            "email": email,
            "displayName": displayName,
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
