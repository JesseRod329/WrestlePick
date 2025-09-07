import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RealDataNewsView()
                .tabItem {
                    Image(systemName: "newspaper")
                    Text("News")
                }
            
            RealDataPredictionsView()
                .tabItem {
                    Image(systemName: "crystal.ball")
                    Text("Predictions")
                }
            
            RealDataAwardsView()
                .tabItem {
                    Image(systemName: "trophy")
                    Text("Awards")
                }
            
            RealDataProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
            
            FantasyBookingView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Booking")
                }
        }
        .accentColor(.blue)
    }
}


#Preview {
    ContentView()
}