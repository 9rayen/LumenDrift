import Foundation

/// Sound effects. The raw value is the file name (without extension) in Resources/Audio.
/// Replace any file with your own .wav/.m4a/.mp3/.caf of the same name.
enum SoundEffect: String, CaseIterable {
    case button = "sfx_button"
    case spark = "sfx_spark"
    case combo = "sfx_combo"
    case nearMiss = "sfx_near_miss"
    case powerUp = "sfx_powerup"
    case shieldBreak = "sfx_shield_break"
    case hit = "sfx_hit"
    case gameOver = "sfx_game_over"
    case newBest = "sfx_new_best"
    case purchase = "sfx_purchase"

    var volume: Float {
        switch self {
        case .button: return 0.5
        case .spark: return 0.55
        case .hit: return 0.9
        default: return 0.75
        }
    }
}

extension SoundEffect {
    /// Spark chimes rise in pitch as the combo chain grows.
    static func sparkPitch(chain: Int) -> Float { 1 + Float(min(max(chain, 0), 12)) * 0.035 }

    /// The combo sting climbs with the multiplier.
    static func comboPitch(multiplier: Int) -> Float { 1 + Float(min(max(multiplier, 1), 8)) * 0.05 }

    /// Every pitch the game plays this effect at. All of them are rendered at launch,
    /// so nothing is resampled during a run.
    var pitches: [Float] {
        switch self {
        case .spark: return (0...12).map { Self.sparkPitch(chain: $0) }
        case .combo: return (1...8).map { Self.comboPitch(multiplier: $0) } + [1]
        case .button: return [1, 1.2]
        default: return [1]
        }
    }
}

/// Background music. Raw value is the file name in Resources/Audio.
enum MusicTrack: String {
    case menu = "music_menu"
    case gameplay = "music_gameplay"
}
