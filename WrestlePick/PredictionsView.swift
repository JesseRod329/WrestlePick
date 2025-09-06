import SwiftUI

struct PredictionsView: View {
    @State private var predictions: [Prediction] = []
    @State private var selectedEvent: WrestlingEvent?
    @State private var showingNewPrediction = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Event Selector
                if !predictions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(events) { event in
                                EventCard(
                                    event: event,
                                    isSelected: selectedEvent?.id == event.id
                                ) {
                                    selectedEvent = event
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // Predictions List
                if predictions.isEmpty {
                    EmptyPredictionsView {
                        showingNewPrediction = true
                    }
                } else {
                    List(filteredPredictions) { prediction in
                        PredictionCardView(prediction: prediction)
                    }
                }
            }
            .navigationTitle("My Predictions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Prediction") {
                        showingNewPrediction = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .sheet(isPresented: $showingNewPrediction) {
                NewPredictionView { prediction in
                    predictions.append(prediction)
                }
            }
        }
        .onAppear {
            loadMockData()
        }
    }
    
    private var filteredPredictions: [Prediction] {
        guard let selectedEvent = selectedEvent else {
            return predictions
        }
        return predictions.filter { $0.eventId == selectedEvent.id }
    }
    
    private func loadMockData() {
        predictions = [
            Prediction(
                id: "1",
                eventId: "wrestlemania-40",
                matchTitle: "Roman Reigns vs Cody Rhodes",
                prediction: "Cody Rhodes",
                confidence: 8,
                reasoning: "The story has been building for years. It's time for Cody to finish the story.",
                timestamp: Date(),
                isLocked: false
            ),
            Prediction(
                id: "2",
                eventId: "wrestlemania-40",
                matchTitle: "Seth Rollins vs Drew McIntyre",
                prediction: "Seth Rollins",
                confidence: 6,
                reasoning: "Seth has been on fire lately, but Drew is hungry for revenge.",
                timestamp: Date().addingTimeInterval(-3600),
                isLocked: true
            )
        ]
    }
    
    private var events: [WrestlingEvent] {
        [
            WrestlingEvent(
                id: "wrestlemania-40",
                name: "WrestleMania 40",
                date: Date().addingTimeInterval(86400 * 30),
                promotion: "WWE",
                venue: "Lincoln Financial Field"
            ),
            WrestlingEvent(
                id: "aew-double-or-nothing",
                name: "Double or Nothing",
                date: Date().addingTimeInterval(86400 * 45),
                promotion: "AEW",
                venue: "T-Mobile Arena"
            )
        ]
    }
}

// MARK: - Models

struct Prediction: Identifiable {
    let id: String
    let eventId: String
    let matchTitle: String
    let prediction: String
    let confidence: Int
    let reasoning: String
    let timestamp: Date
    let isLocked: Bool
}

struct WrestlingEvent: Identifiable {
    let id: String
    let name: String
    let date: Date
    let promotion: String
    let venue: String
}

// MARK: - Supporting Views

struct EmptyPredictionsView: View {
    let onCreatePrediction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "crystal.ball")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("No Predictions Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start making predictions about upcoming matches and prove your wrestling knowledge!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Make Your First Prediction") {
                onCreatePrediction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct EventCard: View {
    let event: WrestlingEvent
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(event.name)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                
                Text(event.promotion)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            }
            .padding()
            .frame(width: 160, height: 100)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct PredictionCardView: View {
    let prediction: Prediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.matchTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Prediction: \(prediction.prediction)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ConfidenceIndicator(confidence: prediction.confidence)
                    if prediction.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Text(prediction.reasoning)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(prediction.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !prediction.isLocked {
                    Button("Edit") {
                        // Edit prediction
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

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

struct NewPredictionView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Prediction) -> Void
    
    @State private var selectedEvent = ""
    @State private var matchTitle = ""
    @State private var prediction = ""
    @State private var confidence = 5
    @State private var reasoning = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Match Details") {
                    TextField("Match Title", text: $matchTitle)
                    TextField("Your Prediction", text: $prediction)
                }
                
                Section("Reasoning") {
                    TextField("Why do you think this will happen?", text: $reasoning, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Confidence Level") {
                    VStack {
                        HStack {
                            Text("Confidence: \(confidence)/10")
                            Spacer()
                        }
                        Slider(value: Binding(
                            get: { Double(confidence) },
                            set: { confidence = Int($0) }
                        ), in: 1...10, step: 1)
                    }
                }
            }
            .navigationTitle("New Prediction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newPrediction = Prediction(
                            id: UUID().uuidString,
                            eventId: "wrestlemania-40",
                            matchTitle: matchTitle,
                            prediction: prediction,
                            confidence: confidence,
                            reasoning: reasoning,
                            timestamp: Date(),
                            isLocked: false
                        )
                        onSave(newPrediction)
                        dismiss()
                    }
                    .disabled(matchTitle.isEmpty || prediction.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PredictionsView()
}