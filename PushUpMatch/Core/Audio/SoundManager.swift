import AVFoundation

/// Plays the bundled synthesized sound effects. Respects the "soundEnabled"
/// setting (defaults to on when the user never touched Settings).
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        // Playback (not ambient): effects stay audible even when the ringer
        // switch is on silent; mixWithOthers keeps the user's music running.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private var isEnabled: Bool {
        (UserDefaults.standard.object(forKey: "soundEnabled") as? Bool) ?? true
    }

    func play(_ name: String, volume: Float = 1.0) {
        guard isEnabled else { return }

        if let player = players[name] {
            player.currentTime = 0
            player.volume = volume
            player.play()
            return
        }

        guard
            let url = Bundle.main.url(forResource: name, withExtension: "wav"),
            let player = try? AVAudioPlayer(contentsOf: url)
        else { return }

        player.volume = volume
        player.prepareToPlay()
        players[name] = player
        player.play()
    }
}
