import XCTest
import Firebase
import FirebaseAuth
import FirebaseFirestore
@testable import WrestlePick

final class FirebaseIntegrationTests: XCTestCase {
    
    var auth: Auth!
    var firestore: Firestore!
    var authService: AuthService!
    var newsService: NewsService!
    var predictionService: PredictionService!
    
    override func setUpWithError() throws {
        // Configure Firebase for testing
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        auth = Auth.auth()
        firestore = Firestore.firestore()
        authService = AuthService.shared
        newsService = NewsService.shared
        predictionService = PredictionService.shared
        
        // Use emulator for testing
        auth.useEmulator(withHost: "localhost", port: 9099)
        firestore.useEmulator(withHost: "localhost", port: 8080)
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        try? auth.signOut()
    }
    
    // MARK: - Authentication Integration Tests
    func testFirebaseAuthenticationSignUp() throws {
        let expectation = XCTestExpectation(description: "Firebase signup")
        
        auth.createUser(withEmail: "test@example.com", password: "password123") { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.user.email, "test@example.com")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testFirebaseAuthenticationSignIn() throws {
        // First create a user
        let signUpExpectation = XCTestExpectation(description: "Firebase signup")
        auth.createUser(withEmail: "test@example.com", password: "password123") { _, _ in
            signUpExpectation.fulfill()
        }
        wait(for: [signUpExpectation], timeout: 10.0)
        
        // Then sign in
        let signInExpectation = XCTestExpectation(description: "Firebase signin")
        auth.signIn(withEmail: "test@example.com", password: "password123") { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.user.email, "test@example.com")
            signInExpectation.fulfill()
        }
        
        wait(for: [signInExpectation], timeout: 10.0)
    }
    
    func testFirebaseAuthenticationSignOut() throws {
        // First create and sign in a user
        let signUpExpectation = XCTestExpectation(description: "Firebase signup")
        auth.createUser(withEmail: "test@example.com", password: "password123") { _, _ in
            signUpExpectation.fulfill()
        }
        wait(for: [signUpExpectation], timeout: 10.0)
        
        // Verify user is signed in
        XCTAssertNotNil(auth.currentUser)
        
        // Sign out
        try auth.signOut()
        
        // Verify user is signed out
        XCTAssertNil(auth.currentUser)
    }
    
    // MARK: - Firestore Integration Tests
    func testFirestoreUserDocumentCreation() throws {
        // Create a user first
        let signUpExpectation = XCTestExpectation(description: "Firebase signup")
        auth.createUser(withEmail: "test@example.com", password: "password123") { _, _ in
            signUpExpectation.fulfill()
        }
        wait(for: [signUpExpectation], timeout: 10.0)
        
        guard let userId = auth.currentUser?.uid else {
            XCTFail("No current user")
            return
        }
        
        // Create user document
        let expectation = XCTestExpectation(description: "Firestore user creation")
        
        let user = User(
            id: userId,
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
        
        let userRef = firestore.collection("users").document(userId)
        userRef.setData(from: user) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testFirestoreUserDocumentRetrieval() throws {
        // Create a user and document first
        let signUpExpectation = XCTestExpectation(description: "Firebase signup")
        auth.createUser(withEmail: "test@example.com", password: "password123") { _, _ in
            signUpExpectation.fulfill()
        }
        wait(for: [signUpExpectation], timeout: 10.0)
        
        guard let userId = auth.currentUser?.uid else {
            XCTFail("No current user")
            return
        }
        
        // Create user document
        let createExpectation = XCTestExpectation(description: "Firestore user creation")
        let user = User(
            id: userId,
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
        
        let userRef = firestore.collection("users").document(userId)
        userRef.setData(from: user) { error in
            XCTAssertNil(error)
            createExpectation.fulfill()
        }
        wait(for: [createExpectation], timeout: 10.0)
        
        // Retrieve user document
        let retrieveExpectation = XCTestExpectation(description: "Firestore user retrieval")
        
        userRef.getDocument { document, error in
            XCTAssertNil(error)
            XCTAssertNotNil(document)
            XCTAssertTrue(document!.exists)
            
            let retrievedUser = try? document!.data(as: User.self)
            XCTAssertNotNil(retrievedUser)
            XCTAssertEqual(retrievedUser?.email, "test@example.com")
            XCTAssertEqual(retrievedUser?.displayName, "Test User")
            
            retrieveExpectation.fulfill()
        }
        
        wait(for: [retrieveExpectation], timeout: 10.0)
    }
    
    func testFirestoreNewsArticleCreation() throws {
        let expectation = XCTestExpectation(description: "Firestore news article creation")
        
        let article = NewsArticle(
            title: "Test Article",
            content: "Test content",
            author: "Test Author",
            source: "Test Source",
            publishDate: Date(),
            category: .breaking
        )
        
        let articleRef = firestore.collection("news_articles").document()
        articleRef.setData(from: article) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testFirestoreNewsArticleQuery() throws {
        // Create test articles first
        let createExpectation = XCTestExpectation(description: "Firestore news articles creation")
        
        let articles = [
            NewsArticle(
                title: "Breaking News 1",
                content: "First breaking news",
                author: "Author 1",
                source: "Source 1",
                publishDate: Date(),
                category: .breaking
            ),
            NewsArticle(
                title: "Regular News 1",
                content: "First regular news",
                author: "Author 2",
                source: "Source 2",
                publishDate: Date(),
                category: .general
            )
        ]
        
        let batch = firestore.batch()
        for article in articles {
            let docRef = firestore.collection("news_articles").document()
            try batch.setData(from: article, forDocument: docRef)
        }
        
        batch.commit { error in
            XCTAssertNil(error)
            createExpectation.fulfill()
        }
        wait(for: [createExpectation], timeout: 10.0)
        
        // Query articles
        let queryExpectation = XCTestExpectation(description: "Firestore news articles query")
        
        firestore.collection("news_articles")
            .whereField("category", isEqualTo: "breaking")
            .getDocuments { snapshot, error in
                XCTAssertNil(error)
                XCTAssertNotNil(snapshot)
                XCTAssertGreaterThan(snapshot!.documents.count, 0)
                
                let breakingArticles = snapshot!.documents.compactMap { doc in
                    try? doc.data(as: NewsArticle.self)
                }
                
                XCTAssertEqual(breakingArticles.count, 1)
                XCTAssertEqual(breakingArticles.first?.category, .breaking)
                
                queryExpectation.fulfill()
            }
        
        wait(for: [queryExpectation], timeout: 10.0)
    }
    
    func testFirestorePredictionCreation() throws {
        // Create a user first
        let signUpExpectation = XCTestExpectation(description: "Firebase signup")
        auth.createUser(withEmail: "test@example.com", password: "password123") { _, _ in
            signUpExpectation.fulfill()
        }
        wait(for: [signUpExpectation], timeout: 10.0)
        
        guard let userId = auth.currentUser?.uid else {
            XCTFail("No current user")
            return
        }
        
        let expectation = XCTestExpectation(description: "Firestore prediction creation")
        
        let prediction = Prediction(
            userId: userId,
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
        
        let predictionRef = firestore.collection("predictions").document()
        predictionRef.setData(from: prediction) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testFirestorePredictionQuery() throws {
        // Create a user first
        let signUpExpectation = XCTestExpectation(description: "Firebase signup")
        auth.createUser(withEmail: "test@example.com", password: "password123") { _, _ in
            signUpExpectation.fulfill()
        }
        wait(for: [signUpExpectation], timeout: 10.0)
        
        guard let userId = auth.currentUser?.uid else {
            XCTFail("No current user")
            return
        }
        
        // Create test predictions
        let createExpectation = XCTestExpectation(description: "Firestore predictions creation")
        
        let predictions = [
            Prediction(
                userId: userId,
                title: "PPV Prediction 1",
                description: "First PPV prediction",
                category: .ppv,
                eventId: "event1",
                eventName: "Event 1",
                eventDate: Date(),
                status: .draft,
                confidence: 8,
                tags: ["ppv"],
                isPublic: true,
                picks: [],
                accuracy: nil,
                engagement: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Prediction(
                userId: userId,
                title: "Storyline Prediction 1",
                description: "First storyline prediction",
                category: .storyline,
                eventId: "event2",
                eventName: "Event 2",
                eventDate: Date(),
                status: .draft,
                confidence: 6,
                tags: ["storyline"],
                isPublic: true,
                picks: [],
                accuracy: nil,
                engagement: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        let batch = firestore.batch()
        for prediction in predictions {
            let docRef = firestore.collection("predictions").document()
            try batch.setData(from: prediction, forDocument: docRef)
        }
        
        batch.commit { error in
            XCTAssertNil(error)
            createExpectation.fulfill()
        }
        wait(for: [createExpectation], timeout: 10.0)
        
        // Query predictions by user
        let queryExpectation = XCTestExpectation(description: "Firestore predictions query")
        
        firestore.collection("predictions")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                XCTAssertNil(error)
                XCTAssertNotNil(snapshot)
                XCTAssertEqual(snapshot!.documents.count, 2)
                
                let userPredictions = snapshot!.documents.compactMap { doc in
                    try? doc.data(as: Prediction.self)
                }
                
                XCTAssertEqual(userPredictions.count, 2)
                XCTAssertTrue(userPredictions.allSatisfy { $0.userId == userId })
                
                queryExpectation.fulfill()
            }
        
        wait(for: [queryExpectation], timeout: 10.0)
    }
    
    // MARK: - Real-time Updates Tests
    func testFirestoreRealTimeUpdates() throws {
        let expectation = XCTestExpectation(description: "Firestore real-time updates")
        
        let article = NewsArticle(
            title: "Real-time Test Article",
            content: "Test content for real-time updates",
            author: "Test Author",
            source: "Test Source",
            publishDate: Date(),
            category: .breaking
        )
        
        let articleRef = firestore.collection("news_articles").document()
        
        // Set up listener
        let listener = articleRef.addSnapshotListener { snapshot, error in
            XCTAssertNil(error)
            XCTAssertNotNil(snapshot)
            XCTAssertTrue(snapshot!.exists)
            
            let retrievedArticle = try? snapshot!.data(as: NewsArticle.self)
            XCTAssertNotNil(retrievedArticle)
            XCTAssertEqual(retrievedArticle?.title, "Real-time Test Article")
            
            expectation.fulfill()
        }
        
        // Create the document
        articleRef.setData(from: article) { error in
            XCTAssertNil(error)
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Remove listener
        listener.remove()
    }
    
    // MARK: - Batch Operations Tests
    func testFirestoreBatchOperations() throws {
        let expectation = XCTestExpectation(description: "Firestore batch operations")
        
        let batch = firestore.batch()
        
        // Add multiple documents
        let article1 = NewsArticle(
            title: "Batch Article 1",
            content: "First batch article",
            author: "Author 1",
            source: "Source 1",
            publishDate: Date(),
            category: .breaking
        )
        
        let article2 = NewsArticle(
            title: "Batch Article 2",
            content: "Second batch article",
            author: "Author 2",
            source: "Source 2",
            publishDate: Date(),
            category: .general
        )
        
        let docRef1 = firestore.collection("news_articles").document()
        let docRef2 = firestore.collection("news_articles").document()
        
        try batch.setData(from: article1, forDocument: docRef1)
        try batch.setData(from: article2, forDocument: docRef2)
        
        batch.commit { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Error Handling Tests
    func testFirestoreErrorHandling() throws {
        let expectation = XCTestExpectation(description: "Firestore error handling")
        
        // Try to create a document with invalid data
        let invalidData: [String: Any] = [
            "invalidField": "invalidValue"
        ]
        
        firestore.collection("test_collection").document().setData(invalidData) { error in
            // This should succeed in the emulator, but in real Firestore it might fail
            // depending on security rules
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Security Rules Tests
    func testFirestoreSecurityRules() throws {
        // Create a user first
        let signUpExpectation = XCTestExpectation(description: "Firebase signup")
        auth.createUser(withEmail: "test@example.com", password: "password123") { _, _ in
            signUpExpectation.fulfill()
        }
        wait(for: [signUpExpectation], timeout: 10.0)
        
        guard let userId = auth.currentUser?.uid else {
            XCTFail("No current user")
            return
        }
        
        // Test user can create their own document
        let createExpectation = XCTestExpectation(description: "Firestore user document creation")
        
        let user = User(
            id: userId,
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
        
        let userRef = firestore.collection("users").document(userId)
        userRef.setData(from: user) { error in
            XCTAssertNil(error)
            createExpectation.fulfill()
        }
        
        wait(for: [createExpectation], timeout: 10.0)
    }
    
    // MARK: - Performance Tests
    func testFirestoreQueryPerformance() throws {
        let expectation = XCTestExpectation(description: "Firestore query performance")
        
        let startTime = Date()
        
        firestore.collection("news_articles")
            .limit(10)
            .getDocuments { snapshot, error in
                let endTime = Date()
                let queryTime = endTime.timeIntervalSince(startTime)
                
                XCTAssertNil(error)
                XCTAssertNotNil(snapshot)
                XCTAssertLessThan(queryTime, 5.0) // Query should complete within 5 seconds
                
                expectation.fulfill()
            }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Cleanup Tests
    func testFirestoreDataCleanup() throws {
        let expectation = XCTestExpectation(description: "Firestore data cleanup")
        
        // Create test document
        let testDoc = firestore.collection("test_cleanup").document()
        testDoc.setData(["test": "data"]) { error in
            XCTAssertNil(error)
            
            // Delete the document
            testDoc.delete { error in
                XCTAssertNil(error)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}
