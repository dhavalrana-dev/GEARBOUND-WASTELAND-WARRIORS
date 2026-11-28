# Cross-engine parity contract

Shared JSON under `shared/` is the source of truth. Both engines load the same `schemaVersion`, run integer ticks at 30 Hz, and use the same stable identifiers.

## Fixture pipeline

`tools/simulation/reference_rules.py` is an independent Python implementation of the shared random algorithm, shop roll and wave expansion. It writes:

- `shared/test-fixtures/random_vectors.json`: `xorshift32-v1` sequences (seeds 1, 42, 0, 2463534242, 4294967295) and `NextInt` mapping.
- `shared/test-fixtures/shop_cases.json`: seeded shop rolls (locks, unlock filters, connectivity guarantee) and reroll costs.
- `shared/test-fixtures/mission_001_spawns.json`: the expanded spawn schedule for `waves/mission_001.json`.

Run `python -I tools/simulation/reference_rules.py --check` to confirm fixtures match the current data.

`flutter/tool/baseline_check.dart` replays the random, shop, wave, combat-trace and workshop fixtures outside the test runner, so they can also be checked in an ahead-of-time compiled binary (`dart compile exe`). That is how release and phone builds run Dart. Verified on the VM and as AOT on Windows x64 (2026-11-28); ARM64 on a phone is still to do (Phase 01).

`flutter/tool/workshop_cases.dart` writes `shared/test-fixtures/workshop_cases.json`: `mixSeed32` vectors and six scripted workshop sessions (ops plus the full state after each op: result, battle scrap, offers, held offers, hand, selection, rerolls, lock and every board gear with its ID, tier, lane and interval). Unlike the Python fixtures, the expected values come from the Dart controller, and Unity's `WorkshopFixtureTests` replays them step for step through the independent C# port. Check with `dart run tool/workshop_cases.dart --check` from `flutter/`; `workshop_fixture_test.dart` fails too when it is stale. C# (`SharedRulesTests`) and Dart (`test/data/shared_rules_test.dart`) each replay the fixtures.

## Shared algorithms

- **Random (`xorshift32-v1`)**: shifts 13/17/5 on a uint32 state. Seed 0 is replaced by `0x9E3779B9`. `NextInt(n) = (NextUint() * n) >> 32`, one draw per call, no rejection loop (bias below 2^-31 per call for small n, accepted). The Dart version needs 64-bit ints, so web is unsupported.
- **Shop roll**: the pool is non-excluded, unlocked gears with positive rarity weight, ordered by ordinal ID. Each unlocked slot draws once among pool entries under the per-offer copy cap. Then, if the board and offers both lack the guaranteed category, the last unlocked slot becomes that category's cheapest gear. The guarantee uses no RNG.
- **Wave expansion**: spawn k of a group fires at `firstSpawnTick + k·intervalTicks` in lane `lanePattern[k mod len]`. Order is by tick, lane, group index, then k.

## Feature parity matrix

| Feature | Unity (C#) | Flutter (Dart) | Shared fixture |
|---|---|---|---|
| Gear network, rotation parity, booster cap | Yes | Yes | network_cases (descriptive) |
| Merge | Yes | Yes | — |
| Output clocks and lane unit cap | Yes | Yes | — |
| Lane combat and battle session | Yes | Yes | combat_traces ✔ both |
| Seeded random | Yes | Yes | random_vectors ✔ both |
| Shop roll / reroll cost / sell value | Yes | Yes (workshop shop UI) | shop_cases ✔ both |
| Wave director from shared JSON | Yes | Yes (runtime assets) | mission_001_spawns ✔ both |
| Campaign route missions (all 12 nodes) | Yes (loads and builds every node; no route UI) | Yes | `RouteMissionTests` (C#), `route_migration_test.dart` (equivalence to the old scripts) |
| Campaign route, stars, contracts, weekly event | No | Yes | — |
| Streak, star chests, Supply Log, boosters | No | Yes | progression_rewards.json ↔ Dart constants |
| Wallet ledger (idempotency, premium verification, caps) | Yes | Yes | reward_transaction_cases ✔ both |
| Ad placement policy | Yes | Yes | ad_policy_cases ✔ both |
| Save migration v1/v2 → v3 | n/a (no Unity save yet) | Yes | save_migration_cases (Dart) |
| Workshop controller (buy, place, merge, move, sell, undo, reroll, offer holds, lock, intermission, preview) | Yes (rules only, no UI; no checkpoint restore) | Yes | workshop_cases ✔ both |
| Multi-wave BattleSession (intermission, soldier withdrawal, hero reset, reward totals) | Yes | Yes | Mirrored unit tests (no shared trace yet) |
| Workshop seed derivation `mixSeed32` (fmix32) | Yes | Yes | workshop_cases `mixSeed32` vectors ✔ both |
| Hero SP and special (Wrench Quake) | Yes | Yes | combat_traces `boss-wave-hero-special` ✔ both; heroes.json parity tests |
| Attack wind-up and cleave (boss telegraphs) | Yes | Yes | combat_traces (boss scenarios + `boss-cleave-crowded-lane`) ✔ both |
| Turret projectiles (lane shots, cap 24) | Yes | Yes | combat_traces `turret-side-lanes` ✔ both |
| Presentation / input | No (device-baseline scene only) | Prototype (canvas primitives) | — |
| On-device fixture baseline | Yes (`DeviceBaseline`, IL2CPP on the Android emulator) | Yes (`baseline_device_test.dart`, debug and AOT on the emulator) | random, shop, wave, combat-trace and workshop fixtures ✔ both |

## Combat trace parity (spec scenario 4)

`shared/test-fixtures/combat_scenarios.json` holds hand-written inputs: board, wave, world length and hero commands. `tools/simulation/generate_combat_traces.ps1` runs the Unity Core sources under Unity's bundled Mono and writes `combat_traces.json`.

Each tick, both runners hash `tick|phase|fortress|` plus `id:lane:pos:hp:shield:state;` for every combatant in ID order, then `P{id}:{lane}:{pos};` for every live projectile (empty without turrets, so older hashes are unchanged), using 32-bit FNV-1a. A checkpoint hash every 30 ticks locates the first point of divergence.

**Status:** all 7 scenarios match exactly in Dart and in the Unity editor (verified 2026-11-27). Combat currently uses no randomness. When critical hits or other random effects arrive, they must draw from `SeededRandom` in a documented order, and new scenarios must cover them.

## Visual parity (planned, `RENDERING_ARCHITECTURE.md` §7)

The engines share **metadata and images, not rendering internals**: Unity shaders, rigs and prefabs are never assumed to work in Flutter.

| Visual contract | Shared source | Proof (planned) |
|---|---|---|
| Lane projection, scale and sort order | `shared/art/projection.json` | `projection_cases.json` evaluated by C# and Dart (GB-064) |
| Character parts, bones, sockets, draw order | `shared/art/character_rigs.json` | Pose snapshots at fixed clip times compared across engines |
| Animation timing and events | `shared/art/animation_catalog.json` | Event ticks match the simulation events in both engines |
| UI tokens and kit | `shared/art/ui_tokens.json` and the nine-slice images | Paired screenshots of the benchmark screens |
| Gear states | `GearNetwork` state + gear layers | Paired captures of the same board in both engines |

**Status:** none of these exist yet. Unity has no presentation layer, and Flutter draws canvas primitives. The first proof comes with the benchmark (GB-063) and GB-064.
