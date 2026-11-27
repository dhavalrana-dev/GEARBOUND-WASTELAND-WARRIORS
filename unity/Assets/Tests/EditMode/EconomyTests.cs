using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Gearbound.Core;
using Gearbound.Economy;
using NUnit.Framework;

namespace Gearbound.Tests
{
    /// <summary>Replays the same shared fixtures as flutter/test/economy and flutter/test/services.</summary>
    public sealed class EconomyTests
    {
        private static string Shared(string relative)
        {
            var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
            while (dir != null && !Directory.Exists(Path.Combine(dir.FullName, "shared"))) dir = dir.Parent;
            Assert.IsNotNull(dir);
            return File.ReadAllText(Path.Combine(dir.FullName, "shared", relative));
        }

        private static Dictionary<string, object> Obj(object o) => SharedJson.Obj(o, "fixture");
        private static int? NullableInt(Dictionary<string, object> o, string key) => o[key] is long v ? (int?)v : null;

        [Test]
        public void LedgerMatchesSharedTransactionCases()
        {
            var fixture = Obj(SharedJson.Parse(Shared("test-fixtures/reward_transaction_cases.json")));
            var currencies = SharedJson.Arr(Obj(SharedJson.Parse(Shared("economy/currencies.json"))), "currencies").Select(Obj).ToArray();
            var stacks = Obj(fixture["boosterMaxStack"]);
            var rules = new AssetRules
            {
                CurrencyMax = currencies.ToDictionary(c => SharedJson.Str(c, "id"), c => SharedJson.Long(c, "max")),
                PremiumCurrencies = new HashSet<string>(currencies.Where(c => SharedJson.Bool(c, "premium")).Select(c => SharedJson.Str(c, "id"))),
                BoosterMaxStack = stacks.Keys.ToDictionary(k => k, k => (long)stacks[k]),
            };

            foreach (var c in SharedJson.Arr(fixture, "cases").Select(Obj))
            {
                var wallet = new Wallet(rules);
                var step = 0;
                foreach (var s in SharedJson.Arr(c, "steps").Select(Obj))
                {
                    var r = Obj(s["request"]);
                    var e = Obj(s["expect"]);
                    var result = wallet.Apply(new TxnRequest
                    {
                        IdempotencyKey = SharedJson.Str(r, "key"), Type = SharedJson.Str(r, "type"), Source = SharedJson.Str(r, "source"),
                        Verification = SharedJson.Str(r, "verification") == "verified" ? TxnVerification.Verified : TxnVerification.Local,
                        Deltas = SharedJson.Arr(r, "deltas").Select(Obj).Select(d => new TxnDelta(SharedJson.Str(d, "asset"), SharedJson.Long(d, "amount"))).ToArray(),
                    }, new DateTime(2026, 11, 27, 0, 0, 0, DateTimeKind.Utc));
                    var where = $"{SharedJson.Str(c, "id")} step {step++}";
                    Assert.AreEqual(SharedJson.Str(e, "status"), result.Status.ToString().ToLowerInvariant(), where);
                    if (e.ContainsKey("reason")) Assert.AreEqual(SharedJson.Str(e, "reason"), result.Reason, where);
                    var balances = Obj(e["balances"]);
                    foreach (var key in balances.Keys) Assert.AreEqual((long)balances[key], wallet.Balance(key), $"{where} {key}");
                }
            }
        }

        [Test]
        public void AdPolicyMatchesSharedCases()
        {
            var policy = new AdPolicy(Shared("monetization/ad_policy.json"));
            Assert.IsFalse(policy.Enabled, "Ads must ship disabled until a real provider and consent flow exist.");
            var fixture = Obj(SharedJson.Parse(Shared("test-fixtures/ad_policy_cases.json")));
            foreach (var c in SharedJson.Arr(fixture, "interstitialCases").Select(Obj))
            {
                var s = Obj(c["state"]);
                var e = Obj(c["expect"]);
                var d = policy.Interstitial(new InterstitialState
                {
                    Context = SharedJson.Str(s, "context"), NowSeconds = SharedJson.Int(s, "nowSeconds"),
                    MissionsCompleted = SharedJson.Int(s, "missionsCompleted"), MissionsSinceLastInterstitial = SharedJson.Int(s, "missionsSinceLastInterstitial"),
                    LastInterstitialSeconds = NullableInt(s, "lastInterstitialSeconds"), InterstitialsThisSession = SharedJson.Int(s, "interstitialsThisSession"),
                    LastRewardedSeconds = NullableInt(s, "lastRewardedSeconds"), NoAds = SharedJson.Bool(s, "noAds"), ConsentReady = SharedJson.Bool(s, "consentReady"),
                });
                Assert.AreEqual(SharedJson.Bool(e, "show"), d.Allowed, SharedJson.Str(c, "id"));
                Assert.AreEqual(SharedJson.Str(e, "reason"), d.Reason, SharedJson.Str(c, "id"));
            }
            foreach (var c in SharedJson.Arr(fixture, "rewardedCases").Select(Obj))
            {
                var s = Obj(c["state"]);
                var e = Obj(c["expect"]);
                var d = policy.Rewarded(SharedJson.Str(c, "placement"), new RewardedState
                {
                    UsedToday = SharedJson.Int(s, "usedToday"), UsedThisMission = SharedJson.Int(s, "usedThisMission"),
                    LastUsedSeconds = NullableInt(s, "lastUsedSeconds"), NowSeconds = SharedJson.Int(s, "nowSeconds"), ConsentReady = SharedJson.Bool(s, "consentReady"),
                });
                Assert.AreEqual(SharedJson.Bool(e, "eligible"), d.Allowed, SharedJson.Str(c, "id"));
                Assert.AreEqual(SharedJson.Str(e, "reason"), d.Reason, SharedJson.Str(c, "id"));
            }
        }
    }
}
