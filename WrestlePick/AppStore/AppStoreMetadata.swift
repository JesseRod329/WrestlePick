import Foundation

// MARK: - App Store Metadata
struct AppStoreMetadata {
    static let appName = "WrestlePick"
    static let bundleIdentifier = "com.wrestlepick.app"
    static let version = "1.0.0"
    static let buildNumber = "1"
    
    // MARK: - App Store Description
    static let shortDescription = "The ultimate wrestling prediction app for fans who think they can book better than WWE!"
    
    static let fullDescription = """
    Think you can book better than WWE? Prove it with WrestlePick - the ultimate wrestling prediction app for die-hard fans!
    
    🏆 MAKE PREDICTIONS LIKE A PRO
    • Predict PPV match winners and outcomes
    • Create monthly themed predictions (Wrestler of the Month, etc.)
    • Make long-term storyline predictions
    • Choose between "Hot Take" vs "Safe Pick" categories
    • Create custom prediction contests with friends
    
    📊 TRACK YOUR ACCURACY
    • Real-time accuracy tracking and leaderboards
    • Weekly, monthly, and all-time rankings
    • Confidence level scoring (1-10)
    • Detailed statistics and analytics
    • Achievement system with badges and rewards
    
    🎭 FANTASY BOOKING MODE
    • Drag-and-drop match card builder
    • Create detailed storylines with multi-show planning
    • "What if" scenario simulator
    • Compare your fantasy bookings with real results
    • Community voting on fantasy bookings
    
    📰 BREAKING NEWS & RUMORS
    • Real-time wrestling news from top sources
    • Reliability scoring system (Tier 1, Tier 2, Speculation)
    • Push notifications for breaking news
    • Offline reading capability
    • Filter by promotion (WWE, AEW, NJPW, etc.)
    
    🛍️ MERCH TRACKER
    • Community-driven merchandise reporting
    • Popular items leaderboard
    • Price tracking and alerts
    • Availability notifications
    • Sales velocity tracking
    
    👥 SOCIAL FEATURES
    • Follow other wrestling fans
    • Comment on predictions and news
    • Group prediction leagues with friends
    • Share your achievements
    • Create user-generated wrestling awards
    
    🏅 PREMIUM FEATURES
    • Unlimited predictions and contests
    • Advanced fantasy booking tools
    • Early access to exclusive content
    • Ad-free experience
    • Advanced statistics and analytics
    • Custom prediction categories
    • Priority customer support
    
    Whether you're a casual fan or a wrestling expert, WrestlePick is the perfect app to test your knowledge, make predictions, and connect with the wrestling community. Download now and show the world who can book better!
    
    Features:
    • Real-time news and rumors
    • Prediction accuracy tracking
    • Fantasy booking mode
    • Merchandise tracking
    • Social features and community
    • Premium subscription available
    • Offline functionality
    • Push notifications
    • Dark mode support
    • Accessibility features
    """
    
    // MARK: - Keywords
    static let keywords = [
        "wrestling",
        "predictions",
        "fantasy",
        "booking",
        "wwe",
        "aew",
        "njpw",
        "rumors",
        "news",
        "community",
        "social",
        "leaderboard",
        "accuracy",
        "merchandise",
        "ppv",
        "storylines",
        "championships",
        "fans",
        "sports",
        "entertainment"
    ].joined(separator: ", ")
    
    // MARK: - App Store Connect Information
    static let appStoreConnectInfo = AppStoreConnectInfo(
        primaryCategory: "Sports",
        secondaryCategory: "Entertainment",
        ageRating: "12+",
        contentDescriptors: [
            "Frequent/Intense Simulated Gambling",
            "Frequent/Intense Cartoon or Fantasy Violence",
            "Frequent/Intense Mature/Suggestive Themes"
        ],
        privacyPolicyURL: "https://wrestlepick.app/privacy",
        termsOfServiceURL: "https://wrestlepick.app/terms",
        supportURL: "https://wrestlepick.app/support",
        marketingURL: "https://wrestlepick.app"
    )
    
    // MARK: - Localization
    static let supportedLanguages = [
        "en-US", // English (United States)
        "en-GB", // English (United Kingdom)
        "en-CA", // English (Canada)
        "en-AU", // English (Australia)
        "es-US", // Spanish (United States)
        "es-ES", // Spanish (Spain)
        "fr-FR", // French (France)
        "fr-CA", // French (Canada)
        "de-DE", // German (Germany)
        "it-IT", // Italian (Italy)
        "pt-BR", // Portuguese (Brazil)
        "ja-JP", // Japanese (Japan)
        "ko-KR", // Korean (South Korea)
        "zh-CN", // Chinese (Simplified, China)
        "zh-TW"  // Chinese (Traditional, Taiwan)
    ]
    
    // MARK: - Screenshots
    static let screenshots = ScreenshotMetadata(
        iPhone65: [
            "screenshot_1_iphone65.png",
            "screenshot_2_iphone65.png",
            "screenshot_3_iphone65.png",
            "screenshot_4_iphone65.png",
            "screenshot_5_iphone65.png"
        ],
        iPhone67: [
            "screenshot_1_iphone67.png",
            "screenshot_2_iphone67.png",
            "screenshot_3_iphone67.png",
            "screenshot_4_iphone67.png",
            "screenshot_5_iphone67.png"
        ],
        iPhone61: [
            "screenshot_1_iphone61.png",
            "screenshot_2_iphone61.png",
            "screenshot_3_iphone61.png",
            "screenshot_4_iphone61.png",
            "screenshot_5_iphone61.png"
        ],
        iPadPro: [
            "screenshot_1_ipadpro.png",
            "screenshot_2_ipadpro.png",
            "screenshot_3_ipadpro.png",
            "screenshot_4_ipadpro.png",
            "screenshot_5_ipadpro.png"
        ],
        iPad: [
            "screenshot_1_ipad.png",
            "screenshot_2_ipad.png",
            "screenshot_3_ipad.png",
            "screenshot_4_ipad.png",
            "screenshot_5_ipad.png"
        ]
    )
    
    // MARK: - App Store Review Information
    static let reviewInfo = AppStoreReviewInfo(
        contactEmail: "review@wrestlepick.app",
        contactPhone: "+1-555-WRESTLE",
        demoAccount: DemoAccount(
            username: "reviewer@wrestlepick.app",
            password: "Review123!",
            instructions: "Use this demo account to test all features. Premium features are enabled for testing purposes."
        ),
        notes: """
        Thank you for reviewing WrestlePick! Here are some key features to test:
        
        1. Sign up with email or use Apple Sign In
        2. Browse the news feed and try filtering by promotion
        3. Create a prediction for an upcoming PPV
        4. Try the fantasy booking mode
        5. Check out the merchandise tracker
        6. Test the social features (comments, likes, shares)
        7. Explore the premium features (subscription required)
        
        The app includes comprehensive accessibility features including VoiceOver support, Dynamic Type, and high contrast mode.
        
        All user data is handled securely with Firebase, and the app respects user privacy with comprehensive privacy controls.
        """
    )
}

// MARK: - App Store Connect Info
struct AppStoreConnectInfo {
    let primaryCategory: String
    let secondaryCategory: String
    let ageRating: String
    let contentDescriptors: [String]
    let privacyPolicyURL: String
    let termsOfServiceURL: String
    let supportURL: String
    let marketingURL: String
}

// MARK: - Screenshot Metadata
struct ScreenshotMetadata {
    let iPhone65: [String] // iPhone 6.5" (iPhone 11 Pro Max, 12 Pro Max, 13 Pro Max, 14 Plus)
    let iPhone67: [String] // iPhone 6.7" (iPhone 12 Pro Max, 13 Pro Max, 14 Pro Max)
    let iPhone61: [String] // iPhone 6.1" (iPhone 12, 13, 14)
    let iPadPro: [String]  // iPad Pro 12.9"
    let iPad: [String]     // iPad 10.2"
}

// MARK: - App Store Review Info
struct AppStoreReviewInfo {
    let contactEmail: String
    let contactPhone: String
    let demoAccount: DemoAccount
    let notes: String
}

// MARK: - Demo Account
struct DemoAccount {
    let username: String
    let password: String
    let instructions: String
}

// MARK: - App Store Configuration
struct AppStoreConfiguration {
    static let configuration = """
    {
        "app_name": "WrestlePick",
        "bundle_identifier": "com.wrestlepick.app",
        "version": "1.0.0",
        "build_number": "1",
        "primary_category": "Sports",
        "secondary_category": "Entertainment",
        "age_rating": "12+",
        "content_descriptors": [
            "Frequent/Intense Simulated Gambling",
            "Frequent/Intense Cartoon or Fantasy Violence",
            "Frequent/Intense Mature/Suggestive Themes"
        ],
        "keywords": "wrestling, predictions, fantasy, booking, wwe, aew, njpw, rumors, news, community, social, leaderboard, accuracy, merchandise, ppv, storylines, championships, fans, sports, entertainment",
        "short_description": "The ultimate wrestling prediction app for fans who think they can book better than WWE!",
        "privacy_policy_url": "https://wrestlepick.app/privacy",
        "terms_of_service_url": "https://wrestlepick.app/terms",
        "support_url": "https://wrestlepick.app/support",
        "marketing_url": "https://wrestlepick.app",
        "supported_languages": [
            "en-US",
            "en-GB",
            "en-CA",
            "en-AU",
            "es-US",
            "es-ES",
            "fr-FR",
            "fr-CA",
            "de-DE",
            "it-IT",
            "pt-BR",
            "ja-JP",
            "ko-KR",
            "zh-CN",
            "zh-TW"
        ],
        "screenshots": {
            "iphone65": [
                "screenshot_1_iphone65.png",
                "screenshot_2_iphone65.png",
                "screenshot_3_iphone65.png",
                "screenshot_4_iphone65.png",
                "screenshot_5_iphone65.png"
            ],
            "iphone67": [
                "screenshot_1_iphone67.png",
                "screenshot_2_iphone67.png",
                "screenshot_3_iphone67.png",
                "screenshot_4_iphone67.png",
                "screenshot_5_iphone67.png"
            ],
            "iphone61": [
                "screenshot_1_iphone61.png",
                "screenshot_2_iphone61.png",
                "screenshot_3_iphone61.png",
                "screenshot_4_iphone61.png",
                "screenshot_5_iphone61.png"
            ],
            "ipadpro": [
                "screenshot_1_ipadpro.png",
                "screenshot_2_ipadpro.png",
                "screenshot_3_ipadpro.png",
                "screenshot_4_ipadpro.png",
                "screenshot_5_ipadpro.png"
            ],
            "ipad": [
                "screenshot_1_ipad.png",
                "screenshot_2_ipad.png",
                "screenshot_3_ipad.png",
                "screenshot_4_ipad.png",
                "screenshot_5_ipad.png"
            ]
        },
        "review_info": {
            "contact_email": "review@wrestlepick.app",
            "contact_phone": "+1-555-WRESTLE",
            "demo_account": {
                "username": "reviewer@wrestlepick.app",
                "password": "Review123!",
                "instructions": "Use this demo account to test all features. Premium features are enabled for testing purposes."
            },
            "notes": "Thank you for reviewing WrestlePick! Here are some key features to test: 1. Sign up with email or use Apple Sign In 2. Browse the news feed and try filtering by promotion 3. Create a prediction for an upcoming PPV 4. Try the fantasy booking mode 5. Check out the merchandise tracker 6. Test the social features (comments, likes, shares) 7. Explore the premium features (subscription required). The app includes comprehensive accessibility features including VoiceOver support, Dynamic Type, and high contrast mode. All user data is handled securely with Firebase, and the app respects user privacy with comprehensive privacy controls."
        }
    }
    """
}
