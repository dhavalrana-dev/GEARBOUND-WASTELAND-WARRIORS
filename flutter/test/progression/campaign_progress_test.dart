import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/progression/campaign_progress.dart';

void main() {
  group('CampaignProgress', () {
    final monday = DateTime(2026, 11, 23, 12);

    test('unlocks route nodes and preserves the best star score', () {
      final progress = CampaignProgress();
      expect(progress.unlockedLevelIndex, 0);
      expect(progress.recordVictory('copperwash-02', 3, at: monday), isFalse);
      expect(progress.recordVictory('copperwash-01', 2, at: monday), isTrue);
      expect(progress.unlockedLevelIndex, 1);
      expect(progress.recordVictory('copperwash-01', 1, at: monday), isTrue);
      expect(progress.starsFor('copperwash-01'), 2);
      expect(
        progress.scrap,
        10,
      ); // first-clear payout plus the daily clear contract
    });

    test('weekly event score uses only each level best and grants tier rewards once', () {
      final progress = CampaignProgress();
      progress.recordVictory('copperwash-01', 2, at: monday);
      progress.recordVictory('copperwash-01', 3, at: monday);
      progress.recordVictory('copperwash-01', 1, at: monday);
      expect(progress.eventPoints, 3);
      expect(progress.claimEventTier(3), isTrue);
      expect(progress.claimEventTier(3), isFalse);
      expect(
        progress.scrap,
        5 + 5 + 5,
      ); // first-clear, clear contract, and event tier
    });

    test('daily contracts reward once and reset on the next day', () {
      final progress = CampaignProgress();
      progress.recordSetup(5, at: monday);
      progress.recordSetup(5, at: monday);
      progress.recordLaneCommand(at: monday);
      progress.recordLaneCommand(at: monday);
      progress.recordLaneCommand(at: monday);
      expect(progress.contractValue('daily-power'), 4);
      expect(progress.contractValue('daily-command'), 3);
      expect(
        progress.claimedContracts,
        containsAll(['daily-power', 'daily-command']),
      );
      expect(progress.scrap, 8);

      progress.recordLaneCommand(at: monday.add(const Duration(days: 1)));
      expect(progress.contractValue('daily-command'), 1);
      expect(progress.claimedContracts, isEmpty);
    });

    test('powered-gear contract measures the best single setup, not accumulated sessions', () {
      final progress = CampaignProgress();
      progress.recordSetup(2, at: monday);
      progress.recordSetup(3, at: monday);
      progress.recordSetup(2, at: monday);
      expect(progress.contractValue('daily-power'), 3);
      expect(progress.claimedContracts, isNot(contains('daily-power')));
      progress.recordSetup(4, at: monday);
      expect(progress.contractValue('daily-power'), 4);
      expect(progress.claimedContracts, contains('daily-power'));
    });

    test('event score and tier claims reset at the weekly boundary', () {
      final progress = CampaignProgress();
      progress.recordVictory('copperwash-01', 3, at: monday);
      progress.claimEventTier(3);
      progress.recordLaneCommand(at: monday.add(const Duration(days: 7)));
      expect(progress.eventPoints, 0);
      expect(progress.claimedEventTiers, isEmpty);
      expect(progress.contractValue('daily-command'), 1);
    });

    test('save data round-trips without losing campaign or event state', () {
      final progress = CampaignProgress();
      progress.recordVictory('copperwash-01', 3, at: monday);
      progress.claimEventTier(3);
      final loaded = CampaignProgress.decode(progress.encode());
      expect(loaded.bestStars, progress.bestStars);
      expect(loaded.scrap, progress.scrap);
      expect(loaded.eventPoints, 3);
      expect(loaded.claimedEventTiers, {3});
      expect(loaded.unlockedLevelIndex, 1);
    });
  });
}
