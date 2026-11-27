using System;
using System.Collections.Generic;
using System.Linq;

namespace Gearbound.Economy
{
    public enum TxnStatus { Applied, Duplicate, Rejected }
    public enum TxnVerification { Local, Verified }

    public sealed class AssetRules
    {
        public IReadOnlyDictionary<string, long> CurrencyMax { get; set; } = new Dictionary<string, long>();
        public ISet<string> PremiumCurrencies { get; set; } = new HashSet<string>();
        public IReadOnlyDictionary<string, long> BoosterMaxStack { get; set; } = new Dictionary<string, long>();
        public bool IsKnown(string asset) => CurrencyMax.ContainsKey(asset) || BoosterMaxStack.ContainsKey(asset);
    }

    public struct TxnDelta
    {
        public string Asset;
        public long Amount;
        public TxnDelta(string asset, long amount) { Asset = asset; Amount = amount; }
    }

    public sealed class TxnRequest
    {
        public string IdempotencyKey;
        public string Type;
        public string Source;
        public string ReferenceId = "";
        public TxnVerification Verification = TxnVerification.Local;
        public IReadOnlyList<TxnDelta> Deltas = Array.Empty<TxnDelta>();
    }

    public sealed class LedgerEntry
    {
        public string TransactionId;
        public string IdempotencyKey;
        public string ProfileId;
        public string Asset;
        public long Amount;
        public string Type;
        public string Source;
        public string ReferenceId;
        public TxnVerification Verification;
        public string CreatedAtUtc;
    }

    public sealed class TxnResult
    {
        public TxnStatus Status;
        public string Reason = "";
        public IReadOnlyList<LedgerEntry> Entries = Array.Empty<LedgerEntry>();
    }

    /// <summary>
    /// Idempotent all-or-nothing ledger; same rules as flutter/lib/economy/wallet.dart, checked by
    /// shared/test-fixtures/reward_transaction_cases.json. Order: duplicate → invalid →
    /// unverified premium → insufficient → overflow. Boosters clamp at their stack cap.
    /// </summary>
    public sealed class Wallet
    {
        public const int LedgerRetention = 500;
        private readonly Dictionary<string, long> balances = new Dictionary<string, long>(StringComparer.Ordinal);
        private readonly List<LedgerEntry> ledger = new List<LedgerEntry>();
        private readonly HashSet<string> processed = new HashSet<string>(StringComparer.Ordinal);
        public AssetRules Rules { get; }
        public string ProfileId { get; }
        public long Sequence { get; private set; }
        public IReadOnlyList<LedgerEntry> Ledger => ledger;

        public Wallet(AssetRules rules, string profileId = "local")
        {
            Rules = rules ?? throw new ArgumentNullException(nameof(rules));
            ProfileId = profileId;
        }

        public long Balance(string asset) => balances.TryGetValue(asset, out var value) ? value : 0;
        public bool HasProcessed(string key) => processed.Contains(key);

        public TxnResult Apply(TxnRequest request, DateTime utcNow)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (request.IdempotencyKey != null && processed.Contains(request.IdempotencyKey))
                return new TxnResult { Status = TxnStatus.Duplicate, Entries = ledger.Where(e => e.IdempotencyKey == request.IdempotencyKey).ToArray() };

            var seen = new HashSet<string>(StringComparer.Ordinal);
            if (string.IsNullOrEmpty(request.IdempotencyKey) || request.Deltas == null || request.Deltas.Count == 0
                || request.Deltas.Any(d => d.Amount == 0 || d.Asset == null || !Rules.IsKnown(d.Asset) || !seen.Add(d.Asset)))
                return Reject("invalid");
            if (request.Verification != TxnVerification.Verified && request.Deltas.Any(d => d.Amount > 0 && Rules.PremiumCurrencies.Contains(d.Asset)))
                return Reject("unverified_premium");

            var next = new Dictionary<string, long>(StringComparer.Ordinal);
            foreach (var d in request.Deltas)
            {
                var result = Balance(d.Asset) + d.Amount;
                if (result < 0) return Reject("insufficient");
                if (Rules.CurrencyMax.TryGetValue(d.Asset, out var max) && result > max) return Reject("overflow");
                next[d.Asset] = Rules.BoosterMaxStack.TryGetValue(d.Asset, out var stack) && result > stack ? stack : result;
            }

            var createdAt = utcNow.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ", System.Globalization.CultureInfo.InvariantCulture);
            var entries = new List<LedgerEntry>();
            foreach (var d in request.Deltas)
            {
                Sequence++;
                entries.Add(new LedgerEntry
                {
                    TransactionId = "txn-" + Sequence, IdempotencyKey = request.IdempotencyKey, ProfileId = ProfileId,
                    Asset = d.Asset, Amount = next[d.Asset] - Balance(d.Asset), Type = request.Type, Source = request.Source,
                    ReferenceId = request.ReferenceId ?? "", Verification = request.Verification, CreatedAtUtc = createdAt,
                });
            }
            foreach (var pair in next)
            {
                if (pair.Value == 0) balances.Remove(pair.Key);
                else balances[pair.Key] = pair.Value;
            }
            processed.Add(request.IdempotencyKey);
            ledger.AddRange(entries);
            if (ledger.Count > LedgerRetention) ledger.RemoveRange(0, ledger.Count - LedgerRetention);
            return new TxnResult { Status = TxnStatus.Applied, Entries = entries };
        }

        private static TxnResult Reject(string reason) => new TxnResult { Status = TxnStatus.Rejected, Reason = reason };
    }
}
