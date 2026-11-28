using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Gearbound.Core
{
    public sealed class CombatScenarioResult
    {
        public string Id { get; set; }
        public string Phase { get; set; }
        public int ElapsedTicks { get; set; }
        public int FortressHealth { get; set; }
        public int FriendlyUnitsProduced { get; set; }
        public int FriendlyAlive { get; set; }
        public int EnemiesAlive { get; set; }
        public uint TraceHash { get; set; }
        public IReadOnlyList<uint> Checkpoints { get; set; }
    }

    /// <summary>
    /// Runs a shared combat scenario and fingerprints it. Each tick appends
    /// "tick|phase|fortress|" then "id:lane:pos:hp:shield:state;" for every combatant in ID order,
    /// with lowercase state names, and folds the ASCII bytes into a 32-bit FNV-1a hash. Hero commands
    /// for tick t apply before simulating tick t. Dart's runner must produce identical hashes.
    /// </summary>
    public static class CombatScenarioRunner
    {
        private static readonly Direction[] AllPorts = { Direction.North, Direction.East, Direction.South, Direction.West };
        private const uint FnvOffset = 2166136261u;
        private const uint FnvPrime = 16777619u;

        public static IReadOnlyList<CombatScenarioResult> RunAll(string scenariosJson, string missionJson, string enemiesJson)
        {
            var root = SharedJson.Obj(SharedJson.Parse(scenariosJson), "scenarios");
            var mission = SharedDataLoader.LoadMission(missionJson);
            var enemies = SharedDataLoader.LoadEnemies(enemiesJson);
            var every = SharedJson.Int(root, "checkpointEveryTicks");
            return SharedJson.Arr(root, "scenarios").Select(s => Run(SharedJson.Obj(s, "scenario"), mission, enemies, every)).ToArray();
        }

        private static CombatScenarioResult Run(Dictionary<string, object> s, MissionDefinition mission, IReadOnlyList<EnemyDefinition> enemies, int every)
        {
            var waveId = SharedJson.Str(s, "waveId");
            var wave = mission.Waves.FirstOrDefault(w => w.Id == waveId) ?? throw new KeyNotFoundException(waveId);
            var board = new GearBoard();
            foreach (var item in SharedJson.Arr(s, "gears"))
            {
                var g = SharedJson.Obj(item, "gear");
                var kind = SharedJson.Str(g, "kind");
                var gearKind = kind == "core" ? GearKind.Core : kind == "transmission" ? GearKind.Transmission : kind == "booster" ? GearKind.Booster : GearKind.Output;
                var outputKind = kind == "infantry" ? GearOutputKind.SpawnInfantry : kind == "turret" ? GearOutputKind.FireProjectile : GearOutputKind.None;
                var projectileDamage = g.ContainsKey("projectileDamage") ? SharedJson.Int(g, "projectileDamage") : 0;
                var projectileSpeed = g.ContainsKey("projectileSpeedMmPerTick") ? SharedJson.Int(g, "projectileSpeedMmPerTick") : 0;
                var interval = g.ContainsKey("intervalTicks") ? SharedJson.Int(g, "intervalTicks") : 0;
                var lane = g.ContainsKey("targetLane") ? SharedJson.Int(g, "targetLane") : 1;
                var node = new GearNode(SharedJson.Str(g, "id"), gearKind, SharedJson.Int(g, "x"), SharedJson.Int(g, "y"), AllPorts, interval,
                    outputKind: outputKind, targetLane: lane, projectileDamage: projectileDamage, projectileSpeedMmPerTick: projectileSpeed);
                if (!board.TryPlace(node, out var error)) throw new InvalidOperationException(error);
            }
            var commands = SharedJson.Arr(s, "heroCommands").Select(c => SharedJson.Obj(c, "command"))
                .Select(c => (tick: SharedJson.Int(c, "tick"), lane: SharedJson.Int(c, "lane"))).ToArray();

            // Optional: the hero recovers after a knockout (scenarios recorded before recovery leave it off).
            var heroRecovers = SharedJson.Bool(s, "heroRecovers");
            var session = new BattleSession(board, GearNetwork.Rebuild(board), WaveDirector.Build(wave, enemies),
                combat: new CombatSimulation(worldLengthMm: SharedJson.Int(s, "worldLengthMm")), heroRecovers: heroRecovers);
            // Optional: the hero starts the wave hurt, as after a checkpoint that carried its health.
            if (s.ContainsKey("heroStartHealth"))
                session.Combat.Combatants.First(u => u.Id == session.HeroId).Health = SharedJson.Int(s, "heroStartHealth");
            session.Start();
            var maxTicks = SharedJson.Int(s, "maxTicks");
            // Optional: the hero uses the special as soon as it is ready (checked before each tick).
            var autoSpecial = SharedJson.Bool(s, "heroUsesSpecialWhenReady");
            var hash = FnvOffset;
            var checkpoints = new List<uint>();
            var line = new StringBuilder();
            while (session.Phase == BattlePhase.Combat && session.ElapsedTicks < maxTicks)
            {
                foreach (var command in commands) if (command.tick == session.ElapsedTicks) session.MoveHeroToLane(command.lane);
                if (autoSpecial) session.UseHeroSpecial();
                session.Tick();
                line.Clear();
                line.Append(session.ElapsedTicks).Append('|').Append(session.Phase.ToString().ToLowerInvariant()).Append('|').Append(session.Combat.FortressHealth).Append('|');
                foreach (var u in session.Combat.Combatants)
                    line.Append(u.Id).Append(':').Append(u.Lane).Append(':').Append(u.PositionMm).Append(':').Append(u.Health).Append(':')
                        .Append(u.Shield).Append(':').Append(u.State.ToString().ToLowerInvariant()).Append(';');
                if (autoSpecial) line.Append("sp:").Append(session.HeroSp);
                if (heroRecovers) line.Append("rc:").Append(session.HeroRecoveryRemaining).Append(';');
                // Projectiles join the hash only when present, so older scenarios keep their hashes.
                foreach (var p in session.Combat.Projectiles) line.Append('P').Append(p.Id).Append(':').Append(p.Lane).Append(':').Append(p.PositionMm).Append(';');
                for (var i = 0; i < line.Length; i++) { hash ^= line[i]; hash *= FnvPrime; }
                if (session.ElapsedTicks % every == 0) checkpoints.Add(hash);
            }

            var units = session.Combat.Combatants;
            return new CombatScenarioResult
            {
                Id = SharedJson.Str(s, "id"),
                Phase = session.Phase.ToString().ToLowerInvariant(),
                ElapsedTicks = session.ElapsedTicks,
                FortressHealth = session.Combat.FortressHealth,
                FriendlyUnitsProduced = units.Count(u => u.Faction == CombatFaction.Friendly && u.Id >= 100000),
                FriendlyAlive = units.Count(u => u.IsAlive && u.Faction == CombatFaction.Friendly),
                EnemiesAlive = units.Count(u => u.IsAlive && u.Faction == CombatFaction.Enemy),
                TraceHash = hash,
                Checkpoints = checkpoints,
            };
        }

        public static string ToJson(IReadOnlyList<CombatScenarioResult> results)
        {
            var b = new StringBuilder();
            b.Append("{\n  \"schemaVersion\": 1,\n  \"generator\": \"tools/simulation/CombatTraceGenerator.cs\",\n  \"hash\": \"fnv1a32\",\n  \"results\": [\n");
            for (var i = 0; i < results.Count; i++)
            {
                var r = results[i];
                b.Append("    { \"id\": \"").Append(r.Id).Append("\", \"phase\": \"").Append(r.Phase)
                 .Append("\", \"elapsedTicks\": ").Append(r.ElapsedTicks)
                 .Append(", \"fortressHealth\": ").Append(r.FortressHealth)
                 .Append(", \"friendlyUnitsProduced\": ").Append(r.FriendlyUnitsProduced)
                 .Append(", \"friendlyAlive\": ").Append(r.FriendlyAlive)
                 .Append(", \"enemiesAlive\": ").Append(r.EnemiesAlive)
                 .Append(", \"traceHash\": ").Append(r.TraceHash)
                 .Append(",\n      \"checkpoints\": [").Append(string.Join(", ", r.Checkpoints)).Append("] }")
                 .Append(i + 1 < results.Count ? ",\n" : "\n");
            }
            b.Append("  ]\n}\n");
            return b.ToString();
        }
    }
}
