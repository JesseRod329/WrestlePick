import SwiftUI

struct PremiumFeatureGateView: View {
    let feature: PremiumFeature
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: feature.iconName)
                    .font(.system(size: 60))
                    .foregroundColor(.wweBlue)
                
                Text("Premium Feature")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(feature.name)
                    .font(.headline)
                    .foregroundColor(.wweBlue)
            }
            
            // Description
            VStack(spacing: 16) {
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    BenefitRow(
                        iconName: "crown.fill",
                        text: "Unlock all premium features"
                    )
                    
                    BenefitRow(
                        iconName: "infinity",
                        text: "Unlimited predictions and contests"
                    )
                    
                    BenefitRow(
                        iconName: "chart.bar.fill",
                        text: "Advanced analytics and insights"
                    )
                    
                    BenefitRow(
                        iconName: "eye.slash.fill",
                        text: "Ad-free experience"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // CTA buttons
            VStack(spacing: 12) {
                Button(action: onUpgrade) {
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.wweBlue)
                        .cornerRadius(12)
                }
                
                Button(action: onDismiss) {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.primary.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let iconName: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.subheadline)
                .foregroundColor(.wweBlue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Feature Gate Modifier
struct FeatureGateModifier: ViewModifier {
    let feature: PremiumFeature
    let isPremium: Bool
    let onUpgrade: () -> Void
    
    func body(content: Content) -> some View {
        if isPremium {
            content
        } else {
            ZStack {
                content
                    .blur(radius: 2)
                    .disabled(true)
                
                VStack {
                    Spacer()
                    
                    PremiumFeatureGateView(
                        feature: feature,
                        onUpgrade: onUpgrade,
                        onDismiss: { }
                    )
                    .padding()
                }
            }
        }
    }
}

// MARK: - Feature Gate Extension
extension View {
    func featureGate(
        _ feature: PremiumFeature,
        isPremium: Bool,
        onUpgrade: @escaping () -> Void
    ) -> some View {
        modifier(FeatureGateModifier(
            feature: feature,
            isPremium: isPremium,
            onUpgrade: onUpgrade
        ))
    }
}

// MARK: - Usage Limit View
struct UsageLimitView: View {
    let currentUsage: Int
    let limit: Int
    let featureName: String
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("\(featureName) Usage")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(currentUsage)/\(limit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: Double(currentUsage), total: Double(limit))
                    .progressViewStyle(LinearProgressViewStyle(tint: .wweBlue))
            }
            
            // Limit reached message
            if currentUsage >= limit {
                VStack(spacing: 12) {
                    Text("Limit Reached")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("You've reached your limit of \(limit) \(featureName.lowercased()) this month. Upgrade to Premium for unlimited access.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: onUpgrade) {
                        Text("Upgrade to Premium")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.wweBlue)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Premium Badge
struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption)
            
            Text("Premium")
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.wweBlue)
        .cornerRadius(8)
    }
}

// MARK: - Feature Lock View
struct FeatureLockView: View {
    let feature: PremiumFeature
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundColor(.gray)
            
            Text("Premium Feature")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(feature.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onUpgrade) {
                Text("Upgrade to Unlock")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.wweBlue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Upgrade Prompt View
struct UpgradePromptView: View {
    let title: String
    let message: String
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Benefits preview
            VStack(alignment: .leading, spacing: 8) {
                BenefitRow(
                    iconName: "infinity",
                    text: "Unlimited predictions"
                )
                
                BenefitRow(
                    iconName: "figure.wrestling",
                    text: "Advanced fantasy booking"
                )
                
                BenefitRow(
                    iconName: "chart.bar.fill",
                    text: "Detailed analytics"
                )
                
                BenefitRow(
                    iconName: "eye.slash.fill",
                    text: "Ad-free experience"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // CTA buttons
            VStack(spacing: 12) {
                Button(action: onUpgrade) {
                    Text("Upgrade Now")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.wweBlue)
                        .cornerRadius(12)
                }
                
                Button(action: onDismiss) {
                    Text("Not Now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Trial Offer View
struct TrialOfferView: View {
    let onStartTrial: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.wweBlue)
                
                Text("Free Trial Offer")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Try Premium free for 7 days, then $2.99/month")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Benefits
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(
                    iconName: "checkmark.circle.fill",
                    text: "Unlimited predictions for any event"
                )
                
                BenefitRow(
                    iconName: "checkmark.circle.fill",
                    text: "Advanced fantasy booking tools"
                )
                
                BenefitRow(
                    iconName: "checkmark.circle.fill",
                    text: "Early access to exclusive content"
                )
                
                BenefitRow(
                    iconName: "checkmark.circle.fill",
                    text: "Ad-free experience"
                )
                
                BenefitRow(
                    iconName: "checkmark.circle.fill",
                    text: "Priority customer support"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // CTA buttons
            VStack(spacing: 12) {
                Button(action: onStartTrial) {
                    Text("Start Free Trial")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.wweBlue)
                        .cornerRadius(12)
                }
                
                Button(action: onDismiss) {
                    Text("No Thanks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Terms
            Text("Cancel anytime. No commitment required.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.primary.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    PremiumFeatureGateView(
        feature: PremiumFeature(
            name: "Advanced Analytics",
            description: "Get detailed insights about your predictions",
            iconName: "chart.bar.fill",
            category: .analytics
        ),
        onUpgrade: { },
        onDismiss: { }
    )
}
