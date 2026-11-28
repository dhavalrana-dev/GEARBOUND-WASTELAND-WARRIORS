using System;
using System.Collections.Generic;
using System.Linq;
using Gearbound.Core;
using Gearbound.Economy;

namespace Gearbound.Workshop
{
    public readonly struct StarterGear
    {
        public StarterGear(string definitionId, int x, int y) { DefinitionId = definitionId; X = x; Y = y; }
        public string DefinitionId { get; }
        public int X { get; }
        public int Y { get; }
    }

    /// <summary>Workshop tuning from shared/configs/gear_rules.json (<c>merge</c>, <c>workshop</c>).</summary>
    public sealed class WorkshopRules
    {
        public int MaxTier { get; set; }
        public IReadOnlyList<int> IntervalPercentByTier { get; set; } = Array.Empty<int>();
        public IReadOnlyList<int> OutputLaneByRow { get; set; } = Array.Empty<int>();
        public IReadOnlyList<StarterGear> StarterGears { get; set; } = Array.Empty<StarterGear>();
        public ISet<string> ShopCategories { get; set; } = new HashSet<string>();

        public static WorkshopRules Load(string json)
        {
            var root = SharedJson.Obj(SharedJson.Parse(json), "gear_rules");
            var merge = SharedJson.Obj(root["merge"], "merge");
            var workshop = SharedJson.Obj(root["workshop"], "workshop");
            return new WorkshopRules
            {
                MaxTier = SharedJson.Int(merge, "maxTier"),
                IntervalPercentByTier = SharedJson.Arr(merge, "intervalPercentByTier").Select(Convert.ToInt32).ToArray(),
                OutputLaneByRow = SharedJson.Arr(workshop, "outputLaneByRow").Select(Convert.ToInt32).ToArray(),
                StarterGears = SharedJson.Arr(workshop, "starterGears").Select(item =>
                {
                    var g = SharedJson.Obj(item, "starterGear");
                    return new StarterGear(SharedJson.Str(g, "definitionId"), SharedJson.Int(g, "x"), SharedJson.Int(g, "y"));
                }).ToArray(),
                ShopCategories = new HashSet<string>(SharedJson.Arr(workshop, "shopCategories").Cast<string>(), StringComparer.Ordinal),
            };
        }

        /// <summary>Output interval for a gear tier: base × percent / 100, rounded up.</summary>
        public int IntervalFor(int baseIntervalTicks, int tier) => (baseIntervalTicks * IntervalPercentByTier[tier - 1] + 99) / 100;

        public int LaneForRow(int row) => OutputLaneByRow[row];
    }

    public enum WorkshopAction
    {
        Ok, Locked, NoOffer, HandFull, InsufficientScrap, Occupied, NothingToPlace,
        NotMergeable, MaxTier, CannotSellCore, NothingSelected, NothingToUndo, AllHeld,
    }

    /// <summary>What would happen if a gear were placed or moved to a cell.</summary>
    public readonly struct PlacementPreview
    {
        public PlacementPreview(bool valid, NetworkState? state, int intervalTicks, int? lane)
        { Valid = valid; State = state; IntervalTicks = intervalTicks; Lane = lane; }
        /// <summary>False when the cell is occupied by a gear that cannot merge.</summary>
        public bool Valid { get; }
        public NetworkState? State { get; }
        /// <summary>Effective output interval after boosters; 0 for non-output gears.</summary>
        public int IntervalTicks { get; }
        public int? Lane { get; }
    }

    /// <summary>
    /// Preparation-phase state for one mission attempt; same rules as
    /// flutter/lib/features/workshop/workshop_controller.dart, checked by shared/test-fixtures/workshop_cases.json.
    /// Battle scrap is a mission-scoped wallet that is never saved; every spend and refund goes through the ledger.
    /// Buys and rerolls are not undoable: Cancel refunds an unplaced buy, and undoing a reroll would preview offers for free.
    /// Not ported yet: checkpoint save/restore (Flutter <c>toJson</c>/<c>restore</c>).
    /// </summary>
    public sealed class WorkshopController
    {
        public const string BattleScrap = "battle_scrap";

        private sealed class UndoEntry
        {
            public List<GearNode> Board;
            public GearDefinition Hand;
            public int ScrapGained;
        }

        private readonly SeededRandom rng;
        private readonly Func<DateTime> clock;
        private readonly List<UndoEntry> undo = new List<UndoEntry>();
        private int nextGearNumber = 1;
        private int nextTxn = 1;

        public GearBoard Board { get; }
        public IReadOnlyList<GearDefinition> Catalog { get; }
        public ShopConfig Shop { get; }
        public WorkshopRules Rules { get; }
        public uint Seed { get; }
        public Wallet Wallet { get; }
        public SeededRandom Random => rng;

        public string[] Offers { get; private set; } = Array.Empty<string>();
        /// <summary>Offers the player is holding: a reroll and a new wave's shop keep them.</summary>
        public bool[] Held { get; private set; } = Array.Empty<bool>();
        public int RerollsTaken { get; private set; }
        public bool Locked { get; private set; }
        /// <summary>Definition bought but not yet placed.</summary>
        public GearDefinition Hand { get; private set; }
        public (int X, int Y)? Selected { get; private set; }

        /// <summary>The mission wallet caps battle scrap like the Dart default asset rules.</summary>
        public static AssetRules MissionAssetRules() => new AssetRules
        {
            CurrencyMax = new Dictionary<string, long>(StringComparer.Ordinal) { [BattleScrap] = 100000 },
        };

        public WorkshopController(GearBoard board, IReadOnlyList<GearDefinition> catalog, ShopConfig shop, WorkshopRules rules,
            uint seed, Func<DateTime> clock = null)
        {
            Board = board ?? throw new ArgumentNullException(nameof(board));
            Catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            Shop = shop ?? throw new ArgumentNullException(nameof(shop));
            Rules = rules ?? throw new ArgumentNullException(nameof(rules));
            Seed = seed;
            this.clock = clock ?? (() => DateTime.UtcNow);
            rng = new SeededRandom(SeededRandom.MixSeed32(seed));
            Wallet = new Wallet(MissionAssetRules(), "mission");
            foreach (var starter in rules.StarterGears)
            {
                if (!board.TryPlace(NewNode(Definition(starter.DefinitionId), starter.X, starter.Y, 1), out var error))
                    throw new InvalidOperationException("Starter gear could not be placed: " + error);
            }
            Wallet.Apply(new TxnRequest
            {
                IdempotencyKey = "mission_start", Type = "grant", Source = "mission_start",
                Deltas = new[] { new TxnDelta(BattleScrap, shop.StartingScrap) },
            }, this.clock());
            RollOffers();
        }

        public bool CanUndo => !Locked && undo.Count > 0;
        public int BattleScrapBalance => (int)Wallet.Balance(BattleScrap);
        public int RerollPrice => GearShop.RerollCost(Shop, RerollsTaken);

        public GearDefinition DefinitionFor(string id) => Definition(id);

        /// <summary>Battle scrap returned when selling the selected gear: the refund share of every tier-1 copy merged into it.</summary>
        public int SelectedSellValue
        {
            get
            {
                var node = Selected.HasValue ? Board.At(Selected.Value.X, Selected.Value.Y) : null;
                if (node == null) return 0;
                return GearShop.SellValue(Shop, Definition(node.DefinitionId)) * (1 << (node.Tier - 1));
            }
        }

        public WorkshopAction Buy(int slot)
        {
            if (Locked) return WorkshopAction.Locked;
            if (Hand != null) return WorkshopAction.HandFull;
            var id = slot >= 0 && slot < Offers.Length ? Offers[slot] : null;
            if (id == null) return WorkshopAction.NoOffer;
            var gear = Definition(id);
            if (!Spend(gear.Cost, "buy", id)) return WorkshopAction.InsufficientScrap;
            Hand = gear;
            Selected = null;
            var next = (string[])Offers.Clone();
            next[slot] = null;
            Offers = next;
            var held = (bool[])Held.Clone();
            held[slot] = false;
            Held = held;
            return WorkshopAction.Ok;
        }

        /// <summary>Holds or releases an offer. Free; a held offer survives rerolls and the next wave's shop until bought or released.</summary>
        public WorkshopAction ToggleHold(int slot)
        {
            if (Locked) return WorkshopAction.Locked;
            if (slot < 0 || slot >= Offers.Length || Offers[slot] == null) return WorkshopAction.NoOffer;
            var held = (bool[])Held.Clone();
            held[slot] = !held[slot];
            Held = held;
            return WorkshopAction.Ok;
        }

        /// <summary>True when every slot is held, so a reroll could not change anything.</summary>
        public bool AllHeld => Held.Length > 0 && Held.All(h => h);

        /// <summary>Undo an unplaced purchase for a full refund.</summary>
        public WorkshopAction CancelHand()
        {
            if (Hand == null) return WorkshopAction.NothingToPlace;
            Grant(Hand.Cost, "undo_buy", Hand.Id);
            Hand = null;
            return WorkshopAction.Ok;
        }

        public WorkshopAction Reroll()
        {
            if (Locked) return WorkshopAction.Locked;
            if (AllHeld) return WorkshopAction.AllHeld;
            if (!Spend(RerollPrice, "reroll", "shop")) return WorkshopAction.InsufficientScrap;
            RerollsTaken++;
            RollOffers();
            return WorkshopAction.Ok;
        }

        /// <summary>Places the gear in hand, selects/deselects a gear, or merges the selected gear into a matching one.</summary>
        public WorkshopAction TapCell(int x, int y)
        {
            if (Locked) return WorkshopAction.Locked;
            if (x < 0 || y < 0 || x >= Board.Width || y >= Board.Height) return WorkshopAction.Occupied;
            var node = Board.At(x, y);
            if (Hand != null)
            {
                if (node != null) return WorkshopAction.Occupied;
                PushUndo();
                Place(NewNode(Hand, x, y, 1));
                Hand = null;
                return WorkshopAction.Ok;
            }
            if (node == null || node.Kind == GearKind.Core)
            {
                Selected = null;
                return node == null ? WorkshopAction.NothingSelected : WorkshopAction.Ok;
            }
            var current = Selected;
            if (current == null || (current.Value.X == x && current.Value.Y == y))
            {
                if (current == null) Selected = (x, y);
                else Selected = null;
                return WorkshopAction.Ok;
            }
            var other = Board.At(current.Value.X, current.Value.Y);
            if (other.DefinitionId != node.DefinitionId || other.Tier != node.Tier)
            {
                Selected = (x, y);
                return WorkshopAction.NotMergeable;
            }
            if (node.Tier >= Rules.MaxTier) return WorkshopAction.MaxTier;
            var definition = Definition(node.DefinitionId);
            PushUndo();
            var nextInterval = definition.BaseIntervalTicks == 0 ? 0 : Rules.IntervalFor(definition.BaseIntervalTicks, node.Tier + 1);
            // The merged gear keeps the top-left cell, so its lane still follows its row.
            if (!Board.TryMerge(current.Value.X, current.Value.Y, x, y, Rules.MaxTier, nextInterval, out var merged, out _))
            {
                undo.RemoveAt(undo.Count - 1);
                return WorkshopAction.NotMergeable;
            }
            Selected = (merged.X, merged.Y);
            return WorkshopAction.Ok;
        }

        public WorkshopAction SellSelected()
        {
            if (Locked) return WorkshopAction.Locked;
            var node = Selected.HasValue ? Board.At(Selected.Value.X, Selected.Value.Y) : null;
            if (node == null) return WorkshopAction.NothingSelected;
            if (node.Kind == GearKind.Core) return WorkshopAction.CannotSellCore;
            var refund = SelectedSellValue;
            PushUndo(refund);
            Board.RemoveAt(node.X, node.Y);
            if (refund > 0) Grant(refund, "sell", node.Id);
            Selected = null;
            return WorkshopAction.Ok;
        }

        /// <summary>Called when the wave starts; returns any unplaced purchase as scrap.</summary>
        public void Lock()
        {
            if (Hand != null) CancelHand();
            Selected = null;
            undo.Clear();
            Locked = true;
        }

        /// <summary>
        /// Reopens the workshop between waves: pays the cleared wave's reward once per wave number through the ledger,
        /// resets the reroll price and rolls fresh offers around any held ones. The board is kept as built.
        /// </summary>
        public WorkshopAction BeginIntermission(int clearedWave, int rewardScrap)
        {
            if (!Locked) return WorkshopAction.Ok;
            if (rewardScrap > 0)
            {
                Wallet.Apply(new TxnRequest
                {
                    IdempotencyKey = "wave_reward:" + clearedWave, Type = "grant", Source = "wave_reward",
                    ReferenceId = "wave " + clearedWave, Deltas = new[] { new TxnDelta(BattleScrap, rewardScrap) },
                }, clock());
            }
            Locked = false;
            RerollsTaken = 0;
            RollOffers();
            return WorkshopAction.Ok;
        }

        /// <summary>
        /// Drops a dragged gear from <paramref name="from"/> onto <paramref name="to"/>: moves it to an empty cell,
        /// merges it into an identical gear, or is refused. Moving is free; the gear's lane follows its new row.
        /// </summary>
        public WorkshopAction Drop((int X, int Y) from, (int X, int Y) to)
        {
            if (Locked) return WorkshopAction.Locked;
            if (Hand != null) return WorkshopAction.HandFull;
            var node = Board.At(from.X, from.Y);
            if (node == null) return WorkshopAction.NothingSelected;
            if (to.X < 0 || to.Y < 0 || to.X >= Board.Width || to.Y >= Board.Height) return WorkshopAction.Occupied;
            if (from.X == to.X && from.Y == to.Y) return WorkshopAction.Ok;
            var target = Board.At(to.X, to.Y);
            if (target != null)
            {
                if (target.Kind == GearKind.Core) return WorkshopAction.Occupied;
                Selected = from;
                return TapCell(to.X, to.Y);
            }
            PushUndo();
            Board.RemoveAt(from.X, from.Y);
            Place(Moved(node, to.X, to.Y));
            Selected = to;
            return WorkshopAction.Ok;
        }

        /// <summary>Reverts the most recent place, move, merge or sell.</summary>
        public WorkshopAction Undo()
        {
            if (Locked) return WorkshopAction.Locked;
            if (undo.Count == 0) return WorkshopAction.NothingToUndo;
            var entry = undo[undo.Count - 1];
            if (entry.Hand != null && Hand != null) return WorkshopAction.HandFull;
            if (entry.ScrapGained > BattleScrapBalance) return WorkshopAction.InsufficientScrap;
            if (entry.ScrapGained > 0 && !Spend(entry.ScrapGained, "undo_sell", "undo")) return WorkshopAction.InsufficientScrap;
            undo.RemoveAt(undo.Count - 1);
            foreach (var node in Board.Nodes.ToList()) Board.RemoveAt(node.X, node.Y);
            foreach (var node in entry.Board) Place(Copy(node));
            Hand = entry.Hand ?? Hand;
            Selected = null;
            return WorkshopAction.Ok;
        }

        /// <summary>Network outcome of putting the hand gear, or the gear at <paramref name="from"/>, on (x, y), computed on a copy of the board.</summary>
        public PlacementPreview PreviewAt(int x, int y, (int X, int Y)? from = null)
        {
            var trial = new GearBoard(Board.Width, Board.Height);
            foreach (var node in Board.Nodes)
            {
                if (from.HasValue && node.X == from.Value.X && node.Y == from.Value.Y) continue;
                trial.TryPlace(Copy(node), out _);
            }
            var moving = from.HasValue ? Board.At(from.Value.X, from.Value.Y) : null;
            GearNode candidate = null;
            if (moving != null) candidate = Moved(moving, x, y);
            else if (Hand != null)
                candidate = new GearNode("__preview__", Hand.Kind, x, y, Hand.Ports, Hand.BaseIntervalTicks, 0, Hand.Id, 1,
                    Hand.OutputKind, Rules.LaneForRow(y), Hand.ProjectileDamage, Hand.ProjectileSpeedMmPerTick);
            if (candidate == null) return new PlacementPreview(false, null, 0, null);
            var occupant = trial.At(x, y);
            if (occupant != null)
            {
                var mergeable = occupant.DefinitionId == candidate.DefinitionId && occupant.Tier == candidate.Tier && occupant.Tier < Rules.MaxTier;
                return new PlacementPreview(mergeable, null, 0, null);
            }
            trial.TryPlace(candidate, out _);
            GearNetwork.Rebuild(trial).Nodes.TryGetValue(candidate.Id, out var result);
            return new PlacementPreview(true, result?.State, result?.EffectiveIntervalTicks ?? 0,
                candidate.OutputKind == GearOutputKind.None ? default(int?) : candidate.TargetLane);
        }

        private void PushUndo(int scrapGained = 0) =>
            undo.Add(new UndoEntry { Board = Board.Nodes.Select(Copy).ToList(), Hand = Hand, ScrapGained = scrapGained });

        private void Place(GearNode node)
        {
            if (!Board.TryPlace(node, out var error)) throw new InvalidOperationException(error);
        }

        private GearNode Copy(GearNode n) => Moved(n, n.X, n.Y);

        private GearNode Moved(GearNode n, int x, int y) =>
            new GearNode(n.Id, n.Kind, x, y, n.LocalPorts, n.BaseIntervalTicks, n.RotationQuarterTurns, n.DefinitionId, n.Tier, n.OutputKind,
                n.OutputKind == GearOutputKind.None ? n.TargetLane : Rules.LaneForRow(y), n.ProjectileDamage, n.ProjectileSpeedMmPerTick);

        private GearNode NewNode(GearDefinition gear, int x, int y, int tier) =>
            new GearNode(gear.Id + "#" + nextGearNumber++, gear.Kind, x, y, gear.Ports,
                gear.BaseIntervalTicks == 0 ? 0 : Rules.IntervalFor(gear.BaseIntervalTicks, tier), 0, gear.Id, tier,
                gear.OutputKind, Rules.LaneForRow(y), gear.ProjectileDamage, gear.ProjectileSpeedMmPerTick);

        private void RollOffers()
        {
            var pool = new HashSet<string>(Catalog.Where(g => Rules.ShopCategories.Contains(g.Category)).Select(g => g.Id), StringComparer.Ordinal);
            if (Held.Length != Shop.OfferCount) Held = new bool[Shop.OfferCount];
            string[] keep = null;
            if (Held.Any(h => h))
            {
                keep = new string[Held.Length];
                for (var i = 0; i < Held.Length; i++) keep[i] = Held[i] ? Offers[i] : null;
            }
            Offers = GearShop.Roll(rng, Catalog, Shop, pool, keep, Board.Nodes.Any(n => n.Kind == GearKind.Transmission));
        }

        private bool Spend(int amount, string type, string reference)
        {
            if (amount <= 0) return true;
            return Wallet.Apply(new TxnRequest
            {
                IdempotencyKey = type + ":" + nextTxn++, Type = "spend", Source = type, ReferenceId = reference,
                Deltas = new[] { new TxnDelta(BattleScrap, -amount) },
            }, clock()).Status == TxnStatus.Applied;
        }

        private void Grant(int amount, string type, string reference) =>
            Wallet.Apply(new TxnRequest
            {
                IdempotencyKey = type + ":" + nextTxn++, Type = "refund", Source = type, ReferenceId = reference,
                Deltas = new[] { new TxnDelta(BattleScrap, amount) },
            }, clock());

        private GearDefinition Definition(string id) =>
            Catalog.FirstOrDefault(g => g.Id == id) ?? throw new KeyNotFoundException("Unknown gear definition: " + id);
    }
}
