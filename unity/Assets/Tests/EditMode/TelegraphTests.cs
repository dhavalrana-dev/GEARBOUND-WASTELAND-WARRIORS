using System;
using System.IO;
using System.Linq;
using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    /// <summary>Mirrors flutter/test/combat/telegraph_test.dart.</summary>
    public sealed class TelegraphTests
    {
        private static Combatant Boss(int windup = 5, bool cleave = false) =>
            new Combatant(500, CombatFaction.Enemy, 1, 1000, 1000, 0, 10, 300, 0, 30, windupTicks: windup, cleave: cleave);

        private static Combatant Ally(int id, int lane = 1, int pos = 900) =>
            new Combatant(id, CombatFaction.Friendly, lane, pos, 100, 0, 1, 0, 0, 10);

        [Test]
        public void HitLandsWhenWindupEnds()
        {
            var sim = new CombatSimulation(worldLengthMm: 2000);
            sim.Add(Boss());
            sim.Add(Ally(10));
            var target = sim.Combatants.First(u => u.Id == 10);
            var attacker = sim.Combatants.First(u => u.Id == 500);
            sim.Tick();
            Assert.AreEqual(5, attacker.WindupRemaining);
            for (var i = 0; i < 4; i++) sim.Tick();
            Assert.AreEqual(100, target.Health);
            sim.Tick();
            Assert.AreEqual(90, target.Health);
        }

        [Test]
        public void LeavingTheLaneDodges()
        {
            var sim = new CombatSimulation(worldLengthMm: 2000);
            sim.Add(Boss());
            sim.Add(Ally(10));
            sim.Tick();
            sim.Tick();
            Assert.IsTrue(sim.MoveLane(10, 0));
            for (var i = 0; i < 6; i++) sim.Tick();
            Assert.AreEqual(100, sim.Combatants.First(u => u.Id == 10).Health);
        }

        [Test]
        public void CleaveHitsEveryoneInRangeInTheLaneOnly()
        {
            var sim = new CombatSimulation(worldLengthMm: 2000);
            sim.Add(Boss(cleave: true));
            sim.Add(Ally(10));
            sim.Add(Ally(11, pos: 750));
            sim.Add(Ally(12, lane: 0));
            sim.Add(Ally(13, pos: 600));
            for (var i = 0; i < 6; i++) sim.Tick();
            int Hp(int id) => sim.Combatants.First(u => u.Id == id).Health;
            CollectionAssert.AreEqual(new[] { 90, 90, 100, 100 }, new[] { Hp(10), Hp(11), Hp(12), Hp(13) });
        }

        [Test]
        public void WindupMustBeShorterThanInterval()
        {
            Assert.Throws<ArgumentOutOfRangeException>(() => Boss(windup: 30));
            Assert.Throws<ArgumentOutOfRangeException>(() => Boss(windup: -1));
        }

        [Test]
        public void ScrapmawLoadsTelegraphAndCleave()
        {
            var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
            while (dir != null && !Directory.Exists(Path.Combine(dir.FullName, "shared"))) dir = dir.Parent;
            Assert.IsNotNull(dir);
            var enemies = SharedDataLoader.LoadEnemies(File.ReadAllText(Path.Combine(dir.FullName, "shared", "enemies", "enemies.json")));
            var scrapmaw = enemies.First(e => e.Id == "boss.scrapmaw");
            Assert.AreEqual(18, scrapmaw.WindupTicks);
            Assert.IsTrue(scrapmaw.Cleave);
            Assert.IsTrue(enemies.Where(e => e.Id != "boss.scrapmaw").All(e => e.WindupTicks == 0 && !e.Cleave));
        }
    }
}
