import CoreGraphics
import Foundation

/// Pure scoring and combo logic, independent of rendering.
struct ScoreKeeper {
    static let comboWindow: TimeInterval = 2.2
    static let sparkValue = 10
    static let nearMissValue = 25

    private(set) var score: Double = 0
    private(set) var chain = 0
    private(set) var comboTimer: TimeInterval = 0
    private(set) var bestMultiplier = 1
    private(set) var sparks = 0
    private(set) var nearMisses = 0

    /// x1 … x8, one step every 5 chained pickups.
    var multiplier: Int { min(8, 1 + chain / 5) }
    var displayScore: Int { Int(score) }
    /// 0…1, how much of the combo window is left.
    var comboFraction: Double { chain == 0 ? 0 : max(0, comboTimer / Self.comboWindow) }

    mutating func reset() { self = ScoreKeeper() }

    mutating func addDistance(_ distance: CGFloat, doubled: Bool) {
        score += Double(distance) / 40 * (doubled ? 2 : 1)
    }

    mutating func registerSpark(doubled: Bool) -> (points: Int, multiplierUp: Bool) {
        sparks += 1
        return chainPickup(base: Self.sparkValue, doubled: doubled)
    }

    mutating func registerNearMiss(doubled: Bool) -> (points: Int, multiplierUp: Bool) {
        nearMisses += 1
        return chainPickup(base: Self.nearMissValue, doubled: doubled)
    }

    /// Advances the combo timer. Returns true when a combo above x1 just broke.
    mutating func tick(_ dt: TimeInterval) -> Bool {
        guard chain > 0 else { return false }
        comboTimer -= dt
        guard comboTimer <= 0 else { return false }
        let hadMultiplier = multiplier > 1
        chain = 0
        comboTimer = 0
        return hadMultiplier
    }

    private mutating func chainPickup(base: Int, doubled: Bool) -> (points: Int, multiplierUp: Bool) {
        let before = multiplier
        chain += 1
        comboTimer = Self.comboWindow
        let points = base * multiplier * (doubled ? 2 : 1)
        score += Double(points)
        bestMultiplier = max(bestMultiplier, multiplier)
        return (points, multiplier > before)
    }
}
