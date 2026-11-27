# Repository audit

Audited 2026-11-27 at `main` = `931f875` (PRs #1 and #2 merged), on branch `feature/progression-economy-foundation`. Every finding below comes from files that were read or commands that were run in this session; nothing is inferred from file names alone.

## Baseline re-run (this session)

| Check | Result |
|---|---|
| Unity 6000.3.27f1 EditMode (`-runTests`, batchmode) | 28/28 passed |
| `flutter analyze` | No issues |
| `flutter test` (before fix) | **1 failure**: `shared_content_test.dart` byte-identical asset check |
| `tools/build/sync_flutter_shared.py --check` (before fix) | **STALE** `configs/gear_rules.json`, `waves/mission_001.json` |
| After adding `.gitattributes` (LF for JSON/Dart/C#/Python/Markdown) | Flutter 44/44, sync check clean |
| `validate_shared.py`, `reference_rules.py --check` | Pass |

**Root cause of the failure:** `core.autocrlf=true`, and there was no `.gitattributes`. Switching branches rewrote some JSON files with CRLF and left others alone, so files whose index content is identical differed on disk. The previous session's claim that line endings "won't break the checks" was wrong; this audit corrects it.

## Implemented systems (verified in source)

| System | Unity (`unity/Assets/Game/Core`) | Flutter (`flutter/lib`) |
|---|---|---|
| Gear board, reciprocal ports, BFS parity, booster cap | `GearNetwork.cs` (`GearBoard`, `GearNetwork.Rebuild`) | `mechanical/gear_network.dart` |
| Merge | `GearBoard.TryMerge` | `GearBoard.merge` |
| Output clocks, lane cap | `GearOutputSystem.cs` | `mechanical/gear_output_system.dart` |
| Lane combat, fixed event order | `CombatSimulation.cs` | `combat/combat_simulation.dart` |
| Battle session | `BattleSession.cs` | `combat/battle_session.dart` |
| RNG `xorshift32-v1` | `SeededRandom.cs` | `core/seeded_random.dart` |
| Shop rules | `GearShop.cs` | `data/shared_rules.dart` (`rollShop`) |
| Wave expansion | `WaveDirector.cs` | `data/shared_rules.dart` (`scheduleWave`) |
| Combat trace runner | `CombatScenario.cs` | `simulation/combat_scenario.dart` |
| Campaign, stars, contracts, Scrapstorm, streak, chests, Supply Log, boosters | — | `progression/campaign_progress.dart`, `progression/rewards.dart` |
| Save | — | `progression/campaign_store.dart` (single JSON string in `SharedPreferencesAsync`, key `gearbound.campaign.v1`, payload `saveVersion: 2`) |

## Partial or placeholder

- **Workshop board is a demo.** `makeStarterBoard()` builds a fixed board. The only edits are "MOVE PRESS" and "rotate output" (`_WorkshopScreenState._movePress`, `_rotateOutput`). There is no shop, purchase, drag-and-drop placement or merge UI, although the shop *rules* exist in both engines.
- **Hard-coded scrap display.** `_Header` in `gearbound_app.dart` shows a literal `'24'`, not the player's scrap.
- **Single-wave missions.** `BattleSession` runs one `WaveDefinition`. The spec's multi-wave loop (waves, inter-wave preparation) is not implemented (GB-025).
- **Route data.** 1 of 12 nodes loads from shared JSON (`shared/missions/campaign_route.json`); the other 11 use `progression/encounters.dart`.
- **Rendering.** `game/gearbound_game.dart` draws everything with canvas primitives. There is no production art, no skeletal animation and no audio.
- **Unity** is a simulation library only: no scenes, presentation, input or progression.

## Architectural problems and risks

| ID | Finding | Evidence | Severity |
|---|---|---|---|
| A-1 | **Clock manipulation.** Daily/weekly periods use the device clock; moving it backwards and forwards re-opens Supply Log claims and contract resets. | `CampaignProgress._ensurePeriods`, `canClaimLogin` use `DateTime.now()` | High once rewards have value |
| A-2 | **No transaction ledger.** Rewards mutate `scrap` and `boosters` in place, so there is no idempotency key or audit trail. | `CampaignProgress._grant`, `claimEventTier`, `_completeContractIfReady` | High before ads/IAP |
| A-3 | **No corruption recovery.** `CampaignProgress.decode` throws on malformed JSON, and `CampaignStore.load` does not catch it, so a corrupted save blocks the hub. There is no backup copy. | `campaign_store.dart` | High |
| A-4 | **Unserialized writes.** Several `unawaited(onProgressSaved(...))` calls can overlap. | `gearbound_app.dart` workshop callbacks | Medium |
| A-5 | **One currency.** `scrap` is meta-only today (earned from first clears, contracts and events; never spent). There is no battle currency, premium currency or XP. | `campaign_progress.dart` | Blocks economy work |
| A-6 | **Reward tuning duplicated.** Values live in Dart constants and are only *checked* against JSON. | `rewards.dart`, `rewards_test.dart` | Medium |
| A-7 | **Oversized UI file.** All screens and widgets are in one file. | `gearbound_app.dart`: 1,255 lines, 39.8 KB | Medium |
| A-8 | **Local-only premium state.** `SharedPreferences` is user-editable, so it is unsafe for purchased currency or entitlements. | — | Blocks IAP |
| A-9 | **Android build blocked** on an unaccepted NDK license (from earlier sessions; not re-checked). | `DEVELOPMENT_STATUS.md` | Blocks device testing |
| A-10 | **Line endings** (fixed this session). | `.gitattributes` | Fixed |

## Documentation vs implementation discrepancies

- `docs/RISK_REGISTER.md` R-03 says the Flutter launcher cannot report its version. It has been working all session (analyze and test run normally).
- `AGENTS.md` and `docs/GAMIFICATION_AND_EVENTS.md` state an earn-only and no-ads policy. That is now superseded by the approved monetization model: rewarded ads, transition-only interstitials, and fixed-content IAP with no paid randomness. These docs are being updated in this branch.
- `README.md` says no custom art exists. That is still accurate.

## Not audited

- Android and iOS platform folders beyond the build-blocker note.
- Unity `ProjectSettings` beyond the version file.
- Store, ad and backend accounts: none exist or are configured.
