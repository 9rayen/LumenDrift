import SpriteKit
import UIKit

/// One solid obstacle segment. `barSize` is the collision size; the sprite is larger to fit the glow.
final class BarNode: SKSpriteNode {
    let barSize: CGSize

    init(barSize: CGSize, tint: UInt32) {
        self.barSize = barSize
        let pad = TextureFactory.barPadding
        super.init(
            texture: TextureFactory.bar(size: barSize, color: tint),
            color: .clear,
            size: CGSize(width: barSize.width + pad * 2, height: barSize.height + pad * 2)
        )
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
