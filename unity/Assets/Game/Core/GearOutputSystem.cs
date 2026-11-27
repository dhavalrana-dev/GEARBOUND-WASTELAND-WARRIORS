using System;
using System.Collections.Generic;
using System.Linq;

namespace Gearbound.Core
{
    public enum GearOutputStatus { Inactive, Progressing, UnitCapacityReached, Produced }

    public sealed class GearOutputClock
    {
        public string GearId { get; internal set; }
        public int ProgressTicks { get; internal set; }
        public bool PendingSpawn { get; internal set; }
        public GearOutputStatus Status { get; internal set; }
    }

    public sealed class GearOutputSystem
    {
        private readonly Dictionary<string, GearOutputClock> clocks = new Dictionary<string, GearOutputClock>();
        private int nextEntityId;
        public IReadOnlyDictionary<string, GearOutputClock> Clocks => clocks;
        public int UnitCapPerLane { get; }

        public GearOutputSystem(int unitCapPerLane = 4, int firstEntityId = 100000)
        {
            if (unitCapPerLane < 1 || firstEntityId < 1) throw new ArgumentOutOfRangeException("Output limits and IDs must be positive.");
            UnitCapPerLane = unitCapPerLane;
            nextEntityId = firstEntityId;
        }

        public void Tick(GearBoard board, GearNetworkResult network, CombatSimulation combat)
        {
            if (board == null || network == null || combat == null) throw new ArgumentNullException("Output bridge inputs cannot be null.");
            var activeGearIds = new HashSet<string>();
            foreach (var gear in board.Nodes.OrderBy(node => node.Y).ThenBy(node => node.X))
            {
                if (gear.Kind != GearKind.Output || gear.OutputKind != GearOutputKind.SpawnInfantry) continue;
                activeGearIds.Add(gear.Id);
                if (!clocks.TryGetValue(gear.Id, out var clock))
                {
                    clock = new GearOutputClock { GearId = gear.Id, Status = GearOutputStatus.Inactive };
                    clocks.Add(gear.Id, clock);
                }

                if (!network.Nodes.TryGetValue(gear.Id, out var state) || state.State != NetworkState.Powered || state.EffectiveIntervalTicks < 1)
                {
                    clock.Status = GearOutputStatus.Inactive;
                    continue;
                }

                if (!clock.PendingSpawn) clock.ProgressTicks++;
                if (!clock.PendingSpawn && clock.ProgressTicks < state.EffectiveIntervalTicks)
                {
                    clock.Status = GearOutputStatus.Progressing;
                    continue;
                }

                var friendlyInLane = combat.Combatants.Count(unit => unit.IsAlive && unit.Faction == CombatFaction.Friendly && unit.Lane == gear.TargetLane);
                if (friendlyInLane >= UnitCapPerLane)
                {
                    clock.PendingSpawn = true;
                    clock.ProgressTicks = state.EffectiveIntervalTicks;
                    clock.Status = GearOutputStatus.UnitCapacityReached;
                    continue;
                }

                combat.Add(new Combatant(nextEntityId++, CombatFaction.Friendly, gear.TargetLane, 0, 30, 1, 5, 250, 40, 24));
                clock.PendingSpawn = false;
                clock.ProgressTicks = 0;
                clock.Status = GearOutputStatus.Produced;
            }

            foreach (var staleId in clocks.Keys.Where(id => !activeGearIds.Contains(id)).ToArray()) clocks.Remove(staleId);
        }
    }
}
