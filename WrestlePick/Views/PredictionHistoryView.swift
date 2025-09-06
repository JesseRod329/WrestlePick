import SwiftUI

struct PredictionHistoryView: View {
    @StateObject private var predictionService = PredictionService.shared
    @State private var predictions: [Prediction] = []
    @State private var isLoading = false
    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedTimeRange: TimeRange = .allTime
    @State private var showingFilters = false
    
    var filteredPredictions: [Prediction] {
        var filtered = predictions
        
        // Filter by status
        switch selectedFilter {
        case .all:
            break
        case .correct:
            filtered = filtered.filter { $0.accuracy?.isCorrect == true }
        case .incorrect:
            filtered = filtered.filter { $0.accuracy?.isCorrect == false }
        case .pending:
            filtered = filtered.filter { $0.status == .submitted || $0.status == .locked }
        }
        
        // Filter by time range
        let now = Date()
        switch selectedTimeRange {
        case .allTime:
            break
        case .lastWeek:
            let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            filtered = filtered.filter { $0.createdAt >= weekAgo }
        case .lastMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
            filtered = filtered.filter { $0.createdAt >= monthAgo }
        case .lastYear:
            let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
            filtered = filtered.filter { $0.createdAt >= yearAgo }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    var accuracyStats: AccuracyStats {
        let resolvedPredictions = predictions.filter { $0.status == .resolved }
        let correctPredictions = resolvedPredictions.filter { $0.accuracy?.isCorrect == true }
        
        return AccuracyStats(
            totalPredictions: resolvedPredictions.count,
            correctPredictions: correctPredictions.count,
            accuracy: resolvedPredictions.isEmpty ? 0.0 : Double(correctPredictions.count) / Double(resolvedPredictions.count),
            averageConfidence: resolvedPredictions.isEmpty ? 0.0 : resolvedPredictions.map { Double($0.confidenceLevel.rawValue) }.reduce(0, +) / Double(resolvedPredictions.count),
            currentStreak: calculateCurrentStreak(),
            longestStreak: calculateLongestStreak()
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats overview
                StatsOverviewView(stats: accuracyStats)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Filters
                FilterBar(
                    selectedFilter: $selectedFilter,
                    selectedTimeRange: $selectedTimeRange,
                    onShowFilters: { showingFilters = true }
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Predictions list
                if isLoading {
                    LoadingView()
                } else if filteredPredictions.isEmpty {
                    EmptyHistoryView(filter: selectedFilter)
                } else {
                    PredictionsList(predictions: filteredPredictions)
                }
            }
            .navigationTitle("Prediction History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilters = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onAppear {
                loadPredictions()
            }
            .sheet(isPresented: $showingFilters) {
                HistoryFiltersView(
                    selectedFilter: $selectedFilter,
                    selectedTimeRange: $selectedTimeRange
                )
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
    
    private func calculateCurrentStreak() -> Int {
        let resolvedPredictions = predictions
            .filter { $0.status == .resolved }
            .sorted { $0.createdAt > $1.createdAt }
        
        var streak = 0
        for prediction in resolvedPredictions {
            if prediction.accuracy?.isCorrect == true {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        let resolvedPredictions = predictions
            .filter { $0.status == .resolved }
            .sorted { $0.createdAt > $1.createdAt }
        
        var longestStreak = 0
        var currentStreak = 0
        
        for prediction in resolvedPredictions {
            if prediction.accuracy?.isCorrect == true {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return longestStreak
    }
}

// MARK: - Accuracy Stats
struct AccuracyStats {
    let totalPredictions: Int
    let correctPredictions: Int
    let accuracy: Double
    let averageConfidence: Double
    let currentStreak: Int
    let longestStreak: Int
}

// MARK: - Stats Overview View
struct StatsOverviewView: View {
    let stats: AccuracyStats
    
    var body: some View {
        VStack(spacing: 16) {
            // Main accuracy stat
            VStack(spacing: 8) {
                Text("\(Int(stats.accuracy * 100))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(accuracyColor)
                
                Text("Overall Accuracy")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(stats.correctPredictions) of \(stats.totalPredictions) predictions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Secondary stats
            HStack(spacing: 20) {
                StatCard(
                    title: "Current Streak",
                    value: "\(stats.currentStreak)",
                    subtitle: "in a row",
                    color: .orange
                )
                
                StatCard(
                    title: "Longest Streak",
                    value: "\(stats.longestStreak)",
                    subtitle: "best run",
                    color: .blue
                )
                
                StatCard(
                    title: "Avg Confidence",
                    value: "\(Int(stats.averageConfidence * 10))/10",
                    subtitle: "confidence",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var accuracyColor: Color {
        if stats.accuracy >= 0.8 {
            return .green
        } else if stats.accuracy >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Bar
struct FilterBar: View {
    @Binding var selectedFilter: HistoryFilter
    @Binding var selectedTimeRange: TimeRange
    let onShowFilters: () -> Void
    
    var body: some View {
        HStack {
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Time range picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Spacer()
            
            // More filters button
            Button(action: onShowFilters) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.wweBlue)
            }
        }
    }
}

// MARK: - History Filter
enum HistoryFilter: String, CaseIterable {
    case all = "all"
    case correct = "correct"
    case incorrect = "incorrect"
    case pending = "pending"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .correct: return "Correct"
        case .incorrect: return "Incorrect"
        case .pending: return "Pending"
        }
    }
}

// MARK: - Time Range
enum TimeRange: String, CaseIterable {
    case allTime = "allTime"
    case lastWeek = "lastWeek"
    case lastMonth = "lastMonth"
    case lastYear = "lastYear"
    
    var displayName: String {
        switch self {
        case .allTime: return "All Time"
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .lastYear: return "Last Year"
        }
    }
}

// MARK: - Predictions List
struct PredictionsList: View {
    let predictions: [Prediction]
    
    var body: some View {
        List {
            ForEach(predictions) { prediction in
                PredictionHistoryRow(prediction: prediction)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Prediction History Row
struct PredictionHistoryRow: View {
    let prediction: Prediction
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            VStack {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                
                if prediction.status == .resolved, let accuracy = prediction.accuracy {
                    Text("+\(accuracy.pointsEarned)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(accuracy.isCorrect ? .green : .red)
                }
            }
            .frame(width: 40)
            
            // Prediction details
            VStack(alignment: .leading, spacing: 4) {
                Text(prediction.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(prediction.predictionType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(typeColor)
                    .cornerRadius(4)
                
                HStack {
                    Text("Confidence: \(prediction.confidenceLevel.rawValue)/10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(prediction.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Accuracy result
            if prediction.status == .resolved, let accuracy = prediction.accuracy {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(accuracy.isCorrect ? "✓" : "✗")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(accuracy.isCorrect ? .green : .red)
                    
                    Text("\(Int(accuracy.accuracyScore * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var statusIcon: String {
        switch prediction.status {
        case .draft: return "pencil"
        case .submitted: return "paperplane"
        case .locked: return "lock"
        case .resolved: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch prediction.status {
        case .draft: return .gray
        case .submitted: return .blue
        case .locked: return .orange
        case .resolved: return .green
        case .cancelled: return .red
        }
    }
    
    private var typeColor: Color {
        switch prediction.predictionType {
        case .ppvMatch: return .blue
        case .monthlyAward: return .purple
        case .storyline: return .green
        case .hotTake: return .red
        case .safePick: return .gray
        case .customContest: return .orange
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading prediction history...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty History View
struct EmptyHistoryView: View {
    let filter: HistoryFilter
    
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
        switch filter {
        case .all: return "crystal.ball"
        case .correct: return "checkmark.circle"
        case .incorrect: return "xmark.circle"
        case .pending: return "clock"
        }
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all: return "No Predictions Yet"
        case .correct: return "No Correct Predictions"
        case .incorrect: return "No Incorrect Predictions"
        case .pending: return "No Pending Predictions"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all: return "Start making predictions to see your history here!"
        case .correct: return "Keep making predictions to get some correct ones!"
        case .incorrect: return "Great! You haven't made any incorrect predictions yet."
        case .pending: return "No predictions are currently pending resolution."
        }
    }
}

// MARK: - History Filters View
struct HistoryFiltersView: View {
    @Binding var selectedFilter: HistoryFilter
    @Binding var selectedTimeRange: TimeRange
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Prediction Status") {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(HistoryFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                }
                
                Section("Time Range") {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PredictionHistoryView()
}
