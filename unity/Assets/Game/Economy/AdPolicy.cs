using System;
using System.Collections.Generic;
using System.Linq;
using Gearbound.Core;

namespace Gearbound.Economy
{
    public struct AdDecision
    {
        public bool Allowed;
        public string Reason;
        public AdDecision(bool allowed, string reason) { Allowed = allowed; Reason = reason; }
    }

    public sealed class InterstitialState
    {
        public string Context;
        public int NowSeconds;
        public int MissionsCompleted;
        public int MissionsSinceLastInterstitial;
        public int? LastInterstitialSeconds;
        public int InterstitialsThisSession;
        public int? LastRewardedSeconds;
        public bool NoAds;
        public bool ConsentReady;
    }

    public sealed class RewardedState
    {
        public int UsedToday;
        public int UsedThisMission;
        public int? LastUsedSeconds;
        public int NowSeconds;
        public bool ConsentReady;
    }

    /// <summary>Pure ad placement rules; mirrors flutter/lib/services/ads/ad_policy.dart.</summary>
    public sealed class AdPolicy
    {
        private sealed class Placement { public bool Enabled; public int DailyCap; public int PerMissionCap; public int CooldownSeconds; }

        private readonly HashSet<string> allowedContexts;
        private readonly int adFreeFirstMissions, minMissionsBetween, minSecondsBetween, maxPerSession, suppressAfterRewarded;
        private readonly Dictionary<string, Placement> placements;
        public bool Enabled { get; }

        public AdPolicy(string json)
        {
            var root = SharedJson.Obj(SharedJson.Parse(json), "ad_policy");
            if (SharedJson.Int(root, "schemaVersion") != 1) throw new FormatException("Unsupported ad policy schema.");
            Enabled = SharedJson.Bool(root, "enabled");
            var i = SharedJson.Obj(root["interstitial"], "interstitial");
            allowedContexts = new HashSet<string>(SharedJson.Arr(i, "allowedContexts").Cast<string>(), StringComparer.Ordinal);
            adFreeFirstMissions = SharedJson.Int(i, "adFreeFirstMissions");
            minMissionsBetween = SharedJson.Int(i, "minMissionsBetween");
            minSecondsBetween = SharedJson.Int(i, "minSecondsBetween");
            maxPerSession = SharedJson.Int(i, "maxPerSession");
            suppressAfterRewarded = SharedJson.Int(i, "suppressSecondsAfterRewarded");
            placements = SharedJson.Arr(root, "rewardedPlacements").Select(p => SharedJson.Obj(p, "placement")).ToDictionary(
                p => SharedJson.Str(p, "id"),
                p => new Placement
                {
                    Enabled = SharedJson.Bool(p, "enabled"), DailyCap = SharedJson.Int(p, "dailyCap"),
                    PerMissionCap = SharedJson.Int(p, "perMissionCap"), CooldownSeconds = SharedJson.Int(p, "cooldownSeconds"),
                }, StringComparer.Ordinal);
        }

        public AdDecision Interstitial(InterstitialState s)
        {
            if (!allowedContexts.Contains(s.Context)) return new AdDecision(false, "context_not_allowed");
            if (s.NoAds) return new AdDecision(false, "no_ads_entitlement");
            if (!s.ConsentReady) return new AdDecision(false, "consent_not_ready");
            if (s.MissionsCompleted <= adFreeFirstMissions) return new AdDecision(false, "ad_free_onboarding");
            if (s.InterstitialsThisSession >= maxPerSession) return new AdDecision(false, "session_cap");
            if (s.LastInterstitialSeconds.HasValue && s.MissionsSinceLastInterstitial < minMissionsBetween) return new AdDecision(false, "mission_spacing");
            if (s.LastInterstitialSeconds.HasValue && s.NowSeconds - s.LastInterstitialSeconds.Value < minSecondsBetween) return new AdDecision(false, "time_spacing");
            if (s.LastRewardedSeconds.HasValue && s.NowSeconds - s.LastRewardedSeconds.Value < suppressAfterRewarded) return new AdDecision(false, "recent_rewarded");
            return new AdDecision(true, "eligible");
        }

        public AdDecision Rewarded(string placementId, RewardedState s)
        {
            if (!placements.TryGetValue(placementId, out var p)) return new AdDecision(false, "unknown_placement");
            if (!p.Enabled) return new AdDecision(false, "placement_disabled");
            if (!s.ConsentReady) return new AdDecision(false, "consent_not_ready");
            if (p.DailyCap > 0 && s.UsedToday >= p.DailyCap) return new AdDecision(false, "daily_cap");
            if (p.PerMissionCap > 0 && s.UsedThisMission >= p.PerMissionCap) return new AdDecision(false, "mission_cap");
            if (p.CooldownSeconds > 0 && s.LastUsedSeconds.HasValue && s.NowSeconds - s.LastUsedSeconds.Value < p.CooldownSeconds) return new AdDecision(false, "cooldown");
            return new AdDecision(true, "eligible");
        }
    }
}
