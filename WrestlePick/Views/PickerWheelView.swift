import SwiftUI

struct PickerWheelView: View {
    let wrestlers: [Wrestler]
    @Binding var selectedWrestler: Wrestler?
    let onWrestlerSelected: (Wrestler) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: WrestlerCategory = .all
    
    var filteredWrestlers: [Wrestler] {
        var filtered = wrestlers
        
        // Filter by category
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { wrestler in
                wrestler.name.localizedCaseInsensitiveContains(searchText) ||
                wrestler.promotion.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.top)
            
            // Category filter
            CategoryFilter(selectedCategory: $selectedCategory)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            // Wrestler list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredWrestlers) { wrestler in
                        WrestlerRow(
                            wrestler: wrestler,
                            isSelected: selectedWrestler?.id == wrestler.id,
                            onTap: {
                                selectedWrestler = wrestler
                                onWrestlerSelected(wrestler)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemBackground))
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

// MARK: - Category Filter
struct CategoryFilter: View {
    @Binding var selectedCategory: WrestlerCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WrestlerCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == category ? Color.wweBlue : Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Wrestler Row
struct WrestlerRow: View {
    let wrestler: Wrestler
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
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
                        .foregroundColor(.primary)
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
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.wweBlue)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.wweBlue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Wrestler Category
enum WrestlerCategory: String, CaseIterable {
    case all = "all"
    case wwe = "wwe"
    case aew = "aew"
    case njpw = "njpw"
    case impact = "impact"
    case indie = "indie"
    case legends = "legends"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .wwe: return "WWE"
        case .aew: return "AEW"
        case .njpw: return "NJPW"
        case .impact: return "Impact"
        case .indie: return "Independent"
        case .legends: return "Legends"
        }
    }
}

// MARK: - Wrestler Model
struct Wrestler: Identifiable, Codable {
    let id: String
    let name: String
    let promotion: String
    let title: String
    let imageURL: String?
    let category: WrestlerCategory
    let isActive: Bool
    let debutDate: Date?
    let height: String?
    let weight: String?
    let hometown: String?
    let signatureMoves: [String]
    let championships: [String]
    
    init(name: String, promotion: String, title: String = "", imageURL: String? = nil, category: WrestlerCategory = .wwe, isActive: Bool = true, debutDate: Date? = nil, height: String? = nil, weight: String? = nil, hometown: String? = nil, signatureMoves: [String] = [], championships: [String] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.promotion = promotion
        self.title = title
        self.imageURL = imageURL
        self.category = category
        self.isActive = isActive
        self.debutDate = debutDate
        self.height = height
        self.weight = weight
        self.hometown = hometown
        self.signatureMoves = signatureMoves
        self.championships = championships
    }
}

// MARK: - Multi-Select Picker
struct MultiSelectPickerView: View {
    let wrestlers: [Wrestler]
    @Binding var selectedWrestlers: [Wrestler]
    let maxSelections: Int?
    let onSelectionChanged: ([Wrestler]) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: WrestlerCategory = .all
    
    var filteredWrestlers: [Wrestler] {
        var filtered = wrestlers
        
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { wrestler in
                wrestler.name.localizedCaseInsensitiveContains(searchText) ||
                wrestler.promotion.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with selection count
            HStack {
                Text("Select Wrestlers")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(selectedWrestlers.count)\(maxSelections != nil ? "/\(maxSelections!)" : "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            // Category filter
            CategoryFilter(selectedCategory: $selectedCategory)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            // Selected wrestlers
            if !selectedWrestlers.isEmpty {
                SelectedWrestlersView(
                    selectedWrestlers: selectedWrestlers,
                    onRemove: { wrestler in
                        selectedWrestlers.removeAll { $0.id == wrestler.id }
                        onSelectionChanged(selectedWrestlers)
                    }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Wrestler list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredWrestlers) { wrestler in
                        MultiSelectWrestlerRow(
                            wrestler: wrestler,
                            isSelected: selectedWrestlers.contains { $0.id == wrestler.id },
                            isDisabled: maxSelections != nil && selectedWrestlers.count >= maxSelections! && !selectedWrestlers.contains { $0.id == wrestler.id },
                            onTap: {
                                if selectedWrestlers.contains(where: { $0.id == wrestler.id }) {
                                    selectedWrestlers.removeAll { $0.id == wrestler.id }
                                } else if maxSelections == nil || selectedWrestlers.count < maxSelections! {
                                    selectedWrestlers.append(wrestler)
                                }
                                onSelectionChanged(selectedWrestlers)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Selected Wrestlers View
struct SelectedWrestlersView: View {
    let selectedWrestlers: [Wrestler]
    let onRemove: (Wrestler) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected (\(selectedWrestlers.count))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
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

// MARK: - Multi-Select Wrestler Row
struct MultiSelectWrestlerRow: View {
    let wrestler: Wrestler
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection checkbox
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
            }
            .padding()
            .background(isSelected ? Color.wweBlue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

#Preview {
    let sampleWrestlers = [
        Wrestler(name: "Roman Reigns", promotion: "WWE", title: "Universal Champion", category: .wwe),
        Wrestler(name: "Cody Rhodes", promotion: "WWE", title: "WWE Champion", category: .wwe),
        Wrestler(name: "Seth Rollins", promotion: "WWE", title: "World Heavyweight Champion", category: .wwe),
        Wrestler(name: "Jon Moxley", promotion: "AEW", title: "AEW World Champion", category: .aew),
        Wrestler(name: "Kenny Omega", promotion: "AEW", title: "AEW World Champion", category: .aew)
    ]
    
    return PickerWheelView(
        wrestlers: sampleWrestlers,
        selectedWrestler: .constant(nil),
        onWrestlerSelected: { _ in }
    )
}
