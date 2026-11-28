# Material library

**Version:** 1.0 (2026-11-28). **Status:** proposed. The hex ramps are starting values until the owner approves them at ART-01, using the swatches on the reference board and, later, the benchmark scene. No painted material sheet exists yet (manifest `style_material_library`, `planned`).
**Related:** `VISUAL_STYLE_BIBLE.md` (tokens, lighting, shading), `ENVIRONMENT_PRODUCTION.md`, `ASSET_GENERATION_PROMPTS.md`.

## 1. How a material is painted

Every material is a **stylized recipe**, not a texture:
- **Base:** the local color, read from the ramp.
- **Shadow:** one cel step, cooler and darker, with its hue moved toward cobalt.
- **Highlight:** a small, hard-edged shape on planes facing the upper-left key light.
- **Accent marks:** the material's signature details (scratches, rivets, weave, grain). These are drawn, never noise.
- **Wear:** placed where use would put it (edges, corners, handles, feet), never spread evenly.

**Rules:**
- No photographic textures, no procedural noise, no normal-map look and no specular gloss.
- Brush strokes follow the form, and they are larger on big planes and simpler at small sizes.
- At gameplay scale a material must still read from its ramp and silhouette details alone. Small details drop out first.
- One material sheet serves both engines. Engines never recolor materials at runtime, except for state overlays that `RENDERING_ARCHITECTURE.md` defines.

## 2. Ramps

Each ramp lists base, shadow and highlight hex values, plus an accent where one applies. Shadow hues lean toward cobalt and highlights toward warm light.

| ID | Material | Base | Shadow | Highlight | Accent | Signature marks | Main uses |
|---|---|---|---|---|---|---|---|
| `mat_painted_steel` | Painted steel | #4E7896 | #2F4C66 | #9CC0D2 | Chipped to #6C7A86 | Paint chips on edges, rivet rows, stencil-free panels | Machine housings, fortress armor, UI frames |
| `mat_gunmetal` | Gunmetal | #3F4B57 | #252D36 | #8A98A6 | — | Tight angular highlights, bolt heads | Weapons, gear spokes, board frame |
| `mat_brass` | Brass | #C99A4E | #8A6430 | #F1D894 | #E6BF6A | Broad warm highlight band, small dents | Gear rims (tier markers), reward trims, UI corners |
| `mat_copper` | Copper | #C26A3E | #7E3F25 | #F0A877 | Patina #4FA39A | Patina in crevices, hammered facets | Copperwash identity, pipes, Rivet's jacket trims |
| `mat_rusted_machinery` | Rusted machinery | #9A5A3A | #5E3426 | #C98A5E | Old paint #5E7F8E | Rust blooms from joints, flaking paint islands | Abandoned machines, enemy scrap armor |
| `mat_weathered_concrete` | Weathered concrete | #B9AE9C | #8A8273 | #E2D8C4 | Stains #9C8E78 | Chipped edges, rebar stubs, drip stains | Fortifications, ruins, ground slabs |
| `mat_industrial_glass` | Industrial glass | #6FA9B6 | #3C6E7D | #E8F4F2 | Grime #7C8A72 | Two diagonal glints, wire mesh, dirt along frames | Gauges, cockpit windows, lamp covers |
| `mat_canvas` | Canvas | #B49A6E | #7F6A48 | #DCC79C | Stitching #6E5A3C | Fold creases, stitched seams, patches | Tool belts, tents, banners, Rivetguard packs |
| `mat_leather` | Leather | #7A4B32 | #4C2C1E | #B07A54 | Scuff #9A6A4A | Stitch lines, worn creases at bends | Gloves, straps, boots |
| `mat_rubber` | Rubber | #3A3634 | #222020 | #6E6864 | — | Matte, few highlights, tread patterns | Tires, hoses, grips, boot soles |
| `mat_mechanical_energy` | Mechanical energy | #F4BF4F | #D98A2B | #FFF3C4 | Core #FFFFFF | Pulse bands that follow conduits; additive glow allowed | Powered conduits, active gear hubs, special attacks |
| `mat_sand` | Sand | #D8B98B | #B0916A | #F0DDB6 | Pebbles #9C8466 | Wind ripples, scattered pebbles, soft drifts against objects | Copperwash ground, dunes |
| `mat_rock` | Rock | #A0785A | #6A4E3E | #CFA683 | Strata #8A644A | Angular planes, horizontal strata, chipped facets | Cliffs, boulders, distant mesas |
| `mat_vegetation` | Vegetation | #6F8F4E | #44603A | #A9C46E | Dry #A69456 | Clumped leaf shapes, dry tips, moss carpets | Scrub (Copperwash), moss and trees (Ironwood) |
| `mat_water` | Water | #3F8C9A | #275E6E | #BFE6E6 | Foam #E8F4F2 | Horizontal glint bands, ripple rings, edge foam | Puddles (Copperwash), flooded yard (Sunken) |

**Checks before approval:**
- Every functional token in `VISUAL_STYLE_BIBLE.md` §7 must stay distinguishable from every material base at gameplay scale. Energy Gold must not be confused with Brass highlights.
- Copper and Rusted machinery must stay distinct; they differ in saturation and patina.
- Sand and Weathered concrete must keep a 3:1 contrast with actor outlines in lane areas.

## 3. Combination rules

- A machine reads as at most **three** main materials, plus energy where it is powered.
- **Friendly technology:** painted steel, brass, teal glass and energy.
- **Enemy scrap:** rusted machinery, gunmetal, rubber and crimson cloth accents.
- **Copperwash:** sand, rock, weathered concrete, copper and rusted machinery.
- **Ironwood:** vegetation and moss over painted steel and rust.
- **Sunken Yard:** water, rust and concrete, with teal shadows.
- **Gears:**
  - The rim tier reads through material: tier 1 is gunmetal, tier 2 has a brass inlay and tier 3 a polished brass rim with an energy hub.
  - Tier never relies on color alone; the spoke count and hub design change as well (`VISUAL_STYLE_BIBLE.md` §12).

## 4. Deliverable

**Painted material sheet:** `assets-source/style-bible/style_material_library_v001.psd`.
- One sphere, one cube and one gear-tooth swatch per material.
- Each swatch shows lit, shadow and worn states, at master scale and at gameplay scale.
- It is exported as a PNG for review.

**Approval:** the sheet is approved at ART-01. After that, the IDs in this table are the vocabulary for manifest notes and prompts.
