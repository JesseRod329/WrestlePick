import SwiftUI

struct PredictionsView: View {
    @State private var predictions: [Prediction] = []
    @State private var selectedEvent: Event?
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
                userId: "user1",
                eventId: "wrestlemania-40",
                matchTitle: "Roman Reigns vs Cody Rhodes",
                prediction: "Cody Rhodes",
                confidenceLevel: .excellent,
                reasoning: "The story has been building for years. It's time for Cody to finish the story.",
                status: .submitted,
                predictionType: .ppvMatch,
                deadline: Date().addingTimeInterval(86400 * 7),
                createdAt: Date(),
                updatedAt: Date()
            ),
            Prediction(
                id: "2",
                userId: "user1",
                eventId: "wrestlemania-40",
                matchTitle: "Seth Rollins vs Drew McIntyre",
                prediction: "Seth Rollins",
                confidenceLevel: .good,
                reasoning: "Seth has been on fire lately, but Drew is hungry for revenge.",
                status: .locked,
                predictionType: .ppvMatch,
                deadline: Date().addingTimeInterval(86400 * 7),
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-3600)
            )
        ]
    }
    
    private var events: [Event] {
        [
            Event(
                name: "WrestleMania 40",
                description: "The Grandest Stage of Them All",
                type: .ppv,
                promotion: "WWE",
                venue: Venue(name: "Lincoln Financial Field", city: "Philadelphia", country: "USA"),
                date: Date().addingTimeInterval(86400 * 30)
            ),
            Event(
                name: "Double or Nothing",
                description: "AEW's annual PPV event",
                type: .ppv,
                promotion: "AEW",
                venue: Venue(name: "T-Mobile Arena", city: "Las Vegas", country: "USA"),
                date: Date().addingTimeInterval(86400 * 45)
            )
        ]
    }
}

// MARK: - Supporting Views

struct EmptyPredictionsView: View {
    let onCreatePrediction: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: "crystal.ball",
            title: "No Predictions Yet",
            description: "Start making predictions about upcoming matches and prove your wrestling knowledge!",
            buttonTitle: "Make Your First Prediction",
            action: onCreatePrediction
        )
    }
}

struct EventCard: View {
    let event: Event
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
                    ConfidenceIndicator(confidence: prediction.confidenceLevel.rawValue)
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
                Text(prediction.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if prediction.canEdit {
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


struct NewPredictionView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Prediction) -> Void
    
    @State private var selectedEventId = ""
    @State private var matchTitle = ""
    @State private var prediction = ""
    @State private var confidence = ConfidenceLevel.average
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
                    Picker("Confidence", selection: $confidence) {
                        ForEach(ConfidenceLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
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
                            userId: "user1",
                            eventId: selectedEventId.isEmpty ? "wrestlemania-40" : selectedEventId,
                            matchTitle: matchTitle,
                            prediction: prediction,
                            confidenceLevel: confidence,
                            reasoning: reasoning,
                            status: .submitted,
                            predictionType: .ppvMatch,
                            deadline: Date().addingTimeInterval(86400 * 7), // 7 days from now
                            createdAt: Date(),
                            updatedAt: Date()
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