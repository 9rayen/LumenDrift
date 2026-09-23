import SwiftUI

nonisolated struct OrbShapeView: Shape {
    let shape: OrbShape

    func path(in rect: CGRect) -> Path {
        Path(shape.cgPath(in: rect))
    }
}

/// SwiftUI rendition of the player orb (menus, shop, previews).
struct OrbView: View {
    let skin: OrbSkin
    var size: CGFloat = 60
    var animated = true

    @State private var pulse = false

    var body: some View {
        let core = Color(hex: skin.core)
        let glow = Color(hex: skin.glow)

        ZStack {
            Circle()
                .fill(RadialGradient(colors: [glow.opacity(0.55), glow.opacity(0)], center: .center, startRadius: 0, endRadius: size * 1.3))
                .frame(width: size * 2.8, height: size * 2.8)
                .scaleEffect(pulse ? 1.08 : 0.94)

            orbBody(core: core, glow: glow)
                .frame(width: size, height: size)
                .shadow(color: glow.opacity(0.9), radius: size * 0.2)
        }
        .frame(width: size * 1.6, height: size * 1.6)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    @ViewBuilder
    private func orbBody(core: Color, glow: Color) -> some View {
        if skin.shape == .ring {
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [.white, core], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.14)
                    .padding(size * 0.08)
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.2, height: size * 0.2)
            }
        } else {
            OrbShapeView(shape: skin.shape)
                .fill(RadialGradient(colors: [.white, core], center: UnitPoint(x: 0.38, y: 0.32), startRadius: 0, endRadius: size * 0.6))
                .overlay(OrbShapeView(shape: skin.shape).stroke(glow, lineWidth: 1.5))
        }
    }
}
