import Testing
@testable import PushUpMatch

struct RankTests {

    @Test func startsAtIron() {
        #expect(Rank.rank(for: 0) == .iron)
        #expect(Rank.rank(for: 49) == .iron)
    }

    @Test func thresholdsPromoteExactlyAtBoundary() {
        #expect(Rank.rank(for: 50)   == .steel)
        #expect(Rank.rank(for: 75)   == .bronze)
        #expect(Rank.rank(for: 120)  == .silver)
        #expect(Rank.rank(for: 200)  == .gold)
        #expect(Rank.rank(for: 300)  == .platinum)
        #expect(Rank.rank(for: 500)  == .diamond)
        #expect(Rank.rank(for: 750)  == .emerald)
        #expect(Rank.rank(for: 1200) == .master)
        #expect(Rank.rank(for: 2000) == .champion)
        #expect(Rank.rank(for: 3000) == .legend)
    }

    @Test func oneRepBelowBoundaryStaysDown() {
        #expect(Rank.rank(for: 199) == .silver)
        #expect(Rank.rank(for: 2999) == .champion)
    }

    @Test func nextRankChainIsComplete() {
        #expect(Rank.iron.next == .steel)
        #expect(Rank.champion.next == .legend)
        #expect(Rank.legend.next == nil)
    }

    @Test func ranksAreOrdered() {
        #expect(Rank.iron < Rank.steel)
        #expect(Rank.gold < Rank.legend)
        #expect(Rank.rank(for: 700) >= .diamond)
    }
}
