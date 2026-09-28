import QuartzCore
import UIKit

/// Thin wrapper over UIKit feedback generators with named, game-specific patterns.
/// Generators are re-armed with `prepare()` after each use so the Taptic Engine responds without delay.
final class HapticsManager {
    static let shared = HapticsManager()

    var enabled = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    /// Sparks arrive in quick lines; one tap per 70 ms feels crisp instead of buzzy.
    private let sparkInterval: CFTimeInterval = 0.07
    private var lastSpark: CFTimeInterval = 0

    private init() {}

    func prepare() {
        guard enabled else { return }
        light.prepare()
        rigid.prepare()
        medium.prepare()
        heavy.prepare()
    }

    func tap() { impact(soft, intensity: 0.8) }
    func select() { if enabled { selection.selectionChanged(); selection.prepare() } }
    func nearMiss() { impact(rigid, intensity: 0.7) }
    func combo() { impact(medium, intensity: 0.9) }
    func powerUp() { notify(.success) }
    func shieldBreak() { impact(heavy, intensity: 0.8) }
    func crash() { impact(heavy, intensity: 1); notify(.error) }
    func success() { notify(.success) }
    func denied() { notify(.warning) }

    func spark() {
        guard enabled else { return }
        let now = CACurrentMediaTime()
        guard now - lastSpark >= sparkInterval else { return }
        lastSpark = now
        impact(light, intensity: 0.55)
    }

    private func impact(_ generator: UIImpactFeedbackGenerator, intensity: CGFloat) {
        guard enabled else { return }
        generator.impactOccurred(intensity: intensity)
        generator.prepare()
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        notification.notificationOccurred(type)
        notification.prepare()
    }
}
