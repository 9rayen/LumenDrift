import Foundation

/// Combined sound + haptic cues for UI interactions.
enum Feedback {
    static func button() {
        AudioManager.shared.play(.button)
        HapticsManager.shared.tap()
    }

    static func select() {
        AudioManager.shared.play(.button, rate: 1.2)
        HapticsManager.shared.select()
    }

    static func purchase() {
        AudioManager.shared.play(.purchase)
        HapticsManager.shared.success()
    }

    static func denied() {
        HapticsManager.shared.denied()
    }
}
