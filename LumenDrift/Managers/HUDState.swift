import Combine

/// Values that change many times per second during a run. Kept apart from `GameSession` so that
/// score ticks only re-render the HUD, not the whole game screen and its SpriteKit view.
final class HUDState: ObservableObject {
    @Published var score = 0
    @Published var multiplier = 1
    @Published var activePowerUps: [ActivePowerUp] = []

    func reset() {
        score = 0
        multiplier = 1
        activePowerUps = []
    }
}
