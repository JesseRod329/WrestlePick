import XCTest
@testable import WrestlePick

final class WrestlePickTests: XCTestCase {
    
    // MARK: - Test Properties
    var authService: AuthService!
    var newsService: NewsService!
    var predictionService: PredictionService!
    var subscriptionService: SubscriptionService!
    var analyticsService: AnalyticsService!
    var performanceMonitor: PerformanceMonitor!
    
    override func setUpWithError() throws {
        // Initialize services for testing
        authService = AuthService.shared
        newsService = NewsService.shared
        predictionService = PredictionService.shared
        subscriptionService = SubscriptionService.shared
        analyticsService = AnalyticsService.shared
        performanceMonitor = PerformanceMonitor.shared
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
        authService = nil
        newsService = nil
        predictionService = nil
        subscriptionService = nil
        analyticsService = nil
        performanceMonitor = nil
    }
    
    // MARK: - Authentication Tests
    func testUserAuthentication() throws {
        // Test user signup
        let expectation = XCTestExpectation(description: "User signup")
        
        authService.signUp(email: "test@example.com", password: "password123") { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertEqual(user.email, "test@example.com")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Signup failed: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testUserSignIn() throws {
        let expectation = XCTestExpectation(description: "User signin")
        
        authService.signIn(email: "test@example.com", password: "password123") { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertTrue(self.authService.isAuthenticated)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Signin failed: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testUserSignOut() throws {
        // First sign in
        let signInExpectation = XCTestExpectation(description: "User signin")
        authService.signIn(email: "test@example.com", password: "password123") { _ in
            signInExpectation.fulfill()
        }
        wait(for: [signInExpectation], timeout: 10.0)
        
        // Then sign out
        authService.signOut()
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    // MARK: - News Service Tests
    func testNewsArticleCreation() throws {
        let article = NewsArticle(
            title: "Test Article",
            content: "Test content",
            author: "Test Author",
            source: "Test Source",
            publishDate: Date(),
            category: .breaking
        )
        
        XCTAssertEqual(article.title, "Test Article")
        XCTAssertEqual(article.content, "Test content")
        XCTAssertEqual(article.author, "Test Author")
        XCTAssertEqual(article.source, "Test Source")
        XCTAssertEqual(article.category, .breaking)
    }
    
    func testNewsArticleFiltering() throws {
        let articles = createTestNewsArticles()
        
        // Test category filtering
        let breakingArticles = articles.filter { $0.category == .breaking }
        XCTAssertEqual(breakingArticles.count, 2)
        
        // Test source filtering
        let sourceArticles = articles.filter { $0.source == "Wrestling Observer" }
        XCTAssertEqual(sourceArticles.count, 1)
    }
    
    func testNewsArticleSearch() throws {
        let articles = createTestNewsArticles()
        
        // Test title search
        let searchResults = articles.filter { $0.title.lowercased().contains("wrestling") }
        XCTAssertEqual(searchResults.count, 2)
        
        // Test content search
        let contentResults = articles.filter { $0.content.lowercased().contains("championship") }
        XCTAssertEqual(contentResults.count, 1)
    }
    
    // MARK: - Prediction Service Tests
    func testPredictionCreation() throws {
        let prediction = Prediction(
            userId: "test_user",
            title: "Test Prediction",
            description: "Test prediction description",
            category: .ppv,
            eventId: "test_event",
            eventName: "Test Event",
            eventDate: Date(),
            status: .draft,
            confidence: 8,
            tags: ["test", "prediction"],
            isPublic: true,
            picks: [],
            accuracy: nil,
            engagement: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(prediction.title, "Test Prediction")
        XCTAssertEqual(prediction.category, .ppv)
        XCTAssertEqual(prediction.confidence, 8)
        XCTAssertEqual(prediction.status, .draft)
    }
    
    func testPredictionAccuracyCalculation() throws {
        let prediction = createTestPrediction()
        
        // Test accuracy calculation
        let accuracy = PredictionAccuracy(
            overallAccuracy: 0.75,
            categoryAccuracy: ["ppv": 0.8, "storyline": 0.7],
            confidenceAccuracy: [5: 0.6, 8: 0.9],
            streak: 5,
            totalPredictions: 20,
            correctPredictions: 15
        )
        
        XCTAssertEqual(accuracy.overallAccuracy, 0.75)
        XCTAssertEqual(accuracy.streak, 5)
        XCTAssertEqual(accuracy.totalPredictions, 20)
        XCTAssertEqual(accuracy.correctPredictions, 15)
    }
    
    func testPredictionScoring() throws {
        let prediction = createTestPrediction()
        
        // Test scoring algorithm
        let score = calculatePredictionScore(prediction, wasCorrect: true, confidence: 8)
        XCTAssertGreaterThan(score, 0)
        
        // Test confidence bonus
        let highConfidenceScore = calculatePredictionScore(prediction, wasCorrect: true, confidence: 10)
        let lowConfidenceScore = calculatePredictionScore(prediction, wasCorrect: true, confidence: 5)
        XCTAssertGreaterThan(highConfidenceScore, lowConfidenceScore)
    }
    
    // MARK: - Subscription Service Tests
    func testSubscriptionPlanValidation() throws {
        let monthlyPlan = SubscriptionPlan(
            id: "monthly",
            name: "Premium Monthly",
            description: "Monthly subscription",
            price: 2.99,
            duration: .monthly,
            features: [],
            productId: "com.wrestlepick.premium.monthly"
        )
        
        XCTAssertEqual(monthlyPlan.id, "monthly")
        XCTAssertEqual(monthlyPlan.price, 2.99)
        XCTAssertEqual(monthlyPlan.duration, .monthly)
        XCTAssertEqual(monthlyPlan.monthlyPrice, 2.99)
    }
    
    func testSubscriptionFeatureGating() throws {
        // Test free tier limitations
        XCTAssertFalse(subscriptionService.canCreateFantasyBooking())
        XCTAssertFalse(subscriptionService.canAccessAdvancedAnalytics())
        XCTAssertFalse(subscriptionService.canCreateCustomCategory())
        
        // Test premium features (would need to mock subscription)
        // This would require mocking the subscription state
    }
    
    func testUsageLimitTracking() throws {
        // Test prediction usage tracking
        subscriptionService.trackPredictionUsage()
        subscriptionService.trackPredictionUsage()
        subscriptionService.trackPredictionUsage()
        
        // Test fantasy booking usage tracking
        subscriptionService.trackFantasyBookingUsage()
        
        // Test custom award usage tracking
        subscriptionService.trackCustomAwardUsage()
        
        // These would need to be verified against actual usage limits
    }
    
    // MARK: - Analytics Service Tests
    func testEventTracking() throws {
        let expectation = XCTestExpectation(description: "Event tracking")
        
        analyticsService.trackEvent("test_event", parameters: [
            "test_param": "test_value",
            "timestamp": Date().timeIntervalSince1970
        ])
        
        // Verify event was tracked
        XCTAssertEqual(analyticsService.totalEvents, 1)
        expectation.fulfill()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testScreenViewTracking() throws {
        analyticsService.trackScreenView("test_screen", parameters: [
            "screen_type": "test"
        ])
        
        XCTAssertEqual(analyticsService.totalScreenViews, 1)
    }
    
    func testUserEngagementTracking() throws {
        analyticsService.trackUserEngagement("test_action", context: "test_context")
        
        // Verify engagement was tracked
        let analyticsData = analyticsService.getAnalyticsData()
        XCTAssertNotNil(analyticsData.userEngagement)
    }
    
    // MARK: - Performance Monitor Tests
    func testPerformanceMonitoring() throws {
        // Test memory usage tracking
        performanceMonitor.updateMemoryUsage()
        XCTAssertGreaterThanOrEqual(performanceMonitor.memoryUsage, 0)
        
        // Test CPU usage tracking
        performanceMonitor.updateCPUUsage()
        XCTAssertGreaterThanOrEqual(performanceMonitor.cpuUsage, 0)
        XCTAssertLessThanOrEqual(performanceMonitor.cpuUsage, 100)
    }
    
    func testPerformanceReportGeneration() throws {
        let report = performanceMonitor.getPerformanceReport()
        
        XCTAssertNotNil(report)
        XCTAssertGreaterThanOrEqual(report.memoryUsage, 0)
        XCTAssertGreaterThanOrEqual(report.cpuUsage, 0)
        XCTAssertGreaterThanOrEqual(report.networkLatency, 0)
    }
    
    // MARK: - Data Model Tests
    func testUserModelValidation() throws {
        let user = User(
            id: "test_user",
            email: "test@example.com",
            displayName: "Test User",
            username: "testuser",
            avatarURL: nil,
            bio: "Test bio",
            joinDate: Date(),
            lastActive: Date(),
            preferences: UserPreferences(),
            predictionStats: PredictionStats(),
            socialStats: SocialStats(),
            isVerified: false,
            isPremium: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(user.id, "test_user")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.displayName, "Test User")
        XCTAssertEqual(user.username, "testuser")
    }
    
    func testNewsArticleModelValidation() throws {
        let article = NewsArticle(
            title: "Test Article",
            content: "Test content",
            author: "Test Author",
            source: "Test Source",
            publishDate: Date(),
            category: .breaking
        )
        
        XCTAssertEqual(article.title, "Test Article")
        XCTAssertEqual(article.content, "Test content")
        XCTAssertEqual(article.author, "Test Author")
        XCTAssertEqual(article.source, "Test Source")
        XCTAssertEqual(article.category, .breaking)
    }
    
    func testPredictionModelValidation() throws {
        let prediction = Prediction(
            userId: "test_user",
            title: "Test Prediction",
            description: "Test description",
            category: .ppv,
            eventId: "test_event",
            eventName: "Test Event",
            eventDate: Date(),
            status: .draft,
            confidence: 8,
            tags: ["test"],
            isPublic: true,
            picks: [],
            accuracy: nil,
            engagement: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(prediction.userId, "test_user")
        XCTAssertEqual(prediction.title, "Test Prediction")
        XCTAssertEqual(prediction.category, .ppv)
        XCTAssertEqual(prediction.confidence, 8)
        XCTAssertEqual(prediction.status, .draft)
    }
    
    // MARK: - Helper Methods
    private func createTestNewsArticles() -> [NewsArticle] {
        return [
            NewsArticle(
                title: "Wrestling News 1",
                content: "First wrestling news article",
                author: "Author 1",
                source: "Wrestling Observer",
                publishDate: Date(),
                category: .breaking
            ),
            NewsArticle(
                title: "Wrestling News 2",
                content: "Second wrestling news article about championship",
                author: "Author 2",
                source: "Fightful",
                publishDate: Date(),
                category: .breaking
            ),
            NewsArticle(
                title: "Regular News",
                content: "Regular news article",
                author: "Author 3",
                source: "Other Source",
                publishDate: Date(),
                category: .general
            )
        ]
    }
    
    private func createTestPrediction() -> Prediction {
        return Prediction(
            userId: "test_user",
            title: "Test Prediction",
            description: "Test prediction description",
            category: .ppv,
            eventId: "test_event",
            eventName: "Test Event",
            eventDate: Date(),
            status: .draft,
            confidence: 8,
            tags: ["test"],
            isPublic: true,
            picks: [],
            accuracy: nil,
            engagement: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func calculatePredictionScore(_ prediction: Prediction, wasCorrect: Bool, confidence: Int) -> Int {
        var score = 0
        
        if wasCorrect {
            score += 10 // Base points for correct prediction
            score += confidence // Bonus points for confidence
        } else {
            score -= 5 // Penalty for incorrect prediction
        }
        
        return score
    }
}

// MARK: - Mock Services for Testing
class MockAuthService: AuthService {
    var mockUser: User?
    var mockIsAuthenticated = false
    
    override var isAuthenticated: Bool {
        return mockIsAuthenticated
    }
    
    override var currentUser: User? {
        return mockUser
    }
    
    override func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        if email == "test@example.com" && password == "password123" {
            mockUser = User(
                id: "test_user",
                email: email,
                displayName: "Test User",
                username: "testuser",
                avatarURL: nil,
                bio: nil,
                joinDate: Date(),
                lastActive: Date(),
                preferences: UserPreferences(),
                predictionStats: PredictionStats(),
                socialStats: SocialStats(),
                isVerified: false,
                isPremium: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            mockIsAuthenticated = true
            completion(.success(mockUser!))
        } else {
            completion(.failure(AuthError.invalidCredentials))
        }
    }
    
    override func signOut() {
        mockUser = nil
        mockIsAuthenticated = false
    }
}

// MARK: - Test Extensions
extension XCTestCase {
    func waitForAsyncOperation(timeout: TimeInterval = 10.0, operation: @escaping () -> Void) {
        let expectation = XCTestExpectation(description: "Async operation")
        
        DispatchQueue.main.async {
            operation()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
}
