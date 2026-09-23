import SpriteKit
import UIKit

final class PlayerNode: SKNode {
    let radius: CGFloat

    private let body = SKNode()
    private let core: SKSpriteNode
    private let halo: SKSpriteNode
    private let shieldRing: SKSpriteNode
    private let magnetRing: SKSpriteNode

    init(skin: OrbSkin, radius: CGFloat) {
        self.radius = radius
        core = SKSpriteNode(texture: TextureFactory.orb(skin), size: CGSize(width: radius * 2.4, height: radius * 2.4))
        halo = SKSpriteNode(texture: TextureFactory.glow, size: CGSize(width: radius * 6, height: radius * 6))
        shieldRing = SKSpriteNode(texture: TextureFactory.ring, size: CGSize(width: radius * 3.6, height: radius * 3.6))
        magnetRing = SKSpriteNode(texture: TextureFactory.dashedRing, size: CGSize(width: radius * 5.5, height: radius * 5.5))
        super.init()

        halo.color = UIColor(hex: skin.glow)
        halo.colorBlendFactor = 1
        halo.blendMode = .add
        halo.alpha = 0.55
        halo.zPosition = -1

        shieldRing.color = UIColor(hex: PowerUpKind.shield.color)
        shieldRing.colorBlendFactor = 1
        shieldRing.blendMode = .add
        shieldRing.alpha = 0
        shieldRing.zPosition = 2

        magnetRing.color = UIColor(hex: PowerUpKind.magnet.color)
        magnetRing.colorBlendFactor = 1
        magnetRing.alpha = 0
        magnetRing.zPosition = 1

        addChild(halo)
        addChild(body)
        body.addChild(core)
        addChild(shieldRing)
        addChild(magnetRing)

        halo.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.7),
            .scale(to: 0.95, duration: 0.7),
        ])))
        magnetRing.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 3)))
        if skin.shape != .circle {
            core.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 6)))
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Tilts and stretches the orb in the direction of travel.
    func lean(velocity: CGFloat) {
        body.zRotation = (-velocity * 0.0007).clamped(to: -0.35...0.35)
        let stretch = min(abs(velocity) * 0.00025, 0.18)
        body.xScale = 1 + stretch
        body.yScale = 1 - stretch * 0.6
    }

    func pop() {
        core.removeAction(forKey: "pop")
        core.run(.sequence([
            .scale(to: 1.3, duration: 0.06),
            .scale(to: 1, duration: 0.14),
        ]), withKey: "pop")
    }

    func setShield(_ on: Bool) {
        toggle(shieldRing, on: on, targetAlpha: 0.9)
    }

    func setMagnet(_ on: Bool) {
        toggle(magnetRing, on: on, targetAlpha: 0.5)
    }

    func explode() {
        run(.group([
            .scale(to: 1.8, duration: 0.12),
            .fadeOut(withDuration: 0.12),
        ]))
    }

    private func toggle(_ ring: SKSpriteNode, on: Bool, targetAlpha: CGFloat) {
        ring.removeAction(forKey: "toggle")
        if on {
            ring.setScale(0.5)
            ring.run(.sequence([
                .group([.fadeAlpha(to: targetAlpha, duration: 0.15), .scale(to: 1, duration: 0.2)]),
                .repeatForever(.sequence([
                    .fadeAlpha(to: targetAlpha * 0.55, duration: 0.5),
                    .fadeAlpha(to: targetAlpha, duration: 0.5),
                ])),
            ]), withKey: "toggle")
        } else {
            ring.run(.group([.fadeOut(withDuration: 0.2), .scale(to: 1.6, duration: 0.2)]), withKey: "toggle")
        }
    }
}
