import SpriteKit
import UIKit

/// Themed gradient, scrolling grid, side rails and parallax dust.
final class BackdropNode: SKNode {
    private let theme: WorldTheme
    private let gradient: SKSpriteNode
    private let nebula: SKSpriteNode
    private var gridLines: [SKSpriteNode] = []
    private var rails: [SKSpriteNode] = []
    private var dust: [(node: SKSpriteNode, depth: CGFloat)] = []
    private var area: CGSize = .zero
    private let gridSpacing: CGFloat = 96

    init(theme: WorldTheme) {
        self.theme = theme
        gradient = SKSpriteNode(texture: TextureFactory.background(for: theme))
        nebula = SKSpriteNode(texture: TextureFactory.glow)
        super.init()

        gradient.anchorPoint = .zero
        gradient.zPosition = 0
        addChild(gradient)

        nebula.color = UIColor(hex: theme.accent)
        nebula.colorBlendFactor = 1
        nebula.blendMode = .add
        nebula.alpha = 0.16
        nebula.zPosition = 1
        addChild(nebula)
        nebula.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.1, duration: 3),
            .fadeAlpha(to: 0.18, duration: 3),
        ])))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func layout(size: CGSize) {
        guard size.width > 0, size.height > 0, size != area else { return }
        area = size

        gradient.size = size
        nebula.size = CGSize(width: size.width * 1.8, height: size.width * 1.4)
        nebula.position = CGPoint(x: size.width * 0.5, y: size.height * 0.88)

        gridLines.forEach { $0.removeFromParent() }
        rails.forEach { $0.removeFromParent() }
        dust.forEach { $0.node.removeFromParent() }
        gridLines.removeAll()
        rails.removeAll()
        dust.removeAll()

        let lineColor = UIColor(hex: theme.accent, alpha: 0.07)
        let count = Int(size.height / gridSpacing) + 2
        for i in 0..<count {
            let line = SKSpriteNode(color: lineColor, size: CGSize(width: size.width, height: 1))
            line.anchorPoint = CGPoint(x: 0, y: 0.5)
            line.position = CGPoint(x: 0, y: CGFloat(i) * gridSpacing)
            line.zPosition = 2
            addChild(line)
            gridLines.append(line)
        }

        for x in [CGFloat(10), size.width - 10] {
            let rail = SKSpriteNode(color: UIColor(hex: theme.obstacle, alpha: 0.18), size: CGSize(width: 1.5, height: size.height))
            rail.anchorPoint = CGPoint(x: 0.5, y: 0)
            rail.position = CGPoint(x: x, y: 0)
            rail.zPosition = 2
            addChild(rail)
            rails.append(rail)
        }

        let dustColor = UIColor(hex: theme.accent)
        for _ in 0..<36 {
            let depth = CGFloat.random(in: 0.25...1.2)
            let side = 2 + depth * 4
            let mote = SKSpriteNode(texture: TextureFactory.glow, size: CGSize(width: side * 2, height: side * 2))
            mote.color = dustColor
            mote.colorBlendFactor = 0.6
            mote.blendMode = .add
            mote.alpha = 0.15 + depth * 0.3
            mote.position = CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height))
            mote.zPosition = 3
            addChild(mote)
            dust.append((mote, depth))
        }
    }

    func advance(dt: TimeInterval, speed: CGFloat) {
        guard area.height > 0 else { return }
        let distance = speed * CGFloat(dt)
        let span = CGFloat(gridLines.count) * gridSpacing
        for line in gridLines {
            line.position.y -= distance * 0.5
            if line.position.y < -gridSpacing { line.position.y += span }
        }
        for item in dust {
            item.node.position.y -= distance * item.depth
            if item.node.position.y < -10 {
                item.node.position.y = area.height + 10
                item.node.position.x = .random(in: 0...area.width)
            }
        }
    }
}
