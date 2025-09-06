import SwiftUI

struct WrestlerPickerView: View {
    @StateObject private var bookingEngine = BookingEngine.shared
    @Binding var selectedWrestlers: [Wrestler]
    let maxSelections: Int?
    let onSelectionChanged: ([Wrestler]) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: WrestlerCategory = .all
    @State private var selectedPromotion: String = "All"
    @State private var showOnlyAvailable = true
    @State private var sortBy: WrestlerSortOption = .name
    
    var filteredWrestlers: [Wrestler] {
        var filtered = bookingEngine.wrestlers
        
        // Filter by category
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by promotion
        if selectedPromotion != "All" {
            filtered = filtered.filter { $0.promotion == selectedPromotion }
        }
        
        // Filter by availability
        if showOnlyAvailable {
            filtered = filtered.filter { wrestler in
                !bookingEngine.wrestlerAvailability.contains { $0.wrestlerId == wrestler.id && !$0.isAvailable }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { wrestler in
                wrestler.name.localizedCaseInsensitiveContains(searchText) ||
                wrestler.promotion.localizedCaseInsensitiveContains(searchText) ||
                wrestler.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort wrestlers
        switch sortBy {
        case .name:
            filtered = filtered.sorted { $0.name < $1.name }
        case .promotion:
            filtered = filtered.sorted { $0.promotion < $1.promotion }
        case .title:
            filtered = filtered.sorted { $0.title > $1.title }
        case .availability:
            filtered = filtered.sorted { wrestler1, wrestler2 in
                let available1 = !bookingEngine.wrestlerAvailability.contains { $0.wrestlerId == wrestler1.id && !$0.isAvailable }
                let available2 = !bookingEngine.wrestlerAvailability.contains { $0.wrestlerId == wrestler2.id && !$0.isAvailable }
                return available1 && !available2
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Filters
                FilterBar(
                    selectedCategory: $selectedCategory,
                    selectedPromotion: $selectedPromotion,
                    showOnlyAvailable: $showOnlyAvailable,
                    sortBy: $sortBy
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Selected wrestlers
                if !selectedWrestlers.isEmpty {
                    SelectedWrestlersView(
                        selectedWrestlers: selectedWrestlers,
                        maxSelections: maxSelections,
                        onRemove: { wrestler in
                            selectedWrestlers.removeAll { $0.id == wrestler.id }
                            onSelectionChanged(selectedWrestlers)
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Wrestlers list
                if filteredWrestlers.isEmpty {
                    EmptyWrestlersView()
                } else {
                    WrestlersList(
                        wrestlers: filteredWrestlers,
                        selectedWrestlers: selectedWrestlers,
                        maxSelections: maxSelections,
                        onToggle: { wrestler in
                            toggleWrestler(wrestler)
                        }
                    )
                }
            }
            .navigationTitle("Select Wrestlers")
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
    
    private func toggleWrestler(_ wrestler: Wrestler) {
        if selectedWrestlers.contains(where: { $0.id == wrestler.id }) {
            selectedWrestlers.removeAll { $0.id == wrestler.id }
        } else if maxSelections == nil || selectedWrestlers.count < maxSelections! {
            selectedWrestlers.append(wrestler)
        }
        onSelectionChanged(selectedWrestlers)
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search wrestlers...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Filter Bar
struct FilterBar: View {
    @Binding var selectedCategory: WrestlerCategory
    @Binding var selectedPromotion: String
    @Binding var showOnlyAvailable: Bool
    @Binding var sortBy: WrestlerSortOption
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Category filter
                Picker("Category", selection: $selectedCategory) {
                    ForEach(WrestlerCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Promotion filter
                Picker("Promotion", selection: $selectedPromotion) {
                    Text("All").tag("All")
                    ForEach(uniquePromotions, id: \.self) { promotion in
                        Text(promotion).tag(promotion)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Availability toggle
                Button(action: {
                    showOnlyAvailable.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showOnlyAvailable ? "checkmark.circle.fill" : "circle")
                        Text("Available")
                    }
                    .font(.caption)
                    .foregroundColor(showOnlyAvailable ? .green : .secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(showOnlyAvailable ? Color.green.opacity(0.2) : Color(.systemGray6))
                .cornerRadius(8)
                
                // Sort picker
                Picker("Sort", selection: $sortBy) {
                    ForEach(WrestlerSortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
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
    
    private var uniquePromotions: [String] {
        // This would come from the booking engine
        return ["WWE", "AEW", "NJPW", "Impact", "Independent"]
    }
}

// MARK: - Wrestler Sort Options
enum WrestlerSortOption: String, CaseIterable {
    case name = "name"
    case promotion = "promotion"
    case title = "title"
    case availability = "availability"
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .promotion: return "Promotion"
        case .title: return "Title"
        case .availability: return "Availability"
        }
    }
}

// MARK: - Selected Wrestlers View
struct SelectedWrestlersView: View {
    let selectedWrestlers: [Wrestler]
    let maxSelections: Int?
    let onRemove: (Wrestler) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected (\(selectedWrestlers.count)\(maxSelections != nil ? "/\(maxSelections!)" : ""))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if maxSelections != nil && selectedWrestlers.count >= maxSelections! {
                    Text("Maximum reached")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedWrestlers) { wrestler in
                        SelectedWrestlerChip(
                            wrestler: wrestler,
                            onRemove: {
                                onRemove(wrestler)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Selected Wrestler Chip
struct SelectedWrestlerChip: View {
    let wrestler: Wrestler
    let onRemove: () -> Void
    
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
            
            Text(wrestler.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Button(action: onRemove) {
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

// MARK: - Wrestlers List
struct WrestlersList: View {
    let wrestlers: [Wrestler]
    let selectedWrestlers: [Wrestler]
    let maxSelections: Int?
    let onToggle: (Wrestler) -> Void
    
    var body: some View {
        List {
            ForEach(wrestlers) { wrestler in
                WrestlerRow(
                    wrestler: wrestler,
                    isSelected: selectedWrestlers.contains { $0.id == wrestler.id },
                    isDisabled: maxSelections != nil && selectedWrestlers.count >= maxSelections! && !selectedWrestlers.contains { $0.id == wrestler.id },
                    onTap: {
                        onToggle(wrestler)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Wrestler Row
struct WrestlerRow: View {
    let wrestler: Wrestler
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    @StateObject private var bookingEngine = BookingEngine.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .wweBlue : .secondary)
                    .font(.title2)
                
                // Wrestler image
                AsyncImage(url: URL(string: wrestler.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.wweBlue : Color.clear, lineWidth: 2)
                )
                
                // Wrestler info
                VStack(alignment: .leading, spacing: 4) {
                    Text(wrestler.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isDisabled ? .secondary : .primary)
                        .lineLimit(1)
                    
                    Text(wrestler.promotion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if !wrestler.title.isEmpty {
                        Text(wrestler.title)
                            .font(.caption)
                            .foregroundColor(.wweBlue)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Availability indicator
                if let availability = bookingEngine.wrestlerAvailability.first(where: { $0.wrestlerId == wrestler.id }) {
                    if !availability.isAvailable {
                        VStack(spacing: 2) {
                            Image(systemName: availability.reason?.iconName ?? "exclamationmark.triangle")
                                .foregroundColor(availability.reason?.color == "red" ? .red : .orange)
                            Text(availability.reason?.rawValue ?? "Unavailable")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.wweBlue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Empty Wrestlers View
struct EmptyWrestlersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Wrestlers Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Title Picker View
struct TitlePickerView: View {
    @Binding var selectedTitle: Championship?
    @StateObject private var bookingEngine = BookingEngine.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bookingEngine.championships) { championship in
                    Button(action: {
                        selectedTitle = championship
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(championship.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(championship.promotion)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(championship.type.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.wweBlue)
                            }
                            
                            Spacer()
                            
                            if selectedTitle?.id == championship.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.wweBlue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Championship")
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
}

// MARK: - Stipulation Picker View
struct StipulationPickerView: View {
    @Binding var selectedStipulation: Stipulation?
    @StateObject private var bookingEngine = BookingEngine.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bookingEngine.stipulations) { stipulation in
                    Button(action: {
                        selectedStipulation = stipulation
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stipulation.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(stipulation.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(stipulation.type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.wweBlue)
                                    
                                    if stipulation.isDangerous {
                                        Text("Dangerous")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if selectedStipulation?.id == stipulation.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.wweBlue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Stipulation")
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
}

#Preview {
    WrestlerPickerView(
        selectedWrestlers: .constant([]),
        maxSelections: 4,
        onSelectionChanged: { _ in }
    )
}
