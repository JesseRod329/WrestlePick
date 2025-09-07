import SwiftUI

struct RealDataPredictionsView: View {
    @State private var predictions: [Prediction] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading predictions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(predictions) { prediction in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(prediction.title)
                                .font(.headline)
                                .lineLimit(2)
                            
                            Text(prediction.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            HStack {
                                Text(prediction.category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                Text("Confidence: \(Int(prediction.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Predictions")
            .onAppear {
                loadPredictions()
            }
        }
    }
    
    private func loadPredictions() {
        // Simulate loading predictions
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            predictions = [
                Prediction(
                    id: "1",
                    title: "Championship Match Winner",
                    description: "Prediction for the upcoming championship match at the next pay-per-view.",
                    category: .match,
                    confidence: 0.75,
                    createdAt: Date()
                ),
                Prediction(
                    id: "2",
                    title: "New Tag Team Champions",
                    description: "Who will win the tag team championship in the next month?",
                    category: .championship,
                    confidence: 0.60,
                    createdAt: Date().addingTimeInterval(-3600)
                ),
                Prediction(
                    id: "3",
                    title: "Wrestler of the Year",
                    description: "Early prediction for wrestler of the year based on current performance.",
                    category: .award,
                    confidence: 0.85,
                    createdAt: Date().addingTimeInterval(-7200)
                )
            ]
            isLoading = false
        }
    }
}

struct Prediction: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: PredictionCategory
    let confidence: Double
    let createdAt: Date
}

enum PredictionCategory: String, CaseIterable {
    case match = "Match"
    case championship = "Championship"
    case award = "Award"
    case storyline = "Storyline"
}

#Preview {
    RealDataPredictionsView()
}