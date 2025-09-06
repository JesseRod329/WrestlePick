import SwiftUI

struct SubscriptionManagementView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingPaywall = false
    @State private var showingCancelAlert = false
    @State private var isRestoring = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if subscriptionService.isSubscribed {
                        // Active subscription
                        ActiveSubscriptionView(
                            subscription: subscriptionService.currentSubscription,
                            onCancel: {
                                showingCancelAlert = true
                            }
                        )
                    } else {
                        // No subscription
                        NoSubscriptionView(
                            onUpgrade: {
                                showingPaywall = true
                            }
                        )
                    }
                    
                    // Billing history
                    BillingHistoryView()
                    
                    // Support section
                    SupportSectionView()
                    
                    // Legal section
                    LegalSectionView()
                }
                .padding()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        restorePurchases()
                    }
                    .disabled(isRestoring)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("Cancel Subscription", isPresented: $showingCancelAlert) {
                Button("Cancel", role: .destructive) {
                    cancelSubscription()
                }
                Button("Keep Subscription", role: .cancel) { }
            } message: {
                Text("Are you sure you want to cancel your subscription? You'll lose access to all premium features.")
            }
            .alert("Subscription", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        
        Task {
            do {
                try await subscriptionService.restorePurchases()
                await MainActor.run {
                    isRestoring = false
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func cancelSubscription() {
        // Note: In a real app, you would need to implement server-side cancellation
        // or direct the user to the App Store settings
        alertMessage = "To cancel your subscription, please go to Settings > Apple ID > Subscriptions"
        showingAlert = true
    }
}

// MARK: - Active Subscription View
struct ActiveSubscriptionView: View {
    let subscription: UserSubscription?
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Status header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Premium Active")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("You have full access to all premium features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Subscription details
            if let subscription = subscription {
                VStack(spacing: 12) {
                    DetailRow(
                        title: "Plan",
                        value: subscription.planId.capitalized
                    )
                    
                    DetailRow(
                        title: "Status",
                        value: subscription.status.displayName
                    )
                    
                    DetailRow(
                        title: "Started",
                        value: subscription.startDate.formatted(date: .abbreviated, time: .omitted)
                    )
                    
                    if let endDate = subscription.endDate {
                        DetailRow(
                            title: "Renews",
                            value: endDate.formatted(date: .abbreviated, time: .omitted)
                        )
                    }
                    
                    if subscription.daysRemaining > 0 {
                        DetailRow(
                            title: "Days Remaining",
                            value: "\(subscription.daysRemaining)"
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel Subscription")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - No Subscription View
struct NoSubscriptionView: View {
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Active Subscription")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Upgrade to Premium to unlock all features and get the full WrestlePick experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onUpgrade) {
                Text("Upgrade to Premium")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.wweBlue)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Billing History View
struct BillingHistoryView: View {
    @State private var billingHistory: [BillingItem] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Billing History")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading billing history...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if billingHistory.isEmpty {
                Text("No billing history available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(billingHistory) { item in
                        BillingItemRow(item: item)
                    }
                }
            }
        }
        .onAppear {
            loadBillingHistory()
        }
    }
    
    private func loadBillingHistory() {
        isLoading = true
        // TODO: Load billing history from StoreKit or server
        billingHistory = [
            BillingItem(
                description: "Premium Monthly",
                amount: 2.99,
                currency: "USD",
                date: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                status: .completed
            ),
            BillingItem(
                description: "Premium Monthly",
                amount: 2.99,
                currency: "USD",
                date: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                status: .completed
            )
        ]
        isLoading = false
    }
}

// MARK: - Billing Item
struct BillingItem: Identifiable {
    let id = UUID()
    let description: String
    let amount: Double
    let currency: String
    let date: Date
    let status: BillingStatus
}

// MARK: - Billing Status
enum BillingStatus: String, CaseIterable {
    case completed = "completed"
    case pending = "pending"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .completed: return "Completed"
        case .pending: return "Pending"
        case .failed: return "Failed"
        case .refunded: return "Refunded"
        }
    }
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .pending: return .yellow
        case .failed: return .red
        case .refunded: return .gray
        }
    }
}

// MARK: - Billing Item Row
struct BillingItemRow: View {
    let item: BillingItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.currency) \(String(format: "%.2f", item.amount))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(item.status.displayName)
                    .font(.caption)
                    .foregroundColor(item.status.color)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Support Section View
struct SupportSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SupportRow(
                    title: "Contact Support",
                    description: "Get help with your subscription",
                    iconName: "questionmark.circle",
                    action: {
                        // TODO: Open support
                    }
                )
                
                SupportRow(
                    title: "FAQ",
                    description: "Frequently asked questions",
                    iconName: "doc.text",
                    action: {
                        // TODO: Open FAQ
                    }
                )
                
                SupportRow(
                    title: "Report a Problem",
                    description: "Report billing or technical issues",
                    iconName: "exclamationmark.triangle",
                    action: {
                        // TODO: Open problem reporting
                    }
                )
            }
        }
    }
}

// MARK: - Support Row
struct SupportRow: View {
    let title: String
    let description: String
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.wweBlue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legal Section View
struct LegalSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Legal")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                LegalRow(
                    title: "Terms of Service",
                    action: {
                        // TODO: Open terms
                    }
                )
                
                LegalRow(
                    title: "Privacy Policy",
                    action: {
                        // TODO: Open privacy policy
                    }
                )
                
                LegalRow(
                    title: "Subscription Terms",
                    action: {
                        // TODO: Open subscription terms
                    }
                )
                
                LegalRow(
                    title: "Refund Policy",
                    action: {
                        // TODO: Open refund policy
                    }
                )
            }
        }
    }
}

// MARK: - Legal Row
struct LegalRow: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.wweBlue)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SubscriptionManagementView()
}
