import SwiftUI

struct AlertSettingsView: View {
    @StateObject private var merchService = MerchService.shared
    @State private var priceAlerts: [PriceAlert] = []
    @State private var isLoading = false
    @State private var showingCreateAlert = false
    @State private var selectedAlert: PriceAlert?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                HeaderView(
                    totalAlerts: priceAlerts.count,
                    activeAlerts: priceAlerts.filter { $0.isActive }.count
                )
                .padding()
                
                // Content
                if isLoading {
                    LoadingView()
                } else if priceAlerts.isEmpty {
                    EmptyStateView()
                } else {
                    AlertsList(
                        alerts: priceAlerts,
                        onEdit: { alert in
                            selectedAlert = alert
                        },
                        onDelete: { alert in
                            deleteAlert(alert)
                        }
                    )
                }
            }
            .navigationTitle("Price Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateAlert = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadPriceAlerts()
            }
            .sheet(isPresented: $showingCreateAlert) {
                CreateAlertView()
            }
            .sheet(item: $selectedAlert) { alert in
                EditAlertView(alert: alert)
            }
        }
    }
    
    private func loadPriceAlerts() {
        isLoading = true
        
        merchService.fetchPriceAlerts(userId: "current_user") { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let alerts):
                    priceAlerts = alerts
                case .failure(let error):
                    print("Error loading price alerts: \(error)")
                    priceAlerts = []
                }
            }
        }
    }
    
    private func deleteAlert(_ alert: PriceAlert) {
        // TODO: Implement delete functionality
        priceAlerts.removeAll { $0.id == alert.id }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let totalAlerts: Int
    let activeAlerts: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(totalAlerts) Alerts")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Total Created")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(activeAlerts)")
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

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading alerts...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Price Alerts")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create price alerts to get notified when items go on sale or restock")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Alerts List
struct AlertsList: View {
    let alerts: [PriceAlert]
    let onEdit: (PriceAlert) -> Void
    let onDelete: (PriceAlert) -> Void
    
    var body: some View {
        List {
            ForEach(alerts) { alert in
                AlertRow(
                    alert: alert,
                    onEdit: {
                        onEdit(alert)
                    },
                    onDelete: {
                        onDelete(alert)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Alert Row
struct AlertRow: View {
    let alert: PriceAlert
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @StateObject private var merchService = MerchService.shared
    @State private var item: MerchItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alertTypeDisplayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let item = item {
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("Loading item...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(isActive: alert.isActive)
                    
                    Text(alert.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Alert details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target Price:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(String(format: "%.2f", alert.targetPrice))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.wweBlue)
                    
                    Spacer()
                }
                
                if let item = item {
                    HStack {
                        Text("Current Price:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("$\(String(format: "%.2f", item.currentPrice))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if alert.alertType == .priceDrop && item.currentPrice <= alert.targetPrice {
                            Text("TRIGGERED")
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
        .onAppear {
            loadItem()
        }
    }
    
    private var alertTypeDisplayName: String {
        switch alert.alertType {
        case .priceDrop:
            return "Price Drop Alert"
        case .priceRise:
            return "Price Rise Alert"
        case .restock:
            return "Restock Alert"
        case .newItem:
            return "New Item Alert"
        case .sale:
            return "Sale Alert"
        }
    }
    
    private func loadItem() {
        merchService.fetchMerchItem(id: alert.itemId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedItem):
                    item = fetchedItem
                case .failure(let error):
                    print("Error loading item: \(error)")
                }
            }
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                .font(.caption)
            
            Text(isActive ? "Active" : "Paused")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(isActive ? Color.green : Color.orange)
        .cornerRadius(4)
    }
}

// MARK: - Create Alert View
struct CreateAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var merchService = MerchService.shared
    
    @State private var searchText = ""
    @State private var selectedItem: MerchItem?
    @State private var alertType: AlertType = .priceDrop
    @State private var targetPrice: Double = 0
    @State private var isCreating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var filteredItems: [MerchItem] {
        if searchText.isEmpty {
            return merchService.merchItems
        } else {
            return merchService.merchItems.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.wrestler.localizedCaseInsensitiveContains(searchText) ||
                item.promotion.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Item selection
                if selectedItem == nil {
                    ItemSelectionList(
                        items: filteredItems,
                        onItemSelected: { item in
                            selectedItem = item
                            targetPrice = item.currentPrice * 0.9 // Default to 10% below current price
                        }
                    )
                } else {
                    AlertConfigurationView(
                        item: selectedItem!,
                        alertType: $alertType,
                        targetPrice: $targetPrice,
                        onBack: {
                            selectedItem = nil
                        },
                        onCreate: createAlert
                    )
                }
            }
            .navigationTitle("Create Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Alert Creation", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func createAlert() {
        guard let item = selectedItem else { return }
        
        isCreating = true
        
        let alert = PriceAlert(
            userId: "current_user", // TODO: Get from auth service
            itemId: item.id ?? "",
            targetPrice: targetPrice,
            alertType: alertType
        )
        
        merchService.createPriceAlert(alert) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success:
                    alertMessage = "Price alert created successfully!"
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                case .failure(let error):
                    alertMessage = "Failed to create alert: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search items...", text: $text)
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

// MARK: - Item Selection List
struct ItemSelectionList: View {
    let items: [MerchItem]
    let onItemSelected: (MerchItem) -> Void
    
    var body: some View {
        List {
            ForEach(items) { item in
                ItemSelectionRow(
                    item: item,
                    onTap: {
                        onItemSelected(item)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Item Selection Row
struct ItemSelectionRow: View {
    let item: MerchItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Item image
                AsyncImage(url: URL(string: item.imageURLs.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: item.category.iconName)
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Item info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(item.wrestler)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(item.promotion)
                            .font(.subheadline)
                            .foregroundColor(.wweBlue)
                    }
                    
                    Text("$\(String(format: "%.2f", item.currentPrice))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.wweBlue)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Alert Configuration View
struct AlertConfigurationView: View {
    let item: MerchItem
    @Binding var alertType: AlertType
    @Binding var targetPrice: Double
    let onBack: () -> Void
    let onCreate: () -> Void
    
    @State private var isCreating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Item info
                ItemInfoCard(item: item)
                
                // Alert type selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Alert Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        ForEach(AlertType.allCases, id: \.self) { type in
                            AlertTypeRow(
                                type: type,
                                isSelected: alertType == type,
                                onTap: {
                                    alertType = type
                                }
                            )
                        }
                    }
                }
                
                // Target price
                VStack(alignment: .leading, spacing: 16) {
                    Text("Target Price")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("$")
                                .font(.title2)
                                .foregroundColor(.primary)
                            
                            TextField("0.00", value: $targetPrice, format: .currency(code: "USD"))
                                .font(.title2)
                                .keyboardType(.decimalPad)
                        }
                        
                        Text(alertDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Create button
                Button(action: onCreate) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Create Alert")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(targetPrice > 0 ? Color.wweBlue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(targetPrice <= 0 || isCreating)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    onBack()
                }
            }
        }
    }
    
    private var alertDescription: String {
        switch alertType {
        case .priceDrop:
            return "Get notified when the price drops to $\(String(format: "%.2f", targetPrice)) or below"
        case .priceRise:
            return "Get notified when the price rises to $\(String(format: "%.2f", targetPrice)) or above"
        case .restock:
            return "Get notified when this item is back in stock"
        case .newItem:
            return "Get notified when new items from this wrestler are available"
        case .sale:
            return "Get notified when this item goes on sale"
        }
    }
}

// MARK: - Item Info Card
struct ItemInfoCard: View {
    let item: MerchItem
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.imageURLs.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: item.category.iconName)
                    .foregroundColor(.gray)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack {
                    Text(item.wrestler)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.promotion)
                        .font(.subheadline)
                        .foregroundColor(.wweBlue)
                }
                
                Text("$\(String(format: "%.2f", item.currentPrice))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.wweBlue)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Alert Type Row
struct AlertTypeRow: View {
    let type: AlertType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: type.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .wweBlue : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(alertTypeDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.wweBlue)
                }
            }
            .padding()
            .background(isSelected ? Color.wweBlue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.wweBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var alertTypeDescription: String {
        switch type {
        case .priceDrop:
            return "Notify when price drops"
        case .priceRise:
            return "Notify when price rises"
        case .restock:
            return "Notify when item restocks"
        case .newItem:
            return "Notify about new items"
        case .sale:
            return "Notify when item goes on sale"
        }
    }
}

// MARK: - Edit Alert View
struct EditAlertView: View {
    let alert: PriceAlert
    @Environment(\.dismiss) private var dismiss
    @StateObject private var merchService = MerchService.shared
    
    @State private var alertType: AlertType
    @State private var targetPrice: Double
    @State private var isActive: Bool
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(alert: PriceAlert) {
        self.alert = alert
        self._alertType = State(initialValue: alert.alertType)
        self._targetPrice = State(initialValue: alert.targetPrice)
        self._isActive = State(initialValue: alert.isActive)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Alert Type") {
                    Picker("Type", selection: $alertType) {
                        ForEach(AlertType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Target Price") {
                    HStack {
                        Text("$")
                        TextField("0.00", value: $targetPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Status") {
                    Toggle("Active", isOn: $isActive)
                }
                
                Section("Description") {
                    Text(alertDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAlert()
                    }
                    .disabled(isSaving)
                }
            }
            .alert("Alert Update", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var alertDescription: String {
        switch alertType {
        case .priceDrop:
            return "Get notified when the price drops to $\(String(format: "%.2f", targetPrice)) or below"
        case .priceRise:
            return "Get notified when the price rises to $\(String(format: "%.2f", targetPrice)) or above"
        case .restock:
            return "Get notified when this item is back in stock"
        case .newItem:
            return "Get notified when new items from this wrestler are available"
        case .sale:
            return "Get notified when this item goes on sale"
        }
    }
    
    private func saveAlert() {
        isSaving = true
        
        // TODO: Implement update functionality
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            alertMessage = "Alert updated successfully!"
            showingAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        }
    }
}

#Preview {
    AlertSettingsView()
}
