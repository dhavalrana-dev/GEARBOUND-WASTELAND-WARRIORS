# Visual style bible: Tactile Industrial Comic 2.5D

**Version:** 3.0 (2026-11-28). It replaces the style sections (§2–6) of art direction v2.
**Status:** proposed. An illustrated mood-board study and a diagrammatic reference board exist at `concept`; no production artwork is approved. These rules become binding when the owner approves ART-01 using the boards and, later, the visual benchmark (`ART_DIRECTION.md` §6).
**Related:** `ART_DIRECTION.md` (decisions, gates and execution order), `MATERIAL_LIBRARY.md`, `CHARACTER_DESIGN.md`, `ENVIRONMENT_PRODUCTION.md`, `UI_UX_SPECIFICATION.md`, `RENDERING_ARCHITECTURE.md`.

## 1. Identity statement

GEARBOUND looks like a **handcrafted industrial diorama brought to life by a comic artist**. The miniature battlefield seems built from painted metal, concrete and canvas. Comic-drawn characters fight in front of it, and every gear looks like a weighty object you could pick up.

A screenshot should be recognizable as GEARBOUND, and it should read on a phone at arm's length.

## 2. The eight components

| Component | What it means here | What it does not mean |
|---|---|---|
| Stylized 2.5D depth | Three logical lanes drawn as receding ground strips: lane scale, ground shadows, layered backgrounds | A free camera, an isometric grid or real-time 3D navigation |
| Comic-book illustration | Confident inked outlines, flat color shapes, 2–3 tone cel shading, graphic shadow shapes | Halftone everywhere, speech bubbles, or copying a comic artist's style |
| Tactile mechanical objects | Gears and machines with thickness: a rim edge, a beveled tooth face, a visible axle, cast shadows | Flat icons of gears |
| Hand-painted environment textures | Visible directional brush strokes on large planes, painted wear at edges | Photographic textures, procedural noise, tiled grunge |
| Expressive cel-shaded characters | Readable acting poses, clear faces, color-blocked costumes | Realistic anatomy, soft airbrushed shading |
| Miniature diorama aesthetic | Slightly compressed scale, crisp object edges, contact shadows, soft depth fade | Tilt-shift blur over gameplay, toy plastic look |
| Premium illustrated interface | Angular painted steel and brass frames, tactile buttons, illustrated icons | Default Material widgets, flat outlined icons in the final game |
| Satisfying motion | Gears that spin and snap with weight; hits with anticipation, contact and recovery | Constant screen shake, floaty tweens |

## 3. Forbidden

- Stickmen, generic chibi, photorealism, and glossy plastic-looking 3D.
- Flat vector icons as final characters, and mixed asset-pack styles.
- Heavy gradients, bloom, chromatic aberration, and full-screen post-processing as part of the identity.
- Random proportions, inconsistent outline weight, and perspective that does not match the camera.
- Mechanical parts with no readable function.
- Duplicated or mirrored near/far limbs (see `CHARACTER_RIGGING_GUIDE.md`).
- Anything traced, kitbashed or closely imitated from reference games: characters, UI frames, icons, logos, maps, fonts or effects.

## 4. Shape language

| Subject | Primary shapes | Notes |
|---|---|---|
| Heroes | Balanced angular and rounded shapes, open stance | Recognizable equipment silhouette |
| Friendly units | Compact trapezoids, rounded helmets | Read as a squad and stay subordinate to the hero |
| Light or fast enemies | Narrow forward-leaning wedges, pointed armor | Lean shows intent to rush |
| Heavy enemies | Broad rectangles and downward triangles | Mass sits low; slow anticipation |
| Bosses | A large silhouette with 2–3 readable mechanical zones | The weak point or telegraph zone must be legible |
| Machines and gears | Circles (motion) on rectangles and trapezoids (structure) | Rotating parts are always circular and centered |
| UI frames | Chamfered rectangles, riveted corners, angled tabs | Never rounded-pill Material shapes |

**Silhouette test:** every character, gear and UI icon must be identifiable as a solid black fill at gameplay size (see `ASSET_VALIDATION_GUIDE.md`).

## 5. Line and shading

**Outlines:**
- Warm-dark ink (`Outline` #20262D, or a darkened local color on interior lines).
- Outer silhouette lines are heavier than interior lines: about 2:1.
- At the 2048 px character master, the outer line is 6–8 px and interior lines are 3–4 px.
- At runtime, an outer line must never fall below 1.5 px on a 1080 px-wide phone. Validate at gameplay scale.
- Lines may taper. They stay crisp, never blurred or doubled.
- Environments use thinner lines that fade with depth. Far layers have no outlines, only value shapes.

**Cel shading:**
- A base tone plus one shadow tone. Add a second deep-shadow or highlight tone only where it explains form: metal, folds, gear teeth.
- Shadows shift hue toward cool cobalt (#386A97) and drop in value. Highlights shift toward warm light (#F2E6D1).
- Never shade by multiplying with grey.
- Shadow shapes are graphic, hard-edged and designed. Soft gradients are allowed only for atmosphere and glow.

## 6. Lighting

- **Key light:** from the upper left, warm (late-afternoon sun in Copperwash). It is the same direction in every asset, so parts can be combined.
- **Fill:** a cool ambient from the sky. Shadow sides lean toward cobalt and teal.
- **Rim:** a thin warm rim on characters is allowed, to separate them from the ground. Never on far background layers.
- **Contact shadows:** every grounded object gets a soft, darkened ellipse under its feet or base, drawn as a separate layer (never baked into a rotating part).
- **Energy light:** powered machinery emits Energy Gold (#F4BF4F). It is a gameplay signal, so it never appears on decoration.
- Lighting is painted or baked. Real-time lights may only accent, and the identity must survive with them switched off (`RENDERING_ARCHITECTURE.md`).

## 7. Color system

The tokens are kept from v2. Values are proposals until ART-01, and the prototype `flutter/lib/design_system/tokens.dart` already mirrors most of them.

| Token | Hex | Role |
|---|---|---|
| Steel Deep | #192531 | Interface shadows, darkest UI fields |
| Gunmetal | #344657 | Mechanical panels |
| Outline | #20262D | Primary illustration outlines |
| Cobalt Steel | #386A97 | Industrial structures, cool shadow hue |
| Machine Teal | #35A7B5 | Friendly technology |
| Copper Rust | #C56B42 | Mechanical accents, Copperwash identity |
| Brass | #D6AC63 | Gears, frames, reward accents |
| Energy Gold | #F4BF4F | Active power (function only) |
| Acid Lime | #B9DF54 | Valid connection and placement |
| Friendly Green | #63B77B | Positive state |
| Enemy Crimson | #D65760 | Threat and invalid |
| Special Violet | #9B73D0 | Rare abilities and rewards |
| Desert Sand | #D8B98B | Wasteland ground |
| Neutral Light | #F2E6D1 | Text and highlights |

**Value structure for readability:**
- Three value bands, from back to front:
  - **Background:** mid-light and low saturation.
  - **Gameplay ground:** mid value and low saturation, a quiet stage.
  - **Actors and gears:** the full value range, the highest saturation and outlines.
- Actors must separate from the ground at a contrast ratio of at least 3:1 (WCAG non-text contrast), measured at the sprite's average edge against the lane behind it.
- Functional colors (Energy Gold, Acid Lime, Enemy Crimson, Special Violet) are reserved for gameplay meaning. The environment may use desaturated relatives only.
- Color is never the only signal; pair it with an icon, shape, animation or label.
- Each region may add 3–5 environment colors (`ENVIRONMENT_PRODUCTION.md`). The UI theme does not change per event.

The material color ramps are in `MATERIAL_LIBRARY.md`.

## 8. Camera and projection

The camera is an **elevated side view**: the apparent elevation is about 15–25°, it is fixed in gameplay, the fortress is on the left and enemies enter from the right.

- **Three logical lanes:**
  - Lane 0 is the far lane, drawn highest on screen and smallest; lane 2 is the near lane.
  - The proposed lane scales are near 1.00, middle 0.92 and far 0.84. These are art-test values, not gameplay rules.
  - The lane-to-screen mapping is fixed by the projection contract in `RENDERING_ARCHITECTURE.md`. The prototype already draws lane 0 at the top (`gearbound_game.dart`).
- **Sprites are drawn for this camera:** characters at a right-facing three-quarter view, slightly from above. You see the top planes of boots, shoulders and machines.
- **Depth:**
  - lane scale;
  - sorting by ground contact;
  - layered environments;
  - contact shadows;
  - restrained parallax (with a fixed camera, mostly ambient motion);
  - atmospheric fade on far layers (lighter, cooler and less saturated).
- **Camera effects:**
  - Small impact shake on heavy hits and boss attacks only, with a capped amplitude, and off in reduced-motion mode.
  - A brief zoom on victory is allowed.
  - No free camera, rotation or perspective tilt.
- **Never:** convert to isometric tactics, let visual scale change gameplay reach, or derive hitboxes from pixels.

## 9. Screen compositions

| Orientation | Layout (after safe areas) |
|---|---|
| Portrait (1080 × 1920) | Status 6% · battlefield 40% · hero controls 8% · mechanical board 29% · shop and actions 17% |
| Landscape (1920 × 1080) | Board and shop 34% of the width · battlefield and hero controls 66% · shared resource and wave strip on top |
| Tablet | More spacing and larger targets, never more gameplay capacity |

During combat, nonessential shop controls collapse; the output status stays visible. The board is always 5×5. Wireframes are on the reference board (§11). The detailed UI rules are in `UI_UX_SPECIFICATION.md`.

## 10. Typography direction

- **Display:** a bold, condensed, slightly angular industrial or comic face for titles, numbers and banners. Commercially licensed for games and apps, with Latin Extended coverage at least.
- **Body:** a highly legible humanist or grotesque sans, with tabular numerals for prices, health, currency and timers.
- Text is never baked into artwork (titles, dates, prices, quantities or descriptions). The fonts are chosen at ART-01, and their licenses are recorded in the manifest.

## 11. Reference board

- **Diagrammatic working board:** `assets-source/style-bible/reference_board_v001.html`, manifest record `style_reference_board`, status `concept`.
- **Illustrated mood-board study:** `assets-source/style-bible/industrial-comic-style-study_v001.png`, manifest record `style_mood_board`, status `concept`; generation prompt and provenance are in `assets-source/style-bible/prompts/industrial-comic-style-study_v001.md`.
- **Contents:** it is original, made only from this repository's tokens and diagrams:
  - palette and value bands;
  - material swatches;
  - shape-language silhouettes;
  - the lane projection;
  - portrait and landscape wireframes;
  - the benchmark checklist.
- **Review status:** both boards are concepts, not approved designs. ART-01 still needs owner review, the painted material sheet and illustrated portrait/landscape compositions.
- **No outside imagery:** no reference-game screenshot or artwork is stored in the repository. Reference observations are written in `REFERENCE_GAME_ANALYSIS.md`.

## 12. Mechanical artwork: gears and board

Gear art is a primary gameplay asset. The source of truth is `shared/gears/starter_gears.json`: `core.wayfarer`, `drive.coupler`, `boost.ratchet`, `unit.rivetguard` and `turret.spark`, all five in the slice.

**Each gear has:**
- Dimensional teeth: a beveled top face plus a darker side face, so the gear has thickness.
- A reinforced rim, mechanical spokes and a visible center axle.
- Layered metals from `MATERIAL_LIBRARY.md`, with restrained highlights.
- A distinct functional silhouette per category:
  - **Core:** a heavy hub with an energy chamber.
  - **Drive:** a plain, efficient wheel.
  - **Booster:** a ratchet pawl and spring.
  - **Unit:** a deploy hatch.
  - **Turret:** a barrel mount.

**Separate runtime layers**, combined to show every state; there is no texture per state:

| Layer | Rotates | Notes |
|---|---|---|
| Ground shadow | No | Never baked into the wheel |
| Stationary base and socket | No | Shows the ports |
| Rotating wheel | Yes | Pivot exactly at the center; the teeth fit the board pitch |
| Center hub | Optional | Spins with the wheel or stays fixed, per category |
| Category badge | No | Shape and icon, not only color |
| Tier marker | No | See below |
| Power indicator | No | Energy Gold only when the gear is powered |
| Production progress | No | A ring or gauge, driven by the simulation clock |
| Connection indicator | No | Drawn per reciprocal port |

**Tiers:**
- The maximum tier is 3 (`gear_rules.json` `merge.maxTier`).
- Each tier adds spokes and changes the hub and rim construction: tier 1 is a gunmetal rim, tier 2 a brass-inlaid rim, tier 3 a polished brass rim with an energy hub.
- A visible numeral or pip marker also shows the tier. Never just a recolor.

**States:**
- Available, selected, dragging.
- Valid or invalid placement.
- Connected, powered, unpowered, jammed (an odd gear loop) and conflicted (more than one core).
- Producing, output blocked, merge eligible, upgraded.
- Jammed and conflicted each get a warning icon and a non-operational animation, not just a red tint.

**Motion follows the simulation exactly:**
- The rotation direction comes from `rotationParity` (it alternates across each mesh).
- Unpowered gears stand still.
- Production pulses align to the output clock.
- The details are in `ANIMATION_SPECIFICATION.md` §5.

**The board** reads like an industrial control station:
- a frame;
- slot states (empty, powered, locked);
- port indicators, connection overlays and a selection highlight;
- the drag ghost and merge preview;
- shop cards, the cost badge, reroll, sell/recycle and undo.

Slot edges must read against both light and dark gears. Connection graphics show reciprocal ports exactly, and the visuals never change the logical 5×5 grid.
