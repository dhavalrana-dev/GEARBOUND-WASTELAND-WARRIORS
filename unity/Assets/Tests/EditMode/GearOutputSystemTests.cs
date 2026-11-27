using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    public sealed class GearOutputSystemTests
    {
        private static readonly Direction[] Ports = { Direction.North, Direction.East, Direction.South, Direction.West };

        private static GearBoard ConnectedInfantryBoard(int interval)
        {
            var board = new GearBoard();
            board.TryPlace(new GearNode("core", GearKind.Core, 0, 0, Ports), out _);
            board.TryPlace(new GearNode("drive", GearKind.Transmission, 1, 0, Ports), out _);
            board.TryPlace(new GearNode("press", GearKind.Output, 2, 0, Ports, interval, outputKind: GearOutputKind.SpawnInfantry), out _);
            return board;
        }

        [Test]
        public void PoweredInfantryGearSpawnsOnItsConfiguredFixedTickInterval()
        {
            var board = ConnectedInfantryBoard(3);
            var combat = new CombatSimulation();
            var outputs = new GearOutputSystem();
            var network = GearNetwork.Rebuild(board);
            for (var tick = 0; tick < 9; tick++) outputs.Tick(board, network, combat);
            Assert.That(combat.Combatants.Count, Is.EqualTo(3));
            Assert.That(outputs.Clocks["press"].ProgressTicks, Is.Zero);
            Assert.That(outputs.Clocks["press"].Status, Is.EqualTo(GearOutputStatus.Produced));
        }

        [Test]
        public void DisconnectPausesOutputWithoutRemovingUnitsAlreadyProduced()
        {
            var board = ConnectedInfantryBoard(3);
            var combat = new CombatSimulation();
            var outputs = new GearOutputSystem();
            var network = GearNetwork.Rebuild(board);
            for (var tick = 0; tick < 3; tick++) outputs.Tick(board, network, combat);
            board.RemoveAt(1, 0);
            network = GearNetwork.Rebuild(board);
            outputs.Tick(board, network, combat);
            Assert.That(combat.Combatants.Count, Is.EqualTo(1));
            Assert.That(outputs.Clocks["press"].Status, Is.EqualTo(GearOutputStatus.Inactive));
        }

        [Test]
        public void UnitCapQueuesOneSpawnWithoutUnboundedGrowth()
        {
            var board = ConnectedInfantryBoard(1);
            var combat = new CombatSimulation();
            combat.Add(new Combatant(5, CombatFaction.Friendly, 1, 0, 30, 0, 1, 0, 0, 1));
            var outputs = new GearOutputSystem(unitCapPerLane: 1);
            outputs.Tick(board, GearNetwork.Rebuild(board), combat);
            Assert.That(combat.Combatants.Count, Is.EqualTo(1));
            Assert.That(outputs.Clocks["press"].PendingSpawn, Is.True);
            Assert.That(outputs.Clocks["press"].Status, Is.EqualTo(GearOutputStatus.UnitCapacityReached));
        }
    }
}
