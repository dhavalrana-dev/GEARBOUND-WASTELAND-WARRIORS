using System;
using System.Collections.Generic;
using System.Linq;

namespace Gearbound.Core
{
    public sealed class ScheduledSpawn
    {
        public int Tick { get; }
        public int Lane { get; }
        public string EnemyId { get; }
        public ScheduledSpawn(int tick, int lane, string enemyId) { Tick = tick; Lane = lane; EnemyId = enemyId; }
    }

    /// <summary>
    /// Expands authored spawn groups into a stable schedule: spawn k of a group fires at
    /// firstSpawnTick + k * intervalTicks in lane lanePattern[k % length]. Order is tick, lane,
    /// group index, then k, so simultaneous spawns always resolve identically.
    /// </summary>
    public static class WaveDirector
    {
        public static IReadOnlyList<ScheduledSpawn> Schedule(AuthoredWave wave)
        {
            if (wave == null) throw new ArgumentNullException(nameof(wave));
            var entries = new List<(int tick, int lane, int group, int k, string enemy)>();
            for (var g = 0; g < wave.Groups.Count; g++)
            {
                var group = wave.Groups[g];
                if (group.Count < 1 || group.IntervalTicks < 1 || group.FirstSpawnTick < 0) throw new ArgumentOutOfRangeException(nameof(wave), "Spawn group timing is invalid.");
                for (var k = 0; k < group.Count; k++)
                    entries.Add((group.FirstSpawnTick + k * group.IntervalTicks, group.LanePattern[k % group.LanePattern.Count], g, k, group.EnemyId));
            }
            return entries.OrderBy(e => e.tick).ThenBy(e => e.lane).ThenBy(e => e.group).ThenBy(e => e.k)
                .Select(e => new ScheduledSpawn(e.tick, e.lane, e.enemy)).ToArray();
        }

        /// <summary>Resolves archetype stats so the battle session receives a playable wave.</summary>
        public static WaveDefinition Build(AuthoredWave wave, IEnumerable<EnemyDefinition> enemies)
        {
            var byId = enemies.ToDictionary(e => e.Id, StringComparer.Ordinal);
            var spawns = Schedule(wave).Select(spawn =>
            {
                if (!byId.TryGetValue(spawn.EnemyId, out var e)) throw new KeyNotFoundException($"Wave '{wave.Id}' references unknown enemy '{spawn.EnemyId}'.");
                return new WaveSpawnEvent(spawn.Tick, spawn.Lane, e.Health, e.Armor, e.Damage, e.AttackRangeMm, e.MovementMmPerTick, e.AttackIntervalTicks);
            });
            return new WaveDefinition(wave.Id, spawns, wave.RewardScrap);
        }
    }
}
