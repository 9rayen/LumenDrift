import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var confirmReset = false

    var body: some View {
        let p = store.progress
        let accent = Color(hex: Catalog.theme(p.selectedTheme).accent)

        ZStack {
            LinearGradient(colors: [Color(hex: 0x10142A), Color(hex: 0x05060C)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack {
                        Text("SETTINGS")
                            .font(.display(26, .black))
                            .tracking(4)
                            .foregroundStyle(.white)
                        Spacer()
                        Button("Done") {
                            Feedback.button()
                            dismiss()
                        }
                        .font(.display(17, .bold))
                        .foregroundStyle(accent)
                    }
                    .padding(.top, 24)

                    GlassCard(padding: 6) {
                        VStack(spacing: 0) {
                            SettingToggleRow(icon: "music.note", title: "Music", subtitle: "Menu and gameplay soundtrack",
                                             tint: accent, isOn: binding(\.music))
                            divider
                            SettingToggleRow(icon: "speaker.wave.2.fill", title: "Sound Effects", subtitle: "Sparks, combos, impacts",
                                             tint: accent, isOn: binding(\.sfx))
                            divider
                            SettingToggleRow(icon: "iphone.radiowaves.left.and.right", title: "Haptics", subtitle: "Vibration feedback",
                                             tint: accent, isOn: binding(\.haptics))
                        }
                    }

                    GlassCard(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("LIFETIME")
                                .font(.eyebrow)
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.5))
                            HStack {
                                StatTile(title: "RUNS", value: p.totalGames.formatted())
                                StatTile(title: "SPARKS", value: p.totalSparks.formatted())
                                StatTile(title: "NEAR MISSES", value: p.totalNearMisses.formatted())
                            }
                        }
                    }

                    GlassCard(padding: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ABOUT")
                                .font(.eyebrow)
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Lumen Drift \(Self.version)")
                                .font(.display(18, .bold))
                                .foregroundStyle(.white)
                            Text("Plays 100% offline. No account, no ads, no tracking. Your progress is stored only on this iPhone.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Built with Swift, SwiftUI and SpriteKit.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SecondaryButton(title: "RESET PROGRESS", icon: "arrow.counterclockwise", role: .destructive) {
                        confirmReset = true
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .presentationDragIndicator(.visible)
        .alert("Reset all progress?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                store.resetProgress()
                HapticsManager.shared.denied()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Best score, sparks, level, achievements and unlocks will be erased. This can't be undone.")
        }
    }

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.07)).frame(height: 1).padding(.leading, 62)
    }

    private func binding(_ keyPath: WritableKeyPath<GameSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.progress.settings[keyPath: keyPath] },
            set: { newValue in
                store.updateSettings { $0[keyPath: keyPath] = newValue }
                HapticsManager.shared.select()
            }
        )
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}

private struct SettingToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isOn ? .black.opacity(0.85) : .white.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(isOn ? tint : .white.opacity(0.1)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.display(16, .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .tint(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .animation(.easeOut(duration: 0.2), value: isOn)
    }
}
