---
inclusion: always
---

# Repository structure

| Path | Contents |
|---|---|
| `shared/` | Source of truth: `configs/`, `gears/`, `enemies/`, `heroes/`, `waves/` (one mission per route node), `missions/campaign_route.json`, `economy/`, `events/`, `monetization/`, `art/asset_manifest.json`, `schemas/`, `test-fixtures/` |
| `unity/Assets/Game/Core` | Simulation: gear network, output clocks, combat, battle session, shop, wave director, shared loaders |
| `unity/Assets/Game/Economy` | Wallet ledger, ad policy |
| `unity/Assets/Game/Workshop` | Workshop controller rules |
| `unity/Assets/Tests/EditMode` | NUnit tests, including fixture replays |
| `flutter/lib/mechanical`, `combat`, `core`, `economy` | Dart mirrors of the shared rules (engine-independent) |
| `flutter/lib/data` | Shared JSON loaders; runtime asset bundle |
| `flutter/lib/features` | `campaign/` hub and `workshop/` screen, controller, checkpoints |
| `flutter/lib/game` | Flame rendering and input |
| `flutter/lib/progression`, `services` | Campaign progress, rewards, saves; ad policy and mock provider |
| `flutter/assets/shared` | Synced copy of runtime shared JSON (never edit by hand) |
| `flutter/tool` | Pure-Dart tools, e.g. the workshop fixture generator |
| `tools/` | Validator, Python reference rules, asset sync, combat trace generator, phase progress check |
| `docs/` | Design, roadmap, backlog, status, parity, art direction |
| `.kiro/specs/gearbound-production` | Requirements, design and the phase checklist |

## Conventions
- Gameplay IDs are stable dotted strings (`unit.rivetguard`, `boss.scrapmaw`); never renumber backlog IDs (GB-xxx).
- A change to shared data is followed by the asset sync, the validator and the fixture checks.
- Every rule change lands in both engines with mirrored tests, plus a fixture or trace when behavior is shared.
- After finishing a task: tick it in `tasks.md`, update the progress table, add evidence to `docs/DEVELOPMENT_STATUS.md` and the backlog row.
