import SwiftUI

/// Vector rank badge: a shield in the rank's metallic color with a tier emblem.
/// Replaces the old pre-rendered PNG badges so it stays crisp at any size.
struct RankBadgeView: View {
    let rank: Rank
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            // Shield base with a vivid two-tone gradient
            Image(systemName: "shield.fill")
                .font(.system(size: size))
                .foregroundStyle(
                    LinearGradient(
                        colors: rank.badgeGradient,
                        startPoint: .top, endPoint: .bottom
                    )
                )

            // Slightly darkened inner field — lets the tier color glow through
            Image(systemName: "shield.fill")
                .font(.system(size: size * 0.78))
                .foregroundStyle(.black.opacity(0.32))

            // Tier emblem
            Image(systemName: rank.emblemSymbol)
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, rank.badgeGradient[0]],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: size * 0.02, y: size * 0.015)
                .offset(y: -size * 0.045)
        }
        .frame(width: size * 1.1, height: size * 1.1)
        .shadow(color: rank.color.opacity(0.7), radius: size * 0.12)
    }
}

extension Rank {
    /// Bright top / deep bottom gradient pair for the badge shield.
    var badgeGradient: [Color] {
        switch self {
        case .iron:     return [Color(white: 0.78), Color(white: 0.32)]
        case .steel:    return [Color(red: 0.72, green: 0.84, blue: 0.95), Color(red: 0.22, green: 0.38, blue: 0.55)]
        case .bronze:   return [Color(red: 1.00, green: 0.68, blue: 0.32), Color(red: 0.55, green: 0.28, blue: 0.08)]
        case .silver:   return [Color(white: 0.97), Color(white: 0.52)]
        case .gold:     return [Color(red: 1.00, green: 0.90, blue: 0.35), Color(red: 0.90, green: 0.55, blue: 0.00)]
        case .platinum: return [Color(red: 0.80, green: 1.00, blue: 0.96), Color(red: 0.25, green: 0.62, blue: 0.62)]
        case .diamond:  return [Color(red: 0.60, green: 0.90, blue: 1.00), Color(red: 0.12, green: 0.42, blue: 0.90)]
        case .emerald:  return [Color(red: 0.45, green: 1.00, blue: 0.65), Color(red: 0.02, green: 0.48, blue: 0.28)]
        case .master:   return [Color(red: 0.85, green: 0.60, blue: 1.00), Color(red: 0.42, green: 0.12, blue: 0.78)]
        case .champion: return [Color(red: 1.00, green: 0.68, blue: 0.28), Color(red: 0.85, green: 0.18, blue: 0.08)]
        case .legend:   return [Color(red: 1.00, green: 0.55, blue: 0.55), Color(red: 0.72, green: 0.02, blue: 0.25)]
        }
    }

    /// SF Symbol shown inside the shield for each tier.
    var emblemSymbol: String {
        switch self {
        case .iron:     return "chevron.up"
        case .steel:    return "bolt.fill"
        case .bronze:   return "medal.fill"
        case .silver:   return "star.fill"
        case .gold:     return "sun.max.fill"
        case .platinum: return "sparkles"
        case .diamond:  return "diamond.fill"
        case .emerald:  return "hexagon.fill"
        case .master:   return "flame.fill"
        case .champion: return "trophy.fill"
        case .legend:   return "crown.fill"
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 14) {
            ForEach(Rank.allCases, id: \.self) { rank in
                HStack(spacing: 16) {
                    RankBadgeView(rank: rank, size: 44)
                    Text(rank.rawValue)
                        .font(.headline)
                        .foregroundStyle(rank.color)
                }
            }
        }
    }
}
