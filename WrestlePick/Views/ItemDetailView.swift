import SwiftUI
import Charts

struct ItemDetailView: View {
    let item: MerchItem
    @StateObject private var merchService = MerchService.shared
    @State private var showingPriceAlert = false
    @State private var showingShareSheet = false
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Image gallery
                ImageGalleryView(
                    images: item.imageURLs,
                    selectedIndex: $selectedImageIndex
                )
                
                // Item info
                ItemInfoView(item: item)
                
                // Price section
                PriceSectionView(
                    item: item,
                    onSetPriceAlert: {
                        showingPriceAlert = true
                    }
                )
                
                // Affiliate links
                AffiliateLinksView(
                    item: item,
                    onLinkTap: { link in
                        openAffiliateLink(link)
                    }
                )
                
                // Price history chart
                if !item.priceHistory.isEmpty {
                    PriceHistoryChartView(priceHistory: item.priceHistory)
                }
                
                // Popularity metrics
                PopularityMetricsView(item: item)
                
                // Social sentiment
                SocialSentimentView(sentiment: item.socialSentiment)
                
                // User reports
                UserReportsView(itemId: item.id ?? "")
            }
            .padding()
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        isLiked.toggle()
                        if isLiked {
                            merchService.trackItemLike(item.id ?? "")
                        }
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                    }
                    
                    Button(action: {
                        isBookmarked.toggle()
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? .blue : .primary)
                    }
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPriceAlert) {
            PriceAlertView(item: item)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareText, shareURL])
        }
        .onAppear {
            merchService.trackItemView(item.id ?? "")
        }
    }
    
    private var shareText: String {
        "Check out this wrestling merch: \(item.name) - $\(String(format: "%.2f", item.currentPrice))"
    }
    
    private var shareURL: String {
        "https://wrestlepick.app/merch/\(item.id ?? "")"
    }
    
    private func openAffiliateLink(_ link: AffiliateLink) {
        if let url = URL(string: link.url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Image Gallery View
struct ImageGalleryView: View {
    let images: [String]
    @Binding var selectedImageIndex: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Main image
            AsyncImage(url: URL(string: images[selectedImageIndex])) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Thumbnail strip
            if images.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, imageURL in
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedImageIndex == index ? Color.wweBlue : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedImageIndex = index
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Item Info View
struct ItemInfoView: View {
    let item: MerchItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and brand
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(item.brand)
                        .font(.headline)
                        .foregroundColor(.wweBlue)
                    
                    Spacer()
                    
                    AvailabilityBadge(status: item.availability)
                }
            }
            
            // Description
            if !item.description.isEmpty {
                Text(item.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Wrestler and promotion
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wrestler")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(item.wrestler)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Promotion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(item.promotion)
                        .font(.headline)
                        .foregroundColor(.wweBlue)
                }
            }
            
            // Tags
            if !item.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.wweBlue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Availability Badge
struct AvailabilityBadge: View {
    let status: AvailabilityStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.caption)
            
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor)
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .inStock: return .green
        case .lowStock: return .yellow
        case .outOfStock: return .red
        case .discontinued: return .gray
        case .preOrder: return .blue
        case .limitedEdition: return .purple
        }
    }
}

// MARK: - Price Section View
struct PriceSectionView: View {
    let item: MerchItem
    let onSetPriceAlert: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Current price
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("$\(String(format: "%.2f", item.currentPrice))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if let originalPrice = item.originalPrice, item.isOnSale {
                                Text("$\(String(format: "%.2f", originalPrice))")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .strikethrough()
                                
                                Text("\(Int(item.discountPercentage))% OFF")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onSetPriceAlert) {
                        HStack {
                            Image(systemName: "bell")
                            Text("Alert")
                        }
                        .font(.caption)
                        .foregroundColor(.wweBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.wweBlue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Best price from affiliates
                if let bestStore = item.bestStore {
                    HStack {
                        Text("Best Price:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("$\(String(format: "%.2f", bestStore.price))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Text("at \(bestStore.storeName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Affiliate Links View
struct AffiliateLinksView: View {
    let item: MerchItem
    let onLinkTap: (AffiliateLink) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where to Buy")
                .font(.headline)
                .fontWeight(.semibold)
            
            if item.affiliateLinks.isEmpty {
                Text("No affiliate links available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(item.affiliateLinks) { link in
                        AffiliateLinkRow(
                            link: link,
                            onTap: {
                                onLinkTap(link)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Affiliate Link Row
struct AffiliateLinkRow: View {
    let link: AffiliateLink
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.storeName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("$\(String(format: "%.2f", link.price))")
                        .font(.subheadline)
                        .foregroundColor(.wweBlue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.wweBlue)
                    
                    if link.commissionRate > 0 {
                        Text("\(Int(link.commissionRate * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.wweBlue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Price History Chart View
struct PriceHistoryChartView: View {
    let priceHistory: [PricePoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price History")
                .font(.headline)
                .fontWeight(.semibold)
            
            if #available(iOS 16.0, *) {
                Chart(priceHistory) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(.wweBlue)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(.wweBlue)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .currency(code: "USD"))
                    }
                }
            } else {
                // Fallback for iOS < 16
                Text("Price history chart requires iOS 16+")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Popularity Metrics View
struct PopularityMetricsView: View {
    let item: MerchItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popularity Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Popularity Score",
                    value: "\(Int(item.popularity.calculatedScore))",
                    icon: "star.fill",
                    color: .yellow
                )
                
                MetricCard(
                    title: "Views",
                    value: "\(item.popularity.views)",
                    icon: "eye.fill",
                    color: .blue
                )
                
                MetricCard(
                    title: "Likes",
                    value: "\(item.popularity.likes)",
                    icon: "heart.fill",
                    color: .red
                )
                
                MetricCard(
                    title: "Shares",
                    value: "\(item.popularity.shares)",
                    icon: "square.and.arrow.up.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Reports",
                    value: "\(item.popularity.reports)",
                    icon: "exclamationmark.circle.fill",
                    color: .orange
                )
                
                MetricCard(
                    title: "Velocity",
                    value: String(format: "%.1f", item.popularity.velocity),
                    icon: "speedometer",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Social Sentiment View
struct SocialSentimentView: View {
    let sentiment: SocialSentiment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Sentiment")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Overall sentiment
                SentimentBar(
                    title: "Overall",
                    sentiment: sentiment.overall
                )
                
                // Platform breakdown
                VStack(spacing: 8) {
                    SentimentBar(
                        title: "Twitter",
                        sentiment: sentiment.twitter
                    )
                    
                    SentimentBar(
                        title: "Instagram",
                        sentiment: sentiment.instagram
                    )
                    
                    SentimentBar(
                        title: "Reddit",
                        sentiment: sentiment.reddit
                    )
                    
                    SentimentBar(
                        title: "YouTube",
                        sentiment: sentiment.youtube
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Sentiment Bar
struct SentimentBar: View {
    let title: String
    let sentiment: SentimentScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(sentiment.mentions) mentions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                // Positive bar
                Rectangle()
                    .fill(Color.green)
                    .frame(width: CGFloat(sentiment.positive) * 100, height: 8)
                    .cornerRadius(4)
                
                // Neutral bar
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: CGFloat(sentiment.neutral) * 100, height: 8)
                    .cornerRadius(4)
                
                // Negative bar
                Rectangle()
                    .fill(Color.red)
                    .frame(width: CGFloat(sentiment.negative) * 100, height: 8)
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - User Reports View
struct UserReportsView: View {
    let itemId: String
    @StateObject private var merchService = MerchService.shared
    @State private var reports: [UserReport] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("User Reports")
                .font(.headline)
                .fontWeight(.semibold)
            
            if reports.isEmpty {
                Text("No user reports yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(reports) { report in
                        UserReportRow(report: report)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            loadReports()
        }
    }
    
    private func loadReports() {
        // TODO: Load reports for specific item
        reports = []
    }
}

// MARK: - User Report Row
struct UserReportRow: View {
    let report: UserReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(report.reportType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(reportTypeColor)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(report.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let price = report.price {
                Text("$\(String(format: "%.2f", price)) at \(report.store)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            if let notes = report.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var reportTypeColor: Color {
        switch report.reportType {
        case .price: return .blue
        case .availability: return .green
        case .newItem: return .purple
        case .restock: return .orange
        case .sale: return .red
        case .discontinued: return .gray
        }
    }
}

// MARK: - Price Alert View
struct PriceAlertView: View {
    let item: MerchItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var merchService = MerchService.shared
    
    @State private var targetPrice: Double = 0
    @State private var alertType: AlertType = .priceDrop
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item") {
                    HStack {
                        AsyncImage(url: URL(string: item.imageURLs.first ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: item.category.iconName)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            
                            Text("$\(String(format: "%.2f", item.currentPrice))")
                                .font(.subheadline)
                                .foregroundColor(.wweBlue)
                        }
                    }
                }
                
                Section("Alert Type") {
                    Picker("Type", selection: $alertType) {
                        ForEach(AlertType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Target Price") {
                    HStack {
                        Text("$")
                        TextField("0.00", value: $targetPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Description") {
                    Text(alertDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Set Price Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createAlert()
                    }
                    .disabled(targetPrice <= 0 || isCreating)
                }
            }
        }
        .onAppear {
            targetPrice = item.currentPrice * 0.9 // Default to 10% below current price
        }
    }
    
    private var alertDescription: String {
        switch alertType {
        case .priceDrop:
            return "Get notified when the price drops to $\(String(format: "%.2f", targetPrice)) or below"
        case .priceRise:
            return "Get notified when the price rises to $\(String(format: "%.2f", targetPrice)) or above"
        case .restock:
            return "Get notified when this item is back in stock"
        case .newItem:
            return "Get notified when new items from this wrestler are available"
        case .sale:
            return "Get notified when this item goes on sale"
        }
    }
    
    private func createAlert() {
        isCreating = true
        
        let alert = PriceAlert(
            userId: "current_user", // TODO: Get from auth service
            itemId: item.id ?? "",
            targetPrice: targetPrice,
            alertType: alertType
        )
        
        merchService.createPriceAlert(alert) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    print("Error creating price alert: \(error)")
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let sampleItem = MerchItem(
        name: "Roman Reigns 'Head of the Table' T-Shirt",
        description: "Official WWE t-shirt featuring Roman Reigns",
        brand: "WWE",
        category: .tshirt,
        wrestler: "Roman Reigns",
        promotion: "WWE",
        imageURLs: ["https://example.com/roman-tshirt.jpg"],
        currentPrice: 29.99,
        originalPrice: 34.99,
        currency: "USD",
        availability: .inStock,
        regions: ["US", "CA", "UK"],
        tags: ["Roman Reigns", "WWE", "T-Shirt", "Head of the Table"],
        affiliateLinks: [
            AffiliateLink(storeName: "WWE Shop", url: "https://shop.wwe.com/roman-reigns-tshirt", price: 29.99, commissionRate: 0.05)
        ]
    )
    
    return NavigationView {
        ItemDetailView(item: sampleItem)
    }
}
