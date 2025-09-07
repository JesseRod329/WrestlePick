import Foundation
import Combine
import os.log

class WrestlerDataService: ObservableObject {
    static let shared = WrestlerDataService()
    
    @Published var wrestlers: [Wrestler] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var error: Error?
    
    private let logger = Logger(subsystem: "com.wrestlepick", category: "WrestlerData")
    private var cancellables = Set<AnyCancellable>()
    private let cache = WrestlerCache.shared
    
    // Data sources for wrestler information
    private let dataSources: [WrestlerDataSource] = [
        WrestlerDataSource(
            name: "WWE Official Roster",
            baseURL: "https://www.wwe.com/superstars",
            promotion: .wwe,
            reliability: .tier1
        ),
        WrestlerDataSource(
            name: "AEW Official Roster",
            baseURL: "https://www.allelitewrestling.com/roster",
            promotion: .aew,
            reliability: .tier1
        ),
        WrestlerDataSource(
            name: "NJPW Official Roster",
            baseURL: "https://www.njpw1972.com/roster",
            promotion: .njpw,
            reliability: .tier1
        ),
        WrestlerDataSource(
            name: "Cagematch Database",
            baseURL: "https://www.cagematch.net",
            promotion: .indie,
            reliability: .tier2
        )
    ]
    
    private init() {
        loadCachedWrestlers()
        refreshWrestlerData()
    }
    
    // MARK: - Public Methods
    func refreshWrestlerData() {
        isLoading = true
        error = nil
        
        let group = DispatchGroup()
        var allWrestlers: [Wrestler] = []
        let queue = DispatchQueue(label: "wrestler.data", qos: .utility)
        
        for source in dataSources {
            group.enter()
            
            queue.async {
                self.fetchWrestlersFromSource(source) { result in
                    switch result {
                    case .success(let wrestlers):
                        allWrestlers.append(contentsOf: wrestlers)
                    case .failure(let error):
                        self.logger.error("Failed to fetch wrestlers from \(source.name): \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.processWrestlers(allWrestlers)
            self.isLoading = false
            self.lastUpdateTime = Date()
        }
    }
    
    func getWrestler(by id: String) -> Wrestler? {
        return wrestlers.first { $0.id == id }
    }
    
    func getWrestlers(by promotion: WrestlingPromotion) -> [Wrestler] {
        return wrestlers.filter { $0.promotions.contains(promotion) }
    }
    
    func searchWrestlers(query: String) -> [Wrestler] {
        let lowercaseQuery = query.lowercased()
        return wrestlers.filter { wrestler in
            wrestler.name.lowercased().contains(lowercaseQuery) ||
            wrestler.realName?.lowercased().contains(lowercaseQuery) == true ||
            wrestler.ringName.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Private Methods
    private func fetchWrestlersFromSource(_ source: WrestlerDataSource, completion: @escaping (Result<[Wrestler], Error>) -> Void) {
        // In a real implementation, this would make HTTP requests to the data sources
        // For now, we'll use mock data that represents real wrestlers
        
        let mockWrestlers = generateMockWrestlersForPromotion(source.promotion)
        completion(.success(mockWrestlers))
    }
    
    private func generateMockWrestlersForPromotion(_ promotion: WrestlingPromotion) -> [Wrestler] {
        switch promotion {
        case .wwe:
            return generateWWEwrestlers()
        case .aew:
            return generateAEWwrestlers()
        case .njpw:
            return generateNJPWwrestlers()
        case .impact:
            return generateImpactWrestlers()
        case .roh:
            return generateROHwrestlers()
        case .indie:
            return generateIndieWrestlers()
        }
    }
    
    private func generateWWEwrestlers() -> [Wrestler] {
        return [
            Wrestler(
                id: "wwe-1",
                name: "Roman Reigns",
                realName: "Leati Joseph Anoa'i",
                ringName: "Roman Reigns",
                promotions: [.wwe],
                hometown: "Pensacola, Florida",
                height: "6'3\"",
                weight: "265 lbs",
                debut: Date(timeIntervalSince1970: 1262304000), // 2010
                championships: [
                    Championship(
                        name: "WWE Universal Championship",
                        promotion: .wwe,
                        currentHolder: true,
                        reignNumber: 1,
                        daysHeld: 1200,
                        wonDate: Date(timeIntervalSince1970: 1598918400) // 2020
                    )
                ],
                photoURL: "https://www.wwe.com/f/styles/wwe_large/public/all/2020/08/Roman_Reigns--20200831_RAW_00000000_01_16_9still_001.jpg",
                socialMedia: SocialMediaLinks(
                    twitter: "WWERomanReigns",
                    instagram: "romanreigns",
                    youtube: nil
                ),
                isActive: true,
                currentPromotion: .wwe,
                status: .active,
                specialties: ["Powerhouse", "Brawler", "Leader"],
                signatureMoves: ["Spear", "Superman Punch", "Guillotine Choke"],
                achievements: ["4x WWE Champion", "1x Universal Champion", "Royal Rumble Winner 2015"],
                biography: "The Tribal Chief and Head of the Table, Roman Reigns is one of WWE's most dominant superstars.",
                statistics: WrestlerStatistics(
                    totalMatches: 450,
                    wins: 320,
                    losses: 130,
                    winPercentage: 71.1,
                    averageMatchLength: 12.5,
                    championshipReigns: 5
                )
            ),
            Wrestler(
                id: "wwe-2",
                name: "Seth Rollins",
                realName: "Colby Lopez",
                ringName: "Seth Rollins",
                promotions: [.wwe],
                hometown: "Davenport, Iowa",
                height: "6'1\"",
                weight: "205 lbs",
                debut: Date(timeIntervalSince1970: 1136073600), // 2006
                championships: [
                    Championship(
                        name: "WWE World Heavyweight Championship",
                        promotion: .wwe,
                        currentHolder: false,
                        reignNumber: 2,
                        daysHeld: 220,
                        wonDate: Date(timeIntervalSince1970: 1554076800) // 2019
                    )
                ],
                photoURL: "https://www.wwe.com/f/styles/wwe_large/public/all/2020/08/Seth_Rollins--20200831_RAW_00000000_01_16_9still_001.jpg",
                socialMedia: SocialMediaLinks(
                    twitter: "WWERollins",
                    instagram: "thesethrollins",
                    youtube: nil
                ),
                isActive: true,
                currentPromotion: .wwe,
                status: .active,
                specialties: ["High Flyer", "Technical", "Striker"],
                signatureMoves: ["Curb Stomp", "Falcon Arrow", "Phoenix Splash"],
                achievements: ["2x WWE Champion", "1x Universal Champion", "Money in the Bank Winner 2014"],
                biography: "The Architect, Seth Rollins is known for his innovative offense and technical prowess.",
                statistics: WrestlerStatistics(
                    totalMatches: 380,
                    wins: 250,
                    losses: 130,
                    winPercentage: 65.8,
                    averageMatchLength: 15.2,
                    championshipReigns: 3
                )
            )
        ]
    }
    
    private func generateAEWwrestlers() -> [Wrestler] {
        return [
            Wrestler(
                id: "aew-1",
                name: "Jon Moxley",
                realName: "Jonathan Good",
                ringName: "Jon Moxley",
                promotions: [.aew],
                hometown: "Cincinnati, Ohio",
                height: "6'1\"",
                weight: "225 lbs",
                debut: Date(timeIntervalSince1970: 1104537600), // 2005
                championships: [
                    Championship(
                        name: "AEW World Championship",
                        promotion: .aew,
                        currentHolder: false,
                        reignNumber: 1,
                        daysHeld: 277,
                        wonDate: Date(timeIntervalSince1970: 1577750400) // 2020
                    )
                ],
                photoURL: "https://www.allelitewrestling.com/sites/default/files/2020-02/Jon_Moxley.jpg",
                socialMedia: SocialMediaLinks(
                    twitter: "JonMoxley",
                    instagram: "jonmoxley",
                    youtube: nil
                ),
                isActive: true,
                currentPromotion: .aew,
                status: .active,
                specialties: ["Brawler", "Hardcore", "Striker"],
                signatureMoves: ["Paradigm Shift", "Dirty Deeds", "Regal Stretch"],
                achievements: ["1x AEW World Champion", "3x WWE Champion", "1x IWGP US Champion"],
                biography: "The Death Rider, Jon Moxley brings an unpredictable and hardcore style to AEW.",
                statistics: WrestlerStatistics(
                    totalMatches: 520,
                    wins: 350,
                    losses: 170,
                    winPercentage: 67.3,
                    averageMatchLength: 18.7,
                    championshipReigns: 8
                )
            )
        ]
    }
    
    private func generateNJPWwrestlers() -> [Wrestler] {
        return [
            Wrestler(
                id: "njpw-1",
                name: "Kazuchika Okada",
                realName: "Kazuchika Okada",
                ringName: "Kazuchika Okada",
                promotions: [.njpw],
                hometown: "Anjo, Aichi, Japan",
                height: "6'3\"",
                weight: "230 lbs",
                debut: Date(timeIntervalSince1970: 1136073600), // 2006
                championships: [
                    Championship(
                        name: "IWGP Heavyweight Championship",
                        promotion: .njpw,
                        currentHolder: false,
                        reignNumber: 5,
                        daysHeld: 720,
                        wonDate: Date(timeIntervalSince1970: 1483228800) // 2017
                    )
                ],
                photoURL: "https://www.njpw1972.com/wp-content/uploads/2020/08/okada.jpg",
                socialMedia: SocialMediaLinks(
                    twitter: "rainmakerXokada",
                    instagram: "rainmakerxokada",
                    youtube: nil
                ),
                isActive: true,
                currentPromotion: .njpw,
                status: .active,
                specialties: ["Technical", "Striker", "High Flyer"],
                signatureMoves: ["Rainmaker", "Tombstone Piledriver", "Dropkick"],
                achievements: ["5x IWGP Heavyweight Champion", "G1 Climax Winner 2012, 2014", "New Japan Cup Winner 2013"],
                biography: "The Rainmaker, Kazuchika Okada is considered one of the best wrestlers in the world.",
                statistics: WrestlerStatistics(
                    totalMatches: 680,
                    wins: 450,
                    losses: 230,
                    winPercentage: 66.2,
                    averageMatchLength: 22.3,
                    championshipReigns: 7
                )
            )
        ]
    }
    
    private func generateImpactWrestlers() -> [Wrestler] {
        return [
            Wrestler(
                id: "impact-1",
                name: "Rich Swann",
                realName: "Richard Swann",
                ringName: "Rich Swann",
                promotions: [.impact],
                hometown: "Baltimore, Maryland",
                height: "5'8\"",
                weight: "175 lbs",
                debut: Date(timeIntervalSince1970: 1230768000), // 2009
                championships: [
                    Championship(
                        name: "Impact World Championship",
                        promotion: .impact,
                        currentHolder: false,
                        reignNumber: 1,
                        daysHeld: 120,
                        wonDate: Date(timeIntervalSince1970: 1609459200) // 2021
                    )
                ],
                photoURL: "https://www.impactwrestling.com/sites/default/files/2020/08/rich_swann.jpg",
                socialMedia: SocialMediaLinks(
                    twitter: "GottaGetSwann",
                    instagram: "gottagetswann",
                    youtube: nil
                ),
                isActive: true,
                currentPromotion: .impact,
                status: .active,
                specialties: ["High Flyer", "Technical", "Striker"],
                signatureMoves: ["Phoenix Splash", "Standing 450 Splash", "Lethal Injection"],
                achievements: ["1x Impact World Champion", "1x WWE Cruiserweight Champion", "1x TNA X Division Champion"],
                biography: "Rich Swann brings high-flying action and technical expertise to Impact Wrestling.",
                statistics: WrestlerStatistics(
                    totalMatches: 420,
                    wins: 280,
                    losses: 140,
                    winPercentage: 66.7,
                    averageMatchLength: 14.8,
                    championshipReigns: 4
                )
            )
        ]
    }
    
    private func generateROHwrestlers() -> [Wrestler] {
        return [
            Wrestler(
                id: "roh-1",
                name: "Rush",
                realName: "William Arturo Rios Ruiz",
                ringName: "Rush",
                promotions: [.roh],
                hometown: "Monterrey, Mexico",
                height: "5'10\"",
                weight: "200 lbs",
                debut: Date(timeIntervalSince1970: 1230768000), // 2009
                championships: [
                    Championship(
                        name: "ROH World Championship",
                        promotion: .roh,
                        currentHolder: false,
                        reignNumber: 1,
                        daysHeld: 180,
                        wonDate: Date(timeIntervalSince1970: 1577750400) // 2020
                    )
                ],
                photoURL: "https://www.rohwrestling.com/sites/default/files/2020/08/rush.jpg",
                socialMedia: SocialMediaLinks(
                    twitter: "RushLucha",
                    instagram: "rushlucha",
                    youtube: nil
                ),
                isActive: true,
                currentPromotion: .roh,
                status: .active,
                specialties: ["Lucha Libre", "Striker", "Brawler"],
                signatureMoves: ["Bull's Horns", "Rush Driver", "Tope Con Hilo"],
                achievements: ["1x ROH World Champion", "2x CMLL World Heavyweight Champion", "1x IWGP Intercontinental Champion"],
                biography: "Rush brings the intensity and lucha libre style to Ring of Honor.",
                statistics: WrestlerStatistics(
                    totalMatches: 380,
                    wins: 250,
                    losses: 130,
                    winPercentage: 65.8,
                    averageMatchLength: 16.5,
                    championshipReigns: 5
                )
            )
        ]
    }
    
    private func generateIndieWrestlers() -> [Wrestler] {
        return [
            Wrestler(
                id: "indie-1",
                name: "Orange Cassidy",
                realName: "James Cipperly",
                ringName: "Orange Cassidy",
                promotions: [.indie, .aew],
                hometown: "New York, New York",
                height: "5'10\"",
                weight: "180 lbs",
                debut: Date(timeIntervalSince1970: 1104537600), // 2005
                championships: [
                    Championship(
                        name: "AEW International Championship",
                        promotion: .aew,
                        currentHolder: false,
                        reignNumber: 1,
                        daysHeld: 90,
                        wonDate: Date(timeIntervalSince1970: 1609459200) // 2021
                    )
                ],
                photoURL: "https://www.allelitewrestling.com/sites/default/files/2020/02/Orange_Cassidy.jpg",
                socialMedia: SocialMediaLinks(
                    twitter: "OrangeCassidy",
                    instagram: "orangecassidy",
                    youtube: nil
                ),
                isActive: true,
                currentPromotion: .aew,
                status: .active,
                specialties: ["Comedy", "Technical", "High Flyer"],
                signatureMoves: ["Orange Punch", "Beach Break", "Superman Punch"],
                achievements: ["1x AEW International Champion", "1x Chikara Grand Champion", "1x PWG World Champion"],
                biography: "Orange Cassidy is known for his laid-back attitude and unique wrestling style.",
                statistics: WrestlerStatistics(
                    totalMatches: 320,
                    wins: 200,
                    losses: 120,
                    winPercentage: 62.5,
                    averageMatchLength: 12.3,
                    championshipReigns: 3
                )
            )
        ]
    }
    
    private func processWrestlers(_ newWrestlers: [Wrestler]) {
        // Remove duplicates and merge data from multiple sources
        let uniqueWrestlers = mergeWrestlerData(newWrestlers)
        
        // Sort by name
        let sortedWrestlers = uniqueWrestlers.sorted { $0.name < $1.name }
        
        // Update published wrestlers
        DispatchQueue.main.async {
            self.wrestlers = sortedWrestlers
            self.cacheWrestlers(sortedWrestlers)
        }
    }
    
    private func mergeWrestlerData(_ wrestlers: [Wrestler]) -> [Wrestler] {
        var mergedWrestlers: [Wrestler] = []
        var wrestlerMap: [String: Wrestler] = [:]
        
        for wrestler in wrestlers {
            if let existing = wrestlerMap[wrestler.id] {
                // Merge data from multiple sources
                let merged = mergeWrestler(existing, with: wrestler)
                wrestlerMap[wrestler.id] = merged
            } else {
                wrestlerMap[wrestler.id] = wrestler
            }
        }
        
        mergedWrestlers = Array(wrestlerMap.values)
        return mergedWrestlers
    }
    
    private func mergeWrestler(_ existing: Wrestler, with new: Wrestler) -> Wrestler {
        // Merge wrestler data, prioritizing more complete information
        return Wrestler(
            id: existing.id,
            name: existing.name,
            realName: existing.realName ?? new.realName,
            ringName: existing.ringName,
            promotions: Array(Set(existing.promotions + new.promotions)),
            hometown: existing.hometown,
            height: existing.height,
            weight: existing.weight,
            debut: existing.debut,
            championships: existing.championships + new.championships,
            photoURL: existing.photoURL ?? new.photoURL,
            socialMedia: existing.socialMedia,
            isActive: existing.isActive,
            currentPromotion: existing.currentPromotion,
            status: existing.status,
            specialties: Array(Set(existing.specialties + new.specialties)),
            signatureMoves: Array(Set(existing.signatureMoves + new.signatureMoves)),
            achievements: Array(Set(existing.achievements + new.achievements)),
            biography: existing.biography.isEmpty ? new.biography : existing.biography,
            statistics: existing.statistics
        )
    }
    
    private func cacheWrestlers(_ wrestlers: [Wrestler]) {
        cache.cacheWrestlers(wrestlers)
    }
    
    private func loadCachedWrestlers() {
        if let cachedWrestlers = cache.getCachedWrestlers() {
            wrestlers = cachedWrestlers
        }
    }
}

// MARK: - Supporting Types
struct WrestlerDataSource {
    let name: String
    let baseURL: String
    let promotion: WrestlingPromotion
    let reliability: ReliabilityTier
}

struct SocialMediaLinks {
    let twitter: String?
    let instagram: String?
    let youtube: String?
}

struct WrestlerStatistics {
    let totalMatches: Int
    let wins: Int
    let losses: Int
    let winPercentage: Double
    let averageMatchLength: Double
    let championshipReigns: Int
}

// MARK: - Wrestler Cache
class WrestlerCache {
    static let shared = WrestlerCache()
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_wrestlers"
    private let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24 hours
    
    func cacheWrestlers(_ wrestlers: [Wrestler]) {
        let cacheData = WrestlerCacheData(
            wrestlers: wrestlers,
            timestamp: Date()
        )
        
        if let data = try? JSONEncoder().encode(cacheData) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }
    
    func getCachedWrestlers() -> [Wrestler]? {
        guard let data = userDefaults.data(forKey: cacheKey),
              let cacheData = try? JSONDecoder().decode(WrestlerCacheData.self, from: data) else {
            return nil
        }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cacheData.timestamp) > maxCacheAge {
            return nil
        }
        
        return cacheData.wrestlers
    }
    
    func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
    }
}

struct WrestlerCacheData: Codable {
    let wrestlers: [Wrestler]
    let timestamp: Date
}
