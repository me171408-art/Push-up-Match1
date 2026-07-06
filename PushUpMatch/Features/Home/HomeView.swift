import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allStats: [PlayerStats]
    @State private var showCountrySelect = false

    private var stats: PlayerStats {
        if let s = allStats.first { return s }
        let s = PlayerStats()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 28) {
                    Spacer()
                    titleBlock
                    rankBlock
                    statsRow
                    Spacer()
                    enterButton
                }
                .padding(24)
            }
            .navigationDestination(isPresented: $showCountrySelect) {
                CountrySelectView()
            }
        }
    }

    @AppStorage("playerName") private var playerName = ""

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text("PUSH-UP MATCH")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.orange)
            if !playerName.isEmpty {
                Text("Warrior \(playerName)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var rankBlock: some View {
        VStack(spacing: 6) {
            RankBadgeView(rank: stats.rankEnum, size: 118)
                .frame(height: 130)

            Text(stats.rank.uppercased())
                .font(.title.bold())
                .foregroundStyle(stats.rankEnum.color)
                .shadow(color: stats.rankEnum.color.opacity(0.5), radius: 8)
            Text("Level \(stats.level)")
                .foregroundStyle(.gray)
            ProgressView(value: stats.xpProgress)
                .tint(.orange)
                .padding(.horizontal, 40)
            if let next = stats.rankEnum.next, let left = stats.repsToNextRank {
                HStack(spacing: 6) {
                    RankBadgeView(rank: next, size: 26)
                        .frame(height: 30)
                    Text("\(left) reps to \(next.rawValue)")
                        .font(.caption.bold())
                        .foregroundStyle(next.color.opacity(0.9))
                }
                .padding(.top, 2)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatChip(label: "Total Reps",    value: "\(stats.totalReps)")
            StatChip(label: "Best Session",  value: "\(stats.bestSession)")
            StatChip(label: "Streak",        value: "\(stats.currentStreak)d")
        }
    }

    private var enterButton: some View {
        Button { showCountrySelect = true } label: {
            Text("⚽ QUICK MATCH")
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

extension Rank {
    var color: Color {
        switch self {
        case .iron:     return Color(white: 0.6)
        case .steel:    return Color(red: 0.55, green: 0.65, blue: 0.75)
        case .bronze:   return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver:   return Color(white: 0.85)
        case .gold:     return Color(red: 1.00, green: 0.84, blue: 0.00)
        case .platinum: return Color(red: 0.70, green: 0.90, blue: 0.90)
        case .diamond:  return Color(red: 0.40, green: 0.75, blue: 1.00)
        case .emerald:  return Color(red: 0.20, green: 0.80, blue: 0.45)
        case .master:   return Color(red: 0.70, green: 0.40, blue: 1.00)
        case .champion: return Color(red: 1.00, green: 0.45, blue: 0.20)
        case .legend:   return Color(red: 1.00, green: 0.25, blue: 0.35)
        }
    }
}

struct StatChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
