import SwiftUI
import UIKit

/// Full-screen celebration card shown after a match when the player
/// reaches a new rank ("Congratulations! You've reached Silver").
struct RankUpCardView: View {
    let rank: Rank
    let onContinue: () -> Void

    @State private var badgeShown = false
    @State private var raysAngle: Double = 0
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.93).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    rays
                        .rotationEffect(.degrees(raysAngle))

                    RankBadgeView(rank: rank, size: 130)
                        .scaleEffect(badgeShown ? (glowPulse ? 1.05 : 1) : 0.1)
                }
                .frame(width: 320, height: 320)

                Text("RANK UP!")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: rank.badgeGradient,
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: rank.color.opacity(0.6), radius: 12)
                    .scaleEffect(badgeShown ? 1 : 0.5)
                    .opacity(badgeShown ? 1 : 0)
                    .padding(.top, 8)

                Text("Congratulations! You've reached")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 18)
                    .opacity(badgeShown ? 1 : 0)

                Text(rank.rawValue)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(rank.color)
                    .shadow(color: rank.color.opacity(0.5), radius: 10)
                    .padding(.top, 2)
                    .opacity(badgeShown ? 1 : 0)

                Spacer()

                Button("Continue") { onContinue() }
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(28)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.45).delay(0.15)) {
                badgeShown = true
            }
            withAnimation(.linear(duration: 16).repeatForever(autoreverses: false)) {
                raysAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(1.0)) {
                glowPulse = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            SoundManager.shared.play("sfx_victory", volume: 0.8)
        }
    }

    /// Slowly rotating light rays behind the badge.
    private var rays: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(colors: [rank.color.opacity(0.45), .clear],
                                       startPoint: .bottom, endPoint: .top)
                    )
                    .frame(width: 5, height: 150)
                    .offset(y: -85)
                    .rotationEffect(.degrees(Double(index) / 12 * 360))
            }
        }
        .opacity(badgeShown ? 1 : 0)
    }
}

#Preview {
    RankUpCardView(rank: .silver) {}
}
