# Animation specification

**Version:** 1.0 (2026-11-28). It replaces art direction v2 §13 and §19, and adds gear, environment and UI motion. **Status:** proposed; no animation exists.
**Related:** `CHARACTER_RIGGING_GUIDE.md`, `RENDERING_ARCHITECTURE.md`, `VISUAL_PERFORMANCE_BUDGET.md`, `docs/COMBAT_ENGINE.md`, `docs/MECHANICAL_ENGINE.md`.

## 1. The rule that overrides everything

**The simulation is authoritative.** Gameplay runs at a fixed 30 Hz in both engines:
- An animation never deals damage, moves a unit or decides an outcome.
- Animations **follow** simulation state and events, and they are interpolated for display between ticks.

**Example:** the hero's attack interval of 18 ticks is 0.6 s, so an attack animation must fit or loop within 0.6 s. Scrapmaw's wind-up of 18 ticks is the time from the telegraph appearing to the hit.

## 2. Binding animations to the simulation

| Simulation signal | Visual response |
|---|---|
| Unit spawned | Deploy animation from the fortress hatch or gear output |
| State `moving`, `attacking` or `dead` | Locomotion, attack loop, or death |
| Attack committed (wind-up starts) | The anticipation pose starts **on that tick**, and the lane warning zone appears |
| Hit lands (damage event) | Impact frame, hit flash and hit reaction on the target |
| Hero lane command | Lane transition, 0.25–0.45 s, while logical movement follows the simulation |
| Hero special used | Wrench Quake animation; the impact frame is aligned to the tick of the damage event |
| Projectile spawned or hit | Muzzle flash, projectile sprite and impact effect |
| Wave cleared, victory, defeat | Celebration, defeat and result transitions |

- **Events are the source.** Each engine exposes the simulation events (damage, spawn, wind-up start, special) to its renderer. A renderer may not reconstruct events by diffing pixels or guessing.
- **Interpolation:** positions blend between the previous and current tick. Event-triggered animations start on the tick of their event; they are never pre-empted early.

## 3. Character animation set

| Animation | Visual duration | Loop | P0 for |
|---|---|---|---|
| Idle | 1.5–2.5 s | Yes | All |
| Walk | 0.7–1.0 s | Yes | All |
| Run | 0.5–0.8 s | Yes | Fast enemies (P0), Rivet (P1) |
| Lane transition | 0.25–0.45 s | No | Rivet |
| Light attack 1 / 2 | 0.3–0.5 / 0.35–0.55 s | No | All (2 is P1) |
| Heavy attack | 0.6–0.9 s | No | P1 (no mechanic yet, ART-ID-05) |
| Dash | 0.2–0.4 s | No | P1 |
| Hit reaction | 0.15–0.3 s | No | All |
| Knockback | 0.3–0.5 s | No | P1 (Phase 03.7) |
| Special ability | 0.6–1.2 s | No | Rivet (Wrench Quake) |
| Boss wind-up | Exactly the simulation wind-up (18 ticks = 0.6 s) | No | Scrapmaw |
| Death | 0.6–1.2 s | No | All |
| Victory | 1.5–2.5 s | Optional | Rivet |

These are visual timings. If a timing conflicts with the simulation, the simulation wins and the animation is retimed.

**Quality bar:**
- Feet stay grounded, with no sliding locomotion; stride length is matched to movement speed in mm per tick, after projection.
- Weapons follow their socket, and limbs never detach.
- Use anticipation, contact and recovery on every attack, and no tweens that kill the impact.
- The identity holds in every frame. Breathing and accessory motion stay subtle.
- Every major enemy attack has a readable anticipation pose. For telegraphed attacks it lasts the full wind-up.

## 4. Formats

- **Authoring:** a skeletal 2D rig, with rigid parts by default (`CHARACTER_RIGGING_GUIDE.md`).
- **Shared animation metadata** (`shared/art/animation_catalog.json`, planned): for each clip, its ID, character, duration, loop flag, and frame events (`impact`, `footstep`, `muzzle`, `windup_start`), each with the simulation event it aligns to.
- **Runtime:** Unity and Flutter may use different runtimes (`RENDERING_ARCHITECTURE.md` §4), but they play the same clips with the same events and timing.

## 5. Gear and machine motion

**Gear motion reflects `GearNetwork` exactly:**

| Network state | Motion |
|---|---|
| Powered | The wheel rotates. The direction comes from `rotationParity` (it alternates across each mesh edge, so meshed gears turn opposite ways); the hub energy pulses |
| Unpowered | Still, with no power glow |
| Jammed (odd loop) | Teeth strain: a 2–3° shudder every 0.5 s, a warning icon, no rotation |
| Conflicted (several cores) | Stutter and stop, a warning icon and a conflict marker on each core involved |
| Producing | The progress ring fills on the output clock; the output pulse fires on the spawn or shot tick |
| Output blocked (cap reached) | The ring holds full and a "blocked" icon blinks slowly (off in reduced motion) |

- **Speed:** angular speed is visual, the same for every powered gear (a proposed 90°/s), with a short ease when a gear powers up or down.
- **Meshing:** meshed gears are drawn with matching tooth phase, so the teeth interlock visually. Phase is computed from board position, never stored state.
- **Fortress motion:** treads idle, power indicators pulse with the core, and damage overlays are added at the health thresholds.

**Placement and merge:**

| Event | Duration |
|---|---|
| Gear snap into a slot | 100–180 ms |
| Merge | 250–450 ms |
| Connection made or broken | 120–200 ms |
| Invalid drop (shake back) | 150–250 ms |

## 6. Environment and UI motion

**Environment ambient motion:** dust, cable sway, slowly turning distant machinery, and heat shimmer on far layers. It is subtle and low-frequency. It never moves the gameplay ground, never competes with actors, and pauses or reduces under reduced motion.

**UI motion:**
- Button press: 60–100 ms down, 120 ms release.
- Panel in and out: 180–250 ms.
- Reward chest:
  - anticipation shake: 250 ms;
  - burst: 300–700 ms;
  - item fly-in: 200–400 ms per item;
  - the sequence can be skipped after the first reveal.
- Event banner shine: one sweep in 600 ms, at most once every 4 s.

## 7. VFX timings

| Effect | Duration |
|---|---|
| Hit flash | 60–120 ms |
| Critical impact (when crits exist) | 120–220 ms |
| Unit deploy | 200–350 ms |
| Projectile impact | 120–200 ms |
| Shield hit | 100–180 ms |
| Enemy defeat | 300–600 ms |
| Boss warning (lane zone) | The full wind-up, matching the simulation |
| Reward reveal | 300–700 ms |

Effects are pooled with configurable particle limits (`VISUAL_PERFORMANCE_BUDGET.md`). Effects never hide an attack telegraph, a projectile or a lane boundary.

## 8. Reduced motion

A setting, also on when the operating system asks for reduced motion:
- removes screen shake and flashes;
- shortens pulses, and stops ambient environment motion;
- skips reward bursts and shows the result directly.

Gear rotation stays, because it carries information, but at 50% speed with no shudder; the warning icons remain. Gameplay timing is unchanged.
