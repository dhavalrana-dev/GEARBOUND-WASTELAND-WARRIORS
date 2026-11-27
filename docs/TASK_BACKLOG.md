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
| GB-023 | P2 | Achievements and rotating weekly event rule sets | GB-020 | Data-driven, offline, cosmetic/earn-only rewards | progression_rewards.json extension | todo |
