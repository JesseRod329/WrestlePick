import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging
import UserNotifications

class FirebaseConfig: ObservableObject {
    static let shared = FirebaseConfig()
    
    @Published var isConfigured = false
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private init() {
        configureFirebase()
    }
    
    private func configureFirebase() {
        // Check if Firebase is already configured
        guard FirebaseApp.app() == nil else {
            self.isConfigured = true
            return
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        self.isConfigured = true
        
        // Set up authentication state listener
        setupAuthStateListener()
        
        // Configure Firestore settings
        configureFirestore()
        
        // Set up push notifications
        setupPushNotifications()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
            }
        }
    }
    
    private func configureFirestore() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
    }
    
    private func setupPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Request notification permissions
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension FirebaseConfig: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension FirebaseConfig: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        // Send token to server if needed
        if let token = fcmToken {
            sendTokenToServer(token)
        }
    }
    
    private func sendTokenToServer(_ token: String) {
        // TODO: Send token to your server
        // This would typically involve making an API call to your backend
        // to associate the FCM token with the user's account
    }
}
