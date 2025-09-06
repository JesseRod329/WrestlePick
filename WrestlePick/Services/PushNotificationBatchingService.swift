import Foundation
import UserNotifications
import Combine

class PushNotificationBatchingService: NSObject, ObservableObject {
    static let shared = PushNotificationBatchingService()
    
    @Published var isEnabled = true
    @Published var batchSize = 5
    @Published var batchInterval: TimeInterval = 300 // 5 minutes
    @Published var pendingNotifications: [BatchedNotification] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var batchTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Notification categories
    private let newsCategory = "NEWS_CATEGORY"
    private let predictionCategory = "PREDICTION_CATEGORY"
    private let socialCategory = "SOCIAL_CATEGORY"
    private let systemCategory = "SYSTEM_CATEGORY"
    
    private override init() {
        super.init()
        setupNotificationCategories()
        startBatching()
    }
    
    deinit {
        stopBatching()
    }
    
    // MARK: - Setup
    private func setupNotificationCategories() {
        // News category
        let newsAction = UNNotificationAction(
            identifier: "VIEW_NEWS",
            title: "View",
            options: [.foreground]
        )
        
        let newsCategory = UNNotificationCategory(
            identifier: self.newsCategory,
            actions: [newsAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Prediction category
        let predictionAction = UNNotificationAction(
            identifier: "VIEW_PREDICTION",
            title: "View",
            options: [.foreground]
        )
        
        let predictionCategory = UNNotificationCategory(
            identifier: self.predictionCategory,
            actions: [predictionAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Social category
        let socialAction = UNNotificationAction(
            identifier: "VIEW_SOCIAL",
            title: "View",
            options: [.foreground]
        )
        
        let socialCategory = UNNotificationCategory(
            identifier: self.socialCategory,
            actions: [socialAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // System category
        let systemCategory = UNNotificationCategory(
            identifier: self.systemCategory,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([
            newsCategory,
            predictionCategory,
            socialCategory,
            systemCategory
        ])
    }
    
    // MARK: - Batching Control
    func startBatching() {
        guard isEnabled else { return }
        
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { [weak self] _ in
            self?.processBatch()
        }
    }
    
    func stopBatching() {
        batchTimer?.invalidate()
        batchTimer = nil
    }
    
    func setBatchingEnabled(_ enabled: Bool) {
        isEnabled = enabled
        
        if enabled {
            startBatching()
        } else {
            stopBatching()
            // Send all pending notifications immediately
            sendAllPendingNotifications()
        }
    }
    
    // MARK: - Notification Batching
    func addNotification(_ notification: BatchedNotification) {
        guard isEnabled else {
            // Send immediately if batching is disabled
            sendNotification(notification)
            return
        }
        
        pendingNotifications.append(notification)
        
        // Check if we should send the batch
        if pendingNotifications.count >= batchSize {
            processBatch()
        }
    }
    
    private func processBatch() {
        guard !pendingNotifications.isEmpty else { return }
        
        let notificationsToSend = Array(pendingNotifications.prefix(batchSize))
        pendingNotifications.removeFirst(min(notificationsToSend.count, pendingNotifications.count))
        
        // Group notifications by category
        let groupedNotifications = Dictionary(grouping: notificationsToSend) { $0.category }
        
        for (category, notifications) in groupedNotifications {
            if notifications.count == 1 {
                // Send individual notification
                sendNotification(notifications[0])
            } else {
                // Send batched notification
                sendBatchedNotification(notifications, category: category)
            }
        }
    }
    
    private func sendAllPendingNotifications() {
        let allNotifications = pendingNotifications
        pendingNotifications.removeAll()
        
        for notification in allNotifications {
            sendNotification(notification)
        }
    }
    
    // MARK: - Notification Sending
    private func sendNotification(_ notification: BatchedNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.categoryIdentifier = notification.category
        content.userInfo = notification.userInfo
        
        if let imageURL = notification.imageURL {
            content.attachments = [createAttachment(from: imageURL)]
        }
        
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    private func sendBatchedNotification(_ notifications: [BatchedNotification], category: String) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = category
        content.userInfo = ["isBatched": true, "count": notifications.count]
        
        switch category {
        case newsCategory:
            content.title = "\(notifications.count) New News Articles"
            content.body = "You have \(notifications.count) new wrestling news articles to read"
        case predictionCategory:
            content.title = "\(notifications.count) Prediction Updates"
            content.body = "You have \(notifications.count) prediction updates to check"
        case socialCategory:
            content.title = "\(notifications.count) Social Updates"
            content.body = "You have \(notifications.count) new social interactions"
        case systemCategory:
            content.title = "\(notifications.count) App Updates"
            content.body = "You have \(notifications.count) new app updates"
        default:
            content.title = "\(notifications.count) New Updates"
            content.body = "You have \(notifications.count) new updates"
        }
        
        let request = UNNotificationRequest(
            identifier: "batched_\(category)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending batched notification: \(error)")
            }
        }
    }
    
    private func createAttachment(from imageURL: String) -> UNNotificationAttachment? {
        guard let url = URL(string: imageURL) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notification_image.jpg")
            try data.write(to: tempURL)
            
            return try UNNotificationAttachment(identifier: "image", url: tempURL, options: nil)
        } catch {
            print("Error creating notification attachment: \(error)")
            return nil
        }
    }
    
    // MARK: - Specific Notification Types
    func sendNewsNotification(_ article: NewsArticle) {
        let notification = BatchedNotification(
            id: "news_\(article.id ?? UUID().uuidString)",
            title: "Breaking News",
            body: article.title,
            category: newsCategory,
            imageURL: article.imageURL,
            userInfo: [
                "articleId": article.id ?? "",
                "type": "news"
            ]
        )
        
        addNotification(notification)
    }
    
    func sendPredictionNotification(_ prediction: Prediction) {
        let notification = BatchedNotification(
            id: "prediction_\(prediction.id ?? UUID().uuidString)",
            title: "Prediction Update",
            body: "Your prediction '\(prediction.title)' has been resolved",
            category: predictionCategory,
            userInfo: [
                "predictionId": prediction.id ?? "",
                "type": "prediction"
            ]
        )
        
        addNotification(notification)
    }
    
    func sendSocialNotification(_ type: SocialNotificationType, user: String, content: String) {
        let title: String
        let body: String
        
        switch type {
        case .like:
            title = "New Like"
            body = "\(user) liked your prediction"
        case .comment:
            title = "New Comment"
            body = "\(user) commented on your prediction"
        case .follow:
            title = "New Follower"
            body = "\(user) started following you"
        case .mention:
            title = "Mentioned"
            body = "\(user) mentioned you in a comment"
        }
        
        let notification = BatchedNotification(
            id: "social_\(UUID().uuidString)",
            title: title,
            body: body,
            category: socialCategory,
            userInfo: [
                "type": "social",
                "socialType": type.rawValue,
                "user": user
            ]
        )
        
        addNotification(notification)
    }
    
    func sendSystemNotification(_ title: String, body: String, type: SystemNotificationType) {
        let notification = BatchedNotification(
            id: "system_\(UUID().uuidString)",
            title: title,
            body: body,
            category: systemCategory,
            userInfo: [
                "type": "system",
                "systemType": type.rawValue
            ]
        )
        
        addNotification(notification)
    }
    
    // MARK: - Settings
    func updateBatchSize(_ size: Int) {
        batchSize = max(1, min(size, 20)) // Limit between 1 and 20
    }
    
    func updateBatchInterval(_ interval: TimeInterval) {
        batchInterval = max(60, min(interval, 3600)) // Limit between 1 minute and 1 hour
        stopBatching()
        startBatching()
    }
    
    // MARK: - Analytics
    func getNotificationStats() -> NotificationStats {
        return NotificationStats(
            totalSent: pendingNotifications.count,
            batchSize: batchSize,
            batchInterval: batchInterval,
            isEnabled: isEnabled
        )
    }
}

// MARK: - Batched Notification
struct BatchedNotification {
    let id: String
    let title: String
    let body: String
    let category: String
    let imageURL: String?
    let userInfo: [String: Any]
    let timestamp: Date
    
    init(id: String, title: String, body: String, category: String, imageURL: String? = nil, userInfo: [String: Any] = [:]) {
        self.id = id
        self.title = title
        self.body = body
        self.category = category
        self.imageURL = imageURL
        self.userInfo = userInfo
        self.timestamp = Date()
    }
}

// MARK: - Social Notification Type
enum SocialNotificationType: String, CaseIterable {
    case like = "like"
    case comment = "comment"
    case follow = "follow"
    case mention = "mention"
}

// MARK: - System Notification Type
enum SystemNotificationType: String, CaseIterable {
    case update = "update"
    case maintenance = "maintenance"
    case feature = "feature"
    case reminder = "reminder"
}

// MARK: - Notification Stats
struct NotificationStats {
    let totalSent: Int
    let batchSize: Int
    let batchInterval: TimeInterval
    let isEnabled: Bool
}

// MARK: - Smart Notification Scheduler
class SmartNotificationScheduler: ObservableObject {
    static let shared = SmartNotificationScheduler()
    
    @Published var userActiveHours: ClosedRange<Int> = 8...22
    @Published var quietHours: ClosedRange<Int> = 23...7
    @Published var maxNotificationsPerHour: Int = 3
    @Published var respectDoNotDisturb: Bool = true
    
    private var notificationCounts: [String: Int] = [:]
    private var lastNotificationTime: Date?
    
    func shouldSendNotification(_ notification: BatchedNotification) -> Bool {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        
        // Check if we're in quiet hours
        if isQuietHours(hour) {
            return false
        }
        
        // Check if we've exceeded the hourly limit
        let hourKey = "\(Calendar.current.component(.year, from: now))_\(Calendar.current.component(.month, from: now))_\(Calendar.current.component(.day, from: now))_\(hour)"
        let currentCount = notificationCounts[hourKey] ?? 0
        
        if currentCount >= maxNotificationsPerHour {
            return false
        }
        
        // Check if we're respecting Do Not Disturb
        if respectDoNotDisturb && isDoNotDisturbActive() {
            return false
        }
        
        return true
    }
    
    func recordNotificationSent(_ notification: BatchedNotification) {
        let now = Date()
        let hourKey = "\(Calendar.current.component(.year, from: now))_\(Calendar.current.component(.month, from: now))_\(Calendar.current.component(.day, from: now))_\(Calendar.current.component(.hour, from: now))"
        
        notificationCounts[hourKey, default: 0] += 1
        lastNotificationTime = now
        
        // Clean up old counts
        cleanupOldCounts()
    }
    
    private func isQuietHours(_ hour: Int) -> Bool {
        if quietHours.lowerBound <= quietHours.upperBound {
            return hour >= quietHours.lowerBound && hour <= quietHours.upperBound
        } else {
            // Handle case where quiet hours cross midnight
            return hour >= quietHours.lowerBound || hour <= quietHours.upperBound
        }
    }
    
    private func isDoNotDisturbActive() -> Bool {
        // This would integrate with the system's Do Not Disturb status
        // For now, return false as a placeholder
        return false
    }
    
    private func cleanupOldCounts() {
        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)
        let currentDay = Calendar.current.component(.day, from: now)
        
        notificationCounts = notificationCounts.filter { key, _ in
            let components = key.split(separator: "_")
            guard components.count >= 4,
                  let day = Int(components[2]),
                  let hour = Int(components[3]) else { return false }
            
            // Keep counts from today and the last hour
            return day == currentDay && hour >= currentHour - 1
        }
    }
}

// MARK: - Notification Preferences
class NotificationPreferences: ObservableObject {
    static let shared = NotificationPreferences()
    
    @Published var newsEnabled: Bool = true
    @Published var predictionEnabled: Bool = true
    @Published var socialEnabled: Bool = true
    @Published var systemEnabled: Bool = true
    @Published var breakingNewsEnabled: Bool = true
    @Published var predictionRemindersEnabled: Bool = true
    @Published var socialMentionsEnabled: Bool = true
    @Published var systemUpdatesEnabled: Bool = true
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadPreferences()
    }
    
    private func loadPreferences() {
        newsEnabled = userDefaults.bool(forKey: "news_enabled")
        predictionEnabled = userDefaults.bool(forKey: "prediction_enabled")
        socialEnabled = userDefaults.bool(forKey: "social_enabled")
        systemEnabled = userDefaults.bool(forKey: "system_enabled")
        breakingNewsEnabled = userDefaults.bool(forKey: "breaking_news_enabled")
        predictionRemindersEnabled = userDefaults.bool(forKey: "prediction_reminders_enabled")
        socialMentionsEnabled = userDefaults.bool(forKey: "social_mentions_enabled")
        systemUpdatesEnabled = userDefaults.bool(forKey: "system_updates_enabled")
    }
    
    func savePreferences() {
        userDefaults.set(newsEnabled, forKey: "news_enabled")
        userDefaults.set(predictionEnabled, forKey: "prediction_enabled")
        userDefaults.set(socialEnabled, forKey: "social_enabled")
        userDefaults.set(systemEnabled, forKey: "system_enabled")
        userDefaults.set(breakingNewsEnabled, forKey: "breaking_news_enabled")
        userDefaults.set(predictionRemindersEnabled, forKey: "prediction_reminders_enabled")
        userDefaults.set(socialMentionsEnabled, forKey: "social_mentions_enabled")
        userDefaults.set(systemUpdatesEnabled, forKey: "system_updates_enabled")
    }
    
    func isNotificationEnabled(for type: NotificationType) -> Bool {
        switch type {
        case .news:
            return newsEnabled
        case .prediction:
            return predictionEnabled
        case .social:
            return socialEnabled
        case .system:
            return systemEnabled
        case .breakingNews:
            return breakingNewsEnabled
        case .predictionReminder:
            return predictionRemindersEnabled
        case .socialMention:
            return socialMentionsEnabled
        case .systemUpdate:
            return systemUpdatesEnabled
        }
    }
}

// MARK: - Notification Type
enum NotificationType: String, CaseIterable {
    case news = "news"
    case prediction = "prediction"
    case social = "social"
    case system = "system"
    case breakingNews = "breaking_news"
    case predictionReminder = "prediction_reminder"
    case socialMention = "social_mention"
    case systemUpdate = "system_update"
}
