import Foundation

/// Match difficulty. Countries are grouped into three fixed tiers so balancing
/// lives in exactly three parameter sets, not per-country tweaks.
enum Difficulty: String, CaseIterable, Identifiable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"

    var id: String { rawValue }

    /// Push-ups required per goal. Rises gently with difficulty.
    var repsPerGoal: Int {
        switch self {
        case .easy:   return 5
        case .medium: return 8
        case .hard:   return 12
        }
    }

    /// Rubber-banding strength (0…1). The real difficulty lever:
    /// easy keeps the score close and forgiving, hard turns assistance off.
    var rubberStrength: Double {
        switch self {
        case .easy:   return 0.8
        case .medium: return 0.4
        case .hard:   return 0.0
        }
    }

    /// Average seconds between opponent goals (constant across difficulties).
    var baseGoalInterval: TimeInterval { 30 }

    /// Random deviation applied to each opponent goal (± seconds).
    var goalIntervalDeviation: TimeInterval { 10 }
}

struct Country: Identifiable, Equatable {
    let id: String        // ISO-ish code, stable identity
    let name: String
    let flag: String      // emoji flag (renders on device)
    let difficulty: Difficulty

    static let all: [Country] = [
        // Easy tier (18)
        Country(id: "CA", name: "Canada",       flag: "🇨🇦", difficulty: .easy),
        Country(id: "AU", name: "Australia",    flag: "🇦🇺", difficulty: .easy),
        Country(id: "IS", name: "Iceland",      flag: "🇮🇸", difficulty: .easy),
        Country(id: "FI", name: "Finland",      flag: "🇫🇮", difficulty: .easy),
        Country(id: "IE", name: "Ireland",      flag: "🇮🇪", difficulty: .easy),
        Country(id: "GR", name: "Greece",       flag: "🇬🇷", difficulty: .easy),
        Country(id: "RO", name: "Romania",      flag: "🇷🇴", difficulty: .easy),
        Country(id: "CZ", name: "Czechia",      flag: "🇨🇿", difficulty: .easy),
        Country(id: "HU", name: "Hungary",      flag: "🇭🇺", difficulty: .easy),
        Country(id: "SA", name: "Saudi Arabia", flag: "🇸🇦", difficulty: .easy),
        Country(id: "QA", name: "Qatar",        flag: "🇶🇦", difficulty: .easy),
        Country(id: "CN", name: "China",        flag: "🇨🇳", difficulty: .easy),
        Country(id: "IN", name: "India",        flag: "🇮🇳", difficulty: .easy),
        Country(id: "ID", name: "Indonesia",    flag: "🇮🇩", difficulty: .easy),
        Country(id: "TH", name: "Thailand",     flag: "🇹🇭", difficulty: .easy),
        Country(id: "ZA", name: "South Africa", flag: "🇿🇦", difficulty: .easy),
        Country(id: "NZ", name: "New Zealand",  flag: "🇳🇿", difficulty: .easy),
        Country(id: "CR", name: "Costa Rica",   flag: "🇨🇷", difficulty: .easy),

        // Medium tier (18)
        Country(id: "TR", name: "Türkiye",      flag: "🇹🇷", difficulty: .medium),
        Country(id: "US", name: "USA",          flag: "🇺🇸", difficulty: .medium),
        Country(id: "MX", name: "Mexico",       flag: "🇲🇽", difficulty: .medium),
        Country(id: "JP", name: "Japan",        flag: "🇯🇵", difficulty: .medium),
        Country(id: "KR", name: "South Korea",  flag: "🇰🇷", difficulty: .medium),
        Country(id: "CH", name: "Switzerland",  flag: "🇨🇭", difficulty: .medium),
        Country(id: "DK", name: "Denmark",      flag: "🇩🇰", difficulty: .medium),
        Country(id: "SE", name: "Sweden",       flag: "🇸🇪", difficulty: .medium),
        Country(id: "NO", name: "Norway",       flag: "🇳🇴", difficulty: .medium),
        Country(id: "PL", name: "Poland",       flag: "🇵🇱", difficulty: .medium),
        Country(id: "RS", name: "Serbia",       flag: "🇷🇸", difficulty: .medium),
        Country(id: "AT", name: "Austria",      flag: "🇦🇹", difficulty: .medium),
        Country(id: "UA", name: "Ukraine",      flag: "🇺🇦", difficulty: .medium),
        Country(id: "SN", name: "Senegal",      flag: "🇸🇳", difficulty: .medium),
        Country(id: "NG", name: "Nigeria",      flag: "🇳🇬", difficulty: .medium),
        Country(id: "EG", name: "Egypt",        flag: "🇪🇬", difficulty: .medium),
        Country(id: "CL", name: "Chile",        flag: "🇨🇱", difficulty: .medium),
        Country(id: "EC", name: "Ecuador",      flag: "🇪🇨", difficulty: .medium),

        // Hard tier (14)
        Country(id: "BR", name: "Brazil",       flag: "🇧🇷", difficulty: .hard),
        Country(id: "AR", name: "Argentina",    flag: "🇦🇷", difficulty: .hard),
        Country(id: "FR", name: "France",       flag: "🇫🇷", difficulty: .hard),
        Country(id: "DE", name: "Germany",      flag: "🇩🇪", difficulty: .hard),
        Country(id: "ES", name: "Spain",        flag: "🇪🇸", difficulty: .hard),
        Country(id: "GB", name: "England",      flag: "🇬🇧", difficulty: .hard),
        Country(id: "IT", name: "Italy",        flag: "🇮🇹", difficulty: .hard),
        Country(id: "PT", name: "Portugal",     flag: "🇵🇹", difficulty: .hard),
        Country(id: "NL", name: "Netherlands",  flag: "🇳🇱", difficulty: .hard),
        Country(id: "BE", name: "Belgium",      flag: "🇧🇪", difficulty: .hard),
        Country(id: "HR", name: "Croatia",      flag: "🇭🇷", difficulty: .hard),
        Country(id: "UY", name: "Uruguay",      flag: "🇺🇾", difficulty: .hard),
        Country(id: "MA", name: "Morocco",      flag: "🇲🇦", difficulty: .hard),
        Country(id: "CO", name: "Colombia",     flag: "🇨🇴", difficulty: .hard)
    ]

    static func countries(in difficulty: Difficulty) -> [Country] {
        all.filter { $0.difficulty == difficulty }
    }

    static func find(id: String) -> Country? {
        all.first { $0.id == id }
    }

    /// UserDefaults key for the country the player represents.
    static let userCountryKey = "userCountryID"
}
