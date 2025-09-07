import Foundation
import Combine
import os.log

class BreakingNewsDetector: ObservableObject {
    static let shared = BreakingNewsDetector()
    
    @Published var breakingNews: [BreakingNewsAlert] = []
    @Published var isMonitoring = false
    @Published var lastDetectionTime: Date?
    
    private let logger = Logger(subsystem: "com.wrestlepick", category: "BreakingNews")
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    
    // Breaking news detection criteria
    private let breakingKeywords = [
        "breaking", "exclusive", "confirmed", "urgent", "just in", "developing",
        "reports", "sources say", "according to", "insider", "backstage"
    ]
    
    private let injuryKeywords = [
        "injured", "injury", "medical", "concussion", "surgery", "recovery",
        "out of action", "sidelined", "rehab", "treatment"
    ]
    
    private let contractKeywords = [
        "signed", "released", "contract", "free agent", "resigned", "extension",
        "terminated", "fired", "quit", "walked out"
    ]
    
    private let championshipKeywords = [
        "championship", "title", "belt", "crown", "champion", "challenger",
        "defend", "retain", "win", "lose", "vacate", "strip"
    ]
    
    private let storylineKeywords = [
        "feud", "rivalry", "beef", "heat", "angle", "storyline", "plot",
        "twist", "shock", "surprise", "return", "debut"
    ]
    
    private let eventKeywords = [
        "wrestlemania", "summerslam", "royal rumble", "money in the bank",
        "survivor series", "tlc", "hell in a cell", "elimination chamber"
    ]
    
    // Source reliability weights
    private let sourceWeights: [String: Double] = [
        "Wrestling Observer Newsletter": 1.0,
        "PWTorch": 1.0,
        "Fightful": 1.0,
        "Wrestling Inc": 1.0,
        "WWE Official": 1.0,
        "AEW Official": 1.0,
        "NJPW Official": 1.0,
        "Cageside Seats": 0.8,
        "WrestleTalk": 0.8,
        "POST Wrestling": 0.8,
        "Wrestling News": 0.8
    ]
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        monitoringTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        isMonitoring = true
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkForBreakingNews()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
    }
    
    func analyzeArticle(_ article: Any) -> BreakingNewsAnalysis {
        // For now, return a default analysis since we don't have NewsArticle type
        let combinedText = "sample text"
        
        var confidence: Double = 0.0
        var categories: [BreakingNewsCategory] = []
        var severity: BreakingNewsSeverity = .low
        
        // Check for breaking news keywords
        let breakingScore = calculateKeywordScore(combinedText, keywords: breakingKeywords)
        if breakingScore > 0.3 {
            confidence += breakingScore * 0.4
            categories.append(.breaking)
        }
        
        // Check for injury keywords
        let injuryScore = calculateKeywordScore(combinedText, keywords: injuryKeywords)
        if injuryScore > 0.2 {
            confidence += injuryScore * 0.3
            categories.append(.injury)
            severity = .high
        }
        
        // Check for contract keywords
        let contractScore = calculateKeywordScore(combinedText, keywords: contractKeywords)
        if contractScore > 0.2 {
            confidence += contractScore * 0.3
            categories.append(.contract)
            severity = .medium
        }
        
        // Check for championship keywords
        let championshipScore = calculateKeywordScore(combinedText, keywords: championshipKeywords)
        if championshipScore > 0.2 {
            confidence += championshipScore * 0.25
            categories.append(.championship)
            severity = .medium
        }
        
        // Check for storyline keywords
        let storylineScore = calculateKeywordScore(combinedText, keywords: storylineKeywords)
        if storylineScore > 0.2 {
            confidence += storylineScore * 0.2
            categories.append(.storyline)
            severity = .low
        }
        
        // Check for event keywords
        let eventScore = calculateKeywordScore(combinedText, keywords: eventKeywords)
        if eventScore > 0.2 {
            confidence += eventScore * 0.15
            categories.append(.event)
            severity = .low
        }
        
        // Apply source reliability weight
        let sourceWeight = sourceWeights[article.source.name] ?? 0.5
        confidence *= sourceWeight
        
        // Determine if it's breaking news
        let isBreaking = confidence > 0.6 && !categories.isEmpty
        
        return BreakingNewsAnalysis(
            isBreaking: isBreaking,
            confidence: confidence,
            categories: categories,
            severity: severity,
            keywords: extractKeywords(combinedText),
            timestamp: Date()
        )
    }
    
    func createBreakingNewsAlert(_ article: Any, analysis: BreakingNewsAnalysis) -> BreakingNewsAlert {
        let alert = BreakingNewsAlert(
            id: UUID().uuidString,
            article: article,
            analysis: analysis,
            priority: calculatePriority(analysis),
            isRead: false,
            createdAt: Date()
        )
        
        // Add to breaking news list
        DispatchQueue.main.async {
            self.breakingNews.insert(alert, at: 0)
            self.lastDetectionTime = Date()
            
            // Send push notification
            self.sendBreakingNewsNotification(alert)
        }
        
        return alert
    }
    
    func markAsRead(_ alert: BreakingNewsAlert) {
        if let index = breakingNews.firstIndex(where: { $0.id == alert.id }) {
            breakingNews[index] = BreakingNewsAlert(
                id: alert.id,
                article: alert.article,
                analysis: alert.analysis,
                priority: alert.priority,
                isRead: true,
                createdAt: alert.createdAt
            )
        }
    }
    
    func clearOldAlerts() {
        let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        breakingNews = breakingNews.filter { $0.createdAt > cutoffDate }
    }
    
    // MARK: - Private Methods
    private func checkForBreakingNews() {
        // This would typically fetch new articles from RSS feeds
        // For now, we'll simulate the process
        logger.info("Checking for breaking news...")
    }
    
    private func calculateKeywordScore(_ text: String, keywords: [String]) -> Double {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let totalWords = words.count
        
        guard totalWords > 0 else { return 0.0 }
        
        var keywordCount = 0
        for keyword in keywords {
            if text.contains(keyword) {
                keywordCount += 1
            }
        }
        
        return Double(keywordCount) / Double(keywords.count)
    }
    
    private func extractKeywords(_ text: String) -> [String] {
        let allKeywords = breakingKeywords + injuryKeywords + contractKeywords + 
                         championshipKeywords + storylineKeywords + eventKeywords
        
        return allKeywords.filter { text.contains($0) }
    }
    
    private func calculatePriority(_ analysis: BreakingNewsAnalysis) -> BreakingNewsPriority {
        if analysis.severity == .high && analysis.confidence > 0.8 {
            return .critical
        } else if analysis.severity == .high && analysis.confidence > 0.6 {
            return .high
        } else if analysis.severity == .medium && analysis.confidence > 0.7 {
            return .high
        } else if analysis.confidence > 0.6 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func sendBreakingNewsNotification(_ alert: BreakingNewsAlert) {
        let notification = PushNotification(
            title: "🚨 Breaking News",
            body: alert.article.title,
            data: [
                "articleId": alert.article.id,
                "category": alert.analysis.categories.first?.rawValue ?? "breaking",
                "priority": alert.priority.rawValue
            ]
        )
        
        PushNotificationService.shared.sendNotification(notification)
    }
}

// MARK: - Supporting Types
struct BreakingNewsAnalysis {
    let isBreaking: Bool
    let confidence: Double
    let categories: [BreakingNewsCategory]
    let severity: BreakingNewsSeverity
    let keywords: [String]
    let timestamp: Date
}

enum BreakingNewsCategory: String, CaseIterable {
    case breaking = "breaking"
    case injury = "injury"
    case contract = "contract"
    case championship = "championship"
    case storyline = "storyline"
    case event = "event"
}

enum BreakingNewsSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

enum BreakingNewsPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

struct BreakingNewsAlert: Identifiable {
    let id: String
    let article: Any
    let analysis: BreakingNewsAnalysis
    let priority: BreakingNewsPriority
    let isRead: Bool
    let createdAt: Date
}

struct PushNotification {
    let title: String
    let body: String
    let data: [String: String]
}

// MARK: - Push Notification Service
class PushNotificationService {
    static let shared = PushNotificationService()
    
    private init() {}
    
    func sendNotification(_ notification: PushNotification) {
        // In a real implementation, this would send actual push notifications
        // For now, we'll just log the notification
        print("📱 Push Notification: \(notification.title) - \(notification.body)")
    }
    
    func sendBreakingNewsNotification(_ article: Any) {
        let notification = PushNotification(
            title: "🚨 Breaking News",
            body: "Breaking news alert",
            data: [
                "articleId": "unknown",
                "category": "breaking",
                "priority": "high"
            ]
        )
        
        sendNotification(notification)
    }
}
