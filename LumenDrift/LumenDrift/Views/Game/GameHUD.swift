import SwiftUI

/// Minimal in-game overlay: pause, score, best, multiplier and active power-ups.
struct GameHUD: View {
    @ObservedObject var session: GameSession
    let accent: Color
    let onPause: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                scoreBlock
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)

                HStack(alignment: .top) {
                    Button {
                        Feedback.button()
                        onPause()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(GlassBackground(shape: Circle()))
                            .contentShape(Circle())
                    }
                    .buttonStyle(PressableButtonStyle(pressedScale: 0.88))
                    .accessibilityLabel("Pause")

                    Spacer()

                    MultiplierBadge(multiplier: session.multiplier, accent: accent)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 8) {
                ForEach(session.activePowerUps) { power in
                    PowerUpChip(power: power)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: session.activePowerUps.map(\.id))
            .allowsHitTesting(false)

            Spacer()

            if session.showHint {
                DragHint(accent: accent)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .animation(.easeOut(duration: 0.3), value: session.showHint)
    }

    private var scoreBlock: some View {
        VStack(spacing: 0) {
            Text("\(session.score)")
                .font(.display(46, .black))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: accent.opacity(0.6), radius: 12)
            Text(session.isNewBestLive ? "NEW BEST" : "BEST \(session.bestScore)")
                .font(.eyebrow)
                .tracking(2)
                .foregroundStyle(session.isNewBestLive ? accent : .white.opacity(0.55))
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MultiplierBadge: View {
    let multiplier: Int
    let accent: Color

    var body: some View {
        ZStack {
            if multiplier > 1 {
                Text("x\(multiplier)")
                    .font(.display(20, .black))
                    .foregroundStyle(.black.opacity(0.85))
                    .frame(width: 56, height: 46)
                    .background(Capsule().fill(accent))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1))
                    .shadow(color: accent.opacity(0.8), radius: 12)
                    .id(multiplier)
                    .transition(.scale(scale: 1.8).combined(with: .opacity))
            }
        }
        .frame(width: 56, height: 46)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: multiplier)
    }
}

private struct PowerUpChip: View {
    let power: ActivePowerUp

    var body: some View {
        let tint = Color(hex: power.kind.color)
        HStack(spacing: 6) {
            ZStack {
                Circle().stroke(tint.opacity(0.25), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: power.fraction)
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: power.kind.symbol)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 26, height: 26)
            Text(power.kind.title.uppercased())
                .font(.display(11, .heavy))
                .tracking(1)
                .foregroundStyle(.white)
        }
        .padding(.leading, 5)
        .padding(.trailing, 12)
        .frame(height: 34)
        .background(GlassBackground(shape: Capsule(), tint: tint))
        .opacity(power.remaining < 1.5 && Int(power.remaining * 6) % 2 == 0 ? 0.45 : 1)
    }
}

private struct DragHint: View {
    let accent: Color
    @State private var swing = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .offset(x: swing ? 44 : -44)
            Text("DRAG ANYWHERE TO DRIFT")
                .font(.display(13, .heavy))
                .tracking(2.5)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 22)
        .background(GlassBackground(shape: RoundedRectangle(cornerRadius: 22, style: .continuous), tint: accent))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { swing = true }
        }
    }
}
