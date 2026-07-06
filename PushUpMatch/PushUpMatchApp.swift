import SwiftUI
import SwiftData

@main
struct PushUpMatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PlayerStats.self, MatchRecord.self])
    }
}
