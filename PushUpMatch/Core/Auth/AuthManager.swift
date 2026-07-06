import Foundation
import Combine

enum AuthProvider: String {
    case apple
    case google
}

/// Local account identity. There is no backend yet: the signed-in identity is
/// stored on-device and will later be linked to cloud sync (CloudKit/Firebase, phase 2).
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var userID: String?
    @Published private(set) var displayName: String?
    @Published private(set) var provider: AuthProvider?

    private let defaults = UserDefaults.standard

    private init() {
        userID      = defaults.string(forKey: "auth.userID")
        displayName = defaults.string(forKey: "auth.displayName")
        provider    = defaults.string(forKey: "auth.provider").flatMap(AuthProvider.init)
    }

    var isSignedIn: Bool { userID != nil }

    func signIn(provider: AuthProvider, userID: String, displayName: String?) {
        self.userID      = userID
        self.displayName = displayName
        self.provider    = provider
        defaults.set(userID, forKey: "auth.userID")
        defaults.set(displayName, forKey: "auth.displayName")
        defaults.set(provider.rawValue, forKey: "auth.provider")
    }

    func signOut() {
        userID = nil
        displayName = nil
        provider = nil
        defaults.removeObject(forKey: "auth.userID")
        defaults.removeObject(forKey: "auth.displayName")
        defaults.removeObject(forKey: "auth.provider")
    }
}
