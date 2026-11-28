# Character design

**Version:** 1.0 (2026-11-28). It replaces art direction v2 §7–9. **Status:** proposed; no character art exists. Rivet's identity is **established and preserved**: this document details it and changes none of it.
**Related:** `VISUAL_STYLE_BIBLE.md`, `CHARACTER_RIGGING_GUIDE.md`, `ANIMATION_SPECIFICATION.md`, `MATERIAL_LIBRARY.md`, `shared/enemies/enemies.json`.

## 1. Design language

Characters are **original, angular, comic-style figures**:
- strong silhouettes, athletic stylized proportions and expressive faces;
- controlled cel shading, consistent dark outlines and handcrafted material detail;
- a unique costume shape for each role;
- oversized mechanical weapons and tools, where they fit the role;
- drawn in a **right-facing three-quarter side view**, slightly from above, to match the camera (`VISUAL_STYLE_BIBLE.md` §8).

**Proportions:**

| Role | Head heights | Build |
|---|---|---|
| Adult heroes | 4.5–5.5 | Strong shoulders, readable hands, slightly oversized boots |
| Friendly infantry | 4–4.5 | Compact and armored; smaller than the hero on screen |
| Light enemies | 4.5–5 | Lean and forward-leaning |
| Heavy enemies | 4–4.5 | Wide torso, low center of mass |
| Bosses | Not head-based | About 2–2.5× hero height; several mechanical zones |

Every approved character gets its own proportion guide. Bodies are not forced to be identical.

**Each character needs:**
- one signature silhouette feature readable at 64 px tall;
- one signature color from its faction ramp;
- one signature motion idea, which goes into `ANIMATION_SPECIFICATION.md`.

## 2. Factions

| Faction | Materials | Accent color | Attitude |
|---|---|---|---|
| Wayfarer crew (friendly) | Painted steel, canvas, leather, brass, teal glass | Machine Teal | Resourceful, repaired and cared for |
| Wasteland raiders (enemy) | Rusted machinery, gunmetal, rubber, scrap plates | Enemy Crimson cloth and paint | Opportunistic, improvised, jagged |

Enemies are readable as threats from their silhouette and crimson accents together, never by color alone.

## 3. Rivet, the main hero (identity preserved)

**Identity:** an adult human mechanic-fighter with an athletic, practical build and a friendly, determined face.

**Signature silhouette:**
- goggles pushed up onto the forehead;
- an asymmetrical copper-and-teal workshop jacket, with one reinforced shoulder and sleeve;
- an oversized mechanical glove on the tool hand;
- a crescent wrench-hammer hybrid weapon;
- a canvas tool belt and heavy reinforced boots.

**Personality:** inventive, resourceful, energetic and approachable, able to fix a machine and to fight. Never a generic futuristic soldier.

**Gameplay links:**
- Rivet's attacks and the Wrench Quake special (GB-055) need readable anticipation and impact poses.
- The SP bar and the special use Special Violet only for the special itself.

**Master deliverables (ART-02).** These come before any skeletal part:
1. Full-body neutral pose, right-facing three-quarter.
2. **Turnaround:** front, right three-quarter, right side, back, and back three-quarter. All views share one height line, head line, belt line and knee line.
3. **Near/far limb sheet:** the near and far arm and leg drawn separately in the gameplay view, with visible surfaces, foreshortening, occlusion and shading for each (see `CHARACTER_RIGGING_GUIDE.md` §3).
4. Expression sheet: neutral, determined, effort, hurt, triumphant and surprised.
5. Proportion sheet with head-height measurements.
6. Color and material callouts using the IDs in `MATERIAL_LIBRARY.md`.
7. Weapon sheet: the wrench-hammer from three angles, with its socket and pivot.
8. Action-pose thumbnails: attack wind-up, impact, special, hit and victory.
9. Portrait and selection-screen illustration (P1).

The approved master is the authoritative reference for all later Rivet assets.

## 4. Vertical-slice roster

| Character | Runtime ID | Role and shape language | Signature | Priority |
|---|---|---|---|---|
| Rivet | Hero in `BattleSession` (provisional owner `hero.rivet`) | Hero; balanced angular and round | Goggles, mechanical glove, wrench-hammer | P0 |
| Rivetguard | Spawned by gear `unit.rivetguard` | Infantry; compact trapezoid | Round riveted helmet, shield-pack, teal lamp | P0 |
| Scrap Raider | `raider.basic` | Basic enemy; lean wedge | Scrap shoulder plate, crimson rag scarf | P0 |
| Rustrunner | `raider.runner` | Fast enemy; forward lean | Long legs, a single wheel or skate on the back | P0 |
| Slagback Bruiser | `raider.bruiser` | Heavy enemy; rectangle and triangle | Slag-plate back armor, oversized fists | P0 |
| Cinder Skirmisher | `raider.skirmisher` | Fast enemy | Ember-lit vents, short blade | P0 |
| Spoke Dasher | `raider.dasher` | Fast enemy, the fastest | Spoked wheel-boots, crouched sprint pose | P0 |
| Scrapmaw | `boss.scrapmaw` (route node named "Scrapjaw"; open naming issue ART-ID-01) | Copperwash boss | A jaw-like scoop arm; the 18-tick wind-up must read; cleave zone | P0 |
| Ironwood and Sunken archetypes | `ironwood.*`, `sunken.*` | — | — | P1, after the Copperwash benchmark |
| Future heroes (Torque, Volt, Ember, Patch, Scout) | None | — | — | P2, concepts only after the slice |

- **Never invent runtime IDs** that conflict with shared data.
- **No ranged friendly unit** exists in the data, so none is designed (ART-ID-03).

**Concept deliverables for every other character:**
- a neutral three-quarter pose and a turnaround: front, three-quarter and side at minimum, plus the back for bosses;
- a near/far limb sheet;
- a color and material callout;
- attack wind-up and impact thumbnails.

## 5. Readability at gameplay scale

On a 1080 px-wide portrait phone, a near-lane character is about 140–200 px tall; the far lane is about 84% of that. Validate against these numbers.

**At that size:**
- the silhouette, signature feature and faction accent must still read;
- faces may simplify to the eye and brow shapes;
- weapons stay readable, because they are oversized on purpose.

**Bosses:** the telegraph zone (where the hit comes from) is the brightest-contrast area during a wind-up.
