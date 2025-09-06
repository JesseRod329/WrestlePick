import Foundation
import FirebaseFirestore
import Combine

class RSSFeedService: ObservableObject {
    @Published var feeds: [RSSFeed] = []
    @Published var feedItems: [RSSFeedItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    private let parser = RSSParser()
    
    init() {
        fetchFeeds()
    }
    
    // MARK: - Feed Management
    func fetchFeeds() {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.rssFeeds)
            .whereField("isActive", isEqualTo: true)
            .order(by: "name")
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.feeds = snapshot?.documents.compactMap { document in
                            try? document.data(as: RSSFeed.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
    
    func addFeed(_ feed: RSSFeed) {
        db.collection(FirestoreCollections.rssFeeds)
            .addDocument(data: feed.dictionary) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.error = error
                    }
                } else {
                    self?.fetchFeeds()
                }
            }
    }
    
    func updateFeed(_ feed: RSSFeed) {
        guard let id = feed.id else { return }
        
        db.collection(FirestoreCollections.rssFeeds)
            .document(id)
            .setData(feed.dictionary, merge: true) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.error = error
                    }
                } else {
                    self?.fetchFeeds()
                }
            }
    }
    
    func deleteFeed(_ feedId: String) {
        db.collection(FirestoreCollections.rssFeeds)
            .document(feedId)
            .delete { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.error = error
                    }
                } else {
                    self?.fetchFeeds()
                }
            }
    }
    
    // MARK: - Feed Processing
    func processAllFeeds() {
        for feed in feeds {
            processFeed(feed)
        }
    }
    
    func processFeed(_ feed: RSSFeed) {
        guard let url = URL(string: feed.url) else { return }
        
        parser.parseFeed(from: url) { [weak self] result in
            switch result {
            case .success(let items):
                self?.processFeedItems(items, for: feed)
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.error = error
                }
            }
        }
    }
    
    private func processFeedItems(_ items: [RSSFeedItem], for feed: RSSFeed) {
        let batch = db.batch()
        let now = Date()
        
        for item in items {
            // Check if item already exists
            db.collection(FirestoreCollections.rssFeedItems)
                .whereField("guid", isEqualTo: item.guid)
                .getDocuments { [weak self] snapshot, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.error = error
                        }
                        return
                    }
                    
                    // If item doesn't exist, add it
                    if snapshot?.documents.isEmpty == true {
                        let newItem = RSSFeedItem(
                            feedId: feed.id ?? "",
                            title: item.title,
                            description: item.description,
                            content: item.content,
                            link: item.link,
                            guid: item.guid,
                            pubDate: item.pubDate
                        )
                        
                        let docRef = self?.db.collection(FirestoreCollections.rssFeedItems).document()
                        docRef?.setData(newItem.dictionary)
                    }
                }
        }
        
        // Update feed last fetched time
        if let feedId = feed.id {
            db.collection(FirestoreCollections.rssFeeds)
                .document(feedId)
                .updateData(["lastFetched": now])
        }
    }
    
    // MARK: - Feed Items
    func fetchFeedItems(for feedId: String? = nil, limit: Int = 50) {
        isLoading = true
        error = nil
        
        var query = db.collection(FirestoreCollections.rssFeedItems)
            .order(by: "pubDate", descending: true)
            .limit(to: limit)
        
        if let feedId = feedId {
            query = query.whereField("feedId", isEqualTo: feedId)
        }
        
        query.getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error
                } else {
                    self?.feedItems = snapshot?.documents.compactMap { document in
                        try? document.data(as: RSSFeedItem.self)
                    } ?? []
                }
                self?.isLoading = false
            }
        }
    }
    
    func searchFeedItems(query: String) {
        isLoading = true
        error = nil
        
        db.collection(FirestoreCollections.rssFeedItems)
            .whereField("title", isGreaterThanOrEqualTo: query)
            .whereField("title", isLessThan: query + "\u{f8ff}")
            .order(by: "pubDate", descending: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.feedItems = snapshot?.documents.compactMap { document in
                            try? document.data(as: RSSFeedItem.self)
                        } ?? []
                    }
                    self?.isLoading = false
                }
            }
    }
}

// MARK: - RSS Parser
class RSSParser: NSObject {
    private var currentElement = ""
    private var currentItem: RSSFeedItem?
    private var items: [RSSFeedItem] = []
    private var completion: ((Result<[RSSFeedItem], Error>) -> Void)?
    
    func parseFeed(from url: URL, completion: @escaping (Result<[RSSFeedItem], Error>) -> Void) {
        self.completion = completion
        self.items = []
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(RSSError.noData))
                return
            }
            
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }
        
        task.resume()
    }
}

// MARK: - XMLParserDelegate
extension RSSParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            currentItem = RSSFeedItem(
                feedId: "",
                title: "",
                description: "",
                content: "",
                link: "",
                guid: "",
                pubDate: Date()
            )
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedString.isEmpty else { return }
        
        switch currentElement {
        case "title":
            currentItem?.title += trimmedString
        case "description":
            currentItem?.description += trimmedString
        case "content:encoded":
            currentItem?.content += trimmedString
        case "link":
            currentItem?.link += trimmedString
        case "guid":
            currentItem?.guid += trimmedString
        case "pubDate":
            if let date = parseDate(trimmedString) {
                currentItem?.pubDate = date
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item", let item = currentItem {
            items.append(item)
            currentItem = nil
        }
        currentElement = ""
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        completion?(.success(items))
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        completion?(.failure(parseError))
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for formatter in formatters {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = formatter
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

// MARK: - Errors
enum RSSError: Error, LocalizedError {
    case noData
    case invalidURL
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No data received from RSS feed"
        case .invalidURL:
            return "Invalid RSS feed URL"
        case .parsingError:
            return "Error parsing RSS feed"
        }
    }
}

// MARK: - Extensions
extension RSSFeed {
    var dictionary: [String: Any] {
        return [
            "name": name,
            "url": url,
            "description": description,
            "category": category.rawValue,
            "isActive": isActive,
            "lastFetched": lastFetched as Any,
            "fetchInterval": fetchInterval,
            "reliabilityScore": reliabilityScore,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

extension RSSFeedItem {
    var dictionary: [String: Any] {
        return [
            "feedId": feedId,
            "title": title,
            "description": description,
            "content": content,
            "link": link,
            "guid": guid,
            "pubDate": pubDate,
            "author": author as Any,
            "categories": categories,
            "isProcessed": isProcessed,
            "createdAt": createdAt
        ]
    }
}
