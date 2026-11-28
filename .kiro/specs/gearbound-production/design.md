# Design Document

## Overview

GEARBOUND keeps one rules core described by shared JSON and implemented twice: Unity C# (the reference runtime) and Dart (inside the Flutter/Flame client). Shared fixtures prove the two implementations agree, so either client can present the same game. This document summarizes the design; the detail lives in the linked docs.

## Architecture

```
shared/ (versioned JSON: rules, content, fixtures)
   │                         │
   ▼                         ▼
Unity Gearbound.Core,     Flutter lib/mechanical, combat,
Economy, Workshop (C#)    economy, features/workshop (Dart)
   │                         │
   ▼                         ▼
(no client yet, GB-046)   Flame board and battlefield + Flutter screens
```

- **Simulation:** 30 Hz fixed ticks, stable IDs, `xorshift32-v1` randomness. See `docs/MECHANICAL_ENGINE.md` and `docs/COMBAT_ENGINE.md`.
- **Gear network:** a 5×5 board with reciprocal orthogonal ports, one core per component, alternating rotation parity, jams on odd loops and conflicts on multiple cores, and boosters capped by config.
- **Outputs:** fixed clocks spawn infantry (4 per lane) or fire turret projectiles (24 live), and hold one pending output when capped.
- **Battle session:** waves from the wave director, intermissions with rewards and a rebuild, hero lane commands and the SP special, boss wind-up and cleave.
- **Workshop:** a seeded shop (`mixSeed32` seed), mission-scoped battle scrap in a ledger wallet, and placement, drag, merge, sell and undo. See `docs/FLUTTER_ARCHITECTURE.md`.
- **Economy and saves:** an idempotent ledger with separated currencies, save v3 with migration, two-slot recovery and a clock-rollback guard. See `docs/REWARD_TRANSACTION_SYSTEM.md` and `docs/SAVE_MIGRATION.md`.
- **Monetization:** a shared ad policy and a mock provider only. See `docs/MONETIZATION_STRATEGY.md`.

## Components and Interfaces

| Component | Unity | Flutter | Shared proof |
|---|---|---|---|
| RNG and seeds | `SeededRandom`, `MixSeed32` | `seeded_random.dart` | `random_vectors.json`, `workshop_cases.json` |
| Gear network | `GearNetwork.cs` | `gear_network.dart` | `network_cases.json` |
| Shop | `GearShop.cs` | `shared_rules.dart` | `shop_cases.json` |
| Waves | `WaveDirector.cs` | `scheduleWave` / `buildWave` | `mission_001_spawns.json` |
| Combat | `CombatSimulation.cs`, `BattleSession.cs` | `combat/` | `combat_traces.json` (8 scenarios) |
| Workshop | `WorkshopController.cs` | `workshop_controller.dart` | `workshop_cases.json` |
| Wallet | `Wallet.cs` | `wallet.dart` | `reward_transaction_cases.json` |
| Ad policy | `AdPolicy.cs` | `ad_policy.dart` | `ad_policy_cases.json` |

The full matrix is in `docs/CROSS_ENGINE_PARITY.md`.

## Data Models

The schemas live in `shared/schemas/`. The main documents are `gear_rules.json`, `starter_gears.json`, `enemies.json`, `heroes.json`, the `waves/*.json` missions, `campaign_route.json`, `shop.json`, `currencies.json`, `ad_policy.json`, `progression_rewards.json` and `art/asset_manifest.json`.

## Error Handling

- The loaders reject an unknown `schemaVersion` and duplicate IDs.
- The ledger rejects invalid, unverified-premium, insufficient and overflowing transactions, and returns duplicates without applying them.
- A corrupt save falls back to the second slot.
- A checkpoint that no longer fits the data is discarded.

## Testing Strategy

- Mirrored rule tests in both engines for every rule change.
- Shared fixtures: Python-generated (`reference_rules.py`), C#-generated (combat traces) and Dart-generated (workshop cases), each replayed by the other engine.
- Flutter widget tests for screens, layouts and lifecycle; headless balance probes become guard tests.
- Device: `integration_test/baseline_device_test.dart` replays the fixtures on Android (emulator, debug and AOT) and checks the app opens on the route. Not yet done: a physical phone and performance measurements; never claim either without evidence.

## Visual Direction

The official identity is **Tactile Industrial Comic 2.5D**: `docs/ART_DIRECTION.md` v3 holds the decisions, gates (ART-01 to ART-06, plus the ART-B visual benchmark) and the 19-step execution order. It maps every topic to a specification: `VISUAL_STYLE_BIBLE`, `MATERIAL_LIBRARY`, `CHARACTER_DESIGN`, `CHARACTER_RIGGING_GUIDE`, `ANIMATION_SPECIFICATION`, `ENVIRONMENT_PRODUCTION`, `UI_UX_SPECIFICATION`, `RENDERING_ARCHITECTURE`, `VISUAL_PERFORMANCE_BUDGET`, `ASSET_GENERATION_PROMPTS`, `ASSET_VALIDATION_GUIDE` and `ASSET_INVENTORY`.

Rendering shares metadata and images between the engines, not internals (`RENDERING_ARCHITECTURE.md`). `shared/art/asset_manifest.json` (337 records; one working concept, nothing approved) tracks every vertical-slice asset through its approval gates.
