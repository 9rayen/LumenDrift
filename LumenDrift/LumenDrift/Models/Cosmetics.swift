import CoreGraphics
import Foundation

enum CosmeticCategory: String, CaseIterable, Identifiable {
    case skin, trail, theme

    var id: String { rawValue }

    var title: String {
        switch self {
        case .skin: return "Orbs"
        case .trail: return "Trails"
        case .theme: return "Worlds"
        }
    }

    var symbol: String {
        switch self {
        case .skin: return "circle.hexagongrid.fill"
        case .trail: return "wind"
        case .theme: return "sparkles.rectangle.stack.fill"
        }
    }
}

enum UnlockRequirement: Hashable {
    case free
    case coins(Int)
    case level(Int)
}

/// The shape used to draw the player orb, both in SpriteKit and SwiftUI.
/// `nonisolated` so SwiftUI's `Shape.path(in:)` can call it from any context.
nonisolated enum OrbShape: Hashable {
    case circle, diamond, hexagon, ring, star

    func cgPath(in rect: CGRect) -> CGPath {
        switch self {
        case .circle, .ring:
            return CGPath(ellipseIn: rect, transform: nil)
        case .diamond:
            return Self.polygon(in: rect, sides: 4, rotation: 0)
        case .hexagon:
            return Self.polygon(in: rect, sides: 6, rotation: 0)
        case .star:
            return Self.star(in: rect, points: 5, innerRatio: 0.5)
        }
    }

    private static func polygon(in rect: CGRect, sides: Int, rotation: CGFloat) -> CGPath {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let path = CGMutablePath()
        for i in 0..<sides {
            let angle = rotation + CGFloat(i) * 2 * .pi / CGFloat(sides) - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private static func star(in rect: CGRect, points: Int, innerRatio: CGFloat) -> CGPath {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        let path = CGMutablePath()
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct OrbSkin: Identifiable, Hashable {
    let id: String
    let name: String
    let core: UInt32
    let glow: UInt32
    let shape: OrbShape
    let requirement: UnlockRequirement
}

enum TrailParticle: Hashable {
    case glow, spark, pixel
}

struct TrailStyle: Identifiable, Hashable {
    let id: String
    let name: String
    /// Colors over the particle lifetime. Empty means "use the orb's glow color".
    let colors: [UInt32]
    let particle: TrailParticle
    let birthRate: CGFloat
    let lifetime: CGFloat
    let scale: CGFloat
    let spread: CGFloat
    let requirement: UnlockRequirement
}

struct WorldTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let top: UInt32
    let bottom: UInt32
    let obstacle: UInt32
    let accent: UInt32
    let requirement: UnlockRequirement
}

/// A category-agnostic view of any unlockable, used by the shop UI and persistence.
struct CosmeticItem: Identifiable, Hashable {
    let category: CosmeticCategory
    let key: String
    let name: String
    let requirement: UnlockRequirement

    /// Globally unique id, e.g. "skin.nova".
    var id: String { "\(category.rawValue).\(key)" }
}

enum CosmeticState: Equatable {
    case equipped
    case owned
    case buyable(price: Int, affordable: Bool)
    case locked(level: Int)
}
