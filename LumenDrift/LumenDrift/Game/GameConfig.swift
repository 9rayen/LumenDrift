import Foundation

/// Cosmetic setup for a game scene, fixed for the lifetime of one session.
struct GameConfig {
    let skin: OrbSkin
    let trail: TrailStyle
    let theme: WorldTheme
}

enum RowPattern: CaseIterable {
    case block, gate, slidingGate, twinGap, pulseBlocks
}
