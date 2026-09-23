import SpriteKit
import UIKit

final class SparkNode: SKSpriteNode {
    var collected = false

    init(tint: UIColor) {
        super.init(texture: TextureFactory.spark, color: tint, size: CGSize(width: 18, height: 18))
        colorBlendFactor = 0.5

        let glow = SKSpriteNode(texture: TextureFactory.glow, size: CGSize(width: 36, height: 36))
        glow.color = tint
        glow.colorBlendFactor = 1
        glow.alpha = 0.55
        glow.blendMode = .add
        glow.zPosition = -1
        addChild(glow)

        run(.repeatForever(.rotate(byAngle: .pi, duration: 1.4)))
        run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.45),
            .scale(to: 0.9, duration: 0.45),
        ])))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

final class PowerUpNode: SKSpriteNode {
    let kind: PowerUpKind
    var collected = false

    init(kind: PowerUpKind) {
        self.kind = kind
        super.init(texture: TextureFactory.powerUp(kind), color: .clear, size: CGSize(width: 44, height: 44))

        let glow = SKSpriteNode(texture: TextureFactory.glow, size: CGSize(width: 90, height: 90))
        glow.color = UIColor(hex: kind.color)
        glow.colorBlendFactor = 1
        glow.alpha = 0.5
        glow.blendMode = .add
        glow.zPosition = -1
        addChild(glow)
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.25, duration: 0.5),
            .fadeAlpha(to: 0.55, duration: 0.5),
        ])))

        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 6, duration: 0.5),
            .moveBy(x: 0, y: -6, duration: 0.5),
        ])))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
