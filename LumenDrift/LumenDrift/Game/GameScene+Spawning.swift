import SpriteKit
import UIKit

extension GameScene {
    func spawnRow() {
        let width = size.width
        let row = RowNode(barHeight: Self.barHeight)
        row.position = CGPoint(x: 0, y: size.height + 60)
        row.zPosition = 10
        let gap = DifficultyCurve.gapWidth(at: elapsed, playerRadius: playerRadius, screenWidth: width)
        var safeX = width / 2

        switch nextPattern() {
        case .block:
            let barWidth = CGFloat.random(in: (width * 0.3)...(width * 0.52))
            let x = CGFloat.random(in: (barWidth / 2)...(width - barWidth / 2))
            row.addBar(width: barWidth, centerX: x, tint: config.theme.obstacle)
            let leftSpace = x - barWidth / 2
            let rightSpace = width - (x + barWidth / 2)
            safeX = leftSpace > rightSpace ? leftSpace / 2 : x + barWidth / 2 + rightSpace / 2

        case .gate:
            let x = CGFloat.random(in: (gap / 2 + 24)...(width - gap / 2 - 24))
            addGate(to: row, gapCenter: x, gap: gap, overhang: 40)
            safeX = x

        case .slidingGate:
            let amplitude = min(width * 0.2, 70)
            let low = gap / 2 + 24 + amplitude
            let high = width - gap / 2 - 24 - amplitude
            let x = low < high ? CGFloat.random(in: low...high) : width / 2
            addGate(to: row, gapCenter: x, gap: gap * 1.08, overhang: 40 + amplitude)
            row.motion = .slide(amplitude: amplitude, speed: .random(in: 1.6...2.4))
            safeX = x

        case .twinGap:
            let g = gap * 1.05
            let first = CGFloat.random(in: (width * 0.2)...(width * 0.32))
            let second = CGFloat.random(in: (width * 0.68)...(width * 0.8))
            addSpan(to: row, from: -40, to: first - g / 2)
            addSpan(to: row, from: first + g / 2, to: second - g / 2)
            addSpan(to: row, from: second + g / 2, to: width + 40)
            safeX = Bool.random() ? first : second

        case .pulseBlocks:
            let barWidth = width * 0.36
            row.addBar(width: barWidth, centerX: width * 0.25, tint: config.theme.obstacle)
            row.addBar(width: barWidth, centerX: width * 0.75, tint: config.theme.obstacle)
            row.motion = .pulse(minScale: 0.3, speed: .random(in: 2.2...3.0))
            safeX = width / 2
        }

        placePickups(on: row, safeX: safeX)
        playfield.addChild(row)
        rows.append(row)
    }

    private func nextPattern() -> RowPattern {
        let pool = DifficultyCurve.patterns(forPhase: DifficultyCurve.phase(at: elapsed))
        var choice = pool.randomElement() ?? .gate
        if choice == lastPattern, let reroll = pool.randomElement() {
            choice = reroll
        }
        lastPattern = choice
        return choice
    }

    private func addGate(to row: RowNode, gapCenter: CGFloat, gap: CGFloat, overhang: CGFloat) {
        addSpan(to: row, from: -overhang, to: gapCenter - gap / 2)
        addSpan(to: row, from: gapCenter + gap / 2, to: size.width + overhang)
    }

    private func addSpan(to row: RowNode, from start: CGFloat, to end: CGFloat) {
        guard end - start > 12 else { return }
        row.addBar(width: end - start, centerX: (start + end) / 2, tint: config.theme.obstacle)
    }

    /// Sparks (or occasionally a power-up) sit between this row and the next, lined up with the safe path.
    private func placePickups(on row: RowNode, safeX: CGFloat) {
        let x = safeX.clamped(to: 30...max(30, size.width - 30))
        let midpoint = DifficultyCurve.rowSpacing(at: elapsed) * 0.5
        rowsSincePowerUp += 1

        if rowsSincePowerUp >= 12, Double.random(in: 0...1) < 0.3 {
            rowsSincePowerUp = 0
            let kind = PowerUpKind.allCases.randomElement() ?? .shield
            row.addPowerUp(kind, at: CGPoint(x: x, y: midpoint))
        } else if Double.random(in: 0...1) < 0.75 {
            let count = Int.random(in: 3...5)
            let spacing: CGFloat = 30
            let tint = UIColor(hex: config.theme.accent)
            for i in 0..<count {
                let offset = (CGFloat(i) - CGFloat(count - 1) / 2) * spacing
                row.addSpark(at: CGPoint(x: x, y: midpoint + offset), tint: tint)
            }
        }
    }
}
