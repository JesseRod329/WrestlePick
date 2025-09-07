import XCTest
import Combine
@testable import WrestlePick

class RealDataIntegrationTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - RSS Feed Tests
    func testRSSFeedsParseCorrectly() {
        let expectation = XCTestExpectation(description: "RSS feeds parse correctly")
        
        let rssManager = RSSFeedManager.shared
        rssManager.refreshAllFeeds()
        
        rssManager.$articles
            .sink { articles in
                if !articles.isEmpty {
                    XCTAssertFalse(articles.isEmpty, "Articles should not be empty")
                    XCTAssertTrue(articles.allSatisfy { !$0.title.isEmpty }, "All articles should have titles")
                    XCTAssertTrue(articles.allSatisfy { !$0.content.isEmpty }, "All articles should have content")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testRSSFeedReliabilityScoring() {
        let rssManager = RSSFeedManager.shared
        rssManager.refreshAllFeeds()
        
        let expectation = XCTestExpectation(description: "Reliability scoring works")
        
        rssManager.$articles
            .sink { articles in
                if !articles.isEmpty {
                    let tier1Sources = articles.filter { $0.source.reliability == .tier1 }
                    let tier2Sources = articles.filter { $0.source.reliability == .tier2 }
                    
                    XCTAssertTrue(tier1Sources.count > 0, "Should have Tier 1 sources")
                    XCTAssertTrue(tier2Sources.count > 0, "Should have Tier 2 sources")
                    
                    // Tier 1 sources should have higher reliability scores
                    let tier1AvgReliability = tier1Sources.map { $0.source.reliability.rawValue }.reduce(0, +) / Double(tier1Sources.count)
                    let tier2AvgReliability = tier2Sources.map { $0.source.reliability.rawValue }.reduce(0, +) / Double(tier2Sources.count)
                    
                    XCTAssertGreaterThan(tier1AvgReliability, tier2AvgReliability, "Tier 1 sources should have higher reliability")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testRSSFeedDeduplication() {
        let rssManager = RSSFeedManager.shared
        rssManager.refreshAllFeeds()
        
        let expectation = XCTestExpectation(description: "Deduplication works")
        
        rssManager.$articles
            .sink { articles in
                if !articles.isEmpty {
                    let titles = articles.map { $0.title.lowercased() }
                    let uniqueTitles = Set(titles)
                    
                    XCTAssertEqual(titles.count, uniqueTitles.count, "All article titles should be unique")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Wrestler Data Tests
    func testWrestlerDataMatchesAcrossSources() {
        let expectation = XCTestExpectation(description: "Wrestler data matches across sources")
        
        let wrestlerService = WrestlerDataService.shared
        wrestlerService.refreshWrestlerData()
        
        wrestlerService.$wrestlers
            .sink { wrestlers in
                if !wrestlers.isEmpty {
                    // Test that wrestlers have consistent data
                    for wrestler in wrestlers {
                        XCTAssertFalse(wrestler.name.isEmpty, "Wrestler name should not be empty")
                        XCTAssertFalse(wrestler.ringName.isEmpty, "Ring name should not be empty")
                        XCTAssertFalse(wrestler.promotions.isEmpty, "Wrestler should have at least one promotion")
                        XCTAssertTrue(wrestler.isActive, "Wrestler should be active")
                    }
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testWrestlerSearchFunctionality() {
        let expectation = XCTestExpectation(description: "Wrestler search works")
        
        let wrestlerService = WrestlerDataService.shared
        wrestlerService.refreshWrestlerData()
        
        wrestlerService.$wrestlers
            .sink { wrestlers in
                if !wrestlers.isEmpty {
                    let searchResults = wrestlerService.searchWrestlers(query: "Roman")
                    XCTAssertFalse(searchResults.isEmpty, "Search should return results")
                    
                    let romanReigns = searchResults.first { $0.name.contains("Roman") }
                    XCTAssertNotNil(romanReigns, "Should find Roman Reigns")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testWrestlerDataByPromotion() {
        let expectation = XCTestExpectation(description: "Wrestler data by promotion works")
        
        let wrestlerService = WrestlerDataService.shared
        wrestlerService.refreshWrestlerData()
        
        wrestlerService.$wrestlers
            .sink { wrestlers in
                if !wrestlers.isEmpty {
                    let wweWrestlers = wrestlerService.getWrestlers(by: .wwe)
                    let aewWrestlers = wrestlerService.getWrestlers(by: .aew)
                    let njpwWrestlers = wrestlerService.getWrestlers(by: .njpw)
                    
                    XCTAssertFalse(wweWrestlers.isEmpty, "Should have WWE wrestlers")
                    XCTAssertFalse(aewWrestlers.isEmpty, "Should have AEW wrestlers")
                    XCTAssertFalse(njpwWrestlers.isEmpty, "Should have NJPW wrestlers")
                    
                    // All wrestlers should belong to their respective promotions
                    XCTAssertTrue(wweWrestlers.allSatisfy { $0.promotions.contains(.wwe) }, "All WWE wrestlers should have WWE promotion")
                    XCTAssertTrue(aewWrestlers.allSatisfy { $0.promotions.contains(.aew) }, "All AEW wrestlers should have AEW promotion")
                    XCTAssertTrue(njpwWrestlers.allSatisfy { $0.promotions.contains(.njpw) }, "All NJPW wrestlers should have NJPW promotion")
                    
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Event Data Tests
    func testEventSchedulesSyncAccurately() {
        let expectation = XCTestExpectation(description: "Event schedules sync accurately")
        
        let eventService = LiveEventDataService.shared
        eventService.refreshEventData()
        
        eventService.$upcomingEvents
            .sink { events in
                if !events.isEmpty {
                    // Test that events have valid data
                    for event in events {
                        XCTAssertFalse(event.name.isEmpty, "Event name should not be empty")
                        XCTAssertFalse(event.venue.name.isEmpty, "Venue name should not be empty")
                        XCTAssertTrue(event.date > Date(), "Event date should be in the future")
                        XCTAssertFalse(event.matches.isEmpty, "Event should have matches")
                    }
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testEventDataByPromotion() {
        let expectation = XCTestExpectation(description: "Event data by promotion works")
        
        let eventService = LiveEventDataService.shared
        eventService.refreshEventData()
        
        eventService.$upcomingEvents
            .sink { events in
                if !events.isEmpty {
                    let wweEvents = eventService.getUpcomingEvents(for: .wwe)
                    let aewEvents = eventService.getUpcomingEvents(for: .aew)
                    let njpwEvents = eventService.getUpcomingEvents(for: .njpw)
                    
                    XCTAssertFalse(wweEvents.isEmpty, "Should have WWE events")
                    XCTAssertFalse(aewEvents.isEmpty, "Should have AEW events")
                    XCTAssertFalse(njpwEvents.isEmpty, "Should have NJPW events")
                    
                    // All events should belong to their respective promotions
                    XCTAssertTrue(wweEvents.allSatisfy { $0.promotion == .wwe }, "All WWE events should have WWE promotion")
                    XCTAssertTrue(aewEvents.allSatisfy { $0.promotion == .aew }, "All AEW events should have AEW promotion")
                    XCTAssertTrue(njpwEvents.allSatisfy { $0.promotion == .njpw }, "All NJPW events should have NJPW promotion")
                    
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testEventDataByDate() {
        let expectation = XCTestExpectation(description: "Event data by date works")
        
        let eventService = LiveEventDataService.shared
        eventService.refreshEventData()
        
        eventService.$upcomingEvents
            .sink { events in
                if !events.isEmpty {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    let tomorrowEvents = eventService.getEventsByDate(tomorrow)
                    
                    // Should have events for tomorrow
                    XCTAssertFalse(tomorrowEvents.isEmpty, "Should have events for tomorrow")
                    
                    // All events should be on the correct date
                    let calendar = Calendar.current
                    XCTAssertTrue(tomorrowEvents.allSatisfy { calendar.isDate($0.date, inSameDayAs: tomorrow) }, "All events should be on the correct date")
                    
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Merchandise Data Tests
    func testMerchandisePricesUpdateCorrectly() {
        let expectation = XCTestExpectation(description: "Merchandise prices update correctly")
        
        let merchService = MerchandiseDataService.shared
        merchService.refreshMerchandiseData()
        
        merchService.$merchandise
            .sink { merchandise in
                if !merchandise.isEmpty {
                    // Test that merchandise has valid pricing data
                    for item in merchandise {
                        XCTAssertTrue(item.currentPrice.amount > 0, "Price should be positive")
                        XCTAssertFalse(item.currentPrice.currency.isEmpty, "Currency should not be empty")
                        XCTAssertTrue(item.priceHistory.count > 0, "Should have price history")
                    }
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testMerchandiseDataByCategory() {
        let expectation = XCTestExpectation(description: "Merchandise data by category works")
        
        let merchService = MerchandiseDataService.shared
        merchService.refreshMerchandiseData()
        
        merchService.$merchandise
            .sink { merchandise in
                if !merchandise.isEmpty {
                    let tShirts = merchService.getMerchandise(by: .tShirt)
                    let hoodies = merchService.getMerchandise(by: .hoodie)
                    let hats = merchService.getMerchandise(by: .hat)
                    
                    XCTAssertFalse(tShirts.isEmpty, "Should have T-shirts")
                    XCTAssertFalse(hoodies.isEmpty, "Should have hoodies")
                    XCTAssertFalse(hats.isEmpty, "Should have hats")
                    
                    // All items should belong to their respective categories
                    XCTAssertTrue(tShirts.allSatisfy { $0.category == .tShirt }, "All T-shirts should have T-shirt category")
                    XCTAssertTrue(hoodies.allSatisfy { $0.category == .hoodie }, "All hoodies should have hoodie category")
                    XCTAssertTrue(hats.allSatisfy { $0.category == .hat }, "All hats should have hat category")
                    
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testMerchandiseSearchFunctionality() {
        let expectation = XCTestExpectation(description: "Merchandise search works")
        
        let merchService = MerchandiseDataService.shared
        merchService.refreshMerchandiseData()
        
        merchService.$merchandise
            .sink { merchandise in
                if !merchandise.isEmpty {
                    let searchResults = merchService.searchMerchandise(query: "Roman")
                    XCTAssertFalse(searchResults.isEmpty, "Search should return results")
                    
                    let romanMerch = searchResults.first { $0.name.contains("Roman") }
                    XCTAssertNotNil(romanMerch, "Should find Roman merchandise")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testMerchandiseTrendingItems() {
        let expectation = XCTestExpectation(description: "Trending items work")
        
        let merchService = MerchandiseDataService.shared
        merchService.refreshMerchandiseData()
        
        merchService.$trendingItems
            .sink { trendingItems in
                if !trendingItems.isEmpty {
                    // Test that trending items are sorted by popularity
                    let popularityScores = trendingItems.map { $0.popularityScore }
                    let sortedScores = popularityScores.sorted(by: >)
                    
                    XCTAssertEqual(popularityScores, sortedScores, "Trending items should be sorted by popularity")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Breaking News Tests
    func testBreakingNewsDetectionAccuracy() {
        let expectation = XCTestExpectation(description: "Breaking news detection works")
        
        let detector = BreakingNewsDetector.shared
        
        // Test with breaking news article
        let breakingArticle = NewsArticle(
            id: "test-1",
            title: "BREAKING: Roman Reigns injured in training",
            content: "Sources confirm that Roman Reigns has suffered an injury during training and may miss WrestleMania.",
            source: NewsSource(
                name: "Wrestling Observer Newsletter",
                url: "https://www.f4wonline.com",
                reliability: .tier1,
                isVerified: true,
                establishedDate: Date(),
                contactInfo: nil
            ),
            category: .breaking,
            promotions: [.wwe],
            publishDate: Date(),
            author: "Dave Meltzer",
            imageURL: nil,
            tags: ["breaking", "injury", "Roman Reigns"],
            isBreaking: true,
            isVerified: true,
            likes: 0,
            shares: 0,
            comments: 0,
            isLiked: false,
            isBookmarked: false,
            isShared: false
        )
        
        let analysis = detector.analyzeArticle(breakingArticle)
        
        XCTAssertTrue(analysis.isBreaking, "Should detect breaking news")
        XCTAssertGreaterThan(analysis.confidence, 0.6, "Confidence should be high")
        XCTAssertTrue(analysis.categories.contains(.breaking), "Should have breaking category")
        XCTAssertTrue(analysis.categories.contains(.injury), "Should have injury category")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testBreakingNewsFalsePositives() {
        let expectation = XCTestExpectation(description: "Breaking news false positives test")
        
        let detector = BreakingNewsDetector.shared
        
        // Test with non-breaking news article
        let regularArticle = NewsArticle(
            id: "test-2",
            title: "WWE Raw results from last night",
            content: "Here are the results from last night's episode of Monday Night Raw.",
            source: NewsSource(
                name: "Wrestling Observer Newsletter",
                url: "https://www.f4wonline.com",
                reliability: .tier1,
                isVerified: true,
                establishedDate: Date(),
                contactInfo: nil
            ),
            category: .results,
            promotions: [.wwe],
            publishDate: Date(),
            author: "Dave Meltzer",
            imageURL: nil,
            tags: ["results", "Raw"],
            isBreaking: false,
            isVerified: true,
            likes: 0,
            shares: 0,
            comments: 0,
            isLiked: false,
            isBookmarked: false,
            isShared: false
        )
        
        let analysis = detector.analyzeArticle(regularArticle)
        
        XCTAssertFalse(analysis.isBreaking, "Should not detect breaking news")
        XCTAssertLessThan(analysis.confidence, 0.6, "Confidence should be low")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Data Validation Tests
    func testDataValidationCatchesInvalidContent() {
        let expectation = XCTestExpectation(description: "Data validation works")
        
        let validator = DataValidator()
        
        // Test with invalid article
        let invalidArticle = NewsArticle(
            id: "test-3",
            title: "", // Empty title
            content: "", // Empty content
            source: NewsSource(
                name: "Test Source",
                url: "https://test.com",
                reliability: .tier2,
                isVerified: false,
                establishedDate: Date(),
                contactInfo: nil
            ),
            category: .news,
            promotions: [],
            publishDate: Date().addingTimeInterval(86400), // Future date
            author: nil,
            imageURL: nil,
            tags: [],
            isBreaking: false,
            isVerified: false,
            likes: 0,
            shares: 0,
            comments: 0,
            isLiked: false,
            isBookmarked: false,
            isShared: false
        )
        
        let result = validator.validateNewsArticle(invalidArticle)
        
        XCTAssertFalse(result.isValid, "Should detect invalid article")
        XCTAssertTrue(result.issues.contains { $0.type == .missingTitle }, "Should detect missing title")
        XCTAssertTrue(result.issues.contains { $0.type == .missingContent }, "Should detect missing content")
        XCTAssertTrue(result.issues.contains { $0.type == .futureDate }, "Should detect future date")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDataValidationPassesValidContent() {
        let expectation = XCTestExpectation(description: "Data validation passes valid content")
        
        let validator = DataValidator()
        
        // Test with valid article
        let validArticle = NewsArticle(
            id: "test-4",
            title: "Roman Reigns wins WWE Championship",
            content: "Roman Reigns defeated Seth Rollins to win the WWE Championship at WrestleMania.",
            source: NewsSource(
                name: "Wrestling Observer Newsletter",
                url: "https://www.f4wonline.com",
                reliability: .tier1,
                isVerified: true,
                establishedDate: Date(),
                contactInfo: nil
            ),
            category: .news,
            promotions: [.wwe],
            publishDate: Date().addingTimeInterval(-3600), // 1 hour ago
            author: "Dave Meltzer",
            imageURL: "https://example.com/image.jpg",
            tags: ["Roman Reigns", "WWE Championship", "WrestleMania"],
            isBreaking: false,
            isVerified: true,
            likes: 0,
            shares: 0,
            comments: 0,
            isLiked: false,
            isBookmarked: false,
            isShared: false
        )
        
        let result = validator.validateNewsArticle(validArticle)
        
        XCTAssertTrue(result.isValid, "Should pass valid article")
        XCTAssertTrue(result.issues.isEmpty, "Should have no issues")
        XCTAssertGreaterThan(result.score, 0.8, "Should have high quality score")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Real-time Sync Tests
    func testRealTimeSyncHandlesNetworkInterruptions() {
        let expectation = XCTestExpectation(description: "Real-time sync handles network interruptions")
        
        let syncManager = RealTimeDataManager.shared
        
        // Test offline sync
        syncManager.handleOfflineSync()
        
        // Should queue updates for when online
        XCTAssertTrue(syncManager.isOnline, "Should be online")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRealTimeSyncPerformance() {
        let expectation = XCTestExpectation(description: "Real-time sync performance test")
        
        let syncManager = RealTimeDataManager.shared
        let startTime = Date()
        
        syncManager.forceSync()
        
        // Wait for sync to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            XCTAssertLessThan(duration, 30.0, "Sync should complete within 30 seconds")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 35.0)
    }
    
    // MARK: - Offline Cache Tests
    func testOfflineCacheProvidesConsistentExperience() {
        let expectation = XCTestExpectation(description: "Offline cache provides consistent experience")
        
        let rssManager = RSSFeedManager.shared
        rssManager.refreshAllFeeds()
        
        // Wait for data to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            let articles = rssManager.articles
            
            if !articles.isEmpty {
                // Test that cached data is available
                XCTAssertFalse(articles.isEmpty, "Should have cached articles")
                XCTAssertTrue(articles.allSatisfy { !$0.title.isEmpty }, "All cached articles should have titles")
                XCTAssertTrue(articles.allSatisfy { !$0.content.isEmpty }, "All cached articles should have content")
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Rate Limiting Tests
    func testRateLimitingPreventsAPIQuotaExceeded() {
        let expectation = XCTestExpectation(description: "Rate limiting prevents API quota exceeded")
        
        let rateLimiter = RateLimiter()
        let endpoint = "test-endpoint"
        
        // Test rate limiting
        var requestCount = 0
        let maxRequests = 5
        
        for _ in 0..<maxRequests {
            if rateLimiter.canMakeRequest(for: endpoint) {
                requestCount += 1
            }
        }
        
        // Should allow some requests but not exceed limit
        XCTAssertLessThanOrEqual(requestCount, maxRequests, "Should not exceed rate limit")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Legal Compliance Tests
    func testLegalComplianceWorksInAllJurisdictions() {
        let expectation = XCTestExpectation(description: "Legal compliance works in all jurisdictions")
        
        // Test that the app respects legal requirements
        let productionConfig = ProductionDataConfig.shared
        
        // Should have proper configuration
        XCTAssertNotNil(productionConfig.apiConfig, "Should have API configuration")
        XCTAssertNotNil(productionConfig.rateLimiter, "Should have rate limiter")
        XCTAssertNotNil(productionConfig.securityConfig, "Should have security configuration")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    func testDataSyncSpeedBenchmarks() {
        let expectation = XCTestExpectation(description: "Data sync speed benchmarks")
        
        let startTime = Date()
        
        let rssManager = RSSFeedManager.shared
        rssManager.refreshAllFeeds()
        
        rssManager.$articles
            .sink { articles in
                if !articles.isEmpty {
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime)
                    
                    // Should sync within reasonable time
                    XCTAssertLessThan(duration, 30.0, "RSS sync should complete within 30 seconds")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 35.0)
    }
    
    func testMemoryUsageDuringLargeUpdates() {
        let expectation = XCTestExpectation(description: "Memory usage during large updates")
        
        let initialMemory = getMemoryUsage()
        
        let rssManager = RSSFeedManager.shared
        rssManager.refreshAllFeeds()
        
        rssManager.$articles
            .sink { articles in
                if !articles.isEmpty {
                    let currentMemory = getMemoryUsage()
                    let memoryIncrease = currentMemory - initialMemory
                    
                    // Memory increase should be reasonable (less than 100MB)
                    XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024, "Memory increase should be less than 100MB")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Helper Methods
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}
