import Foundation
import Combine

class SimpleRSSManager: ObservableObject {
    static let shared = SimpleRSSManager()
    
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSampleData()
    }
    
    func refreshAllFeeds() {
        isLoading = true
        error = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadSampleData()
            self.isLoading = false
            self.lastUpdateTime = Date()
        }
    }
    
    private func loadSampleData() {
        // Create sample real wrestling news articles
        let sampleArticles = [
            NewsArticle(
                title: "WWE Raw Results: New Champion Crowned",
                content: "In a shocking turn of events, a new champion was crowned on Monday Night Raw. The match featured incredible athleticism and unexpected twists that left fans on the edge of their seats.",
                source: NewsSource(name: "WWE Official", url: "https://wwe.com", reliability: .tier1),
                category: .results,
                promotions: [.wwe],
                author: "WWE Staff",
                imageURL: "https://via.placeholder.com/300x200",
                tags: ["Raw", "Championship", "Results"],
                isBreaking: false,
                isVerified: true
            ),
            NewsArticle(
                title: "AEW Dynamite: Major Signing Announced",
                content: "All Elite Wrestling has announced a major signing that will shake up the wrestling world. The new talent brings years of experience and is expected to make an immediate impact.",
                source: NewsSource(name: "AEW Official", url: "https://allelitewrestling.com", reliability: .tier1),
                category: .general,
                promotions: [.aew],
                author: "AEW Staff",
                imageURL: "https://via.placeholder.com/300x200",
                tags: ["Signing", "AEW", "Dynamite"],
                isBreaking: true,
                isVerified: true
            ),
            NewsArticle(
                title: "NJPW Wrestle Kingdom Results",
                content: "New Japan Pro Wrestling's biggest event of the year delivered incredible matches and unforgettable moments. The main event was a classic that will be remembered for years to come.",
                source: NewsSource(name: "NJPW Official", url: "https://njpw1972.com", reliability: .tier1),
                category: .results,
                promotions: [.njpw],
                author: "NJPW Staff",
                imageURL: "https://via.placeholder.com/300x200",
                tags: ["Wrestle Kingdom", "NJPW", "Results"],
                isBreaking: false,
                isVerified: true
            ),
            NewsArticle(
                title: "Wrestling Injury Report: Star Out Indefinitely",
                content: "A top wrestling star has been sidelined with an injury that will keep them out of action indefinitely. The wrestling community sends their well wishes for a speedy recovery.",
                source: NewsSource(name: "Wrestling Observer", url: "https://f4wonline.com", reliability: .tier1),
                category: .injuries,
                promotions: [.wwe, .aew],
                author: "Dave Meltzer",
                imageURL: "https://via.placeholder.com/300x200",
                tags: ["Injury", "Report", "Recovery"],
                isBreaking: false,
                isVerified: true
            ),
            NewsArticle(
                title: "Contract Rumors: Free Agent in High Demand",
                content: "A major free agent wrestler is reportedly in high demand from multiple promotions. Sources suggest several companies are vying for their signature.",
                source: NewsSource(name: "Fightful", url: "https://fightful.com", reliability: .tier2),
                category: .rumors,
                promotions: [.wwe, .aew, .njpw],
                author: "Sean Ross Sapp",
                imageURL: "https://via.placeholder.com/300x200",
                tags: ["Contract", "Free Agent", "Rumors"],
                isBreaking: false,
                isVerified: false
            ),
            NewsArticle(
                title: "Wrestling Business: Record Revenue Quarter",
                content: "The wrestling industry continues to grow with record-breaking revenue reported across multiple promotions. This growth reflects the increasing popularity of professional wrestling worldwide.",
                source: NewsSource(name: "Wrestling Inc", url: "https://wrestlinginc.com", reliability: .tier1),
                category: .business,
                promotions: [.wwe, .aew, .njpw],
                author: "Wrestling Inc Staff",
                imageURL: "https://via.placeholder.com/300x200",
                tags: ["Business", "Revenue", "Growth"],
                isBreaking: false,
                isVerified: true
            )
        ]
        
        articles = sampleArticles
    }
}
