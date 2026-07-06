import SwiftUI

/// Full-screen picker where the player chooses the country they represent.
/// Shown at the end of onboarding, and on first entry for users who signed in
/// (they skip onboarding). Also reachable from Settings to change later.
struct MyCountryPickerView: View {
    let onSelected: (Country) -> Void

    @AppStorage(Country.userCountryKey) private var userCountryID = ""

    private var sortedCountries: [Country] {
        Country.all.sorted { $0.name < $1.name }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10) {
                    Text("REPRESENT YOUR COUNTRY")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)

                    Text("Choose the flag you'll fight for.\nEvery goal you score is a goal for your nation!")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 12)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(sortedCountries) { country in
                            Button {
                                userCountryID = country.id
                                onSelected(country)
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
                                .background(Color.white.opacity(country.id == userCountryID ? 0.18 : 0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            country.id == userCountryID ? Color.orange : Color.white.opacity(0.1),
                                            lineWidth: country.id == userCountryID ? 2 : 1
                                        )
                                )
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}
