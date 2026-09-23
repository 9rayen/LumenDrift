import SwiftUI

/// Springy press-down effect shared by every button.
struct PressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Large glowing call-to-action capsule.
struct PrimaryButton: View {
    let title: String
    var icon: String?
    var accent: Color
    var height: CGFloat = 64
    let action: () -> Void

    @State private var breathe = false

    var body: some View {
        Button {
            Feedback.button()
            action()
        } label: {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: height * 0.3, weight: .black))
                }
                Text(title)
                    .font(.display(height * 0.34, .black))
                    .tracking(2)
            }
            .foregroundStyle(Color.black.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                Capsule()
                    .fill(accent)
                    .overlay(
                        Capsule().fill(
                            LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)], startPoint: .top, endPoint: .center)
                        )
                    )
            )
            .overlay(Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1))
            .shadow(color: accent.opacity(breathe ? 0.75 : 0.35), radius: breathe ? 26 : 14)
            .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

/// Glass capsule for secondary actions.
struct SecondaryButton: View {
    let title: String
    var icon: String?
    var height: CGFloat = 54
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role) {
            Feedback.button()
            action()
        } label: {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(.display(17, .bold))
                    .tracking(1.5)
            }
            .foregroundStyle(role == .destructive ? Color(hex: 0xFF6B7A) : .white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(GlassBackground(shape: Capsule()))
            .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Round glass icon button with an optional caption.
struct GlassIconButton: View {
    let systemName: String
    var label: String?
    var size: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button {
            Feedback.button()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(GlassBackground(shape: Circle()))
                if let label {
                    Text(label.uppercased())
                        .font(.eyebrow)
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(pressedScale: 0.9))
        .accessibilityLabel(label ?? systemName)
    }
}
