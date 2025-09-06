import Foundation

struct NewsTestData {
    static let sampleArticles: [NewsArticle] = [
        NewsArticle(
            title: "WWE Announces Major Championship Change at WrestleMania",
            content: "In a shocking turn of events, WWE has announced that the Universal Championship will be defended in a triple threat match at WrestleMania 40. The match will feature current champion Roman Reigns defending against Cody Rhodes and Seth Rollins.",
            author: "John Smith",
            source: "Wrestling Observer",
            category: .wwe,
            isBreaking: true,
            isRumor: false,
            reliabilityScore: 0.9
        ),
        NewsArticle(
            title: "AEW Dynamite Ratings Hit New High",
            content: "This week's episode of AEW Dynamite drew its highest ratings in months, with the main event featuring CM Punk vs. MJF drawing significant viewership. The show averaged 1.2 million viewers.",
            author: "Sarah Johnson",
            source: "Fightful",
            category: .aew,
            isBreaking: false,
            isRumor: false,
            reliabilityScore: 0.8
        ),
        NewsArticle(
            title: "Rumor: NJPW Star Considering WWE Offer",
            content: "Sources close to the situation indicate that a top NJPW star is seriously considering a WWE offer. The wrestler has been with NJPW for over 5 years and would be a major acquisition for WWE.",
            author: "Mike Chen",
            source: "Cageside Seats",
            category: .njpw,
            isBreaking: false,
            isRumor: true,
            reliabilityScore: 0.6
        ),
        NewsArticle(
            title: "Spoiler: Major Return Planned for Next Week's Raw",
            content: "A former WWE Champion is scheduled to make their return on next week's Monday Night Raw. The return has been kept under wraps but sources indicate it will be a major surprise for fans.",
            author: "Anonymous",
            source: "Wrestling Observer",
            category: .wwe,
            isBreaking: false,
            isRumor: false,
            isSpoiler: true,
            reliabilityScore: 0.7
        ),
        NewsArticle(
            title: "Impact Wrestling Announces New Championship",
            content: "Impact Wrestling has announced the creation of a new championship that will be unveiled at their next pay-per-view event. The championship will be unique in its design and presentation.",
            author: "Lisa Rodriguez",
            source: "Impact Wrestling",
            category: .impact,
            isBreaking: false,
            isRumor: false,
            reliabilityScore: 0.9
        )
    ]
    
    static func createTestArticle(
        title: String,
        content: String,
        source: String = "Test Source",
        category: NewsCategory = .general,
        isBreaking: Bool = false,
        isRumor: Bool = false,
        isSpoiler: Bool = false,
        reliabilityScore: Double = 0.5
    ) -> NewsArticle {
        return NewsArticle(
            title: title,
            content: content,
            author: "Test Author",
            source: source,
            category: category,
            isBreaking: isBreaking,
            isRumor: isRumor,
            isSpoiler: isSpoiler,
            reliabilityScore: reliabilityScore
        )
    }
    
    static func generateRandomArticles(count: Int = 10) -> [NewsArticle] {
        let titles = [
            "WWE Raw Results: Shocking Return",
            "AEW Dynamite: Championship Match Announced",
            "NJPW Wrestle Kingdom: Card Update",
            "Impact Wrestling: New Signing",
            "Independent Wrestling: Rising Star",
            "Backstage News: Contract Negotiations",
            "Business Update: TV Deal Renewal",
            "Rumor Mill: Possible Trade",
            "Spoiler Alert: Match Outcome",
            "Breaking: Injury Update"
        ]
        
        let sources = [
            "Wrestling Observer",
            "Fightful",
            "Cageside Seats",
            "WWE.com",
            "AEW.com",
            "NJPW.com",
            "Impact Wrestling"
        ]
        
        let categories: [NewsCategory] = [.wwe, .aew, .njpw, .impact, .indie, .general, .rumors, .spoilers, .backstage, .business]
        
        return (0..<count).map { index in
            let title = titles.randomElement() ?? "Test Article \(index)"
            let source = sources.randomElement() ?? "Test Source"
            let category = categories.randomElement() ?? .general
            let isBreaking = Bool.random() && index < 3
            let isRumor = Bool.random() && category == .rumors
            let isSpoiler = Bool.random() && category == .spoilers
            let reliabilityScore = Double.random(in: 0.3...0.9)
            
            return NewsArticle(
                title: title,
                content: "This is test content for article \(index). It contains sample text to demonstrate the news feed functionality.",
                author: "Test Author \(index)",
                source: source,
                category: category,
                isBreaking: isBreaking,
                isRumor: isRumor,
                isSpoiler: isSpoiler,
                reliabilityScore: reliabilityScore
            )
        }
    }
}

// MARK: - RSS Feed Test Data
struct RSSTestData {
    static let sampleFeeds: [RSSFeed] = [
        RSSFeed(
            name: "Wrestling Observer",
            url: "https://www.f4wonline.com/feeds/all",
            description: "Wrestling Observer Newsletter RSS Feed",
            category: .general
        ),
        RSSFeed(
            name: "Fightful",
            url: "https://www.fightful.com/rss.xml",
            description: "Fightful Wrestling News RSS Feed",
            category: .general
        ),
        RSSFeed(
            name: "Cageside Seats",
            url: "https://www.cagesideseats.com/rss/index.xml",
            description: "Cageside Seats Wrestling Blog RSS Feed",
            category: .general
        )
    ]
    
    static let sampleRSSItems: [RSSItem] = [
        RSSItem(
            title: "WWE Raw Results: January 15, 2024",
            description: "Complete results from Monday Night Raw including championship matches and surprise appearances.",
            link: "https://example.com/raw-results",
            pubDate: Date(),
            guid: "raw-results-2024-01-15"
        ),
        RSSItem(
            title: "AEW Dynamite Preview: Championship Match",
            description: "Preview of this week's AEW Dynamite featuring a major championship defense.",
            link: "https://example.com/dynamite-preview",
            pubDate: Date().addingTimeInterval(-3600),
            guid: "dynamite-preview-2024-01-15"
        ),
        RSSItem(
            title: "NJPW Wrestle Kingdom 18: Full Card",
            description: "Complete match card for NJPW's biggest event of the year.",
            link: "https://example.com/wk18-card",
            pubDate: Date().addingTimeInterval(-7200),
            guid: "wk18-card-2024-01-15"
        )
    ]
}
