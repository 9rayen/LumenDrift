import Combine
import Foundation

/// Single source of truth for saved progress. Every change is written to disk immediately,
/// so progress survives force-quits and relaunches. Fully offline.
final class ProgressStore: ObservableObject {
    @Published private(set) var progress: PlayerProgress {
        didSet { save() }
    }

    private let fileURL: URL

    init(fileName: String = "progress.json") {
        let fm = FileManager.default
        let directory = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent(fileName)

        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(PlayerProgress.self, from: data) {
            progress = saved
        } else {
            progress = PlayerProgress()
        }
    }

    // MARK: - Runs

    /// Records a finished run and returns everything the game-over screen needs.
    @discardableResult
    func record(_ run: RunResult) -> RunSummary {
        var p = progress
        let previousBest = p.bestScore
        let levelBefore = p.level
        let coins = LevelSystem.coins(for: run)
        let xp = LevelSystem.xp(for: run)

        p.totalGames += 1
        p.totalScore += run.score
        p.coins += coins
        p.xp += xp
        p.totalSparks += run.sparks
        p.totalNearMisses += run.nearMisses
        p.bestMultiplier = max(p.bestMultiplier, run.bestMultiplier)
        p.longestRun = max(p.longestRun, run.duration)

        let isNewBest = run.score > previousBest
        if isNewBest { p.bestScore = run.score }

        let unlocked = Self.awardAchievements(in: &p, run: run)
        progress = p

        return RunSummary(
            result: run,
            previousBest: previousBest,
            bestScore: p.bestScore,
            isNewBest: isNewBest,
            coinsEarned: coins,
            xpGained: xp,
            levelBefore: levelBefore,
            levelAfter: p.level,
            levelProgress: p.levelFraction,
            newAchievementIDs: unlocked.map(\.id)
        )
    }

    private static func awardAchievements(in p: inout PlayerProgress, run: RunResult?) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        for achievement in Achievement.all where !p.achievements.contains(achievement.id) {
            if achievement.check(AchievementContext(progress: p, run: run)) {
                p.achievements.insert(achievement.id)
                p.coins += achievement.reward
                newlyUnlocked.append(achievement)
            }
        }
        return newlyUnlocked
    }

    // MARK: - Cosmetics

    func state(of item: CosmeticItem) -> CosmeticState {
        let p = progress
        if p.selectedKey(for: item.category) == item.key { return .equipped }
        if p.isUnlocked(item) { return .owned }
        switch item.requirement {
        case .coins(let price): return .buyable(price: price, affordable: p.coins >= price)
        case .level(let level): return .locked(level: level)
        case .free: return .owned
        }
    }

    /// Buys and equips an item. Returns false if it can't be bought.
    @discardableResult
    func purchase(_ item: CosmeticItem) -> Bool {
        guard case .coins(let price) = item.requirement,
              !progress.isUnlocked(item),
              progress.coins >= price else { return false }
        var p = progress
        p.coins -= price
        p.unlocked.insert(item.id)
        p.select(item)
        _ = Self.awardAchievements(in: &p, run: nil)
        progress = p
        return true
    }

    func select(_ item: CosmeticItem) {
        guard progress.isUnlocked(item) else { return }
        var p = progress
        p.select(item)
        progress = p
    }

    // MARK: - Settings

    func updateSettings(_ change: (inout GameSettings) -> Void) {
        var p = progress
        change(&p.settings)
        progress = p
    }

    /// Wipes all progress but keeps audio/haptics preferences.
    func resetProgress() {
        var fresh = PlayerProgress()
        fresh.settings = progress.settings
        progress = fresh
    }

    // MARK: - Disk

    private func save() {
        do {
            let data = try JSONEncoder().encode(progress)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("ProgressStore save failed: \(error)")
            #endif
        }
    }
}
