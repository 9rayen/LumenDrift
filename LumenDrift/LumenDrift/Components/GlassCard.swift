import SwiftUI

/// Frosted-glass container used across menus.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var padding: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = 26, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background { GlassBackground(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)) }
    }
}

struct GlassBackground<S: InsettableShape>: View {
    let shape: S
    var tint: Color = .white

    var body: some View {
        shape
            .fill(.ultraThinMaterial)
            .overlay(
                shape.fill(
                    LinearGradient(colors: [tint.opacity(0.12), tint.opacity(0.02)], startPoint: .top, endPoint: .bottom)
                )
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
            )
            .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
    }
}
