import SwiftUI

@main
struct LumenDriftApp: App {
    @StateObject private var store = ProgressStore()
    @StateObject private var router = AppRouter()

    init() {
        AudioManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .preferredColorScheme(.dark)
        }
    }
}
