import SwiftUI

struct RealDataAwardsView: View {
    @State private var awards: [Award] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading awards...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(awards) { award in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(award.name)
                                        .font(.headline)
                                    
                                    Text(award.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("\(award.points)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    
                                    Text("points")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Text(award.category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                if award.isUnlocked {
                                    Text("Unlocked")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Locked")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Awards")
            .onAppear {
                loadAwards()
            }
        }
    }
    
    private func loadAwards() {
        // Simulate loading awards
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            awards = [
                Award(
                    id: "1",
                    name: "First Prediction",
                    description: "Make your first prediction",
                    category: .prediction,
                    points: 10,
                    isUnlocked: true
                ),
                Award(
                    id: "2",
                    name: "Prediction Master",
                    description: "Make 10 correct predictions",
                    category: .achievement,
                    points: 100,
                    isUnlocked: false
                ),
                Award(
                    id: "3",
                    name: "News Reader",
                    description: "Read 50 news articles",
                    category: .engagement,
                    points: 50,
                    isUnlocked: true
                )
            ]
            isLoading = false
        }
    }
}

struct Award: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: AwardCategory
    let points: Int
    let isUnlocked: Bool
}

enum AwardCategory: String, CaseIterable {
    case prediction = "Prediction"
    case achievement = "Achievement"
    case engagement = "Engagement"
    case special = "Special"
}

#Preview {
    RealDataAwardsView()
}