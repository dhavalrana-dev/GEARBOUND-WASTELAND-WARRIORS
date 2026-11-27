# Cross-engine parity contract

Shared JSON under `shared/` is the source of truth. Both engines load the same `schemaVersion`, run integer ticks at 30 Hz, and use the same stable identifiers.

## Fixture pipeline

`tools/simulation/reference_rules.py` is an independent Python implementation of the shared random algorithm, shop roll and wave expansion. It writes:

- `shared/test-fixtures/random_vectors.json`: `xorshift32-v1` sequences (seeds 1, 42, 0, 2463534242, 4294967295) and `NextInt` mapping.
- `shared/test-fixtures/shop_cases.json`: seeded shop rolls (locks, unlock filters, connectivity guarantee) and reroll costs.
- `shared/test-fixtures/mission_001_spawns.json`: the expanded spawn schedule for `waves/mission_001.json`.

Run `python -I tools/simulation/reference_rules.py --check` to confirm fixtures match the current data. C# (`SharedRulesTests`) and Dart (`test/data/shared_rules_test.dart`) each replay the fixtures.

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
| Shop roll / reroll cost / sell value | Yes | Yes (no UI yet) | shop_cases ✔ both |
| Wave director from shared JSON | Yes | Yes (runtime assets; route node 1 migrated) | mission_001_spawns ✔ both |
| Campaign route, stars, contracts, weekly event | No | Yes | — |
| Streak, star chests, Supply Log, boosters | No | Yes | progression_rewards.json ↔ Dart constants |
| Wallet ledger (idempotency, premium verification, caps) | Yes | Yes | reward_transaction_cases ✔ both |
| Ad placement policy | Yes | Yes | ad_policy_cases ✔ both |
| Save migration v1/v2 → v3 | n/a (no Unity save yet) | Yes | save_migration_cases (Dart) |
| Workshop shop/placement/merge controller (merge curve, lane by row) | No | Yes | — (GB-036) |
| Multi-wave BattleSession (intermission, soldier withdrawal, hero reset, reward totals) | Yes | Yes | Mirrored unit tests (no shared trace yet) |
| Workshop seed derivation `mixSeed32` (fmix32) | No | Yes | Dart vectors only (GB-049) |
| Hero SP and special (Wrench Quake) | Yes | Yes | combat_traces `boss-wave-hero-special` ✔ both; heroes.json parity tests |
| Presentation / input | No | Prototype | — |

## Combat trace parity (spec scenario 4)

`shared/test-fixtures/combat_scenarios.json` holds hand-written inputs: board, wave, world length and hero commands. `tools/simulation/generate_combat_traces.ps1` runs the Unity Core sources under Unity's bundled Mono and writes `combat_traces.json`.

Each tick, both runners hash `tick|phase|fortress|` plus `id:lane:pos:hp:shield:state;` for every combatant in ID order, using 32-bit FNV-1a. A checkpoint hash every 30 ticks locates the first point of divergence.

**Status:** all 4 scenarios match exactly in Dart and in the Unity editor (verified 2026-11-27). Combat currently uses no randomness. When critical hits or other random effects arrive, they must draw from `SeededRandom` in a documented order, and new scenarios must cover them.
