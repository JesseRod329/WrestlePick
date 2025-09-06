import Foundation
import FirebaseFirestore
import Combine

class SocialService: ObservableObject {
    static let shared = SocialService()
    
    @Published var socialPosts: [SocialPost] = []
    @Published var comments: [Comment] = []
    @Published var leagues: [League] = []
    @Published var userAwards: [UserAward] = []
    @Published var polls: [Poll] = []
    @Published var moderationReports: [ModerationReport] = []
    @Published var followingUsers: [SocialUser] = []
    @Published var followers: [SocialUser] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSocialPosts()
        loadLeagues()
        loadUserAwards()
        loadPolls()
        loadModerationReports()
    }
    
    // MARK: - Social Posts
    func loadSocialPosts() {
        isLoading = true
        
        db.collection("social_posts")
            .order(by: "createdAt", descending: true)
            .limit(50)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.error = error
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    self.socialPosts = documents.compactMap { try? $0.data(as: SocialPost.self) }
                }
            }
    }
    
    func createPost(_ post: SocialPost, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("social_posts").addDocument(from: post) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    self.loadSocialPosts()
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func likePost(_ postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement like functionality
        completion(.success(()))
    }
    
    func sharePost(_ postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement share functionality
        completion(.success(()))
    }
    
    func bookmarkPost(_ postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement bookmark functionality
        completion(.success(()))
    }
    
    // MARK: - Comments
    func loadComments(for postId: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        db.collection("comments")
            .whereField("postId", isEqualTo: postId)
            .whereField("parentCommentId", isEqualTo: NSNull())
            .order(by: "createdAt", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let comments = documents.compactMap { try? $0.data(as: Comment.self) }
                completion(.success(comments))
            }
    }
    
    func createComment(_ comment: Comment, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("comments").addDocument(from: comment) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func likeComment(_ commentId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement comment like functionality
        completion(.success(()))
    }
    
    func replyToComment(_ commentId: String, reply: Comment, completion: @escaping (Result<Void, Error>) -> Void) {
        var replyWithParent = reply
        replyWithParent = Comment(
            postId: reply.postId,
            authorId: reply.authorId,
            authorUsername: reply.authorUsername,
            authorDisplayName: reply.authorDisplayName,
            authorAvatarURL: reply.authorAvatarURL,
            content: reply.content,
            parentCommentId: commentId,
            replies: [],
            engagement: reply.engagement,
            moderationStatus: reply.moderationStatus
        )
        
        createComment(replyWithParent, completion: completion)
    }
    
    // MARK: - Follow System
    func followUser(_ userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let follow = FollowRelationship(followerId: "current_user", followingId: userId)
        
        do {
            try db.collection("follows").addDocument(from: follow) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    self.loadFollowingUsers()
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func unfollowUser(_ userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("follows")
            .whereField("followerId", isEqualTo: "current_user")
            .whereField("followingId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(()))
                    return
                }
                
                for document in documents {
                    document.reference.delete { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                            self.loadFollowingUsers()
                        }
                    }
                }
            }
    }
    
    func loadFollowingUsers() {
        db.collection("follows")
            .whereField("followerId", isEqualTo: "current_user")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading following users: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let followingIds = documents.compactMap { $0.data()["followingId"] as? String }
                
                if followingIds.isEmpty {
                    self.followingUsers = []
                    return
                }
                
                self.db.collection("social_users")
                    .whereField("userId", in: followingIds)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error loading following users: \(error)")
                            return
                        }
                        
                        guard let documents = snapshot?.documents else { return }
                        self.followingUsers = documents.compactMap { try? $0.data(as: SocialUser.self) }
                    }
            }
    }
    
    func loadFollowers() {
        db.collection("follows")
            .whereField("followingId", isEqualTo: "current_user")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading followers: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let followerIds = documents.compactMap { $0.data()["followerId"] as? String }
                
                if followerIds.isEmpty {
                    self.followers = []
                    return
                }
                
                self.db.collection("social_users")
                    .whereField("userId", in: followerIds)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error loading followers: \(error)")
                            return
                        }
                        
                        guard let documents = snapshot?.documents else { return }
                        self.followers = documents.compactMap { try? $0.data(as: SocialUser.self) }
                    }
            }
    }
    
    // MARK: - Leagues
    func loadLeagues() {
        db.collection("leagues")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading leagues: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self.leagues = documents.compactMap { try? $0.data(as: League.self) }
            }
    }
    
    func createLeague(_ league: League, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("leagues").addDocument(from: league) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    self.loadLeagues()
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func joinLeague(_ leagueId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement join league functionality
        completion(.success(()))
    }
    
    func leaveLeague(_ leagueId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement leave league functionality
        completion(.success(()))
    }
    
    // MARK: - User Awards
    func loadUserAwards() {
        db.collection("user_awards")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading user awards: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self.userAwards = documents.compactMap { try? $0.data(as: UserAward.self) }
            }
    }
    
    func createUserAward(_ award: UserAward, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("user_awards").addDocument(from: award) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    self.loadUserAwards()
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func voteForAward(_ awardId: String, nomineeId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement award voting functionality
        completion(.success(()))
    }
    
    // MARK: - Polls
    func loadPolls() {
        db.collection("polls")
            .whereField("isPublic", isEqualTo: true)
            .whereField("status", isEqualTo: "active")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading polls: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self.polls = documents.compactMap { try? $0.data(as: Poll.self) }
            }
    }
    
    func createPoll(_ poll: Poll, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("polls").addDocument(from: poll) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    self.loadPolls()
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func voteInPoll(_ pollId: String, optionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement poll voting functionality
        completion(.success(()))
    }
    
    // MARK: - Moderation
    func loadModerationReports() {
        db.collection("moderation_reports")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading moderation reports: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self.moderationReports = documents.compactMap { try? $0.data(as: ModerationReport.self) }
            }
    }
    
    func createModerationReport(_ report: ModerationReport, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("moderation_reports").addDocument(from: report) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    self.loadModerationReports()
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func moderateContent(_ contentId: String, action: ModerationAction, moderatorId: String, notes: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement content moderation functionality
        completion(.success(()))
    }
    
    // MARK: - Content Filtering
    func filterContent(_ content: String) -> (isAppropriate: Bool, filteredContent: String) {
        let inappropriateWords = [
            "spam", "scam", "fake", "hate", "harassment", "abuse", "threat", "violence"
        ]
        
        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let hasInappropriateContent = words.contains { word in
            inappropriateWords.contains { inappropriate in
                word.contains(inappropriate)
            }
        }
        
        if hasInappropriateContent {
            return (false, content) // Return original content for moderation
        }
        
        return (true, content)
    }
    
    // MARK: - Search
    func searchUsers(_ query: String, completion: @escaping (Result<[SocialUser], Error>) -> Void) {
        db.collection("social_users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThan: query + "z")
            .limit(20)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let users = documents.compactMap { try? $0.data(as: SocialUser.self) }
                completion(.success(users))
            }
    }
    
    func searchPosts(_ query: String, completion: @escaping (Result<[SocialPost], Error>) -> Void) {
        db.collection("social_posts")
            .whereField("content", isGreaterThanOrEqualTo: query)
            .whereField("content", isLessThan: query + "z")
            .limit(20)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let posts = documents.compactMap { try? $0.data(as: SocialPost.self) }
                completion(.success(posts))
            }
    }
    
    // MARK: - Notifications
    func sendNotification(to userId: String, type: NotificationType, title: String, body: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement push notification functionality
        completion(.success(()))
    }
    
    // MARK: - Analytics
    func trackEngagement(_ contentId: String, action: EngagementAction, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement engagement tracking
        completion(.success(()))
    }
}

// MARK: - Supporting Enums
enum ModerationAction: String, CaseIterable {
    case approve = "approve"
    case reject = "reject"
    case flag = "flag"
    case escalate = "escalate"
    case dismiss = "dismiss"
}

enum NotificationType: String, CaseIterable {
    case like = "like"
    case comment = "comment"
    case follow = "follow"
    case mention = "mention"
    case leagueInvite = "leagueInvite"
    case awardVote = "awardVote"
    case pollVote = "pollVote"
}

enum EngagementAction: String, CaseIterable {
    case view = "view"
    case like = "like"
    case comment = "comment"
    case share = "share"
    case bookmark = "bookmark"
    case report = "report"
}
