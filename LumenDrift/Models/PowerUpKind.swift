import Foundation

enum PowerUpKind: String, CaseIterable, Identifiable {
    case shield, magnet, slowMo, double

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shield: return "Shield"
        case .magnet: return "Magnet"
        case .slowMo: return "Slow-Mo"
        case .double: return "Double"
        }
    }

    var symbol: String {
        switch self {
        case .shield: return "shield.fill"
        case .magnet: return "arrow.down.right.and.arrow.up.left"
        case .slowMo: return "tortoise.fill"
        case .double: return "multiply.circle.fill"
        }
    }

    var color: UInt32 {
        switch self {
        case .shield: return 0x4DF3FF
        case .magnet: return 0xFF4D9D
        case .slowMo: return 0x9D8CFF
        case .double: return 0xFFD24D
        }
    }

    /// Seconds the power-up stays active. The shield also ends when it absorbs a hit.
    var duration: TimeInterval {
        switch self {
        case .shield: return 10
        case .magnet: return 7
        case .slowMo: return 5
        case .double: return 8
        }
    }
}

struct ActivePowerUp: Identifiable, Equatable {
    let kind: PowerUpKind
    let remaining: Double

    var id: String { kind.rawValue }
    var fraction: Double { max(0, min(1, remaining / kind.duration)) }
}
