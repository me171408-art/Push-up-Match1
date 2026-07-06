import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \MatchRecord.date, order: .reverse) private var matches: [MatchRecord]
    @Query private var allStats: [PlayerStats]

    private var stats: PlayerStats? { allStats.first }
    private var wins: Int { matches.filter(\.won).count }
    private var losses: Int { matches.count - wins }
    private var winRate: Int {
        matches.isEmpty ? 0 : Int((Double(wins) / Double(matches.count) * 100).rounded())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        bests
                        matchRecord
                        rankLadder
                        if !matches.isEmpty { repChart }
                        history
                    }
                    .padding()
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var bests: some View {
        VStack(spacing: 10) {
            sectionHeader("PERSONAL BESTS")
            HStack(spacing: 12) {
                StatChip(label: "All-Time Reps", value: "\(stats?.totalReps ?? 0)")
                StatChip(label: "Best Session",  value: "\(stats?.bestSession ?? 0)")
                StatChip(label: "Level",         value: "\(stats?.level ?? 1)")
            }
        }
    }

    private var matchRecord: some View {
        VStack(spacing: 10) {
            sectionHeader("MATCH RECORD")
            HStack(spacing: 12) {
                StatChip(label: "Played", value: "\(matches.count)")
                StatChip(label: "Wins",   value: "\(wins)")
                StatChip(label: "Losses", value: "\(losses)")
            }
            if !matches.isEmpty {
                HStack {
                    Text("Win rate")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("\(winRate)%")
                        .font(.caption.bold())
                        .foregroundStyle(winRate >= 50 ? .green : .red)
                }
                ProgressView(value: Double(winRate) / 100)
                    .tint(winRate >= 50 ? .green : .red)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var rankLadder: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("RANK LADDER")
            ForEach(Rank.allCases, id: \.self) { rank in
                let totalReps = stats?.totalReps ?? 0
                let isCurrent = rank == (stats?.rankEnum ?? .iron)
                let isReached = totalReps >= rank.minReps

                HStack(spacing: 12) {
                    RankBadgeView(rank: rank, size: 38)
                        .frame(width: 44, height: 44)
                        .saturation(isReached ? 1 : 0.15)
                        .opacity(isReached ? 1 : 0.55)

                    Text(rank.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(isReached ? rank.color : .gray)

                    Spacer()

                    Text("\(rank.minReps)+ reps")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    if isReached {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(isCurrent ? rank.color : .green)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.gray.opacity(0.6))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(isCurrent ? 0.12 : 0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isCurrent ? rank.color.opacity(0.6) : .clear, lineWidth: 1.5)
                )
            }
        }
    }

    private var repChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("RECENT MATCHES")
            Chart(matches.prefix(14)) { match in
                BarMark(
                    x: .value("Date", match.date, unit: .day),
                    y: .value("Reps", match.reps)
                )
                .foregroundStyle(.orange)
            }
            .frame(height: 160)
            .chartXAxis(.hidden)
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("MATCH HISTORY")
            ForEach(matches.prefix(20)) { match in
                HStack {
                    Text(match.won ? "W" : "L")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(match.won ? Color.green : Color.red)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(match.countryFlag) \(match.countryName)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text(match.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(match.scoreline)
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                        Text("\(match.reps) reps · +\(match.xpEarned) XP")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
