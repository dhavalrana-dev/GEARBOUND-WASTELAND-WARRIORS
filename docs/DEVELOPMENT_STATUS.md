# Development status

Updated: 2026-11-28 (Asia/Calcutta)

## Workspace audit
- Repository started empty; no existing game code, assets, Git metadata, or project instructions were present.
- Unity Editor 6000.3.27f1 is installed.
- Flutter 3.47.7 stable and Dart 3.13.5 are installed under `E:\flutter\bin` (verified from the SDK cache and Dart binary; Flutter launcher requires its SDK lockfile cache).
- `dotnet` CLI is unavailable in PATH. Unity's bundled compiler is used for Unity builds.

## Current milestone
- **In progress on `feature/unity-workshop-controller` (uncommitted):** GB-036/GB-049 Unity workshop rules with the shared `workshop_cases.json` fixture; GB-024 all 12 route nodes on shared mission data; a `flutter/windows/` desktop runner used only to review the game locally; GB-056 output labels on Flutter workshop gears.

### Merged to `main` (PRs #1–#13)
The entries below name the branch each item was built on; all of them are merged.
- **GB-037 turret projectiles on `feature/turret-projectiles` (PR #13).** Powered turrets fire lane projectiles; the Spark Turret is sold in the shop.
- **GB-058 boss telegraphs on `feature/boss-telegraphs`.** Enemies can have a wind-up: they commit to an attack, a warning zone shows in their lane, and the hit lands when the wind-up ends on whoever is still in range. Optional **cleave** hits everyone in range in the lane. Scrapmaw now has an 18-tick wind-up with cleave, so leaving its lane in time dodges the hit.
- **GB-053 mission checkpoints on `feature/mission-checkpoint`.**
  - **When saved:** a wave-boundary checkpoint (`MissionSnapshot`, schema 1) is written when each wave starts and when each intermission begins, and cleared on victory, defeat or abandon.
  - **Resuming after the app was killed:** an intermission checkpoint resumes into the rebuild phase. A mid-wave kill **restarts that wave, paused, with the board locked as it was**, so killing the app can't be used to rebuild against a wave already seen.
  - **Route screen:** an interrupted mission shows a Resume/Abandon card. Starting another mission abandons it (the streak resets).
  - **No double payouts:** the mission wallet's claim keys and the shop's RNG state are restored, so rewards can't be paid twice and the shop continues exactly where it stopped.
- **GB-055 hero special on `feature/hero-special`.** Rivet gains SP from landed hits (10 per hit, max 100). With a full bar, **Wrench Quake** deals 25 damage, armor applying, to enemies within 1,200 mm in his lane. It's a validated command in both engines, applied after spawns and before the combat step. Tuning lives in `shared/heroes/heroes.json`, and tests in both engines keep the code equal to the file.
- **GB-052 mission lifecycle on `feature/mission-lifecycle`.** Adds a gameplay pause menu (Resume; Abandon with confirmation), auto-pause when the app is hidden during combat (it never auto-resumes), system Back routed to the pause menu once a mission has started, and a 0.25 s per-frame catch-up cap.
- **GB-025 multi-wave missions on `feature/workshop-drag-undo`** (same branch as GB-039, uncommitted). `BattleSession` supports waves with an intermission in both engines. Route node `copperwash-01` is now the 3-wave shared mission `copperwash_01`; wave 1 is identical to the old encounter. Each intermission pays the wave reward in battle scrap, rolls fresh offers and reopens the workshop.
- **GB-039 on `feature/workshop-drag-undo`.** The workshop has drag-and-drop with a ghost and a live target preview (green powered, amber unpowered, red invalid), moving placed gears, and undo for place, move, merge and sell. Undoing a sale charges the refund back through the ledger. Buys and rerolls are not undoable. The selected gear shows its status: power, lane and spawn interval.
- **Production art direction v2 and the 19-phase roadmap applied on `docs/production-art-and-roadmap`** (stacked on PR #4). Added the 316-record vertical-slice asset manifest, all `planned`; no art exists and no art gate has started. Started roadmap P0 #1: the Android toolchain is diagnosed in `docs/TOOLCHAIN_REPORT.md` (resolved in session 18: Android builds run on the emulator).
- **GB-030/GB-031 on `feature/workshop-shop-ui`.** The workshop now has a real gear shop: buy, tap-to-place, merge, sell and reroll with mission-scoped battle scrap through the ledger. `gearbound_app.dart` is split into `features/campaign`, `features/workshop` and `design_system`. The demo-only MOVE PRESS and rotate controls are removed.
- **Extension spec, Phase A (audit) and Phase B (economy foundation) done on `feature/progression-economy-foundation`.** See `docs/REPOSITORY_AUDIT.md`. This work added the ledger-backed wallet (Dart + C#), save v3 with v1/v2 migration, a two-slot store with corruption recovery, a clock-rollback guard, the ad policy engine (Dart + C#) and the mock-provider rewarded controller (Dart). The `AGENTS.md` monetization policy was revised.
- Phase 0 foundation completed for shared rules: `xorshift32-v1` RNG, seeded gear shop, data-driven wave director and enemy archetypes in both engines, all checked against independent fixtures.
- Phase 1: campaign route slice and replay layer. This session added Overclock Streak, star chests, the Supply Log and Vanguard Drop boosters (Flutter).
- Phase 1 (earlier): campaign route slice and replay layer.
- Shared rules and Unity/Dart implementations cover gear power, merge behavior, capped output clocks, combat, and battle-session outcomes.
- Flutter/Flame now has a route hub, twelve progressive nodes, health-based stars, local save data, daily contracts, a weekly best-score event, and a playable workshop/battle screen. All 12 nodes load shared missions since GB-024 (session 15); node 1 has three waves, nodes 2–12 one each until GB-051.

## Verification ledger
### 2026-11-28 session 19 (GB-056 output gear labels)
- Output gears now show their numeric tier, effective spawn rate per second, and target lane badge on the board. Selected-gear detail distinguishes infantry spawns from turret shots.
- Flutter analyze: no issues. Flutter tests: **183/183**; the workshop UI suite covers both portrait and landscape label data and existing phone/tablet overflow cases.
- Shared validation, reference rules, Flutter asset sync, combat traces, workshop cases and phase progress checks: all clean.
- Unity code was unchanged for GB-056. The existing EditMode report shows **57/57**; a fresh rerun stalled during Unity license initialization and produced no new report.
- Device legibility was not checked.

### 2026-11-28 session 18 (Android build and on-device baseline; Phase 00 complete)
- **Android SDK found:** the owner's Android Studio SDK is at `F:\Android\Sdk`, outside the default folder, which is why `flutter doctor` reported none. `flutter config --android-sdk F:\Android\Sdk`. The license was already accepted by the owner. `flutter doctor` still warns that `cmdline-tools` is missing and the license status is unknown.
- **Downloads (owner approved):** Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0 and libraries, NDK 28.2.13676358, Android SDK Platform 35.
- **Build bug found and fixed:** the first build failed in `:shared_preferences_android:compileDebugKotlin` with "Could not close incremental caches". The plugin sources are in the pub cache on C: and the project builds on F:, and Kotlin's incremental caches cannot span drive roots. `android/gradle.properties` now sets `kotlin.incremental=false`.
- **`flutter build apk --debug`: succeeded.** Installed on the Pixel 10 Pro XL emulator (Android 17, API 37, x86_64); the app launched to the campaign route with no errors in logcat (screenshot `artifacts/emulator-launch.png`, not committed).
- **On-device baseline:** `integration_test/baseline_device_test.dart` replays the same 51 checks as `tool/baseline_check.dart` from fixtures bundled into the test (`shared_fixtures.g.dart`, generated, not committed), and boots the app. **Passed in debug** (`flutter test -d emulator-5554`) **and in profile/AOT** (`flutter drive --profile`, 29.1 MB APK).
- New dev dependencies, both from the Flutter SDK (no download): `integration_test` and `flutter_driver`. `flutter analyze`: no issues.
- **Phase 00: 10/10, complete.** The baseline is identical on the Dart VM, Windows AOT, and the Android emulator in debug and AOT.
- **Boot test strengthened after review:** the first version only checked that a `MaterialApp` existed. It now waits for the hub and asserts `CampaignHubScreen`, the "THE WASTELAND ROUTE" header, node 1 "The First Link" and its PLAY button. It passes in debug and profile.
- **Skipped frames:** Android's Choreographer logged "Skipped 87 frames" (first profile run) and "Skipped 79 frames" (second) during cold start, before any Dart test code runs. That points at app start-up on the emulator rather than the fixture replay, but it is not a measurement; real numbers need a phone (Phase 15.2).
- **Not verified:** a physical ARM64 phone (moved to Phase 15, item 15.4), performance on any device, and the Unity Android build.

### 2026-11-28 session 17 (Phase 00 re-verification, GB-061)
- **Toolchain:** Flutter 3.47.7 stable (framework `abaf9c5237`), Dart 3.13.5, Unity 6000.3.27f1, Python 3.14.6. `main` at `a34f9ed`. Android: `flutter doctor` still reports no Android SDK, no `adb` and no emulator images.
- **Baseline re-run:** Flutter analyze clean, Flutter tests **182/182**, Unity EditMode **57/57**. Validator, reference fixtures, asset sync, combat traces, workshop cases and phase progress: all clean.
- **Schemas enforced:** added `hero`, `campaign-route`, `currencies`, `ad-policy` and `progression-rewards` schemas, so all 11 schemas now cover 23 data files (13 of them `waves/*.json`). The validator checks each file against its schema with a built-in subset checker (no packages, so it still runs with `python -I`), and fails on any schema that describes no file. Proven by 7 deliberate corruptions, each rejected with a precise path: hero health 0, an unknown enemy field, lane 3, `adFreeFirstMissions` 2 (policy needs at least 3), a string `premium`, a route node without `waveIds`, and a boolean tier. All current data passed unchanged.
- **AOT determinism:** `flutter/tool/baseline_check.dart` replays 51 checks: random vectors, shop rolls, the mission_001 schedule, all 7 combat traces with every checkpoint, and all 5 workshop cases. It passes on the Dart VM and as an **AOT-compiled Windows x64 binary** (`dart compile exe`), the same compilation mode release and phone builds use.
- **Phase 00:** 9 of 10 checklist items done. **Not verified:** the baseline on an ARM64 Android device. That needs the owner to install a user-profile Android SDK and accept its licenses (Phase 01).

### 2026-11-28 session 16 (phase checklist, GB-060)
- Added the Kiro spec under `.kiro/`: steering (`product.md`, `tech.md`, `structure.md`), and in `specs/gearbound-production/` the `requirements.md` (one EARS requirement per phase), `design.md` and `tasks.md`.
- `tasks.md` has **116 sub-tasks across 19 phases; 43 are ticked (37%)**. Every tick is backed by a test, fixture or document already recorded in this ledger; device, art-approval and account-dependent items stay open and say what blocks them.
- `tools/build/phase_progress.py --check` passes. It fails when the table is stale, a phase box disagrees with its sub-tasks, or numbering drifts.
- Roadmap gates updated: **G1 met in Flutter** with the Android blocker documented; G5 partial with specifics.
- No code or game data changed in this session; the last test results (Flutter 182/182, Unity 57/57) stand.

### 2026-11-28 session 15 (campaign route migration, GB-024)
- Flutter analyze: no issues. Flutter tests: **182/182** (4 new in `route_migration_test.dart`). Unity EditMode: **57/57** (2 new `RouteMissionTests`: every route node builds through `WaveDirector`, and the two late archetypes keep their stats).
- **Data:** `shared/waves/` gains `copperwash_02`-`05`, `ironwood_01`-`05`, `sunken_01`-`02` (one wave each), and `campaign_route.json` lists all 12 nodes. New archetypes in `enemies.json`: `raider.skirmisher`, `raider.dasher`, `ironwood.raider`, `ironwood.lancer`, `ironwood.warden`, `sunken.reaver`, `sunken.tidebreaker`.
- **Balance review** (headless, 10 000 mm field, starter core and press plus: nothing / one side press / both side presses / both plus a booster):

  | Node | Spawns vs old script | Outcome and fortress, all 4 builds |
  |---|---|---|
  | copperwash-02, -03, -04 | identical | identical |
  | copperwash-05 | basic raiders 34→32 HP and 58→60 speed; the late runner is a standard Rustrunner; **Scrapmaw now telegraphs and cleaves** | identical (clear times within 6 ticks) |
  | ironwood-01 to -04 | region archetypes instead of per-level formula stats; ironwood-02 adds 2 runners, -04 a bruiser | identical (side-lane clears 22-405 ticks slower) |
  | ironwood-05, sunken-01, sunken-02 | identical | identical |

  The test pins all 44 node/build outcomes. The probe also showed that **extra enemies in the middle lane change nothing** for these builds, because the starter press and the hero hold it; side lanes carry all the pressure. GB-051 should use that when it designs multi-wave missions.
- Validator: now reads every `waves/*.json`, requires 12 unique route nodes and flags mission files no node uses. Asset sync copies the new files; drift check clean. Reference fixtures, combat traces and workshop cases: unchanged and clean.
- The scripted encounters stay in `encounters.dart` only as the test baseline; the game always passes shared content.
- **Not done:** nodes 2-12 are still single-wave (GB-051), and the 7 new archetypes have no art records in the asset manifest yet.

### 2026-11-27 session 14 (Unity workshop rules, GB-036 and GB-049)
- Flutter analyze: no issues. Flutter tests: **178/178** (3 new fixture tests). Unity EditMode: **55/55** (5 new `WorkshopFixtureTests`).
- **New shared fixture** `workshop_cases.json`, written by `flutter/tool/workshop_cases.dart`: six `mixSeed32` vectors and five scripted sessions (place/merge/sell/undo, drag move and merge, reroll escalation and running out of scrap, lock and intermission with a duplicate wave reward, turret lanes and sale). **The C# port reproduces every step**: results, scrap, offers, hand, selection, rerolls, lock state and every board gear's ID, tier, lane and interval.
- The expected values come from the Dart controller, so this proves the two engines agree, not that the rules are right; the rules themselves stay covered by the existing Dart workshop tests.
- **Bug found while porting:** Dart pushed an undo entry before a merge and kept it when `GearBoard.merge` refused, so a later undo would have been a no-op step. Both engines now drop the entry.
- The C# workshop compiles under Mono `mcs` too (nullable tuples and tuple `==` were rewritten for it).
- Validator, reference fixtures, asset sync, combat traces and the new workshop check: clean.
- **Not ported:** checkpoint save/restore (`toJson`/`restore`) and any Unity UI (GB-046).

### 2026-11-27 session 13 (turret projectiles, GB-037)
- Flutter analyze: no issues. Flutter tests: **175/175**. Unity EditMode: **50/50** (6 new `ProjectileTests`).
- Both engines get rule tests: a hit on the nearest enemy in the lane with armor, other lanes ignored, removal at the field end, the cap refusing shots, powered and unpowered turrets, a capped turret holding, and the Spark Turret loading its projectile and keeping it through merges. Flutter also checks that the workshop shop offers and places a turret and that checkpoints keep projectile fields.
- **Cross-engine parity:** new scenario `turret-side-lanes` (victory at tick 288, fortress 78) matches tick by tick in Dart and the C# generator. **The 6 existing hashes are unchanged.**
- **Opening balance re-measured** with turrets in the shop (500 seeds): a second press is offered in 416 openings and reachable within rerolls in 499 (guards: 400 and 495). A turret is offered in 33 openings.
- **Not verified:** turret strength feel on a device, and projectile rendering beyond the widget smoke tests.

### 2026-11-27 session 12 (boss telegraphs)
- Flutter analyze: no issues. Flutter tests: **169/169**. Unity EditMode: **44/44**. Both engines get rule tests: timing, dodge, cleave, a winding-up attacker holding position, validation, and Scrapmaw loading its new fields. Flutter adds a telegraph render test.
- **Intentional trace change, re-proven:**
  - The three scenarios without Scrapmaw kept identical hashes.
  - The two boss scenarios changed because Scrapmaw now telegraphs and cleaves. They were regenerated from the C# reference, and **Dart reproduces them independently, tick for tick**.
  - New scenario `boss-cleave-crowded-lane` (6 total): a defeat, because one lane is over-stacked and the side lanes are open.
- **The asset drift test caught** that the Flutter copy of `enemies.json` was stale after the edit; it was re-synced.
- `COMBAT_ENGINE.md` was rewritten to match the code. The old version claimed a hero recovery timer and critical rolls that don't exist.
- **Not verified:** whether the 18-tick (0.6 s) warning feels fair on a real device.

### 2026-11-27 session 11 (mission checkpoints)
- Flutter analyze: no issues. Flutter tests: **162/162**. `mission_checkpoint_test.dart` adds 9 tests:
  - snapshot round trip and rejection of corrupt input;
  - the restored shop continuing its exact RNG and keeping its claim keys;
  - `restoreCheckpoint` rejecting impossible values;
  - a mid-wave resume (paused, locked board, opening soldiers redeployed);
  - an intermission resume with no double reward;
  - victory clearing the checkpoint;
  - an invalid checkpoint being discarded;
  - the route card's Abandon.
- Validator, reference fixtures, asset sync and combat traces: clean. Unity EditMode: **not re-run** (no C# or shared data changed; last result 39/39).
- **Hardening:** a failed checkpoint read can no longer block the route screen. Checkpoints that no longer fit the game data are discarded rather than crashing.
- **Not verified:** an actual OS process kill on a device (the Android build is blocked, GB-038). The checkpoint is local only; there's no cloud save yet (Phase 12).

### 2026-11-27 session 10 (hero special)
- Flutter analyze: no issues. Flutter tests: **153/153**. Unity EditMode: **39/39** (4 new hero-special tests).
- **Cross-engine parity:** new combat scenario `boss-wave-hero-special` (the hero uses the special whenever ready; SP is part of that trace's hash) matches tick by tick in Dart and in the C# generator. **The 4 existing trace hashes are unchanged.** The special clears the boss wave at tick 385 versus 416 without it.
- Validator (now checks `heroes.json`), reference fixtures, asset sync and combat traces: clean.
- **Bug found:** the first SP bar used a text accessibility value ("0 of 100"). Flutter requires progress-bar semantics values to be numeric, so it would throw whenever accessibility semantics are active. The widget tests caught it; the bar now reports a percentage.
- **Not verified:** device feel and special balance in real play.

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
- Flutter Android packaging works since session 18 with the owner's Android Studio SDK (`F:\Android\Sdk`, licenses accepted by the owner, never by the agent); debug and profile APKs run on the Pixel 10 Pro XL emulator. iOS packaging requires a macOS host. A Windows desktop debug runner (`flutter/windows/`, GB-059) is used for local review; it needs Windows Developer Mode, which the owner enabled on 2026-11-28.
- Work is merged through PRs; `main` is at `a34f9ed` after PR #13. Uncommitted work is listed under Current milestone.
- Shared JSON is loaded in Unity through a small dependency-free reader (`SharedJson.cs`), not a package, which keeps `Gearbound.Core` engine-independent.
- Flutter now bundles runtime shared JSON under `flutter/assets/shared` (synced by `tools/build/sync_flutter_shared.py`; a test fails on drift). Route node `copperwash-01` loads its wave from `shared/missions/campaign_route.json` → `mission_001.json` `wave.1`, with a test showing the spawns are identical to the old script. Since GB-024 (session 15) all 12 nodes load shared missions; the old scripts in `encounters.dart` remain only as a test baseline.
- Gamification is earn-only and offline: see `docs/GAMIFICATION_AND_EVENTS.md`.
- Campaign and Scrapstorm state save locally through `shared_preferences`; balance playtests, widget-level interaction tests, and mobile-device validation are still outstanding.
