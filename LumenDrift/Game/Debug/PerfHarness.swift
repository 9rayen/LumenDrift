#if DEBUG
import Foundation
import QuartzCore
import SpriteKit

/// Debug-only test harness, compiled out of Release builds.
/// Launching with `-autopilot` skips the menus, plays the game automatically and logs frame timing,
/// so performance can be measured on a CI simulator without touching the screen.
enum DebugHarness {
    static let isAutopilot = ProcessInfo.processInfo.arguments.contains("-autopilot")

    static func log(_ line: String) {
        FileHandle.standardError.write(Data((line + "\n").utf8))
    }
}

/// Collects frame-time statistics and prints a summary every 5 seconds.
final class PerfStats {
    private static let hitchThreshold: TimeInterval = 0.025

    private var windowStart: TimeInterval = 0
    private var frames = 0
    private var hitches = 0
    private var worstFrame: TimeInterval = 0
    private var sparks = 0
    private var sparkFrames = 0
    private var sparkHitches = 0
    private var worstSparkFrame: TimeInterval = 0
    private var collectTotal: TimeInterval = 0
    private var collectWorst: TimeInterval = 0
    private var sparkPending = false

    /// Call once per update with the unclamped time since the previous update.
    func recordFrame(rawDt: TimeInterval, now: TimeInterval) {
        if windowStart == 0 { windowStart = now }
        frames += 1
        if rawDt > Self.hitchThreshold { hitches += 1 }
        worstFrame = max(worstFrame, rawDt)
        // This interval contains the rendering of the frame in which a spark was collected.
        if sparkPending {
            sparkPending = false
            sparkFrames += 1
            if rawDt > Self.hitchThreshold { sparkHitches += 1 }
            worstSparkFrame = max(worstSparkFrame, rawDt)
        }
        if now - windowStart >= 5 { flush(now: now) }
    }

    /// Time spent on the main thread handling one spark pickup.
    func recordCollect(_ duration: TimeInterval) {
        sparks += 1
        collectTotal += duration
        collectWorst = max(collectWorst, duration)
        sparkPending = true
    }

    private func flush(now: TimeInterval) {
        let collectAvg = sparks > 0 ? collectTotal / Double(sparks) : 0
        DebugHarness.log(String(
            format: "PERF window=%.1fs frames=%ld hitches=%ld worstFrame=%.1fms sparks=%ld sparkFrames=%ld sparkHitches=%ld worstSparkFrame=%.1fms collectAvg=%.3fms collectWorst=%.3fms",
            now - windowStart, frames, hitches, worstFrame * 1000, sparks, sparkFrames, sparkHitches,
            worstSparkFrame * 1000, collectAvg * 1000, collectWorst * 1000
        ))
        windowStart = now
        frames = 0
        hitches = 0
        worstFrame = 0
        sparks = 0
        sparkFrames = 0
        sparkHitches = 0
        worstSparkFrame = 0
        collectTotal = 0
        collectWorst = 0
    }
}

extension GameScene {
    /// Steers toward the x position with the most clearance in the next row, which is also where sparks sit.
    func autopilotSteer() {
        guard runState == .running, let player else { return }
        let p = player.position
        guard let row = rows.first(where: { !$0.resolved && !$0.isBroken && $0.position.y > p.y - 10 }) else { return }

        let range = horizontalRange
        var bestX = targetX
        var bestScore = -CGFloat.greatestFiniteMagnitude
        let steps = 32
        for i in 0...steps {
            let x = range.lowerBound + (range.upperBound - range.lowerBound) * CGFloat(i) / CGFloat(steps)
            var clearance = CGFloat.greatestFiniteMagnitude
            for bar in row.bars {
                let f = row.frame(of: bar)
                clearance = min(clearance, max(f.minX - x, 0, x - f.maxX))
            }
            let score = min(clearance, 80) - abs(x - p.x) * 0.05
            if score > bestScore {
                bestScore = score
                bestX = x
            }
        }
        targetX = bestX
    }
}
#endif
