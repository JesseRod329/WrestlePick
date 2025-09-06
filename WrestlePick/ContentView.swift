import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("WrestlePick")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Think you can book better than WWE? Prove it.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                VStack(spacing: 20) {
                    NavigationLink(destination: NewsView()) {
                        FeatureCard(title: "News", description: "Stay updated with wrestling news and rumors")
                    }
                    
                    NavigationLink(destination: PredictionsView()) {
                        FeatureCard(title: "Predictions", description: "Make predictions and track your accuracy")
                    }
                    
                    NavigationLink(destination: CommunityView()) {
                        FeatureCard(title: "Community", description: "Connect with other wrestling fans")
                    }
                    
                    NavigationLink(destination: AwardsView()) {
                        FeatureCard(title: "Awards", description: "Create your own wrestling awards")
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("WrestlePick")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

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

// Placeholder views for navigation
struct NewsView: View {
    var body: some View {
        Text("News View - Coming Soon")
            .navigationTitle("News")
    }
}

struct PredictionsView: View {
    var body: some View {
        Text("Predictions View - Coming Soon")
            .navigationTitle("Predictions")
    }
}

struct CommunityView: View {
    var body: some View {
        Text("Community View - Coming Soon")
            .navigationTitle("Community")
    }
}

struct AwardsView: View {
    var body: some View {
        Text("Awards View - Coming Soon")
            .navigationTitle("Awards")
    }
}

#Preview {
    ContentView()
}
