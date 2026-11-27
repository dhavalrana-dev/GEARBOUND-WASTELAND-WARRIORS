import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/economy/economy_rules.dart';
import 'package:gearbound/economy/wallet.dart';
import 'package:gearbound/services/ads/ad_policy.dart';
import 'package:gearbound/services/ads/ad_provider.dart';

void main() {
  final policy = AdPolicy.fromJson(
    File('../shared/monetization/ad_policy.json').readAsStringSync(),
  );
  final fixture = jsonDecode(
    File('../shared/test-fixtures/ad_policy_cases.json').readAsStringSync(),
  ) as Map<String, Object?>;

  test('ads ship disabled until a real provider and consent flow exist', () {
    expect(policy.enabled, isFalse);
  });

  group('interstitial policy fixture', () {
    for (final c
        in (fixture['interstitialCases'] as List)
            .cast<Map<String, Object?>>()) {
      test(c['id'] as String, () {
        final s = c['state'] as Map<String, Object?>;
        final e = c['expect'] as Map<String, Object?>;
        final decision = policy.interstitialDecision(
          InterstitialState(
            context: s['context'] as String,
            nowSeconds: s['nowSeconds'] as int,
            missionsCompleted: s['missionsCompleted'] as int,
            missionsSinceLastInterstitial:
                s['missionsSinceLastInterstitial'] as int,
            lastInterstitialSeconds: s['lastInterstitialSeconds'] as int?,
            interstitialsThisSession: s['interstitialsThisSession'] as int,
            lastRewardedSeconds: s['lastRewardedSeconds'] as int?,
            noAds: s['noAds'] as bool,
            consentReady: s['consentReady'] as bool,
          ),
        );
        expect([decision.allowed, decision.reason], [e['show'], e['reason']]);
      });
    }
  });

  group('rewarded policy fixture', () {
    for (final c
        in (fixture['rewardedCases'] as List).cast<Map<String, Object?>>()) {
      test(c['id'] as String, () {
        final s = c['state'] as Map<String, Object?>;
        final e = c['expect'] as Map<String, Object?>;
        final decision = policy.rewardedDecision(
          c['placement'] as String,
          RewardedState(
            usedToday: s['usedToday'] as int,
            usedThisMission: s['usedThisMission'] as int,
            lastUsedSeconds: s['lastUsedSeconds'] as int?,
            nowSeconds: s['nowSeconds'] as int,
            consentReady: s['consentReady'] as bool,
          ),
        );
        expect(
          [decision.allowed, decision.reason],
          [e['eligible'], e['reason']],
        );
      });
    }
  });

  group('RewardedAdController with the mock provider', () {
    const reward = [TxnDelta(Currency.workshopScrap, 10)];

    test('mock provider never claims to be live', () {
      expect(MockAdProvider().isLive, isFalse);
    });

    test('grants once even when the SDK fires the callback twice', () async {
      final wallet = Wallet(rules: defaultAssetRules());
      final ads = MockAdProvider(earnedCallbacks: 2);
      final controller = RewardedAdController(provider: ads, wallet: wallet);
      final first = await controller.run(
        placementId: 'rewarded.daily_supply',
        offerId: '2026-11-27#1',
        eligible: true,
        reward: reward,
      );
      final retry = await controller.run(
        placementId: 'rewarded.daily_supply',
        offerId: '2026-11-27#1',
        eligible: true,
        reward: reward,
      );
      expect(first, RewardedFlowResult.granted);
      expect(retry, RewardedFlowResult.alreadyGranted);
      expect(ads.shows, 1);
      expect(wallet.balance(Currency.workshopScrap), 10);
    });

    test('dismissing early, no fill and SDK failure grant nothing', () async {
      for (final (provider, expected) in [
        (
          MockAdProvider(outcome: RewardedOutcome.dismissedEarly),
          RewardedFlowResult.notEarned,
        ),
        (MockAdProvider(fill: false), RewardedFlowResult.unavailable),
        (
          MockAdProvider(outcome: RewardedOutcome.failedToShow),
          RewardedFlowResult.unavailable,
        ),
      ]) {
        final wallet = Wallet(rules: defaultAssetRules());
        final result =
            await RewardedAdController(provider: provider, wallet: wallet).run(
              placementId: 'rewarded.daily_supply',
              offerId: 'x',
              eligible: true,
              reward: reward,
            );
        expect(result, expected);
        expect(wallet.balance(Currency.workshopScrap), 0);
      }
    });

    test('ineligible offers never show an ad', () async {
      final ads = MockAdProvider();
      final result =
          await RewardedAdController(
            provider: ads,
            wallet: Wallet(rules: defaultAssetRules()),
          ).run(
            placementId: 'rewarded.daily_supply',
            offerId: 'x',
            eligible: false,
            reward: reward,
          );
      expect(result, RewardedFlowResult.notEligible);
      expect(ads.shows, 0);
    });

    test('ad rewards can never mint premium currency locally', () async {
      final wallet = Wallet(rules: defaultAssetRules());
      final result =
          await RewardedAdController(
            provider: MockAdProvider(),
            wallet: wallet,
          ).run(
            placementId: 'rewarded.daily_supply',
            offerId: 'alloy-attempt',
            eligible: true,
            reward: const [TxnDelta(Currency.alloy, 50)],
          );
      expect(result, RewardedFlowResult.notEarned);
      expect(wallet.balance(Currency.alloy), 0);
    });
  });
}
