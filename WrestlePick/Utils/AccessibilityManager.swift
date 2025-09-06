import SwiftUI
import UIKit

class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isVoiceOverEnabled = false
    @Published var isReduceMotionEnabled = false
    @Published var isReduceTransparencyEnabled = false
    @Published var isHighContrastEnabled = false
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium
    
    private init() {
        setupAccessibilityObservers()
        updateAccessibilitySettings()
    }
    
    // MARK: - Setup
    private func setupAccessibilityObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceTransparencyStatusChanged),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferredContentSizeCategoryChanged),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func voiceOverStatusChanged() {
        DispatchQueue.main.async {
            self.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        }
    }
    
    @objc private func reduceMotionStatusChanged() {
        DispatchQueue.main.async {
            self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }
    }
    
    @objc private func reduceTransparencyStatusChanged() {
        DispatchQueue.main.async {
            self.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        }
    }
    
    @objc private func preferredContentSizeCategoryChanged() {
        DispatchQueue.main.async {
            self.preferredContentSizeCategory = ContentSizeCategory(
                UIAccessibility.preferredContentSizeCategory
            )
        }
    }
    
    private func updateAccessibilitySettings() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        preferredContentSizeCategory = ContentSizeCategory(
            UIAccessibility.preferredContentSizeCategory
        )
    }
    
    // MARK: - Accessibility Helpers
    func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    func focusOn(_ element: Any) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }
    
    func setAccessibilityLabel(_ label: String, for element: Any) {
        if let view = element as? UIView {
            view.accessibilityLabel = label
        }
    }
    
    func setAccessibilityHint(_ hint: String, for element: Any) {
        if let view = element as? UIView {
            view.accessibilityHint = hint
        }
    }
    
    func setAccessibilityTraits(_ traits: UIAccessibilityTraits, for element: Any) {
        if let view = element as? UIView {
            view.accessibilityTraits = traits
        }
    }
    
    // MARK: - Dynamic Type Support
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaledSize = UIFont.preferredFont(forTextStyle: .body).pointSize * (size / 17.0)
        return Font.system(size: scaledSize, weight: weight)
    }
    
    func scaledPadding(_ basePadding: CGFloat) -> CGFloat {
        let scaleFactor = UIFont.preferredFont(forTextStyle: .body).pointSize / 17.0
        return basePadding * scaleFactor
    }
    
    // MARK: - High Contrast Support
    func adaptiveColor(_ lightColor: Color, darkColor: Color) -> Color {
        if isHighContrastEnabled {
            return darkColor
        }
        return lightColor
    }
    
    // MARK: - Reduce Motion Support
    func shouldAnimate() -> Bool {
        return !isReduceMotionEnabled
    }
    
    func animationDuration() -> Double {
        return isReduceMotionEnabled ? 0.0 : 0.3
    }
}

// MARK: - Content Size Category
enum ContentSizeCategory: String, CaseIterable {
    case extraSmall = "UICTContentSizeCategoryXS"
    case small = "UICTContentSizeCategoryS"
    case medium = "UICTContentSizeCategoryM"
    case large = "UICTContentSizeCategoryL"
    case extraLarge = "UICTContentSizeCategoryXL"
    case extraExtraLarge = "UICTContentSizeCategoryXXL"
    case extraExtraExtraLarge = "UICTContentSizeCategoryXXXL"
    case accessibilityMedium = "UICTContentSizeCategoryAccessibilityM"
    case accessibilityLarge = "UICTContentSizeCategoryAccessibilityL"
    case accessibilityExtraLarge = "UICTContentSizeCategoryAccessibilityXL"
    case accessibilityExtraExtraLarge = "UICTContentSizeCategoryAccessibilityXXL"
    case accessibilityExtraExtraExtraLarge = "UICTContentSizeCategoryAccessibilityXXXL"
    
    init(_ category: UIContentSizeCategory) {
        self = ContentSizeCategory(rawValue: category.rawValue) ?? .medium
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.5
        case .accessibilityLarge: return 1.6
        case .accessibilityExtraLarge: return 1.7
        case .accessibilityExtraExtraLarge: return 1.8
        case .accessibilityExtraExtraExtraLarge: return 1.9
        }
    }
}

// MARK: - Accessibility Modifiers
struct AccessibilityModifier: ViewModifier {
    let label: String?
    let hint: String?
    let traits: UIAccessibilityTraits?
    let value: String?
    let action: (() -> Void)?
    
    init(
        label: String? = nil,
        hint: String? = nil,
        traits: UIAccessibilityTraits? = nil,
        value: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.label = label
        self.hint = hint
        self.traits = traits
        self.value = value
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityTraits(traits ?? [])
            .accessibilityValue(value ?? "")
            .accessibilityAction {
                action?()
            }
    }
}

// MARK: - Dynamic Type Modifier
struct DynamicTypeModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    init(size: CGFloat, weight: Font.Weight = .regular) {
        self.size = size
        self.weight = weight
    }
    
    func body(content: Content) -> some View {
        content
            .font(AccessibilityManager.shared.scaledFont(size: size, weight: weight))
    }
}

// MARK: - High Contrast Modifier
struct HighContrastModifier: ViewModifier {
    let lightColor: Color
    let darkColor: Color
    
    init(lightColor: Color, darkColor: Color) {
        self.lightColor = lightColor
        self.darkColor = darkColor
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(
                AccessibilityManager.shared.adaptiveColor(lightColor, darkColor: darkColor)
            )
    }
}

// MARK: - Reduce Motion Modifier
struct ReduceMotionModifier: ViewModifier {
    let animation: Animation?
    
    init(animation: Animation? = .default) {
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .animation(
                AccessibilityManager.shared.shouldAnimate() ? animation : nil,
                value: UUID()
            )
    }
}

// MARK: - View Extensions
extension View {
    func accessibilityLabel(_ label: String) -> some View {
        modifier(AccessibilityModifier(label: label))
    }
    
    func accessibilityHint(_ hint: String) -> some View {
        modifier(AccessibilityModifier(hint: hint))
    }
    
    func accessibilityTraits(_ traits: UIAccessibilityTraits) -> some View {
        modifier(AccessibilityModifier(traits: traits))
    }
    
    func accessibilityValue(_ value: String) -> some View {
        modifier(AccessibilityModifier(value: value))
    }
    
    func accessibilityAction(_ action: @escaping () -> Void) -> some View {
        modifier(AccessibilityModifier(action: action))
    }
    
    func dynamicType(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(DynamicTypeModifier(size: size, weight: weight))
    }
    
    func highContrast(lightColor: Color, darkColor: Color) -> some View {
        modifier(HighContrastModifier(lightColor: lightColor, darkColor: darkColor))
    }
    
    func reduceMotion(animation: Animation? = .default) -> some View {
        modifier(ReduceMotionModifier(animation: animation))
    }
}

// MARK: - Accessible News Card
struct AccessibleNewsCard: View {
    let article: NewsArticle
    let onTap: () -> Void
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image with accessibility
            if let imageURL = article.imageURL {
                OptimizedImageView(url: imageURL)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
                    .accessibilityLabel("News article image")
                    .accessibilityHint("Double tap to view full image")
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(article.title)
                    .dynamicType(size: 18, weight: .bold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .accessibilityLabel("Article title: \(article.title)")
                
                // Source and date
                HStack {
                    Text(article.source)
                        .dynamicType(size: 14)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Source: \(article.source)")
                    
                    Spacer()
                    
                    Text(article.publishDate.formatted(date: .abbreviated, time: .omitted))
                        .dynamicType(size: 14)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Published: \(article.publishDate.formatted(date: .abbreviated, time: .omitted))")
                }
                
                // Actions
                HStack(spacing: 16) {
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            Image(systemName: article.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(article.isLiked ? .red : .secondary)
                            
                            Text("\(article.likes)")
                                .dynamicType(size: 14)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(article.isLiked ? "Unlike article" : "Like article")
                    .accessibilityValue("\(article.likes) likes")
                    
                    Button(action: onBookmark) {
                        Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(article.isBookmarked ? .blue : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(article.isBookmarked ? "Remove bookmark" : "Bookmark article")
                    
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Share article")
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityAction(.default) {
            onTap()
        }
        .accessibilityAction(named: "Like") {
            onLike()
        }
        .accessibilityAction(named: "Bookmark") {
            onBookmark()
        }
        .accessibilityAction(named: "Share") {
            onShare()
        }
    }
}

// MARK: - Accessible Prediction Card
struct AccessiblePredictionCard: View {
    let prediction: Prediction
    let onTap: () -> Void
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.title)
                        .dynamicType(size: 18, weight: .bold)
                        .foregroundColor(.primary)
                        .accessibilityLabel("Prediction title: \(prediction.title)")
                    
                    Text(prediction.eventName)
                        .dynamicType(size: 14)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Event: \(prediction.eventName)")
                }
                
                Spacer()
                
                // Status badge
                Text(prediction.status.displayName)
                    .dynamicType(size: 12, weight: .medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(8)
                    .accessibilityLabel("Status: \(prediction.status.displayName)")
            }
            
            // Description
            Text(prediction.description)
                .dynamicType(size: 14)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .accessibilityLabel("Description: \(prediction.description)")
            
            // Confidence and category
            HStack {
                Text("Confidence: \(prediction.confidence)/10")
                    .dynamicType(size: 14)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Confidence level: \(prediction.confidence) out of 10")
                
                Spacer()
                
                Text(prediction.category.displayName)
                    .dynamicType(size: 14)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Category: \(prediction.category.displayName)")
            }
            
            // Actions
            HStack(spacing: 16) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .foregroundColor(.secondary)
                        
                        Text("Like")
                            .dynamicType(size: 14)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Like prediction")
                
                Button(action: onComment) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.secondary)
                        
                        Text("Comment")
                            .dynamicType(size: 14)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Comment on prediction")
                
                Button(action: onShare) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.secondary)
                        
                        Text("Share")
                            .dynamicType(size: 14)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Share prediction")
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityAction(.default) {
            onTap()
        }
        .accessibilityAction(named: "Like") {
            onLike()
        }
        .accessibilityAction(named: "Comment") {
            onComment()
        }
        .accessibilityAction(named: "Share") {
            onShare()
        }
    }
    
    private var statusColor: Color {
        switch prediction.status {
        case .draft: return .gray
        case .submitted: return .blue
        case .locked: return .orange
        case .resolved: return .green
        }
    }
}

// MARK: - Accessible Button
struct AccessibleButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let isEnabled: Bool
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    init(
        _ title: String,
        style: ButtonStyle = .primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .dynamicType(size: 16, weight: .semibold)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(backgroundColor)
                .cornerRadius(12)
        }
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
        .accessibilityTraits(isEnabled ? [.button] : [.button, .notEnabled])
    }
    
    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .destructive: return .white
        }
    }
    
    private var backgroundColor: Color {
        if !isEnabled {
            return .gray.opacity(0.3)
        }
        
        switch style {
        case .primary: return .blue
        case .secondary: return .gray.opacity(0.2)
        case .destructive: return .red
        }
    }
    
    private var accessibilityHint: String {
        if !isEnabled {
            return "Button is disabled"
        }
        
        switch style {
        case .primary: return "Double tap to activate"
        case .secondary: return "Double tap to select"
        case .destructive: return "Double tap to confirm action"
        }
    }
}
