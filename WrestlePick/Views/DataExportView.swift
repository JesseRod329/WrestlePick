import SwiftUI

struct DataExportView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var showingShareSheet = false
    @State private var exportedData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 60))
                        .foregroundColor(.wweBlue)
                    
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Download all your WrestlePick data including predictions, achievements, and profile information.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Export Progress
                if isExporting {
                    VStack(spacing: 16) {
                        ProgressView(value: exportProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .tint(.wweBlue)
                        
                        Text("Exporting your data...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(exportProgress * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.wweBlue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Data Preview
                if !isExporting {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What's Included")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            DataItemRow(
                                icon: "person.circle",
                                title: "Profile Information",
                                description: "Username, bio, preferences, and settings"
                            )
                            
                            DataItemRow(
                                icon: "crystal.ball",
                                title: "Predictions",
                                description: "All your predictions and their outcomes"
                            )
                            
                            DataItemRow(
                                icon: "trophy",
                                title: "Achievements",
                                description: "Badges and accomplishments earned"
                            )
                            
                            DataItemRow(
                                icon: "chart.bar",
                                title: "Statistics",
                                description: "Accuracy rates, streaks, and rankings"
                            )
                            
                            DataItemRow(
                                icon: "heart",
                                title: "Engagement Data",
                                description: "Likes, shares, and social interactions"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Export Button
                if !isExporting {
                    Button(action: startExport) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.wweBlue)
                        .cornerRadius(12)
                    }
                }
                
                // Export Complete
                if exportedData != nil && !isExporting {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Export Complete!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your data has been prepared for download.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingShareSheet = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Data")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Data Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportedData {
                ShareSheet(activityItems: [data])
            }
        }
        .alert("Export Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Methods
    private func startExport() {
        isExporting = true
        exportProgress = 0.0
        
        // Simulate progress updates
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            exportProgress += 0.05
            
            if exportProgress >= 1.0 {
                timer.invalidate()
                performExport()
            }
        }
    }
    
    private func performExport() {
        authService.exportUserData { result in
            DispatchQueue.main.async {
                isExporting = false
                
                switch result {
                case .success(let data):
                    exportedData = data
                case .failure(let error):
                    alertMessage = "Failed to export data: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Data Item Row
struct DataItemRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.wweBlue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataExportView()
}
