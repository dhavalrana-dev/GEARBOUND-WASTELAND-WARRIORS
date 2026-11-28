# Asset generation prompts

**Version:** 1.0 (2026-11-28). It replaces art direction v2 §28 and extends it.

**Use:**
- These are briefs for an artist or an image-generation tool. Generated output starts at manifest status `concept`. It is never production-ready until it passes `ASSET_VALIDATION_GUIDE.md`.
- **Order:** follow the execution order in `ART_DIRECTION.md` §7. Do not run prompts for production parts (§4 onward) before their master is approved.

## 1. Rules for every prompt

**Base style block:** prepend it to every prompt.

> Original artwork for GEARBOUND, a premium mobile game in a Tactile Industrial Comic 2.5D style: handcrafted comic-book illustration with confident dark outlines (heavier on the silhouette), two- or three-tone cel shading with cool cobalt-leaning shadows, hand-painted industrial materials without photographic texture or noise, warm key light from the upper left, a miniature industrial diorama feel, strong readable silhouettes, saturated but controlled color.

**Negative block:** append it to every prompt.

> No text, letters, numbers, logos, watermarks or signatures. Not photorealistic, not glossy plastic 3D, not chibi, no stickmen, no flat vector icon style, no heavy gradients, no bloom or lens effects. Do not imitate or reference any existing game's characters, interface, logos or artwork.

**Logging and references:**
- Record the tool, model or version, date, seed (if any), the full prompt and any reference inputs in the asset's provenance. Store the prompt file under `assets-source/**/prompts/`.
- References may only be our own approved assets, for example the approved Rivet master for later Rivet prompts. Never use reference-game screenshots as image inputs.
- Use the token and material names from `VISUAL_STYLE_BIBLE.md` and `MATERIAL_LIBRARY.md`, with hex values where the tool accepts them.

## 2. ART-01: direction and benchmark compositions

**Illustrated mood board (`style_mood_board`):**
> A 16:9 presentation board of original studies for an industrial wasteland world: a warm desert pass with copper scrap and abandoned mining machinery, a rolling workshop fortress, three tactile brass and gunmetal gears with thick beveled teeth, a heroic mechanic silhouette, comic-style raider silhouettes, painted-steel UI panel fragments with riveted chamfered corners. Organized as a clean grid of studies on a dark steel background.

**Generated concept v001:** `assets-source/style-bible/industrial-comic-style-study_v001.png`. The exact executed prompt and provenance are archived at `assets-source/style-bible/prompts/industrial-comic-style-study_v001.md`. It remains at manifest status `concept` pending owner review and commercial-use terms confirmation.

**Material library sheet (`style_material_library`):**
> A material reference sheet of 15 hand-painted stylized material swatches in a 5×3 grid. Each shows a sphere, a cube and a gear tooth with lit, shadow and worn areas: painted steel, gunmetal, brass, copper, rusted machinery, weathered concrete, industrial glass, canvas, leather, rubber, glowing mechanical energy, sand, rock, vegetation, water. Brush strokes follow the form, with designed hard-edged shadow shapes and no photographic texture. Neutral dark background, even spacing.

**Portrait composition (`style_portrait_composition`):**
> A vertical 9:16 gameplay mock-up. Top: a thin resource bar. Upper 40%: an elevated side-view battlefield with three receding horizontal lanes, a rolling workshop fortress on the left and a scrap gate on the right, in a warm desert industrial pass. Middle: a hero control strip. Lower 45%: a 5×5 mechanical gear board in an industrial control-station frame with tactile gears, and three shop cards below. Interface areas are blank shapes; no text.

**Landscape composition (`style_landscape_composition`):** the same, at 16:9, with the board and shop in the left third and the battlefield and hero controls in the right two-thirds.

## 3. ART-02: Rivet master

**Turnaround:**
> Character turnaround of Rivet, an original adult human mechanic-fighter: athletic practical build, friendly determined face with expressive eyebrows, protective goggles pushed up on the forehead, an asymmetrical copper-and-teal workshop jacket with one reinforced shoulder, a canvas tool belt, heavy reinforced boots, an oversized mechanical glove on the tool hand, and a crescent wrench-hammer hybrid weapon. 4.5–5.5 heads tall. Five views on one shared height line: front, right three-quarter, right side, back, back three-quarter. Neutral standing pose with clear limb separation and readable joints. Transparent or flat neutral background.

**Near/far limb sheet:**
> Using the approved Rivet turnaround as the only reference, draw the near-side and far-side arm and leg separately as seen from a slightly elevated right-facing three-quarter camera. The far limbs show more inner surface, are slightly narrower and shorter in projection, sit in deeper cooler shadow, and are partly occluded by the torso. They are not mirrored copies of the near limbs. Label areas by shape only (no text); include hidden overlap at every joint.

**Expression, weapon and action sheets:** reuse the turnaround prompt with: "an expression sheet of 6 heads" / "the wrench-hammer from three angles with its grip point marked by a small circle" / "6 action thumbnails: wind-up, impact, special ground slam, hit reaction, victory, lane dash".

## 4. Production parts (after ART-02)

**Rig parts:**
> Using the approved Rivet master as the authoritative reference, produce separated parts for skeletal animation on one 2048×2048 master canvas with consistent registration: head base, hair front and back, goggles, neck, upper and lower torso, near and far upper arm, forearm and hand, near and far thigh, shin and foot, mechanical glove, tool belt, weapon. Near and far limbs are independently drawn with correct surfaces, perspective, occlusion and shading; never mirrored. Hidden overlap continues under every joint, and joint ends are clean rounded caps. Keep the approved costume, proportions, outline weight, materials and lighting. Transparent background.

**Enemy concept (template):**
> An original wasteland raider enemy for the same game: [ROLE, from `CHARACTER_DESIGN.md` §4], [SIGNATURE FEATURE], built from rusted machinery, gunmetal, rubber and scrap plates with crimson cloth accents. [Shape language for the role]. Right-facing three-quarter view, slightly from above, full body, and a turnaround (front, three-quarter, side).

**Scrapmaw boss:**
> An original large scrap-machine boss about 2.5× the hero's height, with a jaw-like scoop arm, three readable mechanical zones (body, scoop arm, exhaust stack), heavy and deliberate. Show the neutral pose and a clear wind-up pose in which the scoop arm is raised and its strike zone is the highest-contrast area.

## 5. Mechanical artwork

**Gear (template, per category and tier):**
> An original functional industrial gear, [CATEGORY: power core with an energy chamber / plain drive wheel / ratchet booster with pawl and spring / unit gear with a deploy hatch / turret gear with a barrel mount], tier [1: gunmetal rim, 6 spokes / 2: brass-inlaid rim, 8 spokes / 3: polished brass rim with an energy hub, 10 spokes]. Dimensional beveled teeth with a visible side face, reinforced rim, centered axle, restrained metallic cel shading, seen from slightly above. Deliver separate layers: rotating wheel (exactly centered), stationary base with ports, center hub, category badge. No glow, progress ring or shadow baked into the wheel. Transparent background.

**Board frame:**
> An industrial control-station frame for a 5×5 gear grid: painted steel and gunmetal with brass corner plates, rivets and chamfered corners, recessed slot sockets with empty, powered (warm energy rim) and locked (crossed bars) variants as separate layers. Blank slots, no text.

**Fortress:**
> An original rolling workshop fortress, the Wayfarer: a reinforced chassis on heavy treads, armor panels, tool racks, teal glass windows, a power-indicator column, three deploy hatches facing right, and a turret mount. Elevated right-facing side view. Separate overlay layers for damaged and critical states.

## 6. Environment (Copperwash first)

> A layered battlefield for an elevated side view: Copperwash Pass, a warm desert industrial pass in late afternoon. Sky, distant mesas, far abandoned ore crane and conveyor bridge, mid-background copper pipe clusters and a wind pump, near-background scrap walls, a quiet sandy gameplay ground with three receding horizontal lane strips, a fortress pad on the left and a scrap gate on the right, and foreground debris kept to the screen edges. Every layer is delivered separately. The gameplay ground stays low in detail and saturation. Palette: desert sand, mesa rust, copper with teal patina, sun-bleached concrete, shadow plum in the distance.

## 7. Interface and gamification

**UI kit:**
> A premium mechanical comic interface kit: chamfered painted-steel panels with brass trims and rivets, tactile beveled buttons in primary, secondary, destructive, disabled, pressed and selected states, gear-socket slots, a resource-pill frame, a progress bar with a brass casing, a card frame. Nine-slice-friendly, with plain corners and plain stretchable edges. No text.

**Event card template:**
> A modular event card frame with an illustrated header area for an event emblem, an empty title plate, an empty timer plate and an empty reward row. A [Scrapstorm: dust storm, flying scrap, gold and copper / Gear Frenzy: interlocking rotating gears, orange and energy yellow / Engineering Trials: blueprint grid, cobalt and cyan] motif. All text areas are blank plates.

**Reward chest:**
> A tactile reinforced supply chest of painted steel and brass with heavy latches and a gear-shaped lock, in closed, shaking (anticipation) and open states with light spilling out, as separate layers. A star-milestone variant has a star emblem cut into the lid.

**Campaign map section:**
> An illustrated top-down-angled map section of Copperwash Pass: a winding transport road connecting mission-node sockets, landmarks (scrap tower, abandoned workshop, boss monument), terrain transitions, a reward checkpoint post. Node sockets are empty circles; no text or numbers.

**Victory screen backdrop:**
> A celebratory result-screen backdrop: a brass-and-steel banner frame with three empty star sockets, mechanical confetti of small gears and sparks, a warm light burst. Blank title and reward plates.
