using System.IO;
using System.Linq;
using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    /// <summary>Mirrors flutter/test/combat/hero_recovery_test.dart.</summary>
    public sealed class HeroRecoveryTests
    {
        private static WaveSpawnEvent Brute(int tick) => new WaveSpawnEvent(tick, 1, 500, 0, 200, 950, 0, 30);

        private static BattleSession Session(bool recovers = true, params WaveDefinition[] later)
        {
            var board = new GearBoard();
            return new BattleSession(board, GearNetwork.Rebuild(board), new WaveDefinition("w1", new[] { Brute(0) }),
                combat: new CombatSimulation(worldLengthMm: 1000), laterWaves: later, heroRecovers: recovers);
        }

        private static Combatant Hero(BattleSession s) => s.Combat.Combatants.First(u => u.Id == s.HeroId);

        private static int KnockOut(BattleSession s)
        {
            while (Hero(s).IsAlive)
            {
                s.Tick();
                if (s.ElapsedTicks > 300) Assert.Fail("hero was never knocked out");
            }
            return s.ElapsedTicks;
        }

        [Test]
        public void RivetRecoveryMatchesSharedHeroes()
        {
            var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
            while (dir != null && !Directory.Exists(Path.Combine(dir.FullName, "shared"))) dir = dir.Parent;
            Assert.IsNotNull(dir);
            var root = SharedJson.Obj(SharedJson.Parse(File.ReadAllText(Path.Combine(dir.FullName, "shared", "heroes", "heroes.json"))), "heroes");
            var recovery = SharedJson.Obj(SharedJson.Obj(SharedJson.Arr(root, "heroes")[0], "rivet")["recovery"], "recovery");
            Assert.AreEqual(SharedJson.Int(recovery, "ticks"), HeroRecovery.Rivet.Ticks);
            Assert.AreEqual(SharedJson.Int(recovery, "healthPercent"), HeroRecovery.Rivet.HealthPercent);
        }

        [Test]
        public void KnockedOutHeroReturnsAfterExactlyTheRecoveryTicks()
        {
            var s = Session();
            s.Start();
            var down = KnockOut(s);
            Assert.AreEqual(HeroRecovery.Rivet.Ticks, s.HeroRecoveryRemaining);
            Assert.IsFalse(s.SpecialReady);
            while (!Hero(s).IsAlive)
            {
                s.Tick();
                if (s.ElapsedTicks > down + 400) Assert.Fail("hero never recovered");
            }
            Assert.AreEqual(HeroRecovery.Rivet.Ticks, s.ElapsedTicks - down);
            Assert.AreEqual(50, Hero(s).Health);
            Assert.AreEqual(1, Hero(s).Lane);
            Assert.AreEqual(0, Hero(s).WindupRemaining);
            Assert.AreEqual(0, s.HeroRecoveryRemaining);
        }

        [Test]
        public void WithoutRecoveryTheHeroStaysOut()
        {
            var s = Session(false);
            s.Start();
            KnockOut(s);
            for (var i = 0; i < 400; i++) s.Tick();
            Assert.IsFalse(Hero(s).IsAlive);
            Assert.AreEqual(0, s.HeroRecoveryRemaining);
        }

        [Test]
        public void HeroDownAtWaveEndRecoversForTheNextWave()
        {
            var s = Session(true, new WaveDefinition("w2", new[] { Brute(0) }));
            s.Start();
            KnockOut(s);
            s.Combat.AreaDamage(CombatFaction.Enemy, 1, 1000, 5000, 10000);
            s.Tick();
            Assert.AreEqual(BattlePhase.Intermission, s.Phase);
            Assert.AreEqual(50, Hero(s).Health);
            Assert.AreEqual(0, Hero(s).PositionMm);
            Assert.AreEqual(0, s.HeroRecoveryRemaining);
        }
    }
}
