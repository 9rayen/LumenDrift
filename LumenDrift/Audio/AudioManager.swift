import AVFoundation

/// Plays bundled audio only — nothing is streamed. Missing files are skipped silently,
/// so the game still runs if you remove or rename an audio asset.
final class AudioManager {
    static let shared = AudioManager()

    var sfxEnabled = true

    var musicEnabled = true {
        didSet {
            guard musicEnabled != oldValue else { return }
            if musicEnabled, let track = desiredTrack {
                start(track)
            } else if !musicEnabled {
                stopMusic()
            }
        }
    }

    private static let supportedExtensions = ["m4a", "mp3", "caf", "wav", "aiff"]
    private let musicVolume: Float = 0.5

    private var pools: [SoundEffect: [AVAudioPlayer]] = [:]
    private var nextVoice: [SoundEffect: Int] = [:]
    private var musicPlayers: [MusicTrack: AVAudioPlayer] = [:]
    private var desiredTrack: MusicTrack?
    private var currentTrack: MusicTrack?
    private var isConfigured = false

    private init() {}

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true

        // .ambient respects the silent switch and mixes with the player's own music.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        for effect in SoundEffect.allCases {
            guard let url = Self.url(for: effect.rawValue) else { continue }
            let players: [AVAudioPlayer] = (0..<effect.voices).compactMap { _ in
                guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
                player.enableRate = true
                player.volume = effect.volume
                player.prepareToPlay()
                return player
            }
            pools[effect] = players
        }
    }

    // MARK: - Effects

    /// - Parameter rate: playback speed; >1 raises the pitch (used for rising combo sounds).
    func play(_ effect: SoundEffect, rate: Float = 1) {
        guard sfxEnabled, let pool = pools[effect], !pool.isEmpty else { return }
        let index = nextVoice[effect, default: 0]
        nextVoice[effect] = (index + 1) % pool.count
        let player = pool[index]
        player.currentTime = 0
        player.rate = rate
        player.play()
    }

    // MARK: - Music

    func playMusic(_ track: MusicTrack) {
        desiredTrack = track
        guard musicEnabled else { return }
        start(track)
    }

    /// Lowers music while paused.
    func setDucked(_ ducked: Bool) {
        guard let track = currentTrack, let player = musicPlayers[track] else { return }
        player.setVolume(ducked ? musicVolume * 0.3 : musicVolume, fadeDuration: 0.25)
    }

    func handleAppActive(_ active: Bool) {
        if active {
            if musicEnabled, let track = desiredTrack {
                currentTrack = nil
                start(track)
            }
        } else {
            musicPlayers.values.forEach { $0.pause() }
        }
    }

    private func start(_ track: MusicTrack) {
        if currentTrack == track, let player = musicPlayers[track], player.isPlaying { return }

        for (other, player) in musicPlayers where other != track {
            player.stop()
        }
        guard let player = musicPlayer(for: track) else {
            currentTrack = nil
            return
        }
        player.volume = 0
        player.play()
        player.setVolume(musicVolume, fadeDuration: 0.8)
        currentTrack = track
    }

    private func stopMusic() {
        musicPlayers.values.forEach { $0.stop() }
        currentTrack = nil
    }

    private func musicPlayer(for track: MusicTrack) -> AVAudioPlayer? {
        if let existing = musicPlayers[track] { return existing }
        guard let url = Self.url(for: track.rawValue),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.numberOfLoops = -1
        player.prepareToPlay()
        musicPlayers[track] = player
        return player
    }

    private static func url(for name: String) -> URL? {
        for ext in supportedExtensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
        }
        return nil
    }
}
