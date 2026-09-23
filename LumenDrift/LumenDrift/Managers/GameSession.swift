import Combine
import SpriteKit
import SwiftUI

/// Bridges the SpriteKit scene and the SwiftUI HUD/overlays for one visit to the game screen.
final class GameSession: ObservableObject {
    enum Phase: Equatable {
        case playing, paused, over
    }

    @Published private(set) var phase: Phase = .playing
    @Published var score = 0
    @Published var multiplier = 1
    @Published var activePowerUps: [ActivePowerUp] = []
    @Published private(set) var showHint: Bool
    @Published private(set) var summary: RunSummary? = nil
    @Published private(set) var bestScore: Int

    let scene: GameScene
    let theme: WorldTheme
    private let store: ProgressStore

    init(store: ProgressStore) {
        self.store = store
        let p = store.progress
        bestScore = p.bestScore
        showHint = p.totalGames < 3
        theme = Catalog.theme(p.selectedTheme)

        let config = GameConfig(
            skin: Catalog.skin(p.selectedSkin),
            trail: Catalog.trail(p.selectedTrail),
            theme: theme
        )
        scene = GameScene(size: CGSize(width: 390, height: 844), config: config)
        scene.session = self
    }

    var isNewBestLive: Bool { score > bestScore && bestScore > 0 }

    // MARK: - Controls

    func pause() {
        guard phase == .playing, scene.canPause else { return }
        phase = .paused
        scene.setGamePaused(true)
        AudioManager.shared.setDucked(true)
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .playing
        scene.setGamePaused(false)
        AudioManager.shared.setDucked(false)
    }

    func restart() {
        summary = nil
        score = 0
        multiplier = 1
        activePowerUps = []
        bestScore = store.progress.bestScore
        phase = .playing
        AudioManager.shared.setDucked(false)
        scene.setGamePaused(false)
        scene.startNewRun()
    }

    // MARK: - Scene callbacks

    func playerDidMove() {
        if showHint { showHint = false }
    }

    func sceneDidFinish(_ result: RunResult) {
        let summary = store.record(result)
        self.summary = summary
        phase = .over
        if summary.isNewBest && summary.previousBest > 0 {
            AudioManager.shared.play(.newBest)
            HapticsManager.shared.success()
        } else {
            AudioManager.shared.play(.gameOver)
        }
    }
}
