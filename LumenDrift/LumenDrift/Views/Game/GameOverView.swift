import SwiftUI

struct GameOverView: View {
    let summary: RunSummary
    let accent: Color
    let onRestart: () -> Void
    let onMenu: () -> Void

    @State private var shownScore = 0
    @State private var cardIn = false
    @State private var titleIn = false
    @State private var badgeIn = false
    @State private var xpFill: Double = 0

    private var celebrate: Bool { summary.isNewBest && summary.result.score > 0 }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.35), .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if celebrate {
                ConfettiView(colors: [accent, .white, Color(hex: 0xFF4D9D), Color(hex: 0xFFD24D)])
                    .ignoresSafeArea()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    title
                        .padding(.top, 36)

                    resultCard
                        .offset(y: cardIn ? 0 : 280)
                        .opacity(cardIn ? 1 : 0)

                    VStack(spacing: 12) {
                        PrimaryButton(title: "PLAY AGAIN", icon: "arrow.clockwise", accent: accent, height: 68, action: onRestart)
                        SecondaryButton(title: "MENU", icon: "house.fill", action: onMenu)
                    }
                    .opacity(cardIn ? 1 : 0)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
        }
        .task { await animateIn() }
    }

    private var title: some View {
        VStack(spacing: 6) {
            Text(celebrate ? "NEW BEST!" : "GAME OVER")
                .font(.display(42, .black))
                .tracking(3)
                .foregroundStyle(
                    celebrate
                        ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFE9A8), Color(hex: 0xFFB84D)], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(Color.white)
                )
                .shadow(color: (celebrate ? Color(hex: 0xFFD24D) : accent).opacity(0.7), radius: 18)
                .scaleEffect(titleIn ? 1 : 1.6)
                .opacity(titleIn ? 1 : 0)
            if celebrate && summary.previousBest > 0 {
                Text("Beat your old best of \(summary.previousBest.formatted())")
                    .font(.display(14, .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .opacity(badgeIn ? 1 : 0)
            }
        }
    }

    private var resultCard: some View {
        GlassCard(padding: 22) {
            VStack(spacing: 18) {
                VStack(spacing: 2) {
                    Text("SCORE")
                        .font(.eyebrow)
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.55))
                    Text(shownScore.formatted())
                        .font(.display(64, .black))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(shownScore)))
                        .foregroundStyle(.white)
                        .shadow(color: accent.opacity(0.5), radius: 14)
                }

                HStack {
                    StatTile(title: "BEST", value: summary.bestScore.formatted())
                    StatTile(title: "SPARKS", value: "+\(summary.coinsEarned)", tint: Color(hex: 0xFFD24D))
                    StatTile(title: "COMBO", value: "x\(summary.result.bestMultiplier)", tint: accent)
                }

                xpBar

                if !summary.newAchievements.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(summary.newAchievements) { achievement in
                            HStack(spacing: 10) {
                                Image(systemName: achievement.icon)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(hex: 0xFFD24D))
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color(hex: 0xFFD24D).opacity(0.15)))
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("UNLOCKED")
                                        .font(.eyebrow)
                                        .tracking(1.5)
                                        .foregroundStyle(.white.opacity(0.5))
                                    Text(achievement.title)
                                        .font(.display(15, .bold))
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                                Text("+\(achievement.reward)")
                                    .font(.display(14, .heavy))
                                    .foregroundStyle(Color(hex: 0xFFD24D))
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.06)))
                            .opacity(badgeIn ? 1 : 0)
                            .offset(y: badgeIn ? 0 : 12)
                        }
                    }
                }
            }
        }
    }

    private var xpBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text(summary.leveledUp ? "LEVEL UP!  \(summary.levelAfter)" : "LEVEL \(summary.levelAfter)")
                    .font(.display(12, .heavy))
                    .tracking(1.5)
                    .foregroundStyle(summary.leveledUp ? accent : .white.opacity(0.75))
                Spacer()
                Text("+\(summary.xpGained) XP")
                    .font(.display(12, .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(colors: [accent.opacity(0.7), accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * xpFill))
                        .shadow(color: accent.opacity(0.8), radius: 6)
                }
            }
            .frame(height: 8)
        }
    }

    private func animateIn() async {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { titleIn = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1)) { cardIn = true }

        let target = summary.result.score
        let steps = 24
        for step in 1...steps {
            guard (try? await Task.sleep(for: .milliseconds(26))) != nil else { return }
            withAnimation(.snappy(duration: 0.12)) {
                shownScore = target * step / steps
            }
        }
        withAnimation(.easeOut(duration: 0.6)) { xpFill = summary.levelProgress }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { badgeIn = true }
    }
}
