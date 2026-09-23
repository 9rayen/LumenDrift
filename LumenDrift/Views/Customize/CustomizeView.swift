import SwiftUI

struct CustomizeView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var category: CosmeticCategory = .skin
    @State private var pendingPurchase: CosmeticItem?
    @State private var shakeID: String?

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        let p = store.progress
        let theme = Catalog.theme(p.selectedTheme)
        let accent = Color(hex: theme.accent)

        ZStack {
            ThemedBackground(theme: theme)

            VStack(spacing: 16) {
                header(coins: p.coins)

                PreviewStage(
                    skin: Catalog.skin(p.selectedSkin),
                    trail: Catalog.trail(p.selectedTrail),
                    theme: theme
                )
                .frame(height: 190)

                CategoryPicker(selection: $category, accent: accent)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Catalog.items(for: category)) { item in
                            Button {
                                handleTap(item)
                            } label: {
                                CosmeticCard(item: item, state: store.state(of: item), accent: accent)
                                    .modifier(ShakeEffect(travel: shakeID == item.id ? 1 : 0))
                            }
                            .buttonStyle(PressableButtonStyle(pressedScale: 0.95))
                        }
                    }
                    .padding(.bottom, 30)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: category)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .alert(
            "Unlock \(pendingPurchase?.name ?? "")?",
            isPresented: Binding(
                get: { pendingPurchase != nil },
                set: { if !$0 { pendingPurchase = nil } }
            ),
            presenting: pendingPurchase
        ) { item in
            Button("Unlock") { buy(item) }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text(Self.priceMessage(for: item))
        }
    }

    private func header(coins: Int) -> some View {
        HStack {
            Button {
                Feedback.button()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(GlassBackground(shape: Circle()))
            }
            .buttonStyle(PressableButtonStyle(pressedScale: 0.88))
            .accessibilityLabel("Close")

            Spacer()
            Text("STYLE")
                .font(.display(22, .black))
                .tracking(5)
                .foregroundStyle(.white)
            Spacer()

            CoinPill(amount: coins)
        }
    }

    private static func priceMessage(for item: CosmeticItem) -> String {
        guard case .coins(let price) = item.requirement else { return "" }
        return "Spend \(price) sparks to unlock and equip it."
    }

    private func handleTap(_ item: CosmeticItem) {
        switch store.state(of: item) {
        case .equipped:
            HapticsManager.shared.select()
        case .owned:
            Feedback.select()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { store.select(item) }
        case .buyable(_, let affordable):
            if affordable {
                Feedback.button()
                pendingPurchase = item
            } else {
                deny(item)
            }
        case .locked:
            deny(item)
        }
    }

    private func buy(_ item: CosmeticItem) {
        if store.purchase(item) {
            Feedback.purchase()
        } else {
            deny(item)
        }
        pendingPurchase = nil
    }

    private func deny(_ item: CosmeticItem) {
        Feedback.denied()
        shakeID = nil
        withAnimation(.linear(duration: 0.4)) { shakeID = item.id }
        Task {
            try? await Task.sleep(for: .milliseconds(420))
            shakeID = nil
        }
    }
}

/// Horizontal shake used when an item can't be selected yet.
nonisolated struct ShakeEffect: GeometryEffect {
    var travel: CGFloat

    var animatableData: CGFloat {
        get { travel }
        set { travel = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(travel * .pi * 6), y: 0))
    }
}

private struct CategoryPicker: View {
    @Binding var selection: CosmeticCategory
    let accent: Color
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 6) {
            ForEach(CosmeticCategory.allCases) { category in
                let isSelected = category == selection
                Button {
                    Feedback.select()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = category }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.symbol)
                            .font(.system(size: 13, weight: .bold))
                        Text(category.title.uppercased())
                            .font(.display(13, .heavy))
                            .tracking(1)
                    }
                    .foregroundStyle(isSelected ? Color.black.opacity(0.85) : .white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(accent)
                                .shadow(color: accent.opacity(0.6), radius: 10)
                                .matchedGeometryEffect(id: "pill", in: namespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(GlassBackground(shape: Capsule()))
    }
}
