import Foundation
import Combine
import os.log

class ABTestingService: ObservableObject {
    static let shared = ABTestingService()
    
    @Published var activeTests: [String: ABTest] = [:]
    @Published var userVariants: [String: String] = [:]
    @Published var testResults: [String: ABTestResult] = [:]
    
    private let logger = Logger(subsystem: "com.wrestlepick", category: "ABTesting")
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // Test configuration
    private let testConfigurationKey = "ab_test_configuration"
    private let userVariantsKey = "ab_test_user_variants"
    private let testResultsKey = "ab_test_results"
    
    private init() {
        loadTestConfiguration()
        loadUserVariants()
        loadTestResults()
    }
    
    // MARK: - Test Management
    func startTest(_ test: ABTest) {
        activeTests[test.id] = test
        
        // Assign user to variant if not already assigned
        if userVariants[test.id] == nil {
            let variant = assignUserToVariant(test)
            userVariants[test.id] = variant
            saveUserVariants()
        }
        
        // Track test start
        trackTestEvent(test.id, event: "test_started", variant: userVariants[test.id] ?? "")
        
        logger.info("Started AB test: \(test.name) - Variant: \(userVariants[test.id] ?? "")")
    }
    
    func endTest(_ testId: String) {
        guard let test = activeTests[testId] else { return }
        
        activeTests.removeValue(forKey: testId)
        
        // Track test end
        trackTestEvent(testId, event: "test_ended", variant: userVariants[testId] ?? "")
        
        logger.info("Ended AB test: \(test.name)")
    }
    
    func getVariant(for testId: String) -> String? {
        return userVariants[testId]
    }
    
    func isUserInVariant(_ testId: String, variant: String) -> Bool {
        return userVariants[testId] == variant
    }
    
    // MARK: - Variant Assignment
    private func assignUserToVariant(_ test: ABTest) -> String {
        // Use user ID for consistent assignment
        let userId = getUserId()
        let hash = userId.hashValue
        let variantIndex = abs(hash) % test.variants.count
        return test.variants[variantIndex].id
    }
    
    private func getUserId() -> String {
        // Get user ID from auth service or generate one
        return AuthService.shared.currentUser?.id ?? "anonymous_\(UUID().uuidString)"
    }
    
    // MARK: - Event Tracking
    func trackTestEvent(_ testId: String, event: String, variant: String? = nil) {
        let actualVariant = variant ?? userVariants[testId] ?? "unknown"
        
        // Track with analytics service
        AnalyticsService.shared.trackEvent("ab_test_event", parameters: [
            "test_id": testId,
            "variant": actualVariant,
            "event": event,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        // Update test results
        updateTestResult(testId, event: event, variant: actualVariant)
    }
    
    func trackConversion(_ testId: String, conversion: String, value: Double? = nil) {
        guard let variant = userVariants[testId] else { return }
        
        trackTestEvent(testId, event: "conversion", variant: variant)
        
        // Update conversion tracking
        if testResults[testId] == nil {
            testResults[testId] = ABTestResult(testId: testId, variant: variant)
        }
        
        testResults[testId]?.recordConversion(conversion, value: value)
        saveTestResults()
    }
    
    // MARK: - Test Results
    private func updateTestResult(_ testId: String, event: String, variant: String) {
        if testResults[testId] == nil {
            testResults[testId] = ABTestResult(testId: testId, variant: variant)
        }
        
        testResults[testId]?.recordEvent(event)
        saveTestResults()
    }
    
    func getTestResults(_ testId: String) -> ABTestResult? {
        return testResults[testId]
    }
    
    func getAllTestResults() -> [ABTestResult] {
        return Array(testResults.values)
    }
    
    // MARK: - Statistical Analysis
    func calculateTestSignificance(_ testId: String) -> TestSignificance? {
        guard let test = activeTests[testId],
              let result = testResults[testId] else { return nil }
        
        // Calculate conversion rates for each variant
        let variantResults = calculateVariantResults(test, result: result)
        
        // Perform statistical significance test
        return performSignificanceTest(variantResults)
    }
    
    private func calculateVariantResults(_ test: ABTest, result: ABTestResult) -> [VariantResult] {
        var variantResults: [VariantResult] = [:]
        
        for variant in test.variants {
            let variantData = result.events.filter { $0.variant == variant.id }
            let conversions = variantData.filter { $0.event == "conversion" }
            
            variantResults[variant.id] = VariantResult(
                variantId: variant.id,
                totalEvents: variantData.count,
                conversions: conversions.count,
                conversionRate: variantData.count > 0 ? Double(conversions.count) / Double(variantData.count) : 0.0,
                totalValue: conversions.compactMap { $0.value }.reduce(0, +)
            )
        }
        
        return Array(variantResults.values)
    }
    
    private func performSignificanceTest(_ variantResults: [VariantResult]) -> TestSignificance {
        // Simplified chi-square test for conversion rates
        guard variantResults.count >= 2 else {
            return TestSignificance(confidence: 0.0, isSignificant: false)
        }
        
        let control = variantResults[0]
        let treatment = variantResults[1]
        
        // Calculate chi-square statistic
        let chiSquare = calculateChiSquare(control: control, treatment: treatment)
        
        // Determine significance (simplified)
        let isSignificant = chiSquare > 3.84 // 95% confidence level
        let confidence = min(chiSquare / 10.0, 1.0) // Simplified confidence calculation
        
        return TestSignificance(confidence: confidence, isSignificant: isSignificant)
    }
    
    private func calculateChiSquare(control: VariantResult, treatment: VariantResult) -> Double {
        // Simplified chi-square calculation
        let controlRate = control.conversionRate
        let treatmentRate = treatment.conversionRate
        
        if controlRate == 0 && treatmentRate == 0 {
            return 0.0
        }
        
        let expectedRate = (control.conversions + treatment.conversions) / Double(control.totalEvents + treatment.totalEvents)
        let controlExpected = control.totalEvents * expectedRate
        let treatmentExpected = treatment.totalEvents * expectedRate
        
        let controlChi = pow(Double(control.conversions) - controlExpected, 2) / controlExpected
        let treatmentChi = pow(Double(treatment.conversions) - treatmentExpected, 2) / treatmentExpected
        
        return controlChi + treatmentChi
    }
    
    // MARK: - Test Recommendations
    func getTestRecommendations() -> [TestRecommendation] {
        var recommendations: [TestRecommendation] = []
        
        for (testId, result) in testResults {
            if let significance = calculateTestSignificance(testId) {
                if significance.isSignificant {
                    recommendations.append(TestRecommendation(
                        testId: testId,
                        type: .implement,
                        message: "Test shows significant results. Consider implementing the winning variant.",
                        confidence: significance.confidence
                    ))
                } else if result.totalEvents > 1000 {
                    recommendations.append(TestRecommendation(
                        testId: testId,
                        type: .extend,
                        message: "Test has sufficient traffic but no significant results. Consider extending the test period.",
                        confidence: significance.confidence
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    // MARK: - Data Persistence
    private func loadTestConfiguration() {
        if let data = userDefaults.data(forKey: testConfigurationKey),
           let tests = try? JSONDecoder().decode([String: ABTest].self, from: data) {
            activeTests = tests
        }
    }
    
    private func saveTestConfiguration() {
        if let data = try? JSONEncoder().encode(activeTests) {
            userDefaults.set(data, forKey: testConfigurationKey)
        }
    }
    
    private func loadUserVariants() {
        if let data = userDefaults.data(forKey: userVariantsKey),
           let variants = try? JSONDecoder().decode([String: String].self, from: data) {
            userVariants = variants
        }
    }
    
    private func saveUserVariants() {
        if let data = try? JSONEncoder().encode(userVariants) {
            userDefaults.set(data, forKey: userVariantsKey)
        }
    }
    
    private func loadTestResults() {
        if let data = userDefaults.data(forKey: testResultsKey),
           let results = try? JSONDecoder().decode([String: ABTestResult].self, from: data) {
            testResults = results
        }
    }
    
    private func saveTestResults() {
        if let data = try? JSONEncoder().encode(testResults) {
            userDefaults.set(data, forKey: testResultsKey)
        }
    }
    
    // MARK: - Test Cleanup
    func cleanupOldTests() {
        let oneMonthAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        
        // Remove old test results
        testResults = testResults.filter { _, result in
            result.lastUpdated > oneMonthAgo
        }
        
        // Remove old user variants
        userVariants = userVariants.filter { testId, _ in
            testResults[testId] != nil
        }
        
        saveTestResults()
        saveUserVariants()
    }
}

// MARK: - AB Test
struct ABTest: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let variants: [ABTestVariant]
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let targetAudience: [String]
    let successMetrics: [String]
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        variants: [ABTestVariant],
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        targetAudience: [String] = [],
        successMetrics: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.variants = variants
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.targetAudience = targetAudience
        self.successMetrics = successMetrics
    }
}

// MARK: - AB Test Variant
struct ABTestVariant: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let configuration: [String: Any]
    let weight: Double
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        configuration: [String: Any] = [:],
        weight: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.configuration = configuration
        self.weight = weight
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, weight
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        weight = try container.decode(Double.self, forKey: .weight)
        configuration = [:] // Configuration is not decoded for simplicity
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(weight, forKey: .weight)
        // Configuration is not encoded for simplicity
    }
}

// MARK: - AB Test Result
class ABTestResult: Codable, ObservableObject {
    let testId: String
    let variant: String
    var events: [TestEvent] = []
    var conversions: [TestConversion] = []
    var lastUpdated: Date = Date()
    
    init(testId: String, variant: String) {
        self.testId = testId
        self.variant = variant
    }
    
    func recordEvent(_ event: String) {
        let testEvent = TestEvent(
            event: event,
            variant: variant,
            timestamp: Date()
        )
        events.append(testEvent)
        lastUpdated = Date()
    }
    
    func recordConversion(_ conversion: String, value: Double? = nil) {
        let testConversion = TestConversion(
            conversion: conversion,
            variant: variant,
            value: value,
            timestamp: Date()
        )
        conversions.append(testConversion)
        lastUpdated = Date()
    }
    
    var totalEvents: Int {
        return events.count
    }
    
    var totalConversions: Int {
        return conversions.count
    }
    
    var conversionRate: Double {
        return totalEvents > 0 ? Double(totalConversions) / Double(totalEvents) : 0.0
    }
    
    var totalValue: Double {
        return conversions.compactMap { $0.value }.reduce(0, +)
    }
}

// MARK: - Test Event
struct TestEvent: Codable {
    let event: String
    let variant: String
    let timestamp: Date
}

// MARK: - Test Conversion
struct TestConversion: Codable {
    let conversion: String
    let variant: String
    let value: Double?
    let timestamp: Date
}

// MARK: - Variant Result
struct VariantResult {
    let variantId: String
    let totalEvents: Int
    let conversions: Int
    let conversionRate: Double
    let totalValue: Double
}

// MARK: - Test Significance
struct TestSignificance {
    let confidence: Double
    let isSignificant: Bool
}

// MARK: - Test Recommendation
struct TestRecommendation {
    let testId: String
    let type: RecommendationType
    let message: String
    let confidence: Double
}

// MARK: - Recommendation Type
enum RecommendationType: String, CaseIterable {
    case implement = "implement"
    case extend = "extend"
    case stop = "stop"
    case modify = "modify"
}

// MARK: - Predefined Tests
extension ABTestingService {
    func createPredefinedTests() {
        // Paywall design test
        let paywallTest = ABTest(
            name: "Paywall Design",
            description: "Test different paywall designs to improve conversion",
            variants: [
                ABTestVariant(
                    name: "Control",
                    description: "Current paywall design",
                    configuration: ["design": "current"]
                ),
                ABTestVariant(
                    name: "Minimal",
                    description: "Minimal design with fewer elements",
                    configuration: ["design": "minimal"]
                ),
                ABTestVariant(
                    name: "Social Proof",
                    description: "Design with social proof elements",
                    configuration: ["design": "social_proof"]
                )
            ],
            successMetrics: ["subscription_conversion", "trial_signup"]
        )
        
        startTest(paywallTest)
        
        // News feed layout test
        let newsFeedTest = ABTest(
            name: "News Feed Layout",
            description: "Test different news feed layouts for engagement",
            variants: [
                ABTestVariant(
                    name: "List View",
                    description: "Traditional list view",
                    configuration: ["layout": "list"]
                ),
                ABTestVariant(
                    name: "Card View",
                    description: "Card-based layout",
                    configuration: ["layout": "card"]
                ),
                ABTestVariant(
                    name: "Magazine View",
                    description: "Magazine-style layout",
                    configuration: ["layout": "magazine"]
                )
            ],
            successMetrics: ["article_views", "time_spent", "shares"]
        )
        
        startTest(newsFeedTest)
        
        // Prediction interface test
        let predictionTest = ABTest(
            name: "Prediction Interface",
            description: "Test different prediction creation interfaces",
            variants: [
                ABTestVariant(
                    name: "Step-by-Step",
                    description: "Multi-step prediction creation",
                    configuration: ["interface": "step_by_step"]
                ),
                ABTestVariant(
                    name: "Single Page",
                    description: "All-in-one prediction creation",
                    configuration: ["interface": "single_page"]
                ),
                ABTestVariant(
                    name: "Wizard",
                    description: "Guided wizard interface",
                    configuration: ["interface": "wizard"]
                )
            ],
            successMetrics: ["prediction_creation", "completion_rate", "time_to_create"]
        )
        
        startTest(predictionTest)
    }
}
