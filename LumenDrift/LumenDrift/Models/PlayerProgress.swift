import Foundation

struct GameSettings: Codable, Equatable {
    var music = true
    var sfx = true
    var haptics = true
}

/// Everything the player has earned. Saved as JSON in Application Support.
struct PlayerProgress: Codable, Equatable {
    var bestScore = 0
    var totalGames = 0
    var totalScore = 0
    var coins = 0
    var xp = 0
    var totalSparks = 0
    var totalNearMisses = 0
    var bestMultiplier = 1
    var longestRun: Double = 0
    var unlocked: Set<String> = ["skin.nova", "trail.stream", "theme.abyss"]
    var selectedSkin = "nova"
    var selectedTrail = "stream"
    var selectedTheme = "abyss"
    var achievements: Set<String> = []
    var settings = GameSettings()

    var level: Int { LevelSystem.level(forXP: xp) }
    var levelFraction: Double { LevelSystem.fraction(forXP: xp) }

    func isUnlocked(_ item: CosmeticItem) -> Bool {
        switch item.requirement {
        case .free:
            return true
        case .level(let required):
            return level >= required || unlocked.contains(item.id)
        case .coins:
            return unlocked.contains(item.id)
        }
    }

    func selectedKey(for category: CosmeticCategory) -> String {
        switch category {
        case .skin: return selectedSkin
        case .trail: return selectedTrail
        case .theme: return selectedTheme
        }
    }

    mutating func select(_ item: CosmeticItem) {
        switch item.category {
        case .skin: selectedSkin = item.key
        case .trail: selectedTrail = item.key
        case .theme: selectedTheme = item.key
        }
    }
}

extension PlayerProgress {
    // Tolerant decoding: fields added in later versions fall back to defaults instead of wiping a save.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PlayerProgress()
        bestScore = try c.decodeIfPresent(Int.self, forKey: .bestScore) ?? d.bestScore
        totalGames = try c.decodeIfPresent(Int.self, forKey: .totalGames) ?? d.totalGames
        totalScore = try c.decodeIfPresent(Int.self, forKey: .totalScore) ?? d.totalScore
        coins = try c.decodeIfPresent(Int.self, forKey: .coins) ?? d.coins
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? d.xp
        totalSparks = try c.decodeIfPresent(Int.self, forKey: .totalSparks) ?? d.totalSparks
        totalNearMisses = try c.decodeIfPresent(Int.self, forKey: .totalNearMisses) ?? d.totalNearMisses
        bestMultiplier = try c.decodeIfPresent(Int.self, forKey: .bestMultiplier) ?? d.bestMultiplier
        longestRun = try c.decodeIfPresent(Double.self, forKey: .longestRun) ?? d.longestRun
        unlocked = try c.decodeIfPresent(Set<String>.self, forKey: .unlocked) ?? d.unlocked
        selectedSkin = try c.decodeIfPresent(String.self, forKey: .selectedSkin) ?? d.selectedSkin
        selectedTrail = try c.decodeIfPresent(String.self, forKey: .selectedTrail) ?? d.selectedTrail
        selectedTheme = try c.decodeIfPresent(String.self, forKey: .selectedTheme) ?? d.selectedTheme
        achievements = try c.decodeIfPresent(Set<String>.self, forKey: .achievements) ?? d.achievements
        settings = try c.decodeIfPresent(GameSettings.self, forKey: .settings) ?? d.settings
    }
}
