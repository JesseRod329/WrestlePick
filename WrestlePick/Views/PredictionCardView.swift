import SwiftUI

struct PredictionCardView: View {
    let prediction: Prediction
    let onTap: () -> Void
    let onEdit: () -> Void
    let onShare: () -> Void
    let onLike: () -> Void
    let onBookmark: () -> Void
    
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with type and status
            HStack {
                PredictionTypeBadge(type: prediction.predictionType)
                
                Spacer()
                
                PredictionStatusBadge(status: prediction.status)
            }
            
            // Title and description
            VStack(alignment: .leading, spacing: 8) {
                Text(prediction.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if !prediction.description.isEmpty {
                    Text(prediction.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
            
            // Event details
            if let event = prediction.event {
                EventDetailsView(event: event)
            }
            
            // Prediction picks
            if !prediction.picks.isEmpty {
                PredictionPicksView(picks: prediction.picks)
            }
            
            // Confidence and deadline
            HStack {
                ConfidenceIndicator(confidence: prediction.confidenceLevel)
                
                Spacer()
                
                DeadlineIndicator(deadline: prediction.deadline, isLocked: prediction.isLocked)
            }
            
            // Accuracy (if resolved)
            if prediction.status == .resolved, let accuracy = prediction.accuracy {
                AccuracyResultView(accuracy: accuracy)
            }
            
            // Engagement stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .foregroundColor(.secondary)
                    Text("\(prediction.engagement.views)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .foregroundColor(isLiked ? .red : .secondary)
                    Text("\(prediction.engagement.likes)")
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
                    Text("\(prediction.engagement.shares)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    showingShareSheet = true
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
            
            // Action buttons
            if prediction.canEdit {
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Text("Edit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.wweBlue)
                            .cornerRadius(8)
                    }
                    
                    Button(action: onShare) {
                        Text("Share")
                            .font(.headline)
                            .foregroundColor(.wweBlue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.wweBlue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareText, shareURL])
        }
    }
    
    private var shareText: String {
        "Check out my prediction: \(prediction.title)\n\n\(prediction.description)\n\n#WrestlePick"
    }
    
    private var shareURL: String {
        "https://wrestlepick.app/predictions/\(prediction.id ?? "")"
    }
}

// MARK: - Prediction Type Badge
struct PredictionTypeBadge: View {
    let type: PredictionType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.iconName)
                .font(.caption)
            
            Text(type.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(typeColor)
        .cornerRadius(8)
    }
    
    private var typeColor: Color {
        switch type {
        case .ppvMatch: return .blue
        case .monthlyAward: return .purple
        case .storyline: return .green
        case .hotTake: return .red
        case .safePick: return .gray
        case .customContest: return .orange
        }
    }
}

// MARK: - Prediction Status Badge
struct PredictionStatusBadge: View {
    let status: PredictionStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .draft: return .gray
        case .submitted: return .blue
        case .locked: return .orange
        case .resolved: return .green
        case .cancelled: return .red
        }
    }
}

// MARK: - Event Details View
struct EventDetailsView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                
                Text(event.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let venue = event.venue {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                    
                    Text(venue.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Prediction Picks View
struct PredictionPicksView: View {
    let picks: [PredictionPick]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Predictions")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(picks.sorted(by: { $0.position < $1.position })) { pick in
                    PredictionPickView(pick: pick)
                }
            }
        }
    }
}

// MARK: - Prediction Pick View
struct PredictionPickView: View {
    let pick: PredictionPick
    
    var body: some View {
        HStack(spacing: 8) {
            // Wrestler image
            AsyncImage(url: URL(string: pick.wrestlerImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 30, height: 30)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pick.wrestlerName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let isWinner = pick.isWinner {
                    HStack(spacing: 4) {
                        Image(systemName: isWinner ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.caption2)
                        Text(isWinner ? "Correct" : "Incorrect")
                            .font(.caption2)
                    }
                    .foregroundColor(isWinner ? .green : .red)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

// MARK: - Confidence Indicator
struct ConfidenceIndicator: View {
    let confidence: ConfidenceLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge")
                .foregroundColor(confidenceColor)
            
            Text("Confidence: \(confidence.rawValue)/10")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(confidenceColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case .veryLow, .low: return .red
        case .belowAverage, .average: return .orange
        case .aboveAverage, .good: return .yellow
        case .veryGood, .excellent: return .green
        case .outstanding, .perfect: return .blue
        }
    }
}

// MARK: - Deadline Indicator
struct DeadlineIndicator: View {
    let deadline: Date
    let isLocked: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isLocked ? "lock.fill" : "clock")
                .foregroundColor(isLocked ? .orange : .secondary)
            
            Text(isLocked ? "Locked" : timeRemaining)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isLocked ? .orange : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isLocked ? Color.orange.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(6)
    }
    
    private var timeRemaining: String {
        let timeInterval = deadline.timeIntervalSinceNow
        
        if timeInterval < 0 {
            return "Overdue"
        } else if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m left"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours)h left"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d left"
        }
    }
}

// MARK: - Accuracy Result View
struct AccuracyResultView: View {
    let accuracy: PredictionAccuracy
    
    var body: some View {
        HStack {
            Image(systemName: accuracy.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(accuracy.isCorrect ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(accuracy.isCorrect ? "Correct!" : "Incorrect")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(accuracy.isCorrect ? .green : .red)
                
                Text("+\(accuracy.pointsEarned) points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(accuracy.accuracyScore * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.wweBlue)
        }
        .padding()
        .background(accuracy.isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
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
    let samplePrediction = Prediction(
        title: "WWE Championship Match",
        description: "Roman Reigns vs Cody Rhodes at WrestleMania",
        userId: "user123",
        predictionType: .ppvMatch,
        eventId: "event123",
        picks: [
            PredictionPick(wrestlerName: "Roman Reigns", isWinner: true),
            PredictionPick(wrestlerName: "Cody Rhodes", isWinner: false)
        ],
        confidenceLevel: .excellent,
        deadline: Date().addingTimeInterval(86400)
    )
    
    return PredictionCardView(
        prediction: samplePrediction,
        onTap: {},
        onEdit: {},
        onShare: {},
        onLike: {},
        onBookmark: {}
    )
    .padding()
}
