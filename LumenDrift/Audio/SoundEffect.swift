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

    /// How many copies can overlap.
    var voices: Int {
        switch self {
        case .spark: return 4
        case .nearMiss, .button: return 3
        default: return 2
        }
    }

    var volume: Float {
        switch self {
        case .button: return 0.5
        case .spark: return 0.55
        case .hit: return 0.9
        default: return 0.75
        }
    }
}

/// Background music. Raw value is the file name in Resources/Audio.
enum MusicTrack: String {
    case menu = "music_menu"
    case gameplay = "music_gameplay"
}
