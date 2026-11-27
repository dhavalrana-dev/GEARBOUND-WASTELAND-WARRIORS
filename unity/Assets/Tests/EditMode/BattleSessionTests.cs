using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    public sealed class BattleSessionTests
    {
        [Test]
        public void SessionSpawnsOnScheduleAndCompletesAfterLastEnemyDies()
        {
            var board = new GearBoard();
            var network = GearNetwork.Rebuild(board);
            var combat = new CombatSimulation(worldLengthMm: 1000);
            combat.Add(new Combatant(1, CombatFaction.Friendly, 1, 0, 100, 0, 50, 1000, 0, 1));
            var wave = new WaveDefinition("test.wave", new[] { new WaveSpawnEvent(0, 1, 10, 0, 1, 0, 0, 1) }, rewardScrap: 4);
            var session = new BattleSession(board, network, wave, combat: combat);
            Assert.That(session.Start(), Is.True);
            session.Tick();
            Assert.That(session.Phase, Is.EqualTo(BattlePhase.Victory));
            Assert.That(session.ScrapReward, Is.EqualTo(4));
            Assert.That(session.ElapsedTicks, Is.EqualTo(1));
        }

        [Test]
        public void FutureScheduledEnemyPreventsEarlyVictory()
        {
            var board = new GearBoard();
            var combat = new CombatSimulation(worldLengthMm: 1000);
            combat.Add(new Combatant(1, CombatFaction.Friendly, 1, 0, 100, 0, 50, 1000, 0, 1));
            var wave = new WaveDefinition("test.wave", new[] { new WaveSpawnEvent(2, 1, 10, 0, 1, 0, 0, 1) });
            var session = new BattleSession(board, GearNetwork.Rebuild(board), wave, combat: combat);
            session.Start();
            session.Tick();
            Assert.That(session.Phase, Is.EqualTo(BattlePhase.Combat));
            session.Tick();
            Assert.That(session.Phase, Is.EqualTo(BattlePhase.Combat));
            session.Tick();
            Assert.That(session.Phase, Is.EqualTo(BattlePhase.Victory));
        }

        [Test]
        public void FortressDefeatOverridesWaveCompletion()
        {
            var board = new GearBoard();
            var combat = new CombatSimulation(fortressHealth: 5);
            var wave = new WaveDefinition("test.wave", new[] { new WaveSpawnEvent(0, 0, 10, 0, 5, 0, 20000, 1) });
            var session = new BattleSession(board, GearNetwork.Rebuild(board), wave, combat: combat);
            session.Start();
            session.Tick();
            Assert.That(session.Phase, Is.EqualTo(BattlePhase.Defeat));
        }
    }
}
