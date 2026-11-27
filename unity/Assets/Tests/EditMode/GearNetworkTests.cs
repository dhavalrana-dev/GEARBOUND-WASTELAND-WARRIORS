using Gearbound.Core;
using NUnit.Framework;

namespace Gearbound.Tests
{
    public sealed class GearNetworkTests
    {
        private static GearNode Gear(string id, GearKind kind, int x, int y, int interval = 0) =>
            new GearNode(id, kind, x, y, new[] { Direction.North, Direction.East, Direction.South, Direction.West }, interval);

        [Test]
        public void CoreChainPowersOutputAndAlternatesParity()
        {
            var board = new GearBoard();
            Assert.That(board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _), Is.True);
            Assert.That(board.TryPlace(Gear("shaft", GearKind.Transmission, 1, 0), out _), Is.True);
            Assert.That(board.TryPlace(Gear("mill", GearKind.Output, 2, 0, 90), out _), Is.True);
            var result = GearNetwork.Rebuild(board);
            Assert.That(result.Nodes["mill"].State, Is.EqualTo(NetworkState.Powered));
            Assert.That(result.Nodes["core"].RotationParity, Is.Zero);
            Assert.That(result.Nodes["shaft"].RotationParity, Is.EqualTo(1));
            Assert.That(result.Nodes["mill"].EffectiveIntervalTicks, Is.EqualTo(90));
        }

        [Test]
        public void DisconnectedOutputIsUnpowered()
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("mill", GearKind.Output, 4, 4, 90), out _);
            Assert.That(GearNetwork.Rebuild(board).Nodes["mill"].State, Is.EqualTo(NetworkState.Unpowered));
        }

        [Test]
        public void RemovingCouplerDisconnectsDownstreamOutput()
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("shaft", GearKind.Transmission, 1, 0), out _);
            board.TryPlace(Gear("mill", GearKind.Output, 2, 0, 90), out _);
            board.RemoveAt(1, 0);
            Assert.That(GearNetwork.Rebuild(board).Nodes["mill"].State, Is.EqualTo(NetworkState.Unpowered));
        }

        [Test]
        public void BoosterStackIsCappedAndShortensOutputInterval()
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("b1", GearKind.Booster, 1, 0), out _);
            board.TryPlace(Gear("b2", GearKind.Booster, 2, 0), out _);
            board.TryPlace(Gear("b3", GearKind.Booster, 3, 0), out _);
            board.TryPlace(Gear("b4", GearKind.Booster, 4, 0), out _);
            board.TryPlace(Gear("mill", GearKind.Output, 4, 1, 90), out _);
            var output = GearNetwork.Rebuild(board).Nodes["mill"];
            Assert.That(output.BoosterBonusPercent, Is.EqualTo(30));
            Assert.That(output.EffectiveIntervalTicks, Is.EqualTo(70));
        }

        [Test]
        public void PlacementRejectsOutOfBoundsAndOccupiedCells()
        {
            var board = new GearBoard();
            Assert.That(board.TryPlace(Gear("bad", GearKind.Core, -1, 0), out _), Is.False);
            Assert.That(board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _), Is.True);
            Assert.That(board.TryPlace(Gear("other", GearKind.Output, 0, 0), out _), Is.False);
        }

        [Test]
        public void InitialBoardAllowsOnlyOnePowerCore()
        {
            var board = new GearBoard();
            Assert.That(board.TryPlace(Gear("core-a", GearKind.Core, 0, 0), out _), Is.True);
            Assert.That(board.TryPlace(Gear("core-b", GearKind.Core, 4, 4), out _), Is.False);
        }

        [Test]
        public void EvenMechanicalLoopPowersAndAlternatesConsistently()
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("east", GearKind.Transmission, 1, 0), out _);
            board.TryPlace(Gear("south", GearKind.Transmission, 0, 1), out _);
            board.TryPlace(Gear("corner", GearKind.Transmission, 1, 1), out _);
            var result = GearNetwork.Rebuild(board);
            Assert.That(result.Nodes["corner"].State, Is.EqualTo(NetworkState.Powered));
            Assert.That(result.Nodes["corner"].RotationParity, Is.Zero);
        }

        [Test]
        public void TwoCoresInOneConnectedComponentDisableThatComponent()
        {
            var board = new GearBoard(maxCores: 2);
            board.TryPlace(Gear("core-a", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("core-b", GearKind.Core, 1, 0), out _);
            board.TryPlace(Gear("mill", GearKind.Output, 2, 0, 90), out _);
            Assert.That(GearNetwork.Rebuild(board).Nodes["mill"].State, Is.EqualTo(NetworkState.Conflicted));
        }

        [Test]
        public void MergeConsumesMatchingPairAndKeepsRowMajorAnchor()
        {
            var board = new GearBoard();
            board.TryPlace(new GearNode("press-a", GearKind.Output, 2, 1, new[] { Direction.West }, 90, 0, "unit.press", 1), out _);
            board.TryPlace(new GearNode("press-b", GearKind.Output, 1, 0, new[] { Direction.West }, 90, 0, "unit.press", 1), out _);
            Assert.That(board.TryMerge(2, 1, 1, 0, 3, 60, out var merged, out _), Is.True);
            Assert.That(merged.X, Is.EqualTo(1));
            Assert.That(merged.Y, Is.Zero);
            Assert.That(merged.Tier, Is.EqualTo(2));
            Assert.That(merged.BaseIntervalTicks, Is.EqualTo(60));
            Assert.That(board.At(2, 1), Is.Null);
        }

        [Test]
        public void MergeRejectsMismatchedTierWithoutChangingBoard()
        {
            var board = new GearBoard();
            board.TryPlace(new GearNode("press-a", GearKind.Output, 0, 0, new[] { Direction.East }, 90, 0, "unit.press", 1), out _);
            board.TryPlace(new GearNode("press-b", GearKind.Output, 1, 0, new[] { Direction.West }, 60, 0, "unit.press", 2), out _);
            Assert.That(board.TryMerge(0, 0, 1, 0, 3, 40, out _, out _), Is.False);
            Assert.That(board.At(0, 0), Is.Not.Null);
            Assert.That(board.At(1, 0), Is.Not.Null);
        }
    }
}
