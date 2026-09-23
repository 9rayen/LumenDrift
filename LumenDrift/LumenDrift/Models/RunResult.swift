import Foundation

/// Raw statistics for a single run, produced by the game scene.
struct RunResult: Equatable {
    var score: Int
    var sparks: Int
    var nearMisses: Int
    var bestMultiplier: Int
    var duration: TimeInterval
    var powerUps: Int
}

/// What the game-over screen shows after the run was recorded.
struct RunSummary: Equatable {
    let result: RunResult
    let previousBest: Int
    let bestScore: Int
    let isNewBest: Bool
    let coinsEarned: Int
    let xpGained: Int
    let levelBefore: Int
    let levelAfter: Int
    let levelProgress: Double
    let newAchievementIDs: [String]

    var leveledUp: Bool { levelAfter > levelBefore }
    var newAchievements: [Achievement] {
        newAchievementIDs.compactMap { id in Achievement.all.first { $0.id == id } }
    }
}
