import SwiftUI
import StoreKit

struct SettingsView: View {
    @AppStorage("soundEnabled")        private var soundEnabled        = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("cameraPosition")       private var cameraFront         = true
    @AppStorage(Country.userCountryKey) private var userCountryID       = ""
    @State private var showCountryPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    Section("My Country") {
                        Button {
                            showCountryPicker = true
                        } label: {
                            HStack {
                                Text("Representing")
                                    .foregroundStyle(.white)
                                Spacer()
                                if let country = Country.find(id: userCountryID) {
                                    Text("\(country.flag) \(country.name)")
                                        .foregroundStyle(.orange)
                                } else {
                                    Text("Choose…")
                                        .foregroundStyle(.gray)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    Section("Camera") {
                        Toggle("Use Front Camera", isOn: $cameraFront)
                    }
                    Section("Audio") {
                        Toggle("Sound Effects", isOn: $soundEnabled)
                    }
                    Section("Notifications") {
                        Toggle("Daily Reminders", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { _, enabled in
                                if enabled {
                                    Task {
                                        if await NotificationManager.shared.requestPermission() {
                                            NotificationManager.shared.scheduleDailyReminder()
                                        } else {
                                            notificationsEnabled = false
                                        }
                                    }
                                } else {
                                    NotificationManager.shared.cancelDailyReminder()
                                }
                            }
                    }
                    Section("Subscription") {
                        Button("Restore Purchases") {
                            Task { try? await AppStore.sync() }
                        }
                    }
                    Section("Legal") {
                        // Replace with your real privacy policy URL
                        Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCountryPicker) {
                MyCountryPickerView { _ in showCountryPicker = false }
            }
        }
    }
}
