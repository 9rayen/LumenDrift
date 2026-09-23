import SwiftUI

/// Live preview of the equipped orb + trail on the equipped world.
struct PreviewStage: View {
    let skin: OrbSkin
    let trail: TrailStyle
    let theme: WorldTheme

    var body: some View {
        let trailColors: [Color] = trail.colors.isEmpty ? [Color(hex: skin.glow)] : trail.colors.map { Color(hex: $0) }
        let streakColors: [Color] = trailColors.map { (c: Color) -> Color in c.opacity(0.85) } + [Color.clear]
        let obstacle = Color(hex: theme.obstacle)

        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let sway = CGFloat(sin(t * 1.4)) * 60

            ZStack {
                LinearGradient(colors: [Color(hex: theme.top), Color(hex: theme.bottom)], startPoint: .top, endPoint: .bottom)

                // Two sample obstacles.
                HStack {
                    Capsule().fill(obstacle.opacity(0.5))
                        .overlay(Capsule().strokeBorder(obstacle, lineWidth: 1.5))
                        .frame(width: 90, height: 14)
                        .shadow(color: obstacle, radius: 6)
                    Spacer()
                    Capsule().fill(obstacle.opacity(0.5))
                        .overlay(Capsule().strokeBorder(obstacle, lineWidth: 1.5))
                        .frame(width: 70, height: 14)
                        .shadow(color: obstacle, radius: 6)
                }
                .padding(.horizontal, 24)
                .offset(y: -50)

                // Trail streak below the orb.
                Capsule()
                    .fill(LinearGradient(colors: streakColors, startPoint: .top, endPoint: .bottom))
                    .frame(width: 18, height: 90)
                    .blur(radius: 4)
                    .offset(x: sway * 0.9, y: 62)

                OrbView(skin: skin, size: 34, animated: false)
                    .offset(x: sway, y: 20)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
        .accessibilityHidden(true)
    }
}
