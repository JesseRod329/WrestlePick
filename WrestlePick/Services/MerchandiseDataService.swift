import Foundation
import Combine
import os.log

class MerchandiseDataService: ObservableObject {
    static let shared = MerchandiseDataService()
    
    @Published var merchandise: [MerchandiseItem] = []
    @Published var trendingItems: [MerchandiseItem] = []
    @Published var priceAlerts: [PriceAlert] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var error: Error?
    
    private let logger = Logger(subsystem: "com.wrestlepick", category: "MerchandiseData")
    private var cancellables = Set<AnyCancellable>()
    private let cache = MerchandiseCache.shared
    private var refreshTimer: Timer?
    
    // Merchandise data sources
    private let merchSources: [MerchandiseDataSource] = [
        MerchandiseDataSource(
            name: "WWE Shop",
            baseURL: "https://shop.wwe.com",
            promotion: .wwe,
            reliability: .tier1,
            apiKey: "wwe_shop_api_key"
        ),
        MerchandiseDataSource(
            name: "AEW Shop",
            baseURL: "https://shop.allelitewrestling.com",
            promotion: .aew,
            reliability: .tier1,
            apiKey: "aew_shop_api_key"
        ),
        MerchandiseDataSource(
            name: "Pro Wrestling Tees",
            baseURL: "https://www.prowrestlingtees.com",
            promotion: .indie,
            reliability: .tier2,
            apiKey: "pwt_api_key"
        ),
        MerchandiseDataSource(
            name: "Hot Topic",
            baseURL: "https://www.hottopic.com",
            promotion: .wwe,
            reliability: .tier2,
            apiKey: "hottopic_api_key"
        ),
        MerchandiseDataSource(
            name: "BoxLunch",
            baseURL: "https://www.boxlunch.com",
            promotion: .wwe,
            reliability: .tier2,
            apiKey: "boxlunch_api_key"
        )
    ]
    
    private init() {
        loadCachedMerchandise()
        startPeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func refreshMerchandiseData() {
        isLoading = true
        error = nil
        
        let group = DispatchGroup()
        var allMerchandise: [MerchandiseItem] = []
        let queue = DispatchQueue(label: "merchandise.data", qos: .utility)
        
        for source in merchSources {
            group.enter()
            
            queue.async {
                self.fetchMerchandiseFromSource(source) { result in
                    switch result {
                    case .success(let items):
                        allMerchandise.append(contentsOf: items)
                    case .failure(let error):
                        self.logger.error("Failed to fetch merchandise from \(source.name): \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.processMerchandise(allMerchandise)
            self.isLoading = false
            self.lastUpdateTime = Date()
        }
    }
    
    func getMerchandise(by category: MerchandiseCategory) -> [MerchandiseItem] {
        return merchandise.filter { $0.category == category }
    }
    
    func getMerchandise(by wrestler: String) -> [MerchandiseItem] {
        let lowercaseWrestler = wrestler.lowercased()
        return merchandise.filter { item in
            item.wrestler?.name.lowercased().contains(lowercaseWrestler) == true ||
            item.wrestler?.ringName.lowercased().contains(lowercaseWrestler) == true
        }
    }
    
    func getMerchandise(by promotion: WrestlingPromotion) -> [MerchandiseItem] {
        return merchandise.filter { $0.promotion == promotion }
    }
    
    func searchMerchandise(query: String) -> [MerchandiseItem] {
        let lowercaseQuery = query.lowercased()
        return merchandise.filter { item in
            item.name.lowercased().contains(lowercaseQuery) ||
            item.description.lowercased().contains(lowercaseQuery) ||
            item.wrestler?.name.lowercased().contains(lowercaseQuery) == true
        }
    }
    
    func getTrendingItems() -> [MerchandiseItem] {
        return trendingItems.sorted { $0.popularityScore > $1.popularityScore }
    }
    
    func createPriceAlert(for item: MerchandiseItem, targetPrice: Double) {
        let alert = PriceAlert(
            id: UUID().uuidString,
            item: item,
            targetPrice: targetPrice,
            currentPrice: item.currentPrice.amount,
            isActive: true,
            createdDate: Date()
        )
        
        priceAlerts.append(alert)
        savePriceAlerts()
    }
    
    func removePriceAlert(_ alert: PriceAlert) {
        priceAlerts.removeAll { $0.id == alert.id }
        savePriceAlerts()
    }
    
    // MARK: - Private Methods
    private func fetchMerchandiseFromSource(_ source: MerchandiseDataSource, completion: @escaping (Result<[MerchandiseItem], Error>) -> Void) {
        // In a real implementation, this would make HTTP requests to the data sources
        // For now, we'll use mock data that represents real merchandise
        
        let mockMerchandise = generateMockMerchandiseForSource(source)
        completion(.success(mockMerchandise))
    }
    
    private func generateMockMerchandiseForSource(_ source: MerchandiseDataSource) -> [MerchandiseItem] {
        switch source.promotion {
        case .wwe:
            return generateWWEMerchandise()
        case .aew:
            return generateAEWMerchandise()
        case .njpw:
            return generateNJPWMerchandise()
        case .impact:
            return generateImpactMerchandise()
        case .roh:
            return generateROHMerchandise()
        case .indie:
            return generateIndieMerchandise()
        }
    }
    
    private func generateWWEMerchandise() -> [MerchandiseItem] {
        return [
            MerchandiseItem(
                id: "wwe-merch-1",
                name: "Roman Reigns 'The Tribal Chief' T-Shirt",
                category: .tShirt,
                wrestler: Wrestler(
                    id: "wwe-1",
                    name: "Roman Reigns",
                    realName: "Leati Joseph Anoa'i",
                    ringName: "Roman Reigns",
                    promotions: [.wwe],
                    hometown: "Pensacola, Florida",
                    height: "6'3\"",
                    weight: "265 lbs",
                    debut: Date(),
                    championships: [],
                    photoURL: nil,
                    socialMedia: SocialMediaLinks(twitter: nil, instagram: nil, youtube: nil),
                    isActive: true,
                    currentPromotion: .wwe,
                    status: .active,
                    specialties: [],
                    signatureMoves: [],
                    achievements: [],
                    biography: "",
                    statistics: WrestlerStatistics(
                        totalMatches: 0,
                        wins: 0,
                        losses: 0,
                        winPercentage: 0,
                        averageMatchLength: 0,
                        championshipReigns: 0
                    )
                ),
                promotion: .wwe,
                retailer: Retailer(
                    name: "WWE Shop",
                    url: "https://shop.wwe.com",
                    logoURL: "https://shop.wwe.com/logo.png",
                    rating: 4.8,
                    shippingInfo: "Free shipping on orders over $50"
                ),
                currentPrice: Price(
                    amount: 29.99,
                    currency: "USD",
                    originalAmount: 34.99,
                    discountPercentage: 14.3
                ),
                priceHistory: [
                    PricePoint(amount: 34.99, date: Date(timeIntervalSinceNow: -30 * 24 * 60 * 60)),
                    PricePoint(amount: 29.99, date: Date())
                ],
                availability: AvailabilityStatus(
                    status: .inStock,
                    quantity: 150,
                    restockDate: nil
                ),
                imageURLs: [
                    "https://shop.wwe.com/images/roman-reigns-tribal-chief-tshirt-1.jpg",
                    "https://shop.wwe.com/images/roman-reigns-tribal-chief-tshirt-2.jpg"
                ],
                popularityScore: 8.5,
                affiliateURL: "https://shop.wwe.com/roman-reigns-tribal-chief-tshirt",
                description: "Show your support for The Tribal Chief with this official Roman Reigns T-shirt featuring his iconic catchphrase.",
                sizes: ["S", "M", "L", "XL", "XXL"],
                colors: ["Black", "White", "Red"],
                materials: ["100% Cotton"],
                careInstructions: "Machine wash cold, tumble dry low",
                shippingWeight: 0.5,
                dimensions: "12 x 16 inches",
                sku: "WWE-RR-TRIBAL-CHIEF-TS",
                upc: "123456789012",
                releaseDate: Date(timeIntervalSinceNow: -60 * 24 * 60 * 60),
                isLimitedEdition: false,
                isExclusive: false,
                tags: ["Roman Reigns", "The Tribal Chief", "WWE", "T-Shirt", "Official"],
                reviews: [
                    ProductReview(
                        id: "review-1",
                        user: "WrestlingFan123",
                        rating: 5,
                        title: "Great quality!",
                        content: "Love this shirt, great quality and fits perfectly.",
                        date: Date(timeIntervalSinceNow: -7 * 24 * 60 * 60),
                        verified: true
                    )
                ],
                averageRating: 4.7,
                totalReviews: 127,
                returnPolicy: "30-day return policy",
                warranty: "1-year manufacturer warranty"
            ),
            MerchandiseItem(
                id: "wwe-merch-2",
                name: "Seth Rollins 'The Visionary' Hoodie",
                category: .hoodie,
                wrestler: Wrestler(
                    id: "wwe-2",
                    name: "Seth Rollins",
                    realName: "Colby Lopez",
                    ringName: "Seth Rollins",
                    promotions: [.wwe],
                    hometown: "Davenport, Iowa",
                    height: "6'1\"",
                    weight: "205 lbs",
                    debut: Date(),
                    championships: [],
                    photoURL: nil,
                    socialMedia: SocialMediaLinks(twitter: nil, instagram: nil, youtube: nil),
                    isActive: true,
                    currentPromotion: .wwe,
                    status: .active,
                    specialties: [],
                    signatureMoves: [],
                    achievements: [],
                    biography: "",
                    statistics: WrestlerStatistics(
                        totalMatches: 0,
                        wins: 0,
                        losses: 0,
                        winPercentage: 0,
                        averageMatchLength: 0,
                        championshipReigns: 0
                    )
                ),
                promotion: .wwe,
                retailer: Retailer(
                    name: "WWE Shop",
                    url: "https://shop.wwe.com",
                    logoURL: "https://shop.wwe.com/logo.png",
                    rating: 4.8,
                    shippingInfo: "Free shipping on orders over $50"
                ),
                currentPrice: Price(
                    amount: 59.99,
                    currency: "USD",
                    originalAmount: 69.99,
                    discountPercentage: 14.3
                ),
                priceHistory: [
                    PricePoint(amount: 69.99, date: Date(timeIntervalSinceNow: -30 * 24 * 60 * 60)),
                    PricePoint(amount: 59.99, date: Date())
                ],
                availability: AvailabilityStatus(
                    status: .inStock,
                    quantity: 75,
                    restockDate: nil
                ),
                imageURLs: [
                    "https://shop.wwe.com/images/seth-rollins-visionary-hoodie-1.jpg",
                    "https://shop.wwe.com/images/seth-rollins-visionary-hoodie-2.jpg"
                ],
                popularityScore: 7.8,
                affiliateURL: "https://shop.wwe.com/seth-rollins-visionary-hoodie",
                description: "Stay warm and stylish with this official Seth Rollins hoodie featuring his Visionary design.",
                sizes: ["S", "M", "L", "XL", "XXL"],
                colors: ["Black", "Gray", "Navy"],
                materials: ["80% Cotton", "20% Polyester"],
                careInstructions: "Machine wash cold, tumble dry low",
                shippingWeight: 1.2,
                dimensions: "14 x 18 inches",
                sku: "WWE-SR-VISIONARY-HOODIE",
                upc: "123456789013",
                releaseDate: Date(timeIntervalSinceNow: -45 * 24 * 60 * 60),
                isLimitedEdition: false,
                isExclusive: false,
                tags: ["Seth Rollins", "The Visionary", "WWE", "Hoodie", "Official"],
                reviews: [],
                averageRating: 4.5,
                totalReviews: 89,
                returnPolicy: "30-day return policy",
                warranty: "1-year manufacturer warranty"
            )
        ]
    }
    
    private func generateAEWMerchandise() -> [MerchandiseItem] {
        return [
            MerchandiseItem(
                id: "aew-merch-1",
                name: "Jon Moxley 'Death Rider' T-Shirt",
                category: .tShirt,
                wrestler: Wrestler(
                    id: "aew-1",
                    name: "Jon Moxley",
                    realName: "Jonathan Good",
                    ringName: "Jon Moxley",
                    promotions: [.aew],
                    hometown: "Cincinnati, Ohio",
                    height: "6'1\"",
                    weight: "225 lbs",
                    debut: Date(),
                    championships: [],
                    photoURL: nil,
                    socialMedia: SocialMediaLinks(twitter: nil, instagram: nil, youtube: nil),
                    isActive: true,
                    currentPromotion: .aew,
                    status: .active,
                    specialties: [],
                    signatureMoves: [],
                    achievements: [],
                    biography: "",
                    statistics: WrestlerStatistics(
                        totalMatches: 0,
                        wins: 0,
                        losses: 0,
                        winPercentage: 0,
                        averageMatchLength: 0,
                        championshipReigns: 0
                    )
                ),
                promotion: .aew,
                retailer: Retailer(
                    name: "AEW Shop",
                    url: "https://shop.allelitewrestling.com",
                    logoURL: "https://shop.allelitewrestling.com/logo.png",
                    rating: 4.6,
                    shippingInfo: "Free shipping on orders over $40"
                ),
                currentPrice: Price(
                    amount: 27.99,
                    currency: "USD",
                    originalAmount: 32.99,
                    discountPercentage: 15.2
                ),
                priceHistory: [
                    PricePoint(amount: 32.99, date: Date(timeIntervalSinceNow: -30 * 24 * 60 * 60)),
                    PricePoint(amount: 27.99, date: Date())
                ],
                availability: AvailabilityStatus(
                    status: .inStock,
                    quantity: 200,
                    restockDate: nil
                ),
                imageURLs: [
                    "https://shop.allelitewrestling.com/images/jon-moxley-death-rider-tshirt-1.jpg",
                    "https://shop.allelitewrestling.com/images/jon-moxley-death-rider-tshirt-2.jpg"
                ],
                popularityScore: 9.2,
                affiliateURL: "https://shop.allelitewrestling.com/jon-moxley-death-rider-tshirt",
                description: "Represent the Death Rider with this official Jon Moxley T-shirt featuring his iconic design.",
                sizes: ["S", "M", "L", "XL", "XXL"],
                colors: ["Black", "White", "Red"],
                materials: ["100% Cotton"],
                careInstructions: "Machine wash cold, tumble dry low",
                shippingWeight: 0.5,
                dimensions: "12 x 16 inches",
                sku: "AEW-JM-DEATH-RIDER-TS",
                upc: "123456789014",
                releaseDate: Date(timeIntervalSinceNow: -30 * 24 * 60 * 60),
                isLimitedEdition: false,
                isExclusive: false,
                tags: ["Jon Moxley", "Death Rider", "AEW", "T-Shirt", "Official"],
                reviews: [],
                averageRating: 4.8,
                totalReviews: 156,
                returnPolicy: "30-day return policy",
                warranty: "1-year manufacturer warranty"
            )
        ]
    }
    
    private func generateNJPWMerchandise() -> [MerchandiseItem] {
        return [
            MerchandiseItem(
                id: "njpw-merch-1",
                name: "Kazuchika Okada 'Rainmaker' T-Shirt",
                category: .tShirt,
                wrestler: Wrestler(
                    id: "njpw-1",
                    name: "Kazuchika Okada",
                    realName: "Kazuchika Okada",
                    ringName: "Kazuchika Okada",
                    promotions: [.njpw],
                    hometown: "Anjo, Aichi, Japan",
                    height: "6'3\"",
                    weight: "230 lbs",
                    debut: Date(),
                    championships: [],
                    photoURL: nil,
                    socialMedia: SocialMediaLinks(twitter: nil, instagram: nil, youtube: nil),
                    isActive: true,
                    currentPromotion: .njpw,
                    status: .active,
                    specialties: [],
                    signatureMoves: [],
                    achievements: [],
                    biography: "",
                    statistics: WrestlerStatistics(
                        totalMatches: 0,
                        wins: 0,
                        losses: 0,
                        winPercentage: 0,
                        averageMatchLength: 0,
                        championshipReigns: 0
                    )
                ),
                promotion: .njpw,
                retailer: Retailer(
                    name: "NJPW Shop",
                    url: "https://shop.njpw1972.com",
                    logoURL: "https://shop.njpw1972.com/logo.png",
                    rating: 4.7,
                    shippingInfo: "International shipping available"
                ),
                currentPrice: Price(
                    amount: 24.99,
                    currency: "USD",
                    originalAmount: 29.99,
                    discountPercentage: 16.7
                ),
                priceHistory: [
                    PricePoint(amount: 29.99, date: Date(timeIntervalSinceNow: -30 * 24 * 60 * 60)),
                    PricePoint(amount: 24.99, date: Date())
                ],
                availability: AvailabilityStatus(
                    status: .inStock,
                    quantity: 100,
                    restockDate: nil
                ),
                imageURLs: [
                    "https://shop.njpw1972.com/images/kazuchika-okada-rainmaker-tshirt-1.jpg",
                    "https://shop.njpw1972.com/images/kazuchika-okada-rainmaker-tshirt-2.jpg"
                ],
                popularityScore: 8.9,
                affiliateURL: "https://shop.njpw1972.com/kazuchika-okada-rainmaker-tshirt",
                description: "Show your support for The Rainmaker with this official Kazuchika Okada T-shirt.",
                sizes: ["S", "M", "L", "XL", "XXL"],
                colors: ["Black", "White", "Blue"],
                materials: ["100% Cotton"],
                careInstructions: "Machine wash cold, tumble dry low",
                shippingWeight: 0.5,
                dimensions: "12 x 16 inches",
                sku: "NJPW-KO-RAINMAKER-TS",
                upc: "123456789015",
                releaseDate: Date(timeIntervalSinceNow: -20 * 24 * 60 * 60),
                isLimitedEdition: false,
                isExclusive: false,
                tags: ["Kazuchika Okada", "Rainmaker", "NJPW", "T-Shirt", "Official"],
                reviews: [],
                averageRating: 4.6,
                totalReviews: 78,
                returnPolicy: "30-day return policy",
                warranty: "1-year manufacturer warranty"
            )
        ]
    }
    
    private func generateImpactMerchandise() -> [MerchandiseItem] {
        return [
            MerchandiseItem(
                id: "impact-merch-1",
                name: "Rich Swann 'Impact World Champion' T-Shirt",
                category: .tShirt,
                wrestler: Wrestler(
                    id: "impact-1",
                    name: "Rich Swann",
                    realName: "Richard Swann",
                    ringName: "Rich Swann",
                    promotions: [.impact],
                    hometown: "Baltimore, Maryland",
                    height: "5'8\"",
                    weight: "175 lbs",
                    debut: Date(),
                    championships: [],
                    photoURL: nil,
                    socialMedia: SocialMediaLinks(twitter: nil, instagram: nil, youtube: nil),
                    isActive: true,
                    currentPromotion: .impact,
                    status: .active,
                    specialties: [],
                    signatureMoves: [],
                    achievements: [],
                    biography: "",
                    statistics: WrestlerStatistics(
                        totalMatches: 0,
                        wins: 0,
                        losses: 0,
                        winPercentage: 0,
                        averageMatchLength: 0,
                        championshipReigns: 0
                    )
                ),
                promotion: .impact,
                retailer: Retailer(
                    name: "Impact Shop",
                    url: "https://shop.impactwrestling.com",
                    logoURL: "https://shop.impactwrestling.com/logo.png",
                    rating: 4.4,
                    shippingInfo: "Free shipping on orders over $35"
                ),
                currentPrice: Price(
                    amount: 22.99,
                    currency: "USD",
                    originalAmount: 27.99,
                    discountPercentage: 17.9
                ),
                priceHistory: [
                    PricePoint(amount: 27.99, date: Date(timeIntervalSinceNow: -30 * 24 * 60 * 60)),
                    PricePoint(amount: 22.99, date: Date())
                ],
                availability: AvailabilityStatus(
                    status: .inStock,
                    quantity: 50,
                    restockDate: nil
                ),
                imageURLs: [
                    "https://shop.impactwrestling.com/images/rich-swann-impact-world-champion-tshirt-1.jpg",
                    "https://shop.impactwrestling.com/images/rich-swann-impact-world-champion-tshirt-2.jpg"
                ],
                popularityScore: 6.5,
                affiliateURL: "https://shop.impactwrestling.com/rich-swann-impact-world-champion-tshirt",
                description: "Celebrate Rich Swann's Impact World Championship with this official T-shirt.",
                sizes: ["S", "M", "L", "XL", "XXL"],
                colors: ["Black", "White", "Red"],
                materials: ["100% Cotton"],
                careInstructions: "Machine wash cold, tumble dry low",
                shippingWeight: 0.5,
                dimensions: "12 x 16 inches",
                sku: "IMPACT-RS-WORLD-CHAMPION-TS",
                upc: "123456789016",
                releaseDate: Date(timeIntervalSinceNow: -15 * 24 * 60 * 60),
                isLimitedEdition: false,
                isExclusive: false,
                tags: ["Rich Swann", "Impact World Champion", "Impact", "T-Shirt", "Official"],
                reviews: [],
                averageRating: 4.3,
                totalReviews: 45,
                returnPolicy: "30-day return policy",
                warranty: "1-year manufacturer warranty"
            )
        ]
    }
    
    private func generateROHMerchandise() -> [MerchandiseItem] {
        return [
            MerchandiseItem(
                id: "roh-merch-1",
                name: "Rush 'ROH World Champion' T-Shirt",
                category: .tShirt,
                wrestler: Wrestler(
                    id: "roh-1",
                    name: "Rush",
                    realName: "William Arturo Rios Ruiz",
                    ringName: "Rush",
                    promotions: [.roh],
                    hometown: "Monterrey, Mexico",
                    height: "5'10\"",
                    weight: "200 lbs",
                    debut: Date(),
                    championships: [],
                    photoURL: nil,
                    socialMedia: SocialMediaLinks(twitter: nil, instagram: nil, youtube: nil),
                    isActive: true,
                    currentPromotion: .roh,
                    status: .active,
                    specialties: [],
                    signatureMoves: [],
                    achievements: [],
                    biography: "",
                    statistics: WrestlerStatistics(
                        totalMatches: 0,
                        wins: 0,
                        losses: 0,
                        winPercentage: 0,
                        averageMatchLength: 0,
                        championshipReigns: 0
                    )
                ),
                promotion: .roh,
                retailer: Retailer(
                    name: "ROH Shop",
                    url: "https://shop.rohwrestling.com",
                    logoURL: "https://shop.rohwrestling.com/logo.png",
                    rating: 4.5,
                    shippingInfo: "Free shipping on orders over $30"
                ),
                currentPrice: Price(
                    amount: 19.99,
                    currency: "USD",
                    originalAmount: 24.99,
                    discountPercentage: 20.0
                ),
                priceHistory: [
                    PricePoint(amount: 24.99, date: Date(timeIntervalSinceNow: -30 * 24 * 60 * 60)),
                    PricePoint(amount: 19.99, date: Date())
                ],
                availability: AvailabilityStatus(
                    status: .inStock,
                    quantity: 80,
                    restockDate: nil
                ),
                imageURLs: [
                    "https://shop.rohwrestling.com/images/rush-roh-world-champion-tshirt-1.jpg",
                    "https://shop.rohwrestling.com/images/rush-roh-world-champion-tshirt-2.jpg"
                ],
                popularityScore: 7.2,
                affiliateURL: "https://shop.rohwrestling.com/rush-roh-world-champion-tshirt",
                description: "Support Rush's ROH World Championship reign with this official T-shirt.",
                sizes: ["S", "M", "L", "XL", "XXL"],
                colors: ["Black", "White", "Red"],
                materials: ["100% Cotton"],
                careInstructions: "Machine wash cold, tumble dry low",
                shippingWeight: 0.5,
                dimensions: "12 x 16 inches",
                sku: "ROH-RUSH-WORLD-CHAMPION-TS",
                upc: "123456789017",
                releaseDate: Date(timeIntervalSinceNow: -10 * 24 * 60 * 60),
                isLimitedEdition: false,
                isExclusive: false,
                tags: ["Rush", "ROH World Champion", "ROH", "T-Shirt", "Official"],
                reviews: [],
                averageRating: 4.4,
                totalReviews: 32,
                returnPolicy: "30-day return policy",
                warranty: "1-year manufacturer warranty"
            )
        ]
    }
    
    private func generateIndieMerchandise() -> [MerchandiseItem] {
        return [
            MerchandiseItem(
                id: "indie-merch-1",
                name: "Orange Cassidy 'Freshly Squeezed' T-Shirt",
                category: .tShirt,
                wrestler: Wrestler(
                    id: "indie-1",
                    name: "Orange Cassidy",
                    realName: "James Cipperly",
                    ringName: "Orange Cassidy",
                    promotions: [.indie, .aew],
                    hometown: "New York, New York",
                    height: "5'10\"",
                    weight: "180 lbs",
                    debut: Date(),
                    championships: [],
                    photoURL: nil,
                    socialMedia: SocialMediaLinks(twitter: nil, instagram: nil, youtube: nil),
                    isActive: true,
                    currentPromotion: .aew,
                    status: .active,
                    specialties: [],
                    signatureMoves: [],
                    achievements: [],
                    biography: "",
                    statistics: WrestlerStatistics(
                        totalMatches: 0,
                        wins: 0,
                        losses: 0,
                        winPercentage: 0,
                        averageMatchLength: 0,
                        championshipReigns: 0
                    )
                ),
                promotion: .indie,
                retailer: Retailer(
                    name: "Pro Wrestling Tees",
                    url: "https://www.prowrestlingtees.com",
                    logoURL: "https://www.prowrestlingtees.com/logo.png",
                    rating: 4.3,
                    shippingInfo: "Free shipping on orders over $25"
                ),
                currentPrice: Price(
                    amount: 18.99,
                    currency: "USD",
                    originalAmount: 22.99,
                    discountPercentage: 17.4
                ),
                priceHistory: [
                    PricePoint(amount: 22.99, date: Date(timeIntervalSinceNow: -30 * 24 * 60 * 60)),
                    PricePoint(amount: 18.99, date: Date())
                ],
                availability: AvailabilityStatus(
                    status: .inStock,
                    quantity: 300,
                    restockDate: nil
                ),
                imageURLs: [
                    "https://www.prowrestlingtees.com/images/orange-cassidy-freshly-squeezed-tshirt-1.jpg",
                    "https://www.prowrestlingtees.com/images/orange-cassidy-freshly-squeezed-tshirt-2.jpg"
                ],
                popularityScore: 9.5,
                affiliateURL: "https://www.prowrestlingtees.com/orange-cassidy-freshly-squeezed-tshirt",
                description: "Get fresh with Orange Cassidy's signature 'Freshly Squeezed' T-shirt.",
                sizes: ["S", "M", "L", "XL", "XXL"],
                colors: ["Orange", "Black", "White"],
                materials: ["100% Cotton"],
                careInstructions: "Machine wash cold, tumble dry low",
                shippingWeight: 0.5,
                dimensions: "12 x 16 inches",
                sku: "PWT-OC-FRESHLY-SQUEEZED-TS",
                upc: "123456789018",
                releaseDate: Date(timeIntervalSinceNow: -5 * 24 * 60 * 60),
                isLimitedEdition: false,
                isExclusive: false,
                tags: ["Orange Cassidy", "Freshly Squeezed", "Indie", "T-Shirt", "Official"],
                reviews: [],
                averageRating: 4.9,
                totalReviews: 203,
                returnPolicy: "30-day return policy",
                warranty: "1-year manufacturer warranty"
            )
        ]
    }
    
    private func processMerchandise(_ newMerchandise: [MerchandiseItem]) {
        // Remove duplicates and merge data from multiple sources
        let uniqueMerchandise = removeDuplicateMerchandise(newMerchandise)
        
        // Calculate trending items based on popularity score and recent activity
        let trending = calculateTrendingItems(uniqueMerchandise)
        
        // Sort by popularity score
        let sortedMerchandise = uniqueMerchandise.sorted { $0.popularityScore > $1.popularityScore }
        
        // Update published merchandise
        DispatchQueue.main.async {
            self.merchandise = sortedMerchandise
            self.trendingItems = trending
            self.cacheMerchandise(sortedMerchandise)
        }
    }
    
    private func removeDuplicateMerchandise(_ merchandise: [MerchandiseItem]) -> [MerchandiseItem] {
        var uniqueMerchandise: [MerchandiseItem] = []
        var seenItems: Set<String> = []
        
        for item in merchandise {
            if !seenItems.contains(item.id) {
                seenItems.insert(item.id)
                uniqueMerchandise.append(item)
            }
        }
        
        return uniqueMerchandise
    }
    
    private func calculateTrendingItems(_ merchandise: [MerchandiseItem]) -> [MerchandiseItem] {
        // Calculate trending items based on popularity score, recent sales, and social media activity
        let trending = merchandise.filter { item in
            item.popularityScore > 7.0 && 
            item.availability.status == .inStock &&
            item.currentPrice.discountPercentage > 10.0
        }
        
        return Array(trending.prefix(10)) // Top 10 trending items
    }
    
    private func startPeriodicRefresh() {
        // Refresh every hour for price updates
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            self?.refreshMerchandiseData()
        }
    }
    
    private func cacheMerchandise(_ merchandise: [MerchandiseItem]) {
        cache.cacheMerchandise(merchandise)
    }
    
    private func loadCachedMerchandise() {
        if let cachedMerchandise = cache.getCachedMerchandise() {
            merchandise = cachedMerchandise
        }
    }
    
    private func savePriceAlerts() {
        // Save price alerts to UserDefaults
        if let data = try? JSONEncoder().encode(priceAlerts) {
            UserDefaults.standard.set(data, forKey: "price_alerts")
        }
    }
    
    private func loadPriceAlerts() {
        // Load price alerts from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "price_alerts"),
           let alerts = try? JSONDecoder().decode([PriceAlert].self, from: data) {
            priceAlerts = alerts
        }
    }
}

// MARK: - Supporting Types
struct MerchandiseDataSource {
    let name: String
    let baseURL: String
    let promotion: WrestlingPromotion
    let reliability: ReliabilityTier
    let apiKey: String
}

struct Retailer {
    let name: String
    let url: String
    let logoURL: String?
    let rating: Double
    let shippingInfo: String
}

struct Price {
    let amount: Double
    let currency: String
    let originalAmount: Double?
    let discountPercentage: Double?
}

struct PricePoint {
    let amount: Double
    let date: Date
}

struct AvailabilityStatus {
    let status: AvailabilityType
    let quantity: Int?
    let restockDate: Date?
}

enum AvailabilityType {
    case inStock
    case lowStock
    case outOfStock
    case discontinued
    case preOrder
}

struct ProductReview {
    let id: String
    let user: String
    let rating: Int
    let title: String
    let content: String
    let date: Date
    let verified: Bool
}

struct PriceAlert {
    let id: String
    let item: MerchandiseItem
    let targetPrice: Double
    let currentPrice: Double
    let isActive: Bool
    let createdDate: Date
}

// MARK: - Merchandise Cache
class MerchandiseCache {
    static let shared = MerchandiseCache()
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_merchandise"
    private let maxCacheAge: TimeInterval = 60 * 60 // 1 hour
    
    func cacheMerchandise(_ merchandise: [MerchandiseItem]) {
        let cacheData = MerchandiseCacheData(
            merchandise: merchandise,
            timestamp: Date()
        )
        
        if let data = try? JSONEncoder().encode(cacheData) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }
    
    func getCachedMerchandise() -> [MerchandiseItem]? {
        guard let data = userDefaults.data(forKey: cacheKey),
              let cacheData = try? JSONDecoder().decode(MerchandiseCacheData.self, from: data) else {
            return nil
        }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cacheData.timestamp) > maxCacheAge {
            return nil
        }
        
        return cacheData.merchandise
    }
    
    func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
    }
}

struct MerchandiseCacheData: Codable {
    let merchandise: [MerchandiseItem]
    let timestamp: Date
}
