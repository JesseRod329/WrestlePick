import Foundation
// import FirebaseFirestore

struct FirestoreCollections {
    static let users = "users"
    static let newsArticles = "news_articles"
    static let predictions = "predictions"
    static let awards = "awards"
    static let votes = "votes"
    static let merchItems = "merch_items"
    static let merchReviews = "merch_reviews"
    static let wishlists = "wishlists"
    static let events = "events"
    static let matches = "matches"
    static let wrestlers = "wrestlers"
    static let titles = "titles"
    static let rssFeeds = "rss_feeds"
    static let rssFeedItems = "rss_feed_items"
    static let notifications = "notifications"
    static let leaderboards = "leaderboards"
    static let badges = "badges"
    static let comments = "comments"
    static let likes = "likes"
    static let follows = "follows"
    static let reports = "reports"
    static let analytics = "analytics"
}

struct FirestoreSubcollections {
    struct User {
        static let predictions = "predictions"
        static let awards = "awards"
        static let wishlists = "wishlists"
        static let followers = "followers"
        static let following = "following"
        static let notifications = "notifications"
        static let settings = "settings"
    }
    
    struct Event {
        static let matches = "matches"
        static let predictions = "predictions"
        static let comments = "comments"
    }
    
    struct NewsArticle {
        static let comments = "comments"
        static let likes = "likes"
        static let shares = "shares"
    }
    
    struct Prediction {
        static let comments = "comments"
        static let likes = "likes"
        static let picks = "picks"
    }
    
    struct Award {
        static let nominees = "nominees"
        static let votes = "votes"
        static let comments = "comments"
    }
}

// MARK: - Firestore Query Helpers
extension Firestore {
    func users() -> CollectionReference {
        return collection(FirestoreCollections.users)
    }
    
    func newsArticles() -> CollectionReference {
        return collection(FirestoreCollections.newsArticles)
    }
    
    func predictions() -> CollectionReference {
        return collection(FirestoreCollections.predictions)
    }
    
    func awards() -> CollectionReference {
        return collection(FirestoreCollections.awards)
    }
    
    func votes() -> CollectionReference {
        return collection(FirestoreCollections.votes)
    }
    
    func merchItems() -> CollectionReference {
        return collection(FirestoreCollections.merchItems)
    }
    
    func events() -> CollectionReference {
        return collection(FirestoreCollections.events)
    }
    
    func rssFeeds() -> CollectionReference {
        return collection(FirestoreCollections.rssFeeds)
    }
    
    func notifications() -> CollectionReference {
        return collection(FirestoreCollections.notifications)
    }
    
    func leaderboards() -> CollectionReference {
        return collection(FirestoreCollections.leaderboards)
    }
}

// MARK: - Firestore Indexes Configuration
struct FirestoreIndexes {
    // Users indexes
    static let usersByUsername = "users_by_username"
    static let usersByEmail = "users_by_email"
    static let usersByJoinDate = "users_by_join_date"
    static let usersByPredictionAccuracy = "users_by_prediction_accuracy"
    
    // News Articles indexes
    static let newsByCategory = "news_by_category"
    static let newsByPublishDate = "news_by_publish_date"
    static let newsByReliabilityScore = "news_by_reliability_score"
    static let newsByEngagement = "news_by_engagement"
    
    // Predictions indexes
    static let predictionsByUser = "predictions_by_user"
    static let predictionsByEvent = "predictions_by_event"
    static let predictionsByStatus = "predictions_by_status"
    static let predictionsByCreatedDate = "predictions_by_created_date"
    
    // Awards indexes
    static let awardsByCategory = "awards_by_category"
    static let awardsByYear = "awards_by_year"
    static let awardsByStatus = "awards_by_status"
    static let awardsByCreator = "awards_by_creator"
    
    // Events indexes
    static let eventsByPromotion = "events_by_promotion"
    static let eventsByDate = "events_by_date"
    static let eventsByType = "events_by_type"
    static let eventsByStatus = "events_by_status"
    
    // Merch Items indexes
    static let merchByCategory = "merch_by_category"
    static let merchByPopularity = "merch_by_popularity"
    static let merchByPrice = "merch_by_price"
    static let merchByAvailability = "merch_by_availability"
}

// MARK: - Firestore Security Rules Structure
struct FirestoreSecurityRules {
    static let rules = """
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        // Users collection
        match /users/{userId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
          allow read: if resource.data.isPublic == true;
        }
        
        // News Articles collection
        match /news_articles/{articleId} {
          allow read: if true;
          allow write: if request.auth != null && request.auth.token.admin == true;
        }
        
        // Predictions collection
        match /predictions/{predictionId} {
          allow read: if true;
          allow create: if request.auth != null && request.auth.uid == resource.data.userId;
          allow update: if request.auth != null && request.auth.uid == resource.data.userId;
          allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
        }
        
        // Awards collection
        match /awards/{awardId} {
          allow read: if true;
          allow create: if request.auth != null;
          allow update: if request.auth != null && request.auth.uid == resource.data.createdBy;
          allow delete: if request.auth != null && request.auth.uid == resource.data.createdBy;
        }
        
        // Votes collection
        match /votes/{voteId} {
          allow read: if true;
          allow create: if request.auth != null && request.auth.uid == resource.data.userId;
          allow update: if request.auth != null && request.auth.uid == resource.data.userId;
          allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
        }
        
        // Merch Items collection
        match /merch_items/{itemId} {
          allow read: if true;
          allow write: if request.auth != null && request.auth.token.admin == true;
        }
        
        // Events collection
        match /events/{eventId} {
          allow read: if true;
          allow write: if request.auth != null && request.auth.token.admin == true;
        }
        
        // RSS Feeds collection
        match /rss_feeds/{feedId} {
          allow read: if true;
          allow write: if request.auth != null && request.auth.token.admin == true;
        }
        
        // Notifications collection
        match /notifications/{notificationId} {
          allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
        }
        
        // Leaderboards collection
        match /leaderboards/{leaderboardId} {
          allow read: if true;
          allow write: if request.auth != null && request.auth.token.admin == true;
        }
      }
    }
    """
}
