import Foundation

/// Every unlockable in the game. Everything is defined locally; nothing is downloaded.
enum Catalog {
    static let skins: [OrbSkin] = [
        OrbSkin(id: "nova", name: "Nova", core: 0x4DF3FF, glow: 0x4DF3FF, shape: .circle, requirement: .free),
        OrbSkin(id: "ember", name: "Ember", core: 0xFF7A3D, glow: 0xFF9A3D, shape: .circle, requirement: .coins(150)),
        OrbSkin(id: "orchid", name: "Orchid", core: 0xFF4D9D, glow: 0xFF4DD2, shape: .diamond, requirement: .coins(300)),
        OrbSkin(id: "volt", name: "Volt", core: 0x9DFF4D, glow: 0x6BFF4D, shape: .hexagon, requirement: .level(3)),
        OrbSkin(id: "halo", name: "Halo", core: 0xFFE9A8, glow: 0xFFD24D, shape: .ring, requirement: .coins(600)),
        OrbSkin(id: "nebula", name: "Nebula", core: 0xA67BFF, glow: 0x8A5CFF, shape: .star, requirement: .level(6)),
        OrbSkin(id: "prism", name: "Prism", core: 0xF4FBFF, glow: 0x9DE7FF, shape: .diamond, requirement: .coins(1200)),
        OrbSkin(id: "eclipse", name: "Eclipse", core: 0x3A1D5C, glow: 0xFF4D9D, shape: .circle, requirement: .level(10)),
    ]

    static let trails: [TrailStyle] = [
        TrailStyle(id: "stream", name: "Stream", colors: [], particle: .glow,
                   birthRate: 110, lifetime: 0.45, scale: 0.34, spread: 0.12, requirement: .free),
        TrailStyle(id: "embers", name: "Embers", colors: [0xFFD24D, 0xFF5A1F], particle: .spark,
                   birthRate: 70, lifetime: 0.55, scale: 0.55, spread: 0.7, requirement: .coins(200)),
        TrailStyle(id: "aurora", name: "Aurora", colors: [0x5CFFB0, 0x4DF3FF, 0xA67BFF], particle: .glow,
                   birthRate: 130, lifetime: 0.6, scale: 0.4, spread: 0.25, requirement: .level(4)),
        TrailStyle(id: "comet", name: "Comet", colors: [0xFFFFFF, 0x9DE7FF], particle: .glow,
                   birthRate: 220, lifetime: 0.3, scale: 0.6, spread: 0.05, requirement: .coins(400)),
        TrailStyle(id: "pixel", name: "Pixel", colors: [0x9DFF4D, 0x4DF3FF, 0xFF4D9D], particle: .pixel,
                   birthRate: 60, lifetime: 0.6, scale: 0.9, spread: 0.5, requirement: .coins(700)),
        TrailStyle(id: "spectrum", name: "Spectrum", colors: [0xFF4D4D, 0xFFB84D, 0xFFF04D, 0x5CFF8A, 0x4DD2FF, 0xA67BFF],
                   particle: .glow, birthRate: 150, lifetime: 0.7, scale: 0.42, spread: 0.2, requirement: .level(8)),
    ]

    static let themes: [WorldTheme] = [
        WorldTheme(id: "abyss", name: "Abyss", top: 0x0B1030, bottom: 0x03040A, obstacle: 0x5B8CFF, accent: 0x4DF3FF, requirement: .free),
        WorldTheme(id: "synth", name: "Synthwave", top: 0x2A0B4A, bottom: 0x0A0314, obstacle: 0xFF4D9D, accent: 0xFFB84D, requirement: .coins(250)),
        WorldTheme(id: "glacier", name: "Glacier", top: 0x0A2E3A, bottom: 0x02090D, obstacle: 0x7DF9FF, accent: 0xB6FFEA, requirement: .level(5)),
        WorldTheme(id: "inferno", name: "Inferno", top: 0x3A0A0A, bottom: 0x0C0202, obstacle: 0xFF6A3D, accent: 0xFFD24D, requirement: .coins(800)),
        WorldTheme(id: "aurora", name: "Aurora", top: 0x0B2A24, bottom: 0x05030F, obstacle: 0x9D6BFF, accent: 0x5CFFB0, requirement: .level(12)),
    ]

    static func skin(_ id: String) -> OrbSkin { skins.first { $0.id == id } ?? skins[0] }
    static func trail(_ id: String) -> TrailStyle { trails.first { $0.id == id } ?? trails[0] }
    static func theme(_ id: String) -> WorldTheme { themes.first { $0.id == id } ?? themes[0] }

    static func items(for category: CosmeticCategory) -> [CosmeticItem] {
        switch category {
        case .skin:
            return skins.map { CosmeticItem(category: .skin, key: $0.id, name: $0.name, requirement: $0.requirement) }
        case .trail:
            return trails.map { CosmeticItem(category: .trail, key: $0.id, name: $0.name, requirement: $0.requirement) }
        case .theme:
            return themes.map { CosmeticItem(category: .theme, key: $0.id, name: $0.name, requirement: $0.requirement) }
        }
    }

    static var allItems: [CosmeticItem] {
        CosmeticCategory.allCases.flatMap { items(for: $0) }
    }

    static func ownedCount(_ progress: PlayerProgress) -> Int {
        allItems.filter { progress.isUnlocked($0) }.count
    }
}
