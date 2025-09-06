import Foundation
import FirebaseMessaging
import UserNotifications
import FirebaseFirestore

class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var isAuthorized = false
    @Published var fcmToken: String?
    
    private let db = Firestore.firestore()
    
    override init() {
        super.init()
        setupNotificationCenter()
        requestNotificationPermissions()
    }
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func sendNotification(title: String, body: String, data: [String: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = data
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, date: Date, data: [String: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = data
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func sendPredictionReminder(prediction: Prediction) {
        let title = "Prediction Reminder"
        let body = "Your prediction '\(prediction.title)' is due soon!"
        let data = [
            "type": "prediction_reminder",
            "predictionId": prediction.id ?? "",
            "eventDate": prediction.eventDate.timeIntervalSince1970
        ]
        
        sendNotification(title: title, body: body, data: data)
    }
    
    func sendEventNotification(event: Event) {
        let title = "Event Starting Soon"
        let body = "\(event.name) is starting in 30 minutes!"
        let data = [
            "type": "event_reminder",
            "eventId": event.id ?? "",
            "eventName": event.name
        ]
        
        sendNotification(title: title, body: body, data: data)
    }
    
    func sendNewsAlert(article: NewsArticle) {
        let title = "Breaking News"
        let body = article.title
        let data = [
            "type": "news_alert",
            "articleId": article.id ?? "",
            "category": article.category.rawValue
        ]
        
        sendNotification(title: title, body: body, data: data)
    }
    
    func sendAwardNotification(award: Award) {
        let title = "New Award Created"
        let body = "\(award.createdByUsername) created '\(award.name)'"
        let data = [
            "type": "award_created",
            "awardId": award.id ?? "",
            "awardName": award.name
        ]
        
        sendNotification(title: title, body: body, data: data)
    }
    
    func sendMerchNotification(merchItem: MerchItem) {
        let title = "New Merch Available"
        let body = "Check out the new \(merchItem.name)"
        let data = [
            "type": "merch_alert",
            "itemId": merchItem.id ?? "",
            "itemName": merchItem.name
        ]
        
        sendNotification(title: title, body: body, data: data)
    }
    
    func subscribeToTopic(_ topic: String) {
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Error subscribing to topic \(topic): \(error)")
            } else {
                print("Successfully subscribed to topic: \(topic)")
            }
        }
    }
    
    func unsubscribeFromTopic(_ topic: String) {
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("Error unsubscribing from topic \(topic): \(error)")
            } else {
                print("Successfully unsubscribed from topic: \(topic)")
            }
        }
    }
    
    func updateUserNotificationPreferences(userId: String, preferences: NotificationSettings) {
        db.collection(FirestoreCollections.users)
            .document(userId)
            .updateData([
                "preferences.notificationSettings": preferences.dictionary
            ]) { error in
                if let error = error {
                    print("Error updating notification preferences: \(error)")
                }
            }
    }
    
    func sendNotificationToUser(userId: String, title: String, body: String, data: [String: Any] = [:]) {
        let notification = [
            "userId": userId,
            "title": title,
            "body": body,
            "data": data,
            "timestamp": Date(),
            "isRead": false
        ] as [String : Any]
        
        db.collection(FirestoreCollections.notifications)
            .addDocument(data: notification) { error in
                if let error = error {
                    print("Error sending notification to user: \(error)")
                }
            }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap based on type
        if let type = userInfo["type"] as? String {
            handleNotificationTap(type: type, data: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(type: String, data: [String: Any]) {
        switch type {
        case "prediction_reminder":
            if let predictionId = data["predictionId"] as? String {
                // Navigate to prediction
                print("Navigate to prediction: \(predictionId)")
            }
        case "event_reminder":
            if let eventId = data["eventId"] as? String {
                // Navigate to event
                print("Navigate to event: \(eventId)")
            }
        case "news_alert":
            if let articleId = data["articleId"] as? String {
                // Navigate to article
                print("Navigate to article: \(articleId)")
            }
        case "award_created":
            if let awardId = data["awardId"] as? String {
                // Navigate to award
                print("Navigate to award: \(awardId)")
            }
        case "merch_alert":
            if let itemId = data["itemId"] as? String {
                // Navigate to merch item
                print("Navigate to merch item: \(itemId)")
            }
        default:
            break
        }
    }
}

// MARK: - MessagingDelegate
extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        DispatchQueue.main.async {
            self.fcmToken = fcmToken
        }
        
        if let token = fcmToken {
            print("Firebase registration token: \(token)")
            // Send token to server
            sendTokenToServer(token)
        }
    }
    
    private func sendTokenToServer(_ token: String) {
        // TODO: Send token to your server
        // This would typically involve making an API call to your backend
        // to associate the FCM token with the user's account
    }
}

// MARK: - Extensions
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
