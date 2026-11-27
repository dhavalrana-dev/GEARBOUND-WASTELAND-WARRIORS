using System.Linq;
using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    /// <summary>Same cases as flutter/test/combat/multi_wave_test.dart.</summary>
    public sealed class MultiWaveTests
    {
        private static WaveSpawnEvent Weak(int tick) => new WaveSpawnEvent(tick, 1, 10, 0, 1, 0, 0, 1);

        private static BattleSession Session(params WaveDefinition[] waves)
        {
            var combat = new CombatSimulation(worldLengthMm: 1000);
            combat.Add(new Combatant(1, CombatFaction.Friendly, 1, 0, 100, 0, 50, 1000, 0, 1));
            var board = new GearBoard();
            return new BattleSession(board, GearNetwork.Rebuild(board), waves[0], combat: combat, laterWaves: waves.Skip(1));
        }

        private static void RunUntilPaused(BattleSession s)
        {
            for (var i = 0; i < 1000 && s.Phase == BattlePhase.Combat; i++) s.Tick();
        }

        private static readonly WaveDefinition W1 = new WaveDefinition("w1", new[] { Weak(2) }, 3);
        private static readonly WaveDefinition W2 = new WaveDefinition("w2", new[] { Weak(5), Weak(9) }, 4);
        private static readonly WaveDefinition W3 = new WaveDefinition("w3", new[] { Weak(1) }, 6);

        [Test]
        public void NonFinalWaveEntersIntermissionWithReward()
        {
            var s = Session(W1, W2, W3);
            Assert.IsTrue(s.Start());
            RunUntilPaused(s);
            Assert.AreEqual(BattlePhase.Intermission, s.Phase);
            Assert.AreEqual(0, s.WaveIndex);
            Assert.AreEqual(3, s.LastWaveReward);
        }

        [Test]
        public void IntermissionDoesNotTickAndStartAdvances()
        {
            var s = Session(W1, W2, W3);
            s.Start();
            RunUntilPaused(s);
            var ticks = s.ElapsedTicks;
            s.Tick();
            Assert.AreEqual(ticks, s.ElapsedTicks);
            Assert.IsTrue(s.Start());
            Assert.AreEqual("w2", s.CurrentWave.Id);
        }

        [Test]
        public void FinalWaveEndsInVictoryWithTotalReward()
        {
            var s = Session(W1, W2, W3);
            s.Start();
            for (var wave = 0; wave < 3; wave++)
            {
                RunUntilPaused(s);
                if (s.Phase == BattlePhase.Intermission) s.Start();
            }
            Assert.AreEqual(BattlePhase.Victory, s.Phase);
            Assert.AreEqual(13, s.ScrapReward);
            Assert.IsFalse(s.Start());
        }

        [Test]
        public void IntermissionWithdrawsSoldiersAndReturnsHero()
        {
            var s = Session(W1, W2);
            var hero = s.Combat.Combatants.First(u => u.Id == 1);
            s.Combat.Add(new Combatant(100000, CombatFaction.Friendly, 0, 300, 30, 0, 5, 250, 0, 24));
            s.Start();
            for (var i = 0; i < 3; i++) s.Tick();
            RunUntilPaused(s);
            Assert.AreEqual(BattlePhase.Intermission, s.Phase);
            Assert.IsFalse(s.Combat.Combatants.Any(u => u.Id == 100000));
            Assert.IsTrue(s.Combat.Combatants.Contains(hero));
            Assert.AreEqual(0, hero.PositionMm);
        }

        [Test]
        public void SingleWaveSessionStillEndsInVictory()
        {
            var s = Session(W1);
            s.Start();
            RunUntilPaused(s);
            Assert.AreEqual(BattlePhase.Victory, s.Phase);
            Assert.AreEqual(3, s.ScrapReward);
        }
    }
}
