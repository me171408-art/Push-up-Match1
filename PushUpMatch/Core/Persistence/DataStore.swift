import SwiftData
import Foundation

@MainActor
final class DataStore {
    static let shared = DataStore()

    let container: ModelContainer

    private init() {
        let schema = Schema([PlayerStats.self, MatchRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // Force-unwrap is intentional: a failure here means the schema is broken at build time.
        container = try! ModelContainer(for: schema, configurations: config)
    }

    func fetchOrCreateStats(in context: ModelContext) -> PlayerStats {
        let results = (try? context.fetch(FetchDescriptor<PlayerStats>())) ?? []
        if let existing = results.first { return existing }
        let stats = PlayerStats()
        context.insert(stats)
        return stats
    }
}
