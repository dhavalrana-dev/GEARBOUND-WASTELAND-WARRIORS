# Development status

Updated: 2026-11-27 (Asia/Calcutta)

## Workspace audit
- Repository started empty; no existing game code, assets, Git metadata, or project instructions were present.
- Unity Editor 6000.3.27f1 is installed.
- Flutter 3.47.7 stable and Dart 3.13.5 are installed under `E:\flutter\bin` (verified from the SDK cache and Dart binary; Flutter launcher requires its SDK lockfile cache).
- `dotnet` CLI is unavailable in PATH. Unity's bundled compiler is used for Unity builds.

## Current milestone
- **GB-052 mission lifecycle on `feature/mission-lifecycle`.** Adds a gameplay pause menu (Resume; Abandon with confirmation), auto-pause when the app is hidden during combat (it never auto-resumes), system Back routed to the pause menu once a mission has started, and a 0.25 s per-frame catch-up cap.
- **GB-025 multi-wave missions on `feature/workshop-drag-undo`** (same branch as GB-039, uncommitted). `BattleSession` supports waves with an intermission in both engines. Route node `copperwash-01` is now the 3-wave shared mission `copperwash_01`; wave 1 is identical to the old encounter. Each intermission pays the wave reward in battle scrap, rolls fresh offers and reopens the workshop.
- **GB-039 on `feature/workshop-drag-undo`.** The workshop has drag-and-drop with a ghost and a live target preview (green powered, amber unpowered, red invalid), moving placed gears, and undo for place, move, merge and sell. Undoing a sale charges the refund back through the ledger. Buys and rerolls are not undoable. The selected gear shows its status: power, lane and spawn interval.
- **Production art direction v2 and the 19-phase roadmap applied on `docs/production-art-and-roadmap`** (stacked on PR #4). Added the 316-record vertical-slice asset manifest, all `planned`; no art exists and no art gate has started. Started roadmap P0 #1: the Android toolchain is diagnosed in `docs/TOOLCHAIN_REPORT.md`, and the fix is blocked on you.
- **GB-030/GB-031 on `feature/workshop-shop-ui`.** The workshop now has a real gear shop: buy, tap-to-place, merge, sell and reroll with mission-scoped battle scrap through the ledger. `gearbound_app.dart` is split into `features/campaign`, `features/workshop` and `design_system`. The demo-only MOVE PRESS and rotate controls are removed.
- **Extension spec, Phase A (audit) and Phase B (economy foundation) done on `feature/progression-economy-foundation`.** See `docs/REPOSITORY_AUDIT.md`. This work added the ledger-backed wallet (Dart + C#), save v3 with v1/v2 migration, a two-slot store with corruption recovery, a clock-rollback guard, the ad policy engine (Dart + C#) and the mock-provider rewarded controller (Dart). The `AGENTS.md` monetization policy was revised.
- Phase 0 foundation completed for shared rules: `xorshift32-v1` RNG, seeded gear shop, data-driven wave director and enemy archetypes in both engines, all checked against independent fixtures.
- Phase 1: campaign route slice and replay layer. This session added Overclock Streak, star chests, the Supply Log and Vanguard Drop boosters (Flutter).
- Phase 1 (earlier): campaign route slice and replay layer.
- Shared rules and Unity/Dart implementations cover gear power, merge behavior, capped output clocks, combat, and battle-session outcomes.
- Flutter/Flame now has a route hub, twelve progressive nodes, health-based stars, local save data, daily contracts, a weekly best-score event, and a playable workshop/battle screen. The first five nodes have hand-authored spawn timings and roles; later encounters use deterministic scaling.

## Verification ledger
### 2026-11-27 session 9 (mission lifecycle)
- Flutter analyze: no issues. Flutter tests: **147/147**. `mission_lifecycle_test.dart` adds 9 tests: pause and resume, background during combat versus preparation, the stall cap (a 10 s stall becomes at most 8 ticks), Back before and during a mission, abandon with confirmation, rotation mid-combat, and victory recorded once.
- Validator, reference fixtures, asset sync and combat traces: clean. Unity EditMode: **not re-run** (no C# or shared data changed; last result 35/35).
- **Bugs found:**
  1. **Streak exploit:** system Back mid-battle left the screen without recording anything, so a losing player could keep their Overclock Streak. Back now opens the pause menu, and abandoning resets the streak.
  2. **Rotation paused the game and crashed in a widget test:** switching layouts disposed and rebuilt the Flame `GameWidget`, and Flame reports disposal as an app pause (`lifecycleStateChange(paused)`), which triggered `setState` while the tree was locked. Fixed with a `GlobalKey` on the game widget, so it moves instead of rebuilding, and by pausing on Flutter's `AppLifecycleListener.onHide` instead of Flame's hook.
  3. **No cap on catch-up:** after a stall, the loop fast-forwarded every missed tick in one frame. It is now capped at 0.25 s per frame.
- **Not done:** restoring a mission after the OS kills the app (GB-053), and device verification.

### 2026-11-27 session 8 (multi-wave missions)
- Flutter analyze: no issues. Flutter tests: **138/138**. Unity EditMode: **35/35** (adds 5 multi-wave tests). Validator, reference fixtures, asset sync and combat traces: clean, so the traces are unchanged and single-wave sessions behave exactly as before.
- **Design decisions made from measurements** (headless balance probes, later turned into tests):
  1. **Soldiers withdraw at each intermission**, while the hero and fortress damage stay. When soldiers carried over, every later wave was trivial (full fortress at any tuning).
  2. **The hero returns to the fortress line** at intermission, keeping health and lane, so each wave starts from the same position.
- **Bug found: shop RNG bias for small seeds.** Across seeds 1–500 there were only 5 distinct openings, and slot 0 was always the Ratchet Booster: xorshift32's first output for a small seed is tiny, and multiply-shift maps it to index 0. Fixed by deriving the workshop seed with murmur3 `fmix32` (`mixSeed32`). The shared `xorshift32-v1` contract and its fixtures are unchanged. Openings now offer a press 420/500 times, and a press is reachable within rerolls 499/500 times.
- **Balance of node 1** (`mission_balance_test.dart`):
  - The starter board with an idle hero loses wave 1.
  - One bought press plus moving the hero to the open lane wins wave 1 at 100.
  - Covering both side lanes clears all three waves at 100. Node 1 is gentle on purpose; a wave-3 sweep showed pressure is bursty (lanes hold or collapse) and was recorded for GB-051.
- **Test gap found:** the Flutter asset drift test listed files explicitly and missed the new mission, so a stale bundled copy passed. Fixed by adding it to the list (verified to fail on the stale copy first).
- **Not verified:** device play, and multi-wave feel or pacing with real players.

### 2026-11-27 session 7 (workshop drag and undo)
- Flutter analyze: no issues. Flutter tests: **120/120**. Adds 12 controller tests (move, merge-by-drag, core refusal, undo order, undo merge and sell, refund-spent refusal, no undo for reroll, hand-full refusal, lock, previews) and 2 widget tests, including a **real pointer drag through Flame's gesture system**.
- **Bugs found by the new tests:**
  1. Dropping a gear on the power core reported success and did nothing; it is now refused.
  2. The drag position ran ahead of the finger by the full delta, because Flame 1.38's `DragUpdateEvent.localEndPosition` double-counts the move. The view now accumulates `localDelta`. Only the pointer-level test caught this.
- Validator, reference fixtures, asset sync and combat traces: clean. Unity EditMode: **not re-run** (no C# or shared data changed; last result 30/30).
- **Not verified:** touch feel on a real device; the Android build is still blocked (GB-038).

### 2026-11-27 session 6 (art direction, roadmap, toolchain)
- `flutter doctor -v`: **Android toolchain not usable: "Unable to locate Android SDK".** The only SDK is Unity's bundled one, which has no `licenses/` folder and NDK 27.2 instead of the 28.2.13676358 that Flutter 3.47.7 requests (confirmed in the Flutter Gradle plugin source). No build was attempted and no license was accepted. See `TOOLCHAIN_REPORT.md`.
- Shared data validator: passes with the new asset manifest. It was also run against a scratch copy holding an "approved" asset with no evidence and an unknown owner: it **failed as intended** with 4 errors.
- Flutter analyze: no issues. Flutter tests: **106/106**. Reference fixtures, asset sync and combat traces: clean. Unity EditMode: **not re-run**, because no C# and no Unity-read data changed (last result 30/30, session 5).

### 2026-11-27 session 5 (workshop shop UI)
- Flutter analyze: no issues. Flutter tests: **106/106**. That adds 12 controller tests and 6 shop UI tests: the buy/place/sell/lock flow, fallback without shared content, tap-to-cell mapping, and overflow checks at three screen sizes. The 88 earlier tests pass unchanged after the module split.
- **The overflow tests found real layout bugs.** The workshop overflowed by 284 px in phone landscape and by 88 px on a small portrait phone. It is fixed with scrollable control areas.
- Unity EditMode: **30/30** (re-run because `gear_rules.json` changed). Shared data validator, reference fixtures, asset sync and combat traces: clean.
- **Not verified:** the shop has not been played on a real device or emulator, and drag-and-drop is not implemented (taps only).

### 2026-11-27 session 4 (audit + economy foundation)
- **Baseline at `931f875` before changes:** Unity 28/28. Flutter analyze clean. Flutter tests **1 failure**: assets differed from `shared/` only in line endings, caused by `core.autocrlf` with no `.gitattributes`. Fixed by adding `.gitattributes`; Flutter returned to 44/44.
- **After this session's work:** Unity EditMode **30/30** (adds ledger and ad-policy parity). Flutter analyze clean. Flutter tests **88/88** (44 before this session, plus wallet, migration, store, clock-guard and ad-policy tests). Validator, reference fixtures, asset sync and combat traces all clean.
- All 44 pre-existing Flutter tests still pass unchanged after `CampaignProgress` moved onto the ledger.
- **Not done:** no real ad or purchase SDK and no consent flow. `ad_policy.json` `enabled` is false. Mock providers report `isLive == false`.

### 2026-11-27 session 3 (combat parity, widget tests, shared assets)
- **Cross-engine combat parity (spec scenario 4): verified for 4 scenarios.** `tools/simulation/generate_combat_traces.ps1` compiles the Unity Core sources with Unity's bundled Mono and writes `combat_traces.json`. The Dart runner reproduces every per-tick FNV-1a trace hash, checkpoint and outcome exactly, covering 2 victories, 2 defeats, a boss wave, boosters, an unpowered gear and hero lane commands. Unity replays the same file in-editor.
- Unity EditMode: **passed, 28/28**. Flutter analyze: no issues. Flutter tests: **passed, 44/44** (adds 3 widget tests, 3 shared-content tests and 1 combat-parity test).
- The widget tests exercise the hub rewards card (Supply Log claim, star chest) and the workshop Vanguard toggle. That is test-harness rendering only; the UI is still not checked on a real device or emulator.
- Validator, `reference_rules.py --check`, `sync_flutter_shared.py --check` and `generate_combat_traces.ps1 -Check`: all pass.
- Unity Core no longer uses C# 8 switch expressions, so it compiles with both Unity's compiler and Mono `mcs`.

### 2026-11-27 session 2 (shared rules + gamification)
- Unity Test Framework EditMode: **passed, 27/27** (`artifacts/unity-editmode.xml`, Unity 6000.3.27f1 batchmode, ~26 s warm). It includes 7 shared-rule tests that replay the Python-generated fixtures. The first cold run passed 20/20 in 78 s; the earlier 120 s timeout was a tool limit, not a hang.
- One new Unity test initially failed in a useful way. On shared mission wave 1, a single press feeding lane 1 with an idle hero **loses**, because raiders in lanes 0 and 2 go unopposed. This is kept as an intended-pressure test, and covering lanes 0 and 2 wins.
- Flutter analyze: no issues. Flutter tests: **passed, 37/37** (adds 3 shared-rule parity tests and 9 gamification tests).
- `python -I tools/data-validation/validate_shared.py`: passed. `python -I tools/simulation/reference_rules.py --check`: fixtures up to date.
- **Not verified:** the new hub rewards card and workshop loadout bar have not been rendered on a device or emulator, and there are no widget tests for them yet.

### 2026-11-27 session 1
- Unity `projects verify`: passed, 48 files scanned, zero errors/warnings.
- Standalone C# runtime smoke checks: passed, 16 checks compiled and run using Unity's bundled Mono compiler/runtime.
- Unity Test Framework EditMode run: timed out after 120 seconds (superseded by session 2 above).
- Unity player build: not attempted.
- Flutter analysis: passed with no issues.
- Flutter tests: passed, 25 tests across gear network, gear output, combat simulation, battle-session outcomes, campaign unlocks, daily task resets, weekly score caps, save serialization, and authored encounter data.
- Flutter web build: not configured for this project.
- Android APK build: blocked by unaccepted NDK 28.2.13676358 SDK license in the only installed Android SDK; no license was accepted.
- iOS build: unavailable on this Windows host.
- Device performance: not measured.

## Decisions
- Initial production project uses Unity 6.3 LTS as the reference engine.
- Cross-engine determinism will be defined in shared fixtures after the core simulation contract stabilizes.
- Reference study currently relies on official store descriptions and linked public gameplay pages; no screenshot capture or hands-on install was available during this workspace audit.
- The Unity CLI 1.0.1 self-update check could not reach Unity's public CDN. The CLI reports 1.1.0 is available, but its notification explicitly requires user approval before updating.
- Flame 1.38.2 is resolved in the Flutter app and its current `FlameGame`, `World`, `CameraComponent`, and `GameWidget` APIs compile under Flutter analysis.
- Flutter UI wiring now starts the first wave, shows current phase/enemy count, locks workshop edits during combat, and allows the hero to change lanes.
- Flutter Android packaging remains blocked until the Android SDK/NDK license is accepted; no license was accepted in this session. iOS packaging requires a macOS host.
- The campaign prototype is committed (`6ca78c0`); session 2 work is uncommitted until reviewed.
- Shared JSON is loaded in Unity through a small dependency-free reader (`SharedJson.cs`), not a package, which keeps `Gearbound.Core` engine-independent.
- Flutter now bundles runtime shared JSON under `flutter/assets/shared` (synced by `tools/build/sync_flutter_shared.py`; a test fails on drift). Route node `copperwash-01` loads its wave from `shared/missions/campaign_route.json` → `mission_001.json` `wave.1`, with a test showing the spawns are identical to the old script. The other 11 nodes still use `encounters.dart`.
- Gamification is earn-only and offline: see `docs/GAMIFICATION_AND_EVENTS.md`.
- Campaign and Scrapstorm state save locally through `shared_preferences`; balance playtests, widget-level interaction tests, and mobile-device validation are still outstanding.
