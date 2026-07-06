import SwiftUI

struct ContentView: View {
    @State private var onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    @AppStorage(Country.userCountryKey) private var userCountryID = ""

    var body: some View {
        if !onboardingComplete {
            OnboardingView(isPresented: $onboardingComplete)
        } else if userCountryID.isEmpty {
            // Signed-in users skip onboarding but still need to pick their country.
            MyCountryPickerView { _ in }
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Arena", systemImage: "shield.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            AchievementsView()
                .tabItem { Label("Achievements", systemImage: "trophy.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.orange)
    }
}
