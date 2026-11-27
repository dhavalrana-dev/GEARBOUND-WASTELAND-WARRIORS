using System;
using System.Collections.Generic;
using System.Linq;

namespace Gearbound.Core
{
    /// <summary>Intermission sits between waves: combat pauses, fortress damage carries over, the hero returns to the fortress line (keeping health and lane), and gear-produced soldiers withdraw.</summary>
    public enum BattlePhase { Preparation, Combat, Intermission, Victory, Defeat }

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
        private readonly IReadOnlyList<WaveDefinition> waves;
        private int nextSpawnIndex;
        private int waveStartTick;
        private int nextEnemyId = 1000;
        public GearBoard Board { get; }
        public GearNetworkResult Network { get; private set; }
        public CombatSimulation Combat { get; }
        public GearOutputSystem Outputs { get; }
        public BattlePhase Phase { get; private set; } = BattlePhase.Preparation;
        public int ElapsedTicks { get; private set; }
        public int HeroId { get; }
        /// <summary>Total wave rewards earned so far this mission.</summary>
        public int ScrapReward { get; private set; }
        public int LastWaveReward { get; private set; }
        public int WaveIndex { get; private set; }
        public IReadOnlyList<WaveDefinition> Waves => waves;
        public WaveDefinition CurrentWave => waves[WaveIndex];
        public bool IsFinalWave => WaveIndex == waves.Count - 1;

        public BattleSession(GearBoard board, GearNetworkResult network, WaveDefinition wave, int heroId = 1,
            CombatSimulation combat = null, GearOutputSystem outputs = null, IEnumerable<WaveDefinition> laterWaves = null)
        {
            Board = board ?? throw new ArgumentNullException(nameof(board));
            Network = network ?? throw new ArgumentNullException(nameof(network));
            if (wave == null) throw new ArgumentNullException(nameof(wave));
            var all = new List<WaveDefinition> { wave };
            if (laterWaves != null) all.AddRange(laterWaves.Select(w => w ?? throw new ArgumentNullException(nameof(laterWaves))));
            waves = all;
            HeroId = heroId;
            Combat = combat ?? new CombatSimulation();
            Outputs = outputs ?? new GearOutputSystem();
            if (!Combat.Combatants.Any(unit => unit.Id == HeroId))
                Combat.Add(new Combatant(HeroId, CombatFaction.Friendly, 1, 0, 100, 2, 12, 900, 35, 18));
        }

        public void RefreshNetwork() => Network = GearNetwork.Rebuild(Board);

        public bool MoveHeroToLane(int lane) => Combat.MoveLane(HeroId, lane);

        /// <summary>Starts the first wave from preparation, or the next wave from an intermission.</summary>
        public bool Start()
        {
            if (Phase == BattlePhase.Intermission)
            {
                WaveIndex++;
                nextSpawnIndex = 0;
                waveStartTick = ElapsedTicks;
            }
            else if (Phase != BattlePhase.Preparation) return false;
            Phase = BattlePhase.Combat;
            return true;
        }

        public void Tick()
        {
            if (Phase != BattlePhase.Combat) return;
            var wave = CurrentWave;
            while (nextSpawnIndex < wave.Spawns.Count && wave.Spawns[nextSpawnIndex].Tick <= ElapsedTicks - waveStartTick)
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
                LastWaveReward = wave.RewardScrap;
                ScrapReward += wave.RewardScrap;
                if (IsFinalWave) Phase = BattlePhase.Victory;
                else
                {
                    Phase = BattlePhase.Intermission;
                    Combat.Withdraw(unit => unit.Faction == CombatFaction.Friendly && unit.Id != HeroId);
                    // The hero returns to the fortress line, keeping health and lane.
                    var hero = Combat.Combatants.FirstOrDefault(unit => unit.Id == HeroId);
                    if (hero != null) hero.PositionMm = 0;
                }
            }
        }
    }
}
