import Foundation
// import FirebaseFirestore
import Combine

class MerchService: ObservableObject {
    static let shared = MerchService()
    
    @Published var merchItems: [MerchItem] = []
    @Published var leaderboard: [MerchLeaderboardEntry] = []
    @Published var trendingItems: [TrendingItem] = []
    @Published var userReports: [UserReport] = []
    @Published var priceAlerts: [PriceAlert] = []
    @Published var stores: [Store] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadStores()
        loadMerchItems()
        loadUserReports()
        loadPriceAlerts()
        setupRealtimeUpdates()
    }
    
    // MARK: - Data Loading
    private func loadStores() {
        // TODO: Load from Firestore
        stores = [
            Store(name: "WWE Shop", website: "https://shop.wwe.com", isPartner: true, commissionRate: 0.05, regions: ["US", "CA", "UK", "AU"], categories: [.tshirt, .hoodie, .hat, .poster, .actionFigure, .championship, .accessory]),
            Store(name: "ProWrestlingTees", website: "https://prowrestlingtees.com", isPartner: true, commissionRate: 0.08, regions: ["US", "CA", "UK"], categories: [.tshirt, .hoodie, .hat, .poster, .accessory]),
            Store(name: "AEW Shop", website: "https://shop.aewrestling.com", isPartner: true, commissionRate: 0.05, regions: ["US", "CA", "UK"], categories: [.tshirt, .hoodie, .hat, .poster, .actionFigure, .accessory]),
            Store(name: "NJPW Shop", website: "https://shop.njpw1972.com", isPartner: true, commissionRate: 0.05, regions: ["US", "JP", "UK"], categories: [.tshirt, .hoodie, .hat, .poster, .actionFigure, .accessory]),
            Store(name: "Amazon", website: "https://amazon.com", isPartner: false, commissionRate: 0.03, regions: ["US", "CA", "UK", "AU", "DE", "FR"], categories: [.tshirt, .hoodie, .hat, .poster, .actionFigure, .accessory, .collectible])
        ]
    }
    
    private func loadMerchItems() {
        isLoading = true
        
        // TODO: Load from Firestore
        let mockItems = [
            MerchItem(
                name: "Roman Reigns 'Head of the Table' T-Shirt",
                description: "Official WWE t-shirt featuring Roman Reigns",
                brand: "WWE",
                category: .tshirt,
                wrestler: "Roman Reigns",
                promotion: "WWE",
                imageURLs: ["https://example.com/roman-tshirt.jpg"],
                currentPrice: 29.99,
                originalPrice: 34.99,
                currency: "USD",
                availability: .inStock,
                regions: ["US", "CA", "UK"],
                tags: ["Roman Reigns", "WWE", "T-Shirt", "Head of the Table"],
                affiliateLinks: [
                    AffiliateLink(storeName: "WWE Shop", url: "https://shop.wwe.com/roman-reigns-tshirt", price: 29.99, commissionRate: 0.05),
                    AffiliateLink(storeName: "Amazon", url: "https://amazon.com/roman-reigns-tshirt", price: 32.99, commissionRate: 0.03)
                ],
                popularity: PopularityMetrics(score: 85.5, rank: 1, views: 1250, likes: 89, shares: 23, reports: 15, searchCount: 340, socialMentions: 67, velocity: 12.5, trend: .rising)
            ),
            MerchItem(
                name: "Cody Rhodes 'American Nightmare' Hoodie",
                description: "AEW hoodie featuring Cody Rhodes",
                brand: "AEW",
                category: .hoodie,
                wrestler: "Cody Rhodes",
                promotion: "AEW",
                imageURLs: ["https://example.com/cody-hoodie.jpg"],
                currentPrice: 59.99,
                currency: "USD",
                availability: .inStock,
                regions: ["US", "CA", "UK"],
                tags: ["Cody Rhodes", "AEW", "Hoodie", "American Nightmare"],
                affiliateLinks: [
                    AffiliateLink(storeName: "AEW Shop", url: "https://shop.aewrestling.com/cody-hoodie", price: 59.99, commissionRate: 0.05)
                ],
                popularity: PopularityMetrics(score: 78.2, rank: 2, views: 980, likes: 67, shares: 18, reports: 12, searchCount: 280, socialMentions: 45, velocity: 9.8, trend: .stable)
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.merchItems = mockItems
            self.isLoading = false
            self.updateLeaderboard()
            self.updateTrendingItems()
        }
    }
    
    private func loadUserReports() {
        // TODO: Load from Firestore
        userReports = []
    }
    
    private func loadPriceAlerts() {
        // TODO: Load from Firestore
        priceAlerts = []
    }
    
    private func setupRealtimeUpdates() {
        // TODO: Set up real-time listeners for Firestore
    }
    
    // MARK: - Merch Item Management
    func fetchMerchItems(completion: @escaping (Result<[MerchItem], Error>) -> Void) {
        db.collection("merch_items")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let items = documents.compactMap { try? $0.data(as: MerchItem.self) }
                completion(.success(items))
            }
    }
    
    func fetchMerchItem(id: String, completion: @escaping (Result<MerchItem?, Error>) -> Void) {
        db.collection("merch_items")
            .document(id)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot, document.exists else {
                    completion(.success(nil))
                    return
                }
                
                let item = try? document.data(as: MerchItem.self)
                completion(.success(item))
            }
    }
    
    func searchMerchItems(query: String, category: MerchCategory?, promotion: String?, completion: @escaping (Result<[MerchItem], Error>) -> Void) {
        var queryRef = db.collection("merch_items")
        
        if let category = category {
            queryRef = queryRef.whereField("category", isEqualTo: category.rawValue)
        }
        
        if let promotion = promotion {
            queryRef = queryRef.whereField("promotion", isEqualTo: promotion)
        }
        
        queryRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let items = documents.compactMap { try? $0.data(as: MerchItem.self) }
            let filteredItems = items.filter { item in
                query.isEmpty || item.name.localizedCaseInsensitiveContains(query) ||
                item.wrestler.localizedCaseInsensitiveContains(query) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
            
            completion(.success(filteredItems))
        }
    }
    
    // MARK: - User Reports
    func submitReport(_ report: UserReport, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("user_reports").addDocument(from: report) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    self.updateItemFromReport(report)
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchUserReports(userId: String, completion: @escaping (Result<[UserReport], Error>) -> Void) {
        db.collection("user_reports")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let reports = documents.compactMap { try? $0.data(as: UserReport.self) }
                completion(.success(reports))
            }
    }
    
    private func updateItemFromReport(_ report: UserReport) {
        guard let itemIndex = merchItems.firstIndex(where: { $0.id == report.itemId }) else { return }
        
        var item = merchItems[itemIndex]
        
        // Update price if provided
        if let price = report.price {
            let pricePoint = PricePoint(
                price: price,
                currency: report.currency,
                store: report.store,
                availability: report.availability,
                source: .userReport
            )
            
            var updatedPriceHistory = item.priceHistory
            updatedPriceHistory.append(pricePoint)
            updatedPriceHistory.sort { $0.date > $1.date }
            
            // Update current price if this is the lowest price
            if price < item.currentPrice {
                item = MerchItem(
                    name: item.name,
                    description: item.description,
                    brand: item.brand,
                    category: item.category,
                    wrestler: item.wrestler,
                    promotion: item.promotion,
                    imageURLs: item.imageURLs,
                    currentPrice: price,
                    originalPrice: item.originalPrice,
                    currency: report.currency,
                    availability: report.availability,
                    regions: item.regions,
                    tags: item.tags,
                    affiliateLinks: item.affiliateLinks,
                    popularity: item.popularity,
                    priceHistory: updatedPriceHistory,
                    socialSentiment: item.socialSentiment
                )
            }
        }
        
        // Update availability
        if report.availability != item.availability {
            item = MerchItem(
                name: item.name,
                description: item.description,
                brand: item.brand,
                category: item.category,
                wrestler: item.wrestler,
                promotion: item.promotion,
                imageURLs: item.imageURLs,
                currentPrice: item.currentPrice,
                originalPrice: item.originalPrice,
                currency: item.currency,
                availability: report.availability,
                regions: item.regions,
                tags: item.tags,
                affiliateLinks: item.affiliateLinks,
                popularity: item.popularity,
                priceHistory: item.priceHistory,
                socialSentiment: item.socialSentiment
            )
        }
        
        merchItems[itemIndex] = item
        updateLeaderboard()
        updateTrendingItems()
    }
    
    // MARK: - Price Alerts
    func createPriceAlert(_ alert: PriceAlert, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("price_alerts").addDocument(from: alert) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    self.priceAlerts.append(alert)
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchPriceAlerts(userId: String, completion: @escaping (Result<[PriceAlert], Error>) -> Void) {
        db.collection("price_alerts")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let alerts = documents.compactMap { try? $0.data(as: PriceAlert.self) }
                completion(.success(alerts))
            }
    }
    
    func checkPriceAlerts() {
        for alert in priceAlerts {
            guard let item = merchItems.first(where: { $0.id == alert.itemId }) else { continue }
            
            let shouldTrigger = switch alert.alertType {
            case .priceDrop:
                item.currentPrice <= alert.targetPrice
            case .priceRise:
                item.currentPrice >= alert.targetPrice
            case .restock:
                item.availability == .inStock
            case .newItem:
                item.availability == .preOrder
            case .sale:
                item.isOnSale
            }
            
            if shouldTrigger && alert.triggeredAt == nil {
                triggerPriceAlert(alert)
            }
        }
    }
    
    private func triggerPriceAlert(_ alert: PriceAlert) {
        // TODO: Send push notification
        print("Price alert triggered for item: \(alert.itemId)")
        
        // Update alert as triggered
        if let index = priceAlerts.firstIndex(where: { $0.id == alert.id }) {
            priceAlerts[index] = PriceAlert(
                userId: alert.userId,
                itemId: alert.itemId,
                targetPrice: alert.targetPrice,
                currency: alert.currency,
                alertType: alert.alertType,
                isActive: false,
                triggeredAt: Date()
            )
        }
    }
    
    // MARK: - Leaderboard
    func updateLeaderboard() {
        let sortedItems = merchItems.sorted { $0.popularity.calculatedScore > $1.popularity.calculatedScore }
        
        leaderboard = sortedItems.enumerated().map { index, item in
            MerchLeaderboardEntry(
                itemId: item.id ?? "",
                itemName: item.name,
                wrestler: item.wrestler,
                promotion: item.promotion,
                category: item.category,
                currentPrice: item.currentPrice,
                popularityScore: item.popularity.calculatedScore,
                rank: index + 1,
                trend: item.popularity.trend,
                velocity: item.popularity.velocity,
                imageURL: item.imageURLs.first
            )
        }
    }
    
    func fetchLeaderboard(category: MerchCategory?, promotion: String?, limit: Int = 50, completion: @escaping (Result<[MerchLeaderboardEntry], Error>) -> Void) {
        var filteredItems = merchItems
        
        if let category = category {
            filteredItems = filteredItems.filter { $0.category == category }
        }
        
        if let promotion = promotion {
            filteredItems = filteredItems.filter { $0.promotion == promotion }
        }
        
        let sortedItems = filteredItems.sorted { $0.popularity.calculatedScore > $1.popularity.calculatedScore }
        let limitedItems = Array(sortedItems.prefix(limit))
        
        let entries = limitedItems.enumerated().map { index, item in
            MerchLeaderboardEntry(
                itemId: item.id ?? "",
                itemName: item.name,
                wrestler: item.wrestler,
                promotion: item.promotion,
                category: item.category,
                currentPrice: item.currentPrice,
                popularityScore: item.popularity.calculatedScore,
                rank: index + 1,
                trend: item.popularity.trend,
                velocity: item.popularity.velocity,
                imageURL: item.imageURLs.first
            )
        }
        
        completion(.success(entries))
    }
    
    // MARK: - Trending Items
    func updateTrendingItems() {
        let sortedItems = merchItems.sorted { $0.popularity.velocity > $1.popularity.velocity }
        
        trendingItems = sortedItems.prefix(20).map { item in
            TrendingItem(
                itemId: item.id ?? "",
                itemName: item.name,
                wrestler: item.wrestler,
                promotion: item.promotion,
                category: item.category,
                currentPrice: item.currentPrice,
                trendScore: item.popularity.velocity,
                socialMentions: item.popularity.socialMentions,
                searchCount: item.popularity.searchCount,
                velocity: item.popularity.velocity,
                imageURL: item.imageURLs.first,
                hashtags: item.tags
            )
        }
    }
    
    func fetchTrendingItems(completion: @escaping (Result<[TrendingItem], Error>) -> Void) {
        let sortedItems = merchItems.sorted { $0.popularity.velocity > $1.popularity.velocity }
        
        let trending = sortedItems.prefix(20).map { item in
            TrendingItem(
                itemId: item.id ?? "",
                itemName: item.name,
                wrestler: item.wrestler,
                promotion: item.promotion,
                category: item.category,
                currentPrice: item.currentPrice,
                trendScore: item.popularity.velocity,
                socialMentions: item.popularity.socialMentions,
                searchCount: item.popularity.searchCount,
                velocity: item.popularity.velocity,
                imageURL: item.imageURLs.first,
                hashtags: item.tags
            )
        }
        
        completion(.success(Array(trending)))
    }
    
    // MARK: - Social Sentiment
    func updateSocialSentiment(for itemId: String) {
        // TODO: Integrate with social media APIs
        // This would fetch data from Twitter, Instagram, Reddit, YouTube APIs
        // and update the social sentiment for the item
    }
    
    // MARK: - Affiliate Links
    func generateAffiliateLink(for item: MerchItem, store: Store) -> String? {
        guard let affiliateLink = item.affiliateLinks.first(where: { $0.storeName == store.name }) else {
            return nil
        }
        
        // Add affiliate tracking parameters
        let trackingParams = [
            "utm_source": "wrestlepick",
            "utm_medium": "app",
            "utm_campaign": "merch_tracking",
            "affiliate_id": "wrestlepick_\(store.id)"
        ]
        
        var urlComponents = URLComponents(string: affiliateLink.url)
        urlComponents?.queryItems = trackingParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        return urlComponents?.url?.absoluteString
    }
    
    // MARK: - Analytics
    func trackItemView(_ itemId: String) {
        guard let index = merchItems.firstIndex(where: { $0.id == itemId }) else { return }
        
        var item = merchItems[index]
        let updatedPopularity = PopularityMetrics(
            score: item.popularity.score,
            rank: item.popularity.rank,
            views: item.popularity.views + 1,
            likes: item.popularity.likes,
            shares: item.popularity.shares,
            reports: item.popularity.reports,
            searchCount: item.popularity.searchCount,
            socialMentions: item.popularity.socialMentions,
            velocity: item.popularity.velocity,
            trend: item.popularity.trend
        )
        
        item = MerchItem(
            name: item.name,
            description: item.description,
            brand: item.brand,
            category: item.category,
            wrestler: item.wrestler,
            promotion: item.promotion,
            imageURLs: item.imageURLs,
            currentPrice: item.currentPrice,
            originalPrice: item.originalPrice,
            currency: item.currency,
            availability: item.availability,
            regions: item.regions,
            tags: item.tags,
            affiliateLinks: item.affiliateLinks,
            popularity: updatedPopularity,
            priceHistory: item.priceHistory,
            socialSentiment: item.socialSentiment
        )
        
        merchItems[index] = item
        updateLeaderboard()
    }
    
    func trackItemLike(_ itemId: String) {
        guard let index = merchItems.firstIndex(where: { $0.id == itemId }) else { return }
        
        var item = merchItems[index]
        let updatedPopularity = PopularityMetrics(
            score: item.popularity.score,
            rank: item.popularity.rank,
            views: item.popularity.views,
            likes: item.popularity.likes + 1,
            shares: item.popularity.shares,
            reports: item.popularity.reports,
            searchCount: item.popularity.searchCount,
            socialMentions: item.popularity.socialMentions,
            velocity: item.popularity.velocity,
            trend: item.popularity.trend
        )
        
        item = MerchItem(
            name: item.name,
            description: item.description,
            brand: item.brand,
            category: item.category,
            wrestler: item.wrestler,
            promotion: item.promotion,
            imageURLs: item.imageURLs,
            currentPrice: item.currentPrice,
            originalPrice: item.originalPrice,
            currency: item.currency,
            availability: item.availability,
            regions: item.regions,
            tags: item.tags,
            affiliateLinks: item.affiliateLinks,
            popularity: updatedPopularity,
            priceHistory: item.priceHistory,
            socialSentiment: item.socialSentiment
        )
        
        merchItems[index] = item
        updateLeaderboard()
    }
}
