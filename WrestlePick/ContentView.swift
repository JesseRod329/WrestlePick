import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SimpleNewsView()
                .tabItem {
                    Image(systemName: "newspaper")
                    Text("News")
                }
            
            Text("Predictions Tab")
                .tabItem {
                    Image(systemName: "crystal.ball")
                    Text("Predictions")
                }
            
            Text("Awards Tab")
                .tabItem {
                    Image(systemName: "trophy")
                    Text("Awards")
                }
            
            Text("Profile Tab")
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