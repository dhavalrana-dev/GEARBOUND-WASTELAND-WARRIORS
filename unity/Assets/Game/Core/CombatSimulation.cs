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
        public CombatState State { get; internal set; }
        public bool IsAlive => Health > 0;

        public Combatant(int id, CombatFaction faction, int lane, int positionMm, int health, int armor, int damage,
            int attackRangeMm, int movementMmPerTick, int attackIntervalTicks, int shield = 0, int damageReductionPercent = 0)
        {
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

        public void Tick()
        {
            if (IsDefeated) return;
            TickIndex++;
            var living = combatants.Where(unit => unit.IsAlive).OrderBy(unit => unit.Id).ToArray();

            // Phase 1: advance cooldowns and movement in stable entity order.
            var startPositions = living.ToDictionary(unit => unit.Id, unit => unit.PositionMm);
            var nextPositions = new Dictionary<int, int>();
            foreach (var unit in living)
            {
                if (unit.AttackCooldownTicks > 0) unit.AttackCooldownTicks--;
                var hasNearbyTarget = living.Any(target => target.IsAlive && target.Faction != unit.Faction && target.Lane == unit.Lane
                    && Math.Abs(startPositions[target.Id] - startPositions[unit.Id]) <= unit.AttackRangeMm);
                var start = startPositions[unit.Id];
                var atFortress = unit.Faction == CombatFaction.Enemy && start <= 0;
                var atEnemyBoundary = unit.Faction == CombatFaction.Friendly && start >= WorldLengthMm;
                if (!hasNearbyTarget && !atFortress && !atEnemyBoundary && unit.MovementMmPerTick > 0)
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
            foreach (var unit in living)
            {
                var target = FindTarget(unit, living);
                if (target != null)
                {
                    if (unit.AttackCooldownTicks == 0)
                    {
                        events.Add(new CombatDamageEvent { TargetId = target.Id, AttackerId = unit.Id, Damage = unit.Damage });
                        unit.AttackCooldownTicks = unit.AttackIntervalTicks;
                        unit.State = CombatState.Attacking;
                    }
                    else if (unit.State != CombatState.Moving) unit.State = CombatState.Recovering;
                }
                else if (unit.Faction == CombatFaction.Enemy && unit.PositionMm <= 0)
                {
                    if (unit.AttackCooldownTicks == 0)
                    {
                        events.Add(new CombatDamageEvent { TargetId = 0, AttackerId = unit.Id, Damage = unit.Damage });
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
                }
            }
            foreach (var unit in combatants.Where(unit => unit.Health <= 0)) unit.State = CombatState.Dead;
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
    }
}
