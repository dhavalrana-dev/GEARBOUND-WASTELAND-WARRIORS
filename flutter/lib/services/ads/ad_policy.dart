import 'dart:convert';

/// Pure, engine-independent ad placement rules. Mirrors Unity's
/// `Gearbound.Monetization.AdPolicy`; both replay
/// shared/test-fixtures/ad_policy_cases.json. No SDK code lives here.
class AdDecision {
  const AdDecision(this.allowed, this.reason);
  final bool allowed;
  final String reason;
}

class InterstitialRules {
  const InterstitialRules({
    required this.allowedContexts,
    required this.adFreeFirstMissions,
    required this.minMissionsBetween,
    required this.minSecondsBetween,
    required this.maxPerSession,
    required this.suppressSecondsAfterRewarded,
  });

  final Set<String> allowedContexts;
  final int adFreeFirstMissions;
  final int minMissionsBetween;
  final int minSecondsBetween;
  final int maxPerSession;
  final int suppressSecondsAfterRewarded;
}

class RewardedPlacement {
  const RewardedPlacement({
    required this.id,
    required this.reward,
    required this.dailyCap,
    required this.perMissionCap,
    required this.cooldownSeconds,
    required this.enabled,
  });

  final String id;
  final Map<String, Object?> reward;

  /// 0 means no cap.
  final int dailyCap;
  final int perMissionCap;
  final int cooldownSeconds;
  final bool enabled;
}

class InterstitialState {
  const InterstitialState({
    required this.context,
    required this.nowSeconds,
    required this.missionsCompleted,
    required this.missionsSinceLastInterstitial,
    required this.lastInterstitialSeconds,
    required this.interstitialsThisSession,
    required this.lastRewardedSeconds,
    required this.noAds,
    required this.consentReady,
  });

  final String context;
  final int nowSeconds;
  final int missionsCompleted;
  final int missionsSinceLastInterstitial;
  final int? lastInterstitialSeconds;
  final int interstitialsThisSession;
  final int? lastRewardedSeconds;
  final bool noAds;
  final bool consentReady;
}

class RewardedState {
  const RewardedState({
    required this.usedToday,
    required this.usedThisMission,
    required this.lastUsedSeconds,
    required this.nowSeconds,
    required this.consentReady,
  });

  final int usedToday;
  final int usedThisMission;
  final int? lastUsedSeconds;
  final int nowSeconds;
  final bool consentReady;
}

class AdPolicy {
  const AdPolicy({
    required this.enabled,
    required this.interstitial,
    required this.rewarded,
  });

  /// Global kill switch; false until a real provider and consent flow ship.
  final bool enabled;
  final InterstitialRules interstitial;
  final Map<String, RewardedPlacement> rewarded;

  factory AdPolicy.fromJson(String source) {
    final root = jsonDecode(source) as Map<String, Object?>;
    if (root['schemaVersion'] != 1) {
      throw const FormatException('Unsupported ad policy schema.');
    }
    final i = root['interstitial'] as Map<String, Object?>;
    return AdPolicy(
      enabled: root['enabled'] as bool? ?? false,
      interstitial: InterstitialRules(
        allowedContexts: (i['allowedContexts'] as List).cast<String>().toSet(),
        adFreeFirstMissions: i['adFreeFirstMissions'] as int,
        minMissionsBetween: i['minMissionsBetween'] as int,
        minSecondsBetween: i['minSecondsBetween'] as int,
        maxPerSession: i['maxPerSession'] as int,
        suppressSecondsAfterRewarded: i['suppressSecondsAfterRewarded'] as int,
      ),
      rewarded: {
        for (final p
            in (root['rewardedPlacements'] as List)
                .cast<Map<String, Object?>>())
          p['id'] as String: RewardedPlacement(
            id: p['id'] as String,
            reward: p['reward'] as Map<String, Object?>,
            dailyCap: p['dailyCap'] as int,
            perMissionCap: p['perMissionCap'] as int,
            cooldownSeconds: p['cooldownSeconds'] as int,
            enabled: p['enabled'] as bool,
          ),
      },
    );
  }

  /// Rule order is fixed so every engine reports the same reason.
  AdDecision interstitialDecision(InterstitialState s) {
    final r = interstitial;
    if (!r.allowedContexts.contains(s.context)) {
      return const AdDecision(false, 'context_not_allowed');
    }
    if (s.noAds) return const AdDecision(false, 'no_ads_entitlement');
    if (!s.consentReady) return const AdDecision(false, 'consent_not_ready');
    if (s.missionsCompleted <= r.adFreeFirstMissions) {
      return const AdDecision(false, 'ad_free_onboarding');
    }
    if (s.interstitialsThisSession >= r.maxPerSession) {
      return const AdDecision(false, 'session_cap');
    }
    if (s.lastInterstitialSeconds != null &&
        s.missionsSinceLastInterstitial < r.minMissionsBetween) {
      return const AdDecision(false, 'mission_spacing');
    }
    if (s.lastInterstitialSeconds != null &&
        s.nowSeconds - s.lastInterstitialSeconds! < r.minSecondsBetween) {
      return const AdDecision(false, 'time_spacing');
    }
    if (s.lastRewardedSeconds != null &&
        s.nowSeconds - s.lastRewardedSeconds! <
            r.suppressSecondsAfterRewarded) {
      return const AdDecision(false, 'recent_rewarded');
    }
    return const AdDecision(true, 'eligible');
  }

  AdDecision rewardedDecision(String placementId, RewardedState s) {
    final p = rewarded[placementId];
    if (p == null) return const AdDecision(false, 'unknown_placement');
    if (!p.enabled) return const AdDecision(false, 'placement_disabled');
    if (!s.consentReady) return const AdDecision(false, 'consent_not_ready');
    if (p.dailyCap > 0 && s.usedToday >= p.dailyCap) {
      return const AdDecision(false, 'daily_cap');
    }
    if (p.perMissionCap > 0 && s.usedThisMission >= p.perMissionCap) {
      return const AdDecision(false, 'mission_cap');
    }
    if (p.cooldownSeconds > 0 &&
        s.lastUsedSeconds != null &&
        s.nowSeconds - s.lastUsedSeconds! < p.cooldownSeconds) {
      return const AdDecision(false, 'cooldown');
    }
    return const AdDecision(true, 'eligible');
  }
}
