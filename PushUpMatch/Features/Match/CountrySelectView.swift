import SwiftUI

/// Pick an opponent country. Countries are grouped into the three difficulty tiers.
struct CountrySelectView: View {
    @AppStorage(Country.userCountryKey) private var userCountryID = ""
    @AppStorage("suggestedDifficulty") private var suggestedDifficulty = ""
    @State private var selectedCountry: Country?
    @State private var showMatch = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    Text("CHOOSE YOUR OPPONENT")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(.orange)
                        .padding(.top, 8)

                    ForEach(Difficulty.allCases) { difficulty in
                        difficultySection(difficulty)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Quick Match")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showMatch) {
            if let country = selectedCountry {
                MatchView(country: country)
            }
        }
    }

    private func difficultySection(_ difficulty: Difficulty) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(difficulty.rawValue.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(difficultyColor(difficulty))
                Text("· \(difficulty.repsPerGoal) push-ups per goal")
                    .font(.caption)
                    .foregroundStyle(.gray)
                if difficulty.rawValue.lowercased() == suggestedDifficulty {
                    Text("★ RECOMMENDED")
                        .font(.caption2.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.orange)
                        .clipShape(Capsule())
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                // The player's own country can't be the opponent.
                ForEach(Country.countries(in: difficulty).filter { $0.id != userCountryID }) { country in
                    Button {
                        selectedCountry = country
                        showMatch = true
                    } label: {
                        HStack(spacing: 10) {
                            Text(country.flag)
                                .font(.system(size: 30))
                            Text(country.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(difficultyColor(difficulty).opacity(0.35), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy:   return .green
        case .medium: return .yellow
        case .hard:   return .red
        }
    }
}
