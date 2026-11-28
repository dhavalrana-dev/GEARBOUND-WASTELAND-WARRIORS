# Character rigging guide

**Version:** 1.0 (2026-11-28). It replaces art direction v2 §10–12. **Status:** proposed; no rig exists.
**Order:** an approved master turnaround (ART-02), then individual parts, then the skeleton. Parts are never drawn before the turnaround is approved.
**Related:** `CHARACTER_DESIGN.md`, `ANIMATION_SPECIFICATION.md`, `RENDERING_ARCHITECTURE.md`, `ASSET_VALIDATION_GUIDE.md`.

## 1. Source master

- **Canvas:** 2048 × 2048, transparent, sRGB.
- **Origin:** the ground-contact point, between the feet at rest, recorded in metadata.
- **Height:** consistent per character.
- **Layers:** editable, named with the part IDs below.

Use a larger canvas only with a documented reason. Runtime sizes are chosen by in-engine tests.

## 2. Parts

| Group | Parts |
|---|---|
| Head | Head base, hair front, hair back, eyebrows, eyes, mouth and expression variants, goggles, neck |
| Body | Upper torso, lower torso and pelvis |
| Arms | **Near** and **far** upper arm, forearm and hand (hand poses: open, grip, fist) |
| Legs | **Near** and **far** thigh, shin and foot |
| Equipment | Jacket accessories, shoulder armor, mechanical glove, tool belt, weapon, back equipment |

**Rules for every part:**
- Hidden overlap continues under sleeves, armor, knees and elbows, so that no gap appears at an extreme pose.
- Every joint end is a clean rounded cap that rotates without exposing the cut.
- Outlines are drawn on the outer silhouette only, never across a joint seam.

## 3. Near and far limbs

Characters face right in a three-quarter view:
- **Near** is closest to the viewer.
- **Far** is partly behind the torso.

These are depth labels. Anatomical left and right are recorded separately in the rig metadata.

**Each far limb is its own drawing:**
- **Visible surfaces:** the far arm shows more of its inner side and less of its outer side.
- **Perspective:** the far limb is slightly shorter in projection and narrower.
- **Shading:** the far limb sits in more shadow, about one cel step darker on average, with a cooler hue.
- **Occlusion:** the torso overlaps the far shoulder and hip; the far hand may hide behind the weapon.
- **Scale:** the far limb is 92–97% of the near limb, set at ART-02 per character.

**Never duplicate or mirror a near limb as the far limb.** The only exception is an asymmetric part whose far view is truly identical, and that must be justified and approved on the limb sheet. Flipping a character never swaps near and far; an asymmetrical character needs approved facing variants or attachment rules.

## 4. Skeleton

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

**Sockets:**
- weapon, muzzle, projectile origin;
- hit effect, status effect;
- ground shadow, head indicator (HP and state);
- backpack, mechanical attachment.

**Hitboxes and hurtboxes** come from the logical simulation, never from rendered pixels or bones.

## 5. Default draw order (back to front)

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

Animations may override the order for a key range, for example a weapon crossing the torso. Overrides are keyed in the animation data, never by hand-editing sprites.

## 6. Rig metadata (`shared/art/character_rigs.json`, planned)

The metadata is shared by both engines and written to a schema in `shared/schemas/` when the first rig exists. Per character it records:

| Field | Content |
|---|---|
| `characterId` | Runtime ID (`hero.rivet`, `raider.basic`), or a provisional owner where no data ID exists |
| `masterCanvas`, `groundOrigin`, `pixelsPerUnit` | Coordinate system |
| `bones[]` | `id`, `parent`, local position, rotation and scale at rest, rotation limits, `depth` (near or far), `anatomicalSide` |
| `parts[]` | `assetId` (manifest), `bone`, pivot, trim offset, `drawOrder` |
| `sockets[]` | `id`, `bone`, local offset |
| `attachmentRules` | Weapon and hand-pose swaps, facing variants |
| `meshWeights` | Only if a deforming mesh is adopted (Unity 2D Animation); otherwise rigid parts |

Rigid parts are the default. Mesh deformation is used only where it adds clear value (cloth or a belly) and only if Flutter can reproduce it (`RENDERING_ARCHITECTURE.md` §4).

## 7. Exports

1. **Registered parts:** each part at its exact position on the master canvas, for assembly and validation.
2. **Trimmed runtime sprites:** with recorded trim offsets, dimensions and pivots, then packed into atlases (`VISUAL_PERFORMANCE_BUDGET.md`).

Full master canvases are never runtime textures.

## 8. Validation (ART-03)

**Extreme-pose test:** arms raised and fully extended, a deep crouch, a full attack swing, lying knocked down, and the special pose.

**It fails on any of:**
- a visible gap or cut at a joint;
- wrong layering, or a far limb that reads as a near limb;
- a detached weapon, or a pivot that drifts;
- a silhouette that changes identity.

The rest is in `ASSET_VALIDATION_GUIDE.md` §4.
