import Foundation
import FirebaseFirestore

class BookingEngine: ObservableObject {
    static let shared = BookingEngine()
    
    @Published var wrestlers: [Wrestler] = []
    @Published var championships: [Championship] = []
    @Published var stipulations: [Stipulation] = []
    @Published var wrestlerAvailability: [WrestlerAvailability] = []
    @Published var aiSuggestions: [AIBookingSuggestion] = []
    
    private let db = Firestore.firestore()
    
    private init() {
        loadWrestlers()
        loadChampionships()
        loadStipulations()
        loadWrestlerAvailability()
    }
    
    // MARK: - Data Loading
    private func loadWrestlers() {
        // TODO: Load from Firestore
        wrestlers = [
            Wrestler(name: "Roman Reigns", promotion: "WWE", title: "Universal Champion", category: .wwe),
            Wrestler(name: "Cody Rhodes", promotion: "WWE", title: "WWE Champion", category: .wwe),
            Wrestler(name: "Seth Rollins", promotion: "WWE", title: "World Heavyweight Champion", category: .wwe),
            Wrestler(name: "Jon Moxley", promotion: "AEW", title: "AEW World Champion", category: .aew),
            Wrestler(name: "Kenny Omega", promotion: "AEW", title: "AEW World Champion", category: .aew),
            Wrestler(name: "Kazuchika Okada", promotion: "NJPW", title: "IWGP World Heavyweight Champion", category: .njpw)
        ]
    }
    
    private func loadChampionships() {
        // TODO: Load from Firestore
        championships = [
            Championship(name: "WWE Universal Championship", promotion: "WWE", type: .world),
            Championship(name: "WWE Championship", promotion: "WWE", type: .world),
            Championship(name: "World Heavyweight Championship", promotion: "WWE", type: .world),
            Championship(name: "AEW World Championship", promotion: "AEW", type: .world),
            Championship(name: "IWGP World Heavyweight Championship", promotion: "NJPW", type: .world)
        ]
    }
    
    private func loadStipulations() {
        // TODO: Load from Firestore
        stipulations = [
            Stipulation(name: "Title vs Title", description: "Both championships on the line", type: .title),
            Stipulation(name: "Career vs Career", description: "Loser retires", type: .career),
            Stipulation(name: "Hair vs Hair", description: "Loser gets their head shaved", type: .hair),
            Stipulation(name: "Loser Leaves Town", description: "Loser must leave the promotion", type: .contract)
        ]
    }
    
    private func loadWrestlerAvailability() {
        // TODO: Load from Firestore
        wrestlerAvailability = []
    }
    
    // MARK: - Match Card Validation
    func validateMatchCard(_ matchCard: MatchCard, for show: FantasyBooking) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check participant count
        if matchCard.participants.count < matchCard.matchType.minParticipants {
            errors.append("Not enough participants for \(matchCard.matchType.rawValue) match")
        }
        
        if matchCard.participants.count > matchCard.matchType.maxParticipants {
            errors.append("Too many participants for \(matchCard.matchType.rawValue) match")
        }
        
        // Check wrestler availability
        for wrestler in matchCard.participants {
            if let availability = wrestlerAvailability.first(where: { $0.wrestlerId == wrestler.id }) {
                if !availability.isAvailable {
                    errors.append("\(wrestler.name) is not available (\(availability.reason?.rawValue ?? "Unknown reason"))")
                }
            }
        }
        
        // Check for duplicate wrestlers in same match
        let uniqueWrestlers = Set(matchCard.participants.map { $0.id })
        if uniqueWrestlers.count != matchCard.participants.count {
            errors.append("Duplicate wrestlers in same match")
        }
        
        // Check wrestler appearances across show
        let totalAppearances = show.matchCards.flatMap { $0.participants }.map { $0.id }.count
        let maxAppearances = show.constraints.maxWrestlerAppearances
        
        for wrestler in matchCard.participants {
            let appearances = show.matchCards.flatMap { $0.participants }.filter { $0.id == wrestler.id }.count
            if appearances >= maxAppearances {
                warnings.append("\(wrestler.name) appears in \(appearances) matches (max: \(maxAppearances))")
            }
        }
        
        // Check match duration
        if matchCard.estimatedDuration < 60 {
            warnings.append("Match duration seems too short")
        }
        
        if matchCard.estimatedDuration > 1800 {
            warnings.append("Match duration seems too long")
        }
        
        // Check title validity
        if let title = matchCard.title {
            if !championships.contains(where: { $0.id == title.id }) {
                errors.append("Invalid championship selected")
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    // MARK: - Show Validation
    func validateShow(_ show: FantasyBooking) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check match count
        if show.matchCards.count > show.constraints.maxMatches {
            errors.append("Too many matches for \(show.showType.rawValue) (max: \(show.constraints.maxMatches))")
        }
        
        // Check total duration
        let totalDuration = show.matchCards.reduce(0) { $0 + $1.estimatedDuration }
        if totalDuration > show.constraints.maxDuration {
            errors.append("Total show duration exceeds limit (\(Int(totalDuration/60)) minutes)")
        }
        
        if totalDuration < show.constraints.minDuration {
            warnings.append("Total show duration is below minimum (\(Int(totalDuration/60)) minutes)")
        }
        
        // Check for main event
        if show.constraints.requireMainEvent && !show.matchCards.contains(where: { $0.isMainEvent }) {
            errors.append("Show requires a main event")
        }
        
        // Check for opener
        if show.constraints.requireOpener && !show.matchCards.contains(where: { $0.isOpener }) {
            warnings.append("Consider adding an opening match")
        }
        
        // Check for duplicate matches
        if !show.constraints.allowRepeatMatches {
            let matchSignatures = show.matchCards.map { matchCard in
                let participants = matchCard.participants.map { $0.id }.sorted()
                return "\(matchCard.matchType.rawValue)-\(participants.joined(separator: "-"))"
            }
            
            let uniqueSignatures = Set(matchSignatures)
            if uniqueSignatures.count != matchSignatures.count {
                warnings.append("Duplicate matches detected")
            }
        }
        
        // Check storyline connections
        if show.constraints.requireStorylineConnection {
            let matchesWithStorylines = show.matchCards.filter { $0.storyline != nil && !$0.storyline!.isEmpty }
            if matchesWithStorylines.count < show.matchCards.count / 2 {
                warnings.append("Consider adding more storyline connections")
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    // MARK: - AI Suggestions
    func generateAISuggestions(for show: FantasyBooking) {
        var suggestions: [AIBookingSuggestion] = []
        
        // Generate match suggestions
        let matchSuggestions = generateMatchSuggestions(for: show)
        suggestions.append(contentsOf: matchSuggestions)
        
        // Generate storyline suggestions
        let storylineSuggestions = generateStorylineSuggestions(for: show)
        suggestions.append(contentsOf: storylineSuggestions)
        
        // Generate optimization suggestions
        let optimizationSuggestions = generateOptimizationSuggestions(for: show)
        suggestions.append(contentsOf: optimizationSuggestions)
        
        aiSuggestions = suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    private func generateMatchSuggestions(for show: FantasyBooking) -> [AIBookingSuggestion] {
        var suggestions: [AIBookingSuggestion] = []
        
        // Suggest main event if missing
        if !show.matchCards.contains(where: { $0.isMainEvent }) {
            let mainEventSuggestion = AIBookingSuggestion(
                type: .match,
                title: "Main Event Suggestion",
                description: "Add a high-profile main event to close the show",
                confidence: 0.9,
                reasoning: "Every major show needs a strong main event to send fans home happy",
                suggestedMatches: [
                    MatchCard(
                        matchType: .singles,
                        participants: [wrestlers[0], wrestlers[1]],
                        estimatedDuration: 1200,
                        isMainEvent: true
                    )
                ]
            )
            suggestions.append(mainEventSuggestion)
        }
        
        // Suggest title matches
        let availableChampionships = championships.filter { $0.isActive }
        let currentTitleMatches = show.matchCards.filter { $0.title != nil }
        
        if currentTitleMatches.count < availableChampionships.count / 2 {
            let titleMatchSuggestion = AIBookingSuggestion(
                type: .match,
                title: "Title Match Suggestion",
                description: "Add more championship matches to increase stakes",
                confidence: 0.7,
                reasoning: "Championship matches draw more interest and create higher stakes"
            )
            suggestions.append(titleMatchSuggestion)
        }
        
        return suggestions
    }
    
    private func generateStorylineSuggestions(for show: FantasyBooking) -> [AIBookingSuggestion] {
        var suggestions: [AIBookingSuggestion] = []
        
        // Suggest storyline connections
        let matchesWithoutStorylines = show.matchCards.filter { $0.storyline == nil || $0.storyline!.isEmpty }
        
        if matchesWithoutStorylines.count > 0 {
            let storylineSuggestion = AIBookingSuggestion(
                type: .storyline,
                title: "Storyline Connection",
                description: "Connect matches with ongoing storylines for better flow",
                confidence: 0.8,
                reasoning: "Storylines create emotional investment and keep fans engaged"
            )
            suggestions.append(storylineSuggestion)
        }
        
        return suggestions
    }
    
    private func generateOptimizationSuggestions(for show: FantasyBooking) -> [AIBookingSuggestion] {
        var suggestions: [AIBookingSuggestion] = []
        
        // Check show flow
        let totalDuration = show.matchCards.reduce(0) { $0 + $1.estimatedDuration }
        let showDuration = show.showType.duration
        
        if totalDuration > showDuration * 0.9 {
            let durationSuggestion = AIBookingSuggestion(
                type: .optimization,
                title: "Duration Optimization",
                description: "Consider reducing match times to fit within show duration",
                confidence: 0.6,
                reasoning: "Show is running long and may need time adjustments"
            )
            suggestions.append(durationSuggestion)
        }
        
        return suggestions
    }
    
    // MARK: - Title Lineage Management
    func updateTitleLineage(championshipId: String, newHolder: String, previousHolder: String?) {
        guard let championshipIndex = championships.firstIndex(where: { $0.id == championshipId }) else { return }
        
        var championship = championships[championshipIndex]
        var newLineage = championship.lineage
        
        // End previous reign if exists
        if let previousHolder = previousHolder,
           let previousReignIndex = newLineage.firstIndex(where: { $0.wrestler == previousHolder && $0.isCurrent }) {
            newLineage[previousReignIndex] = ChampionshipReign(
                wrestler: previousHolder,
                startDate: newLineage[previousReignIndex].startDate,
                endDate: Date(),
                daysHeld: Calendar.current.dateComponents([.day], from: newLineage[previousReignIndex].startDate, to: Date()).day ?? 0,
                isCurrent: false,
                notes: newLineage[previousReignIndex].notes
            )
        }
        
        // Add new reign
        let newReign = ChampionshipReign(
            wrestler: newHolder,
            startDate: Date(),
            endDate: nil,
            daysHeld: 0,
            isCurrent: true,
            notes: nil
        )
        newLineage.append(newReign)
        
        championship = Championship(
            name: championship.name,
            promotion: championship.promotion,
            type: championship.type,
            currentHolder: newHolder,
            lineage: newLineage,
            isActive: championship.isActive,
            imageURL: championship.imageURL
        )
        
        championships[championshipIndex] = championship
    }
    
    // MARK: - Wrestler Availability Management
    func updateWrestlerAvailability(wrestlerId: String, isAvailable: Bool, reason: AvailabilityReason?, startDate: Date?, endDate: Date?, notes: String?) {
        if let index = wrestlerAvailability.firstIndex(where: { $0.wrestlerId == wrestlerId }) {
            wrestlerAvailability[index] = WrestlerAvailability(
                wrestlerId: wrestlerId,
                isAvailable: isAvailable,
                reason: reason,
                startDate: startDate,
                endDate: endDate,
                notes: notes
            )
        } else {
            let newAvailability = WrestlerAvailability(
                wrestlerId: wrestlerId,
                isAvailable: isAvailable,
                reason: reason,
                startDate: startDate,
                endDate: endDate,
                notes: notes
            )
            wrestlerAvailability.append(newAvailability)
        }
    }
    
    // MARK: - Budget Management
    func calculateMatchCost(_ matchCard: MatchCard) -> Double {
        let baseCost = 1000.0
        let participantCost = Double(matchCard.participants.count) * 500.0
        let titleCost = matchCard.title != nil ? 2000.0 : 0.0
        let stipulationCost = matchCard.stipulation != nil ? 1000.0 : 0.0
        let durationCost = matchCard.estimatedDuration / 60 * 100.0
        
        return baseCost + participantCost + titleCost + stipulationCost + durationCost
    }
    
    func calculateShowCost(_ show: FantasyBooking) -> Double {
        let matchCosts = show.matchCards.map { calculateMatchCost($0) }
        return matchCosts.reduce(0, +)
    }
    
    // MARK: - Community Voting
    func submitVote(bookingId: String, userId: String, rating: Int, comment: String?) {
        let vote = CommunityVote(
            bookingId: bookingId,
            userId: userId,
            rating: rating,
            comment: comment
        )
        
        db.collection("community_votes")
            .addDocument(data: vote.dictionary) { error in
                if let error = error {
                    print("Error submitting vote: \(error)")
                }
            }
    }
    
    func getCommunityRating(for bookingId: String, completion: @escaping (Double) -> Void) {
        db.collection("community_votes")
            .whereField("bookingId", isEqualTo: bookingId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching votes: \(error)")
                    completion(0.0)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(0.0)
                    return
                }
                
                let votes = documents.compactMap { try? $0.data(as: CommunityVote.self) }
                let averageRating = votes.isEmpty ? 0.0 : Double(votes.map { $0.rating }.reduce(0, +)) / Double(votes.count)
                completion(averageRating)
            }
    }
}

// MARK: - Validation Result
struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
}

// MARK: - Extensions
extension CommunityVote {
    var dictionary: [String: Any] {
        return [
            "bookingId": bookingId,
            "userId": userId,
            "rating": rating,
            "comment": comment as Any,
            "createdAt": createdAt
        ]
    }
}
