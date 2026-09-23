import CoreGraphics
import Foundation

/// All difficulty tuning lives here so the game can be balanced in one place.
enum DifficultyCurve {
    static let baseSpeed: CGFloat = 300
    static let speedGain: CGFloat = 540

    /// World scroll speed in points per second. Eases toward baseSpeed + speedGain.
    static func speed(at time: TimeInterval) -> CGFloat {
        baseSpeed + speedGain * CGFloat(1 - exp(-time / 70))
    }

    /// Vertical distance between obstacle rows.
    static func rowSpacing(at time: TimeInterval) -> CGFloat {
        max(270, 430 - CGFloat(time) * 1.6)
    }

    /// Width of the opening in gate rows.
    static func gapWidth(at time: TimeInterval, playerRadius: CGFloat, screenWidth: CGFloat) -> CGFloat {
        let minimum = playerRadius * 2 * 2.5
        let target = 190 - CGFloat(time) * 0.8
        return max(minimum, min(screenWidth * 0.42, target))
    }

    /// Every 18 seconds a new family of patterns joins the mix.
    static func phase(at time: TimeInterval) -> Int {
        min(Int(time / 18), 4)
    }

    static func patterns(forPhase phase: Int) -> [RowPattern] {
        switch phase {
        case 0: return [.block, .block, .gate]
        case 1: return [.block, .gate, .gate, .slidingGate]
        case 2: return [.gate, .slidingGate, .block, .twinGap]
        case 3: return [.gate, .slidingGate, .twinGap, .pulseBlocks, .block]
        default: return [.slidingGate, .twinGap, .pulseBlocks, .gate, .slidingGate]
        }
    }
}
