import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var router: AppRouter

    @State private var showCustomize = false
    @State private var showSettings = false
    @State private var showAchievements = false
    @State private var appeared = false
    @State private var bob = false

    var body: some View {
        let p = store.progress
        let theme = Catalog.theme(p.selectedTheme)
        let accent = Color(hex: theme.accent)

        ZStack {
            ThemedBackground(theme: theme)

            VStack(spacing: 0) {
                topBar(progress: p, accent: accent)
                    .padding(.top, 8)

                Spacer(minLength: 20)

                LogoView(accent: accent)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -24)

                Spacer(minLength: 12)

                OrbView(skin: Catalog.skin(p.selectedSkin), size: 62)
                    .offset(y: bob ? -8 : 8)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.6)

                Spacer(minLength: 12)

                statsCard(progress: p, accent: accent)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)

                PrimaryButton(title: "PLAY", icon: "play.fill", accent: accent, height: 72) {
                    router.go(.game)
                }
                .padding(.top, 18)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)

                bottomBar
                    .padding(.top, 22)
                    .padding(.bottom, 8)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, 24)
        }
        .fullScreenCover(isPresented: $showCustomize) {
            CustomizeView().environmentObject(store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView().environmentObject(store)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { bob = true }
        }
    }

    private func topBar(progress p: PlayerProgress, accent: Color) -> some View {
        HStack {
            LevelBadge(level: p.level, progress: p.levelFraction, accent: accent)
            Spacer()
            CoinPill(amount: p.coins)
        }
    }

    private func statsCard(progress p: PlayerProgress, accent: Color) -> some View {
        GlassCard(padding: 18) {
            VStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text("BEST SCORE")
                        .font(.eyebrow)
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.55))
                    Text(p.bestScore.formatted())
                        .font(.display(40, .black))
                        .monospacedDigit()
                        .foregroundStyle(LinearGradient(colors: [.white, accent], startPoint: .top, endPoint: .bottom))
                }
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
                HStack {
                    StatTile(title: "RUNS", value: p.totalGames.formatted())
                    StatTile(title: "BEST COMBO", value: "x\(p.bestMultiplier)")
                    StatTile(title: "LONGEST", value: Self.format(seconds: p.longestRun))
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            GlassIconButton(systemName: "paintpalette.fill", label: "Style") { showCustomize = true }
            Spacer()
            GlassIconButton(systemName: "trophy.fill", label: "Awards") { showAchievements = true }
            Spacer()
            GlassIconButton(systemName: "gearshape.fill", label: "Settings") { showSettings = true }
        }
        .padding(.horizontal, 12)
    }

    static func format(seconds: Double) -> String {
        let s = Int(seconds)
        return s >= 60 ? "\(s / 60)m \(s % 60)s" : "\(s)s"
    }
}
