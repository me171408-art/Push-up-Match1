import SwiftUI
import UIKit

/// Full-screen celebration shown after a match when the player unlocks
/// an achievement ("Achievement Unlocked — Hat-Trick!").
struct AchievementUnlockedCardView: View {
    let achievement: AchievementDef
    let onContinue: () -> Void

    @State private var iconShown = false
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

                    Circle()
                        .fill(
                            LinearGradient(colors: [achievement.tint, achievement.tint.opacity(0.45)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: achievement.tint.opacity(0.7), radius: 18)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.black)
                }
                .scaleEffect(iconShown ? (glowPulse ? 1.05 : 1) : 0.1)
                .frame(width: 320, height: 320)

                Text("ACHIEVEMENT UNLOCKED!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(achievement.tint)
                    .multilineTextAlignment(.center)
                    .shadow(color: achievement.tint.opacity(0.5), radius: 10)
                    .scaleEffect(iconShown ? 1 : 0.5)
                    .opacity(iconShown ? 1 : 0)
                    .padding(.top, 8)

                Text(achievement.title)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 14)
                    .opacity(iconShown ? 1 : 0)

                Text(achievement.description)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .opacity(iconShown ? 1 : 0)

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
                iconShown = true
            }
            withAnimation(.linear(duration: 16).repeatForever(autoreverses: false)) {
                raysAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(1.0)) {
                glowPulse = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            SoundManager.shared.play("sfx_goal", volume: 0.8)
        }
    }

    private var rays: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(colors: [achievement.tint.opacity(0.45), .clear],
                                       startPoint: .bottom, endPoint: .top)
                    )
                    .frame(width: 5, height: 150)
                    .offset(y: -85)
                    .rotationEffect(.degrees(Double(index) / 12 * 360))
            }
        }
        .opacity(iconShown ? 1 : 0)
    }
}

#Preview {
    AchievementUnlockedCardView(achievement: Achievements.all[0]) {}
}
