import SpriteKit
import UIKit

extension GameScene {
    func emitBurst(at point: CGPoint, color: UIColor, count: Int, speed: CGFloat, lifetime: CGFloat, scale: CGFloat) {
        let emitter = EmitterFactory.burst(color: color, count: count, speed: speed, lifetime: lifetime, scale: scale)
        emitter.position = point
        emitter.zPosition = 30
        fxLayer.addChild(emitter)
        emitter.run(.sequence([
            .wait(forDuration: TimeInterval(lifetime) * 1.5 + 0.3),
            .removeFromParent(),
        ]))
    }

    func popup(_ text: String, at point: CGPoint, color: UIColor, size fontSize: CGFloat) {
        let label = SKLabelNode()
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.rounded(fontSize, weight: .heavy),
            .foregroundColor: color,
        ])
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(
            x: point.x.clamped(to: 60...max(60, size.width - 60)),
            y: point.y
        )
        label.zPosition = 40
        label.setScale(0.4)
        label.alpha = 0
        fxLayer.addChild(label)

        label.run(.sequence([
            .group([.fadeIn(withDuration: 0.08), .scale(to: 1.15, duration: 0.12)]),
            .scale(to: 1, duration: 0.08),
            .group([
                .moveBy(x: 0, y: 46, duration: 0.55),
                .sequence([.wait(forDuration: 0.3), .fadeOut(withDuration: 0.25)]),
            ]),
            .removeFromParent(),
        ]))
    }

    func shockwave(at point: CGPoint, color: UIColor, scale: CGFloat = 3.5) {
        let ring = SKSpriteNode(texture: TextureFactory.ring, size: CGSize(width: 40, height: 40))
        ring.color = color
        ring.colorBlendFactor = 1
        ring.blendMode = .add
        ring.position = point
        ring.zPosition = 25
        ring.alpha = 0.9
        fxLayer.addChild(ring)
        let grow = SKAction.scale(to: scale, duration: 0.35)
        grow.timingMode = .easeOut
        ring.run(.sequence([
            .group([grow, .fadeOut(withDuration: 0.35)]),
            .removeFromParent(),
        ]))
    }

    func shake(_ amount: CGFloat, duration: TimeInterval = 0.35) {
        guard amount > 0 else { return }
        world.removeAction(forKey: "shake")
        let steps = 8
        var actions: [SKAction] = []
        for i in 0..<steps {
            let decay = 1 - CGFloat(i) / CGFloat(steps)
            let offset = CGPoint(
                x: CGFloat.random(in: -amount...amount) * decay,
                y: CGFloat.random(in: -amount...amount) * decay
            )
            actions.append(.move(to: offset, duration: duration / Double(steps)))
        }
        actions.append(.move(to: .zero, duration: 0.04))
        world.run(.sequence(actions), withKey: "shake")
    }

    func flash(color: UIColor, alpha: CGFloat) {
        flashNode.removeAllActions()
        flashNode.color = color
        flashNode.run(.sequence([
            .fadeAlpha(to: alpha, duration: 0.03),
            .fadeAlpha(to: 0, duration: 0.3),
        ]))
    }

    /// Breaks a row apart when the shield absorbs a hit.
    func shatter(_ row: RowNode) {
        row.isBroken = true
        let tint = UIColor(hex: config.theme.obstacle)
        for bar in row.bars {
            let frame = row.frame(of: bar)
            let pieces = max(2, Int(frame.width / 40))
            for i in 0..<pieces {
                let x = frame.minX + frame.width * (CGFloat(i) + 0.5) / CGFloat(pieces)
                emitBurst(at: CGPoint(x: x, y: frame.midY), color: tint, count: 8, speed: 160, lifetime: 0.5, scale: 0.25)
            }
            bar.run(.group([
                .fadeOut(withDuration: 0.2),
                .scaleY(to: 0.2, duration: 0.2),
            ]))
        }
    }
}
