using System.IO;
using System.Linq;
using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    /// <summary>Mirrors flutter/test/combat/hero_special_test.dart.</summary>
    public sealed class HeroSpecialTests
    {
        private static WaveSpawnEvent Enemy(int tick, int health = 200, int lane = 1) =>
            new WaveSpawnEvent(tick, lane, health, 0, 1, 0, 0, 30);

        private static BattleSession Session(params WaveSpawnEvent[] spawns)
        {
            var board = new GearBoard();
            return new BattleSession(board, GearNetwork.Rebuild(board), new WaveDefinition("w", spawns),
                combat: new CombatSimulation(worldLengthMm: 1000));
        }

        [Test]
        public void RivetSpecialAndStatsMatchSharedHeroes()
        {
            var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
            while (dir != null && !Directory.Exists(Path.Combine(dir.FullName, "shared"))) dir = dir.Parent;
            Assert.IsNotNull(dir);
            var root = SharedJson.Obj(SharedJson.Parse(File.ReadAllText(Path.Combine(dir.FullName, "shared", "heroes", "heroes.json"))), "heroes");
            var rivet = SharedJson.Obj(SharedJson.Arr(root, "heroes")[0], "rivet");
            var sp = SharedJson.Obj(rivet["special"], "special");
            Assert.AreEqual(SharedJson.Str(sp, "id"), HeroSpecial.Rivet.Id);
            Assert.AreEqual(SharedJson.Int(sp, "spMax"), HeroSpecial.Rivet.SpMax);
            Assert.AreEqual(SharedJson.Int(sp, "spPerHit"), HeroSpecial.Rivet.SpPerHit);
            Assert.AreEqual(SharedJson.Int(sp, "damage"), HeroSpecial.Rivet.Damage);
            Assert.AreEqual(SharedJson.Int(sp, "radiusMm"), HeroSpecial.Rivet.RadiusMm);

            var hero = Session(Enemy(0)).Combat.Combatants.First(u => u.Id == 1);
            Assert.AreEqual(SharedJson.Int(rivet, "health"), hero.MaxHealth);
            Assert.AreEqual(SharedJson.Int(rivet, "armor"), hero.Armor);
            Assert.AreEqual(SharedJson.Int(rivet, "damage"), hero.Damage);
            Assert.AreEqual(SharedJson.Int(rivet, "attackRangeMm"), hero.AttackRangeMm);
            Assert.AreEqual(SharedJson.Int(rivet, "movementMmPerTick"), hero.MovementMmPerTick);
            Assert.AreEqual(SharedJson.Int(rivet, "attackIntervalTicks"), hero.AttackIntervalTicks);
        }

        [Test]
        public void SpFillsFromHitsAndCaps()
        {
            var s = Session(Enemy(0, 100000));
            s.Start();
            for (var i = 0; i < 2000; i++) s.Tick();
            Assert.AreEqual(HeroSpecial.Rivet.SpMax, s.HeroSp);
        }

        [Test]
        public void SpecialRefusedUntilFullAndOutsideCombat()
        {
            var s = Session(Enemy(0, 100000));
            Assert.IsFalse(s.UseHeroSpecial());
            s.Start();
            s.Tick();
            Assert.IsFalse(s.UseHeroSpecial());
        }

        [Test]
        public void SpecialHitsOnlyTheHeroLaneOnce()
        {
            var s = Session(Enemy(0), Enemy(0, lane: 0));
            s.Start();
            while (s.HeroSp < HeroSpecial.Rivet.SpMax) s.Tick();
            var hero = s.Combat.Combatants.First(u => u.Id == 1);
            var near = s.Combat.Combatants.First(u => u.Faction == CombatFaction.Enemy && u.Lane == hero.Lane);
            var other = s.Combat.Combatants.First(u => u.Faction == CombatFaction.Enemy && u.Lane != hero.Lane);
            var nearBefore = near.Health;
            var otherBefore = other.Health;
            Assert.IsTrue(s.UseHeroSpecial());
            Assert.IsFalse(s.UseHeroSpecial());
            s.Tick();
            Assert.Less(s.HeroSp, HeroSpecial.Rivet.SpMax);
            Assert.GreaterOrEqual(nearBefore - near.Health, 25);
            Assert.AreEqual(otherBefore, other.Health);
        }
    }
}
