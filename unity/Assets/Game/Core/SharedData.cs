using System;
using System.Collections.Generic;
using System.Linq;

namespace Gearbound.Core
{
    public sealed class GearDefinition
    {
        public string Id { get; }
        public string Name { get; }
        public string Category { get; }
        public int Tier { get; }
        public string Rarity { get; }
        public IReadOnlyList<Direction> Ports { get; }
        public int BaseIntervalTicks { get; }
        public int Cost { get; }

        public GearDefinition(string id, string name, string category, int tier, string rarity, IEnumerable<Direction> ports, int baseIntervalTicks, int cost)
        {
            if (string.IsNullOrWhiteSpace(id)) throw new ArgumentException("Gear ID is required.", nameof(id));
            if (tier < 1 || baseIntervalTicks < 0 || cost < 0) throw new ArgumentOutOfRangeException("Gear stats are outside their allowed range.");
            Id = id; Name = name; Category = category; Tier = tier; Rarity = rarity;
            Ports = ports.ToArray(); BaseIntervalTicks = baseIntervalTicks; Cost = cost;
        }

        public GearKind Kind => Category switch
        {
            "power-core" => GearKind.Core,
            "transmission" => GearKind.Transmission,
            "booster" => GearKind.Booster,
            _ => GearKind.Output,
        };

        public GearOutputKind OutputKind => Category == "infantry" ? GearOutputKind.SpawnInfantry : GearOutputKind.None;
    }

    public sealed class EnemyDefinition
    {
        public string Id { get; }
        public string Name { get; }
        public string Role { get; }
        public int Health { get; }
        public int Armor { get; }
        public int Damage { get; }
        public int AttackRangeMm { get; }
        public int MovementMmPerTick { get; }
        public int AttackIntervalTicks { get; }
        public int RewardScrap { get; }

        public EnemyDefinition(string id, string name, string role, int health, int armor, int damage, int attackRangeMm,
            int movementMmPerTick, int attackIntervalTicks, int rewardScrap)
        {
            if (string.IsNullOrWhiteSpace(id)) throw new ArgumentException("Enemy ID is required.", nameof(id));
            if (health < 1 || armor < 0 || damage < 1 || attackRangeMm < 0 || movementMmPerTick < 0 || attackIntervalTicks < 1 || rewardScrap < 0)
                throw new ArgumentOutOfRangeException("Enemy stats are outside their allowed range.");
            Id = id; Name = name; Role = role; Health = health; Armor = armor; Damage = damage; AttackRangeMm = attackRangeMm;
            MovementMmPerTick = movementMmPerTick; AttackIntervalTicks = attackIntervalTicks; RewardScrap = rewardScrap;
        }
    }

    public sealed class ShopConfig
    {
        public int OfferCount { get; set; } = 3;
        public int MaxCopiesPerOffer { get; set; } = 2;
        public IReadOnlyDictionary<string, int> RarityWeights { get; set; } = new Dictionary<string, int>();
        public IReadOnlyCollection<string> ExcludedCategories { get; set; } = Array.Empty<string>();
        public string GuaranteedCategory { get; set; }
        public int RerollBaseCost { get; set; } = 1;
        public int RerollCostStep { get; set; } = 1;
        public int RerollCostCap { get; set; } = 5;
        public int SellRefundPercent { get; set; } = 50;
        public int StartingScrap { get; set; }
    }

    public sealed class WaveGroupDefinition
    {
        public string EnemyId { get; set; }
        public int Count { get; set; }
        public int FirstSpawnTick { get; set; }
        public int IntervalTicks { get; set; }
        public IReadOnlyList<int> LanePattern { get; set; }
    }

    public sealed class AuthoredWave
    {
        public string Id { get; set; }
        public int RewardScrap { get; set; }
        public bool Boss { get; set; }
        public IReadOnlyList<WaveGroupDefinition> Groups { get; set; }
    }

    public sealed class MissionDefinition
    {
        public string MissionId { get; set; }
        public IReadOnlyList<AuthoredWave> Waves { get; set; }
    }

    /// <summary>Loads versioned shared JSON (schemaVersion 1) into engine-independent definitions.</summary>
    public static class SharedDataLoader
    {
        private static Dictionary<string, object> Root(string json, string what)
        {
            var root = SharedJson.Obj(SharedJson.Parse(json), what);
            if (SharedJson.Int(root, "schemaVersion") != 1) throw new FormatException($"{what}: unsupported schemaVersion.");
            return root;
        }

        public static IReadOnlyList<GearDefinition> LoadGears(string json)
        {
            var list = new List<GearDefinition>();
            foreach (var item in SharedJson.Arr(Root(json, "gears"), "gears"))
            {
                var gear = SharedJson.Obj(item, "gear");
                var ports = SharedJson.Arr(gear, "ports").Select(port => ParseDirection((string)port));
                list.Add(new GearDefinition(SharedJson.Str(gear, "id"), SharedJson.Str(gear, "name"), SharedJson.Str(gear, "category"),
                    SharedJson.Int(gear, "tier"), SharedJson.Str(gear, "rarity"), ports, SharedJson.Int(gear, "baseIntervalTicks"), SharedJson.Int(gear, "cost")));
            }
            RequireUniqueIds(list.Select(g => g.Id), "gear");
            return list;
        }

        public static IReadOnlyList<EnemyDefinition> LoadEnemies(string json)
        {
            var list = new List<EnemyDefinition>();
            foreach (var item in SharedJson.Arr(Root(json, "enemies"), "enemies"))
            {
                var e = SharedJson.Obj(item, "enemy");
                list.Add(new EnemyDefinition(SharedJson.Str(e, "id"), SharedJson.Str(e, "name"), SharedJson.Str(e, "role"),
                    SharedJson.Int(e, "health"), SharedJson.Int(e, "armor"), SharedJson.Int(e, "damage"), SharedJson.Int(e, "attackRangeMm"),
                    SharedJson.Int(e, "movementMmPerTick"), SharedJson.Int(e, "attackIntervalTicks"), SharedJson.Int(e, "rewardScrap")));
            }
            RequireUniqueIds(list.Select(e => e.Id), "enemy");
            return list;
        }

        public static ShopConfig LoadShop(string json)
        {
            var root = Root(json, "shop");
            var weights = SharedJson.Obj(root["rarityWeights"], "rarityWeights");
            var reroll = SharedJson.Obj(root["reroll"], "reroll");
            return new ShopConfig
            {
                OfferCount = SharedJson.Int(root, "offerCount"),
                MaxCopiesPerOffer = SharedJson.Int(root, "maxCopiesPerOffer"),
                RarityWeights = weights.Keys.ToDictionary(key => key, key => SharedJson.Int(weights, key), StringComparer.Ordinal),
                ExcludedCategories = SharedJson.Arr(root, "excludedCategories").Cast<string>().ToArray(),
                GuaranteedCategory = root.TryGetValue("guaranteedCategory", out var category) ? category as string : null,
                RerollBaseCost = SharedJson.Int(reroll, "baseCost"),
                RerollCostStep = SharedJson.Int(reroll, "costStep"),
                RerollCostCap = SharedJson.Int(reroll, "costCap"),
                SellRefundPercent = SharedJson.Int(root, "sellRefundPercent"),
                StartingScrap = SharedJson.Int(root, "startingScrap"),
            };
        }

        public static MissionDefinition LoadMission(string json)
        {
            var root = Root(json, "mission");
            var waves = new List<AuthoredWave>();
            foreach (var item in SharedJson.Arr(root, "waves"))
            {
                var w = SharedJson.Obj(item, "wave");
                var groups = SharedJson.Arr(w, "groups").Select(g =>
                {
                    var group = SharedJson.Obj(g, "group");
                    var lanes = SharedJson.Arr(group, "lanePattern").Select(lane => checked((int)(long)lane)).ToArray();
                    if (lanes.Length == 0 || lanes.Any(lane => lane < 0 || lane > 2)) throw new FormatException("lanePattern must contain lanes 0-2.");
                    return new WaveGroupDefinition
                    {
                        EnemyId = SharedJson.Str(group, "enemyId"), Count = SharedJson.Int(group, "count"),
                        FirstSpawnTick = SharedJson.Int(group, "firstSpawnTick"), IntervalTicks = SharedJson.Int(group, "intervalTicks"),
                        LanePattern = lanes,
                    };
                }).ToArray();
                waves.Add(new AuthoredWave { Id = SharedJson.Str(w, "id"), RewardScrap = SharedJson.Int(w, "rewardScrap"), Boss = SharedJson.Bool(w, "boss"), Groups = groups });
            }
            RequireUniqueIds(waves.Select(w => w.Id), "wave");
            return new MissionDefinition { MissionId = SharedJson.Str(root, "missionId"), Waves = waves };
        }

        private static Direction ParseDirection(string port) => port switch
        {
            "north" => Direction.North,
            "east" => Direction.East,
            "south" => Direction.South,
            "west" => Direction.West,
            _ => throw new FormatException($"Unknown port '{port}'."),
        };

        private static void RequireUniqueIds(IEnumerable<string> ids, string what)
        {
            var seen = new HashSet<string>(StringComparer.Ordinal);
            foreach (var id in ids) if (!seen.Add(id)) throw new FormatException($"Duplicate {what} ID '{id}'.");
        }
    }
}
