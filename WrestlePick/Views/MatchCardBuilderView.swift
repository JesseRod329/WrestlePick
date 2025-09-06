import SwiftUI

struct MatchCardBuilderView: View {
    @StateObject private var bookingEngine = BookingEngine.shared
    @State private var matchCards: [MatchCard] = []
    @State private var draggedMatch: MatchCard?
    @State private var showingMatchEditor = false
    @State private var editingMatch: MatchCard?
    @State private var showingValidation = false
    @State private var validationResult: ValidationResult?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                HeaderView(matchCount: matchCards.count, totalDuration: totalDuration)
                    .padding()
                
                // Match cards list
                if matchCards.isEmpty {
                    EmptyStateView()
                } else {
                    MatchCardsList(
                        matchCards: matchCards,
                        onMove: moveMatch,
                        onEdit: editMatch,
                        onDelete: deleteMatch
                    )
                }
                
                // Add match button
                Button(action: {
                    showingMatchEditor = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Match")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.wweBlue)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Match Card Builder")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Validate") {
                        validateShow()
                    }
                }
            }
            .sheet(isPresented: $showingMatchEditor) {
                MatchEditorView(
                    matchCard: editingMatch,
                    onSave: saveMatch,
                    onCancel: {
                        showingMatchEditor = false
                        editingMatch = nil
                    }
                )
            }
            .sheet(isPresented: $showingValidation) {
                if let result = validationResult {
                    ValidationResultView(result: result)
                }
            }
        }
    }
    
    private var totalDuration: TimeInterval {
        matchCards.reduce(0) { $0 + $1.estimatedDuration }
    }
    
    private func moveMatch(from source: IndexSet, to destination: Int) {
        matchCards.move(fromOffsets: source, toOffset: destination)
        updatePositions()
    }
    
    private func editMatch(_ match: MatchCard) {
        editingMatch = match
        showingMatchEditor = true
    }
    
    private func deleteMatch(_ match: MatchCard) {
        matchCards.removeAll { $0.id == match.id }
        updatePositions()
    }
    
    private func saveMatch(_ match: MatchCard) {
        if let editingMatch = editingMatch,
           let index = matchCards.firstIndex(where: { $0.id == editingMatch.id }) {
            matchCards[index] = match
        } else {
            matchCards.append(match)
        }
        updatePositions()
        showingMatchEditor = false
        editingMatch = nil
    }
    
    private func updatePositions() {
        for (index, match) in matchCards.enumerated() {
            matchCards[index] = MatchCard(
                matchType: match.matchType,
                participants: match.participants,
                title: match.title,
                stipulation: match.stipulation,
                storyline: match.storyline,
                estimatedDuration: match.estimatedDuration,
                position: index,
                isMainEvent: match.isMainEvent,
                isOpener: match.isOpener,
                notes: match.notes
            )
        }
    }
    
    private func validateShow() {
        // Create a temporary show for validation
        let tempShow = FantasyBooking(
            title: "Validation Show",
            description: "Temporary show for validation",
            createdByUserId: "temp",
            createdByUsername: "temp",
            promotion: "WWE",
            showType: .raw,
            matchCards: matchCards
        )
        
        validationResult = bookingEngine.validateShow(tempShow)
        showingValidation = true
    }
}

// MARK: - Header View
struct HeaderView: View {
    let matchCount: Int
    let totalDuration: TimeInterval
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(matchCount) Matches")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Total Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(totalDuration))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.wweBlue)
                
                Text("Show Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Matches Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Start building your match card by adding matches")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Match Cards List
struct MatchCardsList: View {
    let matchCards: [MatchCard]
    let onMove: (IndexSet, Int) -> Void
    let onEdit: (MatchCard) -> Void
    let onDelete: (MatchCard) -> Void
    
    var body: some View {
        List {
            ForEach(matchCards.sorted(by: { $0.position < $1.position })) { match in
                MatchCardRow(
                    match: match,
                    onEdit: { onEdit(match) },
                    onDelete: { onDelete(match) }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .onMove(perform: onMove)
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Match Card Row
struct MatchCardRow: View {
    let match: MatchCard
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with match type and position
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: match.matchType.iconName)
                        .foregroundColor(.wweBlue)
                    
                    Text(match.matchType.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    if match.isMainEvent {
                        Text("MAIN EVENT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                    
                    if match.isOpener {
                        Text("OPENER")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Participants
            VStack(alignment: .leading, spacing: 8) {
                Text("Participants")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(match.participants) { wrestler in
                        WrestlerChip(wrestler: wrestler)
                    }
                }
            }
            
            // Title and stipulation
            if let title = match.title {
                HStack {
                    Image(systemName: "crown")
                        .foregroundColor(.yellow)
                    
                    Text(title.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            if let stipulation = match.stipulation {
                HStack {
                    Image(systemName: stipulation.type.iconName)
                        .foregroundColor(.orange)
                    
                    Text(stipulation.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            // Storyline
            if let storyline = match.storyline, !storyline.isEmpty {
                HStack {
                    Image(systemName: "book")
                        .foregroundColor(.purple)
                    
                    Text(storyline)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            // Duration and notes
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(match.estimatedDuration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let notes = match.notes, !notes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .foregroundColor(.secondary)
                        
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action buttons
            HStack {
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundColor(.wweBlue)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Text("Delete")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - Wrestler Chip
struct WrestlerChip: View {
    let wrestler: Wrestler
    
    var body: some View {
        HStack(spacing: 6) {
            AsyncImage(url: URL(string: wrestler.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 20, height: 20)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(wrestler.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(wrestler.promotion)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Match Editor View
struct MatchEditorView: View {
    let matchCard: MatchCard?
    let onSave: (MatchCard) -> Void
    let onCancel: () -> Void
    
    @State private var matchType: MatchType = .singles
    @State private var selectedWrestlers: [Wrestler] = []
    @State private var selectedTitle: Championship?
    @State private var selectedStipulation: Stipulation?
    @State private var storyline: String = ""
    @State private var estimatedDuration: TimeInterval = 600
    @State private var isMainEvent: Bool = false
    @State private var isOpener: Bool = false
    @State private var notes: String = ""
    @State private var showingWrestlerPicker = false
    @State private var showingTitlePicker = false
    @State private var showingStipulationPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Match type selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Match Type")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(MatchType.allCases, id: \.self) { type in
                                MatchTypeCard(
                                    type: type,
                                    isSelected: matchType == type,
                                    onTap: {
                                        matchType = type
                                        // Reset wrestlers if new type has different participant requirements
                                        if selectedWrestlers.count > type.maxParticipants {
                                            selectedWrestlers = Array(selectedWrestlers.prefix(type.maxParticipants))
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    // Wrestler selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Participants")
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
                                
                                if selectedWrestlers.count < matchType.maxParticipants {
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
                    }
                    
                    // Title selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Championship")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Button(action: {
                            showingTitlePicker = true
                        }) {
                            HStack {
                                if let title = selectedTitle {
                                    Text(title.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Championship")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Stipulation selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Stipulation")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Button(action: {
                            showingStipulationPicker = true
                        }) {
                            HStack {
                                if let stipulation = selectedStipulation {
                                    Text(stipulation.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Stipulation")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Storyline
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Storyline")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter storyline description", text: $storyline, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estimated Duration")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Slider(value: $estimatedDuration, in: 60...1800, step: 30)
                            
                            Text(formatDuration(estimatedDuration))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 60)
                        }
                    }
                    
                    // Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Options")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            Toggle("Main Event", isOn: $isMainEvent)
                            Toggle("Opening Match", isOn: $isOpener)
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Add notes", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(2...4)
                    }
                }
                .padding()
            }
            .navigationTitle(matchCard == nil ? "Add Match" : "Edit Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMatch()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingWrestlerPicker) {
            WrestlerPickerView(
                selectedWrestlers: $selectedWrestlers,
                maxSelections: matchType.maxParticipants,
                onSelectionChanged: { _ in }
            )
        }
        .sheet(isPresented: $showingTitlePicker) {
            TitlePickerView(selectedTitle: $selectedTitle)
        }
        .sheet(isPresented: $showingStipulationPicker) {
            StipulationPickerView(selectedStipulation: $selectedStipulation)
        }
        .onAppear {
            loadExistingMatch()
        }
    }
    
    private var isFormValid: Bool {
        selectedWrestlers.count >= matchType.minParticipants &&
        selectedWrestlers.count <= matchType.maxParticipants
    }
    
    private func loadExistingMatch() {
        guard let match = matchCard else { return }
        
        matchType = match.matchType
        selectedWrestlers = match.participants
        selectedTitle = match.title
        selectedStipulation = match.stipulation
        storyline = match.storyline ?? ""
        estimatedDuration = match.estimatedDuration
        isMainEvent = match.isMainEvent
        isOpener = match.isOpener
        notes = match.notes ?? ""
    }
    
    private func saveMatch() {
        let newMatch = MatchCard(
            matchType: matchType,
            participants: selectedWrestlers,
            title: selectedTitle,
            stipulation: selectedStipulation,
            storyline: storyline.isEmpty ? nil : storyline,
            estimatedDuration: estimatedDuration,
            position: 0, // Will be updated by parent
            isMainEvent: isMainEvent,
            isOpener: isOpener,
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(newMatch)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - Match Type Card
struct MatchTypeCard: View {
    let type: MatchType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .wweBlue)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                Text("\(type.minParticipants)-\(type.maxParticipants)")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.wweBlue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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
    MatchCardBuilderView()
}
