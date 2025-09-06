import Foundation
import SQLite
import Combine

class LocalDatabaseService: ObservableObject {
    static let shared = LocalDatabaseService()
    
    private var db: Connection?
    private let fileManager = FileManager.default
    private let databasePath: String
    
    // Tables
    private let newsArticles = Table("news_articles")
    private let predictions = Table("predictions")
    private let userProfiles = Table("user_profiles")
    private let cacheData = Table("cache_data")
    private let syncQueue = Table("sync_queue")
    
    // Columns
    private let id = Expression<String>("id")
    private let title = Expression<String>("title")
    private let content = Expression<String>("content")
    private let source = Expression<String>("source")
    private let publishDate = Expression<Date>("publish_date")
    private let imageURL = Expression<String?>("image_url")
    private let category = Expression<String>("category")
    private let reliabilityScore = Expression<Double>("reliability_score")
    private let isBookmarked = Expression<Bool>("is_bookmarked")
    private let isLiked = Expression<Bool>("is_liked")
    private let likes = Expression<Int>("likes")
    private let comments = Expression<Int>("comments")
    private let shares = Expression<Int>("shares")
    private let createdAt = Expression<Date>("created_at")
    private let updatedAt = Expression<Date>("updated_at")
    private let syncStatus = Expression<String>("sync_status")
    private let data = Expression<Data>("data")
    private let key = Expression<String>("key")
    private let expiresAt = Expression<Date?>("expires_at")
    
    private init() {
        // Set up database path
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        databasePath = documentsPath.appendingPathComponent("WrestlePick.db").path
        
        setupDatabase()
    }
    
    // MARK: - Database Setup
    private func setupDatabase() {
        do {
            db = try Connection(databasePath)
            try createTables()
        } catch {
            print("Database setup error: \(error)")
        }
    }
    
    private func createTables() throws {
        guard let db = db else { return }
        
        // News articles table
        try db.run(newsArticles.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(title)
            t.column(content)
            t.column(source)
            t.column(publishDate)
            t.column(imageURL)
            t.column(category)
            t.column(reliabilityScore)
            t.column(isBookmarked, defaultValue: false)
            t.column(isLiked, defaultValue: false)
            t.column(likes, defaultValue: 0)
            t.column(comments, defaultValue: 0)
            t.column(shares, defaultValue: 0)
            t.column(createdAt, defaultValue: Date())
            t.column(updatedAt, defaultValue: Date())
            t.column(syncStatus, defaultValue: "synced")
        })
        
        // Predictions table
        try db.run(predictions.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(title)
            t.column(content)
            t.column(category)
            t.column(createdAt, defaultValue: Date())
            t.column(updatedAt, defaultValue: Date())
            t.column(syncStatus, defaultValue: "synced")
        })
        
        // User profiles table
        try db.run(userProfiles.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(data)
            t.column(createdAt, defaultValue: Date())
            t.column(updatedAt, defaultValue: Date())
            t.column(syncStatus, defaultValue: "synced")
        })
        
        // Cache data table
        try db.run(cacheData.create(ifNotExists: true) { t in
            t.column(key, primaryKey: true)
            t.column(data)
            t.column(createdAt, defaultValue: Date())
            t.column(expiresAt)
        })
        
        // Sync queue table
        try db.run(syncQueue.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(data)
            t.column(createdAt, defaultValue: Date())
            t.column(syncStatus, defaultValue: "pending")
        })
        
        // Create indexes for better performance
        try createIndexes()
    }
    
    private func createIndexes() throws {
        guard let db = db else { return }
        
        try db.run(newsArticles.createIndex(publishDate, ifNotExists: true))
        try db.run(newsArticles.createIndex(category, ifNotExists: true))
        try db.run(newsArticles.createIndex(source, ifNotExists: true))
        try db.run(predictions.createIndex(createdAt, ifNotExists: true))
        try db.run(predictions.createIndex(category, ifNotExists: true))
        try db.run(cacheData.createIndex(expiresAt, ifNotExists: true))
        try db.run(syncQueue.createIndex(syncStatus, ifNotExists: true))
    }
    
    // MARK: - News Articles
    func saveNewsArticle(_ article: NewsArticle) throws {
        guard let db = db else { return }
        
        let insert = newsArticles.insert(
            id <- article.id ?? UUID().uuidString,
            title <- article.title,
            content <- article.content,
            source <- article.source,
            publishDate <- article.publishDate,
            imageURL <- article.imageURL,
            category <- article.category.rawValue,
            reliabilityScore <- article.reliabilityScore,
            isBookmarked <- article.isBookmarked,
            isLiked <- article.isLiked,
            likes <- article.likes,
            comments <- article.comments,
            shares <- article.shares,
            createdAt <- article.createdAt,
            updatedAt <- Date(),
            syncStatus <- "synced"
        )
        
        try db.run(insert)
    }
    
    func getNewsArticles(limit: Int = 50, offset: Int = 0) throws -> [NewsArticle] {
        guard let db = db else { return [] }
        
        let query = newsArticles
            .order(publishDate.desc)
            .limit(limit, offset: offset)
        
        var articles: [NewsArticle] = []
        
        for row in try db.prepare(query) {
            let article = NewsArticle(
                id: row[id],
                title: row[title],
                content: row[content],
                author: "", // Not stored in local DB
                source: row[source],
                publishDate: row[publishDate],
                imageURL: row[imageURL],
                category: NewsCategory(rawValue: row[category]) ?? .general,
                reliabilityScore: row[reliabilityScore],
                isBookmarked: row[isBookmarked],
                isLiked: row[isLiked],
                likes: row[likes],
                comments: row[comments],
                shares: row[shares],
                createdAt: row[createdAt],
                updatedAt: row[updatedAt]
            )
            articles.append(article)
        }
        
        return articles
    }
    
    func updateNewsArticle(_ article: NewsArticle) throws {
        guard let db = db, let articleId = article.id else { return }
        
        let update = newsArticles.filter(id == articleId)
            .update(
                title <- article.title,
                content <- article.content,
                isBookmarked <- article.isBookmarked,
                isLiked <- article.isLiked,
                likes <- article.likes,
                comments <- article.comments,
                shares <- article.shares,
                updatedAt <- Date(),
                syncStatus <- "pending"
            )
        
        try db.run(update)
    }
    
    func deleteNewsArticle(_ articleId: String) throws {
        guard let db = db else { return }
        
        let delete = newsArticles.filter(id == articleId)
        try db.run(delete.delete())
    }
    
    // MARK: - Predictions
    func savePrediction(_ prediction: Prediction) throws {
        guard let db = db else { return }
        
        let predictionData = try JSONEncoder().encode(prediction)
        
        let insert = predictions.insert(
            id <- prediction.id ?? UUID().uuidString,
            title <- prediction.title,
            content <- prediction.description,
            category <- prediction.category.rawValue,
            createdAt <- prediction.createdAt,
            updatedAt <- Date(),
            syncStatus <- "synced"
        )
        
        try db.run(insert)
    }
    
    func getPredictions(limit: Int = 50, offset: Int = 0) throws -> [Prediction] {
        guard let db = db else { return [] }
        
        let query = predictions
            .order(createdAt.desc)
            .limit(limit, offset: offset)
        
        var predictions: [Prediction] = []
        
        for row in try db.prepare(query) {
            // This is a simplified version - in reality, you'd need to decode the full prediction
            let prediction = Prediction(
                userId: "", // Not stored in local DB
                title: row[title],
                description: row[content],
                category: PredictionCategory(rawValue: row[category]) ?? .ppv,
                eventId: "", // Not stored in local DB
                eventName: "", // Not stored in local DB
                eventDate: Date(), // Not stored in local DB
                status: .draft, // Not stored in local DB
                confidence: 5, // Not stored in local DB
                tags: [], // Not stored in local DB
                isPublic: true, // Not stored in local DB
                picks: [], // Not stored in local DB
                accuracy: nil, // Not stored in local DB
                engagement: nil, // Not stored in local DB
                createdAt: row[createdAt],
                updatedAt: row[updatedAt]
            )
            predictions.append(prediction)
        }
        
        return predictions
    }
    
    // MARK: - Cache Management
    func saveCacheData(key: String, data: Data, expiresAt: Date? = nil) throws {
        guard let db = db else { return }
        
        let insert = cacheData.insert(
            key <- key,
            data <- data,
            createdAt <- Date(),
            expiresAt <- expiresAt
        )
        
        try db.run(insert)
    }
    
    func getCacheData(key: String) throws -> Data? {
        guard let db = db else { return nil }
        
        let query = cacheData.filter(self.key == key)
        
        for row in try db.prepare(query) {
            // Check if data has expired
            if let expiresAt = row[expiresAt], expiresAt < Date() {
                try deleteCacheData(key: key)
                return nil
            }
            
            return row[data]
        }
        
        return nil
    }
    
    func deleteCacheData(key: String) throws {
        guard let db = db else { return }
        
        let delete = cacheData.filter(self.key == key)
        try db.run(delete.delete())
    }
    
    func clearExpiredCache() throws {
        guard let db = db else { return }
        
        let now = Date()
        let delete = cacheData.filter(expiresAt < now)
        try db.run(delete.delete())
    }
    
    // MARK: - Sync Queue
    func addToSyncQueue(data: Data, type: String) throws {
        guard let db = db else { return }
        
        let insert = syncQueue.insert(
            id <- UUID().uuidString,
            data <- data,
            createdAt <- Date(),
            syncStatus <- "pending"
        )
        
        try db.run(insert)
    }
    
    func getPendingSyncItems() throws -> [SyncItem] {
        guard let db = db else { return [] }
        
        let query = syncQueue.filter(syncStatus == "pending")
        
        var items: [SyncItem] = []
        
        for row in try db.prepare(query) {
            let item = SyncItem(
                id: row[id],
                data: row[data],
                createdAt: row[createdAt],
                status: row[syncStatus]
            )
            items.append(item)
        }
        
        return items
    }
    
    func markSyncItemAsSynced(_ itemId: String) throws {
        guard let db = db else { return }
        
        let update = syncQueue.filter(id == itemId)
            .update(syncStatus <- "synced")
        
        try db.run(update)
    }
    
    func markSyncItemAsFailed(_ itemId: String) throws {
        guard let db = db else { return }
        
        let update = syncQueue.filter(id == itemId)
            .update(syncStatus <- "failed")
        
        try db.run(update)
    }
    
    // MARK: - Database Maintenance
    func vacuumDatabase() throws {
        guard let db = db else { return }
        try db.execute("VACUUM")
    }
    
    func getDatabaseSize() -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: databasePath)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    func clearAllData() throws {
        guard let db = db else { return }
        
        try db.run(newsArticles.delete())
        try db.run(predictions.delete())
        try db.run(userProfiles.delete())
        try db.run(cacheData.delete())
        try db.run(syncQueue.delete())
    }
    
    // MARK: - Backup and Restore
    func createBackup() throws -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupPath = documentsPath.appendingPathComponent("WrestlePick_Backup_\(Date().timeIntervalSince1970).db")
        
        try fileManager.copyItem(atPath: databasePath, toPath: backupPath.path)
        
        return backupPath
    }
    
    func restoreFromBackup(_ backupURL: URL) throws {
        try fileManager.removeItem(atPath: databasePath)
        try fileManager.copyItem(at: backupURL, to: URL(fileURLWithPath: databasePath))
        
        // Reconnect to database
        db = try Connection(databasePath)
    }
}

// MARK: - Sync Item
struct SyncItem {
    let id: String
    let data: Data
    let createdAt: Date
    let status: String
}

// MARK: - Offline Manager
class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var isOffline = false
    @Published var pendingSyncItems: Int = 0
    
    private let localDB = LocalDatabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNetworkMonitoring()
        loadPendingSyncItems()
    }
    
    private func setupNetworkMonitoring() {
        // Monitor network status
        NotificationCenter.default.publisher(for: .networkStatusChanged)
            .sink { [weak self] notification in
                if let isConnected = notification.userInfo?["isConnected"] as? Bool {
                    self?.isOffline = !isConnected
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadPendingSyncItems() {
        do {
            let items = try localDB.getPendingSyncItems()
            pendingSyncItems = items.count
        } catch {
            print("Error loading pending sync items: \(error)")
        }
    }
    
    func syncPendingItems() {
        guard !isOffline else { return }
        
        Task {
            do {
                let items = try localDB.getPendingSyncItems()
                
                for item in items {
                    // Attempt to sync item
                    let success = await syncItem(item)
                    
                    if success {
                        try localDB.markSyncItemAsSynced(item.id)
                    } else {
                        try localDB.markSyncItemAsFailed(item.id)
                    }
                }
                
                await MainActor.run {
                    loadPendingSyncItems()
                }
            } catch {
                print("Error syncing pending items: \(error)")
            }
        }
    }
    
    private func syncItem(_ item: SyncItem) async -> Bool {
        // Implement actual sync logic here
        // This would typically involve making network requests
        return true
    }
}

// MARK: - Network Status Notification
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
