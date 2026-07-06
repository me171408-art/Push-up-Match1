import Testing
import Foundation
@testable import PushUpMatch

@MainActor
struct MatchEngineTests {

    private func makeEngine(
        difficulty: Difficulty = .medium,
        duration: Int = 90,
        started: Bool = true
    ) -> MatchEngine {
        let country = Country(id: "TT", name: "Testland", flag: "🏳️", difficulty: difficulty)
        let engine = MatchEngine(country: country, matchDuration: duration)
        if started { engine.start() }
        return engine
    }

    // MARK: – Kickoff gate

    @Test func noScoringBeforeStart() {
        let engine = makeEngine(started: false)
        for _ in 0..<10 { engine.registerRep() }
        engine.scoreOpponentGoal()
        #expect(engine.reps == 0)
        #expect(engine.userGoals == 0)
        #expect(engine.opponentGoals == 0)
    }

    // MARK: – Reps → goals

    @Test func eightRepsScoreOneGoalOnMedium() {
        let engine = makeEngine(difficulty: .medium)
        for _ in 0..<8 { engine.registerRep() }
        #expect(engine.userGoals == 1)
        #expect(engine.repsTowardNextGoal == 0)
        engine.stop()
    }

    @Test func fiveRepsScoreOneGoalOnEasy() {
        let engine = makeEngine(difficulty: .easy)
        for _ in 0..<5 { engine.registerRep() }
        #expect(engine.userGoals == 1)
        engine.stop()
    }

    @Test func twelveRepsScoreOneGoalOnHard() {
        let engine = makeEngine(difficulty: .hard)
        for _ in 0..<12 { engine.registerRep() }
        #expect(engine.userGoals == 1)
        engine.stop()
    }

    @Test func partialProgressDoesNotScore() {
        let engine = makeEngine(difficulty: .medium)
        for _ in 0..<7 { engine.registerRep() }
        #expect(engine.userGoals == 0)
        #expect(engine.repsTowardNextGoal == 7)
        engine.stop()
    }

    @Test func goalsDoNotEndTimedMatchEarly() {
        let engine = makeEngine(difficulty: .medium)
        for _ in 0..<48 { engine.registerRep() }  // 6 goals
        #expect(engine.userGoals == 6)
        #expect(engine.isMatchOver == false)
        engine.stop()
    }

    // MARK: – Clock

    @Test func finalPhaseTriggersInLastFifteenSeconds() {
        let engine = makeEngine(duration: 90)
        for _ in 0..<75 { engine.clockTick() }
        #expect(engine.timeRemaining == 15)
        #expect(engine.isFinalPhase == true)
        #expect(engine.isMatchOver == false)
        engine.stop()
    }

    @Test func leaderWinsAtFullTime() {
        let engine = makeEngine(difficulty: .medium, duration: 90)
        for _ in 0..<8 { engine.registerRep() }  // user 1 - 0
        for _ in 0..<90 { engine.clockTick() }
        #expect(engine.isMatchOver == true)
        #expect(engine.userWon == true)
    }

    @Test func opponentLeadWinsAtFullTime() {
        let engine = makeEngine(duration: 90)
        engine.scoreOpponentGoal()
        for _ in 0..<90 { engine.clockTick() }
        #expect(engine.isMatchOver == true)
        #expect(engine.userWon == false)
    }

    // MARK: – Golden goal

    @Test func tieAtFullTimeGoesToGoldenGoal() {
        let engine = makeEngine(duration: 90)
        for _ in 0..<90 { engine.clockTick() }  // 0-0 at full time
        #expect(engine.isGoldenGoal == true)
        #expect(engine.isMatchOver == false)
        engine.stop()
    }

    @Test func goldenGoalByUserWinsInstantly() {
        let engine = makeEngine(difficulty: .medium, duration: 90)
        for _ in 0..<90 { engine.clockTick() }
        for _ in 0..<8 { engine.registerRep() }  // golden goal
        #expect(engine.isMatchOver == true)
        #expect(engine.userWon == true)
    }

    @Test func goldenGoalByOpponentLosesInstantly() {
        let engine = makeEngine(duration: 90)
        for _ in 0..<90 { engine.clockTick() }
        engine.scoreOpponentGoal()
        #expect(engine.isMatchOver == true)
        #expect(engine.userWon == false)
    }

    @Test func noScoringAfterMatchOver() {
        let engine = makeEngine(duration: 90)
        engine.scoreOpponentGoal()
        for _ in 0..<90 { engine.clockTick() }
        #expect(engine.isMatchOver == true)
        let repsBefore = engine.reps
        engine.registerRep()
        engine.scoreOpponentGoal()
        #expect(engine.reps == repsBefore)
        #expect(engine.opponentGoals == 1)
    }

    // MARK: – Rubber-banding

    @Test func opponentSpeedsUpWhenUserLeads() {
        #expect(MatchEngine.rubberMultiplier(scoreDiff: 2, strength: 0.8) < 1.0)
    }

    @Test func opponentSlowsDownWhenUserTrails() {
        #expect(MatchEngine.rubberMultiplier(scoreDiff: -2, strength: 0.8) > 1.0)
    }

    @Test func hardDifficultyDisablesRubberBanding() {
        #expect(MatchEngine.rubberMultiplier(scoreDiff: 2, strength: 0.0) == 1.0)
        #expect(MatchEngine.rubberMultiplier(scoreDiff: -2, strength: 0.0) == 1.0)
    }

    @Test func scoreDiffInfluenceIsCapped() {
        let atCap     = MatchEngine.rubberMultiplier(scoreDiff: 2, strength: 0.5)
        let beyondCap = MatchEngine.rubberMultiplier(scoreDiff: 5, strength: 0.5)
        #expect(atCap == beyondCap)
    }

    @Test func intervalStaysWithinExpectedBounds() {
        let engine = makeEngine(difficulty: .medium)
        let interval = engine.nextOpponentInterval(randomOffset: 0)
        // Tied score, medium: base 30s, no rubber effect.
        #expect(interval == 30)
        engine.stop()
    }

    @Test func easyRubberBandingIsAggressiveWhenUserLeads() {
        // Easy (0.8 strength), user 2 ahead: opponent should be much faster.
        let multiplier = MatchEngine.rubberMultiplier(scoreDiff: 2, strength: 0.8)
        #expect(abs(multiplier - 0.36) < 0.0001)
    }
}
