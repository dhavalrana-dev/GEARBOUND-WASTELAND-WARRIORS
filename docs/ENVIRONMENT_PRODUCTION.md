# Environment production

**Version:** 1.0 (2026-11-28). It replaces art direction v2 §16–18. **Status:** proposed; no environment art exists.
**Order:** **Copperwash Pass first.** Its approved benchmark sets the standard. Ironwood Frontier, The Sunken Yard and later regions are not painted until the Copperwash benchmark is approved.
**Related:** `VISUAL_STYLE_BIBLE.md`, `MATERIAL_LIBRARY.md`, `RENDERING_ARCHITECTURE.md`, `VISUAL_PERFORMANCE_BUDGET.md`, `ASSET_GENERATION_PROMPTS.md`.

## 1. Principles

- **Layered and handcrafted:** stylized industrial architecture, hand-painted materials and modular structures.
- **Lighting:** warm environmental light, distant landscape silhouettes, foreground framing at the screen edges only, ground-contact shadows, atmospheric particles and mechanical ambient animation.
- **The lanes are a stage:**
  - The gameplay ground is quiet: mid value, low saturation and few details along the lanes, as the value bands in `VISUAL_STYLE_BIBLE.md` §7 require.
  - Detail concentrates at the edges and in the background.
- **Readability beats decoration:** foreground framing never covers lanes, the fortress, enemy entrances, projectiles or controls.
- **Environmental storytelling:** each region shows its history through structures, abandoned machines and settlements, in the background.

## 2. Layer stack

| Layer | Parallax | Content | Notes |
|---|---|---|---|
| Sky | 0.00 | Gradient sky and painted clouds | The only place broad gradients are allowed |
| Distant silhouettes | 0.10 | Mesas, far towers | Value shapes only, no outlines |
| Far architecture | 0.25 | Factories, cranes | Thin or no outlines, atmospheric fade |
| Mid-background | 0.45 | Ruins, pipes, slow-turning machinery | Ambient motion lives here |
| Near-background | 0.70 | Walls, scrap piles behind the far lane | Must not resemble lane ground |
| Gameplay ground | 1.00 | Three lane strips, fortress pad, enemy entrance | Quiet; lane boundaries readable |
| Characters and machines | 1.00 | Actors, fortress, projectiles | Sorted by ground contact |
| Foreground | 1.10–1.20 | Debris, posts and cables at the screen edges | Kept away from the lane area |

With a fixed camera, parallax applies only to small transitions (wave intro, victory pan). Most depth comes from layering and ambient motion.

**Source sizes:**
- Wide master: 3840 × 2160.
- Parallax strips: up to 4096 px wide.
- Props: 256–1024 px.
- Seamless ground tiles where needed.

Never export every layer at source resolution. The runtime sizes come from `VISUAL_PERFORMANCE_BUDGET.md`.

## 3. Copperwash Pass (benchmark region)

**Mood:** a warm desert industrial pass in the late afternoon. Copper scrap, sun-bleached concrete, abandoned mining machinery, and dust in the air.

**Additional palette** (on top of the global tokens):

| Color | Hex | Use |
|---|---|---|
| Pass dust | #E3C9A0 | Sky haze, distant fade |
| Mesa rust | #B5653F | Cliffs |
| Shadow plum | #6C4E5E | Cast shadows in the distance |
| Oxidized teal | #4FA39A | Copper patina accents |

**Materials:** sand, rock, weathered concrete, copper, rusted machinery, painted steel, and canvas awnings.

**Landmarks:** an abandoned ore crane, a broken conveyor bridge in the background, copper pipe clusters, a wind-driven pump, and a collapsed scrap tower that echoes the campaign-map landmark.

**Props (the 18 manifest records `env_copperwash_prop_*`):** modular and reusable. Each is drawn in the gameplay perspective with its own contact shadow.

**Atmosphere:** drifting dust motes, an occasional tumbleweed of scrap wire, heat shimmer on the distant layer, and a turning pump wheel.

**Gameplay elements:**
- the fortress pad on the left;
- an enemy entrance on the right (a raider gate built of scrap);
- the lane strips, with subtle wear marks along them;
- lane-boundary cues: painted guide stones, never strong lines.

## 4. Fortress: the Wayfarer

The visual anchor of the battlefield. Provisional owner `fortress.wayfarer`.

- **Look:** a recognizable rolling-workshop silhouette with a reinforced chassis and treads or wheels.
- **Features:** visible power indicators tied to the core state, armor panels, tool storage, a unit deploy hatch for each lane, and mounts for defensive equipment.
- **Materials:** painted steel, brass, canvas, teal glass and energy.

**States**, as composable overlays:
- normal, producing, shielded;
- damaged (below 60% health) and critical (below 25%);
- defeat and victory.

The thresholds are proposals tied to the HUD (`UI_UX_SPECIFICATION.md`).

**Defensive equipment** (Spark Turret mounts): base, rotating head, barrel, muzzle socket, activation effect, projectile origin and cooldown state. It is drawn only for implemented equipment.

## 5. Later regions (gated on the Copperwash benchmark)

| Region | Direction | Extra palette (to be proposed) |
|---|---|---|
| Ironwood Frontier | Reclaimed industrial forest: moss-covered steel, filtered light, broken rail routes, the Mossback boss monument | Moss greens, bark browns, cool filtered gold |
| The Sunken Yard | Flooded ruins: rusted cranes, waterlogged machinery, puddle reflections, mist, damaged platforms | Teal, deep blue, wet-rust orange |

The manifest has no records for these regions yet (task 7.8). They are added after the benchmark is approved.

## 6. Review

**Each environment is reviewed:**
- as a still at 3840 × 2160;
- in-engine, in portrait and landscape, with the actors present;
- with the HUD over it;
- at Low quality (`VISUAL_PERFORMANCE_BUDGET.md` §4).

**Approval needs:**
- lane readability: the 3:1 actor contrast;
- a free path for telegraphs and projectiles;
- the layer memory measured within budget.
