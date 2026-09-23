# Lumen Drift

A native, fully offline iPhone arcade game built with Swift, SwiftUI and SpriteKit.

Drag left or right anywhere on the screen to steer a glowing orb through falling glass barriers. Collect sparks, chain combos up to x8, brush past walls for near-miss bonuses, and grab power-ups. There's no login, no network access and no data collection. Progress is saved as JSON on the phone.

---

## 1. Requirements

| Item | Value |
|---|---|
| Xcode | **26 or newer** (the project uses Xcode 16+ folder syncing and Swift 6.2 default-actor-isolation settings) |
| Minimum iOS | **17.0** |
| Devices | iPhone only, portrait |
| Language | Swift (Swift 5 language mode) |
| Frameworks | SwiftUI, SpriteKit, AVFoundation, UIKit (haptics), Combine, Foundation. All ship with iOS. |
| Packages | **None.** No SPM, CocoaPods, Firebase, or network code. |
| Bundle ID (example) | `com.yourname.lumendrift`. Change `yourname` to something unique, e.g. `com.rayen.lumendrift` |

---

## 2. Folder structure

```
LumenDrift/
├── LumenDrift.xcodeproj            ← open this
└── LumenDrift/                     ← every file in here is compiled automatically
    ├── App/            LumenDriftApp.swift, RootView.swift, AppRouter.swift
    ├── Models/         Cosmetics, Catalog, PlayerProgress, Achievement, LevelSystem, PowerUpKind, RunResult
    ├── Persistence/    ProgressStore.swift            (JSON save in Application Support)
    ├── Managers/       GameSession.swift (SpriteKit ↔ SwiftUI bridge), Feedback.swift
    ├── Game/           GameScene(+Spawning, +Effects), DifficultyCurve, ScoreKeeper, GameConfig
    │   ├── Nodes/      PlayerNode, RowNode, BarNode, CollectibleNodes, BackdropNode
    │   └── Rendering/  TextureFactory (procedural art), EmitterFactory (particles)
    ├── Audio/          AudioManager.swift, SoundEffect.swift
    ├── Haptics/        HapticsManager.swift
    ├── Components/     GlassCard, Buttons, ThemedBackground, OrbView, LogoView, StatusPills, ConfettiView
    ├── Views/          Launch/, Home/, Game/ (HUD, Pause, GameOver), Customize/, Settings/, Achievements/
    ├── Extensions/     Color+Hex, Font+Display, Comparable+Clamped
    └── Resources/
        ├── Assets.xcassets   AppIcon (1024 px), AccentColor
        ├── Audio/            10 sound effects (.wav) + 2 music loops (.m4a)
        └── PrivacyInfo.xcprivacy   (declares no tracking and no data collected)
```

---

## 3. Open the project

1. Unzip `LumenDrift.zip` on your Mac, e.g. into `~/Developer/LumenDrift`.
2. Double-click **`LumenDrift.xcodeproj`**, or in Xcode choose **File ▸ Open…** and select it.
3. Wait for indexing to finish. The left sidebar shows the `LumenDrift` folder with all the groups above.

## 4. Choose your Apple ID / Development Team

1. **Xcode ▸ Settings… ▸ Accounts** → click **+** → **Apple ID** → sign in. A free Apple ID works.
2. In the Project navigator, click the blue **LumenDrift** project icon → select the **LumenDrift** target → **Signing & Capabilities** tab.
3. Leave **Automatically manage signing** checked.
4. **Team:** choose *Your Name (Personal Team)*, or your paid developer team.
5. **Bundle Identifier:** change `com.yourname.lumendrift` to something unique (e.g. `com.rayen.lumendrift`). If Xcode says the ID is unavailable, change it again.
6. The "Signing Certificate: Apple Development" error should clear on its own.

## 5. Connect your iPhone

1. Plug the iPhone into the Mac with a USB-C/Lightning cable, then unlock it.
2. Tap **Trust** on the phone when it asks "Trust This Computer?", and enter your passcode.
3. In Xcode open **Window ▸ Devices and Simulators** and wait until the phone shows as connected. The first time, Xcode copies debug symbols, which can take a few minutes.
4. Optional: tick **Connect via network** there to deploy wirelessly later.

## 6. Enable Developer Mode (iOS 16+)

1. After the phone has been connected to Xcode once, go to **Settings ▸ Privacy & Security** on the iPhone, scroll to the bottom, and tap **Developer Mode**.
   *If you don't see it, press Run once in Xcode (step 7). The option appears after Xcode first tries to install.*
2. Turn it **On** → **Restart**.
3. After the reboot, unlock the phone and tap **Turn On** at the prompt, then enter your passcode.

## 7. Build and install

1. In the Xcode toolbar, click the run-destination menu next to the scheme **LumenDrift** and pick **your iPhone**, not a simulator.
2. Press **⌘R** (the ▶ Run button).
3. **Free Apple ID only, first install:** the app installs but iOS blocks it with "Untrusted Developer". On the iPhone go to **Settings ▸ General ▸ VPN & Device Management** → tap your Apple ID under *Developer App* → **Trust** → **Trust**. Then press ▶ Run again or just tap the app icon.
4. The game launches. You can **stop Xcode and unplug the phone**. The app stays on your home screen and runs fully offline.

> **Free vs paid account:** apps signed with a free Personal Team expire after **7 days**. Reconnect and press Run to re-sign (your progress is kept). With a paid Apple Developer Program membership, a build lasts 1 year.

---

## 8. Replacing audio

All audio is local and lives in `LumenDrift/Resources/Audio/`. To replace a sound, drop in a file with **the same base name**. `.m4a`, `.mp3`, `.caf`, `.wav` and `.aiff` are all picked up automatically, and **m4a takes priority** over the others. Remove the old file so you don't have duplicates.

| File | Plays when |
|---|---|
| `music_menu` | Launch, home, customize, settings (loops) |
| `music_gameplay` | During a run (loops) |
| `sfx_button` | Any button tap |
| `sfx_spark` | Collecting a spark (pitch rises with the combo) |
| `sfx_combo` | Multiplier goes up |
| `sfx_near_miss` | Brushing past a barrier |
| `sfx_powerup` | Picking up a power-up |
| `sfx_shield_break` | The shield absorbs a hit |
| `sfx_hit` | Crash |
| `sfx_game_over` | Game-over screen |
| `sfx_new_best` | Game-over screen with a new high score |
| `sfx_purchase` | Unlocking a cosmetic |

A missing file is skipped silently, and the game never crashes over audio. Sound respects the ring/silent switch (`.ambient` session) and mixes with your own music.

## 9. Replacing art (optional)

Every visual is drawn in code, so the game never ships broken or missing art. To override it, add an image to `Assets.xcassets` with one of these names:

- `orb_<skinID>`: player orb, e.g. `orb_nova`, `orb_ember`, `orb_orchid`, `orb_volt`, `orb_halo`, `orb_nebula`, `orb_prism`, `orb_eclipse`. Use a square transparent PNG, with the orb taking up about 83% of the canvas.
- `background_<themeID>`: gameplay background, e.g. `background_abyss`, `background_synth`, `background_glacier`, `background_inferno`, `background_aurora`.
- The app icon is `Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`. Replace it with any 1024×1024 PNG that has no transparency.

---

## 10. Game design summary

- **Loop:** endless descent. Barrier rows scroll toward the orb, faster and faster.
- **Controls:** relative one-thumb drag anywhere. The orb follows your finger's movement, not its position, so your thumb never covers it.
- **Lose:** touch a barrier without a shield.
- **Score:** distance (scales with speed), plus sparks at +10 × multiplier, plus near-misses at +25 × multiplier. Each pickup chains the combo, every 5 chained pickups adds +1 to the multiplier (up to x8), and the chain breaks after 2.2 s without a pickup.
- **Difficulty:** speed eases from 300 to 840 pt/s. Rows get closer together and gaps narrower, and a new pattern family unlocks every 18 s (blocks → gates → sliding gates → twin gaps → pulsing blocks). Tune everything in `Game/DifficultyCurve.swift`.
- **Power-ups:** Shield (absorbs 1 hit, 10 s), Magnet (pulls sparks, 7 s), Slow-Mo (world at 55% speed, 5 s), Double (×2 score, 8 s).
- **Progression:** sparks are the currency, XP gives levels, and there are 8 orbs, 6 trails and 5 worlds to unlock (with sparks or by level) plus 12 achievements with spark rewards. Lifetime stats are tracked too.
- **Lifecycle:** the game auto-pauses when the app goes to the background or gets a call, and resumes only when you tap Resume.
