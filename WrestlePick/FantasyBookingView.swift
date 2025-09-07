import SwiftUI

struct FantasyBookingView: View {
    @State private var bookings: [FantasyBooking] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading fantasy bookings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(bookings) { booking in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(booking.title)
                                .font(.headline)
                                .lineLimit(2)
                            
                            Text(booking.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            HStack {
                                Text(booking.eventType.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.2))
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                Text("\(booking.matches.count) matches")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Fantasy Booking")
            .onAppear {
                loadBookings()
            }
        }
    }
    
    private func loadBookings() {
        // Simulate loading fantasy bookings
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            bookings = [
                FantasyBooking(
                    id: "1",
                    title: "WrestleMania Main Event",
                    description: "A dream match between two legendary wrestlers for the world championship.",
                    eventType: .payPerView,
                    matches: [
                        "World Championship: John Cena vs. The Rock",
                        "Tag Team Championship: The Usos vs. New Day",
                        "Women's Championship: Charlotte vs. Becky Lynch"
                    ],
                    createdAt: Date()
                ),
                FantasyBooking(
                    id: "2",
                    title: "SummerSlam Card",
                    description: "A stacked card for the biggest party of the summer.",
                    eventType: .payPerView,
                    matches: [
                        "Universal Championship: Roman Reigns vs. Brock Lesnar",
                        "Intercontinental Championship: Gunther vs. Drew McIntyre",
                        "Women's Tag Team: Damage CTRL vs. Team B.A.D."
                    ],
                    createdAt: Date().addingTimeInterval(-3600)
                ),
                FantasyBooking(
                    id: "3",
                    title: "Raw Main Event",
                    description: "A weekly show main event featuring top stars.",
                    eventType: .weekly,
                    matches: [
                        "Seth Rollins vs. AJ Styles",
                        "Bianca Belair vs. Rhea Ripley"
                    ],
                    createdAt: Date().addingTimeInterval(-7200)
                )
            ]
            isLoading = false
        }
    }
}

struct FantasyBooking: Identifiable {
    let id: String
    let title: String
    let description: String
    let eventType: EventType
    let matches: [String]
    let createdAt: Date
}

enum EventType: String, CaseIterable {
    case payPerView = "Pay-Per-View"
    case weekly = "Weekly Show"
    case special = "Special Event"
    case tournament = "Tournament"
}

#Preview {
    FantasyBookingView()
}