import SwiftData
import Foundation

@Model
final class PlayerStats {
    var totalXP: Int      = 0
    var totalReps: Int    = 0
    var bestSession: Int  = 0
    var currentStreak: Int = 0
    var lastWorkoutDate: Date?

    init() {}

    var level: Int { max(1, totalXP / 100) }
    var xpProgress: Double { Double(totalXP % 100) / 100.0 }

    var rankEnum: Rank { Rank.rank(for: totalReps) }
    var rank: String { rankEnum.rawValue }

    /// Reps still needed for the next rank; nil at the top (Legend).
    var repsToNextRank: Int? {
        guard let next = rankEnum.next else { return nil }
        return max(0, next.minReps - totalReps)
    }
}

@Model
final class MatchRecord {
    var date: Date          = Date()
    var countryName: String = ""
    var countryFlag: String = ""
    var userGoals: Int      = 0
    var opponentGoals: Int  = 0
    var reps: Int           = 0
    var won: Bool           = false
    var xpEarned: Int       = 0

    init(
        date: Date = .now,
        countryName: String,
        countryFlag: String,
        userGoals: Int,
        opponentGoals: Int,
        reps: Int,
        won: Bool,
        xpEarned: Int
    ) {
        self.date          = date
        self.countryName   = countryName
        self.countryFlag   = countryFlag
        self.userGoals     = userGoals
        self.opponentGoals = opponentGoals
        self.reps          = reps
        self.won           = won
        self.xpEarned      = xpEarned
    }

    var scoreline: String { "\(userGoals) - \(opponentGoals)" }
}
