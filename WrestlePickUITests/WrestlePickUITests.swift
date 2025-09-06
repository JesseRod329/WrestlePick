import XCTest

final class WrestlePickUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Authentication Flow Tests
    func testUserSignUpFlow() throws {
        // Test the complete signup flow
        let signUpButton = app.buttons["Sign Up"]
        XCTAssertTrue(signUpButton.exists)
        signUpButton.tap()
        
        // Fill in signup form
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        let displayNameField = app.textFields["Display Name"]
        
        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(passwordField.exists)
        XCTAssertTrue(confirmPasswordField.exists)
        XCTAssertTrue(displayNameField.exists)
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        confirmPasswordField.tap()
        confirmPasswordField.typeText("password123")
        
        displayNameField.tap()
        displayNameField.typeText("Test User")
        
        // Submit signup
        let submitButton = app.buttons["Create Account"]
        XCTAssertTrue(submitButton.exists)
        submitButton.tap()
        
        // Verify success (would need to check for success message or navigation)
        // This would depend on the actual UI implementation
    }
    
    func testUserSignInFlow() throws {
        // Test the complete signin flow
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.exists)
        signInButton.tap()
        
        // Fill in signin form
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(passwordField.exists)
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Submit signin
        let submitButton = app.buttons["Sign In"]
        XCTAssertTrue(submitButton.exists)
        submitButton.tap()
        
        // Verify successful signin (check for main app interface)
        let mainTabBar = app.tabBars.firstMatch
        XCTAssertTrue(mainTabBar.waitForExistence(timeout: 5.0))
    }
    
    func testGuestModeFlow() throws {
        // Test guest mode access
        let guestButton = app.buttons["Continue as Guest"]
        XCTAssertTrue(guestButton.exists)
        guestButton.tap()
        
        // Verify guest mode limitations
        let mainTabBar = app.tabBars.firstMatch
        XCTAssertTrue(mainTabBar.waitForExistence(timeout: 5.0))
        
        // Check that premium features are disabled
        let predictionsTab = app.tabBars.buttons["Predictions"]
        predictionsTab.tap()
        
        // Verify guest limitations are shown
        let upgradePrompt = app.staticTexts["Upgrade to Premium"]
        XCTAssertTrue(upgradePrompt.exists)
    }
    
    // MARK: - News Feed Tests
    func testNewsFeedNavigation() throws {
        // Sign in first
        signInUser()
        
        // Navigate to news feed
        let newsTab = app.tabBars.buttons["News"]
        XCTAssertTrue(newsTab.exists)
        newsTab.tap()
        
        // Verify news feed elements
        let newsFeed = app.collectionViews.firstMatch
        XCTAssertTrue(newsFeed.waitForExistence(timeout: 5.0))
        
        // Test pull to refresh
        let firstCell = newsFeed.cells.firstMatch
        if firstCell.exists {
            firstCell.swipeDown()
        }
        
        // Test search functionality
        let searchBar = app.searchFields.firstMatch
        if searchBar.exists {
            searchBar.tap()
            searchBar.typeText("wrestling")
            
            // Verify search results
            let searchResults = newsFeed.cells
            XCTAssertGreaterThan(searchResults.count, 0)
        }
    }
    
    func testNewsArticleInteraction() throws {
        // Sign in first
        signInUser()
        
        // Navigate to news feed
        let newsTab = app.tabBars.buttons["News"]
        newsTab.tap()
        
        // Tap on first article
        let newsFeed = app.collectionViews.firstMatch
        let firstArticle = newsFeed.cells.firstMatch
        XCTAssertTrue(firstArticle.waitForExistence(timeout: 5.0))
        firstArticle.tap()
        
        // Verify article detail view
        let articleTitle = app.staticTexts.matching(identifier: "article_title").firstMatch
        XCTAssertTrue(articleTitle.waitForExistence(timeout: 5.0))
        
        // Test like button
        let likeButton = app.buttons["Like"]
        if likeButton.exists {
            likeButton.tap()
        }
        
        // Test bookmark button
        let bookmarkButton = app.buttons["Bookmark"]
        if bookmarkButton.exists {
            bookmarkButton.tap()
        }
        
        // Test share button
        let shareButton = app.buttons["Share"]
        if shareButton.exists {
            shareButton.tap()
            
            // Verify share sheet appears
            let shareSheet = app.sheets.firstMatch
            XCTAssertTrue(shareSheet.waitForExistence(timeout: 2.0))
            
            // Dismiss share sheet
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }
    }
    
    // MARK: - Prediction Tests
    func testPredictionCreation() throws {
        // Sign in first
        signInUser()
        
        // Navigate to predictions
        let predictionsTab = app.tabBars.buttons["Predictions"]
        predictionsTab.tap()
        
        // Tap create prediction button
        let createButton = app.buttons["Create Prediction"]
        XCTAssertTrue(createButton.exists)
        createButton.tap()
        
        // Fill in prediction form
        let titleField = app.textFields["Prediction Title"]
        let descriptionField = app.textViews["Description"]
        let categoryPicker = app.pickers["Category"]
        let confidenceSlider = app.sliders["Confidence"]
        
        XCTAssertTrue(titleField.exists)
        XCTAssertTrue(descriptionField.exists)
        XCTAssertTrue(categoryPicker.exists)
        XCTAssertTrue(confidenceSlider.exists)
        
        titleField.tap()
        titleField.typeText("Test Prediction")
        
        descriptionField.tap()
        descriptionField.typeText("This is a test prediction")
        
        // Set confidence level
        confidenceSlider.adjust(toNormalizedSliderPosition: 0.8)
        
        // Save prediction
        let saveButton = app.buttons["Save Prediction"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()
        
        // Verify prediction was created
        let predictionList = app.collectionViews.firstMatch
        XCTAssertTrue(predictionList.waitForExistence(timeout: 5.0))
    }
    
    func testPredictionInteraction() throws {
        // Sign in first
        signInUser()
        
        // Navigate to predictions
        let predictionsTab = app.tabBars.buttons["Predictions"]
        predictionsTab.tap()
        
        // Tap on first prediction
        let predictionList = app.collectionViews.firstMatch
        let firstPrediction = predictionList.cells.firstMatch
        XCTAssertTrue(firstPrediction.waitForExistence(timeout: 5.0))
        firstPrediction.tap()
        
        // Test prediction actions
        let likeButton = app.buttons["Like"]
        if likeButton.exists {
            likeButton.tap()
        }
        
        let commentButton = app.buttons["Comment"]
        if commentButton.exists {
            commentButton.tap()
            
            // Test comment functionality
            let commentField = app.textViews["Comment"]
            if commentField.exists {
                commentField.tap()
                commentField.typeText("Great prediction!")
                
                let postButton = app.buttons["Post"]
                if postButton.exists {
                    postButton.tap()
                }
            }
        }
        
        let shareButton = app.buttons["Share"]
        if shareButton.exists {
            shareButton.tap()
        }
    }
    
    // MARK: - Profile Tests
    func testProfileView() throws {
        // Sign in first
        signInUser()
        
        // Navigate to profile
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.exists)
        profileTab.tap()
        
        // Verify profile elements
        let profileView = app.scrollViews.firstMatch
        XCTAssertTrue(profileView.waitForExistence(timeout: 5.0))
        
        // Test edit profile
        let editButton = app.buttons["Edit Profile"]
        if editButton.exists {
            editButton.tap()
            
            // Test profile editing
            let displayNameField = app.textFields["Display Name"]
            if displayNameField.exists {
                displayNameField.tap()
                displayNameField.clearText()
                displayNameField.typeText("Updated Name")
            }
            
            let saveButton = app.buttons["Save"]
            if saveButton.exists {
                saveButton.tap()
            }
        }
        
        // Test settings
        let settingsButton = app.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.tap()
            
            // Verify settings view
            let settingsView = app.navigationBars["Settings"]
            XCTAssertTrue(settingsView.waitForExistence(timeout: 2.0))
            
            // Go back
            let backButton = app.navigationBars.buttons["Back"]
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    // MARK: - Subscription Tests
    func testSubscriptionFlow() throws {
        // Sign in first
        signInUser()
        
        // Navigate to a premium feature
        let predictionsTab = app.tabBars.buttons["Predictions"]
        predictionsTab.tap()
        
        // Try to access premium feature
        let premiumFeature = app.buttons["Premium Feature"]
        if premiumFeature.exists {
            premiumFeature.tap()
            
            // Verify paywall appears
            let paywallView = app.otherElements["PaywallView"]
            XCTAssertTrue(paywallView.waitForExistence(timeout: 5.0))
            
            // Test subscription selection
            let monthlyPlan = app.buttons["Premium Monthly"]
            if monthlyPlan.exists {
                monthlyPlan.tap()
            }
            
            // Test purchase flow (would need to mock StoreKit)
            let purchaseButton = app.buttons["Start Free Trial"]
            if purchaseButton.exists {
                purchaseButton.tap()
            }
        }
    }
    
    // MARK: - Accessibility Tests
    func testVoiceOverSupport() throws {
        // Enable VoiceOver for testing
        // This would need to be done in the test setup
        
        // Test navigation with VoiceOver
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // Test that all tab bar items are accessible
        let newsTab = tabBar.buttons["News"]
        XCTAssertTrue(newsTab.isAccessibilityElement)
        
        let predictionsTab = tabBar.buttons["Predictions"]
        XCTAssertTrue(predictionsTab.isAccessibilityElement)
        
        let profileTab = tabBar.buttons["Profile"]
        XCTAssertTrue(profileTab.isAccessibilityElement)
    }
    
    func testDynamicTypeSupport() throws {
        // Test with different text sizes
        // This would need to be done in the test setup
        
        // Verify text scales properly
        let newsTab = app.tabBars.buttons["News"]
        newsTab.tap()
        
        let newsFeed = app.collectionViews.firstMatch
        let firstArticle = newsFeed.cells.firstMatch
        if firstArticle.exists {
            XCTAssertTrue(firstArticle.isAccessibilityElement)
        }
    }
    
    // MARK: - Performance Tests
    func testAppLaunchPerformance() throws {
        // Measure app launch time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    func testScrollPerformance() throws {
        // Sign in first
        signInUser()
        
        // Navigate to news feed
        let newsTab = app.tabBars.buttons["News"]
        newsTab.tap()
        
        // Test scrolling performance
        let newsFeed = app.collectionViews.firstMatch
        XCTAssertTrue(newsFeed.waitForExistence(timeout: 5.0))
        
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            newsFeed.swipeUp(velocity: .fast)
            newsFeed.swipeUp(velocity: .fast)
            newsFeed.swipeUp(velocity: .fast)
        }
    }
    
    // MARK: - Helper Methods
    private func signInUser() {
        // Check if already signed in
        let mainTabBar = app.tabBars.firstMatch
        if mainTabBar.exists {
            return
        }
        
        // Sign in
        let signInButton = app.buttons["Sign In"]
        if signInButton.exists {
            signInButton.tap()
            
            let emailField = app.textFields["Email"]
            let passwordField = app.secureTextFields["Password"]
            
            if emailField.exists && passwordField.exists {
                emailField.tap()
                emailField.typeText("test@example.com")
                
                passwordField.tap()
                passwordField.typeText("password123")
                
                let submitButton = app.buttons["Sign In"]
                if submitButton.exists {
                    submitButton.tap()
                }
            }
        }
    }
}

// MARK: - Test Extensions
extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}

// MARK: - Accessibility Test Helpers
class AccessibilityTestHelper {
    static func verifyAccessibilityLabels(_ elements: [XCUIElement]) {
        for element in elements {
            XCTAssertTrue(element.isAccessibilityElement, "Element should be accessible")
            XCTAssertNotNil(element.label, "Element should have accessibility label")
        }
    }
    
    static func verifyAccessibilityTraits(_ element: XCUIElement, expectedTraits: [UIAccessibilityTraits]) {
        for trait in expectedTraits {
            XCTAssertTrue(element.accessibilityTraits.contains(trait), "Element should have trait: \(trait)")
        }
    }
}
