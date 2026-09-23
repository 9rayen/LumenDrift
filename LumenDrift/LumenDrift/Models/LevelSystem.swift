import Foundation

enum LevelSystem {
    /// XP needed to go from `level` to `level + 1`.
    static func xpToAdvance(from level: Int) -> Int {
        250 + (level - 1) * 125
    }

    static func level(forXP xp: Int) -> Int {
        breakdown(forXP: xp).level
    }

    /// Current level, XP earned inside that level, and XP needed for the next one.
    static func breakdown(forXP xp: Int) -> (level: Int, current: Int, needed: Int) {
        var level = 1
        var remaining = max(0, xp)
        while remaining >= xpToAdvance(from: level) {
            remaining -= xpToAdvance(from: level)
            level += 1
        }
        return (level, remaining, xpToAdvance(from: level))
    }

    static func fraction(forXP xp: Int) -> Double {
        let b = breakdown(forXP: xp)
        return Double(b.current) / Double(b.needed)
    }

    /// XP granted for a finished run.
    static func xp(for run: RunResult) -> Int {
        max(10, run.score / 4 + run.nearMisses * 2)
    }

    /// Coins (sparks) granted for a finished run.
    static func coins(for run: RunResult) -> Int {
        run.sparks + run.score / 100
    }
}
