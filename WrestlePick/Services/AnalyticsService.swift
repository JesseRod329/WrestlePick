import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import Combine
import os.log

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var sessionStartTime: Date?
    @Published var currentSessionLength: TimeInterval = 0
    @Published var totalSessions: Int = 0
    @Published var totalScreenViews: Int = 0
    @Published var totalEvents: Int = 0
    
    private let logger = Logger(subsystem: "com.wrestlepick", category: "Analytics")
    private var cancellables = Set<AnyCancellable>()
    private var sessionTimer: Timer?
    private var backgroundTime: Date?
    
    // Analytics data
    private var userEngagement: UserEngagement = UserEngagement()
    private var predictionAnalytics: PredictionAnalytics = PredictionAnalytics()
    private var contentAnalytics: ContentAnalytics = ContentAnalytics()
    private var conversionFunnel: ConversionFunnel = ConversionFunnel()
    private var abTestResults: [String: ABTestResult] = [:]
    
    private init() {
        setupAnalytics()
        startSession()
    }
    
    deinit {
        endSession()
    }
    
    // MARK: - Setup
    private func setupAnalytics() {
        // Configure Firebase Analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Set user properties
        setUserProperties()
        
        // Start session tracking
        startSessionTracking()
    }
    
    private func setUserProperties() {
        // Set user properties for segmentation
        Analytics.setUserProperty("ios", forName: "platform")
        Analytics.setUserProperty(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, forName: "app_version")
        
        // Set user engagement properties
        Analytics.setUserProperty("\(userEngagement.totalSessions)", forName: "total_sessions")
        Analytics.setUserProperty("\(userEngagement.totalScreenViews)", forName: "total_screen_views")
        Analytics.setUserProperty("\(userEngagement.averageSessionLength)", forName: "avg_session_length")
    }
    
    // MARK: - Session Management
    func startSession() {
        sessionStartTime = Date()
        totalSessions += 1
        
        // Start session timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionLength()
        }
        
        // Track session start
        trackEvent("session_start", parameters: [
            "session_id": UUID().uuidString,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        logger.info("Session started")
    }
    
    func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionLength = Date().timeIntervalSince(startTime)
        userEngagement.recordSession(sessionLength)
        
        // Stop session timer
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        // Track session end
        trackEvent("session_end", parameters: [
            "session_length": sessionLength,
            "screen_views": totalScreenViews,
            "events": totalEvents
        ])
        
        // Update user properties
        setUserProperties()
        
        logger.info("Session ended - Length: \(sessionLength) seconds")
    }
    
    private func updateSessionLength() {
        guard let startTime = sessionStartTime else { return }
        currentSessionLength = Date().timeIntervalSince(startTime)
    }
    
    private func startSessionTracking() {
        // Track app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        backgroundTime = Date()
        endSession()
    }
    
    @objc private func appWillEnterForeground() {
        if let backgroundTime = backgroundTime {
            let backgroundDuration = Date().timeIntervalSince(backgroundTime)
            
            // If app was in background for more than 30 minutes, start new session
            if backgroundDuration > 30 * 60 {
                startSession()
            }
        }
        
        backgroundTime = nil
    }
    
    // MARK: - Screen Tracking
    func trackScreenView(_ screenName: String, parameters: [String: Any] = [:]) {
        totalScreenViews += 1
        userEngagement.recordScreenView(screenName)
        
        // Firebase Analytics
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenName
        ])
        
        // Custom parameters
        if !parameters.isEmpty {
            trackEvent("screen_view", parameters: parameters.merging([
                "screen_name": screenName,
                "timestamp": Date().timeIntervalSince1970
            ]) { _, new in new })
        }
        
        logger.info("Screen viewed: \(screenName)")
    }
    
    // MARK: - Event Tracking
    func trackEvent(_ eventName: String, parameters: [String: Any] = [:]) {
        totalEvents += 1
        
        // Firebase Analytics
        Analytics.logEvent(eventName, parameters: parameters)
        
        // Custom event tracking
        let event = AnalyticsEvent(
            name: eventName,
            parameters: parameters,
            timestamp: Date()
        )
        
        processEvent(event)
        
        logger.info("Event tracked: \(eventName)")
    }
    
    private func processEvent(_ event: AnalyticsEvent) {
        // Process different types of events
        switch event.name {
        case "prediction_created":
            predictionAnalytics.recordPredictionCreated(event.parameters)
        case "prediction_resolved":
            predictionAnalytics.recordPredictionResolved(event.parameters)
        case "content_viewed":
            contentAnalytics.recordContentView(event.parameters)
        case "user_engagement":
            userEngagement.recordEngagement(event.parameters)
        case "conversion_funnel":
            conversionFunnel.recordStep(event.parameters)
        default:
            break
        }
    }
    
    // MARK: - User Engagement Tracking
    func trackUserEngagement(_ action: String, context: String = "") {
        userEngagement.recordAction(action, context: context)
        
        trackEvent("user_engagement", parameters: [
            "action": action,
            "context": context,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackFeatureUsage(_ feature: String, duration: TimeInterval? = nil) {
        userEngagement.recordFeatureUsage(feature, duration: duration)
        
        var parameters: [String: Any] = [
            "feature": feature,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let duration = duration {
            parameters["duration"] = duration
        }
        
        trackEvent("feature_usage", parameters: parameters)
    }
    
    // MARK: - Prediction Analytics
    func trackPredictionCreated(_ prediction: Prediction) {
        predictionAnalytics.recordPredictionCreated([
            "prediction_id": prediction.id ?? "",
            "category": prediction.category,
            "confidence": prediction.confidence,
            "is_public": prediction.isPublic
        ])
        
        trackEvent("prediction_created", parameters: [
            "prediction_id": prediction.id ?? "",
            "category": prediction.category,
            "confidence": prediction.confidence,
            "is_public": prediction.isPublic
        ])
    }
    
    func trackPredictionResolved(_ prediction: Prediction, wasCorrect: Bool) {
        predictionAnalytics.recordPredictionResolved([
            "prediction_id": prediction.id ?? "",
            "was_correct": wasCorrect,
            "accuracy": prediction.accuracy?.overallAccuracy ?? 0.0
        ])
        
        trackEvent("prediction_resolved", parameters: [
            "prediction_id": prediction.id ?? "",
            "was_correct": wasCorrect,
            "accuracy": prediction.accuracy?.overallAccuracy ?? 0.0
        ])
    }
    
    // MARK: - Content Analytics
    func trackContentView(_ contentId: String, contentType: String, duration: TimeInterval? = nil) {
        contentAnalytics.recordContentView([
            "content_id": contentId,
            "content_type": contentType,
            "duration": duration ?? 0
        ])
        
        var parameters: [String: Any] = [
            "content_id": contentId,
            "content_type": contentType
        ]
        
        if let duration = duration {
            parameters["duration"] = duration
        }
        
        trackEvent("content_view", parameters: parameters)
    }
    
    func trackContentInteraction(_ contentId: String, action: String) {
        contentAnalytics.recordInteraction(contentId, action: action)
        
        trackEvent("content_interaction", parameters: [
            "content_id": contentId,
            "action": action
        ])
    }
    
    // MARK: - Conversion Funnel
    func trackConversionStep(_ step: String, value: Double? = nil) {
        conversionFunnel.recordStep([
            "step": step,
            "value": value ?? 0.0,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        var parameters: [String: Any] = [
            "step": step,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let value = value {
            parameters["value"] = value
        }
        
        trackEvent("conversion_step", parameters: parameters)
    }
    
    // MARK: - A/B Testing
    func startABTest(_ testName: String, variants: [String]) {
        let variant = variants.randomElement() ?? variants[0]
        
        abTestResults[testName] = ABTestResult(
            testName: testName,
            variant: variant,
            startTime: Date()
        )
        
        trackEvent("ab_test_started", parameters: [
            "test_name": testName,
            "variant": variant
        ])
    }
    
    func trackABTestConversion(_ testName: String, conversion: String) {
        guard var result = abTestResults[testName] else { return }
        
        result.conversions.append(conversion)
        abTestResults[testName] = result
        
        trackEvent("ab_test_conversion", parameters: [
            "test_name": testName,
            "variant": result.variant,
            "conversion": conversion
        ])
    }
    
    // MARK: - Error Tracking
    func trackError(_ error: Error, context: String, severity: ErrorSeverity = .medium) {
        // Firebase Crashlytics
        Crashlytics.crashlytics().record(error: error)
        
        // Custom error tracking
        trackEvent("error_occurred", parameters: [
            "error_description": error.localizedDescription,
            "context": context,
            "severity": severity.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        logger.error("Error tracked: \(error.localizedDescription) in \(context)")
    }
    
    // MARK: - Performance Tracking
    func trackPerformance(_ metric: String, value: Double, unit: String = "ms") {
        trackEvent("performance_metric", parameters: [
            "metric": metric,
            "value": value,
            "unit": unit,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Analytics Data
    func getAnalyticsData() -> AnalyticsData {
        return AnalyticsData(
            userEngagement: userEngagement,
            predictionAnalytics: predictionAnalytics,
            contentAnalytics: contentAnalytics,
            conversionFunnel: conversionFunnel,
            abTestResults: abTestResults,
            sessionData: SessionData(
                currentSessionLength: currentSessionLength,
                totalSessions: totalSessions,
                totalScreenViews: totalScreenViews,
                totalEvents: totalEvents
            )
        )
    }
    
    // MARK: - Export Analytics
    func exportAnalytics() -> Data? {
        let analyticsData = getAnalyticsData()
        return try? JSONEncoder().encode(analyticsData)
    }
}

// MARK: - Analytics Data Models
struct AnalyticsData: Codable {
    let userEngagement: UserEngagement
    let predictionAnalytics: PredictionAnalytics
    let contentAnalytics: ContentAnalytics
    let conversionFunnel: ConversionFunnel
    let abTestResults: [String: ABTestResult]
    let sessionData: SessionData
}

struct SessionData: Codable {
    let currentSessionLength: TimeInterval
    let totalSessions: Int
    let totalScreenViews: Int
    let totalEvents: Int
}

// MARK: - User Engagement
class UserEngagement: Codable {
    var totalSessions: Int = 0
    var totalScreenViews: Int = 0
    var totalEvents: Int = 0
    var averageSessionLength: TimeInterval = 0
    var screenViews: [String: Int] = [:]
    var featureUsage: [String: FeatureUsage] = [:]
    var actions: [String: Int] = [:]
    
    func recordSession(_ length: TimeInterval) {
        totalSessions += 1
        averageSessionLength = (averageSessionLength * Double(totalSessions - 1) + length) / Double(totalSessions)
    }
    
    func recordScreenView(_ screenName: String) {
        totalScreenViews += 1
        screenViews[screenName, default: 0] += 1
    }
    
    func recordFeatureUsage(_ feature: String, duration: TimeInterval? = nil) {
        if featureUsage[feature] == nil {
            featureUsage[feature] = FeatureUsage()
        }
        
        featureUsage[feature]?.usageCount += 1
        if let duration = duration {
            featureUsage[feature]?.totalDuration += duration
        }
    }
    
    func recordAction(_ action: String, context: String) {
        let key = "\(action)_\(context)"
        actions[key, default: 0] += 1
    }
    
    func recordEngagement(_ parameters: [String: Any]) {
        // Process engagement parameters
    }
}

struct FeatureUsage: Codable {
    var usageCount: Int = 0
    var totalDuration: TimeInterval = 0
    
    var averageDuration: TimeInterval {
        return usageCount > 0 ? totalDuration / Double(usageCount) : 0
    }
}

// MARK: - Prediction Analytics
class PredictionAnalytics: Codable {
    var totalPredictions: Int = 0
    var correctPredictions: Int = 0
    var accuracy: Double = 0.0
    var categoryAccuracy: [String: Double] = [:]
    var confidenceDistribution: [Int: Int] = [:]
    var predictionTrends: [PredictionTrend] = []
    
    func recordPredictionCreated(_ parameters: [String: Any]) {
        totalPredictions += 1
        
        if let category = parameters["category"] as? String {
            categoryAccuracy[category, default: 0.0] += 1
        }
        
        if let confidence = parameters["confidence"] as? Int {
            confidenceDistribution[confidence, default: 0] += 1
        }
    }
    
    func recordPredictionResolved(_ parameters: [String: Any]) {
        if let wasCorrect = parameters["was_correct"] as? Bool, wasCorrect {
            correctPredictions += 1
        }
        
        accuracy = totalPredictions > 0 ? Double(correctPredictions) / Double(totalPredictions) : 0.0
    }
}

struct PredictionTrend: Codable {
    let date: Date
    let accuracy: Double
    let predictionCount: Int
}

// MARK: - Content Analytics
class ContentAnalytics: Codable {
    var contentViews: [String: ContentView] = [:]
    var popularContent: [String: Int] = [:]
    var contentInteractions: [String: [String: Int]] = [:]
    
    func recordContentView(_ parameters: [String: Any]) {
        guard let contentId = parameters["content_id"] as? String,
              let contentType = parameters["content_type"] as? String else { return }
        
        if contentViews[contentId] == nil {
            contentViews[contentId] = ContentView(
                contentId: contentId,
                contentType: contentType,
                viewCount: 0,
                totalDuration: 0
            )
        }
        
        contentViews[contentId]?.viewCount += 1
        if let duration = parameters["duration"] as? TimeInterval {
            contentViews[contentId]?.totalDuration += duration
        }
        
        popularContent[contentId, default: 0] += 1
    }
    
    func recordInteraction(_ contentId: String, action: String) {
        if contentInteractions[contentId] == nil {
            contentInteractions[contentId] = [:]
        }
        
        contentInteractions[contentId]?[action, default: 0] += 1
    }
}

struct ContentView: Codable {
    let contentId: String
    let contentType: String
    var viewCount: Int
    var totalDuration: TimeInterval
    
    var averageDuration: TimeInterval {
        return viewCount > 0 ? totalDuration / Double(viewCount) : 0
    }
}

// MARK: - Conversion Funnel
class ConversionFunnel: Codable {
    var steps: [String: FunnelStep] = [:]
    var conversionRate: Double = 0.0
    
    func recordStep(_ parameters: [String: Any]) {
        guard let step = parameters["step"] as? String else { return }
        
        if steps[step] == nil {
            steps[step] = FunnelStep(
                stepName: step,
                count: 0,
                value: 0.0
            )
        }
        
        steps[step]?.count += 1
        if let value = parameters["value"] as? Double {
            steps[step]?.value += value
        }
    }
}

struct FunnelStep: Codable {
    let stepName: String
    var count: Int
    var value: Double
}

// MARK: - A/B Testing
struct ABTestResult: Codable {
    let testName: String
    let variant: String
    let startTime: Date
    var conversions: [String] = []
    
    var conversionRate: Double {
        return conversions.count > 0 ? Double(conversions.count) : 0.0
    }
}

// MARK: - Analytics Event
struct AnalyticsEvent: Codable {
    let name: String
    let parameters: [String: Any]
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case name, timestamp
    }
    
    init(name: String, parameters: [String: Any], timestamp: Date) {
        self.name = name
        self.parameters = parameters
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        parameters = [:] // Parameters are not decoded for simplicity
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(timestamp, forKey: .timestamp)
        // Parameters are not encoded for simplicity
    }
}

// MARK: - Error Severity
enum ErrorSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}
