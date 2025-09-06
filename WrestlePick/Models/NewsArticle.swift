import Foundation

struct NewsArticle: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let author: String
    let publishDate: Date
    let category: NewsCategory
    let tags: [String]
    let isRumor: Bool
    let source: String
    let imageURL: String?
    
    enum NewsCategory: String, CaseIterable, Codable {
        case wwe = "WWE"
        case aew = "AEW"
        case njpw = "NJPW"
        case impact = "Impact"
        case indie = "Independent"
        case general = "General"
    }
}
