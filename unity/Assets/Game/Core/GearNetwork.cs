using System;
using System.Collections.Generic;
using System.Linq;

namespace Gearbound.Core
{
    public enum Direction { North, East, South, West }
    public enum GearKind { Core, Transmission, Booster, Output }
    public enum GearOutputKind { None, SpawnInfantry }
    public enum NetworkState { Unpowered, Powered, Jammed, Conflicted }

    [Serializable]
    public sealed class GearNode
    {
        public string Id;
        public string DefinitionId;
        public GearKind Kind;
        public int Tier;
        public GearOutputKind OutputKind;
        public int TargetLane;
        public int X;
        public int Y;
        public int RotationQuarterTurns;
        public int BaseIntervalTicks;
        public HashSet<Direction> LocalPorts;

        public GearNode(string id, GearKind kind, int x, int y, IEnumerable<Direction> ports, int baseIntervalTicks = 0, int rotationQuarterTurns = 0, string definitionId = null, int tier = 1, GearOutputKind outputKind = GearOutputKind.None, int targetLane = 1)
        {
            Id = id ?? throw new ArgumentNullException(nameof(id));
            DefinitionId = definitionId ?? id;
            Kind = kind;
            if (tier < 1) throw new ArgumentOutOfRangeException(nameof(tier));
            Tier = tier;
            if (targetLane < 0 || targetLane > 2) throw new ArgumentOutOfRangeException(nameof(targetLane));
            OutputKind = outputKind;
            TargetLane = targetLane;
            X = x;
            Y = y;
            BaseIntervalTicks = baseIntervalTicks;
            RotationQuarterTurns = ((rotationQuarterTurns % 4) + 4) % 4;
            LocalPorts = new HashSet<Direction>(ports ?? Array.Empty<Direction>());
        }

        public bool HasPort(Direction worldDirection)
        {
            var local = (Direction)(((int)worldDirection - RotationQuarterTurns + 4) % 4);
            return LocalPorts.Contains(local);
        }
    }

    public sealed class GearBoard
    {
        private readonly Dictionary<(int x, int y), GearNode> cells = new Dictionary<(int, int), GearNode>();
        public int Width { get; }
        public int Height { get; }
        public int MaxCores { get; }
        public IReadOnlyCollection<GearNode> Nodes => cells.Values;

        public GearBoard(int width = 5, int height = 5, int maxCores = 1)
        {
            if (width < 1 || height < 1) throw new ArgumentOutOfRangeException("Board dimensions must be positive.");
            if (maxCores < 1) throw new ArgumentOutOfRangeException(nameof(maxCores));
            Width = width;
            Height = height;
            MaxCores = maxCores;
        }

        public bool TryPlace(GearNode node, out string error)
        {
            if (node == null) { error = "Gear is null."; return false; }
            if (node.X < 0 || node.Y < 0 || node.X >= Width || node.Y >= Height) { error = "Cell is outside the board."; return false; }
            if (cells.ContainsKey((node.X, node.Y))) { error = "Cell is occupied."; return false; }
            if (cells.Values.Any(existing => existing.Id == node.Id)) { error = "Gear ID is already installed."; return false; }
            if (node.Kind == GearKind.Core && cells.Values.Count(existing => existing.Kind == GearKind.Core) >= MaxCores) { error = "Board core limit is reached."; return false; }
            cells.Add((node.X, node.Y), node);
            error = null;
            return true;
        }

        public bool RemoveAt(int x, int y) => cells.Remove((x, y));
        public GearNode At(int x, int y) => cells.TryGetValue((x, y), out var node) ? node : null;

        public bool TryMerge(int x1, int y1, int x2, int y2, int maxTier, int nextTierBaseIntervalTicks, out GearNode merged, out string error)
        {
            merged = null;
            var first = At(x1, y1);
            var second = At(x2, y2);
            if (first == null || second == null) { error = "Both merge cells must contain a gear."; return false; }
            if (first == second) { error = "A gear cannot merge with itself."; return false; }
            if (first.Kind == GearKind.Core || second.Kind == GearKind.Core) { error = "Power cores cannot be merged."; return false; }
            if (first.DefinitionId != second.DefinitionId || first.Kind != second.Kind || first.Tier != second.Tier)
            { error = "Gears must have the same definition and tier."; return false; }
            if (maxTier < 1 || first.Tier >= maxTier) { error = "Gear is already at maximum tier."; return false; }
            if (nextTierBaseIntervalTicks < 0) { error = "The configured output interval cannot be negative."; return false; }

            var anchor = first.Y < second.Y || (first.Y == second.Y && first.X <= second.X) ? first : second;
            var newId = $"{anchor.DefinitionId}:t{anchor.Tier + 1}@{anchor.X},{anchor.Y}";
            if (cells.Values.Any(node => node.Id != first.Id && node.Id != second.Id && node.Id == newId))
            { error = "The merged gear ID is already installed."; return false; }

            var replacement = new GearNode(newId, anchor.Kind, anchor.X, anchor.Y, anchor.LocalPorts,
                nextTierBaseIntervalTicks, anchor.RotationQuarterTurns, anchor.DefinitionId, anchor.Tier + 1, anchor.OutputKind, anchor.TargetLane);
            cells.Remove((first.X, first.Y));
            cells.Remove((second.X, second.Y));
            cells.Add((replacement.X, replacement.Y), replacement);
            merged = replacement;
            error = null;
            return true;
        }
    }

    public sealed class GearNodeResult
    {
        public string Id { get; internal set; }
        public NetworkState State { get; internal set; }
        public int RotationParity { get; internal set; }
        public int BoosterBonusPercent { get; internal set; }
        public int EffectiveIntervalTicks { get; internal set; }
    }

    public sealed class GearNetworkResult
    {
        public IReadOnlyDictionary<string, GearNodeResult> Nodes { get; internal set; }
        public IReadOnlyList<(string a, string b)> Edges { get; internal set; }
    }

    public static class GearNetwork
    {
        private static readonly (Direction direction, int dx, int dy)[] Steps =
        {
            (Direction.North, 0, -1), (Direction.East, 1, 0), (Direction.South, 0, 1), (Direction.West, -1, 0)
        };

        public static GearNetworkResult Rebuild(GearBoard board, int boosterEachPercent = 10, int boosterCapPercent = 30)
        {
            if (board == null) throw new ArgumentNullException(nameof(board));
            if (boosterEachPercent < 0 || boosterCapPercent < 0) throw new ArgumentOutOfRangeException("Booster modifiers must be non-negative.");

            var nodes = board.Nodes.OrderBy(n => n.Y).ThenBy(n => n.X).ToArray();
            var adjacency = nodes.ToDictionary(n => n.Id, _ => new List<GearNode>());
            var edges = new List<(string a, string b)>();
            foreach (var node in nodes)
            foreach (var step in Steps)
            {
                var neighbor = board.At(node.X + step.dx, node.Y + step.dy);
                if (neighbor == null || StringComparer.Ordinal.Compare(node.Id, neighbor.Id) >= 0) continue;
                var reciprocal = (Direction)(((int)step.direction + 2) % 4);
                if (!node.HasPort(step.direction) || !neighbor.HasPort(reciprocal)) continue;
                adjacency[node.Id].Add(neighbor);
                adjacency[neighbor.Id].Add(node);
                edges.Add((node.Id, neighbor.Id));
            }

            var results = nodes.ToDictionary(n => n.Id, n => new GearNodeResult { Id = n.Id, State = NetworkState.Unpowered, RotationParity = -1 });
            var visited = new HashSet<string>();
            foreach (var root in nodes)
            {
                if (!visited.Add(root.Id)) continue;
                var component = new List<GearNode>();
                var parity = new Dictionary<string, int> { [root.Id] = 0 };
                var queue = new Queue<GearNode>();
                queue.Enqueue(root);
                var oddLoop = false;
                while (queue.Count > 0)
                {
                    var current = queue.Dequeue();
                    component.Add(current);
                    foreach (var neighbor in adjacency[current.Id])
                    {
                        var expected = 1 - parity[current.Id];
                        if (!parity.ContainsKey(neighbor.Id))
                        {
                            parity[neighbor.Id] = expected;
                            visited.Add(neighbor.Id);
                            queue.Enqueue(neighbor);
                        }
                        else if (parity[neighbor.Id] != expected) oddLoop = true;
                    }
                }

                var cores = component.Count(n => n.Kind == GearKind.Core);
                var state = cores == 0 ? NetworkState.Unpowered : cores > 1 ? NetworkState.Conflicted : oddLoop ? NetworkState.Jammed : NetworkState.Powered;
                var boosterCount = component.Count(n => n.Kind == GearKind.Booster);
                var bonus = Math.Min(boosterCapPercent, boosterCount * boosterEachPercent);
                foreach (var node in component)
                {
                    var nodeBonus = node.Kind == GearKind.Output && state == NetworkState.Powered ? bonus : 0;
                    var interval = node.Kind == GearKind.Output && state == NetworkState.Powered && node.BaseIntervalTicks > 0
                        ? Math.Max(1, (node.BaseIntervalTicks * 100 + (100 + nodeBonus) - 1) / (100 + nodeBonus))
                        : 0;
                    results[node.Id] = new GearNodeResult { Id = node.Id, State = state, RotationParity = parity[node.Id], BoosterBonusPercent = nodeBonus, EffectiveIntervalTicks = interval };
                }
            }

            return new GearNetworkResult { Nodes = results, Edges = edges };
        }
    }
}
