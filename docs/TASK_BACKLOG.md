# Task backlog

Statuses: `todo`, `in progress`, `blocked`, `done`. A task is done only after its acceptance evidence exists.

| ID | Priority | Task | Dependencies | Acceptance criteria | Tests / deliverables | Status |
|---|---|---|---|---|---|---|
| GB-001 | P0 | Audit workspace and toolchains | — | Installed versions and missing tools recorded | DEVELOPMENT_STATUS.md | done |
| GB-002 | P0 | Analyze reference games and establish original direction | GB-001 | Evidence-backed mechanics/presentation notes and boundaries | REFERENCE_GAME_ANALYSIS.md | in progress |
| GB-003 | P0 | Define shared rules/data schema | GB-001 | Versioned schema, stable IDs, deterministic rules | shared/schema + configs | in progress |
| GB-004 | P0 | Implement gear board, merge, and graph power traversal | GB-003 | Valid placement, merge, and deterministic active/conflict states | Unity EditMode and Mono smoke checks | in progress |
| GB-005 | P0 | Implement fixed-tick output clocks and caps | GB-004 | Output timing is bounded and seed-independent absent RNG | Simulation tests | in progress |
| GB-006 | P0 | Implement three-lane combat simulation | GB-003 | Hero, units, enemies, damage and fortress outcome | Combat fixtures | in progress |
| GB-007 | P0 | Connect gear outputs to combat events | GB-005, GB-006 | Powered modules produce bounded, observable effects | Integration scenario | in progress |
| GB-008 | P1 | Add responsive Unity presentation and input | GB-007 | Portrait and landscape maintain readable play | Layout/input tests | todo |
| GB-009 | P1 | Produce original Rivet and gear art | Art direction | Approved layered asset specs and runtime exports | Asset inventory | todo |
| GB-010 | P1 | Implement Flutter/Flame parity runtime | GB-003, GB-007 | Same fixtures pass under Dart implementation | Dart tests | in progress |
| GB-011 | P1 | Implement mission loop, save, rewards and workshop | GB-007 | One mission starts, completes, saves and returns | Integration tests | in progress |
| GB-012 | P1 | Build and profile mobile targets | GB-008, GB-011 | Android build succeeds; device performance reported | Build/profile report | todo |
| GB-013 | P1 | Add campaign route, unlocks, and star ratings | GB-011 | Cleared nodes unlock in order; best score survives app restart | Progression model tests and route UI | in progress |
| GB-014 | P1 | Add daily contracts and weekly event track | GB-013 | Tasks reset by day; weekly best scores and reward claims cannot be farmed | Event/task boundary tests | in progress |
| GB-015 | P1 | Author and balance the first five route encounters | GB-013 | Distinct enemy scripts, star thresholds, and optional objectives | Encounter data and playtest notes | in progress |
| GB-016 | P0 | Shared seeded RNG with test vectors | GB-003 | C# and Dart reproduce Python reference vectors | random_vectors.json; Unity + Dart tests | done |
| GB-017 | P0 | Seeded gear shop (weights, copies, locks, guarantee, reroll cost) | GB-016 | Both engines match shop_cases.json | GearShop.cs, shared_rules.dart, tests | done (rules); Flutter shop UI todo |
| GB-018 | P0 | Data-driven wave director and enemy archetypes | GB-003 | Both engines expand mission_001 identically | enemies.json, mission_001_spawns.json, tests | done (rules); campaign UI migration todo |
| GB-019 | P1 | Shared data validator and fixture freshness check | GB-003 | Validator and `--check` run clean | tools/data-validation, tools/simulation | done |
| GB-020 | P1 | Earn-only gamification: streak, star chests, Supply Log, boosters | GB-013 | Rules tested; JSON↔Dart parity test; offline, no paid randomness | rewards.dart, rewards_test.dart, hub/workshop UI, widget tests | in progress (widget-tested; device check and playtest pending) |
| GB-021 | P1 | Bundle shared JSON as Flutter assets and drive campaign waves from it | GB-018 | Flutter campaign loads shared missions at runtime | sync_flutter_shared.py, shared_content.dart, campaign_route.json, tests | in progress (pipeline done; 1 of 12 nodes migrated) |
| GB-022 | P1 | Cross-engine combat trace fixture (spec scenario 4) | GB-016 | Same seed/config gives identical combat event trace in both engines | combat_scenarios.json, combat_traces.json, C#/Dart runners | done (4 scenarios) |
| GB-024 | P1 | Migrate route nodes 2–12 to shared mission data | GB-021 | Each node's spawns defined in shared JSON; balance change reviewed | campaign_route.json, missions | todo |
| GB-025 | P1 | Multi-wave missions with inter-wave preparation in Flutter | GB-021 | Spec loop steps 19–23 playable: wave, reward, rebuild, next wave | battle flow + tests | todo |
| GB-026 | P0 | Repository audit (extension Phase A) | — | Findings cite files; baseline re-run | docs/REPOSITORY_AUDIT.md | done |
| GB-027 | P0 | Wallet + idempotent ledger, separated currencies (Dart + C#) | GB-026 | reward_transaction_cases pass in both engines | wallet.dart, Wallet.cs, currencies.json | done |
| GB-028 | P0 | Save v3, v1/v2 migration, two-slot store, corruption recovery, clock guard | GB-027 | save_migration_cases pass; corrupted primary recovers; newer saves never overwritten | campaign_store.dart, save_migration_test.dart | done |
| GB-029 | P1 | Ad policy engine + mock rewarded controller | GB-027 | ad_policy_cases pass in both engines; grant-once under duplicate callbacks | ad_policy.dart, ad_provider.dart, AdPolicy.cs | done (no SDK) |
| GB-030 | P0 | Gear shop + placement UI in Flutter workshop (battle scrap) | GB-017, GB-027 | Buy, place, merge, reroll and sell with battle_scrap through the ledger | workshop_controller.dart, shop panel, board taps, controller and widget tests | done (tap-to-place; drag-and-drop and device check pending) |
| GB-031 | P1 | Split gearbound_app.dart into feature modules | — | No behavior change; all tests pass | lib/features/*, design_system/tokens.dart | done |
| GB-036 | P1 | Port merge curve, lane-by-row and workshop controller rules to Unity | GB-030 | Shared workshop fixture passes in both engines | C# controller + fixture | todo |
| GB-037 | P2 | Implement turret output behavior so the Spark Turret can be sold | GB-030 | Powered turret fires on its clock; combat trace scenario added | output system + traces | todo |
| GB-038 | P0 | Android toolchain readiness (roadmap Phase 01) | — | `flutter doctor` Android OK; debug APK built and installed on a device or emulator | docs/TOOLCHAIN_REPORT.md, APK, logs | blocked (user: install a user-profile SDK and accept licenses; see report) |
| GB-039 | P0 | Workshop completion: drag-and-drop, drag ghost, move placed gear, undo after placement, port/power/interval previews | GB-030 | Phase 02 exit criteria; ledger-backed undo; tests in both orientations | workshop controller, Flame input, widget tests | todo |
| GB-040 | P0 | ART-01 visual direction: mood board, palette lock, style references, portrait/landscape compositions | — | ART-01 approved by the project owner | style_* manifest records → approved_concept | todo (needs art production and owner review) |
| GB-041 | P0 | ART-02 Rivet master: turnaround, proportion, color, weapon, modular-part sheets | GB-040 | ART-02 approved | chr_rivet_* concept records | todo |
| GB-042 | P0 | ART-03 Rivet skeletal parts, rig and P0 animations | GB-041 | No joint gaps, correct near/far parts, animations bound to simulation events | chr_rivet_* parts, rig, anim records | todo |
| GB-043 | P0 | ART-04 starter gear and board art (layered wheels, tiers, overlays) | GB-040 | All gear states readable at gameplay scale in both orientations | gear_*, ui_board_* records | todo |
| GB-044 | P0 | ART-04 Copperwash environment, fortress, units, enemies, Scrapmaw | GB-040 | Coherent battlefield composition | env_*, fortress_*, chr_* records | todo |
| GB-045 | P0 | Flutter/Flame sprite rendering pipeline: projection.json, depth sort, gear components, layers, VFX pooling | GB-042, GB-043, GB-044 | Approved assets render from shared metadata; FPS measured on device | rendering components + tests | todo |
| GB-046 | P0 | Unity playable client (boot, campaign, workshop, battle presentation, input, layouts) | GB-036, GB-045 | Same representative mission completes in Unity and Flutter | Unity scenes and assemblies | todo |
| GB-047 | P1 | Resolve the Scrapjaw/Scrapmaw boss naming conflict (ART-ID-01) | — | One display name used consistently; IDs unchanged | campaign_progress.dart, enemies.json | todo (owner decision) |
| GB-048 | P1 | Production asset manifest, schema and validator rules | — | 316 slice records validate; bad statuses and owners rejected | shared/art/asset_manifest.json, docs/PRODUCTION_ASSET_INVENTORY.md | done |
| GB-032 | P1 | Data-driven daily/weekly contract pools and achievements | GB-027 | Deterministic daily selection, unlock filtering, completion chest | shared/events/*, tests | todo |
| GB-033 | P1 | Event engine: Scrapstorm v2, Gear Frenzy, Engineering Trials | GB-032 | Lifecycle states, claim windows, offline cache | event_catalog.json, tests | todo |
| GB-034 | P1 | Real ad SDK + UMP consent behind policy (Phase F) | GB-029 | Google test ads in a debug build; consent gating verified on device | ads service | blocked (AdMob account, device build) |
| GB-035 | P1 | IAP with server verification (Phases G–H) | GB-027 | Sandbox purchase verified server-side; restore works | purchase service + backend | blocked (store accounts, backend) |
| GB-023 | P2 | Achievements and rotating weekly event rule sets | GB-020 | Data-driven, offline, cosmetic/earn-only rewards | progression_rewards.json extension | todo |
