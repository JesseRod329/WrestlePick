import SwiftUI
import PhotosUI

struct SubmissionFormView: View {
    @StateObject private var merchService = MerchService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var reportType: ReportType = .price
    @State private var itemName: String = ""
    @State private var itemDescription: String = ""
    @State private var brand: String = ""
    @State private var category: MerchCategory = .tshirt
    @State private var wrestler: String = ""
    @State private var promotion: String = ""
    @State private var price: String = ""
    @State private var currency: String = "USD"
    @State private var store: String = ""
    @State private var location: String = ""
    @State private var availability: AvailabilityStatus = .inStock
    @State private var notes: String = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageData: [Data] = []
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Report type selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Report Type")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(ReportType.allCases, id: \.self) { type in
                                ReportTypeCard(
                                    type: type,
                                    isSelected: reportType == type,
                                    onTap: {
                                        reportType = type
                                    }
                                )
                            }
                        }
                    }
                    
                    // Item information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Item Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            // Item name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Item Name")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter item name", text: $itemName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter item description", text: $itemDescription, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                            
                            // Brand and category
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Brand")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    TextField("Enter brand", text: $brand)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Picker("Category", selection: $category) {
                                        ForEach(MerchCategory.allCases, id: \.self) { category in
                                            Text(category.rawValue).tag(category)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Wrestler and promotion
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Wrestler")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    TextField("Enter wrestler name", text: $wrestler)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Promotion")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    TextField("Enter promotion", text: $promotion)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                    }
                    
                    // Pricing information (if applicable)
                    if reportType == .price || reportType == .sale {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pricing Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Price")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        TextField("0.00", text: $price)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Currency")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Picker("Currency", selection: $currency) {
                                            Text("USD").tag("USD")
                                            Text("CAD").tag("CAD")
                                            Text("EUR").tag("EUR")
                                            Text("GBP").tag("GBP")
                                            Text("JPY").tag("JPY")
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Store")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    TextField("Enter store name", text: $store)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                    }
                    
                    // Availability information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Availability")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Status")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Picker("Availability", selection: $availability) {
                                    ForEach(AvailabilityStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Location (Optional)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter location", text: $location)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    
                    // Images
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Images")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            PhotosPicker(
                                selection: $selectedImages,
                                maxSelectionCount: 5,
                                matching: .images
                            ) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Select Images")
                                }
                                .font(.headline)
                                .foregroundColor(.wweBlue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.wweBlue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            if !imageData.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(imageData.enumerated()), id: \.offset) { index, data in
                                            Image(uiImage: UIImage(data: data) ?? UIImage())
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    Button(action: {
                                                        imageData.remove(at: index)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.white)
                                                            .background(Color.black.opacity(0.6))
                                                            .clipShape(Circle())
                                                    }
                                                    .padding(4),
                                                    alignment: .topTrailing
                                                )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Notes")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Any additional information", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Submit button
                    Button(action: submitReport) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Submit Report")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.wweBlue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
                .padding()
            }
            .navigationTitle("Submit Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedImages) { newImages in
                loadImages()
            }
            .alert("Report Submission", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !itemName.isEmpty && !wrestler.isEmpty && !promotion.isEmpty
    }
    
    private func loadImages() {
        imageData.removeAll()
        
        for image in selectedImages {
            image.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data {
                        DispatchQueue.main.async {
                            imageData.append(data)
                        }
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        // Create a new merch item if it doesn't exist
        let newItem = MerchItem(
            name: itemName,
            description: itemDescription,
            brand: brand,
            category: category,
            wrestler: wrestler,
            promotion: promotion,
            imageURLs: [], // Will be uploaded separately
            currentPrice: Double(price) ?? 0.0,
            currency: currency,
            availability: availability,
            regions: location.isEmpty ? [] : [location]
        )
        
        // Create the report
        let report = UserReport(
            userId: "current_user", // TODO: Get from auth service
            itemId: newItem.id ?? "",
            reportType: reportType,
            price: Double(price),
            currency: currency,
            store: store,
            location: location.isEmpty ? nil : location,
            availability: availability,
            notes: notes.isEmpty ? nil : notes,
            images: [] // Will be uploaded separately
        )
        
        // Submit the report
        merchService.submitReport(report) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    alertMessage = "Report submitted successfully! Thank you for contributing."
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                case .failure(let error):
                    alertMessage = "Failed to submit report: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Report Type Card
struct ReportTypeCard: View {
    let type: ReportType
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
                    .multilineTextAlignment(.center)
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
        case .price: return .blue
        case .availability: return .green
        case .newItem: return .purple
        case .restock: return .orange
        case .sale: return .red
        case .discontinued: return .gray
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
    SubmissionFormView()
}
