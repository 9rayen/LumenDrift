import SpriteKit
import SwiftUI

struct GameContainerView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var session: GameSession
    @State private var showSettings = false

    init(store: ProgressStore) {
        _session = StateObject(wrappedValue: GameSession(store: store))
    }

    var body: some View {
        let accent = Color(hex: session.theme.accent)

        ZStack {
            SpriteView(scene: session.scene, preferredFramesPerSecond: 60)
                .ignoresSafeArea()

            if session.phase != .over {
                GameHUD(session: session, accent: accent) {
                    session.pause()
                }
                .transition(.opacity)
            }

            if session.phase == .paused {
                PauseView(
                    accent: accent,
                    onResume: { session.resume() },
                    onRestart: { session.restart() },
                    onSettings: { showSettings = true },
                    onMenu: { router.go(.home) }
                )
                .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }

            if session.phase == .over, let summary = session.summary {
                GameOverView(
                    summary: summary,
                    accent: accent,
                    onRestart: { session.restart() },
                    onMenu: { router.go(.home) }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.phase)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .bottom)
        .onChange(of: scenePhase) { _, phase in
            // Pause automatically when the app is backgrounded or interrupted.
            if phase != .active { session.pause() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
    }
}
