# Rendering architecture

**Version:** 1.0 (2026-11-28). It replaces art direction v2 §5 (projection), §29 and §30. **Status:** design only. Unity has no gameplay scene; its only scene is the generated device-baseline scene from session 20. Flutter still draws canvas primitives in `flutter/lib/game/gearbound_game.dart`.
**Related:** `VISUAL_STYLE_BIBLE.md`, `CHARACTER_RIGGING_GUIDE.md`, `ANIMATION_SPECIFICATION.md`, `VISUAL_PERFORMANCE_BUDGET.md`, `CROSS_ENGINE_PARITY.md`.

## 1. Principles

1. **The simulation stays presentation-free.**
   - `Gearbound.Core`, `Economy` and `Workshop` in C#, and `lib/mechanical`, `combat` and `economy` in Dart, gain no rendering dependency.
   - Renderers read state and events. They never write gameplay state.
2. **One shared description, two renderers.** `shared/art/` holds engine-neutral metadata: the projection, rigs, animation clips, environment layers and UI tokens. Each engine has its own runtime that reproduces the **approved look**, not the same internals.
3. **The identity is painted or baked, not computed.** Outlines, shading and lighting live in the artwork. Real-time lights and post-processing are optional accents that the Low quality tier switches off without losing the identity.
4. **Never assume portability.** Unity shaders, `.anim` files, 2D Animation rigs and prefabs do not run in Flutter. Every shared fact goes through `shared/art/*.json` or exported images and atlases.

## 2. Shared metadata in `shared/art/`

| File | Status | Content |
|---|---|---|
| `asset_manifest.json` | **Exists** (schema enforced) | Every asset's identity, paths, dimensions, pivots, trim, atlas, draw order, license, provenance, revision, status and evidence |
| `projection.json` | Planned (benchmark) | Lane baselines, lane scales, apparent elevation, world-mm to screen mapping, shadow offset, sort-key formula, reference resolutions |
| `character_rigs.json` | Planned (ART-03) | Bones, parts, pivots, sockets, draw order (`CHARACTER_RIGGING_GUIDE.md` §6) |
| `animation_catalog.json` | Planned (ART-03) | Clips, durations, loops, frame events aligned to simulation events |
| `environment_layers.json` | Planned (ART-04) | Per region: layers, parallax factors, tiling, ambient emitters |
| `atlases.json` | Planned (first export) | Atlas pages, sprite rectangles, trim offsets, pivots (one per engine export) |
| `ui_tokens.json` | Planned (ART-05) | Colors, type scale, spacing, corner chamfers, button states |

**Rules:**
- Each file gets a schema in `shared/schemas/` and a validator entry when it is created. The validator already fails on schemas that describe no file.
- Flutter copies of these files are synced by `tools/build/sync_flutter_shared.py`.

## 3. Projection contract

- **Inputs:** a horizontal simulation position in mm, the lane index (0 = far, 2 = near) and an optional visual elevation.
- **Outputs:** a screen position, the lane scale, the ground-shadow position and the depth-sort key.
- **Lanes:** each lane has a baseline y in the battlefield rectangle and a scale (art test: near 1.00, middle 0.92, far 0.84).
- **x mapping:** x is mapped linearly from world mm to the battlefield rectangle, independently of scale.
- **Sort key:** `(laneDepth, groundY, renderPriority, entityId)`, from far to near. `renderPriority` separates shadows, bodies and attached VFX. `entityId` breaks ties stably, so the order is deterministic.
- **Visual scale never changes gameplay.** Reach, range and hit tests stay in simulation mm.
- **Proof:** golden cases in a shared fixture (`projection_cases.json`, planned) are evaluated by both engines when the contract is implemented, like the combat traces.

## 4. Characters and skeletal animation

| Option | Unity | Flutter | Notes |
|---|---|---|---|
| **A. Rigid-part rig from shared metadata (proposed default)** | Custom part renderer, or Unity 2D Animation with bones only | Custom Flame component: one transform per part, drawn from an atlas | Cheapest to keep identical; no deformation; fits the rigid-parts default |
| B. Unity 2D Animation with mesh deformation | Native (2D Animation and 2D IK packages) | Not portable; would need a baked fallback | The reference package analysis shows this works at mobile scale in the genre |
| C. Third-party skeletal tool with runtimes for both engines | Vendor runtime | Vendor runtime | Check the current license terms of the editor and runtime, the maintenance of the Flutter runtime, and the performance before adopting |
| D. Baked sprite-sheet frames | Sprite animation | `SpriteAnimationComponent` | Simplest at runtime, highest texture memory; good for VFX and small enemies |

**Proposed:**
- **A** for characters, **D** for VFX and very small units.
- **C** is evaluated only if A cannot reach the animation quality bar.
- The decision is recorded at ART-03 (GB-045). Adding packages follows `AGENTS.md`: a justified use, compatible with Unity 6.3 and with the installed Flutter SDK.

## 5. Unity rendering plan (GB-046)

**Evaluated in this order, with each step adopted only on evidence:**

1. **Sprite Atlas v2 and sprite import:**
   - a consistent pixels-per-unit;
   - custom pivots, preserved trim, and atlases per scene group.
2. **Sorting:** sorting layers (Background, Ground, Actors, Projectiles, FX, Foreground, UI). A `SortingGroup` per character, with the order computed from the projection sort key.
3. **Unity 2D Animation:** for the rig option chosen in §4. Inverse kinematics (2D IK) only if needed for foot planting.
4. **Lighting:**
   - First choice: baked lighting painted into the art.
   - Then lightweight 2D lights (URP 2D renderer) for power glows and boss warnings, only if profiling on the reference devices shows headroom.
   - The project currently uses the built-in pipeline (no URP package). Switching to URP is a measured decision.
5. **Optional low-poly environment geometry:** only for a background element that gains real depth from it, rendered to match the painted style and baked lighting. Not in the benchmark unless 2D layers fail.
6. **Pooling:** units, projectiles, damage numbers and VFX are pooled from the first scene, with no instantiation during combat.
7. **Responsive UI:** UI Toolkit or uGUI (chosen at GB-046), built from `ui_tokens.json`, with portrait and landscape layouts and safe areas.

**No expensive real-time lighting, shadows or post-processing in the core identity.**

## 6. Flutter and Flame rendering plan (GB-045)

- **Layers:** a `World` with parallax and background layers as `SpriteComponent` or tiled sprites, the gameplay ground, actors and foreground.
- **Atlases:** sprites come from atlases (`atlases.json`) loaded once per mission and cached through Flame's image cache. Nothing is decoded during combat.
- **Characters:** option A from §4, a custom component that applies bone transforms to part sprites from `character_rigs.json` and `animation_catalog.json`.
- **Depth sort:** by the projection sort key, recomputed each frame in a reused list (no per-frame allocation).
- **Shadows:** sprite contact shadows, scaled per lane; baked lighting only.
- **Gears:** separate components for the base, wheel, hub and overlays. Rotation is driven by the network state (`ANIMATION_SPECIFICATION.md` §5).
- **Effects:** `SpriteAnimationComponent` pools, and particle limits per quality tier.
- **Interpolation:** render positions are interpolated between 30 Hz ticks, independent of the frame rate.
- **Overlays:** menus, HUD frames and the shop are Flutter widgets styled from `ui_tokens.json` with painted nine-slice frames. **No default Material styling in the final game.** Material widgets remain only as a prototype scaffold.
- **Migration:** canvas primitives are replaced incrementally behind the same game interface, keeping the current widget and route tests green.

## 7. Cross-engine visual parity

Rendering internals may differ. The outcome must not:
- same layout proportions;
- same lane projection (shared fixture), same sort order, same clip timing and events;
- same palette and assets;
- same state visuals for gears and UI.

It is checked with paired screenshots of the benchmark mission at the same simulation tick in both engines (`ASSET_VALIDATION_GUIDE.md` §6) and recorded in `CROSS_ENGINE_PARITY.md`.
