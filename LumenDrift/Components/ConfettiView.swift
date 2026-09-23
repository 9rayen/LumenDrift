import SwiftUI

/// Lightweight celebratory burst drawn with Canvas (no assets).
struct ConfettiView: View {
    let colors: [Color]
    var count = 90
    var duration: Double = 3.2

    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                Self.draw(in: &ctx, size: size, time: context.date.timeIntervalSince(start),
                          colors: colors, count: count, duration: duration)
            }
        }
        .allowsHitTesting(false)
    }

    private static func draw(in ctx: inout GraphicsContext, size: CGSize, time t: Double,
                             colors: [Color], count: Int, duration: Double) {
        guard t < duration, !colors.isEmpty else { return }
        let w = Double(size.width)
        let h = Double(size.height)
        let fade = max(0, 1 - max(0, t - duration + 0.8) / 0.8)

        for i in 0..<count {
            let seed = Double(i)
            let angle = hash(seed) * .pi * 2
            let power = 250 + hash(seed * 2.3) * 450
            let vx = cos(angle) * power * 0.7
            let vy = sin(angle) * power - 380
            let x = w / 2 + vx * t
            let y = h * 0.32 + vy * t + 0.5 * 900 * t * t
            let spin = t * (4 + hash(seed * 4.1) * 8)
            let pw = 5 + hash(seed * 5.7) * 6
            let ph = pw * 0.45

            var piece = ctx
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(spin))
            piece.opacity = fade
            let rect = CGRect(x: -pw / 2, y: -ph / 2, width: pw, height: ph)
            piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(colors[i % colors.count]))
        }
    }

    private static func hash(_ n: Double) -> Double {
        let v = sin(n * 91.3458 + 12.9898) * 47453.5453
        return v - floor(v)
    }
}
