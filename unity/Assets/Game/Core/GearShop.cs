using System;
using System.Collections.Generic;
using System.Linq;

namespace Gearbound.Core
{
    /// <summary>
    /// Seeded preparation-phase shop. Rules (shared with Dart and tools/simulation/reference_rules.py):
    /// pool = catalog minus excluded categories, filtered by unlocks and positive rarity weight, ordered by ordinal ID.
    /// Each unlocked slot draws once from the pool entries below the per-offer copy cap (weighted by rarity).
    /// If the board lacks the guaranteed category and no offer has it, the last unlocked slot becomes the
    /// cheapest gear of that category; this guarantee consumes no randomness.
    /// </summary>
    public static class GearShop
    {
        public static string[] Roll(SeededRandom rng, IEnumerable<GearDefinition> catalog, ShopConfig config,
            ISet<string> unlockedIds = null, IReadOnlyList<string> lockedOffers = null, bool boardHasGuaranteedCategory = true)
        {
            if (rng == null || catalog == null || config == null) throw new ArgumentNullException("Shop inputs cannot be null.");
            var count = config.OfferCount;
            if (lockedOffers != null && lockedOffers.Count != count) throw new ArgumentException("Locked offers must match the offer count.", nameof(lockedOffers));
            var all = catalog.ToArray();
            var byId = all.ToDictionary(g => g.Id, StringComparer.Ordinal);
            var excluded = new HashSet<string>(config.ExcludedCategories, StringComparer.Ordinal);
            var pool = all
                .Where(g => !excluded.Contains(g.Category) && (unlockedIds == null || unlockedIds.Contains(g.Id)) && Weight(config, g) > 0)
                .OrderBy(g => g.Id, StringComparer.Ordinal)
                .ToArray();

            var offers = new string[count];
            for (var i = 0; i < count; i++) offers[i] = lockedOffers?[i];

            for (var slot = 0; slot < count; slot++)
            {
                if (lockedOffers?[slot] != null) continue;
                var candidates = pool.Where(g => offers.Count(o => o == g.Id) < config.MaxCopiesPerOffer).ToArray();
                if (candidates.Length == 0) { offers[slot] = null; continue; }
                var roll = rng.NextInt(candidates.Sum(g => Weight(config, g)));
                foreach (var gear in candidates)
                {
                    roll -= Weight(config, gear);
                    if (roll < 0) { offers[slot] = gear.Id; break; }
                }
            }

            var category = config.GuaranteedCategory;
            if (!string.IsNullOrEmpty(category) && !boardHasGuaranteedCategory
                && !offers.Any(o => o != null && byId[o].Category == category))
            {
                var lastUnlocked = Enumerable.Range(0, count).Where(i => lockedOffers?[i] == null).DefaultIfEmpty(-1).Last();
                var option = pool.Where(g => g.Category == category).OrderBy(g => g.Cost).ThenBy(g => g.Id, StringComparer.Ordinal).FirstOrDefault();
                if (lastUnlocked >= 0 && option != null) offers[lastUnlocked] = option.Id;
            }
            return offers;
        }

        public static int RerollCost(ShopConfig config, int rerollsTaken)
        {
            if (rerollsTaken < 0) throw new ArgumentOutOfRangeException(nameof(rerollsTaken));
            return Math.Min(config.RerollCostCap, config.RerollBaseCost + config.RerollCostStep * rerollsTaken);
        }

        /// <summary>Sale value rounds down; refund applies to the gear's purchase cost.</summary>
        public static int SellValue(ShopConfig config, GearDefinition gear) => gear.Cost * config.SellRefundPercent / 100;

        private static int Weight(ShopConfig config, GearDefinition gear) =>
            gear.Rarity != null && config.RarityWeights.TryGetValue(gear.Rarity, out var weight) ? weight : 0;
    }
}
