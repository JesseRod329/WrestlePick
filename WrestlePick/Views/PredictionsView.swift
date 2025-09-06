import SwiftUI

struct PredictionsView: View {
    @StateObject private var predictionService = PredictionService.shared
    @State private var selectedTab: PredictionTab = .active
    @State private var showingCreatePrediction = false
    @State private var showingLeaderboard = false
    @State private var showingHistory = false
    @State private var predictions: [Prediction] = []
    @State private var isLoading = false
    
    var filteredPredictions: [Prediction] {
        switch selectedTab {
        case .active:
            return predictions.filter { $0.status == .submitted || $0.status == .locked }
        case .draft:
            return predictions.filter { $0.status == .draft }
        case .resolved:
            return predictions.filter { $0.status == .resolved }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                TabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Content
                if isLoading {
                    LoadingView()
                } else if filteredPredictions.isEmpty {
                    EmptyPredictionsView(tab: selectedTab)
                } else {
                    PredictionsList(
                        predictions: filteredPredictions,
                        onEdit: { prediction in
                            // TODO: Navigate to edit prediction
                        },
                        onShare: { prediction in
                            // TODO: Show share sheet
                        },
                        onLike: { prediction in
                            predictionService.likePrediction(prediction.id ?? "")
                        },
                        onBookmark: { prediction in
                            predictionService.bookmarkPrediction(prediction.id ?? "")
                        }
                    )
                }
            }
            .navigationTitle("Predictions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: {
                            showingLeaderboard = true
                        }) {
                            Image(systemName: "trophy")
                        }
                        
                        Button(action: {
                            showingHistory = true
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreatePrediction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadPredictions()
            }
            .sheet(isPresented: $showingCreatePrediction) {
                CreatePredictionView()
            }
            .sheet(isPresented: $showingLeaderboard) {
                LeaderboardView()
            }
            .sheet(isPresented: $showingHistory) {
                PredictionHistoryView()
            }
        }
    }
    
    private func loadPredictions() {
        isLoading = true
        
        predictionService.fetchUserPredictions { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedPredictions):
                    predictions = fetchedPredictions
                case .failure(let error):
                    print("Error loading predictions: \(error)")
                    predictions = []
                }
            }
        }
    }
}

// MARK: - Prediction Tab
enum PredictionTab: String, CaseIterable {
    case active = "active"
    case draft = "draft"
    case resolved = "resolved"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .draft: return "Drafts"
        case .resolved: return "Resolved"
        }
    }
    
    var iconName: String {
        switch self {
        case .active: return "clock"
        case .draft: return "pencil"
        case .resolved: return "checkmark.circle"
        }
    }
}

// MARK: - Tab Selector
struct TabSelector: View {
    @Binding var selectedTab: PredictionTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PredictionTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.title3)
                        
                        Text(tab.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? .wweBlue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.wweBlue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Predictions List
struct PredictionsList: View {
    let predictions: [Prediction]
    let onEdit: (Prediction) -> Void
    let onShare: (Prediction) -> Void
    let onLike: (Prediction) -> Void
    let onBookmark: (Prediction) -> Void
    
    var body: some View {
        List {
            ForEach(predictions) { prediction in
                PredictionCardView(
                    prediction: prediction,
                    onTap: {
                        // TODO: Navigate to prediction detail
                    },
                    onEdit: {
                        onEdit(prediction)
                    },
                    onShare: {
                        onShare(prediction)
                    },
                    onLike: {
                        onLike(prediction)
                    },
                    onBookmark: {
                        onBookmark(prediction)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading predictions...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Predictions View
struct EmptyPredictionsView: View {
    let tab: PredictionTab
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyIcon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(emptyTitle)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyIcon: String {
        switch tab {
        case .active: return "clock"
        case .draft: return "pencil"
        case .resolved: return "checkmark.circle"
        }
    }
    
    private var emptyTitle: String {
        switch tab {
        case .active: return "No Active Predictions"
        case .draft: return "No Draft Predictions"
        case .resolved: return "No Resolved Predictions"
        }
    }
    
    private var emptyMessage: String {
        switch tab {
        case .active: return "Create your first prediction to get started!"
        case .draft: return "Start drafting a prediction to see it here."
        case .resolved: return "Your resolved predictions will appear here."
        }
    }
}

// MARK: - Create Prediction View
struct CreatePredictionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var predictionService = PredictionService.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var predictionType: PredictionType = .ppvMatch
    @State private var confidenceLevel: ConfidenceLevel = .average
    @State private var selectedWrestlers: [Wrestler] = []
    @State private var deadline = Date().addingTimeInterval(86400) // 24 hours from now
    @State private var isPublic = true
    @State private var isLoading = false
    @State private var showingWrestlerPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Prediction type selector
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Prediction Type")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(PredictionType.allCases, id: \.self) { type in
                                PredictionTypeCard(
                                    type: type,
                                    isSelected: predictionType == type,
                                    onTap: {
                                        predictionType = type
                                    }
                                )
                            }
                        }
                    }
                    
                    // Basic information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Prediction Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            // Title
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter prediction title", text: $title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter prediction description", text: $description, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                            
                            // Confidence level
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confidence Level")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Picker("Confidence", selection: $confidenceLevel) {
                                    ForEach(ConfidenceLevel.allCases, id: \.self) { level in
                                        Text(level.displayName).tag(level)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Wrestler selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wrestlers")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if selectedWrestlers.isEmpty {
                            Button(action: {
                                showingWrestlerPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Wrestlers")
                                }
                                .font(.headline)
                                .foregroundColor(.wweBlue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.wweBlue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        } else {
                            VStack(spacing: 12) {
                                ForEach(selectedWrestlers) { wrestler in
                                    SelectedWrestlerRow(
                                        wrestler: wrestler,
                                        onRemove: {
                                            selectedWrestlers.removeAll { $0.id == wrestler.id }
                                        }
                                    )
                                }
                                
                                Button(action: {
                                    showingWrestlerPicker = true
                                }) {
                                    Text("Add More Wrestlers")
                                        .font(.subheadline)
                                        .foregroundColor(.wweBlue)
                                }
                            }
                        }
                    }
                    
                    // Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            // Deadline
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Deadline")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                DatePicker("Deadline", selection: $deadline, in: Date()...)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                            
                            // Privacy
                            Toggle("Public Prediction", isOn: $isPublic)
                        }
                    }
                    
                    // Create button
                    Button(action: createPrediction) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Create Prediction")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.wweBlue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                }
                .padding()
            }
            .navigationTitle("Create Prediction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingWrestlerPicker) {
            MultiSelectPickerView(
                wrestlers: [], // TODO: Load wrestlers from service
                selectedWrestlers: $selectedWrestlers,
                maxSelections: nil,
                onSelectionChanged: { _ in }
            )
        }
        .alert("Prediction Creation", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !selectedWrestlers.isEmpty
    }
    
    private func createPrediction() {
        isLoading = true
        
        let picks = selectedWrestlers.enumerated().map { index, wrestler in
            PredictionPick(
                wrestlerName: wrestler.name,
                wrestlerImageURL: wrestler.imageURL,
                position: index
            )
        }
        
        let prediction = Prediction(
            title: title,
            description: description,
            userId: "current_user_id", // TODO: Get from auth service
            predictionType: predictionType,
            eventId: nil,
            picks: picks,
            confidenceLevel: confidenceLevel,
            deadline: deadline,
            isPublic: isPublic
        )
        
        predictionService.createPrediction(prediction) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    alertMessage = "Prediction created successfully!"
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                case .failure(let error):
                    alertMessage = "Failed to create prediction: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Prediction Type Card
struct PredictionTypeCard: View {
    let type: PredictionType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : typeColor)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? typeColor : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Selected Wrestler Row
struct SelectedWrestlerRow: View {
    let wrestler: Wrestler
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: wrestler.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(wrestler.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(wrestler.promotion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Custom Text Field Style
struct RoundedBorderTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

#Preview {
    PredictionsView()
}
