import Foundation

/// Lifetime push-up rank ladder. Thresholds ramp roughly geometrically from
/// Iron at 30 toward Legend at 3000 lifetime push-ups.
enum Rank: String, CaseIterable {
    case iron     = "Iron"
    case steel    = "Steel"
    case bronze   = "Bronze"
    case silver   = "Silver"
    case gold     = "Gold"
    case platinum = "Platinum"
    case diamond  = "Diamond"
    case emerald  = "Emerald"
    case master   = "Master"
    case champion = "Champion"
    case legend   = "Legend"

    var minReps: Int {
        switch self {
        case .iron:     return 30
        case .steel:    return 50
        case .bronze:   return 75
        case .silver:   return 120
        case .gold:     return 200
        case .platinum: return 300
        case .diamond:  return 500
        case .emerald:  return 750
        case .master:   return 1200
        case .champion: return 2000
        case .legend:   return 3000
        }
    }

    static func rank(for totalReps: Int) -> Rank {
        Rank.allCases.last { totalReps >= $0.minReps } ?? .iron
    }

    /// The rank after this one, nil for Legend.
    var next: Rank? {
        guard let index = Rank.allCases.firstIndex(of: self),
              index + 1 < Rank.allCases.count else { return nil }
        return Rank.allCases[index + 1]
    }
}

extension Rank: Comparable {
    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.minReps < rhs.minReps }
}

struct PlayerProgress {
    var totalXP: Int     = 0
    var totalReps: Int   = 0
    var bestSession: Int = 0
    var currentStreak: Int = 0
    var lastWorkoutDate: Date?

    var level: Int { max(1, totalXP / 100) }
    var rank: Rank { Rank.rank(for: totalReps) }
    var xpProgress: Double { Double(totalXP % 100) / 100.0 }

    mutating func add(reps: Int, xp: Int) {
        totalReps += reps
        totalXP   += xp
        if reps > bestSession { bestSession = reps }
    }

    mutating func updateStreak() {
        let cal = Calendar.current
        if let last = lastWorkoutDate {
            if cal.isDateInToday(last) { return }
            currentStreak = cal.isDateInYesterday(last) ? currentStreak + 1 : 1
        } else {
            currentStreak = 1
        }
        lastWorkoutDate = Date()
    }
}
