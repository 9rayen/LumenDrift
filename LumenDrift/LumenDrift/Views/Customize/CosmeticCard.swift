import SwiftUI

struct CosmeticCard: View {
    let item: CosmeticItem
    let state: CosmeticState
    let accent: Color

    var body: some View {
        VStack(spacing: 12) {
            preview
                .frame(height: 78)
                .frame(maxWidth: .infinity)
                .opacity(isLocked ? 0.45 : 1)
                .overlay(alignment: .topTrailing) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(8)
                    }
                }

            Text(item.name)
                .font(.display(16, .bold))
                .foregroundStyle(.white)

            statusLabel
        }
        .padding(14)
        .background(
            GlassBackground(
                shape: RoundedRectangle(cornerRadius: 22, style: .continuous),
                tint: state == .equipped ? accent : .white
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: state == .equipped ? 2 : 0)
                .shadow(color: accent.opacity(0.7), radius: 8)
        )
        .accessibilityElement(children: .combine)
    }

    private var isLocked: Bool {
        switch state {
        case .buyable, .locked: return true
        default: return false
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item.category {
        case .skin:
            OrbView(skin: Catalog.skin(item.key), size: 36, animated: false)
        case .trail:
            TrailSwatch(trail: Catalog.trail(item.key), fallback: accent)
        case .theme:
            ThemeSwatch(theme: Catalog.theme(item.key))
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch state {
        case .equipped:
            label("EQUIPPED", icon: "checkmark", color: accent)
        case .owned:
            label("SELECT", icon: nil, color: .white.opacity(0.7))
        case .buyable(let price, let affordable):
            label("\(price)", icon: "sparkle", color: affordable ? Color(hex: 0xFFD24D) : .white.opacity(0.4))
        case .locked(let level):
            label("LEVEL \(level)", icon: "lock.fill", color: .white.opacity(0.45))
        }
    }

    private func label(_ text: String, icon: String?, color: Color) -> some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon).font(.system(size: 11, weight: .black))
            }
            Text(text).font(.display(12, .heavy)).tracking(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(Capsule().fill(color.opacity(0.14)))
    }
}

struct TrailSwatch: View {
    let trail: TrailStyle
    let fallback: Color

    var body: some View {
        let colors: [Color] = trail.colors.isEmpty ? [fallback] : trail.colors.map { Color(hex: $0) }
        let tailColor: Color = colors.last.map { $0.opacity(0) } ?? Color.clear
        let streakColors: [Color] = colors + [tailColor]
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: streakColors, startPoint: .top, endPoint: .bottom))
                .frame(width: 14, height: 70)
                .blur(radius: 3)
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: CGFloat(8 - i), height: CGFloat(8 - i))
                    .offset(x: CGFloat(i.isMultiple(of: 2) ? -12 : 12), y: CGFloat(i) * 10 - 20)
                    .opacity(1 - Double(i) * 0.12)
            }
        }
    }
}

struct ThemeSwatch: View {
    let theme: WorldTheme

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: theme.top), Color(hex: theme.bottom)], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(Color(hex: theme.obstacle))
                    .frame(width: 44, height: 8)
                    .shadow(color: Color(hex: theme.obstacle), radius: 4)
                    .padding(.top, 18)
                    .padding(.leading, 10)
            }
            .overlay(alignment: .trailing) {
                Capsule()
                    .fill(Color(hex: theme.obstacle))
                    .frame(width: 34, height: 8)
                    .shadow(color: Color(hex: theme.obstacle), radius: 4)
                    .padding(.trailing, 10)
            }
            .overlay(alignment: .bottom) {
                Circle()
                    .fill(Color(hex: theme.accent))
                    .frame(width: 12, height: 12)
                    .shadow(color: Color(hex: theme.accent), radius: 6)
                    .padding(.bottom, 12)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .frame(width: 96)
    }
}
