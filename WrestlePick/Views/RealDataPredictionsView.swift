import SwiftUI

struct RealDataPredictionsView: View {
    @EnvironmentObject var wrestlerService: WrestlerDataService
    @EnvironmentObject var eventService: LiveEventDataService
    @State private var selectedEvent: WrestlingEvent?
    @State private var showingNewPrediction = false
    @State private var searchText = ""
    
    var upcomingEvents: [WrestlingEvent] {
        eventService.getUpcomingEvents()
    }
    
    var filteredEvents: [WrestlingEvent] {
        if searchText.isEmpty {
            return upcomingEvents
        } else {
            return upcomingEvents.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.venue.name.localizedCaseInsensitiveContains(searchText) ||
                event.promotion.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                if eventService.isLoading {
                    LoadingView()
                } else if upcomingEvents.isEmpty {
                    EmptyStateView(
                        title: "No Upcoming Events",
                        message: "No wrestling events scheduled at the moment.",
                        systemImage: "calendar"
                    )
                } else {
                    EventsList(events: filteredEvents, selectedEvent: $selectedEvent)
                }
            }
            .navigationTitle("Predictions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewPrediction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewPrediction) {
                NewPredictionView(events: upcomingEvents)
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
        }
    }
}

struct EventsList: View {
    let events: [WrestlingEvent]
    @Binding var selectedEvent: WrestlingEvent?
    
    var body: some View {
        List(events) { event in
            EventRow(event: event)
                .onTapGesture {
                    selectedEvent = event
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(PlainListStyle())
    }
}

struct EventRow: View {
    let event: WrestlingEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(event.promotion.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(event.promotion.color.opacity(0.2))
                        .foregroundColor(event.promotion.color)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(event.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(event.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.venue.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("\(event.venue.city), \(event.venue.state)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(event.matches.count) matches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if event.ticketInfo?.availability == .available {
                        Text("Tickets Available")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Match Preview
            if !event.matches.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Featured Matches")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(event.matches.prefix(2)) { match in
                        MatchPreview(match: match)
                    }
                    
                    if event.matches.count > 2 {
                        Text("+ \(event.matches.count - 2) more matches")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MatchPreview: View {
    let match: Match
    
    var body: some View {
        HStack {
            Text(match.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Spacer()
            
            if match.isMainEvent {
                Text("MAIN EVENT")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        }
    }
}

struct EventDetailView: View {
    let event: WrestlingEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(event.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text(event.promotion.rawValue.uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(event.promotion.color.opacity(0.2))
                                .foregroundColor(event.promotion.color)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(event.date, style: .date)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(event.date, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Venue Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Venue")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(event.venue.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("\(event.venue.city), \(event.venue.state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if event.venue.capacity > 0 {
                            Text("Capacity: \(event.venue.capacity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Matches
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Match Card")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(event.matches) { match in
                            MatchCard(match: match)
                        }
                    }
                    
                    // Ticket Information
                    if let ticketInfo = event.ticketInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ticket Information")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("Price Range:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(ticketInfo.priceRange)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("Availability:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(ticketInfo.availability.rawValue.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(ticketInfo.availability == .available ? .green : .orange)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Event Details")
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

struct MatchCard: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(match.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if match.isMainEvent {
                    Text("MAIN EVENT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
            
            if !match.participants.isEmpty {
                Text(match.participants.joined(separator: " vs "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let stipulation = match.stipulation {
                Text(stipulation)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct NewPredictionView: View {
    let events: [WrestlingEvent]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvent: WrestlingEvent?
    @State private var selectedMatch: Match?
    @State private var prediction = ""
    @State private var confidence: Double = 0.5
    
    var body: some View {
        NavigationView {
            Form {
                Section("Select Event") {
                    Picker("Event", selection: $selectedEvent) {
                        Text("Choose an event").tag(nil as WrestlingEvent?)
                        ForEach(events) { event in
                            Text(event.name).tag(event as WrestlingEvent?)
                        }
                    }
                }
                
                if let event = selectedEvent {
                    Section("Select Match") {
                        Picker("Match", selection: $selectedMatch) {
                            Text("Choose a match").tag(nil as Match?)
                            ForEach(event.matches) { match in
                                Text(match.name).tag(match as Match?)
                            }
                        }
                    }
                    
                    if let match = selectedMatch {
                        Section("Your Prediction") {
                            TextField("Enter your prediction...", text: $prediction, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        Section("Confidence Level") {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Confidence: \(Int(confidence * 100))%")
                                        .font(.subheadline)
                                    Spacer()
                                }
                                
                                Slider(value: $confidence, in: 0...1, step: 0.05)
                            }
                        }
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
                        // Save prediction
                        dismiss()
                    }
                    .disabled(selectedEvent == nil || selectedMatch == nil || prediction.isEmpty)
                }
            }
        }
    }
}

#Preview {
    RealDataPredictionsView()
        .environmentObject(WrestlerDataService.shared)
        .environmentObject(LiveEventDataService.shared)
}
