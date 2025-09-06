import SwiftUI

struct PaywallView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlan: SubscriptionPlan?
    @State private var isPurchasing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var currentPage = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HeaderView()
                    
                    // Feature showcase
                    FeatureShowcaseView(currentPage: $currentPage)
                    
                    // Pricing plans
                    PricingPlansView(
                        plans: subscriptionService.subscriptionPlans,
                        selectedPlan: $selectedPlan
                    )
                    
                    // Benefits list
                    BenefitsListView()
                    
                    // CTA section
                    CTASectionView(
                        selectedPlan: selectedPlan,
                        isPurchasing: isPurchasing,
                        onPurchase: {
                            purchaseSelectedPlan()
                        },
                        onRestore: {
                            restorePurchases()
                        }
                    )
                    
                    // Footer
                    FooterView()
                }
            }
            .navigationTitle("Go Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func purchaseSelectedPlan() {
        guard let plan = selectedPlan else { return }
        
        isPurchasing = true
        
        Task {
            do {
                try await subscriptionService.purchaseSubscription(plan)
                await MainActor.run {
                    isPurchasing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                try await subscriptionService.restorePurchases()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // App icon
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            // Title
            Text("Unlock Premium")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Subtitle
            Text("Get the full WrestlePick experience with unlimited predictions, advanced tools, and exclusive content")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 32)
    }
}

// MARK: - Feature Showcase View
struct FeatureShowcaseView: View {
    @Binding var currentPage: Int
    
    let features = [
        FeatureShowcase(
            title: "Unlimited Predictions",
            description: "Make as many predictions as you want for any wrestling event",
            iconName: "crystal.ball.fill",
            color: .blue
        ),
        FeatureShowcase(
            title: "Advanced Fantasy Booking",
            description: "Create detailed storylines and match cards with our advanced tools",
            iconName: "figure.wrestling",
            color: .purple
        ),
        FeatureShowcase(
            title: "Early Access Content",
            description: "Get exclusive news and content before everyone else",
            iconName: "clock.fill",
            color: .orange
        ),
        FeatureShowcase(
            title: "Ad-Free Experience",
            description: "Enjoy the app without any interruptions",
            iconName: "eye.slash.fill",
            color: .green
        )
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            TabView(selection: $currentPage) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeatureShowcaseCard(feature: feature)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 200)
            
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.wweBlue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Feature Showcase
struct FeatureShowcase {
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

// MARK: - Feature Showcase Card
struct FeatureShowcaseCard: View {
    let feature: FeatureShowcase
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: feature.iconName)
                .font(.system(size: 40))
                .foregroundColor(feature.color)
            
            Text(feature.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(feature.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Pricing Plans View
struct PricingPlansView: View {
    let plans: [SubscriptionPlan]
    @Binding var selectedPlan: SubscriptionPlan?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                ForEach(plans) { plan in
                    PricingPlanCard(
                        plan: plan,
                        isSelected: selectedPlan?.id == plan.id,
                        onTap: {
                            selectedPlan = plan
                        }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Pricing Plan Card
struct PricingPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(plan.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if plan.isPopular {
                        PopularBadge()
                    }
                }
                
                // Price
                HStack(alignment: .bottom, spacing: 4) {
                    Text("$\(String(format: "%.2f", plan.price))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("/\(plan.duration.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let savings = plan.savingsText {
                        Text(savings)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                
                // Features preview
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.features.prefix(3)) { feature in
                        FeatureRow(feature: feature)
                    }
                    
                    if plan.features.count > 3 {
                        Text("+ \(plan.features.count - 3) more features")
                            .font(.caption)
                            .foregroundColor(.wweBlue)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.wweBlue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.wweBlue : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Popular Badge
struct PopularBadge: View {
    var body: some View {
        Text("MOST POPULAR")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.wweBlue)
            .cornerRadius(8)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: feature.iconName)
                .font(.caption)
                .foregroundColor(.wweBlue)
                .frame(width: 16)
            
            Text(feature.name)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Benefits List View
struct BenefitsListView: View {
    let benefits = [
        BenefitItem(
            title: "Unlimited Predictions",
            description: "Make as many predictions as you want for any wrestling event",
            iconName: "crystal.ball.fill",
            category: "Predictions"
        ),
        BenefitItem(
            title: "Advanced Fantasy Booking",
            description: "Create detailed storylines and match cards with our advanced tools",
            iconName: "figure.wrestling",
            category: "Fantasy"
        ),
        BenefitItem(
            title: "Early Access Content",
            description: "Get exclusive news and content before everyone else",
            iconName: "clock.fill",
            category: "Content"
        ),
        BenefitItem(
            title: "Ad-Free Experience",
            description: "Enjoy the app without any interruptions",
            iconName: "eye.slash.fill",
            category: "Experience"
        ),
        BenefitItem(
            title: "Advanced Analytics",
            description: "Detailed statistics and insights about your predictions",
            iconName: "chart.bar.fill",
            category: "Analytics"
        ),
        BenefitItem(
            title: "Custom Categories",
            description: "Create your own prediction categories",
            iconName: "tag.fill",
            category: "Customization"
        ),
        BenefitItem(
            title: "Priority Support",
            description: "Get help faster with priority support",
            iconName: "headphones",
            category: "Support"
        )
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Premium Benefits")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                ForEach(benefits) { benefit in
                    BenefitCard(benefit: benefit)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Benefit Item
struct BenefitItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let category: String
}

// MARK: - Benefit Card
struct BenefitCard: View {
    let benefit: BenefitItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: benefit.iconName)
                .font(.title2)
                .foregroundColor(.wweBlue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(benefit.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - CTA Section View
struct CTASectionView: View {
    let selectedPlan: SubscriptionPlan?
    let isPurchasing: Bool
    let onPurchase: () -> Void
    let onRestore: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Purchase button
            Button(action: onPurchase) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(selectedPlan != nil ? "Start Free Trial" : "Select a Plan")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedPlan != nil ? Color.wweBlue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedPlan == nil || isPurchasing)
            
            // Restore purchases button
            Button(action: onRestore) {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(.wweBlue)
            }
            
            // Terms and privacy
            VStack(spacing: 8) {
                Text("By subscribing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button("Terms of Service") {
                        // TODO: Open terms
                    }
                    .font(.caption)
                    .foregroundColor(.wweBlue)
                    
                    Button("Privacy Policy") {
                        // TODO: Open privacy policy
                    }
                    .font(.caption)
                    .foregroundColor(.wweBlue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 32)
    }
}

// MARK: - Footer View
struct FooterView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Join thousands of wrestling fans who trust WrestlePick for their predictions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Testimonials
            VStack(spacing: 12) {
                TestimonialCard(
                    text: "WrestlePick has completely changed how I follow wrestling. The predictions are spot on!",
                    author: "Sarah M."
                )
                
                TestimonialCard(
                    text: "The fantasy booking tools are incredible. I can finally show my friends who can book better!",
                    author: "Mike R."
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
}

// MARK: - Testimonial Card
struct TestimonialCard: View {
    let text: String
    let author: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(text)\"")
                .font(.subheadline)
                .foregroundColor(.primary)
                .italic()
            
            Text("- \(author)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PaywallView()
}
