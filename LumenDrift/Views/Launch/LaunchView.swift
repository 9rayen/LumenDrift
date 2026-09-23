import SwiftUI

/// Animated intro: the orb drops in, a ring pulses out, and the wordmark resolves.
/// The static system launch screen is plain black (dark style), so this continues seamlessly from it.
struct LaunchView: View {
    let onFinish: () -> Void

    @State private var orbIn = false
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0.9
    @State private var titleIn = false
    @State private var taglineIn = false
    @State private var finished = false

    private let accent = Color(hex: 0x4DF3FF)

    var body: some View {
        ZStack {
            Color.black
            RadialGradient(colors: [accent.opacity(titleIn ? 0.22 : 0), .clear], center: .center, startRadius: 0, endRadius: 420)

            VStack(spacing: 34) {
                ZStack {
                    Circle()
                        .stroke(accent.opacity(ringOpacity), lineWidth: 2)
                        .frame(width: 110, height: 110)
                        .scaleEffect(ringScale)
                    OrbView(skin: Catalog.skins[0], size: 44)
                        .offset(y: orbIn ? 0 : -420)
                        .opacity(orbIn ? 1 : 0)
                }
                .frame(height: 140)

                LogoView(accent: accent)
                    .opacity(titleIn ? 1 : 0)
                    .blur(radius: titleIn ? 0 : 14)
                    .scaleEffect(titleIn ? 1 : 1.15)

                Text("DRAG  ·  DODGE  ·  DRIFT")
                    .font(.display(12, .bold))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(taglineIn ? 0.6 : 0))
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(perform: finish)
        .task { await runIntro() }
    }

    private func runIntro() async {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { orbIn = true }
        guard await pause(0.45) else { return }
        withAnimation(.easeOut(duration: 0.8)) {
            ringScale = 2.6
            ringOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.6)) { titleIn = true }
        guard await pause(0.35) else { return }
        withAnimation(.easeOut(duration: 0.5)) { taglineIn = true }
        guard await pause(1.0) else { return }
        finish()
    }

    /// Returns false if the task was cancelled (view left the screen).
    private func pause(_ seconds: Double) async -> Bool {
        (try? await Task.sleep(for: .seconds(seconds))) != nil
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinish()
    }
}
