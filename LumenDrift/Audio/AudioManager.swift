import AVFoundation

/// Plays bundled audio only — nothing is streamed. Missing files are skipped silently,
/// so the game still runs if you remove or rename an audio asset.
///
/// Sound effects run through `AVAudioEngine`: every effect is decoded once into memory and played by
/// scheduling a buffer on a pooled player node. Scheduling never blocks the main thread, which keeps the
/// game loop smooth when many sparks are collected in quick succession. Music uses `AVAudioPlayer`.
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
    private static let sampleRate: Double = 44_100
    private static let voiceCount = 12
    private let musicVolume: Float = 0.5

    // Sound effects
    private let engine = AVAudioEngine()
    private var sfxFormat: AVAudioFormat?
    private var voices: [AVAudioPlayerNode] = []
    private var nextVoice = 0
    /// Mono samples at `sampleRate`, decoded once at launch.
    private var samples: [SoundEffect: [Float]] = [:]
    /// Ready-to-play buffers per effect and pitch (pitch in hundredths).
    private var buffers: [SoundEffect: [Int: AVAudioPCMBuffer]] = [:]

    // Music
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
        try? session.setPreferredIOBufferDuration(0.01)
        try? session.setActive(true)

        setUpEffects()
    }

    // MARK: - Effects

    /// - Parameter rate: pitch/speed multiplier; >1 plays higher (used for rising combo sounds).
    func play(_ effect: SoundEffect, rate: Float = 1) {
        guard sfxEnabled, !voices.isEmpty,
              let buffer = buffer(for: effect, rate: rate),
              startEngineIfNeeded() else { return }

        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        voice.volume = effect.volume
        voice.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !voice.isPlaying { voice.play() }
    }

    private func setUpEffects() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 1) else { return }
        sfxFormat = format

        for effect in SoundEffect.allCases {
            guard let url = Self.url(for: effect.rawValue),
                  let decoded = Self.decodeMono(url: url, sampleRate: Self.sampleRate) else { continue }
            samples[effect] = decoded
        }

        // Only the input-free output path is used, so the microphone is never touched.
        let mixer = engine.mainMixerNode
        for _ in 0..<Self.voiceCount {
            let voice = AVAudioPlayerNode()
            engine.attach(voice)
            engine.connect(voice, to: mixer, format: format)
            voices.append(voice)
        }

        // Build every buffer the game can ask for up front, so no effect is prepared mid-game.
        for effect in SoundEffect.allCases {
            for pitch in effect.pitches {
                _ = buffer(for: effect, rate: pitch)
            }
        }

        engine.prepare()
        startEngineIfNeeded()
    }

    /// Restarts the engine after interruptions (calls, Siri, route changes). Returns false if it can't run.
    @discardableResult
    private func startEngineIfNeeded() -> Bool {
        if engine.isRunning { return true }
        do {
            try engine.start()
        } catch {
            return false
        }
        guard engine.isRunning else { return false }
        // Keep every voice running (silently) so the first sound on each one starts instantly;
        // starting a player node the first time costs several milliseconds.
        for voice in voices where !voice.isPlaying {
            voice.play()
        }
        return true
    }

    /// Returns a cached buffer for the effect at the requested pitch, resampling once if needed.
    private func buffer(for effect: SoundEffect, rate: Float) -> AVAudioPCMBuffer? {
        let pitch = Int((min(max(rate, 0.5), 2) * 100).rounded())
        if let cached = buffers[effect]?[pitch] { return cached }
        guard let format = sfxFormat, let source = samples[effect], !source.isEmpty else { return nil }

        let step = Double(pitch) / 100
        let frameCount = max(1, Int(Double(source.count) / step))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)),
              let output = buffer.floatChannelData?[0] else { return nil }

        let last = source.count - 1
        for i in 0..<frameCount {
            let position = Double(i) * step
            let index = min(Int(position), last)
            let next = min(index + 1, last)
            let fraction = Float(position - Double(index))
            output[i] = source[index] + (source[next] - source[index]) * fraction
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        buffers[effect, default: [:]][pitch] = buffer
        return buffer
    }

    /// Decodes any supported file to mono Float samples at the given sample rate.
    private static func decodeMono(url: URL, sampleRate: Double) -> [Float]? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let format = file.processingFormat
        let length = AVAudioFrameCount(file.length)
        guard length > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: length),
              (try? file.read(into: buffer)) != nil,
              let channels = buffer.floatChannelData else { return nil }

        let frames = Int(buffer.frameLength)
        let channelCount = Int(format.channelCount)
        guard frames > 0, channelCount > 0 else { return nil }

        var mono = [Float](repeating: 0, count: frames)
        for channel in 0..<channelCount {
            let data = channels[channel]
            for i in 0..<frames { mono[i] += data[i] }
        }
        if channelCount > 1 {
            let scale = 1 / Float(channelCount)
            for i in 0..<frames { mono[i] *= scale }
        }

        let ratio = format.sampleRate / sampleRate
        guard abs(ratio - 1) > 0.0001 else { return mono }

        let outputCount = max(1, Int(Double(frames) / ratio))
        var resampled = [Float](repeating: 0, count: outputCount)
        for i in 0..<outputCount {
            let position = Double(i) * ratio
            let index = min(Int(position), frames - 1)
            let next = min(index + 1, frames - 1)
            let fraction = Float(position - Double(index))
            resampled[i] = mono[index] + (mono[next] - mono[index]) * fraction
        }
        return resampled
    }

    #if DEBUG
    var debugStatus: String {
        let bufferCount = buffers.values.reduce(0) { $0 + $1.count }
        return "engine running=\(engine.isRunning) voices=\(voices.count) effects=\(samples.count) buffers=\(bufferCount)"
    }
    #endif

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
            startEngineIfNeeded()
            if musicEnabled, let track = desiredTrack {
                currentTrack = nil
                start(track)
            }
        } else {
            musicPlayers.values.forEach { $0.pause() }
            engine.pause()
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
