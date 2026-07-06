# PushBoss — RPG Push-Up Fitness App
### Full Technical & Product Blueprint for Claude Code

---

## 1. Concept Summary

PushBoss is an iOS fitness app that gamifies push-ups by turning each rep into combat against RPG-style enemies (slimes, goblins, skeletons, bosses). The app uses the phone's camera and on-device pose detection to count reps in real time, then maps every rep to in-game damage, XP, and progression (dungeons, ranks, boss fights).

**Core loop:** Open app → place phone on floor → select a "Dungeon"/enemy → camera tracks push-up form → each valid rep deals damage to the enemy's HP bar → enemy defeated → XP/loot/rank progress → next dungeon unlocks.

---

## 2. Tech Stack Recommendation

| Layer | Recommendation | Why |
|---|---|---|
| Platform | iOS first (SwiftUI) | Matches reference app; can add Android (Kotlin/Compose) in phase 2 |
| Pose detection | Apple Vision framework — `VNDetectHumanBodyPoseRequest` | Built-in, on-device, free, no model training needed, real-time, privacy-friendly (no camera upload) |
| Camera capture | AVFoundation (`AVCaptureSession`) | Standard for real-time frame processing |
| Rep-counting logic | Custom Swift state machine on elbow-angle + shoulder/hip alignment | Explained in detail in Section 4 |
| UI | SwiftUI | Fast to build, good animation support for HP bars/level-ups |
| Game state / data | Core Data or SwiftData (iOS 17+) | Local persistence of stats, XP, unlocked dungeons |
| Cloud sync (optional, phase 2) | CloudKit or Firebase | iCloud sync of progress across devices |
| Backend (optional, for leaderboards/PvP) | Firebase (Firestore + Auth) or Supabase | Cheapest/fastest way to add global leaderboards |
| Subscriptions | StoreKit 2 | Native, required for App Store IAP/subscriptions |
| Art assets | AI-generated (Midjourney/DALL·E) or licensed asset packs (itch.io, Kenney.nl) for monsters/dungeon backgrounds | Keep cost low at MVP stage; replace with commissioned art later if budget allows |
| Analytics | TelemetryDeck or Firebase Analytics | Lightweight, privacy-respecting options |

---

## 3. Project Structure (suggested for Claude Code to scaffold)

```
PushBoss/
├── PushBossApp.swift
├── Core/
│   ├── PoseTracking/
│   │   ├── PoseDetector.swift          # Vision framework wrapper
│   │   ├── PushUpRepCounter.swift      # State machine: up/down/rep validation
│   │   └── CameraManager.swift         # AVCaptureSession setup
│   ├── GameEngine/
│   │   ├── Enemy.swift                 # Enemy model (HP, level, sprite, attack flavor text)
│   │   ├── Dungeon.swift               # Sequence of enemies + difficulty curve
│   │   ├── BattleManager.swift         # Maps reps → damage → HP updates → win/lose state
│   │   └── PlayerProgress.swift        # XP, level, rank, stats, achievements
│   └── Persistence/
│       ├── DataStore.swift             # SwiftData/CoreData stack
│       └── Models.swift                # Persistent entities
├── Features/
│   ├── Home/                           # Dashboard: rank, stats, dungeon selector
│   ├── Battle/                         # Camera view + HP bar + skeleton overlay
│   ├── DungeonMap/                     # Campaign mode progression map
│   ├── Stats/                          # Total reps, PRs, history charts
│   ├── Achievements/
│   ├── Paywall/                        # StoreKit subscription screen
│   └── Onboarding/
├── Resources/
│   ├── Assets.xcassets/                # Enemy sprites, icons, sounds
│   └── Sounds/                         # Hit SFX, victory fanfare, music
└── Tests/
    ├── PushUpRepCounterTests.swift
    └── BattleManagerTests.swift
```

---

## 4. Core Mechanic — Pose Detection & Rep Counting (the hardest part)

This is the part that makes or breaks the app. Detail to give Claude Code:

**4.1 Pipeline**
1. `AVCaptureSession` streams camera frames (front or back camera, user-selectable).
2. Each frame is passed to `VNDetectHumanBodyPoseRequest`.
3. Extract key joints: `leftShoulder`, `rightShoulder`, `leftElbow`, `rightElbow`, `leftWrist`, `rightWrist`, `leftHip`, `rightHip`.
4. Compute the **elbow angle** (angle between shoulder–elbow–wrist vector) for both arms, averaged.
5. Compute a **body-line straightness score** (shoulder–hip alignment) to penalize sagging/piking form — used for "form bonus" scoring, not required for MVP.

**4.2 Rep state machine**
```
States: WAITING_FOR_DOWN → AT_BOTTOM → WAITING_FOR_UP → REP_COMPLETE

- WAITING_FOR_DOWN: elbow angle decreasing, crosses below ~90° threshold → AT_BOTTOM
- AT_BOTTOM: hold for minimum N frames to avoid false positives from fast bouncing → WAITING_FOR_UP
- WAITING_FOR_UP: elbow angle increasing, crosses above ~160° threshold → REP_COMPLETE → increment rep count, reset to WAITING_FOR_DOWN
```
Add debounce/smoothing (rolling average over last 3–5 frames) to avoid jitter from noisy joint detection.

**4.3 Edge cases to handle**
- User not fully in frame → show "move back" warning, pause tracking.
- Poor lighting → Vision confidence score per joint; if below threshold, ignore frame.
- Partial reps (not going low enough) → don't count, optionally show "go lower!" feedback.
- Camera angle (phone propped vs. on the floor) → calibration step in onboarding asking user to do 1 test rep.

**4.4 Privacy**
All processing must happen on-device. No video frames should be uploaded or stored — only the resulting rep counts/stats. State this clearly in the privacy policy and App Store privacy labels.

---

## 5. Game Design

**5.1 Enemies**
Each enemy = `{name, spriteAsset, maxHP, hpPerRep, levelRequirement, flavorTaunts: [String], deathLine: String}`

Example progression (mirrors reference app's tone):
| Tier | Enemy | HP | Reps to defeat (approx) |
|---|---|---|---|
| 1 | Slime | 50 | 5 |
| 2 | Goblin | 70 | 7 |
| 3 | Skeleton | 90 | 9 |
| 4 | Mummy | 120 | 12 |
| 5 (Boss) | Dungeon Boss | 250 | 25 |

**5.2 Modes**
- **Campaign Mode** — linear dungeons (10+), each ending in a boss fight, difficulty scales.
- **Ranks** — ELO-like ladder (Bronze → Silver → Gold → Champion) based on best single-session rep count or weekly volume.
- **Speed Challenge** — timed mode, max reps in 60 seconds.
- **Horde Mode** — endless waves, HP scales infinitely, track survival rep count.
- **Max Reps Mode** — single set to failure, just logs a PR.

**5.3 Progression systems**
- XP per rep → player level → unlocks cosmetic skins/themes for the camera overlay.
- Achievements (first rep, 100 total reps, first boss kill, 7-day streak, etc.).
- Daily streak tracking with push notification reminders (opt-in).

---

## 6. Monetization

- **Free tier:** first 1–2 dungeons, basic stats, daily streak.
- **Subscription (StoreKit 2, auto-renewing):** unlocks full campaign, Horde Mode, Speed Challenges, detailed stats/history, all achievements.
- Recommend a 3-day free trial to reduce paywall friction (the reference app's reviews show users are frustrated by an immediate hard paywall — avoid that mistake).
- Use `StoreKit 2`'s `Transaction.currentEntitlements` for clean subscription-state checks, and `SubscriptionStoreView` (iOS 17+) to cut custom paywall UI work.

---

## 7. Screens / UI Flow

1. **Onboarding** — permission requests (camera), 1-rep calibration, account creation (optional, Sign in with Apple).
2. **Home Dashboard** — current rank, level, daily streak, "Enter Arena" CTA, dungeon map preview.
3. **Dungeon Map** — visual node-based map (like the reference app's "Bone Temple" screenshots) showing locked/unlocked enemies.
4. **Battle Screen** — full-screen camera feed, skeleton overlay (optional toggle), enemy sprite + HP bar top, rep counter, timer (if relevant mode).
5. **Victory/Defeat screen** — XP gained, loot/achievement unlocks, "Next Dungeon" CTA.
6. **Stats Screen** — charts (reps over time), personal bests, dungeons cleared.
7. **Achievements Screen** — grid of unlockable badges.
8. **Paywall** — triggered after free content exhausted.
9. **Settings** — camera selection, sound, notifications, manage subscription, privacy policy link.

---

## 8. MVP Scope (what to build first with Claude Code)

To keep the first build achievable, scope the MVP to:
1. Camera + pose detection + rep counter (core risk — build and test this first, in isolation, before any game UI).
2. One battle screen with one enemy type, HP bar tied to rep count.
3. Basic XP/level system, stored locally (SwiftData).
4. 3–5 dungeon nodes in a simple linear map.
5. Stats screen (total reps, best session).
6. No backend, no leaderboards, no subscriptions yet — validate the core mechanic feels good before adding monetization/infrastructure.

**Suggested build order for Claude Code sessions:**
1. Xcode project scaffold + camera permission + raw Vision pose overlay (prove tracking works).
2. Rep-counting state machine + unit tests with recorded sample angle sequences.
3. Battle screen UI wired to rep counter (enemy HP decreases live).
4. Persistence layer (XP, stats).
5. Dungeon map + progression unlocking.
6. Polish pass: animations, sound effects, haptics on each rep/hit.
7. StoreKit paywall (only after core loop is fun and tested).

---

## 9. Differentiation Ideas (to avoid being a pure clone)

Since several apps already exist in this space (Push Up Arena, Pushup Arena, PushArena, Push Up Counter: Arena), consider picking at least one differentiator:
- **Real PvP** — live camera battles against another player's rep speed (reference apps mostly fake this with leaderboards, not live).
- **Form-quality scoring** — reward proper depth/back alignment, not just rep count, using the body-line straightness score from Section 4.1.
- **Multi-exercise support** — squats, sit-ups, planks, not just push-ups, using the same pose-tracking core.
- **Friendlier monetization** — free trial instead of hard paywall (the reference app's user reviews specifically complain about this).
- **Hand-illustrated or stylized 2D art** instead of generic AI art (also called out negatively in reviews of the reference app).

---

## 10. What to Tell Claude Code (example first prompt)

> "Set up a new SwiftUI iOS app called PushBoss targeting iOS 17+. First, implement camera capture with AVFoundation and real-time body pose detection using Vision's VNDetectHumanBodyPoseRequest. Display the detected joints as an overlay on the camera feed. Then build a PushUpRepCounter state machine that tracks elbow angle to detect down/up rep cycles, with debouncing to avoid false positives. Write unit tests for the rep counter using mock angle sequences before touching any UI."

Build incrementally — one module per session — and have Claude Code write tests for the rep-counting logic specifically, since that's the hardest part to get right empirically (camera angle, lighting, and body type variation).

---

## 11. Legal / Store Notes

- App Store privacy nutrition label must disclose camera usage and confirm no video data leaves the device (if true).
- If adding any AI-generated art, no special disclosure required by Apple currently, but be aware of evolving App Store guidelines on AI content.
- Trademark check: avoid naming your app identically to "Push Up Arena" or close enough to cause App Store confusion/rejection — Apple does review for this.
