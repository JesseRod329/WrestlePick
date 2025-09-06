import SwiftUI

struct NewsCardView: View {
    let article: NewsArticle
    let onTap: () -> Void
    let onShare: () -> Void
    let onBookmark: () -> Void
    let onLike: () -> Void
    
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with source and reliability
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.source)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ReliabilityBadge(tier: reliabilityTier)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(article.publishDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if article.isBreaking {
                        BreakingNewsBadge()
                    }
                }
            }
            
            // Title
            Text(article.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(3)
                .foregroundColor(.primary)
            
            // Content excerpt
            if !article.excerpt.isEmpty {
                Text(article.excerpt)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Image if available
            if let imageURL = article.media.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(8)
            }
            
            // Tags and category
            HStack {
                CategoryBadge(category: article.category)
                
                if article.isRumor {
                    RumorBadge()
                }
                
                if article.isSpoiler {
                    SpoilerBadge()
                }
                
                Spacer()
            }
            
            // Engagement stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .foregroundColor(.secondary)
                    Text("\(article.engagement.views)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .foregroundColor(isLiked ? .red : .secondary)
                    Text("\(article.engagement.likes)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    isLiked.toggle()
                    onLike()
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                    Text("\(article.engagement.shares)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    showShareSheet = true
                }
                
                Spacer()
                
                Button(action: {
                    isBookmarked.toggle()
                    onBookmark()
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isBookmarked ? .blue : .secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareText, shareURL])
        }
    }
    
    private var reliabilityTier: ReliabilityTier {
        if article.reliabilityScore >= 0.8 {
            return .tier1
        } else if article.reliabilityScore >= 0.6 {
            return .tier2
        } else if article.reliabilityScore >= 0.4 {
            return .speculation
        } else {
            return .unverified
        }
    }
    
    private var shareText: String {
        "\(article.title)\n\n\(article.excerpt)\n\nRead more: \(shareURL)"
    }
    
    private var shareURL: String {
        article.sourceURL ?? "https://wrestlepick.app/news/\(article.id ?? "")"
    }
}

// MARK: - Badge Components
struct ReliabilityBadge: View {
    let tier: ReliabilityTier
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tierColor)
                .frame(width: 6, height: 6)
            
            Text(tier.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(tierColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(tierColor.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var tierColor: Color {
        switch tier {
        case .tier1: return .tier1Green
        case .tier2: return .tier2Blue
        case .speculation: return .speculationOrange
        case .unverified: return .unverifiedRed
        }
    }
}

struct BreakingNewsBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
            
            Text("BREAKING")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.red)
        .cornerRadius(4)
    }
}

struct CategoryBadge: View {
    let category: NewsCategory
    
    var body: some View {
        Text(category.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(categoryColor)
            .cornerRadius(4)
    }
    
    private var categoryColor: Color {
        switch category {
        case .wwe: return .wweBlue
        case .aew: return .aewRed
        case .njpw: return .njpwPurple
        case .impact: return .impactOrange
        case .indie: return .indieGreen
        case .general: return .gray
        case .rumors: return .rumorYellow
        case .spoilers: return .spoilerPink
        case .backstage: return .brown
        case .business: return .cyan
        }
    }
}

struct RumorBadge: View {
    var body: some View {
        Text("RUMOR")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.rumorYellow)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.rumorYellow.opacity(0.2))
            .cornerRadius(4)
    }
}

struct SpoilerBadge: View {
    var body: some View {
        Text("SPOILER")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.spoilerPink)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.spoilerPink.opacity(0.2))
            .cornerRadius(4)
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
    let sampleArticle = NewsArticle(
        title: "WWE Announces Major Championship Change at WrestleMania",
        content: "In a shocking turn of events, WWE has announced that the Universal Championship will be defended in a triple threat match at WrestleMania 40.",
        author: "John Smith",
        source: "Wrestling Observer",
        category: .wwe
    )
    
    return NewsCardView(
        article: sampleArticle,
        onTap: {},
        onShare: {},
        onBookmark: {},
        onLike: {}
    )
    .padding()
}
