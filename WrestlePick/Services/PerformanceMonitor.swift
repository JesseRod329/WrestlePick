import Foundation
import UIKit
import Combine
import os.log

class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    @Published var networkLatency: Double = 0.0
    @Published var appLaunchTime: Double = 0.0
    @Published var viewLoadTimes: [String: Double] = [:]
    @Published var networkRequestCount: Int = 0
    @Published var cacheHitRate: Double = 0.0
    @Published var errorCount: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var memoryTimer: Timer?
    private var performanceTimer: Timer?
    private let logger = Logger(subsystem: "com.wrestlepick", category: "Performance")
    
    // Performance thresholds
    private let maxMemoryUsage: Double = 200.0 // MB
    private let maxCPUUsage: Double = 80.0 // %
    private let maxNetworkLatency: Double = 5000.0 // ms
    private let maxViewLoadTime: Double = 1000.0 // ms
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring Control
    func startMonitoring() {
        startMemoryMonitoring()
        startPerformanceMonitoring()
        startNetworkMonitoring()
    }
    
    func stopMonitoring() {
        memoryTimer?.invalidate()
        performanceTimer?.invalidate()
    }
    
    // MARK: - Memory Monitoring
    private func startMemoryMonitoring() {
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }
    
    private func updateMemoryUsage() {
        let memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(memoryInfo.resident_size) / 1024.0 / 1024.0
            DispatchQueue.main.async {
                self.memoryUsage = memoryUsageMB
            }
            
            if memoryUsageMB > self.maxMemoryUsage {
                self.logger.warning("High memory usage: \(memoryUsageMB) MB")
                self.handleHighMemoryUsage()
            }
        }
    }
    
    private func handleHighMemoryUsage() {
        // Clear caches
        ImageCache.shared.clearCache()
        NewsCache.shared.clearOldCache()
        
        // Force garbage collection
        DispatchQueue.global(qos: .background).async {
            // Trigger memory pressure
        }
    }
    
    // MARK: - Performance Monitoring
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateCPUUsage()
        }
    }
    
    private func updateCPUUsage() {
        var info = processor_info_array_t.allocate(capacity: 1)
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(),
                                       PROCESSOR_CPU_LOAD_INFO,
                                       &numCpus,
                                       &info,
                                       &numCpuInfo)
        
        if result == KERN_SUCCESS {
            let cpuInfo = info.withMemoryRebound(to: processor_cpu_load_info_t.self, capacity: Int(numCpus)) {
                $0
            }
            
            var totalUser: UInt32 = 0
            var totalSystem: UInt32 = 0
            var totalIdle: UInt32 = 0
            
            for i in 0..<Int(numCpus) {
                totalUser += cpuInfo[i].cpu_ticks[CPU_STATE_USER]
                totalSystem += cpuInfo[i].cpu_ticks[CPU_STATE_SYSTEM]
                totalIdle += cpuInfo[i].cpu_ticks[CPU_STATE_IDLE]
            }
            
            let totalTicks = totalUser + totalSystem + totalIdle
            let cpuUsage = totalTicks > 0 ? Double(totalUser + totalSystem) / Double(totalTicks) * 100.0 : 0.0
            
            DispatchQueue.main.async {
                self.cpuUsage = cpuUsage
            }
            
            if cpuUsage > self.maxCPUUsage {
                self.logger.warning("High CPU usage: \(cpuUsage)%")
            }
        }
        
        info.deallocate()
    }
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        // Monitor network requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkRequestStarted),
            name: .networkRequestStarted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkRequestCompleted),
            name: .networkRequestCompleted,
            object: nil
        )
    }
    
    @objc private func networkRequestStarted() {
        DispatchQueue.main.async {
            self.networkRequestCount += 1
        }
    }
    
    @objc private func networkRequestCompleted(notification: Notification) {
        if let latency = notification.userInfo?["latency"] as? Double {
            DispatchQueue.main.async {
                self.networkLatency = latency
            }
            
            if latency > self.maxNetworkLatency {
                self.logger.warning("High network latency: \(latency) ms")
            }
        }
    }
    
    // MARK: - App Launch Time
    func recordAppLaunchTime(_ time: Double) {
        appLaunchTime = time
        logger.info("App launch time: \(time) ms")
        
        if time > 3000.0 { // 3 seconds
            logger.warning("Slow app launch: \(time) ms")
        }
    }
    
    // MARK: - View Load Time
    func recordViewLoadTime(_ viewName: String, time: Double) {
        viewLoadTimes[viewName] = time
        logger.info("View \(viewName) load time: \(time) ms")
        
        if time > maxViewLoadTime {
            logger.warning("Slow view load: \(viewName) - \(time) ms")
        }
    }
    
    // MARK: - Cache Performance
    func recordCacheHit() {
        // This would be called by cache implementations
        updateCacheHitRate()
    }
    
    func recordCacheMiss() {
        // This would be called by cache implementations
        updateCacheHitRate()
    }
    
    private func updateCacheHitRate() {
        // Calculate cache hit rate based on hits vs misses
        // This is a simplified implementation
        let totalRequests = ImageCache.shared.totalRequests
        let hits = ImageCache.shared.hitCount
        
        if totalRequests > 0 {
            cacheHitRate = Double(hits) / Double(totalRequests)
        }
    }
    
    // MARK: - Error Tracking
    func recordError(_ error: Error, context: String) {
        errorCount += 1
        logger.error("Error in \(context): \(error.localizedDescription)")
        
        // Send to crash reporting service
        CrashReporter.shared.recordError(error, context: context)
    }
    
    // MARK: - Performance Metrics
    func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            networkLatency: networkLatency,
            appLaunchTime: appLaunchTime,
            viewLoadTimes: viewLoadTimes,
            networkRequestCount: networkRequestCount,
            cacheHitRate: cacheHitRate,
            errorCount: errorCount,
            timestamp: Date()
        )
    }
    
    // MARK: - Performance Optimization
    func optimizePerformance() {
        // Clear unnecessary caches
        ImageCache.shared.clearOldImages()
        NewsCache.shared.clearOldCache()
        
        // Reduce memory pressure
        if memoryUsage > maxMemoryUsage * 0.8 {
            handleHighMemoryUsage()
        }
        
        // Optimize network requests
        NetworkOptimizer.shared.optimizeRequests()
    }
}

// MARK: - Performance Report
struct PerformanceReport: Codable {
    let memoryUsage: Double
    let cpuUsage: Double
    let networkLatency: Double
    let appLaunchTime: Double
    let viewLoadTimes: [String: Double]
    let networkRequestCount: Int
    let cacheHitRate: Double
    let errorCount: Int
    let timestamp: Date
}

// MARK: - Network Notifications
extension Notification.Name {
    static let networkRequestStarted = Notification.Name("networkRequestStarted")
    static let networkRequestCompleted = Notification.Name("networkRequestCompleted")
}

// MARK: - Image Cache
class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    var totalRequests: Int = 0
    var hitCount: Int = 0
    
    private init() {
        // Configure cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        // Create cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func image(for url: String) -> UIImage? {
        totalRequests += 1
        
        // Check memory cache first
        if let image = cache.object(forKey: url as NSString) {
            hitCount += 1
            return image
        }
        
        // Check disk cache
        if let image = loadImageFromDisk(url: url) {
            cache.setObject(image, forKey: url as NSString)
            hitCount += 1
            return image
        }
        
        return nil
    }
    
    func setImage(_ image: UIImage, for url: String) {
        cache.setObject(image, forKey: url as NSString)
        saveImageToDisk(image: image, url: url)
    }
    
    private func loadImageFromDisk(url: String) -> UIImage? {
        let fileName = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    private func saveImageToDisk(image: UIImage, url: String) {
        let fileName = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    func clearOldImages() {
        // Remove images older than 7 days
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            for file in files {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < sevenDaysAgo {
                    try fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("Error clearing old images: \(error)")
        }
    }
}

// MARK: - News Cache
class NewsCache {
    static let shared = NewsCache()
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_news_articles"
    private let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24 hours
    
    func cacheArticles(_ articles: [NewsArticle]) {
        let cacheData = NewsCacheData(
            articles: articles,
            timestamp: Date()
        )
        
        if let data = try? JSONEncoder().encode(cacheData) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }
    
    func getCachedArticles() -> [NewsArticle]? {
        guard let data = userDefaults.data(forKey: cacheKey),
              let cacheData = try? JSONDecoder().decode(NewsCacheData.self, from: data) else {
            return nil
        }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cacheData.timestamp) > maxCacheAge {
            return nil
        }
        
        return cacheData.articles
    }
    
    func clearOldCache() {
        userDefaults.removeObject(forKey: cacheKey)
    }
}

// MARK: - News Cache Data
struct NewsCacheData: Codable {
    let articles: [NewsArticle]
    let timestamp: Date
}

// MARK: - Network Optimizer
class NetworkOptimizer {
    static let shared = NetworkOptimizer()
    
    private let maxConcurrentRequests = 3
    private let requestQueue = DispatchQueue(label: "network.optimizer", qos: .utility)
    private var activeRequests: Set<String> = []
    
    func optimizeRequests() {
        // Implement request batching, prioritization, and caching
    }
    
    func shouldMakeRequest(_ url: String) -> Bool {
        return !activeRequests.contains(url) && activeRequests.count < maxConcurrentRequests
    }
    
    func startRequest(_ url: String) {
        activeRequests.insert(url)
    }
    
    func endRequest(_ url: String) {
        activeRequests.remove(url)
    }
}

// MARK: - Crash Reporter
class CrashReporter {
    static let shared = CrashReporter()
    
    func recordError(_ error: Error, context: String) {
        // Send to crash reporting service (e.g., Crashlytics, Sentry)
        print("Crash reported: \(error.localizedDescription) in \(context)")
    }
}
