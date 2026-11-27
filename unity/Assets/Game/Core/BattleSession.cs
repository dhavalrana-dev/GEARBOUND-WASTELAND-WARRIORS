using System;
using System.Collections.Generic;
using System.Linq;

namespace Gearbound.Core
{
    public enum BattlePhase { Preparation, Combat, Victory, Defeat }

    public sealed class WaveSpawnEvent
    {
        public int Tick { get; }
        public int Lane { get; }
        public int Health { get; }
        public int Armor { get; }
        public int Damage { get; }
        public int AttackRangeMm { get; }
        public int MovementMmPerTick { get; }
        public int AttackIntervalTicks { get; }

        public WaveSpawnEvent(int tick, int lane, int health, int armor, int damage, int attackRangeMm, int movementMmPerTick, int attackIntervalTicks)
        {
            if (tick < 0 || lane < 0 || lane > 2 || health <= 0 || armor < 0 || damage <= 0 || attackRangeMm < 0 || movementMmPerTick < 0 || attackIntervalTicks < 1)
                throw new ArgumentOutOfRangeException("Wave spawn data is outside its allowed range.");
            Tick = tick;
            Lane = lane;
            Health = health;
            Armor = armor;
            Damage = damage;
            AttackRangeMm = attackRangeMm;
            MovementMmPerTick = movementMmPerTick;
            AttackIntervalTicks = attackIntervalTicks;
        }
    }

    public sealed class WaveDefinition
    {
        public string Id { get; }
        public IReadOnlyList<WaveSpawnEvent> Spawns { get; }
        public int RewardScrap { get; }

        public WaveDefinition(string id, IEnumerable<WaveSpawnEvent> spawns, int rewardScrap = 0)
        {
            if (string.IsNullOrWhiteSpace(id)) throw new ArgumentException("Wave ID is required.", nameof(id));
            if (rewardScrap < 0) throw new ArgumentOutOfRangeException(nameof(rewardScrap));
            Id = id;
            Spawns = spawns?.OrderBy(spawn => spawn.Tick).ThenBy(spawn => spawn.Lane).ToArray() ?? throw new ArgumentNullException(nameof(spawns));
            RewardScrap = rewardScrap;
        }
    }

    public sealed class BattleSession
    {
        private readonly WaveDefinition wave;
        private int nextSpawnIndex;
        private int nextEnemyId = 1000;
        public GearBoard Board { get; }
        public GearNetworkResult Network { get; private set; }
        public CombatSimulation Combat { get; }
        public GearOutputSystem Outputs { get; }
        public BattlePhase Phase { get; private set; } = BattlePhase.Preparation;
        public int ElapsedTicks { get; private set; }
        public int HeroId { get; }
        public int ScrapReward { get; private set; }

        public BattleSession(GearBoard board, GearNetworkResult network, WaveDefinition wave, int heroId = 1,
            CombatSimulation combat = null, GearOutputSystem outputs = null)
        {
            Board = board ?? throw new ArgumentNullException(nameof(board));
            Network = network ?? throw new ArgumentNullException(nameof(network));
            this.wave = wave ?? throw new ArgumentNullException(nameof(wave));
            HeroId = heroId;
            Combat = combat ?? new CombatSimulation();
            Outputs = outputs ?? new GearOutputSystem();
            if (!Combat.Combatants.Any(unit => unit.Id == HeroId))
                Combat.Add(new Combatant(HeroId, CombatFaction.Friendly, 1, 0, 100, 2, 12, 900, 35, 18));
        }

        public void RefreshNetwork() => Network = GearNetwork.Rebuild(Board);

        public bool MoveHeroToLane(int lane) => Combat.MoveLane(HeroId, lane);

        public bool Start()
        {
            if (Phase != BattlePhase.Preparation) return false;
            Phase = BattlePhase.Combat;
            return true;
        }

        public void Tick()
        {
            if (Phase != BattlePhase.Combat) return;
            while (nextSpawnIndex < wave.Spawns.Count && wave.Spawns[nextSpawnIndex].Tick <= ElapsedTicks)
            {
                var spawn = wave.Spawns[nextSpawnIndex++];
                Combat.Add(new Combatant(nextEnemyId++, CombatFaction.Enemy, spawn.Lane, Combat.WorldLengthMm,
                    spawn.Health, spawn.Armor, spawn.Damage, spawn.AttackRangeMm, spawn.MovementMmPerTick, spawn.AttackIntervalTicks));
            }

            Combat.Tick();
            Outputs.Tick(Board, Network, Combat);
            ElapsedTicks++;

            if (Combat.IsDefeated) Phase = BattlePhase.Defeat;
            else if (nextSpawnIndex >= wave.Spawns.Count && !Combat.Combatants.Any(unit => unit.IsAlive && unit.Faction == CombatFaction.Enemy))
            {
                Phase = BattlePhase.Victory;
                ScrapReward = wave.RewardScrap;
            }
        }
    }
}
