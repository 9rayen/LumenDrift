import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let unlocked = store.progress.achievements
        let accent = Color(hex: Catalog.theme(store.progress.selectedTheme).accent)
        let gold = Color(hex: 0xFFD24D)

        ZStack {
            LinearGradient(colors: [Color(hex: 0x10142A), Color(hex: 0x05060C)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AWARDS")
                                .font(.display(26, .black))
                                .tracking(4)
                                .foregroundStyle(.white)
                            Text("\(unlocked.count) of \(Achievement.all.count) unlocked")
                                .font(.display(13, .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        Spacer()
                        Button("Done") {
                            Feedback.button()
                            dismiss()
                        }
                        .font(.display(17, .bold))
                        .foregroundStyle(accent)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 6)

                    ForEach(Achievement.all) { achievement in
                        let done = unlocked.contains(achievement.id)
                        HStack(spacing: 14) {
                            Image(systemName: achievement.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(done ? .black.opacity(0.85) : .white.opacity(0.35))
                                .frame(width: 46, height: 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(done ? gold : .white.opacity(0.07))
                                )
                                .shadow(color: done ? gold.opacity(0.6) : .clear, radius: 8)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(achievement.title)
                                    .font(.display(16, .bold))
                                    .foregroundStyle(done ? .white : .white.opacity(0.6))
                                Text(achievement.detail)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                            if done {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(gold)
                            } else {
                                HStack(spacing: 3) {
                                    Image(systemName: "sparkle").font(.system(size: 10, weight: .black))
                                    Text("\(achievement.reward)").font(.display(13, .heavy))
                                }
                                .foregroundStyle(gold.opacity(0.8))
                            }
                        }
                        .padding(12)
                        .background(GlassBackground(shape: RoundedRectangle(cornerRadius: 20, style: .continuous)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .presentationDragIndicator(.visible)
    }
}
