import SwiftUI

struct LogoView: View {
    var accent: Color
    var scale: CGFloat = 1

    var body: some View {
        VStack(spacing: -4 * scale) {
            Text("LUMEN")
                .font(.system(size: 58 * scale, weight: .black, design: .rounded))
                .tracking(6 * scale)
                .padding(.leading, 6 * scale)
                .foregroundStyle(
                    LinearGradient(colors: [.white, accent], startPoint: .top, endPoint: .bottom)
                )
            Text("DRIFT")
                .font(.system(size: 22 * scale, weight: .light, design: .rounded))
                .tracking(20 * scale)
                .padding(.leading, 20 * scale)
                .foregroundStyle(.white.opacity(0.85))
        }
        .shadow(color: accent.opacity(0.6), radius: 18 * scale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lumen Drift")
    }
}
