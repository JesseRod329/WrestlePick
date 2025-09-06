import SwiftUI

struct StorylineTimelineView: View {
    @StateObject private var bookingEngine = BookingEngine.shared
    @State private var storylines: [StorylineArc] = []
    @State private var showingStorylineEditor = false
    @State private var editingStoryline: StorylineArc?
    @State private var selectedTimeRange: TimeRange = .all
    @State private var selectedIntensity: StorylineIntensity? = nil
    
    var filteredStorylines: [StorylineArc] {
        var filtered = storylines
        
        // Filter by time range
        switch selectedTimeRange {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.status == .active }
        case .concluded:
            filtered = filtered.filter { $0.status == .concluded }
        case .paused:
            filtered = filtered.filter { $0.status == .paused }
        }
        
        // Filter by intensity
        if let intensity = selectedIntensity {
            filtered = filtered.filter { $0.intensity == intensity }
        }
        
        return filtered.sorted { $0.startDate > $1.startDate }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                HeaderView(storylineCount: storylines.count, activeCount: storylines.filter { $0.status == .active }.count)
                    .padding()
                
                // Filters
                FilterBar(
                    selectedTimeRange: $selectedTimeRange,
                    selectedIntensity: $selectedIntensity
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Storylines list
                if filteredStorylines.isEmpty {
                    EmptyStateView()
                } else {
                    StorylinesList(
                        storylines: filteredStorylines,
                        onEdit: editStoryline,
                        onDelete: deleteStoryline
                    )
                }
                
                // Add storyline button
                Button(action: {
                    showingStorylineEditor = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Storyline")
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
            .navigationTitle("Storyline Timeline")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingStorylineEditor) {
                StorylineEditorView(
                    storyline: editingStoryline,
                    onSave: saveStoryline,
                    onCancel: {
                        showingStorylineEditor = false
                        editingStoryline = nil
                    }
                )
            }
        }
    }
    
    private func editStoryline(_ storyline: StorylineArc) {
        editingStoryline = storyline
        showingStorylineEditor = true
    }
    
    private func deleteStoryline(_ storyline: StorylineArc) {
        storylines.removeAll { $0.id == storyline.id }
    }
    
    private func saveStoryline(_ storyline: StorylineArc) {
        if let editingStoryline = editingStoryline,
           let index = storylines.firstIndex(where: { $0.id == editingStoryline.id }) {
            storylines[index] = storyline
        } else {
            storylines.append(storyline)
        }
        showingStorylineEditor = false
        editingStoryline = nil
    }
}

// MARK: - Header View
struct HeaderView: View {
    let storylineCount: Int
    let activeCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(storylineCount) Storylines")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Total Created")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(activeCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Filter Bar
struct FilterBar: View {
    @Binding var selectedTimeRange: TimeRange
    @Binding var selectedIntensity: StorylineIntensity?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Time range filter
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
                
                // Intensity filter
                Picker("Intensity", selection: $selectedIntensity) {
                    Text("All").tag(StorylineIntensity?.none)
                    ForEach(StorylineIntensity.allCases, id: \.self) { intensity in
                        Text(intensity.rawValue).tag(StorylineIntensity?.some(intensity))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Time Range
enum TimeRange: String, CaseIterable {
    case all = "all"
    case active = "active"
    case concluded = "concluded"
    case paused = "paused"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .concluded: return "Concluded"
        case .paused: return "Paused"
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Storylines Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Start creating storylines to connect your matches across shows")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Storylines List
struct StorylinesList: View {
    let storylines: [StorylineArc]
    let onEdit: (StorylineArc) -> Void
    let onDelete: (StorylineArc) -> Void
    
    var body: some View {
        List {
            ForEach(storylines) { storyline in
                StorylineRow(
                    storyline: storyline,
                    onEdit: { onEdit(storyline) },
                    onDelete: { onDelete(storyline) }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Storyline Row
struct StorylineRow: View {
    let storyline: StorylineArc
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(storyline.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(storyline.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: storyline.status)
                    IntensityBadge(intensity: storyline.intensity)
                }
            }
            
            // Participants
            if !storyline.participants.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Participants")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(storyline.participants, id: \.self) { participant in
                                Text(participant)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.wweBlue)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Timeline info
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    
                    Text("Started \(storyline.startDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let endDate = storyline.endDate {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        
                        Text("Ended \(endDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        
                        Text("Ongoing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Match and show count
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .foregroundColor(.secondary)
                    
                    Text("\(storyline.matches.count) matches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "tv")
                        .foregroundColor(.secondary)
                    
                    Text("\(storyline.shows.count) shows")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: StorylineStatus
    
    var body: some View {
        Text(status.rawValue)
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
        case .active: return .green
        case .paused: return .yellow
        case .concluded: return .blue
        case .cancelled: return .red
        }
    }
}

// MARK: - Intensity Badge
struct IntensityBadge: View {
    let intensity: StorylineIntensity
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame")
                .font(.caption)
            
            Text(intensity.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(intensityColor)
        .cornerRadius(8)
    }
    
    private var intensityColor: Color {
        switch intensity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }
}

// MARK: - Storyline Editor View
struct StorylineEditorView: View {
    let storyline: StorylineArc?
    let onSave: (StorylineArc) -> Void
    let onCancel: () -> Void
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var participants: [String] = []
    @State private var startDate: Date = Date()
    @State private var endDate: Date? = nil
    @State private var status: StorylineStatus = .active
    @State private var intensity: StorylineIntensity = .medium
    @State private var notes: String = ""
    @State private var showingParticipantPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Storyline Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            // Title
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter storyline title", text: $title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter storyline description", text: $description, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                        }
                    }
                    
                    // Participants
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Participants")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if participants.isEmpty {
                            Button(action: {
                                showingParticipantPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Participants")
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
                                ForEach(participants, id: \.self) { participant in
                                    HStack {
                                        Text(participant)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            participants.removeAll { $0 == participant }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    showingParticipantPicker = true
                                }) {
                                    Text("Add More Participants")
                                        .font(.subheadline)
                                        .foregroundColor(.wweBlue)
                                }
                            }
                        }
                    }
                    
                    // Timeline
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Timeline")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            // Start date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start Date")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                            
                            // End date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End Date")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Toggle("Has End Date", isOn: Binding(
                                    get: { endDate != nil },
                                    set: { endDate = $0 ? Date() : nil }
                                ))
                                
                                if endDate != nil {
                                    DatePicker("End Date", selection: Binding(
                                        get: { endDate ?? Date() },
                                        set: { endDate = $0 }
                                    ), displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                }
                            }
                        }
                    }
                    
                    // Status and intensity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Status & Intensity")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            // Status
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Status")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Picker("Status", selection: $status) {
                                    ForEach(StorylineStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            // Intensity
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Intensity")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Picker("Intensity", selection: $intensity) {
                                    ForEach(StorylineIntensity.allCases, id: \.self) { intensity in
                                        Text(intensity.rawValue).tag(intensity)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
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
            .navigationTitle(storyline == nil ? "Add Storyline" : "Edit Storyline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveStoryline()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingParticipantPicker) {
            ParticipantPickerView(
                selectedParticipants: $participants,
                onSelectionChanged: { _ in }
            )
        }
        .onAppear {
            loadExistingStoryline()
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !participants.isEmpty
    }
    
    private func loadExistingStoryline() {
        guard let storyline = storyline else { return }
        
        title = storyline.title
        description = storyline.description
        participants = storyline.participants
        startDate = storyline.startDate
        endDate = storyline.endDate
        status = storyline.status
        intensity = storyline.intensity
        notes = storyline.notes ?? ""
    }
    
    private func saveStoryline() {
        let newStoryline = StorylineArc(
            title: title,
            description: description,
            participants: participants,
            startDate: startDate,
            endDate: endDate,
            shows: [], // Will be populated when connected to shows
            matches: [], // Will be populated when connected to matches
            status: status,
            intensity: intensity,
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(newStoryline)
    }
}

// MARK: - Participant Picker View
struct ParticipantPickerView: View {
    @Binding var selectedParticipants: [String]
    let onSelectionChanged: ([String]) -> Void
    
    @State private var searchText = ""
    @StateObject private var bookingEngine = BookingEngine.shared
    
    var filteredWrestlers: [Wrestler] {
        let wrestlers = bookingEngine.wrestlers
        
        if searchText.isEmpty {
            return wrestlers
        } else {
            return wrestlers.filter { wrestler in
                wrestler.name.localizedCaseInsensitiveContains(searchText) ||
                wrestler.promotion.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Selected participants
                if !selectedParticipants.isEmpty {
                    SelectedParticipantsView(
                        selectedParticipants: selectedParticipants,
                        onRemove: { participant in
                            selectedParticipants.removeAll { $0 == participant }
                            onSelectionChanged(selectedParticipants)
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Wrestlers list
                List {
                    ForEach(filteredWrestlers) { wrestler in
                        Button(action: {
                            toggleParticipant(wrestler.name)
                        }) {
                            HStack {
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
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(wrestler.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(wrestler.promotion)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedParticipants.contains(wrestler.name) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.wweBlue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Select Participants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
    
    private func toggleParticipant(_ name: String) {
        if selectedParticipants.contains(name) {
            selectedParticipants.removeAll { $0 == name }
        } else {
            selectedParticipants.append(name)
        }
        onSelectionChanged(selectedParticipants)
    }
}

// MARK: - Selected Participants View
struct SelectedParticipantsView: View {
    let selectedParticipants: [String]
    let onRemove: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected (\(selectedParticipants.count))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedParticipants, id: \.self) { participant in
                        HStack(spacing: 6) {
                            Text(participant)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                onRemove(participant)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.wweBlue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
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
    StorylineTimelineView()
}
