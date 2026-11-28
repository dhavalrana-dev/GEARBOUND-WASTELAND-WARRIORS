using System.IO;
using System.Linq;
using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    /// <summary>GB-024: every campaign route node loads from shared mission data and resolves its enemies in C#.</summary>
    public sealed class RouteMissionTests
    {
        private static string SharedRoot()
        {
            var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
            while (dir != null && !Directory.Exists(Path.Combine(dir.FullName, "shared"))) dir = dir.Parent;
            Assert.IsNotNull(dir);
            return Path.Combine(dir.FullName, "shared");
        }

        [Test]
        public void EveryRouteNodeBuildsItsWaves()
        {
            var root = SharedRoot();
            var enemies = SharedDataLoader.LoadEnemies(File.ReadAllText(Path.Combine(root, "enemies", "enemies.json")));
            var route = SharedJson.Obj(SharedJson.Parse(File.ReadAllText(Path.Combine(root, "missions", "campaign_route.json"))), "route");
            var nodes = SharedJson.Arr(route, "nodes");
            Assert.AreEqual(12, nodes.Count);
            foreach (var item in nodes)
            {
                var node = SharedJson.Obj(item, "node");
                var mission = SharedDataLoader.LoadMission(File.ReadAllText(Path.Combine(root, SharedJson.Str(node, "mission"))));
                foreach (var waveId in SharedJson.Arr(node, "waveIds").Cast<string>())
                {
                    var wave = mission.Waves.Single(w => w.Id == waveId);
                    var built = WaveDirector.Build(wave, enemies);
                    Assert.Greater(built.Spawns.Count, 0, SharedJson.Str(node, "id") + " " + waveId);
                }
            }
        }

        [Test]
        public void LateNodeArchetypesMatchTheirOldScriptedStats()
        {
            var enemies = SharedDataLoader.LoadEnemies(File.ReadAllText(Path.Combine(SharedRoot(), "enemies", "enemies.json")));
            var warden = enemies.First(e => e.Id == "ironwood.warden");
            CollectionAssert.AreEqual(new[] { 68, 1, 9, 340, 78, 30 },
                new[] { warden.Health, warden.Armor, warden.Damage, warden.AttackRangeMm, warden.MovementMmPerTick, warden.AttackIntervalTicks });
            var tide = enemies.First(e => e.Id == "sunken.tidebreaker");
            CollectionAssert.AreEqual(new[] { 76, 2, 9, 360, 82, 30 },
                new[] { tide.Health, tide.Armor, tide.Damage, tide.AttackRangeMm, tide.MovementMmPerTick, tide.AttackIntervalTicks });
        }
    }
}
