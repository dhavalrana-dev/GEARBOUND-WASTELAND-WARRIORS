# Development status

Updated: 2026-11-27 (Asia/Calcutta)

## Workspace audit
- Repository started empty; no existing game code, assets, Git metadata, or project instructions were present.
- Unity Editor 6000.3.27f1 is installed.
- Flutter 3.47.7 stable and Dart 3.13.5 are installed under `E:\flutter\bin` (verified from the SDK cache and Dart binary; Flutter launcher requires its SDK lockfile cache).
- `dotnet` CLI is unavailable in PATH. Unity's bundled compiler is used for Unity builds.

## Current milestone
- **Production art direction v2 and the 19-phase roadmap applied on `docs/production-art-and-roadmap`** (stacked on PR #4). Added the 316-record vertical-slice asset manifest, all `planned`; no art exists and no art gate has started. Started roadmap P0 #1: the Android toolchain is diagnosed in `docs/TOOLCHAIN_REPORT.md`, and the fix is blocked on you.
- **GB-030/GB-031 on `feature/workshop-shop-ui`.** The workshop now has a real gear shop: buy, tap-to-place, merge, sell and reroll with mission-scoped battle scrap through the ledger. `gearbound_app.dart` is split into `features/campaign`, `features/workshop` and `design_system`. The demo-only MOVE PRESS and rotate controls are removed.
- **Extension spec, Phase A (audit) and Phase B (economy foundation) done on `feature/progression-economy-foundation`.** See `docs/REPOSITORY_AUDIT.md`. This work added the ledger-backed wallet (Dart + C#), save v3 with v1/v2 migration, a two-slot store with corruption recovery, a clock-rollback guard, the ad policy engine (Dart + C#) and the mock-provider rewarded controller (Dart). The `AGENTS.md` monetization policy was revised.
- Phase 0 foundation completed for shared rules: `xorshift32-v1` RNG, seeded gear shop, data-driven wave director and enemy archetypes in both engines, all checked against independent fixtures.
- Phase 1: campaign route slice and replay layer. This session added Overclock Streak, star chests, the Supply Log and Vanguard Drop boosters (Flutter).
- Phase 1 (earlier): campaign route slice and replay layer.
- Shared rules and Unity/Dart implementations cover gear power, merge behavior, capped output clocks, combat, and battle-session outcomes.
- Flutter/Flame now has a route hub, twelve progressive nodes, health-based stars, local save data, daily contracts, a weekly best-score event, and a playable workshop/battle screen. The first five nodes have hand-authored spawn timings and roles; later encounters use deterministic scaling.

## Verification ledger
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
