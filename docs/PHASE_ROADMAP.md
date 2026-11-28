# GEARBOUND: Wasteland Warriors — Production and Development Roadmap

**Document version:** 2.0 (replaces the five-phase v1 and the A–J extension table; mapping in §25)
**Updated:** 2026-11-27
**Delivery strategy:** Incremental, test-driven, vertical-slice-first
**Engines:** Unity 6.3 LTS and Flutter/Flame — **Platforms:** Android and iOS

---

## 1. Vision

Deliver one complete, polished, original mobile game that combines:
- Gear Fight!-style mechanical construction and automatic armies.
- The Last Friend-style expressive characters, 2.5D environments and arcade combat.
- Candy Crush-style campaign progression, daily tasks, rewards and rotating events.
- Sustainable monetization: rewarded ads, transition interstitials and fixed-content IAP.

The goal is a finished game, not an oversized unfinished prototype.

## 2. Current baseline (verified in this repository)

Updated 2026-11-28.

**Branches:**
- `main` = `a34f9ed` (PRs #1–#13 merged, the last being GB-037 turret projectiles).
- `feature/unity-workshop-controller` holds uncommitted work: GB-036/GB-049 (Unity workshop rules and `mixSeed32`), GB-024 (all route nodes on shared data) and a `flutter/windows/` desktop runner for local review.

**Technical foundation (implemented, both engines):**
- Fixed 30 Hz simulation on a 5×5 board with reciprocal ports, graph traversal, rotation parity, merge, output clocks and lane combat.
- Multi-wave `BattleSession` with intermission, hero special (Wrench Quake), boss wind-up and cleave, and turret projectiles.
- Wave director, seeded shop, workshop controller rules, shared JSON with validator, an independent Python fixture generator, and the Dart-generated workshop fixture.
- Seven cross-engine combat trace scenarios that match exactly.

**Flutter (implemented):**
- 12 route nodes across Copperwash Pass, Ironwood Frontier and The Sunken Yard, all loading shared mission data. Node 1 has 3 waves; nodes 2–12 have one.
- Workshop: shop, tap and drag placement, moves, merges, sell, undo, previews; turrets in the shop.
- Mission lifecycle (pause, background, Back, rotation) and wave-boundary checkpoints.
- Progression: best-result stars, daily contracts, Scrapstorm, Overclock Streak, Supply Log, star chests and Vanguard Drop.

**Commercial foundation (implemented, local only):**
- Ledger wallet in Dart and C#, with separated currencies and idempotent claims.
- Save v3 with v1/v2 migration, two-slot recovery and a clock-rollback guard.
- Shared ad policy in Dart and C#, plus a mock rewarded provider. Ads are disabled.

**Recorded verification** (latest run in `DEVELOPMENT_STATUS.md`; re-run before every merge):

| Check | Result |
|---|---|
| Unity EditMode | 57/57 |
| Flutter tests | 182/182 |
| Flutter analyze | Clean |
| Validator, reference fixtures, asset sync, combat traces, workshop cases | Clean |

**Limitations:**
- No production art.
- Unity is a simulation and rules library only, with no playable client or UI.
- Route nodes 2–12 are single-wave (GB-051).
- No status effects, knockback or hero recovery.
- No ad SDK, consent, IAP or backend.
- Android debug and profile builds run on the emulator only; no physical phone yet and no performance data (see `TOOLCHAIN_REPORT.md`). A Windows desktop debug build is also available for review.
- iOS needs macOS and Xcode.
- No device performance data.

## 3. Development rules

- Follow `AGENTS.md`. Preserve working systems, and never rebuild one without a documented reason.
- Use feature branches, focused commits and PRs.
- Each task has an ID, priority, dependencies, requirements, deliverables, acceptance criteria, tests, actual status and limitations.
- A phase is complete only with verification evidence.
- Never renumber backlog IDs; add new ones. `DEVELOPMENT_STATUS.md` is authoritative for progress.

## 4. Overview

| Phase | Focus | Status |
|---|---|---|
| 00 | Repository and simulation foundation | **Complete** (2026-11-28): schemas enforced; baseline identical on the Dart VM, Windows AOT, and the Android emulator in debug and AOT |
| 01 | Toolchain and build readiness | Partial (7/9): Flutter debug and profile APKs and the Unity IL2CPP baseline APK run on the emulator; Windows runner (GB-059); `cmdline-tools` (owner) and iOS (macOS) remain; a physical phone is Phase 15 |
| 02 | Complete mechanical workshop | **Implemented in Flutter** (shop, drag, move, undo, previews); workshop rules ported to Unity C# with a shared fixture (GB-036); device test and Unity UI pending |
| 03 | Combat and multi-wave mission flow | In progress: multi-wave, intermission, lifecycle, checkpoints, hero special, boss telegraphs (wind-up and cleave) and turret projectiles done; status effects and hero recovery pending |
| 04 | Visual preproduction | In progress: v3 specifications, diagram board and illustrated mood-board study at concept; ART-01 approval, painted material sheet and illustrated compositions pending |
| 05 | Production vertical slice | Planned |
| 06 | Unity and Flutter playable parity | Partial: simulation, workshop rules, economy and ad-policy parity; no Unity client (GB-046) |
| 07 | Campaign content | Partial: all 12 nodes on shared mission data (GB-024); nodes 2–12 single-wave until GB-051 |
| 08 | Expanded gamification | Partial: streak, star chests, Supply Log, Vanguard Drop, daily contracts; data-driven pools pending (GB-032) |
| 09 | LiveOps events | Partial (Scrapstorm offline) |
| 10 | Economy and persistence hardening | Local foundation implemented |
| 11 | Advertising integration | Policy and mock implemented; SDK pending |
| 12 | Backend and verification | Blocked on account decisions |
| 13 | In-app purchases | Blocked on 10/12 and store accounts |
| 14 | Audio, onboarding, accessibility | Planned |
| 15 | Performance and QA | Planned |
| 16 | Closed testing and soft launch | Planned |
| 17 | Commercial release | Planned |
| 18 | Post-launch operations | Planned |

---

## Phase 00 — Repository and simulation foundation
**P0 · Implemented, preserve and revalidate** · Tasks GB-001–007, 010, 016–019, 022, 026

**Steps:**
1. Inspect the latest commits, `AGENTS.md` and architecture docs.
2. Confirm toolchain versions and review the schemas.
3. Preserve seeded randomness, stable ordering, 30 Hz timing, power and rotation rules, and the combat fixtures.
4. Re-run the baseline and record the results.

**Exit:** behavior is unchanged unless approved; fixtures, validator and analyze pass; Unity tests pass; any gaps are documented.

**Status (2026-11-28): complete.** Every runtime data file has an enforced schema. The shared fixtures replay identically on the Dart VM, as a Windows AOT binary, and on the Android emulator in debug and AOT (profile) builds. A physical ARM64 phone is part of the Phase 15 device matrix.

## Phase 01 — Toolchain and mobile build readiness
**P0 · Partly blocked (owner and macOS items)** · GB-012, GB-038, GB-059

**Status (2026-11-28):** Android works with the owner's SDK at `F:\Android\Sdk`: debug and profile APKs build and run on the Pixel 10 Pro XL emulator (`TOOLCHAIN_REPORT.md`). The Unity Android build (IL2CPP, ARM64 + x86_64) runs the shared-fixture baseline scene on the emulator (session 20). Remaining: `cmdline-tools` for a green `flutter doctor` (owner), a physical phone (Phase 15) and iOS (needs macOS). Unity EditMode runs in batch mode. A Windows desktop debug runner (`flutter run -d windows`, needs Windows Developer Mode) is in place for reviewing the game on the development PC; it is not a release target and proves nothing about phone performance.

**Unity:**
- Editor, Android Build Support, SDK/NDK/JDK and modules.
- The project opens with no compilation errors, and a development build target is set.
- Build steps are written down.

**Flutter:**
- `flutter doctor` and the Android SDK location.
- **SDK/NDK licenses are accepted by the user**; the agent never accepts them.
- Java/Gradle compatibility, `pub get`, `analyze`, `test`, and a debug APK.

**iOS:** document the macOS/Xcode and signing prerequisites, and never claim builds on unsupported hosts.

**Deliverables:** toolchain report, build commands, debug APK when possible, install steps, blocker list.

**Exit:**
- The Flutter build launches on a device or emulator.
- A Unity test scene runs.
- Build logs are recorded, and no license is accepted without authorization.

## Phase 02 — Complete mechanical workshop
**P0** · GB-017, GB-030, GB-031, GB-039, GB-036 · Depends on Phase 00

**02.1 Shop UI**
- *Done (PR #4):* three offers with name, category, price and buy; reroll; insufficient-funds and sold-out states.
- *Remaining:* gear art (or labeled temporary art) and a numeric tier and spawn-rate display (GB-056). Merged gears show a tier badge; the selected gear shows its interval.
- Offer locking: the rule exists in `rollShop`, but there is no UI.
- Pricing must come from the shared shop rules, never the UI.

**02.2 Placement**
- *Done:* tap-to-select, tap-to-place, valid-cell highlight, occupancy validation.
- *Done (GB-039):* drag-and-drop with a ghost, target-cell preview (powered, unpowered, invalid), drop onto a gear to merge, and orientation-aware input, tested in both orientations.
- *Remaining:* device touch check.

**02.3 Manipulation**
- *Done:* merge, sell, cancel unplaced purchase, and power state shown through the indicators.
- *Done (GB-039):* moving placed gears, undo for place, move, merge and sell, and an interval preview.
- *Remaining:* rotation (meaningful only once gears with partial ports exist) and a conflict explanation.
- Define atomic transaction boundaries for each action.

**02.4 Battle economy**
- *Done:* battle scrap in a mission wallet, separate from permanent currency; ledger-checked spends and refunds; no negative balances.
- *Done (GB-053):* wave-boundary checkpoints restore the mission wallet, offers and RNG after the app is killed.

**02.5 Refactoring**
- *Done:* `features/campaign`, `features/workshop`, `design_system`.
- *Remaining:* reusable board, shop and currency components when production art lands.

**Exit:**
- Purchase, place, (rotate,) merge and sell all work, and power updates immediately.
- All costs go through the ledger; invalid actions change nothing.
- Edits are blocked outside preparation, and the shop fixtures stay valid.
- The Unity workshop rules (`Gearbound.Workshop.WorkshopController`) match Flutter through `workshop_cases.json` (GB-036). The Unity workshop UI follows with the playable client (GB-046).

## Phase 03 — Complete combat and mission flow
**P0** · GB-006, 007, 011, 015, 025 · Depends on Phase 02

| Step | Scope |
|---|---|
| 03.1 Battle session | Explicit states: init → prep → wave → wave complete → inter-wave rewards → prep → … → victory/defeat → result → route |
| 03.2 Hero | Keep lane commands. Evaluate horizontal movement, basic and heavy attacks, dash, special ability, targeting assist and auto-attack one at a time. Extend the shared simulation first. |
| 03.3 Combat depth | Targeting, anticipation and recovery, projectiles, armor, shields, status effects, knockback, boss telegraphs, prioritized by authored encounters |
| 03.4 Feedback | Fortress, hero, enemy count, wave number, production state, deployment, damage, status, results. Temporary visuals are labeled. |
| 03.5 Lifecycle | Pause, background/resume, rotation, interruption, return to workshop, reward claim |

**Status (2026-11-28):**
- 03.1 done in both engines (GB-025): init, prep, wave, intermission with rewards, victory or defeat, result.
- 03.2 partial: lane commands and the Wrench Quake special (GB-055). Other hero actions not evaluated yet.
- 03.3 partial: armor, shields, wind-up and cleave (GB-058) and turret projectiles (GB-037). Status effects, knockback and hero recovery pending.
- 03.4 partial: fortress, wave, SP and telegraph feedback with temporary visuals.
- 03.5 done in Flutter (GB-052, GB-053); not device-tested.
- Playable builds: the Android debug APK on the emulator and the Windows desktop debug runner. Not yet on a physical phone.

**Deliverables:** a multi-wave mission, deterministic scenarios, updated fixtures, lifecycle tests, a playable build.

**Exit:**
- A 3–5-wave mission can be completed, with gear changes between waves.
- Hero actions go through validated commands, and gear strategy stays central.
- Rewards are paid once, and state survives rotation and lifecycle changes.
- Existing fixtures pass.

## Phase 04 — Visual preproduction
**P0** · GB-009, GB-040–041 · See `ART_DIRECTION.md` · Depends on stable 02/03 contracts

**Visual direction v3 (2026-11-28):** the official identity is **Tactile Industrial Comic 2.5D**. Phase 04 covers execution steps 1–10 of `ART_DIRECTION.md` §7 and ends with the visual benchmark (ART-B).

**Tasks:**
1. Inspect the repository and reconcile the documentation. **Done** (session 21).
2. Establish the visual direction. **Documented:** `ART_DIRECTION.md` v3, `VISUAL_STYLE_BIBLE.md`, `CHARACTER_DESIGN.md`, `CHARACTER_RIGGING_GUIDE.md`, `MATERIAL_LIBRARY.md`, `ANIMATION_SPECIFICATION.md`, `ENVIRONMENT_PRODUCTION.md`, `ASSET_GENERATION_PROMPTS.md`, `ASSET_VALIDATION_GUIDE.md`, `RENDERING_ARCHITECTURE.md`, `VISUAL_PERFORMANCE_BUDGET.md`, `UI_UX_SPECIFICATION.md` v2.
3. Visual reference boards. The diagrammatic board and illustrated mood-board study are both at `concept` (`assets-source/style-bible/reference_board_v001.html`, `industrial-comic-style-study_v001.png`); neither is approved.
4. Materials and colors. **Proposed** (15-material library, palette tokens); the painted material sheet is still to be made.
5. Rivet master: turnaround, near/far limb sheet, expressions, weapon (ART-02).
6. Mechanical gear artwork: all 5 starter gears, tiers 1–3, state layers.
7. Copperwash environment and fortress concepts.
8. Illustrated portrait and landscape gameplay compositions.
9. **Visual benchmark (ART-B):** the 14-element scene, in-engine (Flutter), in portrait and landscape, with a first device reading.
10. Refine the detailed asset inventory from the benchmark (337 records now: 335 planned, 2 concept).

**Deliverables:** an approved style bible and material library, Rivet's master, gear masters, the Copperwash master, compositions, the approved benchmark, an asset inventory (**`ASSET_INVENTORY.md`, formerly `PRODUCTION_ASSET_INVENTORY.md`; `shared/art/asset_manifest.json`**) and prompts.

**Exit:** ART-01, ART-02 and ART-B approved; one coherent style; identity and proportions locked; camera and lighting documented; no proprietary assets; **no full-scale production before the benchmark is approved.**

## Phase 05 — Production vertical slice
**P0** · GB-042–045 · Depends on 03 and 04 (ART-B approved) · Execution steps 11–13, 15–18 (`ART_DIRECTION.md` §7)

| Step | Scope |
|---|---|
| 05.1 Characters | Rivet skeletal parts (independent near/far limbs), rig, weapon attachments, core animations; Rivetguard; enemies; Scrapmaw (`boss.scrapmaw`) |
| 05.2 Mechanical | Starter gear catalogue: wheels, bases, power indicators, connection and merge effects, shop illustrations, board panels and slots |
| 05.3 Environment | Copperwash layers, props, atmosphere, fortress |
| 05.4 Combat visuals | Animation playback, depth sorting, shadows, projectiles, hits, damage, shields, defeat, boss arrival |
| 05.5 UI | Workshop, shop, HUD, wave complete, victory, defeat, rewards, return |
| 05.6 Review | Capture portrait, landscape, compact phone and tablet |
| 05.7 Performance | Measure the slice on representative devices against `VISUAL_PERFORMANCE_BUDGET.md` (60 FPS target, stable 30 FPS fallback) |

**Exit:**
- ART-03, ART-04 and the relevant ART-05 pass.
- No geometric placeholder characters, no near/far inconsistencies, no broken joints.
- Gear visuals match the simulation state.
- A full mission is playable from prep to reward, and visual quality is approved before content expands.

## Phase 06 — Unity and Flutter playable parity
**P0** · GB-008, 010, 022, 036, 046 · Depends on Phase 05 standards

- **Unity:** boot flow, campaign, workshop, battle presentation, gear, character and environment views, input, responsive layout, results. Core assemblies stay presentation-free.
- **Flutter:** replace canvas primitives with Flame sprite, character, environment, animation, shadow and VFX components.
- **Shared:** same rules, IDs, configuration, missions, rewards and visual metadata, with equivalent outcomes. Rendering internals may differ.
- **Exit:** both clients complete the same mission with equivalent simulation outcomes, in both orientations, with consistent visual identity. ART-06 passes on real runtimes.

**Status (2026-11-28):** simulation, combat traces, wallet, ad policy and workshop rules match (GB-036, GB-049). Unity has no client; Flutter still draws canvas primitives.

## Phase 07 — Campaign content
**P1** · GB-013, 015, 021, 024

| Step | Scope |
|---|---|
| 07.1 | Move all 12 nodes to shared data, keeping IDs and unlocks; remove hard-coded encounters only after equivalence tests; mission schema; validator. **Done (GB-024):** every node loads shared data, equivalence pinned by `route_migration_test.dart`; the old scripts remain only as that test's baseline |
| 07.2 | Copperwash: The First Link, Rivet Ridge, The Split Gear, Dust Devil Run, Scrapjaw, each teaching a distinct concept |
| 07.3 | Ironwood and Sunken after Copperwash passes review |
| 07.4 | Illustrated map: nodes, path, stars, bosses, checkpoints, region transitions, lock states |
| 07.5 | Balance through composition, timing, lane pressure, constraints, resources, roles and bosses; not stat inflation |

**Exit:** every normal mission has a no-purchase path; progress survives restart; stars and first-clear rewards follow the rules; no impossible unlocks; missions need distinct strategies.

## Phase 08 — Expanded gamification
**P1** · GB-014, 020, 023, 032

**Preserve:** daily contracts, Scrapstorm, streak, star chests, Supply Log, Vanguard Drop.

**Add:**
- Data-driven daily pool, weekly contracts and completion chests.
- Achievements, XP and levels, hero mastery, gear collection.
- Region rewards, fixed cosmetics and more boosters.

**Rules:**
- Filter tasks by what's unlocked, and never offer impossible ones.
- Deterministic selection; count only validated events, with no progress from repeated UI clicks.
- Claims go through the ledger, and saves stay compatible.

**UI:** daily and weekly screens, achievements, profile, collection, reward track, booster inventory.

**Exit:** documented resets; no double claims; missing a day loses nothing; offline campaign works; no paid actions required; migration is correct.

## Phase 09 — LiveOps and rotating events
**P1** · GB-033

**Engine:** definitions, UTC start/end, eligibility, objectives, scoring, milestones, fixed rewards, claim deadline, offline cache, config version, flags, history.

**Lifecycle:** scheduled → upcoming → active → completed → claimable → expired → archived.

**First three events:**
1. **Scrapstorm v2:** keeps the weekly best-score behavior, adding a progress track, claim window, art, history and modifiers.
2. **Gear Frenzy:** scores valid merges only, with fixed milestones.
3. **Engineering Trials:** preset boards with limited scrap, allowed gears, objectives and deterministic configuration.

Further events later, never all at once.

**Exit:** survives restarts; expired events pay nothing; claim deadlines are respected; offline behavior documented; clock manipulation can't authorize server-backed rewards; no fake competitors.

## Phase 10 — Economy and persistence hardening
**P0 for commercial features** · GB-027, 028 · Local foundation implemented; can run in parallel

**Tasks:**
- Review the ledger, currencies, keys, migration, recovery and rollback guard.
- Add transaction tests for: claim, gear buy/sell, booster use, event reward, rewarded ad, purchase delivery, refund, duplicate callback, interrupted transaction.
- Design account-linked wallet reconciliation, premium authority, entitlement storage, trusted event time and active-mission recovery.

**Exit:** consistent after interruption; legitimate progress preserved; newer saves never overwritten; no premium grants from UI; existing ledger tests pass.

## Phase 11 — Advertising integration
**P1** · GB-029, 034 · Depends on the mission loop, Phase 10 and tooling

| Step | Scope |
|---|---|
| 11.1 | Reuse `ad_policy.json`, `AdPolicy` (Dart/C#), `MockAdProvider` and the ledger. Do not duplicate them. |
| 11.2 | Official Google Mobile Ads (Unity plugin, `google_mobile_ads`) after compatibility checks; test ad units only; production ads stay off |
| 11.3 | Consent: UMP, privacy options, age eligibility, ATT where needed |
| 11.4 | Rewarded: daily supply, victory multiplier, free reroll, Vanguard Drop. Emergency continue needs mission recovery first. Normal rewards are always granted. |
| 11.5 | Interstitials per the shared policy (after mission, once progress is saved), read from config rather than duplicated in UI |
| 11.6 | Lifecycle: no fill, load/show failure, cancel, duplicate callback, verification, pause/resume, audio, rotation |

**Exit:** test ads show on devices; no live ad interaction in automation; rewards paid exactly once; failures never block; never during combat or placement; consent validated; production flag off until release approval.

## Phase 12 — Backend and cloud services
**P1** · Blocked on account setup

- **Evaluate Firebase** (Auth, Firestore, Functions, Remote Config, Analytics, Crashlytics) and use only what is needed.
- **Build:** identity, account linking, cloud save reconciliation, trusted time, secure wallet operations, purchase and reward verification, validated remote config, access rules, rate limits, idempotency, audit logs.
- **Security:** clients cannot grant premium currency, entitlements or scores; secrets stay server-side; tokens never go into analytics; offline campaign still works.
- **Exit:** authorized calls succeed and unauthorized fail; duplicates are deduplicated; cloud conflicts are handled; environments verified.

## Phase 13 — In-app purchases
**P1** · GB-035 · Depends on 10 and 12

- **Products:** No Ads, starter bundle, Alloy packs, booster bundle, cosmetics; season later.
- **Tasks:**
  - Unity IAP and `in_app_purchase` compatibility; store products; localized prices; exact fixed contents.
  - Purchase flow with pending handling and token verification.
  - Grant once, then acknowledge or finish.
  - Restore, refund and revoke reconciliation; entitlement persistence; offline and interruption handling.
- **Supply Depot UI:** product art, contents, localized price, pending, error and restore states.
- **No Ads** disables interstitials only; rewarded ads stay optional, and this is disclosed.
- **Exit:** a sandbox purchase grants exactly once; duplicates rejected; pending, refund and revoke verified; entitlement survives restart and restore; localized prices; real money off until production approval.

## Phase 14 — Audio, onboarding and accessibility
**P1**

- **Audio:** gear sounds, activation, deployment, hits, projectiles, reactions, victory, defeat, rewards, UI, ambience, workshop, combat and boss music. Pooling, volume categories, transitions, interruptions, restore.
- **Onboarding:** a playable tutorial: buy/select, place, connect, production, start wave, lanes, merge, rewards. Gradual and non-blocking.
- **Accessibility:** volume, haptics, reduced motion, readable type, state not shown by color alone, large targets, assisted combat, pause.
- **Exit:** new players finish onboarding unaided; audio survives ads and lifecycle; playable without sound.

## Phase 15 — Performance and QA
**P0 before release**

- **Devices:** low, mid and high-end Android phones, an Android tablet, iPhone and iPad where available, a foldable or resizable viewport.
- **Aspect ratios:** 4:3 through 21:9, portrait, landscape and rotation.
- **Targets (unmeasured):** 60 FPS on mid-range, stable 30 fallback, responsive input, controlled memory, predictable loading, acceptable heat and battery.
- **Work:** profile CPU, GPU, frame time, memory and draw calls; atlases, pooling, particles, loading, widget rebuilds, startup, resume.
- **Regression:** every test suite plus device integration.
- **Exit:** no critical gameplay, save-loss or duplicate-paid defects; targets measured; release builds succeed.

## Phase 16 — Closed testing and soft launch
**P0 before launch**

- **Observe:** first interaction, tutorial, placement clarity, combat, difficulty, duration, motivation, event discovery, reward clarity, ad frustration, purchase comprehension, visual appeal.
- **Privacy-conscious metrics:** tutorial and first mission, failure rates, session length, D1/D7/D30, build diversity, events, ad opt-in, ad-related exits, conversion, crash-free rate, FPS.
- Treat targets as hypotheses. Tune difficulty, resources, costs, outputs, caps (if justified), pacing, events, ad frequency and products.
- **Exit:** fun without purchases; players understand the building; usability fixed; ads tolerable; sustainable economy; critical crashes and save bugs resolved.

## Phase 17 — Commercial release
**P0**

- **Store:** icon, screenshots, trailer, description, feature graphic, privacy policy, terms, data safety, app privacy, rating, audience, support.
- **Technical:** signing, AAB, iOS archive, production config, backend verified, crash reporting, analytics consent, purchase verification, flags, rollback.
- **Monetization:** current policies reviewed, products configured, prices verified, ads approved, No Ads verified, consent verified, support and refunds documented.
- **Exit:** release candidate approved, store validation passed, no critical defects, credentials secured, devices tested, production features enabled only through reviewed config.

## Phase 18 — Post-launch operations
**Ongoing**

- **Monitor:** stability, feedback, retention, difficulty, economy, ads, purchase errors, events.
- **Expand gradually:** regions, gears, heroes, enemies, bosses, trials, cosmetics, seasons.
- **Social systems** (leaderboards, competition, co-op, guilds, community) only with demonstrated demand.

---

## 19. Parallel workstreams

| Workstream | Scope |
|---|---|
| Gameplay | Workshop, combat, missions, campaign |
| Art | Style, Rivet, gears, environment, UI, animation, VFX |
| Platform | Builds, devices, lifecycle, layouts |
| Commercial | Economy, saves, mocks, backend design |
| Engagement | Contracts, achievements, events |

For a solo developer, keep only a few feature branches active at once.

## 20. Production gates

| Gate | Requires | Status |
|---|---|---|
| G0 Foundation | Baseline tests, fixtures, save compatibility | **Met** (local; re-verify per merge) |
| G1 Playable prototype | Gear buy/place, full mission flow, Android install or documented blocker | **Met in Flutter** with a documented Android blocker: workshop, multi-wave flow, lifecycle and checkpoints done; reviewable as a Windows debug build |
| G2 Visual direction | `ART_DIRECTION.md` v3 approved (ART-01), Rivet master (ART-02), visual benchmark (ART-B) | In progress: v3 specs, diagram board and illustrated mood-board study at concept; no art gate passed |
| G3 Vertical slice | Final character, environment, board, animations, responsive UI | Not started |
| G4 Cross-engine client | Unity and Flutter playable, parity, visual consistency | Not started |
| G5 Engagement | Campaign, contracts, achievements, events, reliable rewards | Partial: campaign, contracts, Scrapstorm and rewards done; achievements and the event engine pending |
| G6 Commercial | Consent, ads, verified purchases, entitlements, offline fallback | Not started (policy and mock only) |
| G7 Release candidate | Devices, profiling, privacy, store validation, closed test | Not started |

Never skip a gate without a documented reason, risk and approval.

## 21. Sprint order (work packages, not dates)

| Sprint | Focus | Status (2026-11-28) |
|---|---|---|
| 01 | Finish the workshop: GB-030 remainder → **GB-039** (drag, move, undo, previews) | Done in Flutter; device check pending |
| 02 | Mission loop: GB-025 (multi-wave, inter-wave prep, results, persistence, lifecycle) | Done in Flutter (GB-025, GB-052, GB-053); combat depth GB-055, GB-058, GB-037 added |
| 03 | Visual preproduction: v3 direction, reference board, materials, Rivet master, gear and Copperwash masters, compositions, benchmark (GB-040, GB-041, GB-062, GB-063) | v3 docs and diagram board done; illustrated mood-board study at concept; ART-01 owner review and the material sheet/compositions remain |
| 04 | First production art: Rivet parts and rig, animations, enemies, gears, environment layers (GB-042–044) | Not started (needs Sprint 03) |
| 05 | Playable production slice: rendering, VFX, HUD, audio (GB-045) | Not started (needs approved art) |
| 06 | Unity playable presentation and parity (GB-046, GB-036) | GB-036 and GB-049 done (rules); client not started |
| 07 | Campaign migration and progression (GB-024, GB-032) | GB-024 done; GB-051 and GB-032 next |
| 08 | First LiveOps events (GB-033) | Not started |
| 09 | Ad adapters and consent (GB-034) | Blocked (AdMob account, device build) |
| 10 | Backend and verified purchases (GB-035) | Blocked (store accounts, backend) |
| 11 | Device profiling and release quality | Not started (Android emulator builds work; a physical phone is needed for real measurements) |

Work that needs no art or accounts has been pulled forward while Sprints 03–05 wait on art production.

Resolve Phase 01 blockers in parallel throughout.

## 22. Documentation and evidence rules

- After every milestone, update `DEVELOPMENT_STATUS.md`, `TASK_BACKLOG.md`, `CROSS_ENGINE_PARITY.md`, `RISK_REGISTER.md`, `CHANGELOG.md` and the relevant technical docs.
- Tick the matching boxes in `.kiro/specs/gearbound-production/tasks.md`, the phase-wise checklist, and refresh its progress table with `python -I tools/build/phase_progress.py`.
- **Art:** manifest, concept approval, rig and animation metadata, integration status, screenshots.
- **Tests:** command, environment, date, commit, and passed/failed/skipped/blocked counts.
- Never report unexecuted verification as passing.

## 23. Commands

**Flutter:**

```
flutter pub get
flutter analyze
flutter test
flutter build apk --debug    # works with the Android Studio SDK (F:\Android\Sdk)
flutter test integration_test/baseline_device_test.dart -d emulator-5554
```

**Shared data and fixtures:**

```
python -I tools/data-validation/validate_shared.py
python -I tools/simulation/reference_rules.py --check
python -I tools/build/sync_flutter_shared.py --check
tools/simulation/generate_combat_traces.ps1 -Check
python -I tools/build/phase_progress.py --check
cd flutter; dart run tool/workshop_cases.dart --check
cd flutter; dart run tool/baseline_check.dart   # also as an AOT binary via dart compile exe
```

**Unity:** EditMode tests per `AGENTS.md`.

Never regenerate fixtures to hide a behavior change. Changes to expected simulation behavior need review and an explicit fixture update.

## 24. Risks and scope control

See `RISK_REGISTER.md`. Main risks:
- **Double effort across two engines:** one visual slice, then reuse.
- **Inconsistent AI art:** approve masters and individual assets.
- **Rig anatomy errors:** validate assembly and extreme poses.
- **Placeholder graphics persisting:** the visual slice is a mandatory gate.
- **Android verified only on the emulator:** get a physical phone for device and performance checks (Phase 15).
- **Campaign scope:** Copperwash first.
- **Disruptive ads:** shared policy and measurement.
- **Purchase fraud or duplication:** server verification and idempotency.
- **Save migration failure:** keep the migration tests.
- **Clock manipulation:** trusted time for valuable rewards.
- **Unverified performance:** device profiling.
- **Feature creep:** fixed gates.

## 25. Mapping from earlier roadmaps

| Earlier phase | Revised | Status |
|---|---|---|
| v1 Phase 0 Production foundation | 00 | Implemented |
| v1 Phase 1 Route slice | 02, 03, 07, 08 | Partial |
| v1 Phase 2 Campaign content | 07 | Partial |
| v1 Phase 3 Event calendar | 09 | Partial |
| v1 Phase 4 Polish and release | 14–17 | Planned |
| A Audit | 00 | Done |
| B Economy foundation | 10 | Local foundation done |
| C Gamification | 08 | Partial |
| D LiveOps | 09 | Planned beyond the offline Scrapstorm |
| E Gameplay and presentation | 02–07 | Partial |
| F Advertising | 11 | Policy and mock done; SDK pending |
| G IAP | 13 | Blocked |
| H Backend | 12 | Blocked |
| I Parity | 06, 08–13 | Partial |
| J Release testing | 15–17 | Pending |

Reorganizing phases never reclassifies finished tasks as unfinished.

## 26. Definition of done

A feature is done when it:
- Compiles, follows the architecture and preserves validated behavior.
- Has tests and verified interaction, and supports both orientations.
- Uses shared configuration, handles failures and preserves player data.
- Meets the visual standards and measured performance where applicable.
- Has evidence and documented limitations.

Commercial features additionally need sandbox or provider verification. Mock ads, mock payments and temporary art stay labeled.

## 27. Execution order

1. Verify `main`.
2. Resolve toolchain blockers.
3. Finish GB-030 → GB-039.
4. GB-025.
5. Art direction approval.
6. Rivet master and skeleton.
7. First gear and environment assets.
8. Production vertical slice.
9. Unity playable client.
10. Flutter parity.
11. Campaign.
12. Gamification and events.
13. Ads through the existing policy.
14. Verified purchases and backend.
15. Devices and release.

Document external blockers and continue independent work. Never claim unimplemented features, unapproved art or unexecuted tests are complete.
