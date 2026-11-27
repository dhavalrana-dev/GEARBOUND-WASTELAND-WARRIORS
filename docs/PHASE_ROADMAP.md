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

**Branches:**
- `main` = `4f50218` (PRs #1–#3 merged).
- **PR #4 (`feature/workshop-shop-ui`, `bc269a4`) is open and not merged.** It holds GB-030 and GB-031.
- This roadmap's branch is stacked on PR #4.

**Technical foundation (implemented):**
- Fixed 30 Hz simulation on a 5×5 board with reciprocal ports, graph traversal, rotation parity, merge, output clocks and lane combat.
- Wave director, seeded shop, shared JSON with validator, and an independent Python fixture generator.
- Four cross-engine combat trace scenarios that match exactly.

**Flutter progression (implemented):** 12 nodes across Copperwash Pass, Ironwood Frontier and The Sunken Yard, with best-result stars, daily contracts, Scrapstorm, Overclock Streak, Supply Log, star chests and Vanguard Drop.

**Commercial foundation (implemented, local only):**
- Ledger wallet in Dart and C#, with separated currencies and idempotent claims.
- Save v3 with v1/v2 migration, two-slot recovery and a clock-rollback guard.
- Shared ad policy in Dart and C#, plus a mock rewarded provider. Ads are disabled.

**Workshop (PR #4):**
- Shop with buy, tap-to-place, merge, sell, reroll and cancel, paid in mission-scoped battle scrap through the ledger.
- Board taps, and controls that scroll at every size.

**Recorded verification** (re-run before every merge):

| Check | Result |
|---|---|
| Unity EditMode | 30/30 |
| Flutter tests | 106/106 on PR #4 (88/88 on `main`) |
| Flutter analyze | Clean |
| Validator, reference fixtures, asset sync, combat traces | Clean |

**Limitations:**
- No production art.
- Unity is a simulation library only, with no playable client.
- Workshop: no drag-and-drop, gear moves, or undo after placement.
- 1 of 12 route nodes uses shared data.
- Single-wave missions only.
- No ad SDK, consent, IAP or backend.
- Android build blocked on the NDK license (re-checked this session, see `DEVELOPMENT_STATUS.md`).
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
| 00 | Repository and simulation foundation | Implemented; device verification pending |
| 01 | Toolchain and build readiness | **Blocked** (Android NDK license, user action) |
| 02 | Complete mechanical workshop | **Implemented in Flutter** (shop, drag, move, undo, previews); device test and Unity port (GB-036) pending |
| 03 | Combat and multi-wave mission flow | In progress (single wave only) |
| 04 | Visual preproduction | Planned (asset manifest created, all `planned`) |
| 05 | Production vertical slice | Planned |
| 06 | Unity and Flutter playable parity | Partial (simulation, economy and ad-policy parity only) |
| 07 | Campaign content | Partial (1/12 nodes on shared data) |
| 08 | Expanded gamification | Partial (existing systems) |
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

## Phase 01 — Toolchain and mobile build readiness
**P0 · Blocked** · GB-012, GB-038

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
- *Remaining:* gear art (or labeled temporary art), tier display, output preview.
- Offer locking: the rule exists in `rollShop`, but there is no UI.
- Pricing must come from the shared shop rules, never the UI.

**02.2 Placement**
- *Done:* tap-to-select, tap-to-place, valid-cell highlight, occupancy validation.
- *Remaining (GB-039):* drag-and-drop, drag ghost and snapping, invalid-cell preview, port/connection and power preview, touch cancel, and orientation-aware input mapping. Tap mapping is already tested in both orientations.

**02.3 Manipulation**
- *Done:* merge, sell, cancel unplaced purchase, and power state shown through the indicators.
- *Remaining (GB-039):* moving placed gears, rotation (meaningful only once gears with partial ports exist), undo after placement, a conflict explanation, and an interval preview.
- Define atomic transaction boundaries for each action.

**02.4 Battle economy**
- *Done:* battle scrap in a mission wallet, separate from permanent currency; ledger-checked spends and refunds; no negative balances.
- *Remaining:* recovery if the app is interrupted mid-mission (Phase 03.5).

**02.5 Refactoring**
- *Done:* `features/campaign`, `features/workshop`, `design_system`.
- *Remaining:* reusable board, shop and currency components when production art lands.

**Exit:**
- Purchase, place, (rotate,) merge and sell all work, and power updates immediately.
- All costs go through the ledger; invalid actions change nothing.
- Edits are blocked outside preparation, and the shop fixtures stay valid.
- The Unity workshop follows once a Unity UI exists (GB-036).

## Phase 03 — Complete combat and mission flow
**P0** · GB-006, 007, 011, 015, 025 · Depends on Phase 02

| Step | Scope |
|---|---|
| 03.1 Battle session | Explicit states: init → prep → wave → wave complete → inter-wave rewards → prep → … → victory/defeat → result → route |
| 03.2 Hero | Keep lane commands. Evaluate horizontal movement, basic and heavy attacks, dash, special ability, targeting assist and auto-attack one at a time. Extend the shared simulation first. |
| 03.3 Combat depth | Targeting, anticipation and recovery, projectiles, armor, shields, status effects, knockback, boss telegraphs, prioritized by authored encounters |
| 03.4 Feedback | Fortress, hero, enemy count, wave number, production state, deployment, damage, status, results. Temporary visuals are labeled. |
| 03.5 Lifecycle | Pause, background/resume, rotation, interruption, return to workshop, reward claim |

**Deliverables:** a multi-wave mission, deterministic scenarios, updated fixtures, lifecycle tests, a playable build.

**Exit:**
- A 3–5-wave mission can be completed, with gear changes between waves.
- Hero actions go through validated commands, and gear strategy stays central.
- Rewards are paid once, and state survives rotation and lifecycle changes.
- Existing fixtures pass.

## Phase 04 — Visual preproduction
**P0** · GB-009, GB-040–041 · See `ART_DIRECTION.md` · Depends on stable 02/03 contracts

**Tasks:**
- Style references: palette, shape language, proportions, projection, readability targets and UI style.
- Rivet: concept, turnaround and weapon.
- Concepts for enemies, starter gears, the Copperwash environment and the fortress.
- Portrait and landscape compositions.

**Deliverables:** approved style bible, character master, environment master, board design, UI examples, asset inventory (**created: `PRODUCTION_ASSET_INVENTORY.md`, `shared/art/asset_manifest.json`**), prompts.

**Exit:** ART-01 and ART-02 approved; one coherent style; identity and proportions locked; camera and lighting documented; no proprietary assets; no production assets before concept approval.

## Phase 05 — Production vertical slice
**P0** · GB-042–045 · Depends on 03 and 04

| Step | Scope |
|---|---|
| 05.1 Characters | Rivet skeletal parts (independent near/far limbs), rig, weapon attachments, core animations; Rivetguard; enemies; Scrapmaw (`boss.scrapmaw`) |
| 05.2 Mechanical | Starter gear catalogue: wheels, bases, power indicators, connection and merge effects, shop illustrations, board panels and slots |
| 05.3 Environment | Copperwash layers, props, atmosphere, fortress |
| 05.4 Combat visuals | Animation playback, depth sorting, shadows, projectiles, hits, damage, shields, defeat, boss arrival |
| 05.5 UI | Workshop, shop, HUD, wave complete, victory, defeat, rewards, return |
| 05.6 Review | Capture portrait, landscape, compact phone and tablet |

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

## Phase 07 — Campaign content
**P1** · GB-013, 015, 021, 024

| Step | Scope |
|---|---|
| 07.1 | Move all 12 nodes to shared data, keeping IDs and unlocks; remove hard-coded encounters only after equivalence tests; mission schema; validator |
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
| G1 Playable prototype | Gear buy/place, full mission flow, Android install or documented blocker | Partial: shop in PR #4; multi-wave missing; Android blocked |
| G2 Visual direction | `ART_DIRECTION.md` approved, Rivet master, battlefield composition | Not started |
| G3 Vertical slice | Final character, environment, board, animations, responsive UI | Not started |
| G4 Cross-engine client | Unity and Flutter playable, parity, visual consistency | Not started |
| G5 Engagement | Campaign, contracts, achievements, events, reliable rewards | Partial |
| G6 Commercial | Consent, ads, verified purchases, entitlements, offline fallback | Not started (policy and mock only) |
| G7 Release candidate | Devices, profiling, privacy, store validation, closed test | Not started |

Never skip a gate without a documented reason, risk and approval.

## 21. Sprint order (work packages, not dates)

| Sprint | Focus |
|---|---|
| 01 | Finish the workshop: GB-030 remainder → **GB-039** (drag, move, undo, previews) |
| 02 | Mission loop: GB-025 (multi-wave, inter-wave prep, results, persistence, lifecycle) |
| 03 | Visual preproduction: Rivet master, proportions, gear concepts, Copperwash concept, wireframes, manifest (GB-040, GB-041) |
| 04 | First production art: Rivet parts and rig, animations, enemies, gears, environment layers (GB-042–044) |
| 05 | Playable production slice: rendering, VFX, HUD, audio (GB-045) |
| 06 | Unity playable presentation and parity (GB-046, GB-036) |
| 07 | Campaign migration and progression (GB-024, GB-032) |
| 08 | First LiveOps events (GB-033) |
| 09 | Ad adapters and consent (GB-034) |
| 10 | Backend and verified purchases (GB-035) |
| 11 | Device profiling and release quality |

Resolve Phase 01 blockers in parallel throughout.

## 22. Documentation and evidence rules

- After every milestone, update `DEVELOPMENT_STATUS.md`, `TASK_BACKLOG.md`, `CROSS_ENGINE_PARITY.md`, `RISK_REGISTER.md`, `CHANGELOG.md` and the relevant technical docs.
- **Art:** manifest, concept approval, rig and animation metadata, integration status, screenshots.
- **Tests:** command, environment, date, commit, and passed/failed/skipped/blocked counts.
- Never report unexecuted verification as passing.

## 23. Commands

**Flutter:**

```
flutter pub get
flutter analyze
flutter test
flutter build apk --debug    # blocked: Android NDK license (Phase 01)
```

**Shared data and fixtures:**

```
python -I tools/data-validation/validate_shared.py
python -I tools/simulation/reference_rules.py --check
python -I tools/build/sync_flutter_shared.py --check
tools/simulation/generate_combat_traces.ps1 -Check
```

**Unity:** EditMode tests per `AGENTS.md`.

Never regenerate fixtures to hide a behavior change. Changes to expected simulation behavior need review and an explicit fixture update.

## 24. Risks and scope control

See `RISK_REGISTER.md`. Main risks:
- **Double effort across two engines:** one visual slice, then reuse.
- **Inconsistent AI art:** approve masters and individual assets.
- **Rig anatomy errors:** validate assembly and extreme poses.
- **Placeholder graphics persisting:** the visual slice is a mandatory gate.
- **Android build blocked:** prioritize the toolchain.
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
