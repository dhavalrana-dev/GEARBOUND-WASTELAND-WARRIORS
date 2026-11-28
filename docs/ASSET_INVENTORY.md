# Asset inventory: first vertical slice

- **Source of truth:** `shared/art/asset_manifest.json`, schema `shared/schemas/asset-manifest.schema.json`.
- **Validation:** `tools/data-validation/validate_shared.py`.
- **Art rules:** `ART_DIRECTION.md` (decisions and gates), `VISUAL_STYLE_BIBLE.md`, `ASSET_VALIDATION_GUIDE.md` (lifecycle and checks).
- **Renamed** from `PRODUCTION_ASSET_INVENTORY.md` on 2026-11-28 (visual direction v3).

**Status (2026-11-28): 337 records: 335 `planned` and 2 `concept` (`style_reference_board` and `style_mood_board`). The mood-board image is an exploratory study; no production artwork has been approved, and no art gate (ART-01 to ART-06, ART-B) has passed.** The game still uses canvas primitives drawn in `flutter/lib/game/gearbound_game.dart`.

## Counts

| Category | Records | Notes |
|---|---|---|
| Style references | 11 | ART-01: mood board, reference board, palette, material library, character, environment and UI style, portrait and landscape compositions; ART-B: benchmark captures in portrait and landscape |
| Character concepts | 20 | Rivet: 13 sheets. One concept each for Rivetguard, Raider, Rustrunner, Bruiser, Cinder Skirmisher, Spoke Dasher and Scrapmaw |
| Character parts | 27 + 7 part sets | Rivet's parts with default draw order from §12; part sets for the other characters |
| Rig | 1 | Rivet skeleton (§11) |
| Animations | 50 | Rivet 13 (8 P0, 5 P1), units and enemies 5 each, Scrapmaw 7 |
| Gears and overlays | 33 + 6 | 5 layers per gear, tier 2/3 wheels for mergeable gears, 6 shared state overlays |
| Board UI and screens | 13 + 3 | Frame, slots, overlays, drag preview, purchase card, reroll, sell, undo; benchmark screen compositions for the HUD, gear shop and victory |
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

By priority: **282 P0, 52 P1, 3 P2.**

Changed 2026-11-28: the Spark Turret's 7 gear records moved from P2 to P0 (it is sold since GB-037); `anim_rivet_special` moved to P0 (Wrench Quake exists, GB-055); 14 records added for the Copperwash enemies `raider.skirmisher` and `raider.dasher` (GB-024). The Ironwood and Sunken archetypes are outside this slice and have no records.

## Visual benchmark set (ART-B)

The benchmark is built and approved **before** any mass production (`ART_DIRECTION.md` §6). It is the smallest set that proves every standard: character, material, environment, camera and UI. Each element is reviewed in portrait and landscape, in-engine in Flutter at least.

| Benchmark element | Records it needs | Minimum state for ART-B |
|---|---|---|
| Rivet | `chr_rivet_concept_*` (master, turnaround, near/far sheet), Rivet parts, rig, `anim_rivet_idle`, `anim_rivet_attack_light_1` | Master approved; rigged idle and light attack in-engine |
| Rivetguard | Concept, part set, idle, walk, attack | Animated in-engine |
| Representative enemies | `raider.basic`, `raider.bruiser`, `boss.scrapmaw` concepts and part sets; Scrapmaw wind-up | Animated in-engine, including the telegraph |
| Starter gear catalogue | All 5 gears with layers, tier 2 and 3 wheels, 6 state overlays | Every state readable in the live board |
| Mechanical board | `ui_board_*` | In-engine with drag, merge and invalid states |
| Fortress | `fortress_wayfarer_*` | Base plus damaged and producing overlays |
| Copperwash battlefield | 7 `env_copperwash_*` layers, the 6 or more props the benchmark uses | Layered in-engine with the actors |
| Combat VFX | `fx_melee_hit`, `fx_unit_deploy`, `fx_projectile_impact`, `fx_boss_warning`, `fx_enemy_defeat` | Pooled, timed to simulation events |
| Gear shop | `ui_screen_gear_shop`, `ui_board_purchase_card`, `ui_board_cost_badge`, `ui_board_reroll_button` | Live shop with real offers |
| Gameplay HUD | `ui_screen_gameplay_hud`, `ui_panel_hud_strip`, HUD icons | Live values from the session |
| Victory screen | `ui_screen_victory`, `ui_reward_chest_star_milestone` | With a rewarded-ad bonus button in its distinct state |
| Campaign map section | `ui_map_copperwash_region`, a landmark, the route path, the node states | Nodes 1–5 with real progress |
| Event card | `ui_event_scrapstorm_card_portrait`, `ui_event_scrapstorm_emblem` | Dynamic title, timer and rewards in code |
| Reward chest | `ui_reward_chest_star_milestone` | Closed, anticipation and open states animated |

## Open issues found while reconciling with game data

| ID | Issue | Proposed resolution |
|---|---|---|
| ART-ID-01 | The Copperwash boss is named "Scrapjaw" on route node `copperwash-05` (`campaign_progress.dart`) and "Scrapmaw" for enemy `boss.scrapmaw` (`enemies.json`) | Pick one name before concept approval, then change the display string in one place. IDs stay stable. |
| ART-ID-02 | The fortress and the Copperwash region have no shared data IDs | **Partly resolved:** `hero.rivet` is a real ID in `shared/heroes/heroes.json` since GB-055, and the validator now reads hero IDs from that file. `fortress.wayfarer` and `region.copperwash` stay provisional until fortress and region definitions move into shared JSON. |
| ART-ID-03 | The art brief lists a "configured ranged friendly unit", but none exists | Not planned until a ranged gear exists. |
| ART-ID-04 | Spark Turret (`turret.spark`) is in the catalogue, but turret output isn't implemented | **Resolved:** GB-037 implemented turrets; the gear art is P0. Projectile impact VFX (`fx_projectile_impact`) is already P0. |
| ART-ID-05 | Rivet animations for heavy attack, dash, special, run, a second light attack and knockback have no simulation mechanic yet | P1, produced once the Phase 03.2 mechanics exist. The special now exists (GB-055), so `anim_rivet_special` is P0. |
| ART-ID-06 | Rivet's gender is not specified in any design document; the mood board study (`style_mood_board`) depicts Rivet as a woman | Owner decision at ART-02; record it in `CHARACTER_DESIGN.md` §3. |
| ART-ID-07 | The mood board study shows a ranged Rivetguard, a ranged raider and a turret as a tracked field unit, none of which exist in the data | Treat as exploration only. Rivetguard stays melee infantry, and the Spark Turret is a board gear that fires into lanes, unless the game design changes first. |

## Status lifecycle

`planned` → `concept` → `approved_concept` → `source_ready` → `rigged` → `animated` → `runtime_integrated` → `qa_passed` → `approved`

The validator enforces these rules:
- From `approved_concept` onward, a record needs a reviewer, acceptance evidence, a license and provenance.
- `runtime_integrated` and later need runtime paths.
- Every `logicalOwnerId` must be a real data ID, a reserved product ID (`gearbound.*`) or a listed provisional owner.
