import SwiftUI
import Combine

struct OptimizedImageView: View {
    let url: String
    let placeholder: Image
    let contentMode: ContentMode
    let cornerRadius: CGFloat
    let maxWidth: CGFloat?
    let maxHeight: CGFloat?
    
    @StateObject private var imageLoader = ImageLoader()
    @State private var isLoaded = false
    @State private var hasError = false
    
    init(
        url: String,
        placeholder: Image = Image(systemName: "photo"),
        contentMode: ContentMode = .fit,
        cornerRadius: CGFloat = 0,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) {
        self.url = url
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        Group {
            if isLoaded, let image = imageLoader.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    .clipped()
                    .cornerRadius(cornerRadius)
                    .transition(.opacity)
            } else if hasError {
                placeholder
                    .foregroundColor(.gray)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    .cornerRadius(cornerRadius)
            } else {
                placeholder
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    .cornerRadius(cornerRadius)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { newURL in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard !url.isEmpty else { return }
        
        imageLoader.loadImage(from: url) { success in
            DispatchQueue.main.async {
                isLoaded = success
                hasError = !success
            }
        }
    }
}

// MARK: - Image Loader
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellables = Set<AnyCancellable>()
    private let cache = ImageCache.shared
    
    func loadImage(from url: String, completion: @escaping (Bool) -> Void) {
        // Check cache first
        if let cachedImage = cache.image(for: url) {
            DispatchQueue.main.async {
                self.image = cachedImage
                completion(true)
            }
            return
        }
        
        // Load from network
        guard let imageURL = URL(string: url) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: imageURL)
            .map(\.data)
            .compactMap { UIImage(data: $0) }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .failure:
                        completion(false)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] loadedImage in
                    self?.image = loadedImage
                    self?.cache.setImage(loadedImage, for: url)
                    completion(true)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Lazy Loading Grid
struct LazyLoadingGrid<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let columns: [GridItem]
    let itemView: (Item) -> ItemView
    let onLoadMore: () -> Void
    let isLoading: Bool
    let hasMore: Bool
    
    init(
        items: [Item],
        columns: [GridItem],
        isLoading: Bool = false,
        hasMore: Bool = true,
        @ViewBuilder itemView: @escaping (Item) -> ItemView,
        onLoadMore: @escaping () -> Void = {}
    ) {
        self.items = items
        self.columns = columns
        self.itemView = itemView
        self.onLoadMore = onLoadMore
        self.isLoading = isLoading
        self.hasMore = hasMore
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { item in
                itemView(item)
                    .onAppear {
                        if item.id == items.last?.id && hasMore && !isLoading {
                            onLoadMore()
                        }
                    }
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
}

// MARK: - Paginated List
struct PaginatedList<Item: Identifiable, ItemView: View>: View {
    @StateObject private var paginationManager = PaginationManager()
    
    let items: [Item]
    let itemView: (Item) -> ItemView
    let onLoadMore: () -> Void
    let isLoading: Bool
    let hasMore: Bool
    let threshold: Int
    
    init(
        items: [Item],
        isLoading: Bool = false,
        hasMore: Bool = true,
        threshold: Int = 5,
        @ViewBuilder itemView: @escaping (Item) -> ItemView,
        onLoadMore: @escaping () -> Void = {}
    ) {
        self.items = items
        self.itemView = itemView
        self.onLoadMore = onLoadMore
        self.isLoading = isLoading
        self.hasMore = hasMore
        self.threshold = threshold
    }
    
    var body: some View {
        List {
            ForEach(items) { item in
                itemView(item)
                    .onAppear {
                        paginationManager.checkForLoadMore(
                            currentItem: item,
                            allItems: items,
                            threshold: threshold,
                            hasMore: hasMore,
                            isLoading: isLoading,
                            onLoadMore: onLoadMore
                        )
                    }
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Pagination Manager
class PaginationManager: ObservableObject {
    private var lastLoadedIndex: Int = -1
    
    func checkForLoadMore<Item: Identifiable>(
        currentItem: Item,
        allItems: [Item],
        threshold: Int,
        hasMore: Bool,
        isLoading: Bool,
        onLoadMore: () -> Void
    ) {
        guard hasMore && !isLoading else { return }
        
        guard let currentIndex = allItems.firstIndex(where: { $0.id == currentItem.id }) else { return }
        
        if currentIndex >= allItems.count - threshold && currentIndex > lastLoadedIndex {
            lastLoadedIndex = currentIndex
            onLoadMore()
        }
    }
}

// MARK: - Infinite Scroll View
struct InfiniteScrollView<Content: View>: View {
    let content: Content
    let onLoadMore: () -> Void
    let isLoading: Bool
    let hasMore: Bool
    
    init(
        isLoading: Bool = false,
        hasMore: Bool = true,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onLoadMore = onLoadMore
        self.isLoading = isLoading
        self.hasMore = hasMore
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                content
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
        .onAppear {
            if hasMore && !isLoading {
                onLoadMore()
            }
        }
    }
}

// MARK: - Memory Optimized List
struct MemoryOptimizedList<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let itemView: (Item) -> ItemView
    let onLoadMore: () -> Void
    let isLoading: Bool
    let hasMore: Bool
    let maxVisibleItems: Int
    
    @State private var visibleRange: Range<Int> = 0..<0
    
    init(
        items: [Item],
        maxVisibleItems: Int = 50,
        isLoading: Bool = false,
        hasMore: Bool = true,
        @ViewBuilder itemView: @escaping (Item) -> ItemView,
        onLoadMore: @escaping () -> Void = {}
    ) {
        self.items = items
        self.itemView = itemView
        self.onLoadMore = onLoadMore
        self.isLoading = isLoading
        self.hasMore = hasMore
        self.maxVisibleItems = maxVisibleItems
    }
    
    var body: some View {
        List {
            ForEach(visibleItems) { item in
                itemView(item)
                    .onAppear {
                        updateVisibleRange()
                    }
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .onAppear {
            updateVisibleRange()
        }
    }
    
    private var visibleItems: [Item] {
        let start = max(0, visibleRange.lowerBound)
        let end = min(items.count, visibleRange.upperBound)
        return Array(items[start..<end])
    }
    
    private func updateVisibleRange() {
        let newStart = max(0, items.count - maxVisibleItems)
        let newEnd = items.count
        visibleRange = newStart..<newEnd
    }
}

// MARK: - Image Placeholder
struct ImagePlaceholder: View {
    let systemName: String
    let size: CGFloat
    let color: Color
    
    init(systemName: String = "photo", size: CGFloat = 50, color: Color = .gray) {
        self.systemName = systemName
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}

// MARK: - Loading States
struct LoadingStateView: View {
    let message: String
    let isLoading: Bool
    let hasError: Bool
    let onRetry: (() -> Void)?
    
    init(
        message: String = "Loading...",
        isLoading: Bool = true,
        hasError: Bool = false,
        onRetry: (() -> Void)? = nil
    ) {
        self.message = message
        self.isLoading = isLoading
        self.hasError = hasError
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if hasError {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                Text("Something went wrong")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let onRetry = onRetry {
                    Button("Retry", action: onRetry)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Performance Optimized News Card
struct PerformanceOptimizedNewsCard: View {
    let article: NewsArticle
    let onTap: () -> Void
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    
    @State private var isLiked = false
    @State private var isBookmarked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            if let imageURL = article.imageURL {
                OptimizedImageView(
                    url: imageURL,
                    placeholder: ImagePlaceholder(systemName: "newspaper"),
                    contentMode: .fill,
                    cornerRadius: 8,
                    maxHeight: 200
                )
                .clipped()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // Source and date
                HStack {
                    Text(article.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(article.publishDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Actions
                HStack(spacing: 16) {
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .secondary)
                            
                            Text("\(article.likes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onBookmark) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? .blue : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    OptimizedImageView(
        url: "https://example.com/image.jpg",
        placeholder: ImagePlaceholder(),
        maxWidth: 200,
        maxHeight: 150
    )
}
