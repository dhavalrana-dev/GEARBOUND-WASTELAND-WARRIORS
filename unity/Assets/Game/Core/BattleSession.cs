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
        public int WindupTicks { get; }
        public bool Cleave { get; }

        public WaveSpawnEvent(int tick, int lane, int health, int armor, int damage, int attackRangeMm, int movementMmPerTick, int attackIntervalTicks,
            int windupTicks = 0, bool cleave = false)
        {
            WindupTicks = windupTicks;
            Cleave = cleave;
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

    /// <summary>A hero's special ability, from shared/heroes/heroes.json.</summary>
    public sealed class HeroSpecial
    {
        public string Id { get; }
        public int SpMax { get; }
        public int SpPerHit { get; }
        public int Damage { get; }
        public int RadiusMm { get; }

        public HeroSpecial(string id, int spMax, int spPerHit, int damage, int radiusMm)
        {
            if (spMax < 1 || spPerHit < 1 || damage < 1 || radiusMm < 0) throw new ArgumentOutOfRangeException("Hero special values are outside their allowed range.");
            Id = id; SpMax = spMax; SpPerHit = spPerHit; Damage = damage; RadiusMm = radiusMm;
        }

        /// <summary>Rivet's Wrench Quake; a test keeps this equal to heroes.json.</summary>
        public static readonly HeroSpecial Rivet = new HeroSpecial("special.wrench_quake", 100, 10, 25, 1200);
    }

    /// <summary>How a knocked-out hero comes back, from shared/heroes/heroes.json (<c>recovery</c>).</summary>
    public sealed class HeroRecovery
    {
        /// <summary>Combat ticks the hero stays out after a knockout.</summary>
        public int Ticks { get; }
        /// <summary>Share of maximum health the hero returns with (at least 1).</summary>
        public int HealthPercent { get; }

        public HeroRecovery(int ticks, int healthPercent)
        {
            if (ticks < 1 || healthPercent < 1 || healthPercent > 100) throw new ArgumentOutOfRangeException("Hero recovery values are outside their allowed range.");
            Ticks = ticks; HealthPercent = healthPercent;
        }

        /// <summary>Rivet's recovery; a test keeps this equal to heroes.json.</summary>
        public static readonly HeroRecovery Rivet = new HeroRecovery(300, 50);

        public int HealthFor(int maxHealth) => Math.Max(1, maxHealth * HealthPercent / 100);
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
        public HeroSpecial Special { get; }
        /// <summary>Null means a knocked-out hero stays out for the rest of the wave (the original traces' behavior).</summary>
        public HeroRecovery Recovery { get; }
        /// <summary>Combat ticks until a knocked-out hero returns; 0 while the hero is up.</summary>
        public int HeroRecoveryRemaining { get; private set; }

        /// <summary>Special points: gained when the hero's attacks land, spent in full by UseHeroSpecial. Carries across waves.</summary>
        public int HeroSp { get; private set; }
        private bool specialQueued;

        public bool SpecialReady => Phase == BattlePhase.Combat && !specialQueued && HeroSp >= Special.SpMax
            && Combat.Combatants.Any(u => u.Id == HeroId && u.IsAlive);

        /// <summary>
        /// Validated hero command: accepted only in combat with a full SP bar and a living hero. Applies at the start of
        /// the next Tick, after spawns and before combat, so both engines resolve it identically.
        /// </summary>
        public bool UseHeroSpecial()
        {
            if (!SpecialReady) return false;
            specialQueued = true;
            return true;
        }
        /// <summary>Total wave rewards earned so far this mission.</summary>
        public int ScrapReward { get; private set; }
        public int LastWaveReward { get; private set; }
        public int WaveIndex { get; private set; }
        public IReadOnlyList<WaveDefinition> Waves => waves;
        public WaveDefinition CurrentWave => waves[WaveIndex];
        public bool IsFinalWave => WaveIndex == waves.Count - 1;

        public BattleSession(GearBoard board, GearNetworkResult network, WaveDefinition wave, int heroId = 1,
            CombatSimulation combat = null, GearOutputSystem outputs = null, IEnumerable<WaveDefinition> laterWaves = null,
            HeroSpecial special = null, bool heroRecovers = true, HeroRecovery recovery = null)
        {
            Special = special ?? HeroSpecial.Rivet;
            Recovery = heroRecovers ? recovery ?? HeroRecovery.Rivet : null;
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
                    spawn.Health, spawn.Armor, spawn.Damage, spawn.AttackRangeMm, spawn.MovementMmPerTick, spawn.AttackIntervalTicks,
                    windupTicks: spawn.WindupTicks, cleave: spawn.Cleave));
            }

            // Recovery comes after spawns and before the special and combat, in both engines.
            if (HeroRecoveryRemaining > 0)
            {
                HeroRecoveryRemaining--;
                if (HeroRecoveryRemaining == 0) ReviveHero();
            }

            if (specialQueued)
            {
                specialQueued = false;
                var hero = Combat.Combatants.FirstOrDefault(u => u.Id == HeroId && u.IsAlive);
                if (hero != null)
                {
                    Combat.AreaDamage(CombatFaction.Enemy, hero.Lane, hero.PositionMm, Special.RadiusMm, Special.Damage);
                    HeroSp = 0;
                }
            }

            Combat.Tick();
            foreach (var hit in Combat.LastHits)
                if (hit.attackerId == HeroId) HeroSp = Math.Min(Special.SpMax, HeroSp + Special.SpPerHit);
            if (Recovery != null && HeroRecoveryRemaining == 0 && Combat.Combatants.Any(u => u.Id == HeroId && !u.IsAlive))
                HeroRecoveryRemaining = Recovery.Ticks;
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
                    // A hero who is down recovers now rather than missing the next wave.
                    if (HeroRecoveryRemaining > 0) ReviveHero();
                }
            }
        }

        private void ReviveHero()
        {
            HeroRecoveryRemaining = 0;
            foreach (var hero in Combat.Combatants)
            {
                if (hero.Id != HeroId || hero.IsAlive) continue;
                hero.Health = Recovery.HealthFor(hero.MaxHealth);
                hero.PositionMm = 0;
                hero.AttackCooldownTicks = 0;
                hero.WindupRemaining = 0;
                hero.State = CombatState.Idle;
            }
        }
    }
}
