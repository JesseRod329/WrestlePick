import Foundation
import Combine
import os.log

class LiveEventDataService: ObservableObject {
    static let shared = LiveEventDataService()
    
    @Published var upcomingEvents: [WrestlingEvent] = []
    @Published var liveEvents: [WrestlingEvent] = []
    @Published var completedEvents: [WrestlingEvent] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var error: Error?
    
    private let logger = Logger(subsystem: "com.wrestlepick", category: "LiveEventData")
    private var cancellables = Set<AnyCancellable>()
    private let cache = EventCache.shared
    private var refreshTimer: Timer?
    
    // Event data sources
    private let eventSources: [EventDataSource] = [
        EventDataSource(
            name: "WWE Official Schedule",
            baseURL: "https://www.wwe.com/schedule",
            promotion: .wwe,
            reliability: .tier1
        ),
        EventDataSource(
            name: "AEW Official Schedule",
            baseURL: "https://www.allelitewrestling.com/schedule",
            promotion: .aew,
            reliability: .tier1
        ),
        EventDataSource(
            name: "NJPW Official Schedule",
            baseURL: "https://www.njpw1972.com/schedule",
            promotion: .njpw,
            reliability: .tier1
        ),
        EventDataSource(
            name: "Impact Wrestling Schedule",
            baseURL: "https://www.impactwrestling.com/schedule",
            promotion: .impact,
            reliability: .tier1
        )
    ]
    
    private init() {
        loadCachedEvents()
        startPeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func refreshEventData() {
        isLoading = true
        error = nil
        
        let group = DispatchGroup()
        var allEvents: [WrestlingEvent] = []
        let queue = DispatchQueue(label: "event.data", qos: .utility)
        
        for source in eventSources {
            group.enter()
            
            queue.async {
                self.fetchEventsFromSource(source) { result in
                    switch result {
                    case .success(let events):
                        allEvents.append(contentsOf: events)
                    case .failure(let error):
                        self.logger.error("Failed to fetch events from \(source.name): \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.processEvents(allEvents)
            self.isLoading = false
            self.lastUpdateTime = Date()
        }
    }
    
    func getUpcomingEvents(for promotion: WrestlingPromotion? = nil) -> [WrestlingEvent] {
        let events = promotion != nil ? 
            upcomingEvents.filter { $0.promotion == promotion } : 
            upcomingEvents
        
        return events.sorted { $0.date < $1.date }
    }
    
    func getLiveEvents() -> [WrestlingEvent] {
        return liveEvents.filter { $0.status == .live }
    }
    
    func getEvent(by id: String) -> WrestlingEvent? {
        return upcomingEvents.first { $0.id == id } ??
               liveEvents.first { $0.id == id } ??
               completedEvents.first { $0.id == id }
    }
    
    func getEventsByDate(_ date: Date) -> [WrestlingEvent] {
        let calendar = Calendar.current
        return (upcomingEvents + liveEvents + completedEvents).filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
    
    // MARK: - Private Methods
    private func fetchEventsFromSource(_ source: EventDataSource, completion: @escaping (Result<[WrestlingEvent], Error>) -> Void) {
        // In a real implementation, this would make HTTP requests to the data sources
        // For now, we'll use mock data that represents real events
        
        let mockEvents = generateMockEventsForPromotion(source.promotion)
        completion(.success(mockEvents))
    }
    
    private func generateMockEventsForPromotion(_ promotion: WrestlingPromotion) -> [WrestlingEvent] {
        switch promotion {
        case .wwe:
            return generateWWEEvents()
        case .aew:
            return generateAEWEvents()
        case .njpw:
            return generateNJPWEvents()
        case .impact:
            return generateImpactEvents()
        case .roh:
            return generateROHEvents()
        case .indie:
            return generateIndieEvents()
        }
    }
    
    private func generateWWEEvents() -> [WrestlingEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            WrestlingEvent(
                id: "wwe-1",
                name: "WrestleMania 40",
                promotion: .wwe,
                date: calendar.date(byAdding: .day, value: 30, to: now) ?? now,
                venue: Venue(
                    name: "Lincoln Financial Field",
                    city: "Philadelphia",
                    state: "Pennsylvania",
                    country: "United States",
                    capacity: 70000
                ),
                eventType: .ppv,
                matches: generateWrestleManiaMatches(),
                ticketInfo: TicketInfo(
                    onSaleDate: calendar.date(byAdding: .day, value: -60, to: now) ?? now,
                    priceRange: "$50 - $500",
                    availability: .available,
                    purchaseURL: "https://www.ticketmaster.com/wrestlemania-40"
                ),
                streamingInfo: StreamingInfo(
                    platform: "Peacock",
                    price: "$4.99/month",
                    startTime: calendar.date(byAdding: .hour, value: 7, to: now) ?? now
                ),
                status: .scheduled,
                description: "The Grandest Stage of Them All returns to Philadelphia for WrestleMania 40!",
                imageURL: "https://www.wwe.com/f/styles/wwe_large/public/all/2024/01/WrestleMania_40--20240127_RAW_00000000_01_16_9still_001.jpg",
                socialMedia: EventSocialMedia(
                    hashtag: "#WrestleMania40",
                    twitter: "WWE",
                    instagram: "wwe"
                )
            ),
            WrestlingEvent(
                id: "wwe-2",
                name: "Monday Night Raw",
                promotion: .wwe,
                date: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
                venue: Venue(
                    name: "Madison Square Garden",
                    city: "New York",
                    state: "New York",
                    country: "United States",
                    capacity: 20789
                ),
                eventType: .tv,
                matches: generateRawMatches(),
                ticketInfo: TicketInfo(
                    onSaleDate: calendar.date(byAdding: .day, value: -30, to: now) ?? now,
                    priceRange: "$25 - $150",
                    availability: .limited,
                    purchaseURL: "https://www.ticketmaster.com/monday-night-raw"
                ),
                streamingInfo: StreamingInfo(
                    platform: "USA Network",
                    price: "Included with cable",
                    startTime: calendar.date(byAdding: .hour, value: 8, to: now) ?? now
                ),
                status: .scheduled,
                description: "The longest-running weekly episodic program in television history!",
                imageURL: "https://www.wwe.com/f/styles/wwe_large/public/all/2024/01/Raw--20240127_RAW_00000000_01_16_9still_001.jpg",
                socialMedia: EventSocialMedia(
                    hashtag: "#WWERaw",
                    twitter: "WWE",
                    instagram: "wwe"
                )
            )
        ]
    }
    
    private func generateAEWEvents() -> [WrestlingEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            WrestlingEvent(
                id: "aew-1",
                name: "AEW Revolution 2024",
                promotion: .aew,
                date: calendar.date(byAdding: .day, value: 45, to: now) ?? now,
                venue: Venue(
                    name: "Greensboro Coliseum",
                    city: "Greensboro",
                    state: "North Carolina",
                    country: "United States",
                    capacity: 23500
                ),
                eventType: .ppv,
                matches: generateAEWRevolutionMatches(),
                ticketInfo: TicketInfo(
                    onSaleDate: calendar.date(byAdding: .day, value: -45, to: now) ?? now,
                    priceRange: "$30 - $200",
                    availability: .available,
                    purchaseURL: "https://www.ticketmaster.com/aew-revolution-2024"
                ),
                streamingInfo: StreamingInfo(
                    platform: "Bleacher Report",
                    price: "$49.99",
                    startTime: calendar.date(byAdding: .hour, value: 8, to: now) ?? now
                ),
                status: .scheduled,
                description: "AEW Revolution returns to Greensboro for another night of incredible action!",
                imageURL: "https://www.allelitewrestling.com/sites/default/files/2024/01/Revolution_2024.jpg",
                socialMedia: EventSocialMedia(
                    hashtag: "#AEWRevolution",
                    twitter: "AEW",
                    instagram: "allelitewrestling"
                )
            )
        ]
    }
    
    private func generateNJPWEvents() -> [WrestlingEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            WrestlingEvent(
                id: "njpw-1",
                name: "Wrestle Kingdom 18",
                promotion: .njpw,
                date: calendar.date(byAdding: .day, value: 60, to: now) ?? now,
                venue: Venue(
                    name: "Tokyo Dome",
                    city: "Tokyo",
                    state: "Tokyo",
                    country: "Japan",
                    capacity: 55000
                ),
                eventType: .ppv,
                matches: generateWrestleKingdomMatches(),
                ticketInfo: TicketInfo(
                    onSaleDate: calendar.date(byAdding: .day, value: -90, to: now) ?? now,
                    priceRange: "¥3,000 - ¥15,000",
                    availability: .soldOut,
                    purchaseURL: "https://www.njpw1972.com/tickets"
                ),
                streamingInfo: StreamingInfo(
                    platform: "NJPW World",
                    price: "¥999/month",
                    startTime: calendar.date(byAdding: .hour, value: 16, to: now) ?? now
                ),
                status: .scheduled,
                description: "The biggest event in Japanese professional wrestling!",
                imageURL: "https://www.njpw1972.com/wp-content/uploads/2024/01/WK18.jpg",
                socialMedia: EventSocialMedia(
                    hashtag: "#WK18",
                    twitter: "njpw1972",
                    instagram: "njpw1972"
                )
            )
        ]
    }
    
    private func generateImpactEvents() -> [WrestlingEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            WrestlingEvent(
                id: "impact-1",
                name: "Impact Wrestling: Hard To Kill 2024",
                promotion: .impact,
                date: calendar.date(byAdding: .day, value: 20, to: now) ?? now,
                venue: Venue(
                    name: "Palms Casino Resort",
                    city: "Las Vegas",
                    state: "Nevada",
                    country: "United States",
                    capacity: 2500
                ),
                eventType: .ppv,
                matches: generateImpactHardToKillMatches(),
                ticketInfo: TicketInfo(
                    onSaleDate: calendar.date(byAdding: .day, value: -30, to: now) ?? now,
                    priceRange: "$25 - $100",
                    availability: .available,
                    purchaseURL: "https://www.impactwrestling.com/tickets"
                ),
                streamingInfo: StreamingInfo(
                    platform: "FITE TV",
                    price: "$39.99",
                    startTime: calendar.date(byAdding: .hour, value: 8, to: now) ?? now
                ),
                status: .scheduled,
                description: "Impact Wrestling's biggest event of the year!",
                imageURL: "https://www.impactwrestling.com/sites/default/files/2024/01/HardToKill_2024.jpg",
                socialMedia: EventSocialMedia(
                    hashtag: "#HardToKill",
                    twitter: "IMPACTWRESTLING",
                    instagram: "impactwrestling"
                )
            )
        ]
    }
    
    private func generateROHEvents() -> [WrestlingEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            WrestlingEvent(
                id: "roh-1",
                name: "ROH Supercard of Honor 2024",
                promotion: .roh,
                date: calendar.date(byAdding: .day, value: 40, to: now) ?? now,
                venue: Venue(
                    name: "Galen Center",
                    city: "Los Angeles",
                    state: "California",
                    country: "United States",
                    capacity: 10258
                ),
                eventType: .ppv,
                matches: generateROHSupercardMatches(),
                ticketInfo: TicketInfo(
                    onSaleDate: calendar.date(byAdding: .day, value: -45, to: now) ?? now,
                    priceRange: "$20 - $80",
                    availability: .available,
                    purchaseURL: "https://www.rohwrestling.com/tickets"
                ),
                streamingInfo: StreamingInfo(
                    platform: "Honor Club",
                    price: "$9.99/month",
                    startTime: calendar.date(byAdding: .hour, value: 8, to: now) ?? now
                ),
                status: .scheduled,
                description: "Ring of Honor's premier event returns to Los Angeles!",
                imageURL: "https://www.rohwrestling.com/sites/default/files/2024/01/Supercard_2024.jpg",
                socialMedia: EventSocialMedia(
                    hashtag: "#ROHSupercard",
                    twitter: "ringofhonor",
                    instagram: "ringofhonor"
                )
            )
        ]
    }
    
    private func generateIndieEvents() -> [WrestlingEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            WrestlingEvent(
                id: "indie-1",
                name: "GCW: The Wrld on GCW",
                promotion: .indie,
                date: calendar.date(byAdding: .day, value: 15, to: now) ?? now,
                venue: Venue(
                    name: "Hammerstein Ballroom",
                    city: "New York",
                    state: "New York",
                    country: "United States",
                    capacity: 2500
                ),
                eventType: .liveEvent,
                matches: generateGCWMatches(),
                ticketInfo: TicketInfo(
                    onSaleDate: calendar.date(byAdding: .day, value: -20, to: now) ?? now,
                    priceRange: "$15 - $50",
                    availability: .available,
                    purchaseURL: "https://www.gcwrestling.com/tickets"
                ),
                streamingInfo: StreamingInfo(
                    platform: "FITE TV",
                    price: "$19.99",
                    startTime: calendar.date(byAdding: .hour, value: 8, to: now) ?? now
                ),
                status: .scheduled,
                description: "Game Changer Wrestling's biggest event of the year!",
                imageURL: "https://www.gcwrestling.com/sites/default/files/2024/01/Wrld_2024.jpg",
                socialMedia: EventSocialMedia(
                    hashtag: "#GCWWrld",
                    twitter: "GCWrestling",
                    instagram: "gcwrestling"
                )
            )
        ]
    }
    
    // MARK: - Match Generation
    private func generateWrestleManiaMatches() -> [Match] {
        return [
            Match(
                id: "wm40-1",
                name: "WWE Universal Championship Match",
                participants: ["Roman Reigns", "Cody Rhodes"],
                matchType: .singles,
                stipulation: "Championship Match",
                estimatedDuration: 25.0,
                isMainEvent: true,
                isOpener: false,
                description: "The Tribal Chief defends his Universal Championship against the American Nightmare"
            ),
            Match(
                id: "wm40-2",
                name: "WWE Championship Match",
                participants: ["Seth Rollins", "Drew McIntyre"],
                matchType: .singles,
                stipulation: "Championship Match",
                estimatedDuration: 20.0,
                isMainEvent: false,
                isOpener: false,
                description: "The Visionary defends his WWE Championship against the Scottish Warrior"
            )
        ]
    }
    
    private func generateRawMatches() -> [Match] {
        return [
            Match(
                id: "raw-1",
                name: "Tag Team Match",
                participants: ["The Usos", "The New Day"],
                matchType: .tagTeam,
                stipulation: "Standard Tag Team Match",
                estimatedDuration: 15.0,
                isMainEvent: false,
                isOpener: true,
                description: "Tag team action on Monday Night Raw"
            )
        ]
    }
    
    private func generateAEWRevolutionMatches() -> [Match] {
        return [
            Match(
                id: "aew-rev-1",
                name: "AEW World Championship Match",
                participants: ["Jon Moxley", "Kenny Omega"],
                matchType: .singles,
                stipulation: "Championship Match",
                estimatedDuration: 30.0,
                isMainEvent: true,
                isOpener: false,
                description: "The Death Rider defends his AEW World Championship against the Cleaner"
            )
        ]
    }
    
    private func generateWrestleKingdomMatches() -> [Match] {
        return [
            Match(
                id: "wk18-1",
                name: "IWGP Heavyweight Championship Match",
                participants: ["Kazuchika Okada", "Tetsuya Naito"],
                matchType: .singles,
                stipulation: "Championship Match",
                estimatedDuration: 35.0,
                isMainEvent: true,
                isOpener: false,
                description: "The Rainmaker defends his IWGP Heavyweight Championship against El Ingobernable"
            )
        ]
    }
    
    private func generateImpactHardToKillMatches() -> [Match] {
        return [
            Match(
                id: "impact-htk-1",
                name: "Impact World Championship Match",
                participants: ["Rich Swann", "Moose"],
                matchType: .singles,
                stipulation: "Championship Match",
                estimatedDuration: 20.0,
                isMainEvent: true,
                isOpener: false,
                description: "The Impact World Championship is on the line"
            )
        ]
    }
    
    private func generateROHSupercardMatches() -> [Match] {
        return [
            Match(
                id: "roh-sc-1",
                name: "ROH World Championship Match",
                participants: ["Rush", "Bandido"],
                matchType: .singles,
                stipulation: "Championship Match",
                estimatedDuration: 25.0,
                isMainEvent: true,
                isOpener: false,
                description: "The ROH World Championship is up for grabs"
            )
        ]
    }
    
    private func generateGCWMatches() -> [Match] {
        return [
            Match(
                id: "gcw-1",
                name: "GCW Championship Match",
                participants: ["Orange Cassidy", "Nick Gage"],
                matchType: .singles,
                stipulation: "Championship Match",
                estimatedDuration: 15.0,
                isMainEvent: true,
                isOpener: false,
                description: "Independent wrestling at its finest"
            )
        ]
    }
    
    private func processEvents(_ newEvents: [WrestlingEvent]) {
        let now = Date()
        
        // Categorize events by status
        let upcoming = newEvents.filter { $0.date > now && $0.status == .scheduled }
        let live = newEvents.filter { $0.status == .live }
        let completed = newEvents.filter { $0.date <= now && $0.status == .completed }
        
        // Remove duplicates and merge data
        let uniqueUpcoming = removeDuplicateEvents(upcoming)
        let uniqueLive = removeDuplicateEvents(live)
        let uniqueCompleted = removeDuplicateEvents(completed)
        
        // Update published events
        DispatchQueue.main.async {
            self.upcomingEvents = uniqueUpcoming
            self.liveEvents = uniqueLive
            self.completedEvents = uniqueCompleted
            self.cacheEvents(uniqueUpcoming + uniqueLive + uniqueCompleted)
        }
    }
    
    private func removeDuplicateEvents(_ events: [WrestlingEvent]) -> [WrestlingEvent] {
        var uniqueEvents: [WrestlingEvent] = []
        var seenEvents: Set<String> = []
        
        for event in events {
            if !seenEvents.contains(event.id) {
                seenEvents.insert(event.id)
                uniqueEvents.append(event)
            }
        }
        
        return uniqueEvents
    }
    
    private func startPeriodicRefresh() {
        // Refresh every 5 minutes for live events, every hour for upcoming events
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            self?.refreshEventData()
        }
    }
    
    private func cacheEvents(_ events: [WrestlingEvent]) {
        cache.cacheEvents(events)
    }
    
    private func loadCachedEvents() {
        if let cachedEvents = cache.getCachedEvents() {
            let now = Date()
            upcomingEvents = cachedEvents.filter { $0.date > now && $0.status == .scheduled }
            liveEvents = cachedEvents.filter { $0.status == .live }
            completedEvents = cachedEvents.filter { $0.date <= now && $0.status == .completed }
        }
    }
}

// MARK: - Supporting Types
struct EventDataSource {
    let name: String
    let baseURL: String
    let promotion: WrestlingPromotion
    let reliability: ReliabilityTier
}

struct Venue {
    let name: String
    let city: String
    let state: String
    let country: String
    let capacity: Int
}

struct TicketInfo {
    let onSaleDate: Date
    let priceRange: String
    let availability: TicketAvailability
    let purchaseURL: String
}

enum TicketAvailability {
    case available
    case limited
    case soldOut
    case notAvailable
}

struct StreamingInfo {
    let platform: String
    let price: String
    let startTime: Date
}

struct EventSocialMedia {
    let hashtag: String
    let twitter: String
    let instagram: String
}

// MARK: - Event Cache
class EventCache {
    static let shared = EventCache()
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_events"
    private let maxCacheAge: TimeInterval = 60 * 60 // 1 hour
    
    func cacheEvents(_ events: [WrestlingEvent]) {
        let cacheData = EventCacheData(
            events: events,
            timestamp: Date()
        )
        
        if let data = try? JSONEncoder().encode(cacheData) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }
    
    func getCachedEvents() -> [WrestlingEvent]? {
        guard let data = userDefaults.data(forKey: cacheKey),
              let cacheData = try? JSONDecoder().decode(EventCacheData.self, from: data) else {
            return nil
        }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cacheData.timestamp) > maxCacheAge {
            return nil
        }
        
        return cacheData.events
    }
    
    func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
    }
}

struct EventCacheData: Codable {
    let events: [WrestlingEvent]
    let timestamp: Date
}
