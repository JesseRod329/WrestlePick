import SwiftUI

struct ShareableImageView: View {
    let prediction: Prediction
    let user: User?
    let onShare: () -> Void
    let onSave: () -> Void
    
    @State private var showingShareSheet = false
    @State private var generatedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 20) {
            // Generated image preview
            if let image = generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            } else {
                // Placeholder while generating
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Generating image...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 300, height: 400)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: onSave) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.wweBlue)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.headline)
                    .foregroundColor(.wweBlue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.wweBlue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .onAppear {
            generateImage()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = generatedImage {
                ShareSheet(activityItems: [image])
            }
        }
    }
    
    private func generateImage() {
        let renderer = ImageRenderer(content: PredictionCardImage(prediction: prediction, user: user))
        renderer.scale = 3.0 // High resolution for social media
        
        if let image = renderer.uiImage {
            generatedImage = image
        }
    }
}

// MARK: - Prediction Card Image
struct PredictionCardImage: View {
    let prediction: Prediction
    let user: User?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app branding
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WrestlePick")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Prediction Card")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if let user = user {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("@\(user.username)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Prediction by")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.wweBlue, Color.wweBlue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Main content
            VStack(spacing: 16) {
                // Prediction type badge
                HStack {
                    PredictionTypeBadge(type: prediction.predictionType)
                    
                    Spacer()
                    
                    ConfidenceBadge(confidence: prediction.confidenceLevel)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 8) {
                    Text(prediction.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if !prediction.description.isEmpty {
                        Text(prediction.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Prediction picks
                if !prediction.picks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Predictions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(prediction.picks.sorted(by: { $0.position < $1.position })) { pick in
                                PredictionPickChip(pick: pick)
                            }
                        }
                    }
                }
                
                // Event details
                if let event = prediction.event {
                    EventDetailsChip(event: event)
                }
                
                // Deadline
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    
                    Text("Deadline: \(prediction.deadline, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Accuracy result (if resolved)
                if prediction.status == .resolved, let accuracy = prediction.accuracy {
                    AccuracyResultChip(accuracy: accuracy)
                }
            }
            .padding()
            
            // Footer
            HStack {
                Text("Made with WrestlePick")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("wrestlepick.app")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.wweBlue)
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .frame(width: 300, height: 500)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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

// MARK: - Confidence Badge
struct ConfidenceBadge: View {
    let confidence: ConfidenceLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge")
                .font(.caption)
            
            Text("\(confidence.rawValue)/10")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor)
        .cornerRadius(8)
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

// MARK: - Prediction Pick Chip
struct PredictionPickChip: View {
    let pick: PredictionPick
    
    var body: some View {
        HStack(spacing: 6) {
            // Wrestler image placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pick.wrestlerName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let isWinner = pick.isWinner {
                    HStack(spacing: 2) {
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

// MARK: - Event Details Chip
struct EventDetailsChip: View {
    let event: Event
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let venue = event.venue {
                    Text(venue.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
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

// MARK: - Accuracy Result Chip
struct AccuracyResultChip: View {
    let accuracy: PredictionAccuracy
    
    var body: some View {
        HStack {
            Image(systemName: accuracy.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(accuracy.isCorrect ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(accuracy.isCorrect ? "Correct!" : "Incorrect")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(accuracy.isCorrect ? .green : .red)
                
                Text("+\(accuracy.pointsEarned) points")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(accuracy.accuracyScore * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.wweBlue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(accuracy.isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(6)
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

// MARK: - Image Renderer Extension
extension ImageRenderer {
    var uiImage: UIImage? {
        return nsImage
    }
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
    
    let sampleUser = User(
        username: "wrestlingfan",
        email: "fan@example.com",
        displayName: "Wrestling Fan"
    )
    
    return ShareableImageView(
        prediction: samplePrediction,
        user: sampleUser,
        onShare: {},
        onSave: {}
    )
}
