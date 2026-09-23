import SpriteKit
import UIKit

/// The gameplay scene. Owns the simulation; reports state to `GameSession` for the SwiftUI HUD.
final class GameScene: SKScene {
    enum RunState {
        case idle, running, dying, over
    }

    static let barHeight: CGFloat = 22
    static let nearMissThreshold: CGFloat = 14
    static let dragSensitivity: CGFloat = 1.35
    /// Seconds between the crash and the game-over screen.
    static let deathDelay: TimeInterval = 1.0

    weak var session: GameSession?
    let config: GameConfig
    let playerRadius: CGFloat = 15

    // Layers
    let backdrop: BackdropNode
    let world = SKNode()
    let playfield = SKNode()
    let fxLayer = SKNode()
    let slowMoOverlay = SKSpriteNode(color: UIColor(hex: PowerUpKind.slowMo.color), size: .zero)
    let flashNode = SKSpriteNode(color: .white, size: .zero)
    var player: PlayerNode?
    var trail: SKEmitterNode?

    // Run state
    var runState: RunState = .idle
    private(set) var isGamePaused = false
    var elapsed: TimeInterval = 0
    var deathElapsed: TimeInterval = 0
    var currentSpeed: CGFloat = DifficultyCurve.baseSpeed
    var distanceSinceRow: CGFloat = 0
    var nextRowSpacing: CGFloat = 0
    var rows: [RowNode] = []
    var keeper = ScoreKeeper()
    var powerUps: [PowerUpKind: TimeInterval] = [:]
    var powerUpsCollected = 0
    var rowsSincePowerUp = 0
    var lastPattern: RowPattern?
    var invulnerable: TimeInterval = 0

    // Input
    var targetX: CGFloat = 0
    private var lastTouchX: CGFloat?
    private var hasMoved = false

    // Frame timing / publishing
    private var lastUpdateTime: TimeInterval = 0
    private var publishedScore = -1
    private var publishedMultiplier = -1
    private var publishedPowerUps: [ActivePowerUp] = []
    private var isBuilt = false

    init(size: CGSize, config: GameConfig) {
        self.config = config
        backdrop = BackdropNode(theme: config.theme)
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = UIColor(hex: config.theme.bottom)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = false
        buildIfNeeded()
        if runState == .idle {
            startNewRun()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutForSize()
    }

    private func buildIfNeeded() {
        guard !isBuilt else { return }
        isBuilt = true

        backdrop.zPosition = -100
        addChild(backdrop)

        world.zPosition = 0
        addChild(world)
        playfield.zPosition = 10
        world.addChild(playfield)
        fxLayer.zPosition = 30
        world.addChild(fxLayer)

        slowMoOverlay.anchorPoint = .zero
        slowMoOverlay.alpha = 0
        slowMoOverlay.blendMode = .add
        slowMoOverlay.zPosition = 90
        addChild(slowMoOverlay)

        flashNode.anchorPoint = .zero
        flashNode.alpha = 0
        flashNode.zPosition = 100
        addChild(flashNode)

        layoutForSize()
    }

    private func layoutForSize() {
        guard size.width > 0, size.height > 0 else { return }
        backdrop.layout(size: size)
        slowMoOverlay.size = size
        flashNode.size = size
        if let player {
            player.position.y = playerBaseY
            targetX = targetX.clamped(to: horizontalRange)
            player.position.x = player.position.x.clamped(to: horizontalRange)
        }
    }

    var playerBaseY: CGFloat {
        let bottomInset = view?.safeAreaInsets.bottom ?? 0
        return max(size.height * 0.26, bottomInset + 150)
    }

    var horizontalRange: ClosedRange<CGFloat> {
        let margin = playerRadius + 8
        return margin...max(margin, size.width - margin)
    }

    var canPause: Bool { runState == .running }

    // MARK: - Run control

    func startNewRun() {
        buildIfNeeded()
        hasMoved = false

        rows.forEach { $0.removeFromParent() }
        rows.removeAll()
        fxLayer.removeAllChildren()
        world.removeAllActions()
        world.position = .zero
        world.isPaused = false
        backdrop.isPaused = false
        slowMoOverlay.removeAllActions()
        slowMoOverlay.alpha = 0

        keeper.reset()
        powerUps.removeAll()
        powerUpsCollected = 0
        rowsSincePowerUp = 0
        lastPattern = nil
        invulnerable = 0
        elapsed = 0
        deathElapsed = 0
        currentSpeed = DifficultyCurve.baseSpeed
        nextRowSpacing = DifficultyCurve.rowSpacing(at: 0)
        distanceSinceRow = nextRowSpacing // first row spawns immediately at the top edge
        publishedScore = -1
        publishedMultiplier = -1
        publishedPowerUps = []
        lastTouchX = nil
        isGamePaused = false

        player?.removeFromParent()
        trail?.removeFromParent()

        let orb = PlayerNode(skin: config.skin, radius: playerRadius)
        orb.position = CGPoint(x: size.width / 2, y: playerBaseY)
        orb.zPosition = 20
        playfield.addChild(orb)
        player = orb
        targetX = orb.position.x

        let emitter = EmitterFactory.trail(config.trail, fallbackColor: config.skin.glow, radius: playerRadius)
        emitter.position = orb.position
        emitter.zPosition = 15
        emitter.targetNode = playfield
        playfield.addChild(emitter)
        trail = emitter

        // Entry animation: orb drops in.
        orb.setScale(0.2)
        orb.alpha = 0
        orb.run(.group([.fadeIn(withDuration: 0.2), .scale(to: 1, duration: 0.25)]))

        runState = .running
        HapticsManager.shared.prepare()
        publish(force: true)
    }

    func setGamePaused(_ paused: Bool) {
        isGamePaused = paused
        world.isPaused = paused
        backdrop.isPaused = paused
        lastTouchX = nil
    }

    // MARK: - Frame loop

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard lastUpdateTime > 0 else { return }
        let dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        guard !isGamePaused else { return }

        switch runState {
        case .running:
            step(dt)
        case .dying:
            stepDying(dt)
        case .idle, .over:
            backdrop.advance(dt: dt, speed: DifficultyCurve.baseSpeed * 0.3)
        }
    }

    private func step(_ dt: TimeInterval) {
        guard let player else { return }
        let slowed = powerUps[.slowMo] != nil
        let worldDt = dt * (slowed ? 0.55 : 1)
        elapsed += worldDt
        currentSpeed = DifficultyCurve.speed(at: elapsed)
        let travel = currentSpeed * CGFloat(worldDt)

        // Player follows the finger in real time (not slowed).
        let oldX = player.position.x
        let follow = min(1, CGFloat(dt) * 22)
        player.position.x += (targetX - player.position.x) * follow
        player.lean(velocity: (player.position.x - oldX) / CGFloat(max(dt, 0.001)))
        if let trail {
            trail.position = player.position
            trail.particleSpeed = currentSpeed * (slowed ? 0.55 : 1) * 0.9
        }

        backdrop.advance(dt: worldDt, speed: currentSpeed)

        for row in rows {
            row.position.y -= travel
            row.advance(dt: worldDt)
        }

        distanceSinceRow += travel
        if distanceSinceRow >= nextRowSpacing {
            distanceSinceRow -= nextRowSpacing
            spawnRow()
            nextRowSpacing = DifficultyCurve.rowSpacing(at: elapsed)
        }

        keeper.addDistance(travel, doubled: powerUps[.double] != nil)
        if keeper.tick(worldDt) {
            comboBroken()
        }
        tickPowerUps(dt)
        invulnerable = max(0, invulnerable - dt)

        collectPickups(dt: dt, player: player)
        checkCollisions(player: player)
        cullRows()
        publish()
    }

    private func stepDying(_ dt: TimeInterval) {
        deathElapsed += dt
        let factor = CGFloat(max(0, 1 - deathElapsed * 2.2))
        let travel = currentSpeed * factor * CGFloat(dt)
        for row in rows { row.position.y -= travel }
        backdrop.advance(dt: dt, speed: currentSpeed * factor)
        if deathElapsed >= Self.deathDelay {
            finishRun()
        }
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastTouchX = touch.location(in: self).x
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard runState == .running, !isGamePaused,
              let touch = touches.first, let last = lastTouchX else { return }
        let x = touch.location(in: self).x
        let dx = x - last
        lastTouchX = x
        targetX = (targetX + dx * Self.dragSensitivity).clamped(to: horizontalRange)
        if !hasMoved && abs(dx) > 2 {
            hasMoved = true
            session?.playerDidMove()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchX = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchX = nil
    }

    // MARK: - Collisions & pickups

    private func checkCollisions(player: PlayerNode) {
        let p = player.position
        let hitRadius = playerRadius * 0.82

        for row in rows where !row.isBroken {
            let verticalGap = abs(row.position.y - p.y)
            if verticalGap < row.barHeight / 2 + playerRadius + 60 {
                for bar in row.bars {
                    let d = row.frame(of: bar).distance(to: p)
                    row.nearestGap = min(row.nearestGap, d - playerRadius)
                    if d < hitRadius {
                        handleHit(row: row)
                        return
                    }
                }
            }
            if !row.resolved && row.position.y + row.barHeight / 2 < p.y - playerRadius {
                row.resolved = true
                if row.nearestGap < Self.nearMissThreshold {
                    nearMiss(row: row, player: player)
                }
            }
        }
    }

    private func collectPickups(dt: TimeInterval, player: PlayerNode) {
        let p = player.position
        let magnet = powerUps[.magnet] != nil
        let doubled = powerUps[.double] != nil

        for row in rows {
            for spark in row.sparks where !spark.collected {
                var sp = row.parentPosition(of: spark)
                if magnet {
                    let d = sp.distance(to: p)
                    if d < 200 {
                        let pull = min(1, CGFloat(dt) * 10)
                        spark.position.x += (p.x - sp.x) * pull
                        spark.position.y += (p.y - sp.y) * pull
                        sp = row.parentPosition(of: spark)
                    }
                }
                if sp.distance(to: p) < playerRadius + 14 {
                    collect(spark: spark, at: sp, doubled: doubled)
                }
            }
            for node in row.powerUps where !node.collected {
                let pp = row.parentPosition(of: node)
                if pp.distance(to: p) < playerRadius + 22 {
                    activate(node, at: pp)
                }
            }
        }
    }

    private func collect(spark: SparkNode, at point: CGPoint, doubled: Bool) {
        spark.collected = true
        spark.removeAllActions()
        spark.run(.sequence([
            .group([.scale(to: 2, duration: 0.15), .fadeOut(withDuration: 0.15)]),
            .removeFromParent(),
        ]))

        let result = keeper.registerSpark(doubled: doubled)
        let tint = UIColor(hex: config.theme.accent)
        emitBurst(at: point, color: tint, count: 10, speed: 120, lifetime: 0.35, scale: 0.2)
        popup("+\(result.points)", at: CGPoint(x: point.x, y: point.y + 18), color: tint, size: 15)
        player?.pop()

        let pitch = 1 + Float(min(keeper.chain, 12)) * 0.035
        AudioManager.shared.play(.spark, rate: pitch)
        HapticsManager.shared.spark()

        if result.multiplierUp { multiplierIncreased() }
    }

    private func nearMiss(row: RowNode, player: PlayerNode) {
        let result = keeper.registerNearMiss(doubled: powerUps[.double] != nil)
        let color = UIColor.white
        popup("CLOSE +\(result.points)", at: CGPoint(x: player.position.x, y: player.position.y + 44), color: color, size: 16)
        emitBurst(at: player.position, color: UIColor(hex: config.skin.glow), count: 14, speed: 180, lifetime: 0.3, scale: 0.18)
        AudioManager.shared.play(.nearMiss)
        HapticsManager.shared.nearMiss()
        if result.multiplierUp { multiplierIncreased() }
    }

    private func multiplierIncreased() {
        let m = keeper.multiplier
        let tint = UIColor(hex: config.theme.accent)
        popup("COMBO x\(m)", at: CGPoint(x: size.width / 2, y: size.height * 0.62), color: tint, size: 30)
        shockwave(at: player?.position ?? .zero, color: tint)
        AudioManager.shared.play(.combo, rate: 1 + Float(m) * 0.05)
        HapticsManager.shared.combo()
    }

    private func comboBroken() {
        guard let player else { return }
        popup("combo lost", at: CGPoint(x: player.position.x, y: player.position.y + 50),
              color: UIColor.white.withAlphaComponent(0.6), size: 13)
    }

    private func handleHit(row: RowNode) {
        guard invulnerable <= 0 else { return }

        if powerUps[.shield] != nil {
            powerUps[.shield] = nil
            player?.setShield(false)
            invulnerable = 0.8
            shatter(row)
            shake(8)
            flash(color: UIColor(hex: PowerUpKind.shield.color), alpha: 0.25)
            AudioManager.shared.play(.shieldBreak)
            HapticsManager.shared.shieldBreak()
            return
        }
        die()
    }

    private func activate(_ node: PowerUpNode, at point: CGPoint) {
        node.collected = true
        node.removeAllActions()
        node.run(.sequence([
            .group([.scale(to: 2.2, duration: 0.2), .fadeOut(withDuration: 0.2)]),
            .removeFromParent(),
        ]))

        let kind = node.kind
        let tint = UIColor(hex: kind.color)
        powerUps[kind] = kind.duration
        powerUpsCollected += 1

        switch kind {
        case .shield: player?.setShield(true)
        case .magnet: player?.setMagnet(true)
        case .slowMo:
            slowMoOverlay.removeAllActions()
            slowMoOverlay.run(.fadeAlpha(to: 0.1, duration: 0.25))
        case .double: break
        }

        emitBurst(at: point, color: tint, count: 30, speed: 220, lifetime: 0.5, scale: 0.3)
        shockwave(at: point, color: tint)
        popup(kind.title.uppercased(), at: CGPoint(x: size.width / 2, y: size.height * 0.55), color: tint, size: 26)
        AudioManager.shared.play(.powerUp)
        HapticsManager.shared.powerUp()
    }

    private func tickPowerUps(_ dt: TimeInterval) {
        for (kind, remaining) in powerUps {
            let next = remaining - dt
            if next <= 0 {
                powerUps[kind] = nil
                deactivate(kind)
            } else {
                powerUps[kind] = next
            }
        }
    }

    private func deactivate(_ kind: PowerUpKind) {
        switch kind {
        case .shield: player?.setShield(false)
        case .magnet: player?.setMagnet(false)
        case .slowMo:
            slowMoOverlay.removeAllActions()
            slowMoOverlay.run(.fadeOut(withDuration: 0.3))
        case .double: break
        }
    }

    private func cullRows() {
        while let first = rows.first, first.position.y + first.topExtent < -80 {
            first.removeFromParent()
            rows.removeFirst()
        }
    }

    // MARK: - Death

    private func die() {
        guard let player else { return }
        runState = .dying
        deathElapsed = 0
        trail?.particleBirthRate = 0

        let p = player.position
        let color = UIColor(hex: config.skin.glow)
        emitBurst(at: p, color: color, count: 70, speed: 340, lifetime: 0.9, scale: 0.45)
        emitBurst(at: p, color: .white, count: 24, speed: 160, lifetime: 0.5, scale: 0.3)
        shockwave(at: p, color: color, scale: 6)
        player.explode()
        shake(16, duration: 0.5)
        flash(color: color, alpha: 0.35)

        AudioManager.shared.play(.hit)
        HapticsManager.shared.crash()

    }

    private func finishRun() {
        guard runState == .dying else { return }
        runState = .over
        publish(force: true)
        let result = RunResult(
            score: keeper.displayScore,
            sparks: keeper.sparks,
            nearMisses: keeper.nearMisses,
            bestMultiplier: keeper.bestMultiplier,
            duration: elapsed,
            powerUps: powerUpsCollected
        )
        session?.sceneDidFinish(result)
    }

    // MARK: - HUD publishing

    private func publish(force: Bool = false) {
        guard let session else { return }
        let score = keeper.displayScore
        if force || score != publishedScore {
            publishedScore = score
            session.score = score
        }
        let multiplier = keeper.multiplier
        if force || multiplier != publishedMultiplier {
            publishedMultiplier = multiplier
            session.multiplier = multiplier
        }
        // Quantized so SwiftUI only re-renders ~20 times per second for power-up rings.
        let active = PowerUpKind.allCases.compactMap { kind -> ActivePowerUp? in
            guard let remaining = powerUps[kind] else { return nil }
            return ActivePowerUp(kind: kind, remaining: (remaining * 20).rounded(.up) / 20)
        }
        if force || active != publishedPowerUps {
            publishedPowerUps = active
            session.activePowerUps = active
        }
    }
}
