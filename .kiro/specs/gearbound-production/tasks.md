# Implementation Plan

Phase-wise checklist for GEARBOUND: Wasteland Warriors. Each phase task maps to `docs/PHASE_ROADMAP.md`, each sub-task names its backlog ID (`docs/TASK_BACKLOG.md`), and `_Requirements_` points to `requirements.md`.

**Tick a box only when its evidence exists:** a passing test, a fixture, a recorded build or an owner approval, written down in `docs/DEVELOPMENT_STATUS.md`. A phase box is ticked only when every sub-task under it is ticked. Blocked items say who or what they wait on.

After changing any box, update the progress table and run `python -I tools/build/phase_progress.py --check`.

## Progress

<!-- progress:start -->
| Phase | Name | Done | Progress |
|---|---|---|---|
| 00 | Repository and simulation foundation | 10/10 | 100% |
| 01 | Toolchain and build readiness | 7/9 | 77% |
| 02 | Complete mechanical workshop | 8/13 | 61% |
| 03 | Combat and multi-wave mission flow | 6/12 | 50% |
| 04 | Visual preproduction | 4/12 | 33% |
| 05 | Production vertical slice | 0/9 | 0% |
| 06 | Unity and Flutter playable parity | 4/9 | 44% |
| 07 | Campaign content | 3/8 | 37% |
| 08 | Expanded gamification | 2/7 | 28% |
| 09 | LiveOps and rotating events | 1/3 | 33% |
| 10 | Economy and persistence hardening | 3/5 | 60% |
| 11 | Advertising integration | 2/6 | 33% |
| 12 | Backend and cloud services | 0/3 | 0% |
| 13 | In-app purchases | 0/4 | 0% |
| 14 | Audio, onboarding and accessibility | 1/4 | 25% |
| 15 | Performance and QA | 0/4 | 0% |
| 16 | Closed testing and soft launch | 0/3 | 0% |
| 17 | Commercial release | 0/3 | 0% |
| 18 | Post-launch operations | 0/2 | 0% |
| **All** | | **51/126** | **40%** |
<!-- progress:end -->

Last verified 2026-11-28 session 19: Flutter 183/183, analyze clean, every shared check clean; Unity EditMode previous report 57/57.

## Tasks

- [x] 0. Phase 00 — Repository and simulation foundation
  - [x] 0.1 Fixed 30 Hz ticks, stable IDs and seeded `xorshift32-v1` randomness in both engines (GB-016)
    - Evidence: `random_vectors.json` replayed by `SharedRulesTests` and `shared_rules_test.dart`
  - [x] 0.2 5×5 board with reciprocal ports, graph power, rotation parity, jam and conflict rules, booster cap (GB-004)
  - [x] 0.3 Merge and capped output clocks with a pending spawn (GB-004, GB-005)
  - [x] 0.4 Three-lane combat and `BattleSession` connected to gear outputs (GB-006, GB-007)
  - [x] 0.5 Versioned schemas for every runtime data file, enforced by the validator, plus Python reference fixtures (GB-003, GB-019, GB-061)
    - Evidence: `validate_shared.py` checks 23 files against 11 schemas; 7 deliberate corruptions rejected (session 17)
  - [x] 0.6 Cross-engine combat traces, 7 scenarios matching tick for tick (GB-022)
  - [x] 0.7 Repository audit and LF pinning in `.gitattributes` (GB-026)
  - [x] 0.8 Flutter parity runtime reproducing every shared fixture (GB-010)
  - [x] 0.9 Baseline replayed in ahead-of-time compiled Dart, as release builds run it (GB-061)
    - Evidence: `tool/baseline_check.dart` gives the same 51 results on the VM and as an AOT Windows x64 binary (session 17)
  - [x] 0.10 Baseline re-verified on Android, in debug and AOT (profile) builds (GB-061)
    - Evidence: `integration_test/baseline_device_test.dart` on the Pixel 10 Pro XL emulator (Android 17, API 37, x86_64): 51/51 checks and the app boots, in `flutter test` (debug) and `flutter drive --profile` (AOT). Logs: `artifacts/device-baseline-*.log` (session 18)
    - A physical ARM64 phone is tracked in Phase 15 (item 15.4)
  - _Requirements: 0_

- [ ] 1. Phase 01 — Toolchain and build readiness
  - [x] 1.1 Android toolchain diagnosed and options written up in `docs/TOOLCHAIN_REPORT.md` (GB-038)
  - [x] 1.2 Unity EditMode tests run in batch mode
  - [x] 1.3 Flutter `pub get`, `analyze` and `test` run clean
  - [x] 1.4 Windows desktop debug runner for local review (GB-059)
  - [x] 1.5 User-profile Android SDK installed and its licenses accepted
    - Evidence: the owner's Android Studio SDK at `F:\Android\Sdk` with `licenses/android-sdk-license`; Flutter pointed at it with `flutter config --android-sdk` (session 18)
  - [x] 1.6 Debug APK built and installed on a device or emulator (GB-038)
    - Evidence: `flutter build apk --debug` succeeded; installed and launched on the Pixel 10 Pro XL emulator to the campaign route, no errors in logcat (session 18)
  - [ ] 1.9 `flutter doctor` fully green for Android
    - Remaining warnings: `cmdline-tools` missing and license status unknown; install the command-line tools from Android Studio's SDK Manager (owner)
  - [x] 1.7 Unity Android build target set and a test scene running on a device (GB-012)
    - Evidence: `AndroidBaselineBuild.Build` builds an IL2CPP APK (ARM64 + x86_64) from a generated baseline scene; on the Pixel 10 Pro XL emulator (x86_64) it logs "UNITY DEVICE BASELINE OK: 36 checks, 7 combat traces, 5 workshop cases" (session 20). A physical ARM64 phone stays with 15.4
  - [ ] 1.8 iOS build on a macOS host with signing
    - Needs macOS and Xcode; Windows cannot build iOS
  - _Requirements: 1_

- [ ] 2. Phase 02 — Complete mechanical workshop
  - [x] 2.1 Shop with three offers, buy, reroll, and insufficient-funds and sold-out states (GB-030)
  - [x] 2.2 Tap and drag placement with a ghost and a powered/unpowered/invalid preview (GB-039)
  - [x] 2.3 Merge, sell, cancel, move and undo for place, move, merge and sell (GB-030, GB-039)
  - [x] 2.4 Mission-scoped battle scrap through the ledger (GB-030)
  - [x] 2.5 Feature modules: `features/campaign`, `features/workshop`, `design_system` (GB-031)
  - [x] 2.6 Unity workshop rules matching Flutter through `workshop_cases.json` (GB-036, GB-049)
  - [x] 2.7 Spark Turret sold and placeable (GB-037)
  - [x] 2.8 Numeric tier, spawn rate and lane marker on output gears (GB-056)
    - Evidence: Flutter workshop UI tests verify tier/rate and lane labels in portrait and landscape board layouts; full suite 183/183 (session 19)
  - [ ] 2.9 Offer locking UI (the rule exists in `rollShop`)
  - [ ] 2.10 Rotation and a conflict explanation
    - Needed only once gears with partial ports exist
  - [ ] 2.11 Port workshop checkpoint save and restore to Unity
  - [ ] 2.12 Opening-shop edge case decision: 1 of 500 seeds (GB-050)
    - Owner design decision
  - [ ] 2.13 Touch check on a device
    - Android emulator available since session 18; a physical phone is still needed for real touch
  - _Requirements: 2_

- [ ] 3. Phase 03 — Combat and multi-wave mission flow
  - [x] 3.1 Battle states with multi-wave intermission, wave rewards and rebuild (GB-025)
  - [x] 3.2 Hero lane commands and the Wrench Quake SP special as a validated command (GB-055)
  - [x] 3.3 Boss wind-up and cleave telegraphs, dodgeable by leaving the lane (GB-058)
  - [x] 3.4 Turret projectiles with a 24-shot cap (GB-037)
  - [x] 3.5 Pause, background auto-pause, Back to the pause menu, rotation and a catch-up cap (GB-052)
  - [x] 3.6 Wave-boundary mission checkpoints that survive an app kill (GB-053)
  - [ ] 3.7 Status effects, knockback and stun
  - [ ] 3.8 Hero recovery after a knockout
  - [ ] 3.9 Evaluate further hero actions: dash, heavy attack, auto-attack
  - [ ] 3.10 Critical hits and other random rolls through `SeededRandom`, with new traces
  - [ ] 3.11 Complete combat feedback HUD (03.4) with final visuals
  - [ ] 3.12 Device check of telegraph timing and turret feel
    - Can start on the emulator; final judgment needs a physical phone
  - _Requirements: 3_

- [ ] 4. Phase 04 — Visual preproduction
  - [x] 4.1 Art direction v2 style bible (`docs/ART_DIRECTION.md`)
  - [x] 4.2 Asset manifest, schema and validator rules: 337 records, 335 `planned` and 2 `concept` (GB-048, GB-040)
  - [x] 4.8 Visual direction v3, Tactile Industrial Comic 2.5D: docs reconciled and the supporting specifications written (GB-062)
    - Evidence: `ART_DIRECTION.md` v3 (decisions, 19-step execution order, gates incl. ART-B) plus `VISUAL_STYLE_BIBLE`, `MATERIAL_LIBRARY`, `CHARACTER_DESIGN`, `CHARACTER_RIGGING_GUIDE`, `ANIMATION_SPECIFICATION`, `ENVIRONMENT_PRODUCTION`, `ASSET_GENERATION_PROMPTS`, `ASSET_VALIDATION_GUIDE`, `RENDERING_ARCHITECTURE`, `VISUAL_PERFORMANCE_BUDGET`, `UI_UX_SPECIFICATION` v2; inventory renamed `ASSET_INVENTORY.md` with the benchmark set; manifest 337 records, validator clean (session 21). Documentation only: nothing is approved
  - [x] 4.9 Working visual reference board (GB-040)
    - Evidence: `assets-source/style-bible/reference_board_v001.html` plus `industrial-comic-style-study_v001.png`; manifest records `style_reference_board` and `style_mood_board` at `concept`. The image is an unapproved ART-01 study; it does not complete approval or production gates (sessions 21–22)
  - [ ] 4.10 Painted material library sheet approved (`style_material_library`, `MATERIAL_LIBRARY.md`)
  - [ ] 4.3 ART-01 visual direction approved (GB-040)
    - Mood-board and diagram-board concepts exist; owner review, painted material sheet and illustrated screen compositions remain
  - [ ] 4.4 ART-02 Rivet master approved (GB-041)
  - [ ] 4.5 Concepts for enemies, starter gears, the Copperwash environment and the fortress
  - [ ] 4.6 Portrait and landscape compositions
  - [ ] 4.7 Scrapjaw/Scrapmaw boss name decided (GB-047)
    - Owner decision
  - [ ] 4.11 Gear masters for the 5 starter gears, tiers 1–3 and state layers approved
  - [ ] 4.12 Visual benchmark ART-B approved in-engine in portrait and landscape, with a first device reading (GB-063)
    - Gates Phase 05: no full-scale production before this box is ticked
  - _Requirements: 4_

- [ ] 5. Phase 05 — Production vertical slice
  - [ ] 5.1 Rivet skeletal parts, rig and P0 animations (GB-042)
  - [ ] 5.2 Starter gear and board art (GB-043)
  - [ ] 5.3 Copperwash environment, fortress, units, enemies and Scrapmaw (GB-044)
  - [ ] 5.4 Flame sprite rendering pipeline with depth sort and VFX pooling (GB-045)
  - [ ] 5.5 Combat visuals: animation playback, shadows, projectiles, hits, defeat
  - [ ] 5.6 Final workshop, HUD, result and reward screens
  - [ ] 5.7 Review captures: portrait, landscape, compact phone, tablet
  - [ ] 5.8 Shared art metadata: `projection.json` with cross-engine golden cases, then `ui_tokens.json` (GB-064)
  - [ ] 5.9 Slice performance measured on representative devices against `VISUAL_PERFORMANCE_BUDGET.md`
  - _Requirements: 5_

- [ ] 6. Phase 06 — Unity and Flutter playable parity
  - [x] 6.1 Simulation and combat trace parity (GB-010, GB-022)
  - [x] 6.2 Wallet and ad policy parity (GB-027, GB-029)
  - [x] 6.3 Workshop rules parity (GB-036)
  - [x] 6.4 Every route mission loads and builds in Unity (GB-024)
  - [ ] 6.5 Unity playable client: boot, campaign, workshop, battle (GB-046)
  - [ ] 6.6 Unity responsive presentation and input (GB-008)
  - [ ] 6.7 Flutter sprites replacing canvas primitives
  - [ ] 6.8 The same mission completed in both clients with equivalent outcomes
  - [ ] 6.9 Unity campaign progress, rewards and saves
  - _Requirements: 6_

- [ ] 7. Phase 07 — Campaign content
  - [x] 7.1 12-node route with ordered unlocks and best stars (GB-013)
  - [x] 7.2 All 12 nodes on shared mission data, with equivalence pinned by `route_migration_test.dart` (GB-021, GB-024)
  - [x] 7.3 Node 1 as the 3-wave `copperwash_01` mission (GB-025)
  - [ ] 7.4 Nodes 2–12 as multi-wave missions with measured pressure (GB-051)
    - The GB-024 probe found side lanes carry all the pressure; use that in the design
  - [ ] 7.5 Copperwash nodes each teaching one concept, with playtest notes (GB-015)
  - [ ] 7.6 Mission objectives beyond survival (GB-057)
  - [ ] 7.7 Illustrated campaign map
  - [ ] 7.8 Ironwood and Sunken art records in the manifest
  - _Requirements: 7_

- [ ] 8. Phase 08 — Expanded gamification
  - [x] 8.1 Daily contracts and the weekly event with once-only claims (GB-014)
  - [x] 8.2 Overclock Streak, star chests, Supply Log and Vanguard Drop (GB-020)
  - [ ] 8.3 Device check and playtest of the rewards (GB-020)
  - [ ] 8.4 Data-driven daily and weekly pools with a completion chest (GB-032)
  - [ ] 8.5 Achievements and rotating weekly rule sets (GB-023)
  - [ ] 8.6 Loadout selection before a mission (GB-054)
  - [ ] 8.7 XP, levels, hero mastery and gear collection
  - _Requirements: 8_

- [ ] 9. Phase 09 — LiveOps and rotating events
  - [x] 9.1 Scrapstorm offline weekly best-score event
  - [ ] 9.2 Event engine with lifecycle states and claim windows (GB-033)
  - [ ] 9.3 Scrapstorm v2, Gear Frenzy and Engineering Trials (GB-033)
  - _Requirements: 9_

- [ ] 10. Phase 10 — Economy and persistence hardening
  - [x] 10.1 Idempotent ledger with separated currencies in both engines (GB-027)
  - [x] 10.2 Save v3 with v1/v2 migration, two-slot recovery and a clock guard (GB-028)
  - [x] 10.3 Checkpoints restore mission claim keys, so nothing pays twice (GB-053)
  - [ ] 10.4 Transaction tests for ad rewards, purchase delivery, refunds and interrupted transactions
  - [ ] 10.5 Account-linked wallet reconciliation design
  - _Requirements: 10_

- [ ] 11. Phase 11 — Advertising integration
  - [x] 11.1 Shared ad policy in both engines with fixtures (GB-029)
  - [x] 11.2 Mock rewarded provider that grants exactly once (GB-029)
  - [ ] 11.3 Google Mobile Ads with test units only (GB-034)
    - Blocked on an AdMob account and a device build
  - [ ] 11.4 UMP consent and privacy options
  - [ ] 11.5 Rewarded placements and interstitials wired through the policy
  - [ ] 11.6 Ad failure and lifecycle handling verified on a device
  - _Requirements: 11_

- [ ] 12. Phase 12 — Backend and cloud services
  - [ ] 12.1 Backend evaluation (Firebase services, only what is needed)
    - Blocked on account decisions
  - [ ] 12.2 Identity, account linking and cloud save reconciliation
  - [ ] 12.3 Server-verified rewards, trusted time and validated remote config
  - _Requirements: 12_

- [ ] 13. Phase 13 — In-app purchases
  - [ ] 13.1 Store products with fixed contents and localized prices
    - Blocked on store accounts and Phase 12
  - [ ] 13.2 Purchase flow with server verification, granted once (GB-035)
  - [ ] 13.3 Restore, refund and revoke reconciliation
  - [ ] 13.4 Supply Depot UI
  - _Requirements: 13_

- [ ] 14. Phase 14 — Audio, onboarding and accessibility
  - [x] 14.1 Prototype accessibility basics: telegraphs use shape and "!" rather than color alone; the SP bar reports numeric semantics
  - [ ] 14.2 Audio: gears, combat, UI and music, with lifecycle handling
  - [ ] 14.3 Playable onboarding tutorial
  - [ ] 14.4 Accessibility settings: volume, haptics, reduced motion, readable type, large targets
  - _Requirements: 14_

- [ ] 15. Phase 15 — Performance and QA
  - [ ] 15.1 Device matrix and aspect ratios from 4:3 to 21:9
    - Needs physical phones and tablets; only the Pixel 10 Pro XL emulator exists today
  - [ ] 15.2 Profiling with measured FPS, memory and draw calls
  - [ ] 15.3 Full regression including device integration
  - [ ] 15.4 Baseline and app smoke test on a physical ARM64 Android phone
    - `flutter test integration_test/baseline_device_test.dart -d <phone>` and the `flutter drive --profile` run; the emulator run in session 18 was x86_64
    - On the emulator, Android logs "Skipped 79–87 frames" during cold start, before any Dart test code runs. That is an emulator start-up figure, not a measurement; measure on a phone in 15.2
  - _Requirements: 15_

- [ ] 16. Phase 16 — Closed testing and soft launch
  - [ ] 16.1 Closed test build distributed
  - [ ] 16.2 Privacy-conscious metrics and observation plan
  - [ ] 16.3 Tuning from test evidence
  - _Requirements: 16_

- [ ] 17. Phase 17 — Commercial release
  - [ ] 17.1 Store listing, privacy policy and data-safety forms
  - [ ] 17.2 Signed release builds with production configuration
  - [ ] 17.3 Monetization review and release approval
  - _Requirements: 17_

- [ ] 18. Phase 18 — Post-launch operations
  - [ ] 18.1 Monitoring for stability, economy and events
  - [ ] 18.2 Gradual content expansion
  - _Requirements: 18_
