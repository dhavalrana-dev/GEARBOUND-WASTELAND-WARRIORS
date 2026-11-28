# Production asset inventory — first vertical slice

- **Source of truth:** `shared/art/asset_manifest.json`, schema `shared/schemas/asset-manifest.schema.json`.
- **Validation:** `tools/data-validation/validate_shared.py`.
- **Art rules:** `ART_DIRECTION.md`.

**Status (2026-11-28): 330 records, all `planned`. No artwork exists yet, and no art gate (ART-01 to ART-06) has started.** The game still uses canvas primitives drawn in `flutter/lib/game/gearbound_game.dart`.

## Counts

| Category | Records | Notes |
|---|---|---|
| Style references | 7 | ART-01: mood board, palette, character, environment and UI style, portrait and landscape compositions |
| Character concepts | 20 | Rivet: 13 sheets. One concept each for Rivetguard, Raider, Rustrunner, Bruiser, Cinder Skirmisher, Spoke Dasher and Scrapmaw |
| Character parts | 27 + 7 part sets | Rivet's parts with default draw order from §12; part sets for the other characters |
| Rig | 1 | Rivet skeleton (§11) |
| Animations | 50 | Rivet 13 (8 P0, 5 P1), units and enemies 5 each, Scrapmaw 7 |
| Gears and overlays | 33 + 6 | 5 layers per gear, tier 2/3 wheels for mergeable gears, 6 shared state overlays |
| Board UI | 13 | Frame, slots, overlays, drag preview, purchase card, reroll, sell, undo |
| Environment | 7 layers + 18 props | Copperwash (§16–17) |
| Fortress | 7 | Base plus 6 state overlays |
| VFX | 15 | §19 list |
| UI panels, buttons, icons | 5 + 7 + 32 | 6 currency icons, 26 HUD and system icons |
| Campaign map | 17 | Copperwash region, landmarks, 10 node states |
| Event art | 24 | Scrapstorm (P0), Gear Frenzy and Engineering Trials (P1), 8 assets each |
| Rewards | 6 | Crates and chests |
| Shop products | 8 | P1; IAP not implemented |
| Audio | 16 | P1 |
| Marketing | 4 | P1/P2 |

By priority: **275 P0, 52 P1, 3 P2.**

Changed 2026-11-28: the Spark Turret's 7 gear records moved from P2 to P0 (it is sold since GB-037); `anim_rivet_special` moved to P0 (Wrench Quake exists, GB-055); 14 records added for the Copperwash enemies `raider.skirmisher` and `raider.dasher` (GB-024). The Ironwood and Sunken archetypes are outside this slice and have no records.

## Open issues found while reconciling with game data

| ID | Issue | Proposed resolution |
|---|---|---|
| ART-ID-01 | The Copperwash boss is named "Scrapjaw" on route node `copperwash-05` (`campaign_progress.dart`) and "Scrapmaw" for enemy `boss.scrapmaw` (`enemies.json`) | Pick one name before concept approval, then change the display string in one place. IDs stay stable. |
| ART-ID-02 | Rivet, the fortress and the Copperwash region have no shared data IDs | The manifest uses provisional owners `hero.rivet`, `fortress.wayfarer` and `region.copperwash`. Add data IDs when hero and region definitions move into shared JSON. |
| ART-ID-03 | The art brief lists a "configured ranged friendly unit", but none exists | Not planned until a ranged gear exists. |
| ART-ID-04 | Spark Turret (`turret.spark`) is in the catalogue, but turret output isn't implemented | **Resolved:** GB-037 implemented turrets; the gear art is P0. Projectile impact VFX (`fx_projectile_impact`) is already P0. |
| ART-ID-05 | Rivet animations for heavy attack, dash, special, run, a second light attack and knockback have no simulation mechanic yet | P1, produced once the Phase 03.2 mechanics exist. The special now exists (GB-055), so `anim_rivet_special` is P0. |

## Status lifecycle

`planned` → `concept` → `approved_concept` → `source_ready` → `rigged` → `animated` → `runtime_integrated` → `qa_passed` → `approved`

The validator enforces these rules:
- From `approved_concept` onward, a record needs a reviewer, acceptance evidence, a license and provenance.
- `runtime_integrated` and later need runtime paths.
- Every `logicalOwnerId` must be a real data ID, a reserved product ID (`gearbound.*`) or a listed provisional owner.
