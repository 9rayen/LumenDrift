import SwiftUI

/// Shows the player's spark (coin) balance.
struct CoinPill: View {
    let amount: Int
    var accent: Color = Color(hex: 0xFFD24D)

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(accent)
                .shadow(color: accent, radius: 6)
            Text(amount.formatted())
                .font(.display(17, .bold))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(amount)))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(GlassBackground(shape: Capsule()))
        .animation(.snappy, value: amount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(amount) sparks")
    }
}

/// Level number inside an XP progress ring, plus a label.
struct LevelBadge: View {
    let level: Int
    let progress: Double
    var accent: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: max(0.02, progress))
                    .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accent.opacity(0.8), radius: 4)
                Text("\(level)")
                    .font(.display(16, .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 1) {
                Text("LEVEL")
                    .font(.eyebrow)
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.55))
                Text("\(Int(progress * 100))% to \(level + 1)")
                    .font(.display(12, .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 14)
        .frame(height: 48)
        .background(GlassBackground(shape: Capsule()))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(level)")
    }
}

/// Small stat block used in cards.
struct StatTile: View {
    let title: String
    let value: String
    var tint: Color = .white

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.display(20, .heavy))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.eyebrow)
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }
}
