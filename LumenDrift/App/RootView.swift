import SwiftUI

/// Switches between the top-level screens and keeps audio/haptics in sync with settings.
struct RootView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch router.screen {
            case .launch:
                LaunchView { router.go(.home) }
                    .transition(.opacity)
            case .home:
                HomeView()
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.04)), removal: .opacity))
            case .game:
                GameContainerView(store: store)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: router.screen)
        .onChange(of: store.progress.settings, initial: true) { _, settings in
            AudioManager.shared.sfxEnabled = settings.sfx
            AudioManager.shared.musicEnabled = settings.music
            HapticsManager.shared.enabled = settings.haptics
        }
        .onChange(of: router.screen, initial: true) { _, screen in
            AudioManager.shared.playMusic(screen == .game ? .gameplay : .menu)
        }
        .onChange(of: scenePhase) { _, phase in
            AudioManager.shared.handleAppActive(phase == .active)
        }
    }
}
