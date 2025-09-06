import Foundation
import Combine
import FirebaseFirestore

class NewsService: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    private let rssService = RSSFeedService()
    
    init() {
        // Process RSS feeds on initialization
        rssService.processAllFeeds()
    }
    
    func fetchArticles(limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("status", isEqualTo: "published")
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchArticlesByCategory(_ category: NewsCategory, limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("category", isEqualTo: category.rawValue)
            .whereField("status", isEqualTo: "published")
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func searchArticles(query: String, limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("title", isGreaterThanOrEqualTo: query)
            .whereField("title", isLessThan: query + "\u{f8ff}")
            .whereField("status", isEqualTo: "published")
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchRumorArticles(limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("isRumor", isEqualTo: true)
            .whereField("status", isEqualTo: "published")
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchBreakingNews(limit: Int = 20) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("isBreaking", isEqualTo: true)
            .whereField("status", isEqualTo: "published")
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func fetchHighReliabilityArticles(minScore: Double = 0.7, limit: Int = 50) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.newsArticles)
            .whereField("reliabilityScore", isGreaterThanOrEqualTo: minScore)
            .whereField("status", isEqualTo: "published")
            .order(by: "reliabilityScore", descending: true)
            .order(by: "publishDate", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.articles = snapshot?.documents.compactMap { document in
                            try? document.data(as: NewsArticle.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func likeArticle(_ articleId: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let likeData = [
            "userId": currentUser.id ?? "",
            "articleId": articleId,
            "timestamp": Date()
        ] as [String : Any]
        
        db.collection("likes")
            .addDocument(data: likeData) { error in
                if let error = error {
                    print("Error liking article: \(error)")
                }
            }
    }
    
    func bookmarkArticle(_ articleId: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let bookmarkData = [
            "userId": currentUser.id ?? "",
            "articleId": articleId,
            "timestamp": Date()
        ] as [String : Any]
        
        db.collection("bookmarks")
            .addDocument(data: bookmarkData) { error in
                if let error = error {
                    print("Error bookmarking article: \(error)")
                }
            }
    }
    
    func shareArticle(_ articleId: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let shareData = [
            "userId": currentUser.id ?? "",
            "articleId": articleId,
            "timestamp": Date()
        ] as [String : Any]
        
        db.collection("shares")
            .addDocument(data: shareData) { error in
                if let error = error {
                    print("Error sharing article: \(error)")
                }
            }
    }
    
    func reportArticle(_ articleId: String, reason: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let reportData = [
            "userId": currentUser.id ?? "",
            "articleId": articleId,
            "reason": reason,
            "timestamp": Date(),
            "status": "pending"
        ] as [String : Any]
        
        db.collection("reports")
            .addDocument(data: reportData) { error in
                if let error = error {
                    print("Error reporting article: \(error)")
                }
            }
    }
}
