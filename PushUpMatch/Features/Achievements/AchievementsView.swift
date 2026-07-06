import SwiftUI
import SwiftData

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let condition: (PlayerStats) -> Bool
}

struct AchievementsView: View {
    @Query private var allStats: [PlayerStats]

    private var stats: PlayerStats? { allStats.first }

    private let achievements: [Achievement] = [
        Achievement(title: "First Blood",    description: "Complete your first rep",  icon: "figure.strengthtraining.traditional", condition: { $0.totalReps >= 1    }),
        Achievement(title: "Warm Up",        description: "10 total reps",            icon: "flame.fill",                          condition: { $0.totalReps >= 10   }),
        Achievement(title: "Centurion",      description: "100 total reps",           icon: "shield.fill",                         condition: { $0.totalReps >= 100  }),
        Achievement(title: "Gold Rush",      description: "Reach Gold rank",          icon: "bolt.fill",                           condition: { $0.rankEnum >= .gold     }),
        Achievement(title: "Diamond Arms",   description: "Reach Diamond rank",       icon: "rhombus.fill",                        condition: { $0.rankEnum >= .diamond  }),
        Achievement(title: "Champion",       description: "Reach Champion rank",      icon: "crown.fill",                          condition: { $0.rankEnum >= .champion }),
        Achievement(title: "Legend",         description: "Reach Legend rank — 10,000 push-ups", icon: "medal.fill",               condition: { $0.rankEnum >= .legend   }),
        Achievement(title: "Streak Starter", description: "3-day streak",             icon: "calendar.badge.checkmark",            condition: { $0.currentStreak >= 3 }),
        Achievement(title: "On Fire",        description: "7-day streak",             icon: "flame",                               condition: { $0.currentStreak >= 7 }),
        Achievement(title: "Rising Star",    description: "Reach Level 5",            icon: "star.fill",                           condition: { $0.level >= 5        }),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(achievements) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                isUnlocked: stats.map { achievement.condition($0) } ?? false
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: achievement.icon)
                .font(.system(size: 32))
                .foregroundStyle(isUnlocked ? .orange : .gray)
            Text(achievement.title)
                .font(.subheadline.bold())
                .foregroundStyle(isUnlocked ? .white : .gray)
                .multilineTextAlignment(.center)
            Text(achievement.description)
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(isUnlocked ? 0.1 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? Color.orange.opacity(0.4) : .clear, lineWidth: 1)
        )
    }
}
