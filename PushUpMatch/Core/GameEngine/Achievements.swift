import SwiftUI

/// A motivational goal with measurable progress toward a target.
struct AchievementDef: Identifiable, Sendable {
    let id: String            // stable key persisted once unlocked
    let title: String
    let description: String
    let icon: String
    let target: Int
    let tint: Color
    let progress: @Sendable (PlayerStats, [MatchRecord]) -> Int
}

/// Central achievement catalog + persistent unlock registry.
enum Achievements {

    static let all: [AchievementDef] = [
        // – Lifetime reps –
        AchievementDef(id: "first_rep",  title: "First Blood",   description: "Complete your first rep",        icon: "figure.strengthtraining.traditional", target: 1, tint: Color(red: 0.95, green: 0.30, blue: 0.30),
                       progress: { stats, _ in stats.totalReps }),
        AchievementDef(id: "reps_30",    title: "Warm Up",       description: "30 total push-ups",              icon: "flame.fill", target: 30, tint: .orange,
                       progress: { stats, _ in stats.totalReps }),
        AchievementDef(id: "reps_100",   title: "Centurion",     description: "100 total push-ups",             icon: "shield.fill", target: 100, tint: Color(red: 0.55, green: 0.65, blue: 0.75),
                       progress: { stats, _ in stats.totalReps }),
        AchievementDef(id: "reps_500",   title: "Iron Grinder",  description: "500 total push-ups",             icon: "bolt.fill", target: 500, tint: .yellow,
                       progress: { stats, _ in stats.totalReps }),
        AchievementDef(id: "reps_1000",  title: "Push Machine",  description: "1,000 total push-ups",           icon: "gearshape.fill", target: 1000, tint: Color(red: 0.55, green: 0.80, blue: 0.90),
                       progress: { stats, _ in stats.totalReps }),

        // – Ranks –
        AchievementDef(id: "rank_gold",   title: "Gold Rush",    description: "Reach Gold rank",                icon: "sun.max.fill", target: Rank.gold.minReps, tint: Rank.gold.color,
                       progress: { stats, _ in stats.totalReps }),
        AchievementDef(id: "rank_legend", title: "Legend",       description: "Reach Legend rank",              icon: "crown.fill", target: Rank.legend.minReps, tint: Rank.legend.color,
                       progress: { stats, _ in stats.totalReps }),

        // – Matches –
        AchievementDef(id: "first_win",  title: "First Victory", description: "Win your first match",           icon: "trophy.fill", target: 1, tint: Color(red: 1.00, green: 0.75, blue: 0.20),
                       progress: { _, records in records.filter(\.won).count }),
        AchievementDef(id: "wins_10",    title: "Serial Winner", description: "Win 10 matches",                 icon: "rosette", target: 10, tint: Color(red: 0.70, green: 0.40, blue: 1.00),
                       progress: { _, records in records.filter(\.won).count }),
        AchievementDef(id: "matches_25", title: "Veteran",       description: "Play 25 matches",                icon: "medal.fill", target: 25, tint: Color(red: 0.80, green: 0.50, blue: 0.20),
                       progress: { _, records in records.count }),
        AchievementDef(id: "clean_sheet", title: "Clean Sheet",  description: "Win without conceding a goal",   icon: "hand.raised.fill", target: 1, tint: Color(red: 0.25, green: 0.85, blue: 0.50),
                       progress: { _, records in records.contains { $0.won && $0.opponentGoals == 0 } ? 1 : 0 }),
        AchievementDef(id: "hat_trick",  title: "Hat-Trick",     description: "Score 3 goals in one match",     icon: "soccerball", target: 3, tint: .white,
                       progress: { _, records in records.map(\.userGoals).max() ?? 0 }),
        AchievementDef(id: "world_tour", title: "World Tour",    description: "Beat 5 different countries",     icon: "globe.europe.africa.fill", target: 5, tint: Color(red: 0.35, green: 0.65, blue: 1.00),
                       progress: { _, records in Set(records.filter(\.won).map(\.countryName)).count }),
        AchievementDef(id: "beast_50",   title: "Beast Mode",    description: "50 push-ups in a single match",  icon: "dumbbell.fill", target: 50, tint: Color(red: 1.00, green: 0.35, blue: 0.45),
                       progress: { stats, _ in stats.bestSession }),

        // – Streaks –
        AchievementDef(id: "streak_3",   title: "Streak Starter", description: "Train 3 days in a row",         icon: "calendar.badge.checkmark", target: 3, tint: .teal,
                       progress: { stats, _ in stats.currentStreak }),
        AchievementDef(id: "streak_7",   title: "On Fire",        description: "Train 7 days in a row",         icon: "flame", target: 7, tint: Color(red: 1.00, green: 0.45, blue: 0.15),
                       progress: { stats, _ in stats.currentStreak }),
        AchievementDef(id: "streak_30",  title: "Unstoppable",    description: "Train 30 days in a row",        icon: "infinity", target: 30, tint: Color(red: 0.85, green: 0.45, blue: 1.00),
                       progress: { stats, _ in stats.currentStreak }),

        // – Levels –
        AchievementDef(id: "level_5",    title: "Rising Star",    description: "Reach Level 5",                 icon: "star.fill", target: 5, tint: .yellow,
                       progress: { stats, _ in stats.level }),
        AchievementDef(id: "level_20",   title: "Superstar",      description: "Reach Level 20",                icon: "sparkles", target: 20, tint: Color(red: 1.00, green: 0.55, blue: 0.85),
                       progress: { stats, _ in stats.level }),
    ]

    private static let unlockedKey = "unlockedAchievements"

    static func unlockedIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: unlockedKey) ?? [])
    }

    /// Marks any newly satisfied achievements as unlocked and returns them
    /// (in catalog order) so the match flow can celebrate each one once.
    static func registerNewUnlocks(stats: PlayerStats, records: [MatchRecord]) -> [AchievementDef] {
        var unlocked = unlockedIDs()
        var fresh: [AchievementDef] = []
        for def in all where !unlocked.contains(def.id) {
            if def.progress(stats, records) >= def.target {
                unlocked.insert(def.id)
                fresh.append(def)
            }
        }
        if !fresh.isEmpty {
            UserDefaults.standard.set(Array(unlocked), forKey: unlockedKey)
        }
        return fresh
    }
}
