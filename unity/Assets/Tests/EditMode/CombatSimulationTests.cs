using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    public sealed class CombatSimulationTests
    {
        [Test]
        public void UnitsMoveTowardOpponentsAndCannotTargetOtherLanes()
        {
            var simulation = new CombatSimulation(worldLengthMm: 1000);
            var friendly = new Combatant(1, CombatFaction.Friendly, 0, 0, 20, 0, 5, 20, 100, 10);
            var enemy = new Combatant(2, CombatFaction.Enemy, 1, 1000, 20, 0, 5, 20, 100, 10);
            simulation.Add(friendly);
            simulation.Add(enemy);
            simulation.Tick();
            Assert.That(friendly.PositionMm, Is.EqualTo(100));
            Assert.That(enemy.PositionMm, Is.EqualTo(900));
            Assert.That(friendly.Health, Is.EqualTo(20));
            Assert.That(enemy.Health, Is.EqualTo(20));
        }

        [Test]
        public void DamageAppliesArmorThenReductionThenShield()
        {
            var simulation = new CombatSimulation();
            var attacker = new Combatant(1, CombatFaction.Friendly, 1, 1000, 100, 0, 11, 100, 0, 10);
            var defender = new Combatant(2, CombatFaction.Enemy, 1, 1050, 20, 2, 1, 0, 0, 10, shield: 2, damageReductionPercent: 25);
            simulation.Add(attacker);
            simulation.Add(defender);
            simulation.Tick();
            Assert.That(defender.Shield, Is.Zero);
            Assert.That(defender.Health, Is.EqualTo(16));
        }

        [Test]
        public void SimultaneousHitsResolveBeforeDeathRemoval()
        {
            var simulation = new CombatSimulation();
            var friendly = new Combatant(1, CombatFaction.Friendly, 0, 1000, 5, 0, 5, 0, 0, 1);
            var enemy = new Combatant(2, CombatFaction.Enemy, 0, 1000, 5, 0, 5, 0, 0, 1);
            simulation.Add(friendly);
            simulation.Add(enemy);
            simulation.Tick();
            Assert.That(friendly.State, Is.EqualTo(CombatState.Dead));
            Assert.That(enemy.State, Is.EqualTo(CombatState.Dead));
        }

        [Test]
        public void EnemyAtFortressDamagesItAndDefeatStopsFurtherTicks()
        {
            var simulation = new CombatSimulation(fortressHealth: 10);
            simulation.Add(new Combatant(1, CombatFaction.Enemy, 2, 0, 20, 0, 10, 0, 0, 1));
            simulation.Tick();
            Assert.That(simulation.FortressHealth, Is.Zero);
            Assert.That(simulation.IsDefeated, Is.True);
            simulation.Tick();
            Assert.That(simulation.TickIndex, Is.EqualTo(1));
        }
    }
}
