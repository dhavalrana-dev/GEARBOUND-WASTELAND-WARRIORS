# GEARBOUND: Wasteland Warriors — Art direction

**Document version:** 3.0 (2026-11-28). It replaces v2.0, "Industrial Comic 2.5D".
**Official visual identity: TACTILE INDUSTRIAL COMIC 2.5D.**
**Status:** proposed production direction. No production art has been approved. Two ART-01 studies are at `concept`: the working HTML reference board (`assets-source/style-bible/reference_board_v001.html`) and one illustrated mood board (`assets-source/style-bible/industrial-comic-style-study_v001.png`). Both await owner review.
**Platforms:** Android and iOS. **Rendering:** Unity 6.3 LTS (reference) and Flutter/Flame.

> **Repository reconciliation** (2026-11-27, still current):
> - Runtime IDs come from shared JSON.
> - The Copperwash boss *node* is named "Scrapjaw" (`copperwash-05`), but the boss *enemy* is `boss.scrapmaw` ("Scrapmaw"); this is open as ART-ID-01 and GB-047.
> - There is no ranged friendly unit in the data. Friendly infantry comes from the `unit.rivetguard` gear.
> - The prototype colors live in `flutter/lib/design_system/tokens.dart`.

---

## 1. What changed in v3

v3 keeps every rule from v2 and sharpens the identity from "Industrial Comic" to **Tactile Industrial Comic 2.5D**:
- objects with physical weight (gears, machines and UI you could touch);
- a miniature industrial diorama feel;
- a named material library;
- a single visual benchmark that must be approved before production;
- an explicit 19-step execution order.

v2's long single document is split into specialized specifications (§4). This file keeps the decisions, the gates and the order.

## 2. Vision

GEARBOUND is an original mechanical strategy and action game set in a colorful industrial wasteland. It should feel **handcrafted, original, colorful, visually sophisticated and immediately readable on a phone**: a miniature industrial diorama in which comic-drawn heroes fight beside tactile machines the player built.

**The combination:**
- stylized 2.5D battlefield depth;
- handcrafted comic-book illustration;
- tactile mechanical objects and hand-painted environment textures;
- expressive cel-shaded characters;
- a miniature industrial diorama aesthetic;
- a premium illustrated interface;
- satisfying mechanical and combat animation.

## 3. Creative references (broad principles only)

| Reference | What it informs |
|---|---|
| Gear Fight! | Mechanical gameplay: gear connections, immediate power feedback, merge and purchase loop, readability of a small board |
| The Last Friend | Character design energy, side-view combat with depth, angular comic silhouettes, hand-drawn environments |
| SteamWorld Build and SteamWorld Dig | Industrial machinery with personality; world-building through machines and settlements; tactile mechanical detail |
| Clash Royale | A miniature battlefield that reads instantly on a phone; tactile, toy-like objects; clear unit readability; satisfying UI feedback |
| Hades | Illustrated character portraits and interface quality; dramatic but readable effects; a cohesive painted identity |
| Candy Crush Saga | Campaign map progression, events, reward chests, daily goals and gamification presentation |

**Never reproduce** any proprietary asset, character, interface graphic, icon, logo, map layout, font, level or effect. References inform principles, not looks.

- `REFERENCE_GAME_ANALYSIS.md` records what each reference teaches and the originality checks.
- `ASSET_VALIDATION_GUIDE.md` §8 runs an originality review at every gate.

## 4. Document map

| Topic | Document | Replaces v2 sections |
|---|---|---|
| Style rules, palette, light, camera, compositions, gears and board, reference board | `VISUAL_STYLE_BIBLE.md` | §2–6, §14–15 |
| Materials | `MATERIAL_LIBRARY.md` | New |
| Characters, roster, Rivet's identity | `CHARACTER_DESIGN.md` | §7–9 |
| Parts, near/far limbs, skeleton, draw order, rig metadata | `CHARACTER_RIGGING_GUIDE.md` | §10–12 |
| Character, gear, environment, UI and VFX motion | `ANIMATION_SPECIFICATION.md` | §13, §19 |
| Copperwash, later regions, layers, fortress | `ENVIRONMENT_PRODUCTION.md` | §16–18 |
| Interface, monetization states, gamification visuals, campaign map, rewards and shop art | `UI_UX_SPECIFICATION.md` | §20–23 |
| Inventory, benchmark set, open ID issues | `ASSET_INVENTORY.md` (was `PRODUCTION_ASSET_INVENTORY.md`) | §27 |
| Prompts | `ASSET_GENERATION_PROMPTS.md` | §28 |
| Lifecycle, QA, provenance | `ASSET_VALIDATION_GUIDE.md` | §26, §32 |
| Unity and Flutter rendering, shared art metadata, projection | `RENDERING_ARCHITECTURE.md` | §5, §29–30 |
| Frame, memory and quality budgets | `VISUAL_PERFORMANCE_BUDGET.md` | §31 |

## 5. Pillars and non-negotiables

**Pillars** (kept from v2):
1. **Mechanical satisfaction.** Machines look functional, and the player sees why a machine is running or idle.
2. **Character personality.** Each major character is identifiable from silhouette alone.
3. **Environmental storytelling.** Each region tells its history through structures and machines.
4. **Gameplay readability.** Nothing hides enemies, projectiles, lanes, gear connections or controls.
5. **Reward satisfaction.** Rewards look tangible, and their animations are short and clear.

**Non-negotiables:**
- The **simulation is authoritative**: 30 Hz fixed ticks and the logical three-lane battlefield. Art follows state and events, and never decides outcomes.
- The camera is an **elevated side view**. It is not isometric tactics and has no free 3D camera. Depth comes from lane scale, ground-contact sorting, layers, shadows, restrained parallax and atmosphere.
- Rivet's identity is preserved (`CHARACTER_DESIGN.md` §3).
- **Master turnarounds come before skeletal parts.** Near and far limbs are drawn independently.
- **Production-ready means `approved`** after visual, technical and in-engine validation (`ASSET_VALIDATION_GUIDE.md`). A generated image is never production-ready on its own.
- **No full-scale production before the visual benchmark is approved** (§6).
- Unity-specific shaders, rigs and components are never assumed to work in Flutter. The two engines share metadata and images (`RENDERING_ARCHITECTURE.md`).
- Performance claims need device measurements (`VISUAL_PERFORMANCE_BUDGET.md`).

## 6. The visual benchmark (gate ART-B)

**What it is:** one complete, small, in-engine scene that proves every standard at once. It contains:
- Rivet and Rivetguard;
- representative enemies (Scrap Raider, Slagback Bruiser, Scrapmaw);
- the starter gear catalogue and the mechanical board;
- the fortress and the Copperwash battlefield;
- combat VFX;
- the gear shop, gameplay HUD, victory screen, a campaign map section, an event card and a reward chest.

The records and minimum states are listed in `ASSET_INVENTORY.md` §"Visual benchmark set".

**Exit criteria:**
- **Orientations:** validated in **portrait and landscape** on a phone-sized viewport, plus the compact and tablet checks in `ASSET_VALIDATION_GUIDE.md` §6.
- **Engine:** running in Flutter with live simulation state. Unity follows in Phase 06.
- **Standards:** character, material, environment, camera and UI standards are approved by the owner, using this scene.
- **Performance:** a first device performance reading on a mid-range phone (`VISUAL_PERFORMANCE_BUDGET.md` §6). This is not the final optimization, but it shows the budget is realistic before production scales.

**Once ART-B passes**, the benchmark becomes the permanent reference: every later asset is judged against it.

## 7. Execution order and status

| # | Step | Gate | Roadmap | Status (2026-11-28) |
|---|---|---|---|---|
| 1 | Inspect the latest repository | — | 04 | **Done** (session 21) |
| 2 | Reconcile existing documentation | — | 04 | **Done** (session 21: v3 docs, inventory rename, roadmap, backlog, risks, parity) |
| 3 | Establish the updated visual direction | ART-01 | 04 | **Documented, proposed**; needs owner approval |
| 4 | Create the visual reference board | ART-01 | 04 | **Working HTML board and illustrated mood-board study created** (concept); both await owner review |
| 5 | Define materials and colors | ART-01 | 04 | **Defined, proposed** (`MATERIAL_LIBRARY.md`, palette); the painted material sheet is still needed |
| 6 | Approve Rivet's character master | ART-02 | 04 | Not started |
| 7 | Approve mechanical gear artwork | ART-04 (benchmark part) | 04 | Not started |
| 8 | Approve the Copperwash environment | ART-04 (benchmark part) | 04 | Not started |
| 9 | Approve portrait and landscape gameplay compositions | ART-01, then ART-B | 04 | Wireframes on the board; illustrated compositions not started |
| 10 | Produce the detailed asset inventory | — | 04 | **337 records: 335 planned, 2 concepts**; refine after ART-B |
| 11 | Produce individual production assets | ART-03/04/05 | 05 | Blocked on ART-B |
| 12 | Assemble character skeletons | ART-03 | 05 | Blocked |
| 13 | Create animation sets | ART-03 | 05 | Blocked |
| 14 | Integrate artwork into Unity | ART-06 | 06 | Blocked; Unity has no gameplay client (GB-046) |
| 15 | Integrate equivalent artwork into Flutter | ART-B, then ART-06 | 05 | Blocked; the Flame sprite pipeline is GB-045 |
| 16 | Validate actual gameplay presentation | ART-06 | 05/06 | Blocked |
| 17 | Measure device performance | — | 15 | Blocked; needs a physical phone |
| 18 | Approve the complete visual vertical slice | ART-06 | 05/06 | Blocked |
| 19 | Expand campaign content and LiveOps artwork | — | 07–09 | Blocked |

**The benchmark sits between steps 9 and 11:** steps 6–9 produce its masters, and ART-B approves it in-engine before step 11 starts.

## 8. Art gates

| Gate | Deliver | Exit | Status |
|---|---|---|---|
| ART-01 Visual direction | Reference board, illustrated mood board, palette, material sheet, character/environment/UI style, compositions | One coherent direction, approved by the owner | Not passed (both boards are concepts; material sheet and compositions still need art; owner review pending) |
| ART-02 Rivet master | Turnaround, near/far limb sheet, proportions, color, weapon, expressions | Identity, anatomy and perspective consistent | Not started |
| ART-B Visual benchmark | The §6 scene in portrait and landscape, in-engine | Standards approved; first device reading | Not started |
| ART-03 Rig and animation | Skeleton, pivots, P0 clips, metadata | No gaps, draw-order errors or detached weapons; events aligned | Not started |
| ART-04 Mechanical and environment | Full starter gears, board, Copperwash, fortress, units | Coherent battlefield at production scale | Not started |
| ART-05 UI and engagement | Map, workshop, HUD, events, rewards, shop, responsive layouts | Readable game and progression | Not started |
| ART-06 Cross-engine | Unity and Flutter slices, paired captures, profiling | Approved art works in both engines | Not started |

## 9. Asset directories, naming and manifest

**Source art:** `assets-source/` (created 2026-11-28 with `style-bible/`). Planned subfolders:
- `style-bible/`
- `characters/rivet/{concepts,turnarounds,layered,rig,animation,exports,prompts}/`
- `characters/rivetguard/`
- `enemies/`, `bosses/`, `gears/`, `machines/`, `fortress/`
- `environments/{copperwash,ironwood,sunken}/`
- `effects/`
- `ui/{panels,buttons,icons,screens,map,events,rewards,shop}/`
- `audio/`, `marketing/`, `licenses/`

**Runtime:**
- `unity/Assets/Game/Art/` and `flutter/assets/art/`, created with the first integrated asset.
- Engine-specific exports are produced separately where needed: atlas formats, compression, the Unity import settings.

**Shared metadata:** `shared/art/`.
- `asset_manifest.json` exists (schema enforced, 337 records: 335 planned and 2 concepts).
- `projection.json`, `character_rigs.json`, `animation_catalog.json`, `environment_layers.json`, `atlases.json` and `ui_tokens.json` are planned (`RENDERING_ARCHITECTURE.md` §2).

**Naming:**
- Lowercase snake_case, with stable logical IDs independent of revision numbers. Examples: `chr_rivet_arm_near_upper_v001.png`, `gear_transmission_t01_wheel_v001.png`, `env_copperwash_bg_far_v001.png`, `ui_event_scrapstorm_banner_v001.png`, `fx_gear_merge_v001.png`.
- No spaces and no "final-final".

**Manifest:** every asset has a record. It tracks:
- the paths, dimensions, pivot and trim, atlas and draw order;
- the license, provenance and revision history;
- the status, reviewer and evidence.

The fields and lifecycle are in `ASSET_VALIDATION_GUIDE.md` §1.

## 10. Final instruction

Do not generate production art at random:
1. Approve the direction (ART-01) and Rivet's master (ART-02).
2. Build and approve the one benchmark scene (ART-B) in portrait and landscape.
3. Then expand through the pipeline: parts, rigs, animation, Unity and Flutter integration, device measurement, slice approval, and only then campaign and LiveOps art.

Never mark art or integration complete without verified evidence.
