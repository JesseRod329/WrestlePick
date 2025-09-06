import Foundation
import StoreKit
import FirebaseFirestore
import Combine

class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var subscriptionPlans: [SubscriptionPlan] = []
    @Published var currentSubscription: UserSubscription?
    @Published var isSubscribed = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var products: [Product] = []
    
    // StoreKit product identifiers
    private let productIdentifiers = [
        "com.wrestlepick.premium.monthly",
        "com.wrestlepick.premium.yearly",
        "com.wrestlepick.premium.lifetime"
    ]
    
    private override init() {
        super.init()
        setupStoreKit()
        loadSubscriptionPlans()
        loadCurrentSubscription()
    }
    
    // MARK: - StoreKit Setup
    private func setupStoreKit() {
        Task {
            do {
                try await loadProducts()
                await updateSubscriptionStatus()
            } catch {
                print("StoreKit setup error: \(error)")
            }
        }
    }
    
    @MainActor
    private func loadProducts() async throws {
        let products = try await Product.products(for: productIdentifiers)
        self.products = products
    }
    
    // MARK: - Subscription Plans
    func loadSubscriptionPlans() {
        // TODO: Load from Firestore
        subscriptionPlans = [
            SubscriptionPlan(
                id: "monthly",
                name: "Premium Monthly",
                description: "Full access to all premium features",
                price: 2.99,
                duration: .monthly,
                features: [
                    PremiumFeature(name: "Unlimited Predictions", description: "Make unlimited predictions for any event", iconName: "crystal.ball.fill", category: .predictions),
                    PremiumFeature(name: "Advanced Fantasy Booking", description: "Access to all fantasy booking tools", iconName: "figure.wrestling", category: .fantasy),
                    PremiumFeature(name: "Early Access Content", description: "Get exclusive content before everyone else", iconName: "clock.fill", category: .content),
                    PremiumFeature(name: "Ad-Free Experience", description: "Enjoy the app without advertisements", iconName: "eye.slash.fill", category: .content),
                    PremiumFeature(name: "Advanced Analytics", description: "Detailed statistics and insights", iconName: "chart.bar.fill", category: .analytics),
                    PremiumFeature(name: "Custom Categories", description: "Create your own prediction categories", iconName: "tag.fill", category: .predictions),
                    PremiumFeature(name: "Priority Support", description: "Get help faster with priority support", iconName: "headphones", category: .support)
                ],
                productId: "com.wrestlepick.premium.monthly"
            ),
            SubscriptionPlan(
                id: "yearly",
                name: "Premium Yearly",
                description: "Full access with 17% savings",
                price: 29.99,
                duration: .yearly,
                features: [
                    PremiumFeature(name: "Unlimited Predictions", description: "Make unlimited predictions for any event", iconName: "crystal.ball.fill", category: .predictions),
                    PremiumFeature(name: "Advanced Fantasy Booking", description: "Access to all fantasy booking tools", iconName: "figure.wrestling", category: .fantasy),
                    PremiumFeature(name: "Early Access Content", description: "Get exclusive content before everyone else", iconName: "clock.fill", category: .content),
                    PremiumFeature(name: "Ad-Free Experience", description: "Enjoy the app without advertisements", iconName: "eye.slash.fill", category: .content),
                    PremiumFeature(name: "Advanced Analytics", description: "Detailed statistics and insights", iconName: "chart.bar.fill", category: .analytics),
                    PremiumFeature(name: "Custom Categories", description: "Create your own prediction categories", iconName: "tag.fill", category: .predictions),
                    PremiumFeature(name: "Priority Support", description: "Get help faster with priority support", iconName: "headphones", category: .support)
                ],
                isPopular: true,
                productId: "com.wrestlepick.premium.yearly"
            ),
            SubscriptionPlan(
                id: "lifetime",
                name: "Premium Lifetime",
                description: "One-time payment for lifetime access",
                price: 99.99,
                duration: .lifetime,
                features: [
                    PremiumFeature(name: "Unlimited Predictions", description: "Make unlimited predictions for any event", iconName: "crystal.ball.fill", category: .predictions),
                    PremiumFeature(name: "Advanced Fantasy Booking", description: "Access to all fantasy booking tools", iconName: "figure.wrestling", category: .fantasy),
                    PremiumFeature(name: "Early Access Content", description: "Get exclusive content before everyone else", iconName: "clock.fill", category: .content),
                    PremiumFeature(name: "Ad-Free Experience", description: "Enjoy the app without advertisements", iconName: "eye.slash.fill", category: .content),
                    PremiumFeature(name: "Advanced Analytics", description: "Detailed statistics and insights", iconName: "chart.bar.fill", category: .analytics),
                    PremiumFeature(name: "Custom Categories", description: "Create your own prediction categories", iconName: "tag.fill", category: .predictions),
                    PremiumFeature(name: "Priority Support", description: "Get help faster with priority support", iconName: "headphones", category: .support)
                ],
                productId: "com.wrestlepick.premium.lifetime"
            )
        ]
    }
    
    // MARK: - Current Subscription
    func loadCurrentSubscription() {
        // TODO: Load from Firestore
        // For now, simulate no subscription
        currentSubscription = nil
        isSubscribed = false
    }
    
    @MainActor
    func updateSubscriptionStatus() async {
        // Check current subscription status
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    // Handle auto-renewable subscription
                    await handleSubscriptionTransaction(transaction)
                }
            }
        }
    }
    
    // MARK: - Purchase Flow
    func purchaseSubscription(_ plan: SubscriptionPlan) async throws {
        guard let product = products.first(where: { $0.id == plan.productId }) else {
            throw SubscriptionError.productNotFound
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await handleSubscriptionTransaction(transaction)
            }
        case .userCancelled:
            throw SubscriptionError.userCancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    private func handleSubscriptionTransaction(_ transaction: Transaction) async {
        // Update local subscription status
        let subscription = UserSubscription(
            userId: "current_user", // TODO: Get from auth service
            planId: transaction.productID,
            status: .active,
            startDate: transaction.purchaseDate,
            endDate: transaction.expirationDate,
            originalTransactionId: transaction.originalID,
            productId: transaction.productID,
            price: transaction.price
        )
        
        await MainActor.run {
            currentSubscription = subscription
            isSubscribed = true
        }
        
        // Save to Firestore
        await saveSubscription(subscription)
        
        // Track revenue
        await trackRevenue(
            userId: "current_user",
            revenueType: .subscription,
            amount: transaction.price,
            source: "App Store",
            description: "Subscription purchase",
            transactionId: transaction.originalID
        )
        
        // Finish the transaction
        await transaction.finish()
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Cancel Subscription
    func cancelSubscription() async throws {
        // Note: In a real app, you would need to implement server-side cancellation
        // or direct the user to the App Store settings
        throw SubscriptionError.notImplemented
    }
    
    // MARK: - Feature Gating
    func hasFeature(_ feature: PremiumFeature) -> Bool {
        return isSubscribed && feature.isEnabled
    }
    
    func canMakePrediction() -> Bool {
        // TODO: Check usage limits
        return true
    }
    
    func canCreateFantasyBooking() -> Bool {
        return isSubscribed
    }
    
    func canAccessAdvancedAnalytics() -> Bool {
        return isSubscribed
    }
    
    func canCreateCustomCategory() -> Bool {
        return isSubscribed
    }
    
    func canAccessEarlyContent() -> Bool {
        return isSubscribed
    }
    
    func hasAdFreeExperience() -> Bool {
        return isSubscribed
    }
    
    func hasPrioritySupport() -> Bool {
        return isSubscribed
    }
    
    // MARK: - Usage Tracking
    func trackPredictionUsage() {
        // TODO: Track prediction usage for limits
    }
    
    func trackFantasyBookingUsage() {
        // TODO: Track fantasy booking usage for limits
    }
    
    func trackCustomAwardUsage() {
        // TODO: Track custom award usage for limits
    }
    
    func trackLeagueCreationUsage() {
        // TODO: Track league creation usage for limits
    }
    
    // MARK: - Revenue Tracking
    func trackRevenue(userId: String, revenueType: RevenueType, amount: Double, source: String, description: String, transactionId: String? = nil, affiliateId: String? = nil, commissionRate: Double = 0.0) async {
        let revenue = RevenueTracking(
            userId: userId,
            revenueType: revenueType,
            amount: amount,
            source: source,
            description: description,
            transactionId: transactionId,
            affiliateId: affiliateId,
            commissionRate: commissionRate,
            commissionAmount: amount * commissionRate
        )
        
        do {
            try db.collection("revenue_tracking").addDocument(from: revenue)
        } catch {
            print("Error tracking revenue: \(error)")
        }
    }
    
    // MARK: - Affiliate Tracking
    func trackAffiliateClick(_ affiliateLink: AffiliateLink) {
        // TODO: Track affiliate link clicks
    }
    
    func trackAffiliateConversion(_ affiliateLink: AffiliateLink, amount: Double) {
        // TODO: Track affiliate conversions
    }
    
    // MARK: - Sponsored Content
    func loadSponsoredContent() async -> [SponsoredContent] {
        // TODO: Load sponsored content from Firestore
        return []
    }
    
    func trackSponsoredContentImpression(_ content: SponsoredContent) {
        // TODO: Track sponsored content impressions
    }
    
    func trackSponsoredContentClick(_ content: SponsoredContent) {
        // TODO: Track sponsored content clicks
    }
    
    // MARK: - Premium Tournaments
    func loadPremiumTournaments() async -> [PremiumTournament] {
        // TODO: Load premium tournaments from Firestore
        return []
    }
    
    func joinTournament(_ tournament: PremiumTournament) async throws {
        // TODO: Implement tournament joining with payment
    }
    
    // MARK: - Custom League Hosting
    func createCustomLeague(_ hosting: CustomLeagueHosting) async throws {
        // TODO: Implement custom league hosting
    }
    
    // MARK: - Analytics
    func getRevenueAnalytics() async -> RevenueAnalytics {
        // TODO: Load revenue analytics from Firestore
        return RevenueAnalytics(
            totalRevenue: 0.0,
            subscriptionRevenue: 0.0,
            affiliateRevenue: 0.0,
            sponsoredRevenue: 0.0,
            tournamentRevenue: 0.0,
            customLeagueRevenue: 0.0,
            monthlyRevenue: 0.0,
            yearlyRevenue: 0.0
        )
    }
    
    // MARK: - Helper Methods
    private func saveSubscription(_ subscription: UserSubscription) async {
        do {
            try db.collection("user_subscriptions").addDocument(from: subscription)
        } catch {
            print("Error saving subscription: \(error)")
        }
    }
}

// MARK: - Revenue Analytics
struct RevenueAnalytics: Codable {
    let totalRevenue: Double
    let subscriptionRevenue: Double
    let affiliateRevenue: Double
    let sponsoredRevenue: Double
    let tournamentRevenue: Double
    let customLeagueRevenue: Double
    let monthlyRevenue: Double
    let yearlyRevenue: Double
}

// MARK: - Subscription Errors
enum SubscriptionError: Error, LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case unknown
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending"
        case .unknown:
            return "Unknown error occurred"
        case .notImplemented:
            return "Feature not implemented"
        }
    }
}

// MARK: - StoreKit Transaction Listener
extension SubscriptionService {
    func startTransactionListener() {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await handleSubscriptionTransaction(transaction)
                }
            }
        }
    }
}
