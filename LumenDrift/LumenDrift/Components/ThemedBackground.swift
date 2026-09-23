import SwiftUI

/// Animated menu backdrop matching the selected world: gradient, glow blobs and drifting motes.
struct ThemedBackground: View {
    let theme: WorldTheme

    var body: some View {
        let accent = Color(hex: theme.accent)
        let obstacle = Color(hex: theme.obstacle)

        ZStack {
            LinearGradient(colors: [Color(hex: theme.top), Color(hex: theme.bottom)], startPoint: .top, endPoint: .bottom)

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                Canvas { ctx, size in
                    Self.draw(in: &ctx, size: size, time: context.date.timeIntervalSinceReferenceDate,
                              accent: accent, secondary: obstacle)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private static func draw(in ctx: inout GraphicsContext, size: CGSize, time t: Double, accent: Color, secondary: Color) {
        let w = Double(size.width)
        let h = Double(size.height)
        guard w > 0, h > 0 else { return }

        // Two slow glow blobs.
        let blobs: [(color: Color, x: Double, y: Double, phase: Double)] = [
            (accent, 0.25, 0.22, 0.0),
            (secondary, 0.8, 0.7, 2.1),
        ]
        for blob in blobs {
            let cx = w * (blob.x + 0.08 * sin(t * 0.25 + blob.phase))
            let cy = h * (blob.y + 0.05 * cos(t * 0.2 + blob.phase))
            let radius = w * 0.7
            let center = CGPoint(x: cx, y: cy)
            let rect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
            let gradient = Gradient(colors: [blob.color.opacity(0.28), blob.color.opacity(0)])
            ctx.fill(Path(ellipseIn: rect),
                     with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: CGFloat(radius)))
        }

        // Faint horizontal grid scrolling down.
        let spacing = 64.0
        var y = (t * 18).truncatingRemainder(dividingBy: spacing) - spacing
        while y < h {
            ctx.fill(Path(CGRect(x: 0, y: y, width: w, height: 0.5)), with: .color(accent.opacity(0.06)))
            y += spacing
        }

        // Drifting motes.
        for i in 0..<42 {
            let seed = Double(i)
            let speed = 10 + hash(seed * 3.1) * 30
            let x = hash(seed) * w
            let rawY = hash(seed * 7.7) * h + t * speed
            let my = rawY.truncatingRemainder(dividingBy: h + 20) - 10
            let r = 1 + hash(seed * 1.9) * 2.2
            let alpha = 0.15 + hash(seed * 5.3) * 0.45
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: my - r, width: r * 2, height: r * 2)),
                     with: .color(accent.opacity(alpha)))
        }
    }

    /// Deterministic 0…1 pseudo-random value.
    private static func hash(_ n: Double) -> Double {
        let v = sin(n * 12.9898 + 78.233) * 43758.5453
        return v - floor(v)
    }
}
