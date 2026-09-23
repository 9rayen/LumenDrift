import SwiftUI

struct PauseView: View {
    let accent: Color
    let onResume: () -> Void
    let onRestart: () -> Void
    let onSettings: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.35))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("PAUSED")
                    .font(.display(40, .black))
                    .tracking(8)
                    .padding(.leading, 8)
                    .foregroundStyle(.white)
                    .shadow(color: accent.opacity(0.6), radius: 16)
                    .padding(.bottom, 18)

                PrimaryButton(title: "RESUME", icon: "play.fill", accent: accent, action: onResume)
                SecondaryButton(title: "RESTART", icon: "arrow.clockwise", action: onRestart)
                SecondaryButton(title: "SETTINGS", icon: "gearshape.fill", action: onSettings)
                SecondaryButton(title: "MAIN MENU", icon: "house.fill", action: onMenu)
            }
            .padding(.horizontal, 36)
            .frame(maxWidth: 440)
        }
    }
}
