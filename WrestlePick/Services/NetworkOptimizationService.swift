import Foundation
import Network
import Combine
import os.log

class NetworkOptimizationService: ObservableObject {
    static let shared = NetworkOptimizationService()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi
    @Published var isExpensive = false
    @Published var isConstrained = false
    @Published var networkQuality: NetworkQuality = .good
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let logger = Logger(subsystem: "com.wrestlepick", category: "Network")
    
    // Request management
    private var activeRequests: Set<String> = []
    private var requestQueue: [NetworkRequest] = []
    private let maxConcurrentRequests = 3
    private let requestTimeout: TimeInterval = 30.0
    
    // Caching
    private let cache = URLCache.shared
    private let cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad
    
    // Retry logic
    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    
    private init() {
        setupNetworkMonitoring()
        configureURLCache()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        connectionType = getConnectionType(path)
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        networkQuality = calculateNetworkQuality(path)
        
        logger.info("Network status updated - Connected: \(isConnected), Type: \(connectionType.rawValue), Expensive: \(isExpensive), Constrained: \(isConstrained)")
        
        // Process queued requests when connection is restored
        if isConnected && !requestQueue.isEmpty {
            processQueuedRequests()
        }
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    private func calculateNetworkQuality(_ path: NWPath) -> NetworkQuality {
        if !isConnected {
            return .poor
        }
        
        if isConstrained {
            return .poor
        }
        
        if isExpensive {
            return .fair
        }
        
        switch connectionType {
        case .wifi, .ethernet:
            return .excellent
        case .cellular:
            return .good
        case .unknown:
            return .fair
        }
    }
    
    // MARK: - URL Cache Configuration
    private func configureURLCache() {
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 200 * 1024 * 1024 // 200 MB
        
        cache.memoryCapacity = memoryCapacity
        cache.diskCapacity = diskCapacity
    }
    
    // MARK: - Optimized Network Requests
    func makeRequest<T: Codable>(
        _ request: NetworkRequest,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // Check if we should make the request
        guard shouldMakeRequest(request) else {
            if isConnected {
                // Queue the request for later
                queueRequest(request, responseType: responseType, completion: completion)
            } else {
                // Return cached data if available
                returnCachedData(request, responseType: responseType, completion: completion)
            }
            return
        }
        
        // Make the request
        executeRequest(request, responseType: responseType, completion: completion)
    }
    
    private func shouldMakeRequest(_ request: NetworkRequest) -> Bool {
        // Don't make requests if not connected
        guard isConnected else { return false }
        
        // Don't make expensive requests on cellular if user prefers wifi
        if isExpensive && request.priority == .low {
            return false
        }
        
        // Don't make requests if we've hit the concurrent limit
        if activeRequests.count >= maxConcurrentRequests {
            return false
        }
        
        // Don't make requests if network quality is poor and request is not critical
        if networkQuality == .poor && request.priority != .critical {
            return false
        }
        
        return true
    }
    
    private func executeRequest<T: Codable>(
        _ request: NetworkRequest,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        let requestId = UUID().uuidString
        activeRequests.insert(requestId)
        
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = requestTimeout
        urlRequest.cachePolicy = cachePolicy
        
        // Add headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if present
        if let body = request.body {
            urlRequest.httpBody = body
        }
        
        // Track request start time
        let startTime = Date()
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.activeRequests.remove(requestId)
                
                // Calculate latency
                let latency = Date().timeIntervalSince(startTime)
                
                if let error = error {
                    self?.handleRequestError(requestId, error: error, request: request, completion: completion)
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(responseType, from: data)
                    completion(.success(decodedResponse))
                    
                    // Cache the response
                    self?.cacheResponse(data, for: request)
                    
                    // Track successful request
                    self?.trackSuccessfulRequest(request, latency: latency)
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    private func handleRequestError<T: Codable>(
        _ requestId: String,
        error: Error,
        request: NetworkRequest,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        let attemptCount = retryAttempts[requestId] ?? 0
        
        if attemptCount < maxRetryAttempts && shouldRetry(error) {
            // Retry the request
            retryAttempts[requestId] = attemptCount + 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                self.executeRequest(request, responseType: T.self, completion: completion)
            }
        } else {
            // Give up and return error
            retryAttempts.removeValue(forKey: requestId)
            completion(.failure(.networkError(error)))
        }
    }
    
    private func shouldRetry(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    private func queueRequest<T: Codable>(
        _ request: NetworkRequest,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        let queuedRequest = QueuedNetworkRequest(
            request: request,
            responseType: responseType,
            completion: completion
        )
        
        requestQueue.append(queuedRequest)
        logger.info("Request queued: \(request.url.absoluteString)")
    }
    
    private func processQueuedRequests() {
        let requestsToProcess = Array(requestQueue.prefix(maxConcurrentRequests))
        requestQueue.removeFirst(min(requestsToProcess.count, requestQueue.count))
        
        for queuedRequest in requestsToProcess {
            executeRequest(
                queuedRequest.request,
                responseType: queuedRequest.responseType,
                completion: queuedRequest.completion
            )
        }
    }
    
    private func returnCachedData<T: Codable>(
        _ request: NetworkRequest,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // Try to get cached data
        if let cachedResponse = cache.cachedResponse(for: URLRequest(url: request.url)) {
            do {
                let decodedResponse = try JSONDecoder().decode(responseType, from: cachedResponse.data)
                completion(.success(decodedResponse))
                logger.info("Returned cached data for: \(request.url.absoluteString)")
            } catch {
                completion(.failure(.decodingError(error)))
            }
        } else {
            completion(.failure(.noData))
        }
    }
    
    private func cacheResponse(_ data: Data, for request: NetworkRequest) {
        let response = HTTPURLResponse(
            url: request.url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let cachedResponse = CachedURLResponse(response: response, data: data)
        cache.storeCachedResponse(cachedResponse, for: URLRequest(url: request.url))
    }
    
    private func trackSuccessfulRequest(_ request: NetworkRequest, latency: TimeInterval) {
        // Track performance metrics
        PerformanceMonitor.shared.trackPerformance("network_latency", value: latency * 1000, unit: "ms")
        
        // Update analytics
        AnalyticsService.shared.trackEvent("network_request_success", parameters: [
            "url": request.url.absoluteString,
            "latency": latency,
            "connection_type": connectionType.rawValue,
            "network_quality": networkQuality.rawValue
        ])
    }
    
    // MARK: - Request Prioritization
    func prioritizeRequest(_ request: NetworkRequest, priority: RequestPriority) {
        var updatedRequest = request
        updatedRequest.priority = priority
        
        // Move to front of queue if high priority
        if priority == .critical {
            requestQueue.insert(
                QueuedNetworkRequest(
                    request: updatedRequest,
                    responseType: Any.self,
                    completion: { _ in }
                ),
                at: 0
            )
        }
    }
    
    // MARK: - Data Compression
    func compressData(_ data: Data) -> Data? {
        return data.compressed(using: .lzfse)
    }
    
    func decompressData(_ data: Data) -> Data? {
        return data.decompressed(using: .lzfse)
    }
    
    // MARK: - Request Batching
    func batchRequests(_ requests: [NetworkRequest]) -> [NetworkRequest] {
        // Group requests by endpoint
        let groupedRequests = Dictionary(grouping: requests) { $0.url.host }
        
        var batchedRequests: [NetworkRequest] = []
        
        for (host, hostRequests) in groupedRequests {
            if hostRequests.count > 1 {
                // Create batched request
                let batchedRequest = createBatchedRequest(hostRequests, host: host)
                batchedRequests.append(batchedRequest)
            } else {
                batchedRequests.append(contentsOf: hostRequests)
            }
        }
        
        return batchedRequests
    }
    
    private func createBatchedRequest(_ requests: [NetworkRequest], host: String) -> NetworkRequest {
        // This is a simplified implementation
        // In reality, you'd need to create a proper batch endpoint
        let batchURL = URL(string: "https://\(host)/batch")!
        
        return NetworkRequest(
            url: batchURL,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: try? JSONEncoder().encode(requests),
            priority: .normal
        )
    }
    
    // MARK: - Network Quality Optimization
    func optimizeForNetworkQuality() {
        switch networkQuality {
        case .excellent:
            // Use full quality
            maxConcurrentRequests = 5
        case .good:
            // Use good quality
            maxConcurrentRequests = 3
        case .fair:
            // Use reduced quality
            maxConcurrentRequests = 2
        case .poor:
            // Use minimal quality
            maxConcurrentRequests = 1
        }
    }
    
    // MARK: - Cleanup
    func clearCache() {
        cache.removeAllCachedResponses()
    }
    
    func clearOldCache() {
        // Remove cached responses older than 24 hours
        let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        // Implementation would depend on your specific caching strategy
    }
}

// MARK: - Network Request
struct NetworkRequest {
    let url: URL
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
    var priority: RequestPriority
    
    init(url: URL, method: HTTPMethod = .GET, headers: [String: String] = [:], body: Data? = nil, priority: RequestPriority = .normal) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.priority = priority
    }
}

// MARK: - Queued Network Request
struct QueuedNetworkRequest {
    let request: NetworkRequest
    let responseType: Any.Type
    let completion: (Result<Any, NetworkError>) -> Void
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Request Priority
enum RequestPriority: Int, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
}

// MARK: - Connection Type
enum ConnectionType: String, CaseIterable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case unknown = "unknown"
}

// MARK: - Network Quality
enum NetworkQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
}

// MARK: - Network Error
enum NetworkError: Error, LocalizedError {
    case noData
    case networkError(Error)
    case decodingError(Error)
    case timeout
    case noConnection
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No data received"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .noConnection:
            return "No internet connection"
        }
    }
}

// MARK: - Data Compression Extension
extension Data {
    func compressed(using algorithm: NSData.CompressionAlgorithm) -> Data? {
        return (self as NSData).compressed(using: algorithm)
    }
    
    func decompressed(using algorithm: NSData.CompressionAlgorithm) -> Data? {
        return (self as NSData).decompressed(using: algorithm)
    }
}
