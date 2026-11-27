using System.IO;
using System.Linq;
using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    /// <summary>Mirrors flutter/test/combat/projectile_test.dart.</summary>
    public sealed class ProjectileTests
    {
        private static readonly Direction[] All = { Direction.North, Direction.East, Direction.South, Direction.West };

        private static Combatant Enemy(int id, int lane = 1, int pos = 900, int armor = 0) =>
            new Combatant(id, CombatFaction.Enemy, lane, pos, 50, armor, 1, 0, 0, 30);

        [Test]
        public void ProjectileHitsNearestEnemyInLane()
        {
            var sim = new CombatSimulation(worldLengthMm: 2000);
            sim.Add(Enemy(10, pos: 900, armor: 2));
            sim.Add(Enemy(11, pos: 1200));
            Assert.IsTrue(sim.FireProjectile(1, 0, 300, 8));
            sim.Tick();
            sim.Tick();
            Assert.AreEqual(600, sim.Projectiles.Single().PositionMm);
            sim.Tick();
            Assert.AreEqual(44, sim.Combatants.First(u => u.Id == 10).Health);
            Assert.AreEqual(50, sim.Combatants.First(u => u.Id == 11).Health);
            Assert.IsEmpty(sim.Projectiles);
        }

        [Test]
        public void ProjectileIgnoresOtherLanesAndLeavesField()
        {
            var sim = new CombatSimulation(worldLengthMm: 1000);
            sim.Add(Enemy(10, lane: 0, pos: 500));
            sim.FireProjectile(1, 0, 400, 8);
            for (var i = 0; i < 3; i++) sim.Tick();
            Assert.AreEqual(50, sim.Combatants.Single().Health);
            Assert.IsEmpty(sim.Projectiles);
        }

        [Test]
        public void CapRefusesExtraShots()
        {
            var sim = new CombatSimulation { MaxActiveProjectiles = 2 };
            CollectionAssert.AreEqual(new[] { true, true, false },
                new[] { sim.FireProjectile(0, 0, 1, 1), sim.FireProjectile(0, 0, 1, 1), sim.FireProjectile(0, 0, 1, 1) });
        }

        private static GearBoard TurretBoard(bool powered)
        {
            var board = new GearBoard();
            board.TryPlace(new GearNode("core", GearKind.Core, 0, 2, All), out _);
            board.TryPlace(new GearNode("turret", GearKind.Output, powered ? 1 : 4, powered ? 2 : 4, All, 10,
                outputKind: GearOutputKind.FireProjectile, targetLane: 2, projectileDamage: 8, projectileSpeedMmPerTick: 300), out _);
            return board;
        }

        [Test]
        public void PoweredTurretFiresEachCycle()
        {
            var board = TurretBoard(true);
            var net = GearNetwork.Rebuild(board);
            var sim = new CombatSimulation();
            var outputs = new GearOutputSystem();
            for (var i = 0; i < 10; i++) outputs.Tick(board, net, sim);
            Assert.AreEqual(1, sim.Projectiles.Count);
            Assert.AreEqual(2, sim.Projectiles[0].Lane);
        }

        [Test]
        public void UnpoweredTurretNeverFiresAndCappedTurretHolds()
        {
            var idle = TurretBoard(false);
            var sim = new CombatSimulation();
            var outputs = new GearOutputSystem();
            for (var i = 0; i < 40; i++) outputs.Tick(idle, GearNetwork.Rebuild(idle), sim);
            Assert.IsEmpty(sim.Projectiles);

            var board = TurretBoard(true);
            var capped = new CombatSimulation { MaxActiveProjectiles = 1 };
            var out2 = new GearOutputSystem();
            var net = GearNetwork.Rebuild(board);
            for (var i = 0; i < 30; i++) out2.Tick(board, net, capped);
            Assert.AreEqual(1, capped.Projectiles.Count);
            Assert.AreEqual(GearOutputStatus.UnitCapacityReached, out2.Clocks.Values.Single().Status);
        }

        [Test]
        public void SparkTurretLoadsProjectileAndMergeKeepsIt()
        {
            var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
            while (dir != null && !Directory.Exists(Path.Combine(dir.FullName, "shared"))) dir = dir.Parent;
            Assert.IsNotNull(dir);
            var catalog = SharedDataLoader.LoadGears(File.ReadAllText(Path.Combine(dir.FullName, "shared", "gears", "starter_gears.json")));
            var spark = catalog.First(g => g.Id == "turret.spark");
            Assert.AreEqual(8, spark.ProjectileDamage);
            Assert.AreEqual(300, spark.ProjectileSpeedMmPerTick);
            Assert.AreEqual(GearOutputKind.FireProjectile, spark.OutputKind);

            var board = new GearBoard();
            board.TryPlace(new GearNode("a", GearKind.Output, 0, 0, All, 45, definitionId: "turret.spark",
                outputKind: GearOutputKind.FireProjectile, projectileDamage: 8, projectileSpeedMmPerTick: 300), out _);
            board.TryPlace(new GearNode("b", GearKind.Output, 0, 1, All, 45, definitionId: "turret.spark",
                outputKind: GearOutputKind.FireProjectile, projectileDamage: 8, projectileSpeedMmPerTick: 300), out _);
            Assert.IsTrue(board.TryMerge(0, 0, 0, 1, 3, 32, out var merged, out _));
            Assert.AreEqual(8, merged.ProjectileDamage);
            Assert.AreEqual(300, merged.ProjectileSpeedMmPerTick);
        }
    }
}
