# Development status

Updated: 2026-11-27 (Asia/Calcutta)

## Workspace audit
- Repository started empty; no existing game code, assets, Git metadata, or project instructions were present.
- Unity Editor 6000.3.27f1 is installed.
- Flutter 3.47.7 stable and Dart 3.13.5 are installed under `E:\flutter\bin` (verified from the SDK cache and Dart binary; Flutter launcher requires its SDK lockfile cache).
- `dotnet` CLI is unavailable in PATH. Unity's bundled compiler is used for Unity builds.

## Current milestone
- Phase 0 foundation completed for shared rules: `xorshift32-v1` RNG, seeded gear shop, data-driven wave director and enemy archetypes in both engines, all checked against independent fixtures.
- Phase 1: campaign route slice and replay layer. This session added Overclock Streak, star chests, the Supply Log and Vanguard Drop boosters (Flutter).
- Phase 1 (earlier): campaign route slice and replay layer.
- Shared rules and Unity/Dart implementations cover gear power, merge behavior, capped output clocks, combat, and battle-session outcomes.
- Flutter/Flame now has a route hub, twelve progressive nodes, health-based stars, local save data, daily contracts, a weekly best-score event, and a playable workshop/battle screen. The first five nodes have hand-authored spawn timings and roles; later encounters use deterministic scaling.

## Verification ledger
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
- Shared JSON is loaded in Unity through a small dependency-free reader (`SharedJson.cs`), not a package, which keeps `Gearbound.Core` engine-independent. Flutter tests read `../shared` directly. Bundling shared JSON as Flutter runtime assets is still a todo, so the Flutter campaign still uses `encounters.dart` for its waves.
- Gamification is earn-only and offline: see `docs/GAMIFICATION_AND_EVENTS.md`.
- Campaign and Scrapstorm state save locally through `shared_preferences`; balance playtests, widget-level interaction tests, and mobile-device validation are still outstanding.
