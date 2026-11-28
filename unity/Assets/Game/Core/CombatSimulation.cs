using System;
using System.Collections.Generic;
using System.Linq;

namespace Gearbound.Core
{
    public enum CombatFaction { Friendly, Enemy }
    public enum CombatState { Idle, Moving, AcquiringTarget, Attacking, Recovering, Stunned, KnockedBack, Dying, Dead }

    public sealed class Combatant
    {
        public int Id { get; }
        public CombatFaction Faction { get; }
        public int Lane { get; internal set; }
        public int PositionMm { get; internal set; }
        public int Health { get; internal set; }
        public int MaxHealth { get; }
        public int Armor { get; }
        public int Damage { get; }
        public int DamageReductionPercent { get; }
        public int Shield { get; internal set; }
        public int AttackRangeMm { get; }
        public int MovementMmPerTick { get; }
        public int AttackIntervalTicks { get; }
        public int AttackCooldownTicks { get; internal set; }
        public int StunRemaining { get; internal set; }
        public CombatState State { get; internal set; }
        public bool IsAlive => Health > 0;

        /// <summary>Ticks between committing to an attack and the hit landing (0 = instant hit).</summary>
        public int WindupTicks { get; }
        /// <summary>When true, a wind-up hit lands on every opponent in range in the lane.</summary>
        public bool Cleave { get; }
        /// <summary>Ticks until a committed attack lands; the telegraph is visible while this is above 0.</summary>
        public int WindupRemaining { get; internal set; }

        public Combatant(int id, CombatFaction faction, int lane, int positionMm, int health, int armor, int damage,
            int attackRangeMm, int movementMmPerTick, int attackIntervalTicks, int shield = 0, int damageReductionPercent = 0,
            int windupTicks = 0, bool cleave = false)
        {
            if (windupTicks < 0 || (windupTicks > 0 && windupTicks >= attackIntervalTicks))
                throw new ArgumentOutOfRangeException(nameof(windupTicks), "Wind-up must be 0 or shorter than the attack interval.");
            WindupTicks = windupTicks;
            Cleave = cleave;
            if (id <= 0) throw new ArgumentOutOfRangeException(nameof(id));
            if (lane < 0 || lane > 2) throw new ArgumentOutOfRangeException(nameof(lane));
            if (health <= 0 || armor < 0 || damage <= 0 || attackRangeMm < 0 || movementMmPerTick < 0 || attackIntervalTicks < 1 || shield < 0)
                throw new ArgumentOutOfRangeException("Combat stats are outside their allowed range.");
            if (damageReductionPercent < 0 || damageReductionPercent > 80) throw new ArgumentOutOfRangeException(nameof(damageReductionPercent));
            Id = id;
            Faction = faction;
            Lane = lane;
            PositionMm = positionMm;
            Health = MaxHealth = health;
            Armor = armor;
            Damage = damage;
            AttackRangeMm = attackRangeMm;
            MovementMmPerTick = movementMmPerTick;
            AttackIntervalTicks = attackIntervalTicks;
            Shield = shield;
            DamageReductionPercent = damageReductionPercent;
            State = CombatState.Idle;
        }
    }

    /// <summary>A friendly projectile travelling down a lane from the fortress line.</summary>
    public sealed class Projectile
    {
        public int Id { get; }
        public int Lane { get; }
        public int PositionMm { get; internal set; }
        public int SpeedMmPerTick { get; }
        public int Damage { get; }

        internal Projectile(int id, int lane, int positionMm, int speedMmPerTick, int damage)
        {
            Id = id; Lane = lane; PositionMm = positionMm; SpeedMmPerTick = speedMmPerTick; Damage = damage;
        }
    }

    internal sealed class CombatDamageEvent
    {
        public int TargetId;
        public int AttackerId;
        public int Damage;
    }

    public sealed class CombatSimulation
    {
        private readonly List<Combatant> combatants = new List<Combatant>();
        private readonly HashSet<int> ids = new HashSet<int>();
        public IReadOnlyList<Combatant> Combatants => combatants;
        public int TickIndex { get; private set; }
        public int FortressHealth { get; private set; }
        public int FortressMaxHealth { get; }
        public int WorldLengthMm { get; }
        public bool IsDefeated => FortressHealth <= 0;

        public CombatSimulation(int fortressHealth = 100, int worldLengthMm = 20000)
        {
            if (fortressHealth <= 0 || worldLengthMm <= 0) throw new ArgumentOutOfRangeException("Battle dimensions and fortress health must be positive.");
            FortressHealth = FortressMaxHealth = fortressHealth;
            WorldLengthMm = worldLengthMm;
        }

        public bool Add(Combatant combatant)
        {
            if (combatant == null) throw new ArgumentNullException(nameof(combatant));
            if (!ids.Add(combatant.Id)) return false;
            combatants.Add(combatant);
            combatants.Sort((a, b) => a.Id.CompareTo(b.Id));
            return true;
        }

        /// <summary>Removes matching combatants without killing them; IDs stay reserved.</summary>
        public int Withdraw(Func<Combatant, bool> predicate)
        {
            if (predicate == null) throw new ArgumentNullException(nameof(predicate));
            return combatants.RemoveAll(unit => predicate(unit));
        }

        public bool MoveLane(int combatantId, int lane)
        {
            if (lane < 0 || lane > 2) return false;
            var combatant = combatants.FirstOrDefault(unit => unit.Id == combatantId);
            if (combatant == null || !combatant.IsAlive) return false;
            combatant.Lane = lane;
            return true;
        }

        private readonly List<(int attackerId, int targetId)> lastHits = new List<(int attackerId, int targetId)>();
        private readonly List<Projectile> projectiles = new List<Projectile>();
        private int nextProjectileId = 1;

        /// <summary>Hard cap on live projectiles; firing beyond it is refused.</summary>
        public int MaxActiveProjectiles { get; set; } = 24;
        public IReadOnlyList<Projectile> Projectiles => projectiles;

        /// <summary>
        /// Launches a friendly projectile. Each tick (in projectile ID order) it advances by its speed and hits the
        /// nearest living enemy in its lane between its old and new position; it is removed on a hit or at the end of
        /// the field. Projectile hits use attacker ID -projectileId, so they sort before unit hits and never collide with unit IDs.
        /// </summary>
        public bool FireProjectile(int lane, int startMm, int speedMmPerTick, int damage)
        {
            if (lane < 0 || lane > 2 || speedMmPerTick < 1 || damage < 1) throw new ArgumentOutOfRangeException("Invalid projectile.");
            if (projectiles.Count >= MaxActiveProjectiles) return false;
            projectiles.Add(new Projectile(nextProjectileId++, lane, startMm, speedMmPerTick, damage));
            return true;
        }

        /// <summary>Unit hits resolved during the most recent Tick, in resolution order (fortress hits excluded). Bookkeeping only.</summary>
        public IReadOnlyList<(int attackerId, int targetId)> LastHits => lastHits;

        /// <summary>
        /// Deals damage (armor, reduction and shields apply as for a normal hit) to every living combatant of
        /// <paramref name="faction"/> in <paramref name="lane"/> within <paramref name="radiusMm"/> of
        /// <paramref name="centerMm"/>, in entity ID order. Returns how many were hit.
        /// </summary>
        public int AreaDamage(CombatFaction faction, int lane, int centerMm, int radiusMm, int damage, int knockbackMm = 0, int stunTicks = 0)
        {
            if (knockbackMm < 0 || stunTicks < 0) throw new ArgumentOutOfRangeException("Control effects cannot be negative.");
            var targets = combatants.Where(u => u.IsAlive && u.Faction == faction && u.Lane == lane && Math.Abs(u.PositionMm - centerMm) <= radiusMm)
                .OrderBy(u => u.Id).ToArray();
            foreach (var target in targets)
            {
                ApplyDamage(target, damage);
                if (target.Health <= 0) target.State = CombatState.Dead;
                else ApplyControlEffect(target, centerMm, knockbackMm, stunTicks);
            }
            return targets.Length;
        }

        public void Tick()
        {
            if (IsDefeated) return;
            TickIndex++;
            lastHits.Clear();
            var living = combatants.Where(unit => unit.IsAlive).OrderBy(unit => unit.Id).ToArray();

            // Phase 1: advance cooldowns and movement in stable entity order.
            var startPositions = living.ToDictionary(unit => unit.Id, unit => unit.PositionMm);
            var nextPositions = new Dictionary<int, int>();
            foreach (var unit in living)
            {
                if (unit.StunRemaining > 0)
                {
                    unit.StunRemaining--;
                    nextPositions[unit.Id] = startPositions[unit.Id];
                    unit.State = CombatState.Stunned;
                    continue;
                }
                if (unit.AttackCooldownTicks > 0) unit.AttackCooldownTicks--;
                var hasNearbyTarget = living.Any(target => target.IsAlive && target.Faction != unit.Faction && target.Lane == unit.Lane
                    && Math.Abs(startPositions[target.Id] - startPositions[unit.Id]) <= unit.AttackRangeMm);
                var start = startPositions[unit.Id];
                var atFortress = unit.Faction == CombatFaction.Enemy && start <= 0;
                var atEnemyBoundary = unit.Faction == CombatFaction.Friendly && start >= WorldLengthMm;
                // A unit winding up an attack holds its position until the hit lands.
                if (!hasNearbyTarget && !atFortress && !atEnemyBoundary && unit.MovementMmPerTick > 0 && unit.WindupRemaining == 0)
                {
                    var step = unit.Faction == CombatFaction.Friendly ? unit.MovementMmPerTick : -unit.MovementMmPerTick;
                    nextPositions[unit.Id] = Math.Max(0, Math.Min(WorldLengthMm, start + step));
                    unit.State = CombatState.Moving;
                }
                else { nextPositions[unit.Id] = start; unit.State = CombatState.Idle; }
            }
            foreach (var unit in living) unit.PositionMm = nextPositions[unit.Id];

            // Phase 2: select targets and schedule hits after all movement is complete.
            var events = new List<CombatDamageEvent>();
            foreach (var shot in projectiles.OrderBy(p => p.Id).ToArray())
            {
                var from = shot.PositionMm;
                var to = Math.Min(WorldLengthMm, from + shot.SpeedMmPerTick);
                var hit = living.Where(u => u.IsAlive && u.Faction == CombatFaction.Enemy && u.Lane == shot.Lane
                        && u.PositionMm >= from && u.PositionMm <= to)
                    .OrderBy(u => u.PositionMm).ThenBy(u => u.Id).FirstOrDefault();
                if (hit != null)
                {
                    events.Add(new CombatDamageEvent { TargetId = hit.Id, AttackerId = -shot.Id, Damage = shot.Damage });
                    projectiles.Remove(shot);
                }
                else if (to >= WorldLengthMm) projectiles.Remove(shot);
                else shot.PositionMm = to;
            }
            foreach (var unit in living)
            {
                if (unit.StunRemaining > 0 || unit.State == CombatState.Stunned) continue;
                if (unit.WindupRemaining > 0)
                {
                    // Telegraphed attack: the hit lands when the wind-up ends, on whoever is in range then.
                    unit.WindupRemaining--;
                    unit.State = CombatState.Attacking;
                    if (unit.WindupRemaining == 0) ReleaseWindup(unit, living, events);
                    continue;
                }
                var target = FindTarget(unit, living);
                if (target != null)
                {
                    if (unit.AttackCooldownTicks == 0)
                    {
                        if (unit.WindupTicks > 0) unit.WindupRemaining = unit.WindupTicks;
                        else events.Add(new CombatDamageEvent { TargetId = target.Id, AttackerId = unit.Id, Damage = unit.Damage });
                        unit.AttackCooldownTicks = unit.AttackIntervalTicks;
                        unit.State = CombatState.Attacking;
                    }
                    else if (unit.State != CombatState.Moving) unit.State = CombatState.Recovering;
                }
                else if (unit.Faction == CombatFaction.Enemy && unit.PositionMm <= 0)
                {
                    if (unit.AttackCooldownTicks == 0)
                    {
                        if (unit.WindupTicks > 0) unit.WindupRemaining = unit.WindupTicks;
                        else events.Add(new CombatDamageEvent { TargetId = 0, AttackerId = unit.Id, Damage = unit.Damage });
                        unit.AttackCooldownTicks = unit.AttackIntervalTicks;
                        unit.State = CombatState.Attacking;
                    }
                    else unit.State = CombatState.Recovering;
                }
            }

            // Phase 3: simultaneous hits are resolved by target ID, then attacker ID.
            foreach (var hit in events.OrderBy(e => e.TargetId).ThenBy(e => e.AttackerId))
            {
                if (hit.TargetId == 0) FortressHealth = Math.Max(0, FortressHealth - hit.Damage);
                else
                {
                    var target = combatants.First(unit => unit.Id == hit.TargetId);
                    ApplyDamage(target, hit.Damage);
                    lastHits.Add((hit.AttackerId, hit.TargetId));
                }
            }
            foreach (var unit in combatants.Where(unit => unit.Health <= 0)) unit.State = CombatState.Dead;
        }

        /// <summary>
        /// Resolves a finished wind-up: cleave hits every opponent in range in the lane (ID order), otherwise the
        /// nearest one. With no opponent in range, an enemy at the fortress line hits the fortress; otherwise it misses.
        /// </summary>
        private static void ReleaseWindup(Combatant unit, Combatant[] living, List<CombatDamageEvent> events)
        {
            if (unit.Cleave)
            {
                var hit = false;
                foreach (var target in living.Where(t => t.IsAlive && t.Faction != unit.Faction && t.Lane == unit.Lane
                    && Math.Abs(t.PositionMm - unit.PositionMm) <= unit.AttackRangeMm).OrderBy(t => t.Id))
                {
                    events.Add(new CombatDamageEvent { TargetId = target.Id, AttackerId = unit.Id, Damage = unit.Damage });
                    hit = true;
                }
                if (hit) return;
            }
            else
            {
                var target = FindTarget(unit, living);
                if (target != null)
                {
                    events.Add(new CombatDamageEvent { TargetId = target.Id, AttackerId = unit.Id, Damage = unit.Damage });
                    return;
                }
            }
            if (unit.Faction == CombatFaction.Enemy && unit.PositionMm <= 0)
                events.Add(new CombatDamageEvent { TargetId = 0, AttackerId = unit.Id, Damage = unit.Damage });
        }

        private static Combatant FindTarget(Combatant attacker, IEnumerable<Combatant> candidates)
        {
            return candidates
                .Where(target => target.IsAlive && target.Faction != attacker.Faction && target.Lane == attacker.Lane)
                .Select(target => new { Target = target, Distance = Math.Abs(target.PositionMm - attacker.PositionMm) })
                .Where(item => item.Distance <= attacker.AttackRangeMm)
                .OrderBy(item => item.Distance)
                .ThenBy(item => item.Target.Id)
                .Select(item => item.Target)
                .FirstOrDefault();
        }

        private static void ApplyDamage(Combatant target, int rawDamage)
        {
            var afterArmor = Math.Max(0, rawDamage - target.Armor);
            var afterReduction = afterArmor * (100 - target.DamageReductionPercent) / 100;
            var remaining = Math.Max(1, afterReduction);
            var absorbed = Math.Min(target.Shield, remaining);
            target.Shield -= absorbed;
            target.Health = Math.Max(0, target.Health - (remaining - absorbed));
        }

        private void ApplyControlEffect(Combatant target, int centerMm, int knockbackMm, int stunTicks)
        {
            if (knockbackMm > 0)
            {
                var direction = target.PositionMm >= centerMm ? 1 : -1;
                target.PositionMm = Math.Max(0, Math.Min(WorldLengthMm, target.PositionMm + direction * knockbackMm));
                target.State = CombatState.KnockedBack;
            }
            if (stunTicks > target.StunRemaining) target.StunRemaining = stunTicks;
        }
    }
}
