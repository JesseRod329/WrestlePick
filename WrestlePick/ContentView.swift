import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NewsView()
                .tabItem {
                    Image(systemName: "newspaper")
                    Text("News")
                }
            
            PredictionsView()
                .tabItem {
                    Image(systemName: "crystal.ball")
                    Text("Predictions")
                }
            
            AwardsView()
                .tabItem {
                    Image(systemName: "trophy")
                    Text("Awards")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .accentColor(.accentColor)
    }
}

#Preview {
    ContentView()
}