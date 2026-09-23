import Foundation

struct AchievementContext {
    let progress: PlayerProgress
    let run: RunResult?
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let reward: Int
    let check: (AchievementContext) -> Bool

    static let all: [Achievement] = [
        Achievement(id: "first_drift", title: "First Drift", detail: "Finish your first run.",
                    icon: "flag.checkered", reward: 25) { $0.progress.totalGames >= 1 },
        Achievement(id: "score_500", title: "Warming Up", detail: "Score 500 in one run.",
                    icon: "flame.fill", reward: 50) { ($0.run?.score ?? 0) >= 500 },
        Achievement(id: "score_2500", title: "In the Zone", detail: "Score 2,500 in one run.",
                    icon: "bolt.fill", reward: 150) { ($0.run?.score ?? 0) >= 2_500 },
        Achievement(id: "score_10000", title: "Lightspeed", detail: "Score 10,000 in one run.",
                    icon: "sparkles", reward: 500) { ($0.run?.score ?? 0) >= 10_000 },
        Achievement(id: "combo_4", title: "Chain Reaction", detail: "Reach a x4 multiplier.",
                    icon: "link", reward: 75) { ($0.run?.bestMultiplier ?? 0) >= 4 },
        Achievement(id: "combo_8", title: "Overdrive", detail: "Reach the x8 multiplier.",
                    icon: "gauge.with.dots.needle.100percent", reward: 300) { ($0.run?.bestMultiplier ?? 0) >= 8 },
        Achievement(id: "near_10", title: "Thread the Needle", detail: "10 near-misses in one run.",
                    icon: "scope", reward: 120) { ($0.run?.nearMisses ?? 0) >= 10 },
        Achievement(id: "sparks_50", title: "Spark Hunter", detail: "Collect 50 sparks in one run.",
                    icon: "sparkle", reward: 100) { ($0.run?.sparks ?? 0) >= 50 },
        Achievement(id: "survive_60", title: "Minute Man", detail: "Survive for 60 seconds.",
                    icon: "timer", reward: 150) { ($0.run?.duration ?? 0) >= 60 },
        Achievement(id: "games_50", title: "Dedicated", detail: "Play 50 runs.",
                    icon: "repeat", reward: 200) { $0.progress.totalGames >= 50 },
        Achievement(id: "level_10", title: "Luminary", detail: "Reach player level 10.",
                    icon: "star.circle.fill", reward: 300) { $0.progress.level >= 10 },
        Achievement(id: "collector", title: "Collector", detail: "Own 10 cosmetics.",
                    icon: "paintpalette.fill", reward: 250) { Catalog.ownedCount($0.progress) >= 10 },
    ]
}
