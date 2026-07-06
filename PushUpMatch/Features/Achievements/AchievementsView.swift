import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var allStats: [PlayerStats]
    @Query private var records: [MatchRecord]

    private var stats: PlayerStats? { allStats.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    if unlockedCount > 0 {
                        Text("\(unlockedCount) / \(Achievements.all.count) unlocked")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 6)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(Achievements.all) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                current: currentProgress(of: achievement),
                                isUnlocked: isUnlocked(achievement)
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

    private func currentProgress(of achievement: AchievementDef) -> Int {
        guard let stats else { return 0 }
        return achievement.progress(stats, records)
    }

    private func isUnlocked(_ achievement: AchievementDef) -> Bool {
        Achievements.unlockedIDs().contains(achievement.id)
            || currentProgress(of: achievement) >= achievement.target
    }

    private var unlockedCount: Int {
        Achievements.all.filter { isUnlocked($0) }.count
    }
}

struct AchievementCard: View {
    let achievement: AchievementDef
    let current: Int
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: achievement.icon)
                .font(.system(size: 32))
                .foregroundStyle(achievement.tint.opacity(isUnlocked ? 1 : 0.75))
                .saturation(isUnlocked ? 1 : 0.45)
                .shadow(color: isUnlocked ? achievement.tint.opacity(0.6) : .clear, radius: 8)
                .frame(height: 38)

            Text(achievement.title)
                .font(.subheadline.bold())
                .foregroundStyle(isUnlocked ? .white : .gray)
                .multilineTextAlignment(.center)

            Text(achievement.description)
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            if isUnlocked {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(achievement.tint)
            } else {
                VStack(spacing: 4) {
                    ProgressView(value: Double(min(current, achievement.target)),
                                 total: Double(achievement.target))
                        .tint(achievement.tint)
                    Text("\(min(current, achievement.target)) / \(achievement.target)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(minHeight: 175, alignment: .top)
        .background(Color.white.opacity(isUnlocked ? 0.1 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? achievement.tint.opacity(0.5) : .clear, lineWidth: 1)
        )
    }
}
