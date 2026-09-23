import UIKit

/// Thin wrapper over UIKit feedback generators with named, game-specific patterns.
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

    private init() {}

    func prepare() {
        guard enabled else { return }
        light.prepare()
        rigid.prepare()
        heavy.prepare()
    }

    func tap() { if enabled { soft.impactOccurred(intensity: 0.8) } }
    func select() { if enabled { selection.selectionChanged() } }
    func spark() { if enabled { light.impactOccurred(intensity: 0.55) } }
    func nearMiss() { if enabled { rigid.impactOccurred(intensity: 0.7) } }
    func combo() { if enabled { medium.impactOccurred(intensity: 0.9) } }
    func powerUp() { if enabled { notification.notificationOccurred(.success) } }
    func shieldBreak() { if enabled { heavy.impactOccurred(intensity: 0.8) } }
    func crash() { if enabled { heavy.impactOccurred(intensity: 1) ; notification.notificationOccurred(.error) } }
    func success() { if enabled { notification.notificationOccurred(.success) } }
    func denied() { if enabled { notification.notificationOccurred(.warning) } }
}
