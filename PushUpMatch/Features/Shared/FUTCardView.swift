import SwiftUI

struct FUTCardView: View {
    let reps: Int
    let userGoals: Int
    let opponentGoals: Int
    let userCountry: Country?
    let opponentCountry: Country
    let playerName: String
    let streak: Int
    let level: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    // MARK: - Stats

    private var pwrStat: Int { min(99, max(40, reps * 2)) }
    private var spdStat: Int { min(99, max(40, Int(Double(reps) / 1.5))) }
    private var golStat: Int { min(99, max(40, userGoals * 22 + 35)) }
    private var defStat: Int { max(40, 99 - opponentGoals * 14) }
    private var strStat: Int { min(99, max(40, streak * 10 + 40)) }
    private var lvlStat: Int { min(99, max(40, level * 4 + 40)) }

    private var overall: Int {
        let w = Double(pwrStat) * 0.30
              + Double(spdStat) * 0.20
              + Double(golStat) * 0.20
              + Double(defStat) * 0.15
              + Double(strStat) * 0.10
              + Double(lvlStat) * 0.05
        return max(50, min(99, Int(w)))
    }

    // MARK: - Card Tier

    enum CardTier {
        case bronze, silver, gold, elite, legend, icon, wall, hero

        var label: String {
            switch self {
            case .bronze: return "BRONZE"
            case .silver: return "SILVER"
            case .gold:   return "GOLD"
            case .elite:  return "ELITE"
            case .legend: return "LEGEND"
            case .icon:   return "ICON"
            case .wall:   return "WALL"
            case .hero:   return "HERO"
            }
        }

        var gradientColors: [Color] {
            switch self {
            case .bronze:
                return [Color(red: 0.78, green: 0.52, blue: 0.24),
                        Color(red: 0.52, green: 0.30, blue: 0.10),
                        Color(red: 0.68, green: 0.44, blue: 0.18)]
            case .silver:
                return [Color(white: 0.80),
                        Color(white: 0.52),
                        Color(white: 0.72)]
            case .gold:
                return [Color(red: 0.95, green: 0.82, blue: 0.28),
                        Color(red: 0.72, green: 0.56, blue: 0.04),
                        Color(red: 0.88, green: 0.74, blue: 0.16)]
            case .elite:
                return [Color(red: 0.58, green: 0.30, blue: 0.90),
                        Color(red: 0.35, green: 0.12, blue: 0.62),
                        Color(red: 0.50, green: 0.24, blue: 0.82)]
            case .legend:
                return [Color(red: 0.80, green: 0.12, blue: 0.20),
                        Color(red: 0.50, green: 0.04, blue: 0.10),
                        Color(red: 0.70, green: 0.10, blue: 0.16)]
            case .icon:
                return [Color(red: 0.22, green: 0.18, blue: 0.10),
                        Color(red: 0.10, green: 0.08, blue: 0.04),
                        Color(red: 0.18, green: 0.14, blue: 0.08)]
            case .wall:
                return [Color(red: 0.14, green: 0.40, blue: 0.88),
                        Color(red: 0.06, green: 0.20, blue: 0.58),
                        Color(red: 0.10, green: 0.32, blue: 0.76)]
            case .hero:
                return [Color(red: 0.52, green: 0.10, blue: 0.72),
                        Color(red: 0.30, green: 0.04, blue: 0.46),
                        Color(red: 0.44, green: 0.08, blue: 0.62)]
            }
        }

        var textColor: Color {
            self == .silver
                ? Color(red: 0.22, green: 0.22, blue: 0.22)
                : Color(red: 1.00, green: 0.92, blue: 0.60)
        }
    }

    private var tier: CardTier {
        if opponentCountry.difficulty == .hard && userGoals > opponentGoals { return .icon }
        if opponentGoals == 0 && userGoals > opponentGoals               { return .wall }
        if userGoals >= 3                                                 { return .hero }
        if overall >= 93 { return .legend }
        if overall >= 85 { return .elite }
        if overall >= 75 { return .gold }
        if overall >= 65 { return .silver }
        return .bronze
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("MATCH CARD")
                    .font(.system(size: 12, weight: .black))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.45))

                card
                    .scaleEffect(appeared ? 1 : 0.25)
                    .opacity(appeared ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(appeared ? 0 : -30),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.68),
                        value: appeared
                    )

            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { onDismiss() }
        }
    }

    // MARK: - Card Shape

    private var card: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: tier.gradientColors[1], location: 0.0),
                            .init(color: tier.gradientColors[0], location: 0.35),
                            .init(color: tier.gradientColors[2], location: 0.65),
                            .init(color: tier.gradientColors[1], location: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(tier.textColor.opacity(0.35), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.55), radius: 32, x: 0, y: 12)

            VStack(spacing: 0) {
                topRow
                flagSection
                divider
                statsGrid
            }
        }
        .frame(width: 265, height: 390)
    }

    private var topRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(overall)")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(tier.textColor)
                Text("ATK")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(tier.textColor.opacity(0.75))
            }

            Spacer()

            Text(tier.label)
                .font(.system(size: 9, weight: .black))
                .tracking(1.2)
                .foregroundStyle(tier.textColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(tier.textColor.opacity(0.18))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
    }

    private var flagSection: some View {
        VStack(spacing: 6) {
            Text(userCountry?.flag ?? "💪")
                .font(.system(size: 76))

            let name = playerName.isEmpty
                ? (userCountry?.name ?? "WARRIOR").uppercased()
                : playerName.uppercased()
            Text(name)
                .font(.system(size: 11, weight: .black))
                .tracking(1.8)
                .foregroundStyle(tier.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    private var divider: some View {
        Rectangle()
            .fill(tier.textColor.opacity(0.22))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    private var statsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                statCell(value: pwrStat, label: "PWR")
                statCell(value: spdStat, label: "SPD")
                statCell(value: golStat, label: "GOL")
            }
            HStack(spacing: 0) {
                statCell(value: defStat, label: "DEF")
                statCell(value: strStat, label: "STR")
                statCell(value: lvlStat, label: "LVL")
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
    }

    private func statCell(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(tier.textColor)
            Text(label)
                .font(.system(size: 9, weight: .black))
                .tracking(0.6)
                .foregroundStyle(tier.textColor.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }
}
