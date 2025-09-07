import SwiftUI

// MARK: - Category Button
struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

// MARK: - Reliability Badge
struct ReliabilityBadge: View {
    let score: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundColor(reliabilityColor)
            
            Text(reliabilityText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(reliabilityColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(reliabilityColor.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var reliabilityColor: Color {
        switch score {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var reliabilityText: String {
        switch score {
        case 0.8...1.0:
            return "Tier 1"
        case 0.6..<0.8:
            return "Tier 2"
        default:
            return "Speculation"
        }
    }
}

// MARK: - Confidence Indicator
struct ConfidenceIndicator: View {
    let confidence: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...10, id: \.self) { index in
                Circle()
                    .fill(index <= confidence ? Color.accentColor : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(buttonTitle) {
                action()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
