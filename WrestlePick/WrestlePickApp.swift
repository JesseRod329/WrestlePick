import SwiftUI
import Firebase

@main
struct WrestlePickApp: App {
    @StateObject private var firebaseConfig = FirebaseConfig.shared
    
    init() {
        // Firebase will be configured in FirebaseConfig.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseConfig)
        }
    }
}
