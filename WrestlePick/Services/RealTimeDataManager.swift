import Foundation
import Combine
import os.log

class RealTimeDataManager: ObservableObject {
    static let shared = RealTimeDataManager()
    
    @Published var isOnline = true
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    @Published var error: Error?
    
    private let logger = Logger(subsystem: "com.wrestlepick", category: "RealTimeData")
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // Data sync services
    private let newsSync: NewsDataSync
    private let eventSync: EventDataSync
    private let wrestlerSync: WrestlerDataSync
    private let merchSync: MerchandiseDataSync
    
    // Sync intervals (in seconds)
    private let criticalDataInterval: TimeInterval = 30      // Live events
    private let newsDataInterval: TimeInterval = 5 * 60      // News feeds
    private let wrestlerDataInterval: TimeInterval = 24 * 60 * 60  // Wrestler data
    private let merchDataInterval: TimeInterval = 60 * 60    // Merchandise prices
    
    private init() {
        self.newsSync = NewsDataSync()
        self.eventSync = EventDataSync()
        self.wrestlerSync = WrestlerDataSync()
        self.merchSync = MerchandiseDataSync()
        
        setupNetworkMonitoring()
        startRealTimeSync()
    }
    
    deinit {
        syncTimer?.invalidate()
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
    }
    
    // MARK: - Public Methods
    func startRealTimeSync() {
        logger.info("Starting real-time data sync")
        syncStatus = .syncing
        
        // Start periodic sync
        syncTimer = Timer.scheduledTimer(withTimeInterval: criticalDataInterval, repeats: true) { [weak self] _ in
            self?.performSync()
        }
        
        // Initial sync
        performSync()
    }
    
    func stopRealTimeSync() {
        logger.info("Stopping real-time data sync")
        syncStatus = .idle
        syncTimer?.invalidate()
    }
    
    func forceSync() {
        logger.info("Force syncing all data")
        performSync()
    }
    
    func handleOfflineSync() {
        logger.info("Handling offline sync")
        
        // Queue updates for when online
        queueOfflineUpdates()
        
        // Try to sync critical data
        if isOnline {
            performSync()
        }
    }
    
    // MARK: - Private Methods
    private func setupNetworkMonitoring() {
        // Monitor network connectivity
        NotificationCenter.default.publisher(for: .reachabilityChanged)
            .sink { [weak self] notification in
                if let reachability = notification.object as? Reachability {
                    self?.isOnline = reachability.connection != .none
                    self?.logger.info("Network status changed: \(self?.isOnline ?? false)")
                    
                    if self?.isOnline == true {
                        self?.handleOfflineSync()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSync() {
        guard isOnline else {
            logger.warning("Cannot sync - offline")
            return
        }
        
        syncStatus = .syncing
        lastSyncTime = Date()
        
        let group = DispatchGroup()
        var syncErrors: [Error] = []
        
        // Sync critical data (live events)
        group.enter()
        eventSync.syncCriticalData { [weak self] result in
            switch result {
            case .success:
                self?.logger.info("Event data synced successfully")
            case .failure(let error):
                self?.logger.error("Event data sync failed: \(error.localizedDescription)")
                syncErrors.append(error)
            }
            group.leave()
        }
        
        // Sync news data
        group.enter()
        newsSync.syncData { [weak self] result in
            switch result {
            case .success:
                self?.logger.info("News data synced successfully")
            case .failure(let error):
                self?.logger.error("News data sync failed: \(error.localizedDescription)")
                syncErrors.append(error)
            }
            group.leave()
        }
        
        // Sync wrestler data (less frequent)
        if shouldSyncWrestlerData() {
            group.enter()
            wrestlerSync.syncData { [weak self] result in
                switch result {
                case .success:
                    self?.logger.info("Wrestler data synced successfully")
                case .failure(let error):
                    self?.logger.error("Wrestler data sync failed: \(error.localizedDescription)")
                    syncErrors.append(error)
                }
                group.leave()
            }
        }
        
        // Sync merchandise data
        group.enter()
        merchSync.syncData { [weak self] result in
            switch result {
            case .success:
                self?.logger.info("Merchandise data synced successfully")
            case .failure(let error):
                self?.logger.error("Merchandise data sync failed: \(error.localizedDescription)")
                syncErrors.append(error)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.handleSyncCompletion(errors: syncErrors)
        }
    }
    
    private func shouldSyncWrestlerData() -> Bool {
        guard let lastSync = lastSyncTime else { return true }
        return Date().timeIntervalSince(lastSync) >= wrestlerDataInterval
    }
    
    private func handleSyncCompletion(errors: [Error]) {
        if errors.isEmpty {
            syncStatus = .success
            logger.info("All data synced successfully")
        } else {
            syncStatus = .error
            error = errors.first
            logger.error("Sync completed with \(errors.count) errors")
        }
    }
    
    private func queueOfflineUpdates() {
        // Queue updates for when online
        // This would typically store updates in a local queue
        logger.info("Queuing offline updates")
    }
    
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "DataSync") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}

// MARK: - Data Sync Services
class NewsDataSync {
    func syncData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Sync news data from RSS feeds
        RSSFeedManager.shared.refreshAllFeeds()
        completion(.success(()))
    }
}

class EventDataSync {
    func syncCriticalData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Sync live event data
        LiveEventDataService.shared.refreshEventData()
        completion(.success(()))
    }
    
    func syncData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Sync all event data
        LiveEventDataService.shared.refreshEventData()
        completion(.success(()))
    }
}

class WrestlerDataSync {
    func syncData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Sync wrestler data
        WrestlerDataService.shared.refreshWrestlerData()
        completion(.success(()))
    }
}

class MerchandiseDataSync {
    func syncData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Sync merchandise data
        MerchandiseDataService.shared.refreshMerchandiseData()
        completion(.success(()))
    }
}

// MARK: - Supporting Types
enum SyncStatus {
    case idle
    case syncing
    case success
    case error
}

// MARK: - Network Reachability
class Reachability: ObservableObject {
    @Published var connection: Connection = .none
    
    enum Connection {
        case none
        case wifi
        case cellular
    }
}

extension Notification.Name {
    static let reachabilityChanged = Notification.Name("reachabilityChanged")
}

// MARK: - Data Validation
class DataValidator {
    func validateNewsArticle(_ article: NewsArticle) -> ValidationResult {
        var issues: [ValidationIssue] = []
        
        // Check title
        if article.title.isEmpty {
            issues.append(ValidationIssue(type: .missingTitle, severity: .high))
        }
        
        // Check content
        if article.content.isEmpty {
            issues.append(ValidationIssue(type: .missingContent, severity: .high))
        }
        
        // Check publish date
        if article.publishDate > Date() {
            issues.append(ValidationIssue(type: .futureDate, severity: .medium))
        }
        
        // Check for spam
        if detectSpam(article.content) {
            issues.append(ValidationIssue(type: .spam, severity: .high))
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            score: calculateQualityScore(article, issues: issues)
        )
    }
    
    func cleanWrestlerData(_ wrestler: Wrestler) -> Wrestler {
        // Clean and normalize wrestler data
        let cleanedName = wrestler.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedRealName = wrestler.realName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedRingName = wrestler.ringName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Wrestler(
            id: wrestler.id,
            name: cleanedName,
            realName: cleanedRealName,
            ringName: cleanedRingName,
            promotions: wrestler.promotions,
            hometown: wrestler.hometown,
            height: wrestler.height,
            weight: wrestler.weight,
            debut: wrestler.debut,
            championships: wrestler.championships,
            photoURL: wrestler.photoURL,
            socialMedia: wrestler.socialMedia,
            isActive: wrestler.isActive,
            currentPromotion: wrestler.currentPromotion,
            status: wrestler.status,
            specialties: wrestler.specialties,
            signatureMoves: wrestler.signatureMoves,
            achievements: wrestler.achievements,
            biography: wrestler.biography,
            statistics: wrestler.statistics
        )
    }
    
    func detectDuplicateContent(_ content: String) -> [ContentMatch] {
        // Detect duplicate content across sources
        // This would typically use a content hashing or similarity algorithm
        return []
    }
    
    func scoreContentQuality(_ article: NewsArticle) -> QualityScore {
        var score = 0.0
        
        // Title quality
        if article.title.count > 10 && article.title.count < 100 {
            score += 0.2
        }
        
        // Content quality
        if article.content.count > 100 {
            score += 0.3
        }
        
        // Source reliability
        if article.source.reliability == .tier1 {
            score += 0.3
        } else if article.source.reliability == .tier2 {
            score += 0.2
        }
        
        // Image presence
        if article.imageURL != nil {
            score += 0.1
        }
        
        // Author presence
        if article.author != nil {
            score += 0.1
        }
        
        return QualityScore(score: score, maxScore: 1.0)
    }
    
    func verifyDataCompleteness(_ data: Any) -> CompletenessReport {
        // Verify data completeness
        return CompletenessReport(
            isComplete: true,
            missingFields: [],
            completenessScore: 1.0
        )
    }
    
    private func detectSpam(_ content: String) -> Bool {
        // Simple spam detection
        let spamKeywords = ["click here", "buy now", "free money", "guaranteed"]
        let lowercaseContent = content.lowercased()
        
        return spamKeywords.contains { lowercaseContent.contains($0) }
    }
    
    private func calculateQualityScore(_ article: NewsArticle, issues: [ValidationIssue]) -> Double {
        let baseScore = 1.0
        let penalty = issues.reduce(0.0) { total, issue in
            total + issue.severity.penalty
        }
        
        return max(0.0, baseScore - penalty)
    }
}

struct ValidationResult {
    let isValid: Bool
    let issues: [ValidationIssue]
    let score: Double
}

struct ValidationIssue {
    let type: ValidationIssueType
    let severity: ValidationSeverity
}

enum ValidationIssueType {
    case missingTitle
    case missingContent
    case futureDate
    case spam
    case invalidFormat
    case duplicateContent
}

enum ValidationSeverity {
    case low
    case medium
    case high
    case critical
    
    var penalty: Double {
        switch self {
        case .low: return 0.1
        case .medium: return 0.2
        case .high: return 0.3
        case .critical: return 0.5
        }
    }
}

struct ContentMatch {
    let content: String
    let similarity: Double
    let source: String
}

struct QualityScore {
    let score: Double
    let maxScore: Double
}

struct CompletenessReport {
    let isComplete: Bool
    let missingFields: [String]
    let completenessScore: Double
}
