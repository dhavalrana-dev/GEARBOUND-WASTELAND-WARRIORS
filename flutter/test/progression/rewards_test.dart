import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/progression/campaign_progress.dart';
import 'package:gearbound/progression/rewards.dart';

void main() {
  final monday = DateTime(2026, 11, 23, 12);

  group('Overclock Streak', () {
    test('grows per victory, caps, and resets on defeat', () {
      final p = CampaignProgress();
      p.recordVictory('copperwash-01', 1, at: monday);
      p.recordVictory('copperwash-02', 1, at: monday);
      p.recordVictory('copperwash-03', 1, at: monday);
      p.recordVictory('copperwash-04', 1, at: monday);
      expect(p.winStreak, winStreakMaxLevel);
      p.recordDefeat();
      expect(p.winStreak, 0);
    });

    test('rejected victories do not grow the streak', () {
      final p = CampaignProgress();
      expect(p.recordVictory('copperwash-05', 3, at: monday), isFalse);
      expect(p.winStreak, 0);
    });

    test('opening soldiers follow streak lane order then vanguard lanes', () {
      expect(openingSoldierLanes(streakLevel: 0, vanguard: false), isEmpty);
      expect(openingSoldierLanes(streakLevel: 2, vanguard: false), [1, 0]);
      expect(openingSoldierLanes(streakLevel: 9, vanguard: true), [
        1,
        0,
        2,
        0,
        1,
        2,
      ]);
    });
  });

  group('Star chests', () {
    test('open once at the threshold with fixed contents', () {
      final p = CampaignProgress(
        bestStars: {'copperwash-01': 3, 'copperwash-02': 2},
      );
      expect(p.claimStarChest(6), isFalse); // 5 stars
      p.bestStars['copperwash-03'] = 1;
      expect(p.claimStarChest(6), isTrue);
      expect(p.claimStarChest(6), isFalse);
      expect(p.scrap, 10);
      expect(p.boosterCount(vanguardBoosterId), 1);
      expect(p.claimStarChest(7), isFalse); // not a chest milestone
    });
  });

  group('Supply Log', () {
    test(
      'claims once per day and pauses instead of resetting on missed days',
      () {
        final p = CampaignProgress();
        expect(p.claimLogin(at: monday), isTrue);
        expect(p.claimLogin(at: monday.add(const Duration(hours: 3))), isFalse);
        expect(p.scrap, 3);
        // Skip four days: the next claim is still day two, not day one.
        expect(p.claimLogin(at: monday.add(const Duration(days: 5))), isTrue);
        expect(p.loginStep, 2);
        expect(p.boosterCount(vanguardBoosterId), 1);
      },
    );

    test('loops after the seventh day', () {
      final p = CampaignProgress();
      for (var day = 0; day < 8; day++) {
        p.claimLogin(at: monday.add(Duration(days: day)));
      }
      expect(p.loginStep, 8);
      expect(p.nextLoginReward, same(loginTrackDays[1]));
    });
  });

  group('Boosters', () {
    test('consume only what was earned and respect the stack cap', () {
      final p = CampaignProgress(boosters: {vanguardBoosterId: 1});
      expect(p.consumeBooster(vanguardBoosterId), isTrue);
      expect(p.consumeBooster(vanguardBoosterId), isFalse);
      final full = CampaignProgress(
        boosters: {vanguardBoosterId: boosterMaxStack(vanguardBoosterId)},
        bestStars: {'copperwash-01': 3, 'copperwash-02': 3},
      );
      full.claimStarChest(6);
      expect(
        full.boosterCount(vanguardBoosterId),
        boosterMaxStack(vanguardBoosterId),
      );
    });
  });

  test('save v2 round-trips gamification state and loads v1 saves', () {
    final p = CampaignProgress(
      bestStars: {'copperwash-01': 3, 'copperwash-02': 3},
    );
    p.recordVictory('copperwash-03', 2, at: monday);
    p.claimStarChest(6);
    p.claimLogin(at: monday);
    final loaded = CampaignProgress.decode(p.encode());
    expect(loaded.winStreak, 1);
    expect(loaded.boosters, p.boosters);
    expect(loaded.claimedStarChests, {6});
    expect(loaded.loginStep, 1);
    expect(loaded.canClaimLogin(at: monday), isFalse);

    final legacy = CampaignProgress.decode(
      '{"scrap":4,"bestStars":{"copperwash-01":2}}',
    );
    expect(legacy.scrap, 4);
    expect(legacy.winStreak, 0);
    expect(legacy.boosters, isEmpty);
  });

  test('Dart reward tuning matches shared/events/progression_rewards.json', () {
    final json = jsonDecode(
      File('../shared/events/progression_rewards.json').readAsStringSync(),
    ) as Map<String, Object?>;
    Map<String, int> ints(Object? m) =>
        (m as Map<String, Object?>).map((k, v) => MapEntry(k, v as int));

    final boosters = (json['boosters'] as List).cast<Map<String, Object?>>();
    expect(boosters.map((b) => [b['id'], b['name'], b['maxStack']]).toList(), [
      for (final b in boosterDefinitions) [b.id, b.name, b.maxStack],
    ]);
    final streak = json['winStreak'] as Map<String, Object?>;
    expect(streak['maxLevel'], winStreakMaxLevel);
    expect(streak['streakSoldierLaneOrder'], streakSoldierLaneOrder);
    expect(
      (json['starChests'] as List)
          .cast<Map<String, Object?>>()
          .map((c) => [c['stars'], c['scrap'], ints(c['boosters'])])
          .toList(),
      [
        for (final c in starChests)
          [c.stars, c.reward.scrap, c.reward.boosters],
      ],
    );
    final days = ((json['loginTrack'] as Map)['days'] as List)
        .cast<Map<String, Object?>>();
    expect(days.map((d) => [d['scrap'], ints(d['boosters'])]).toList(), [
      for (final d in loginTrackDays) [d.scrap, d.boosters],
    ]);
    expect(
      (json['dailyContracts'] as List)
          .cast<Map<String, Object?>>()
          .map((c) => [c['id'], c['title'], c['target'], c['scrapReward']])
          .toList(),
      [
        for (final c in dailyContracts)
          [c.id, c.title, c.target, c.scrapReward],
      ],
    );
    expect(
      (json['weeklyEventTiers'] as List)
          .cast<Map<String, Object?>>()
          .map((t) => [t['points'], t['scrap']])
          .toList(),
      [
        for (final t in eventRewardTiers) [t.points, t.scrap],
      ],
    );
  });
}
