# Combat engine (implemented rules)

Updated 2026-11-27. Implemented identically in `unity/Assets/Game/Core/CombatSimulation.cs` + `BattleSession.cs` and `flutter/lib/combat/`. Proven by the cross-engine combat traces in `shared/test-fixtures/combat_traces.json` (8 scenarios). Updated 2026-11-28 for hero recovery.

## Space and time
- **Space:** lanes 0–2 and integer millimeters. Friendlies start at 0 (the fortress line) and enemies at the world length, approaching from the right.
- **Time:** 30 fixed ticks per second. Each entity has a stable ID; ties are always broken by ID.
- **States:** `Idle`, `Moving`, `Attacking`, `Recovering` and `Dead` are in use. `AcquiringTarget`, `Stunned`, `KnockedBack` and `Dying` are reserved for future mechanics.

## Tick order
1. **Movement.** A unit moves only when no opponent is within its range in its lane, it is not at the fortress or enemy boundary, and **it isn't winding up an attack**.
2. **Attacks**, in ID order:
   - A unit **winding up** counts down. When the wind-up reaches 0, the attack resolves (below).
   - Otherwise, with an opponent in range and the cooldown at 0, the unit attacks. With `windupTicks = 0` the hit is scheduled immediately. With `windupTicks > 0` the unit **commits**: the wind-up starts, the cooldown resets, and the hit lands `windupTicks` ticks later.
   - An enemy at the fortress line with no unit to hit attacks the fortress the same way.
3. **Damage**, ordered by target ID then attacker ID. Deaths are applied after all hits.

## Wind-up and cleave (telegraphs)
- **Releasing a wind-up:** a **cleave** attacker hits *every* opponent within range in its lane at the moment of release, in ID order. A non-cleave attacker hits the nearest one. If nobody is in range, an enemy at the fortress line hits the fortress; otherwise **the attack misses**.
- **Counter-play:** leaving the lane (or the range) during the wind-up dodges the hit.
- **Telegraph:** the Flame view draws a warning zone covering the attacker's reach while `windupRemaining > 0`. It grows more opaque as the hit approaches, is outlined, and carries a "!" (not color alone).
- **Data:** optional `windupTicks` and `cleave` in `shared/enemies/enemies.json`. `windupTicks` must be shorter than `attackIntervalTicks`. Only **Scrapmaw** uses them today (18-tick wind-up, cleave).

## Damage formula
`max(1, floor((rawDamage - armor) × (100 - reductionPct) / 100))`, where `reductionPct` is limited to 0–80. A shield absorbs damage before health.

## Hero
- **Lane commands:** move between lanes.
- **Special:** SP charge and the Wrench Quake special (`shared/heroes/heroes.json`; see the hero special in `DEVELOPMENT_STATUS.md`).
- **Knockout and recovery:** when the hero is knocked out, a timer starts at `recovery.ticks` (`shared/heroes/heroes.json`: 300 ticks, 10 s).
  - **Order within a tick:** the timer counts down **after spawns and before the special and combat**. When it reaches 0, the hero returns at the fortress line (x = 0) in the same lane, with `healthPercent` of maximum health (50%, at least 1), a ready attack and no wind-up. So the hero is out for exactly `ticks` ticks.
  - **SP** is kept, but the special cannot be used while the hero is down.
  - **Between waves:** a hero who is down when a wave ends recovers at once, at the intermission.
  - **Checkpoints:** a checkpoint restored with the hero at 0 health restarts the timer.
  - **Traces:** sessions created with no recovery (`recovery: null`, C# `heroRecovers: false`) keep the old rule, staying out for the wave. The seven older trace scenarios run that way, so their hashes are unchanged.
  - **Balance note (2026-11-28):** with current content the hero is never knocked out. A probe of every route mission's waves with the hero alone in a lane found no knockout, because the hero's 900 mm range outreaches every enemy. Recovery is a safety net until content puts real pressure on the hero.

## Outputs and waves
- **Unit cap:** gear outputs spawn soldiers up to **4 friendlies per lane**. A blocked output holds one pending spawn.
- **Waves:** multi-wave missions pause between waves (see `FLUTTER_ARCHITECTURE.md`). The mission is lost when the fortress reaches 0, and won when every scheduled enemy of the final wave is defeated.

## Projectiles (turrets)
- **Firing:** a powered turret gear (`FireProjectile` output) fires one projectile per output cycle from the fortress line (x = 0) in its lane, with `damage` and `speedMmPerTick` from the gear's `projectile` block in `starter_gears.json` (Spark Turret: 8 damage, 300 mm/tick).
- **Cap:** at most `output.maxActiveProjectiles` (24) are alive. A capped turret holds its shot with status `UnitCapacityReached`, like a capped infantry output.
- **Resolution:** at the start of the attack phase, in projectile ID order, each shot covers `[from, min(world, from + speed)]`. It hits the nearest living enemy in its lane inside that span (lowest position, then ID) through the normal damage formula, with attacker ID `-projectileId`, and disappears. A shot that reaches the end of the field without a hit is removed.
- **Other lanes and friendlies** are never hit. Projectiles do not charge hero SP.
- **Hash:** traces append `P{id}:{lane}:{pos};` per live projectile.

## Not implemented yet
- Critical hits and other random combat rolls (they must use the shared `SeededRandom`, in a documented order, with new trace scenarios).
- Status effects, knockback and stun. Arcing or splash projectiles (mortars).
- Ranged enemy behavior beyond attack range.
