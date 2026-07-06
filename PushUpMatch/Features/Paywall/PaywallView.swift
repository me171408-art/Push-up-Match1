import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                Text("Push Up Match Pro")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(icon: "map.fill",                         text: "Full campaign unlocked")
                    FeatureRow(icon: "infinity",                         text: "Horde Mode & Speed Challenges")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis",        text: "Detailed stats & history")
                    FeatureRow(icon: "trophy.fill",                      text: "All achievements")
                }
                .padding(20)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Spacer()

                // StoreKit 2 subscription UI — replace groupID with your App Store group ID
                SubscriptionStoreView(groupID: "REPLACE_WITH_YOUR_SUBSCRIPTION_GROUP_ID")
                    .subscriptionStoreControlStyle(.buttons)
                    .tint(.orange)

                Button("Maybe Later") { dismiss() }
                    .foregroundStyle(.gray)
                    .font(.subheadline)
                    .padding(.bottom, 8)
            }
            .padding(24)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(.white)
        }
    }
}
