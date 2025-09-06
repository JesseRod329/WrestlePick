import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "figure.wrestling")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("WrestlePick")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Think you can book better than WWE? Prove it.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    FeatureCard(
                        title: "Track Rumors",
                        description: "Stay up to date with the latest wrestling news and rumors"
                    )
                    
                    FeatureCard(
                        title: "Make Predictions",
                        description: "Predict match outcomes and prove your wrestling knowledge"
                    )
                    
                    FeatureCard(
                        title: "Create Awards",
                        description: "Design your own wrestling awards and share with the community"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("Coming Soon to iOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("WrestlePick")
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


#Preview {
    ContentView()
}
