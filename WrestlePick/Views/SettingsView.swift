import SwiftUI

struct SettingsView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingDataExport = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section("Profile") {
                    NavigationLink(destination: EditProfileView()) {
                        SettingsRow(
                            icon: "person.circle",
                            title: "Edit Profile",
                            subtitle: "Update your personal information"
                        )
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(
                            icon: "lock.shield",
                            title: "Privacy Settings",
                            subtitle: "Control your data visibility"
                        )
                    }
                }
                
                // Notifications Section
                Section("Notifications") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRow(
                            icon: "bell",
                            title: "Notification Preferences",
                            subtitle: "Manage your alerts and updates"
                        )
                    }
                }
                
                // Data Section
                Section("Data") {
                    Button(action: { showingDataExport = true }) {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Export Data",
                            subtitle: "Download your data"
                        )
                    }
                    .foregroundColor(.primary)
                    
                    NavigationLink(destination: DataManagementView()) {
                        SettingsRow(
                            icon: "externaldrive",
                            title: "Data Management",
                            subtitle: "Storage and sync settings"
                        )
                    }
                }
                
                // App Section
                Section("App") {
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(
                            icon: "info.circle",
                            title: "About",
                            subtitle: "Version and app information"
                        )
                    }
                    
                    NavigationLink(destination: SupportView()) {
                        SettingsRow(
                            icon: "questionmark.circle",
                            title: "Support",
                            subtitle: "Help and contact"
                        )
                    }
                }
                
                // Account Section
                Section("Account") {
                    Button(action: { showingSignOutAlert = true }) {
                        SettingsRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Sign Out",
                            subtitle: "Sign out of your account"
                        )
                    }
                    .foregroundColor(.orange)
                    
                    if !authService.isGuest {
                        Button(action: { showingDeleteAccountAlert = true }) {
                            SettingsRow(
                                icon: "trash",
                                title: "Delete Account",
                                subtitle: "Permanently delete your account"
                            )
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement account deletion
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.wweBlue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var privacySettings: PrivacySettings
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init() {
        _privacySettings = State(initialValue: PrivacySettings())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Visibility") {
                    Toggle("Public Profile", isOn: $privacySettings.isPublic)
                        .onChange(of: privacySettings.isPublic) { _ in
                            saveSettings()
                        }
                    
                    Text("When enabled, other users can view your profile and predictions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Prediction Visibility") {
                    Toggle("Show Predictions", isOn: $privacySettings.showPredictions)
                        .onChange(of: privacySettings.showPredictions) { _ in
                            saveSettings()
                        }
                    
                    Toggle("Show Statistics", isOn: $privacySettings.showStats)
                        .onChange(of: privacySettings.showStats) { _ in
                            saveSettings()
                        }
                    
                    Toggle("Show Activity", isOn: $privacySettings.showActivity)
                        .onChange(of: privacySettings.showActivity) { _ in
                            saveSettings()
                        }
                }
                
                Section("Social Features") {
                    Toggle("Allow Messages", isOn: $privacySettings.allowMessages)
                        .onChange(of: privacySettings.allowMessages) { _ in
                            saveSettings()
                        }
                    
                    Toggle("Data Sharing", isOn: $privacySettings.dataSharing)
                        .onChange(of: privacySettings.dataSharing) { _ in
                            saveSettings()
                        }
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Privacy Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCurrentSettings() {
        privacySettings = authService.currentUser?.preferences.privacySettings ?? PrivacySettings()
    }
    
    private func saveSettings() {
        isLoading = true
        
        authService.updatePrivacySettings(privacySettings) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    alertMessage = "Privacy settings updated successfully!"
                    showingAlert = true
                case .failure(let error):
                    alertMessage = "Failed to update privacy settings: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var notificationSettings: NotificationSettings
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init() {
        _notificationSettings = State(initialValue: NotificationSettings())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Push Notifications") {
                    Toggle("Enable Push Notifications", isOn: $notificationSettings.pushNotifications)
                        .onChange(of: notificationSettings.pushNotifications) { _ in
                            saveSettings()
                        }
                    
                    Toggle("Email Notifications", isOn: $notificationSettings.emailNotifications)
                        .onChange(of: notificationSettings.emailNotifications) { _ in
                            saveSettings()
                        }
                }
                
                Section("Content Notifications") {
                    Toggle("Prediction Reminders", isOn: $notificationSettings.predictionReminders)
                        .onChange(of: notificationSettings.predictionReminders) { _ in
                            saveSettings()
                        }
                    
                    Toggle("News Alerts", isOn: $notificationSettings.newsAlerts)
                        .onChange(of: notificationSettings.newsAlerts) { _ in
                            saveSettings()
                        }
                    
                    Toggle("Social Updates", isOn: $notificationSettings.socialUpdates)
                        .onChange(of: notificationSettings.socialUpdates) { _ in
                            saveSettings()
                        }
                    
                    Toggle("Weekly Digest", isOn: $notificationSettings.weeklyDigest)
                        .onChange(of: notificationSettings.weeklyDigest) { _ in
                            saveSettings()
                        }
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Notification Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCurrentSettings() {
        notificationSettings = authService.currentUser?.preferences.notificationSettings ?? NotificationSettings()
    }
    
    private func saveSettings() {
        isLoading = true
        
        authService.updateNotificationPreferences(notificationSettings) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    alertMessage = "Notification settings updated successfully!"
                    showingAlert = true
                case .failure(let error):
                    alertMessage = "Failed to update notification settings: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Data Management View
struct DataManagementView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Storage") {
                    HStack {
                        Text("Local Storage")
                        Spacer()
                        Text("2.3 MB")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Cached Images")
                        Spacer()
                        Text("15.7 MB")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Sync") {
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text("2 minutes ago")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sync Status")
                        Spacer()
                        Text("Up to date")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Actions") {
                    Button("Clear Cache") {
                        // TODO: Implement cache clearing
                    }
                    .foregroundColor(.orange)
                    
                    Button("Force Sync") {
                        // TODO: Implement force sync
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        NavigationView {
            List {
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Legal") {
                    Button("Terms of Service") {
                        // TODO: Open terms of service
                    }
                    .foregroundColor(.primary)
                    
                    Button("Privacy Policy") {
                        // TODO: Open privacy policy
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Support View
struct SupportView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Get Help") {
                    Button("FAQ") {
                        // TODO: Open FAQ
                    }
                    .foregroundColor(.primary)
                    
                    Button("Contact Support") {
                        // TODO: Open contact form
                    }
                    .foregroundColor(.primary)
                    
                    Button("Report Bug") {
                        // TODO: Open bug report form
                    }
                    .foregroundColor(.primary)
                }
                
                Section("Community") {
                    Button("Discord Server") {
                        // TODO: Open Discord
                    }
                    .foregroundColor(.primary)
                    
                    Button("Twitter") {
                        // TODO: Open Twitter
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
