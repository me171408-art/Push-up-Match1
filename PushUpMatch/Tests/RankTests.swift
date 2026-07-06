import Testing
@testable import PushUpMatch

struct RankTests {

    @Test func startsAtIron() {
        #expect(Rank.rank(for: 0) == .iron)
        #expect(Rank.rank(for: 19) == .iron)
    }

    @Test func thresholdsPromoteExactlyAtBoundary() {
        #expect(Rank.rank(for: 20)  == .steel)
        #expect(Rank.rank(for: 30)  == .bronze)
        #expect(Rank.rank(for: 40)  == .silver)
        #expect(Rank.rank(for: 50)  == .gold)
        #expect(Rank.rank(for: 80)  == .platinum)
        #expect(Rank.rank(for: 100) == .diamond)
        #expect(Rank.rank(for: 150) == .emerald)
        #expect(Rank.rank(for: 200) == .master)
        #expect(Rank.rank(for: 250) == .champion)
        #expect(Rank.rank(for: 300) == .legend)
    }

    @Test func oneRepBelowBoundaryStaysDown() {
        #expect(Rank.rank(for: 49) == .silver)
        #expect(Rank.rank(for: 299) == .champion)
    }

    @Test func nextRankChainIsComplete() {
        #expect(Rank.iron.next == .steel)
        #expect(Rank.champion.next == .legend)
        #expect(Rank.legend.next == nil)
    }

    @Test func ranksAreOrdered() {
        #expect(Rank.iron < Rank.steel)
        #expect(Rank.gold < Rank.legend)
        #expect(Rank.rank(for: 700) >= .gold)
    }
}
