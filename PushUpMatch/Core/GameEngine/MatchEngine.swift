import Foundation
import Combine

enum MatchEvent: Equatable {
    case userGoal(score: Int)
    case opponentGoal(score: Int)
    case finalPhase
    case goldenGoal
    case matchOver(won: Bool)
    case yellowCard
    case redCard
}

/// Timed match (default 90 seconds). Most goals when the clock hits zero wins;
/// a tie goes to golden goal — the next goal from either side decides it.
/// The opponent scores on a timer (base tempo ± random deviation), adjusted by
/// rubber-banding so the score stays tense until the final moments.
@MainActor
final class MatchEngine: ObservableObject {
    let country: Country
    let matchDuration: Int

    @Published private(set) var reps = 0
    @Published private(set) var userGoals = 0
    @Published private(set) var opponentGoals = 0
    @Published private(set) var timeRemaining: Int
    @Published private(set) var goalAttemptSeconds: Int = 0
    @Published private(set) var hasStarted = false
    @Published private(set) var isMatchOver = false
    @Published private(set) var userWon = false
    @Published private(set) var isFinalPhase = false
    @Published private(set) var isGoldenGoal = false
    @Published private(set) var lastEvent: MatchEvent?

    private var yellowCardShown = false

    /// Final-phase warning kicks in with this many seconds left.
    private let finalPhaseThreshold = 15

    var repsPerGoal: Int { country.difficulty.repsPerGoal }
    var repsTowardNextGoal: Int { reps % repsPerGoal }

    private var opponentTimer: Timer?
    private var clockTimer: Timer?

    // Progress tracking for the opponent's next goal, so a user goal adjusts
    // the pace without wiping the opponent's accumulated progress.
    private var opponentIntervalStart: Date?
    private var opponentInterval: TimeInterval = 0

    init(country: Country, matchDuration: Int = 90) {
        self.country = country
        self.matchDuration = matchDuration
        self.timeRemaining = matchDuration
    }

    // MARK: – Lifecycle

    /// Called when the player is detected in push-up position.
    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        scheduleOpponentGoal()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.clockTick() }
        }
    }

    func stop() {
        opponentTimer?.invalidate()
        opponentTimer = nil
        clockTimer?.invalidate()
        clockTimer = nil
    }

    // MARK: – Clock

    /// One second of match time. Exposed for tests; normally fired by the timer.
    func clockTick() {
        guard hasStarted, !isMatchOver, !isGoldenGoal else { return }
        timeRemaining -= 1

        if timeRemaining <= finalPhaseThreshold, timeRemaining > 0, !isFinalPhase {
            isFinalPhase = true
            lastEvent = .finalPhase
        }

        if timeRemaining <= 0 {
            timeRemaining = 0
            clockTimer?.invalidate()
            if userGoals == opponentGoals {
                isGoldenGoal = true
                lastEvent = .goldenGoal
            } else {
                finish()
            }
            return
        }

        // Card system: track time elapsed on the current goal attempt.
        goalAttemptSeconds += 1
        let limit = country.difficulty.goalTimeLimit
        let yellowAt = country.difficulty.yellowCardThreshold

        if !yellowCardShown && goalAttemptSeconds >= yellowAt {
            yellowCardShown = true
            lastEvent = .yellowCard
        } else if goalAttemptSeconds >= limit {
            lastEvent = .redCard
            if userGoals > 0 { userGoals -= 1 }
            resetGoalAttempt()
        }
    }

    private func resetGoalAttempt() {
        goalAttemptSeconds = 0
        yellowCardShown = false
    }

    // MARK: – User side

    func registerRep() {
        guard hasStarted, !isMatchOver else { return }
        reps += 1
        if reps % repsPerGoal == 0 {
            userGoals += 1
            lastEvent = .userGoal(score: userGoals)
            resetGoalAttempt()
            handleScoreChange(opponentScored: false)
        }
    }

    // MARK: – Opponent side

    /// Exposed for tests; normally fired by the internal timer.
    func scoreOpponentGoal() {
        guard hasStarted, !isMatchOver else { return }
        opponentGoals += 1
        lastEvent = .opponentGoal(score: opponentGoals)
        resetGoalAttempt()
        handleScoreChange(opponentScored: true)
    }

    /// Next opponent goal delay: base tempo ± deviation, scaled by rubber-banding.
    func nextOpponentInterval(randomOffset: TimeInterval? = nil) -> TimeInterval {
        let difficulty = country.difficulty
        let offset = randomOffset
            ?? .random(in: -difficulty.goalIntervalDeviation...difficulty.goalIntervalDeviation)
        let base = difficulty.baseGoalInterval + offset
        let multiplier = Self.rubberMultiplier(
            scoreDiff: userGoals - opponentGoals,
            strength: difficulty.rubberStrength
        )
        return max(5, base * multiplier)
    }

    /// < 1 (opponent speeds up) when the user is ahead, > 1 (slows down) when behind.
    /// Score gap influence is capped at ±2 goals, per the rubber-banding design.
    static func rubberMultiplier(scoreDiff: Int, strength: Double) -> Double {
        let clamped = Double(max(-2, min(2, scoreDiff)))
        return 1 - strength * 0.4 * clamped
    }

    // MARK: – Shared scoring logic

    private func handleScoreChange(opponentScored: Bool) {
        if isGoldenGoal {
            finish()
            return
        }
        if opponentScored {
            // Opponent just scored: plan its next goal from scratch.
            scheduleOpponentGoal()
        } else {
            // User scored: adjust the opponent's pace via rubber-banding but
            // KEEP its accumulated progress — resetting it meant a fast player
            // could postpone the opponent's goal forever.
            rebalanceOpponentSchedule()
        }
    }

    func forceEnd() {
        guard hasStarted, !isMatchOver else { return }
        userGoals = Int.random(in: 0...4)
        opponentGoals = Int.random(in: 0...4)
        finish()
    }

    private func finish() {
        isMatchOver = true
        userWon = userGoals > opponentGoals
        stop()
        lastEvent = .matchOver(won: userWon)
    }

    private func scheduleOpponentGoal() {
        let interval = nextOpponentInterval()
        opponentInterval = interval
        opponentIntervalStart = Date()
        armOpponentTimer(after: interval)
    }

    /// Re-plan with the current rubber-band multiplier, carrying over the
    /// fraction of progress the opponent already made toward its next goal.
    private func rebalanceOpponentSchedule() {
        guard let start = opponentIntervalStart, opponentInterval > 0 else {
            scheduleOpponentGoal()
            return
        }
        let fraction = min(0.95, max(0, Date().timeIntervalSince(start) / opponentInterval))
        let newInterval = nextOpponentInterval()
        opponentInterval = newInterval
        opponentIntervalStart = Date().addingTimeInterval(-fraction * newInterval)
        armOpponentTimer(after: max(1, newInterval * (1 - fraction)))
    }

    private func armOpponentTimer(after delay: TimeInterval) {
        opponentTimer?.invalidate()
        opponentTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.scoreOpponentGoal() }
        }
    }
}
