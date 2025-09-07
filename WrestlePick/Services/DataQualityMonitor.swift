import Foundation
import Combine
import os.log

class DataQualityMonitor: ObservableObject {
    static let shared = DataQualityMonitor()
    
    @Published var metrics: DataQualityMetrics = DataQualityMetrics()
    @Published var alerts: [QualityAlert] = []
    @Published var isMonitoring = false
    
    private let logger = Logger(subsystem: "com.wrestlepick", category: "DataQuality")
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    
    // Quality thresholds
    private let sourceReliabilityThreshold: Double = 0.8
    private let contentFreshnessThreshold: TimeInterval = 24 * 60 * 60 // 24 hours
    private let duplicationRateThreshold: Double = 0.1
    private let validationAccuracyThreshold: Double = 0.9
    private let userEngagementThreshold: Double = 0.7
    private let apiResponseTimeThreshold: TimeInterval = 5.0 // 5 seconds
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        monitoringTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        isMonitoring = true
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.collectMetrics()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
    }
    
    func generateQualityReport() -> QualityReport {
        return QualityReport(
            timestamp: Date(),
            metrics: metrics,
            recommendations: generateRecommendations(),
            overallScore: calculateOverallScore()
        )
    }
    
    func clearAlerts() {
        alerts.removeAll()
    }
    
    // MARK: - Private Methods
    private func collectMetrics() {
        logger.info("Collecting data quality metrics")
        
        // Collect source reliability metrics
        collectSourceReliabilityMetrics()
        
        // Collect content freshness metrics
        collectContentFreshnessMetrics()
        
        // Collect duplication rate metrics
        collectDuplicationRateMetrics()
        
        // Collect validation accuracy metrics
        collectValidationAccuracyMetrics()
        
        // Collect user engagement metrics
        collectUserEngagementMetrics()
        
        // Collect API response time metrics
        collectAPIResponseTimeMetrics()
        
        // Check for quality issues
        checkQualityIssues()
    }
    
    private func collectSourceReliabilityMetrics() {
        // Calculate source reliability scores
        let sources = [
            "Wrestling Observer Newsletter": 0.95,
            "PWTorch": 0.92,
            "Fightful": 0.88,
            "Wrestling Inc": 0.85,
            "WWE Official": 0.98,
            "AEW Official": 0.96,
            "NJPW Official": 0.94,
            "Cageside Seats": 0.78,
            "WrestleTalk": 0.75,
            "POST Wrestling": 0.82,
            "Wrestling News": 0.70
        ]
        
        metrics.sourceReliability = sources
    }
    
    private func collectContentFreshnessMetrics() {
        // Calculate content freshness
        let now = Date()
        let articles = RSSFeedManager.shared.articles
        
        let averageAge = articles.reduce(0.0) { total, article in
            total + now.timeIntervalSince(article.publishDate)
        } / Double(articles.count)
        
        metrics.contentFreshness = averageAge
    }
    
    private func collectDuplicationRateMetrics() {
        // Calculate duplication rate
        let articles = RSSFeedManager.shared.articles
        let totalArticles = articles.count
        
        guard totalArticles > 0 else {
            metrics.duplicationRate = 0.0
            return
        }
        
        var duplicates = 0
        var seenTitles: Set<String> = []
        
        for article in articles {
            let normalizedTitle = article.title.lowercased()
                .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
            
            if seenTitles.contains(normalizedTitle) {
                duplicates += 1
            } else {
                seenTitles.insert(normalizedTitle)
            }
        }
        
        metrics.duplicationRate = Double(duplicates) / Double(totalArticles)
    }
    
    private func collectValidationAccuracyMetrics() {
        // Calculate validation accuracy
        let articles = RSSFeedManager.shared.articles
        let totalArticles = articles.count
        
        guard totalArticles > 0 else {
            metrics.validationAccuracy = 1.0
            return
        }
        
        var validArticles = 0
        
        for article in articles {
            let validator = DataValidator()
            let result = validator.validateNewsArticle(article)
            if result.isValid {
                validArticles += 1
            }
        }
        
        metrics.validationAccuracy = Double(validArticles) / Double(totalArticles)
    }
    
    private func collectUserEngagementMetrics() {
        // Calculate user engagement score
        let articles = RSSFeedManager.shared.articles
        let totalArticles = articles.count
        
        guard totalArticles > 0 else {
            metrics.userEngagementScore = 0.0
            return
        }
        
        let totalEngagement = articles.reduce(0.0) { total, article in
            total + Double(article.likes + article.shares + article.comments)
        }
        
        metrics.userEngagementScore = totalEngagement / Double(totalArticles)
    }
    
    private func collectAPIResponseTimeMetrics() {
        // Calculate average API response time
        // This would typically be collected from actual API calls
        metrics.apiResponseTime = 2.5 // Mock value
    }
    
    private func checkQualityIssues() {
        var newAlerts: [QualityAlert] = []
        
        // Check source reliability
        for (source, reliability) in metrics.sourceReliability {
            if reliability < sourceReliabilityThreshold {
                let alert = QualityAlert(
                    id: UUID().uuidString,
                    type: .sourceReliability,
                    severity: .warning,
                    message: "Source \(source) reliability is below threshold: \(String(format: "%.2f", reliability))",
                    timestamp: Date(),
                    isResolved: false
                )
                newAlerts.append(alert)
            }
        }
        
        // Check content freshness
        if metrics.contentFreshness > contentFreshnessThreshold {
            let alert = QualityAlert(
                id: UUID().uuidString,
                type: .contentFreshness,
                severity: .warning,
                message: "Content freshness is below threshold: \(String(format: "%.1f", metrics.contentFreshness / 3600)) hours",
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // Check duplication rate
        if metrics.duplicationRate > duplicationRateThreshold {
            let alert = QualityAlert(
                id: UUID().uuidString,
                type: .duplicationRate,
                severity: .error,
                message: "Duplication rate is above threshold: \(String(format: "%.2f", metrics.duplicationRate * 100))%",
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // Check validation accuracy
        if metrics.validationAccuracy < validationAccuracyThreshold {
            let alert = QualityAlert(
                id: UUID().uuidString,
                type: .validationAccuracy,
                severity: .error,
                message: "Validation accuracy is below threshold: \(String(format: "%.2f", metrics.validationAccuracy * 100))%",
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // Check user engagement
        if metrics.userEngagementScore < userEngagementThreshold {
            let alert = QualityAlert(
                id: UUID().uuidString,
                type: .userEngagement,
                severity: .info,
                message: "User engagement is below threshold: \(String(format: "%.2f", metrics.userEngagementScore))",
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // Check API response time
        if metrics.apiResponseTime > apiResponseTimeThreshold {
            let alert = QualityAlert(
                id: UUID().uuidString,
                type: .apiResponseTime,
                severity: .warning,
                message: "API response time is above threshold: \(String(format: "%.2f", metrics.apiResponseTime)) seconds",
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // Add new alerts
        DispatchQueue.main.async {
            self.alerts.append(contentsOf: newAlerts)
        }
    }
    
    private func generateRecommendations() -> [QualityRecommendation] {
        var recommendations: [QualityRecommendation] = []
        
        // Source reliability recommendations
        let lowReliabilitySources = metrics.sourceReliability.filter { $0.value < sourceReliabilityThreshold }
        if !lowReliabilitySources.isEmpty {
            recommendations.append(QualityRecommendation(
                type: .sourceReliability,
                priority: .high,
                title: "Improve Source Reliability",
                description: "Consider removing or improving sources with low reliability: \(lowReliabilitySources.keys.joined(separator: ", "))",
                action: "Review and update source selection criteria"
            ))
        }
        
        // Content freshness recommendations
        if metrics.contentFreshness > contentFreshnessThreshold {
            recommendations.append(QualityRecommendation(
                type: .contentFreshness,
                priority: .medium,
                title: "Improve Content Freshness",
                description: "Content is not being updated frequently enough",
                action: "Increase RSS feed refresh frequency or add more sources"
            ))
        }
        
        // Duplication rate recommendations
        if metrics.duplicationRate > duplicationRateThreshold {
            recommendations.append(QualityRecommendation(
                type: .duplicationRate,
                priority: .high,
                title: "Reduce Content Duplication",
                description: "Too many duplicate articles are being processed",
                action: "Improve deduplication algorithm or source selection"
            ))
        }
        
        // Validation accuracy recommendations
        if metrics.validationAccuracy < validationAccuracyThreshold {
            recommendations.append(QualityRecommendation(
                type: .validationAccuracy,
                priority: .high,
                title: "Improve Data Validation",
                description: "Data validation is not catching enough issues",
                action: "Review and improve validation rules"
            ))
        }
        
        // User engagement recommendations
        if metrics.userEngagementScore < userEngagementThreshold {
            recommendations.append(QualityRecommendation(
                type: .userEngagement,
                priority: .medium,
                title: "Improve User Engagement",
                description: "Users are not engaging with content as expected",
                action: "Review content quality and user interface"
            ))
        }
        
        // API response time recommendations
        if metrics.apiResponseTime > apiResponseTimeThreshold {
            recommendations.append(QualityRecommendation(
                type: .apiResponseTime,
                priority: .medium,
                title: "Improve API Performance",
                description: "API responses are taking too long",
                action: "Optimize API calls or implement caching"
            ))
        }
        
        return recommendations
    }
    
    private func calculateOverallScore() -> Double {
        let sourceScore = metrics.sourceReliability.values.reduce(0, +) / Double(metrics.sourceReliability.count)
        let freshnessScore = max(0, 1 - (metrics.contentFreshness / contentFreshnessThreshold))
        let duplicationScore = max(0, 1 - (metrics.duplicationRate / duplicationRateThreshold))
        let validationScore = metrics.validationAccuracy
        let engagementScore = min(1, metrics.userEngagementScore / userEngagementThreshold)
        let responseTimeScore = max(0, 1 - (metrics.apiResponseTime / apiResponseTimeThreshold))
        
        return (sourceScore + freshnessScore + duplicationScore + validationScore + engagementScore + responseTimeScore) / 6.0
    }
}

// MARK: - Supporting Types
struct DataQualityMetrics {
    var sourceReliability: [String: Double] = [:]
    var contentFreshness: TimeInterval = 0
    var duplicationRate: Double = 0
    var validationAccuracy: Double = 0
    var userEngagementScore: Double = 0
    var apiResponseTime: TimeInterval = 0
}

struct QualityAlert: Identifiable {
    let id: String
    let type: QualityAlertType
    let severity: QualityAlertSeverity
    let message: String
    let timestamp: Date
    let isResolved: Bool
}

enum QualityAlertType {
    case sourceReliability
    case contentFreshness
    case duplicationRate
    case validationAccuracy
    case userEngagement
    case apiResponseTime
}

enum QualityAlertSeverity {
    case info
    case warning
    case error
    case critical
}

struct QualityReport {
    let timestamp: Date
    let metrics: DataQualityMetrics
    let recommendations: [QualityRecommendation]
    let overallScore: Double
}

struct QualityRecommendation {
    let type: QualityAlertType
    let priority: QualityPriority
    let title: String
    let description: String
    let action: String
}

enum QualityPriority {
    case low
    case medium
    case high
    case critical
}
