# GEARBOUND: Wasteland Warriors — Production Art Direction and Visual Style Bible

**Document version:** 2.0 (replaces v1, the three-paragraph direction note)
**Status:** Proposed production specification. **No artwork has been produced or approved yet.**
**Platforms:** Android and iOS
**Rendering:** Unity 6.3 LTS and Flutter/Flame
**Related:** `GAME_DESIGN_DOCUMENT.md`, `UI_UX_SPECIFICATION.md`, `PHASE_ROADMAP.md`, `CROSS_ENGINE_PARITY.md`, `PRODUCTION_ASSET_INVENTORY.md`, `shared/art/asset_manifest.json`

> **Repository reconciliation (2026-11-27).** Runtime IDs in this document come from shared JSON. The Copperwash boss *node* is named "Scrapjaw" (`copperwash-05`), but the boss *enemy* is `boss.scrapmaw` ("Scrapmaw"). This naming conflict is open (ART-ID-01 in the inventory); nothing has been renamed. There is no ranged friendly unit in the data, and friendly infantry is produced by the `unit.rivetguard` gear, so there is no separate unit definition file. The current prototype colors live in `flutter/lib/design_system/tokens.dart`.

---

## 1. Creative vision

GEARBOUND is an original mechanical strategy and action game set in a colorful industrial wasteland. It combines satisfying gear construction, automatic unit production, multi-lane battlefield combat, expressive characters, illustrated environments, campaign exploration and rewarding progression.

The visuals must read as a premium handcrafted indie game, not a generic mobile prototype. The visual identity stays consistent across gameplay, characters, gear machinery, world maps, events, shops, rewards, animation and marketing art.

### Creative references

| Reference | What it informs |
|---|---|
| Gear Fight! | Mechanical board, gear rotation and connections, immediate feedback, readability at mobile scale, purchasing and merging, simple interactions |
| The Last Friend | Elevated side-view battlefield, expressive comic characters, angular silhouettes, handcrafted environments, stylized combat animation, layered depth, illustrated UI |
| Candy Crush Saga | Illustrated campaign maps, distinct regions, event presentation, progress indicators, reward chests, daily tasks and milestones, clear shop interfaces |

References inform broad design principles only. Never reproduce proprietary artwork, characters, interface graphics, logos, environments or animation assets.

## 2. Mandatory visual style — "Industrial Comic 2.5D"

**Required:**
- A handcrafted illustrated look, with angular cartoon anatomy and athletic, exaggerated proportions.
- Expressive poses and faces, and strong silhouettes.
- Controlled dark outlines and two- or three-tone cel shading.
- Mechanical details that have a clear functional purpose, and rich industrial materials.
- Warm environmental lighting, and saturated but controlled accents.
- Clear separation between foreground, gameplay and background, with consistent perspective.

**Forbidden:**
- Stickmen, generic chibi characters, photorealistic characters, or plastic-looking generic 3D.
- Flat vector icons used as final characters, or unrelated asset-pack styles.
- Excessive gradients or bloom.
- Random proportions or inconsistent outline weight.
- Confusing mechanical parts.
- Identical duplicated near-side and far-side limbs.

The primary direction is stylized 2D art in a simulated 2.5D world. Full 3D environments are optional, and only if they add no inconsistency or unnecessary cost.

## 3. Visual pillars

1. **Mechanical satisfaction.** Machines look functional: rotating teeth, transmission connections, pistons, energy pulses, locks, production cycles and visible outputs. A player can tell why a machine is running or idle without reading text.
2. **Character personality.** Every major character is identifiable from silhouette alone: hair, costume, equipment, body shape, movement and expression.
3. **Environmental storytelling.** Each region tells its history through structures, abandoned machines, terrain and settlements.
4. **Gameplay readability.** Foreground detail, lighting, background motion and effects never hide enemies, projectiles, lane boundaries, gear connections or controls.
5. **Reward satisfaction.** Rewards look tangible (crates, polished alloy, blueprints, badges, components, cosmetics). Reward animations are short, skippable where appropriate, and clear.

## 4. Color system (proposed tokens)

| Token | Color | Purpose |
|---|---|---|
| Steel Deep | #192531 | Main interface shadows |
| Gunmetal | #344657 | Mechanical panels |
| Outline | #20262D | Primary illustration outlines |
| Cobalt Steel | #386A97 | Industrial structures |
| Machine Teal | #35A7B5 | Friendly technology |
| Copper Rust | #C56B42 | Mechanical accents |
| Brass | #D6AC63 | Gears and reward accents |
| Energy Gold | #F4BF4F | Active power |
| Acid Lime | #B9DF54 | Valid connection indicators |
| Friendly Green | #63B77B | Positive gameplay state |
| Enemy Crimson | #D65760 | Threats |
| Special Violet | #9B73D0 | Rare abilities and rewards |
| Desert Sand | #D8B98B | Wasteland environments |
| Neutral Light | #F2E6D1 | Text and highlights |

Rules:
- Environments are less saturated than active gameplay objects, and bright energy colors are reserved for function.
- Red means threat or invalid, but color is never the only signal: icons, outlines, animation and labels carry state too.
- Character colors stay identical across portraits, sprites, rig parts and marketing.
- Each region may add 3–5 environment colors. Do not recolor the whole UI theme per event.
- These are starting values. Approve them in a composed in-engine scene before locking. The prototype palette in `tokens.dart` (`ink`, `panel`, `cream`, `amber`) is temporary.

## 5. Camera and 2.5D projection

The battlefield uses an elevated side view with three horizontal lanes: the friendly fortress on the left, enemy entrances on the right, and the nearest lane drawn closest to the viewer. Gameplay stays on logical positions (horizontal mm and lane index).

**Projection contract** (one shared contract for both engines, `shared/art/projection.json` when created):
- **Inputs:** horizontal simulation position, lane index, optional visual elevation.
- **Outputs:** screen position, lane scale, ground-shadow position, depth-sort key.
- **Initial art-test parameters:** near lane scale 1.00, middle 0.92, far 0.84; apparent camera elevation about 15–25°; light from the upper left. These are visual tuning values, not gameplay rules.
- **Depth sorting:** by ground-contact position, with ties broken by entity ID or explicit render priority.
- **Scale never changes gameplay:** visual scaling must not change range or reach in farther lanes.

## 6. Reference screen compositions

**Portrait (1080 × 1920 reference)**, after safe areas:

| Area | Share of height |
|---|---|
| Status and resources | 6% |
| Battlefield | 40% |
| Hero controls | 8% |
| Mechanical board | 29% |
| Shop and actions | 17% |

During combat, collapse nonessential shop controls; output status stays visible. *Current prototype:* the canvas takes 11/20 and the controls scroll (see `FLUTTER_ARCHITECTURE.md`).

**Landscape (1920 × 1080 reference):** board and shop take 34% of the width, battlefield and hero controls 66%, with a shared resource and wave strip on top.

**Tablet:** more spacing and larger targets, but never more gameplay capacity, visible range or gear slots.

**Responsive rules:**
- Preserve aspect ratios, and never stretch characters or gears.
- The logical board stays 5×5.
- Respect safe areas and cutouts, readable text and touch targets.
- Preserve mission state through rotation.
- Test compact, tall, tablet and foldable screens, based on viewport size rather than device model.

## 7. Character design language

**Adult heroes:**
- About 4.5–5.5 heads tall, with strong shoulders and readable hands.
- Slightly oversized boots, distinct costume shapes, and angular torso and limbs.
- Expressive faces that are not over-exaggerated.
- Each approved hero gets a proportion guide; do not force identical bodies.

**Shape language by role:**

| Role | Shapes |
|---|---|
| Heroes | Balanced angular and rounded shapes, open expressions, recognizable equipment |
| Heavy enemies | Broad rectangles and triangles, strong shoulders, heavy armor, deliberate movement |
| Fast enemies | Narrow, forward-leaning, pointed armor, light kit |
| Companions | Compact, visible joints, distinct energy indicators |
| Bosses | Large silhouette, several readable mechanical zones, clear anticipation and vulnerable states |

## 8. Main hero — Rivet

**Identity (preserved from v1):** adult human mechanic-fighter with an athletic, practical build and a friendly, determined face.
- Expressive eyebrows and goggles pushed onto the forehead.
- Asymmetrical copper-and-teal workshop jacket, reinforced boots and a canvas tool belt.
- Oversized mechanical glove on the tool hand.
- A crescent wrench-hammer hybrid weapon.

Rivet should read as inventive, resourceful, energetic and approachable: able to repair machines and to fight.

**Signature silhouette:** raised goggles, asymmetrical shoulder and sleeve, oversized glove, crescent wrench-hammer, heavy boots. Never a generic futuristic soldier.

**Concept deliverables:**
- Full-body neutral pose.
- Front, right-facing side, right-facing three-quarter and back views.
- Expression, proportion, color/material, weapon and action-pose sheets.
- Modular body-part sheet.
- Portrait and selection-screen illustration.

The approved master is the authoritative reference for everything later.

## 9. Initial roster (vertical slice only)

| Asset | Runtime source | Role | Priority |
|---|---|---|---|
| Rivet | Hero in `BattleSession` (no data file yet) | Main hero | P0 |
| Rivetguard soldier | Spawned by gear `unit.rivetguard` | Friendly infantry | P0 |
| Scrap Raider | `raider.basic` | Basic enemy | P0 |
| Rustrunner | `raider.runner` | Fast enemy | P0 |
| Slagback Bruiser | `raider.bruiser` | Heavy enemy | P0 (used in route encounters) |
| Scrapmaw | `boss.scrapmaw` (the "Scrapjaw" node's boss; naming open, ART-ID-01) | Copperwash boss | P0 |
| Ranged friendly unit | **None in data** | — | Not planned until a ranged gear exists |
| Mossback | Node `ironwood-05`; no enemy ID yet | Ironwood boss | P1 |
| Future heroes (Torque, Volt, Ember, Patch, Scout) | None | Expanded roster | P2, concepts only |

Never invent runtime IDs that conflict with shared data.

## 10. Character source art and rigging

**Source master:**
- 2048 × 2048, transparent, sRGB.
- A shared origin, a documented ground-contact point and a consistent master height.
- Editable layers. Use larger canvases only with justification; runtime sizes are chosen by in-engine testing.

**Separated parts:**
- Head: head base, hair front, hair back, eyebrows, eyes, mouth/expression variants, goggles, neck.
- Body: upper torso, lower torso/pelvis.
- Arms: near and far upper arm, forearm and hand.
- Legs: near and far thigh, shin and foot.
- Equipment: jacket accessories, shoulder armor, mechanical glove, tool belt, weapon, back equipment where present.

**Near vs far:**
- Characters face right in three-quarter view. "Near" means closest to the viewer and "far" means partly behind the torso; these are depth labels, and anatomical left/right is recorded separately in rig metadata.
- Every limb needs correct perspective, scale, visible surface, shading, occlusion, outline, joint attachment and pivot.
- Never duplicate or mirror a near limb as the far limb.
- Keep hidden overlap beneath sleeves, armor, knees and elbows.

**Exports:**
1. Registered transparent parts on the master canvas, for assembly and validation.
2. Trimmed runtime sprites with recorded trim offsets, dimensions and pivots.

Never load full master canvases as runtime textures.

## 11. Skeleton hierarchy

```
root
  pelvis
    torso_lower
      torso_upper
        neck
          head
            hair_front
            hair_back
            goggles
            facial_features
        shoulder_near
          upper_arm_near
            forearm_near
              hand_near
                weapon_socket_near
        shoulder_far
          upper_arm_far
            forearm_far
              hand_far
                weapon_socket_far
    thigh_near
      shin_near
        foot_near
    thigh_far
      shin_far
        foot_far
```

**Additional sockets:** weapon, muzzle, projectile origin, hit effect, ground shadow, status effect, head indicator, backpack, mechanical attachment.

**Record:** parents, local transforms, rotation limits, rest pose, mesh weights, attachment rules and draw order.

Hitboxes and hurtboxes come from the logical simulation, never from rendered pixels.

## 12. Default draw order (back to front)

1. Ground shadow
2. Far leg
3. Far arm and hand
4. Back accessories
5. Pelvis
6. Torso
7. Neck
8. Head
9. Near leg
10. Near arm
11. Near hand
12. Weapon
13. Foreground costume accessories
14. Attached VFX

Animations may override the order temporarily, for example a weapon crossing the torso. Flipping a character never reassigns near and far. Asymmetrical characters need approved facing variants or attachment rules.

## 13. Animation

| Animation | Visual duration | Loop |
|---|---|---|
| Idle | 1.5–2.5 s | Yes |
| Walk | 0.7–1.0 s | Yes |
| Run | 0.5–0.8 s | Yes |
| Lane transition | 0.25–0.45 s | No |
| Light attack 1 / 2 | 0.3–0.5 / 0.35–0.55 s | No |
| Heavy attack | 0.6–0.9 s | No |
| Dash | 0.2–0.4 s | No |
| Hit reaction | 0.15–0.3 s | No |
| Knockback | 0.3–0.5 s | No |
| Special ability | 0.6–1.2 s | No |
| Death | 0.6–1.2 s | No |
| Victory | 1.5–2.5 s | Optional |

These are proposed visual timings. **Gameplay timing in the simulation is authoritative** (for example, the hero's `attackIntervalTicks: 18` at 30 Hz is 0.6 s). Animations align to ticks and state transitions, and animation callbacks never deal damage.

**Quality bar:**
- Feet stay grounded, with no sliding run cycles.
- Weapons follow their socket, and limbs never detach.
- Identity is preserved; use subtle breathing and accessory motion.
- No impact-killing tweens.
- Every major enemy attack has readable anticipation.

## 14. Mechanical gear art

Gear art is a primary gameplay asset. Each gear needs:
- A clear silhouette, readable teeth, a visible axle, distinct spokes and depth.
- Restrained metallic highlights.
- A category indicator, tier variants and functional ports.

The source of truth is `shared/gears/starter_gears.json`: `core.wayfarer`, `drive.coupler`, `boost.ratchet`, `unit.rivetguard`, `turret.spark`. All five are in the vertical slice; the turret has been sold since GB-037.

**Runtime layers:**
- Stationary base/socket
- Rotating wheel (exact center pivot)
- Center hub
- Category badge
- Power overlay
- Production progress
- Connection indicator
- Tier badge

Teeth must fit the board geometry. Never bake a shadow that rotates with the wheel.

**States:**
- Available, selected, dragging.
- Valid placement, invalid placement.
- Connected, powered, disconnected, conflicted.
- Producing, output blocked.
- Merge eligible, upgraded, temporarily disabled.

Build states by combining layers, not with a texture per state.

**Tiers:** the max tier is 3 (`gear_rules.json` `merge.maxTier`). Higher tiers add spokes, a refined hub, distinct rim construction, controlled energy highlights and a visible marker, never just a recolor.

**Export targets:**

| Asset | Size |
|---|---|
| Source | ~512² |
| Runtime wheel | 128–256 px, chosen by screen test |
| Item icon | 128–256 px |
| Small state icon | 48–96 px |

## 15. Gear board visuals

The board looks like an industrial control station. Assets:
- Frame; slot backgrounds for empty, powered and locked.
- Connection overlays, selection highlight and port indicators.
- Merge effect and drag preview.
- Purchase card, scrap cost badge and reroll button.
- Sell/recycle area, undo control and production progress.

Slot edges must read against both light and dark gears, and visuals never change the logical grid. Connection graphics show reciprocal ports exactly. Conflicted gears get a warning icon and a non-operational animation, not just a red tint.

## 16. Environments

**Copperwash Pass (first region):** warm desert industrial wasteland.
- Warm sky, distant rocks, abandoned towers.
- Rusted machinery, broken concrete, pipes and cables.
- Scattered copper scrap, dust, industrial ground, foreground debris.

**Ironwood Frontier:** reclaimed industrial forest, with overgrown and moss-covered steel, filtered sunlight and broken transport routes.

**The Sunken Yard:** flooded ruins, with rusted cranes, waterlogged machinery, teal and blue tones, puddle reflections, mist and damaged platforms.

Other regions stay planned until the first slice is approved.

## 17. Layering and parallax

| Layer | Parallax |
|---|---|
| Sky | 0.00 |
| Distant silhouettes | 0.10 |
| Far architecture | 0.25 |
| Mid-background | 0.45 |
| Near-background | 0.70 |
| Gameplay ground | 1.00 |
| Characters and machines | 1.00 |
| Foreground | 1.10–1.20 |

With a fixed camera, prefer restrained ambient motion over artificial parallax.

**Sources:**
- Wide master: 3840 × 2160.
- Parallax strips: up to 4096 px wide.
- Props: 256–1024 px.
- Seamless ground tiles where needed.

Tile oversized textures, and never export every layer at source resolution. Test against real memory budgets.

## 18. Fortress and defensive equipment

**Fortress** (the visual anchor):
- Recognizable silhouette and reinforced chassis.
- Wheels or tracks, power indicators, armor panels and tool storage.
- Defensive attachments and gear-powered machinery.

**Fortress states:** normal, producing, shielded, damaged, critical, defeat, victory. Damage is shown with composable overlays.

**Defensive equipment:** base, rotating head, barrel, muzzle socket, activation effect, projectile origin and cooldown state. Only for implemented equipment types.

## 19. Visual effects

**Required:**
- Gear: placement, connection, disconnection, merge, power transmission.
- Combat: unit deployment, melee hit, ranged shot, projectile impact, shield, damage reaction, enemy defeat, boss warning.
- Results: victory, reward collection.

**Starting durations:**

| Effect | Duration |
|---|---|
| Gear snap | 100–180 ms |
| Merge | 250–450 ms |
| Hit flash | 60–120 ms |
| Critical impact | 120–220 ms |
| Reward reveal | 300–700 ms |

Effects are pooled, with configurable particle limits. Reduced-motion mode cuts shake, pulses, flashes and nonessential animation. Effects never hide attack telegraphs.

## 20. UI/UX art system

**Panels:** angular industrial frames, dark steel interiors, small brass or copper edges, controlled bevels, readable text areas and a clear hierarchy. Use nine-slice; never stretch corners.

**Button families:** primary, secondary, destructive, disabled, selected, pressed, loading, rewarded-ad action and purchase action. Ads and purchases must never look like ordinary navigation.

**Typography:**
- Commercially licensed fonts: a bold industrial or comic display face and a highly legible sans for body text.
- Tabular numerals for prices, health and currency.
- Localization-ready.
- Text is never baked into art, including prices, descriptions and dates.

## 21. Campaign map

A handcrafted illustrated Wasteland Route with winding transport routes, landmarks, settlements, terrain transitions, mission nodes, boss monuments, reward checkpoints and a moving fortress marker.

**Node states:** locked, available, selected, completed, 1★, 2★, 3★, hard, boss, event.

Hit areas are separate from decorative art. Use reusable regional tiles and landmarks, never a full-screen image per node. Mission IDs and unlock rules are preserved.

## 22. Gamification and LiveOps art

Use modular event templates.

| Event | Visual motifs |
|---|---|
| Scrapstorm | Dust storm, flying debris, scrap emblem, gold and copper |
| Gear Frenzy | Interlocking rotating gears, orange and energy yellow |
| Engineering Trials | Blueprint grid, diagrams, tools, cobalt and cyan |
| Future events (Boss Rush, Iron Fortress, Blueprint Hunt, Endless Siege, Convoy Expedition, Festival of Machines) | Motifs consistent with the world |

**Per event:** emblem, landscape banner, portrait card, reward-track background, milestone marker, completion badge, token icon where used, and locked/expired states.

Titles, timers, objectives and rewards stay in dynamic, localized UI.

## 23. Rewards and shop art

**Containers:** small, medium and reinforced supply crates, star milestone chest, blueprint container, premium alloy container.

**Currency icons**, one for each currency in `shared/economy/currencies.json`:
- `battle_scrap` and `workshop_scrap`, which must be visually distinct.
- `alloy`, with its own silhouette and material.
- `blueprints`, `event_tokens` and `xp`.

**Shop art:**
- Small, medium and large alloy bundles.
- Starter bundle and booster bundle.
- Hero and fortress cosmetics.
- Remove Interstitial Ads icon.

Prices are never baked into art; show only catalogue quantities and store-localized prices.

**Rewarded-ad UI:**
- Shows the exact reward, an ad icon, a Watch Ad action, the normal reward action, unavailable/loading states and verification pending.
- The normal reward action stays readable and accessible.
- No misleading buttons, fake close controls or artificial countdowns.

## 24. Asset directories

**Source art:** `assets-source/` (exists).
- `style-bible/`
- `characters/rivet/{concepts,turnarounds,layered,rig,animation,exports}/`
- `characters/rivetguard/`
- `enemies/`, `bosses/`, `gears/`, `machines/`, `fortress/`
- `environments/{copperwash,ironwood,sunken}/`
- `effects/`
- `ui/{panels,buttons,icons,map,events,rewards,shop}/`
- `audio/`, `marketing/`, `manifests/`

**Runtime:** `unity/Assets/Game/Art/` and `flutter/assets/art/` (to be created with the first approved asset).

**Shared metadata:** `shared/art/`.
- **Created:** `asset_manifest.json` and its schema.
- **Planned:** `character_rigs.json`, `animation_catalog.json`, `environment_layers.json`, `projection.json`, `ui_tokens.json`.

Do not move validated files just to match this layout.

## 25. Naming

Lowercase snake_case, with stable logical IDs that are independent of revision filenames. Examples: `chr_rivet_arm_near_upper_v001.png`, `gear_transmission_t01_wheel_v001.png`, `env_copperwash_bg_far_v001.png`, `ui_event_scrapstorm_banner_v001.png`, `fx_gear_merge_v001.png`. No spaces, no "final-final".

## 26. Asset manifest

Every production asset has a record in `shared/art/asset_manifest.json` (schema: `shared/schemas/asset-manifest.schema.json`, checked by `validate_shared.py`). The fields:

| Group | Fields |
|---|---|
| Identity | `assetId`, `category`, `logicalOwnerId` |
| Paths | `sourcePath`, `runtimePaths` |
| Dimensions | `sourceWidth`, `sourceHeight`, `runtimeWidth`, `runtimeHeight` |
| Placement | `pivotX`, `pivotY`, `trimOffset`, `originalCanvasSize` |
| Rendering | `atlasGroup`, `colorSpace`, `animationReference`, `drawOrder` |
| Provenance | `license`, `provenance` |
| Review | `revision`, `status`, `reviewer`, `acceptanceEvidence` |

**Status lifecycle:** `planned` → `concept` → `approved_concept` → `source_ready` → `rigged` → `animated` → `runtime_integrated` → `qa_passed` → `approved`. Generating an image does not complete an asset.

## 27. Vertical-slice inventory

Planning targets, not existing inventory. The itemized list is in `PRODUCTION_ASSET_INVENTORY.md`.

| Category | Target |
|---|---|
| Final hero | 1 |
| Friendly unit types | 1 (Rivetguard) |
| Enemy types | 3 (`raider.basic`, `raider.runner`, `raider.bruiser`) |
| Boss | 1 (`boss.scrapmaw`) |
| Gear types | 5 (starter catalogue) |
| Gear tiers | 3 |
| Fortress | 1 |
| Complete environment | 1 (Copperwash) |
| Environment layers | 7 |
| Modular props | 15–25 |
| Core VFX | 12–16 |
| UI panel families | 4–6 |
| Button families | 5–7 |
| Functional icons | 30–50 |
| Campaign region map | 1 |
| Event art sets | 3 |
| Reward chest variants | 3–5 |
| Currency icons | 6 |
| Shop product illustrations | 5–8 |

Cut scope if art or performance blocks progress. Do not produce future characters or regions before the slice is approved.

## 28. AI-assisted asset workflow

1. Approved concept.
2. Master turnaround.
3. Color and material sheet.
4. Camera and lighting reference.
5. Individual parts.
6. Perspective and anatomy validation.
7. Transparency cleanup.
8. Alignment on the master canvas.
9. Pivots.
10. Skeleton.
11. Extreme-pose test.
12. Animations.
13. Optimized exports.
14. Integration in both engines.
15. Gameplay capture.
16. Approve or revise.

Never mass-generate assets from an unapproved reference. Keep prompts, references, revisions and licenses. Never claim generated assets are approved without a real review.

**Master character prompt.** Create an original adult mechanic-fighter for a premium stylized 2.5D industrial wasteland arcade strategy game. Use expressive angular comic-book anatomy, athletic practical proportions, strong readable silhouettes, slightly oversized hands and reinforced boots, controlled cel shading, consistent dark outlines and upper-left lighting. Character identity: Rivet, a resourceful engineer wearing protective goggles on the forehead, an asymmetrical copper-and-teal workshop jacket, canvas tool belt, oversized mechanical glove and distinctive crescent wrench-hammer hybrid. Show a right-facing three-quarter neutral pose with clear limb separation and readable joint locations. Maintain consistent identity and proportions across all subsequent assets. Isolated transparent background; no text, watermark, decorative background or copied reference-game character designs.

**Rig-sheet prompt.** Using the approved Rivet master turnaround as the authoritative reference, produce separated skeletal animation artwork on a consistent master coordinate system. Include distinct near-side and far-side upper arms, forearms, hands, thighs, shins and feet, plus head, torso, pelvis, accessories and weapon. Near-side and far-side limbs must be independently designed with correct visible surfaces, perspective, occlusion and shading; do not duplicate or mirror limbs. Include hidden overlap beneath every joint. Maintain the approved costume, proportions, outline thickness, materials and lighting. Export individual transparent assets and a labeled assembly reference (documentation, not a runtime sprite).

**Environment prompt.** Create an original layered industrial desert wasteland battlefield for a premium illustrated 2.5D mobile arcade strategy game: stylized angular architecture, abandoned mechanical factories, sun-bleached concrete, copper-colored scrap, warm upper-left sunlight. Elevated side-view battlefield with three readable horizontal lanes, space for a friendly fortress on the left and enemy entrances on the right. Keep the active ground subdued and readable. Separate sky, distant landscape, far architecture, mid-background, near-background, gameplay ground and foreground decoration into independent layers. No characters, UI, text, watermarks or copied commercial artwork.

**Gear prompt.** Create an original functional industrial gear for a stylized mobile mechanical strategy game: readable circular silhouette, clearly defined teeth, centered axle, reinforced spokes, controlled metallic cel shading, consistent mechanical comic style. Provide independently exportable rotating wheel, stationary base, center hub and optional category details with exact center alignment. Do not bake text, power glows, production indicators or background shadows into the wheel. Transparent background; approved Gearbound palette.

## 29. Unity integration

- Evaluate the official 2D Animation and Sprite Atlas packages before adding dependencies.
- Sprite import with consistent pixels-per-unit and custom pivots; preserve trim data.
- Character prefabs, and sorting layers.
- Projection from logical state, with animations bound to simulation events.
- Pooling for units, projectiles and effects; atlases; compression chosen after visual tests.
- Responsive UI.
- `Gearbound.Core` and `Gearbound.Economy` stay free of presentation dependencies.
- Adopt URP only after compatibility and profiling checks.
- Unity art is not integrated until a playable scene uses approved assets.

## 30. Flutter/Flame integration

- Replace the canvas primitives in `lib/game/gearbound_game.dart` incrementally.
- Use Flame sprite and animation components, driven by shared character and projection metadata.
- Depth sort by ground contact.
- Separate rotating gear components, reusable environment layers and character renderers.
- Render interpolation independent of 30 Hz ticks, and event-driven UI.
- Texture caching and pooling; Flutter widgets for menus and overlays.
- For skeletal animation, evaluate a supported runtime on licensing, performance and integration cost. Otherwise export approved animations as sprite atlases with shared frame and event metadata.
- Never assume Unity rig files run in Flutter. Never lower the art bar for engine differences.

## 31. Visual performance budgets (targets, unmeasured)

**Targets:**
- 60 FPS on representative mid-range devices, with a stable 30 FPS fallback.
- Typical atlas 2048²; larger only with measured justification.
- Limited particles, no runtime texture decoding in combat, and no unused layers loaded.
- Texture memory measured on device, with no unnecessary full-screen post-processing.
- The simulation stays at 30 Hz.

**Quality levels:**

| Level | Contents |
|---|---|
| Low | Fewer particles, less ambient motion, simple shadows, no post-processing |
| Medium | Standard art, particles and camera effects |
| High | Extra atmosphere and lighting, within measured budgets |

Gameplay rules are identical at every quality level.

## 32. Art QA

**Reject** assets with any of:
- Bad transparency or edge halos.
- Inconsistent lighting, wrong perspective or inconsistent proportions.
- Duplicated near/far limbs, missing joint overlap or wrong pivots.
- Skeletal gaps, blurry exports or wrong draw order.
- Unreadable silhouettes, distorted layouts or excessive texture memory.
- Missing license or provenance.

Validate at gameplay scale.

**Evidence:**
- Source preview, sprite exports and rig assembly.
- Animation preview.
- Portrait and landscape gameplay screenshots, from both Unity and Flutter.
- Performance capture where relevant.

## 33. Art gates

| Gate | Deliver | Exit |
|---|---|---|
| ART-01 Visual direction | Mood board, palette, character, environment and UI style references | One coherent direction |
| ART-02 Rivet master | Turnaround, proportion, color and weapon sheets, modular parts | Identity, anatomy, perspective and costume consistent |
| ART-03 Rig and animation | Skeleton, pivots, initial animations, metadata | No gaps, draw-order errors or detached weapons |
| ART-04 Mechanical and environment | Starter gears, board, Copperwash, fortress, units | Coherent battlefield |
| ART-05 UI and engagement | Map, workshop UI, HUD, events, rewards, shop, responsive layouts | Readable game and progression |
| ART-06 Cross-engine | Unity and Flutter visual slices, screenshots, validation, profiling | Approved art works in both engines |

**Current status: all gates not started.**

## 34. Final instruction

Do not generate production art at random. First approve one complete visual slice: Rivet, the starter board, representative enemies, the fortress, Copperwash, combat effects and the primary interface. Use it as the permanent benchmark, then expand through the approved pipeline. Never mark art or integration complete without verified evidence.
