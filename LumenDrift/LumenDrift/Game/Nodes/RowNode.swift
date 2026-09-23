import SpriteKit
import UIKit

/// A horizontal band of obstacles plus the pickups that follow it.
/// Rows are moved manually by the scene each frame so slow-motion can scale time.
final class RowNode: SKNode {
    enum Motion {
        case none
        case slide(amplitude: CGFloat, speed: CGFloat)
        case pulse(minScale: CGFloat, speed: CGFloat)
    }

    let barHeight: CGFloat
    let barLayer = SKNode()
    private(set) var bars: [BarNode] = []
    private(set) var sparks: [SparkNode] = []
    private(set) var powerUps: [PowerUpNode] = []
    private(set) var topExtent: CGFloat

    var motion: Motion = .none
    /// Closest edge-to-edge distance between the orb and any bar while passing (for near-misses).
    var nearestGap: CGFloat = .greatestFiniteMagnitude
    var resolved = false
    var isBroken = false

    private var clock = CGFloat.random(in: 0...(2 * CGFloat.pi))

    init(barHeight: CGFloat) {
        self.barHeight = barHeight
        topExtent = barHeight
        super.init()
        addChild(barLayer)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func addBar(width: CGFloat, centerX: CGFloat, tint: UInt32) {
        let bar = BarNode(barSize: CGSize(width: width, height: barHeight), tint: tint)
        bar.position = CGPoint(x: centerX, y: 0)
        barLayer.addChild(bar)
        bars.append(bar)
    }

    func addSpark(at point: CGPoint, tint: UIColor) {
        let spark = SparkNode(tint: tint)
        spark.position = point
        spark.zPosition = 2
        addChild(spark)
        sparks.append(spark)
        topExtent = max(topExtent, point.y + 24)
    }

    func addPowerUp(_ kind: PowerUpKind, at point: CGPoint) {
        let node = PowerUpNode(kind: kind)
        node.position = point
        node.zPosition = 3
        addChild(node)
        powerUps.append(node)
        topExtent = max(topExtent, point.y + 40)
    }

    func advance(dt: TimeInterval) {
        clock += CGFloat(dt)
        switch motion {
        case .none:
            break
        case let .slide(amplitude, speed):
            barLayer.position.x = sin(clock * speed) * amplitude
        case let .pulse(minScale, speed):
            let scale = minScale + (1 - minScale) * (0.5 + 0.5 * sin(clock * speed))
            for bar in bars { bar.xScale = scale }
        }
    }

    /// Collision rectangle of a bar in the parent (playfield) coordinate space.
    func frame(of bar: BarNode) -> CGRect {
        let width = bar.barSize.width * bar.xScale
        let height = bar.barSize.height
        let cx = position.x + barLayer.position.x + bar.position.x
        let cy = position.y + barLayer.position.y + bar.position.y
        return CGRect(x: cx - width / 2, y: cy - height / 2, width: width, height: height)
    }

    /// Position of a pickup child in the parent (playfield) coordinate space.
    func parentPosition(of node: SKNode) -> CGPoint {
        CGPoint(x: position.x + node.position.x, y: position.y + node.position.y)
    }
}
