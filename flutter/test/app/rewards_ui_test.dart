import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/app/gearbound_app.dart';
import 'package:gearbound/progression/campaign_progress.dart';
import 'package:gearbound/progression/campaign_store.dart';
import 'package:gearbound/progression/rewards.dart';

class _MemoryStore extends CampaignStore {
  _MemoryStore(this.progress);
  final CampaignProgress progress;
  int saves = 0;

  @override
  Future<CampaignProgress> load({DateTime? at}) async => progress;

  @override
  Future<void> save(CampaignProgress progress) async => saves++;
}

void main() {
  void useTallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'hub shows streak and lets the player claim Supply Log and chest',
    (tester) async {
      useTallPhone(tester);
      final progress = CampaignProgress(
        winStreak: 2,
        bestStars: {'copperwash-01': 3, 'copperwash-02': 3},
      );
      final store = _MemoryStore(progress);
      await tester.pumpWidget(
        MaterialApp(home: CampaignHubScreen(store: store)),
      );
      await tester.pumpAndSettle();

      expect(find.text('OVERCLOCK STREAK · LEVEL 2/3'), findsOneWidget);
      expect(find.text('Supply Log · Day 1'), findsOneWidget);
      expect(find.text('Star chest · 6/6★'), findsOneWidget);

      await tester.ensureVisible(find.text('CLAIM').first);
      await tester.tap(find.text('CLAIM').first);
      await tester.pumpAndSettle();
      expect(progress.loginStep, 1);
      expect(find.text('TOMORROW'), findsOneWidget);

      await tester.ensureVisible(find.text('OPEN'));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(progress.claimedStarChests, {6});
      expect(progress.boosterCount(vanguardBoosterId), 1);
      expect(progress.scrap, 3 + 10);
      expect(find.text('Star chest · 6/12★'), findsOneWidget);
      expect(store.saves, greaterThanOrEqualTo(2));
    },
  );

  testWidgets(
    'workshop loadout consumes an equipped Vanguard Drop at wave start',
    (tester) async {
      useTallPhone(tester);
      final progress = CampaignProgress(boosters: {vanguardBoosterId: 1});
      await tester.pumpWidget(
        MaterialApp(
          home: WorkshopScreen(
            levelIndex: 0,
            progress: progress,
            onProgressSaved: (_) async {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Streak 0: +0 soldiers at start'), findsOneWidget);
      expect(find.text('Vanguard ×1'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('START WAVE'));
      await tester.pump();

      expect(progress.boosterCount(vanguardBoosterId), 0);
      expect(find.text('3 opening soldiers deployed'), findsOneWidget);
    },
  );

  testWidgets('workshop leaves boosters untouched when not equipped', (
    tester,
  ) async {
    useTallPhone(tester);
    final progress = CampaignProgress(
      winStreak: 1,
      boosters: {vanguardBoosterId: 2},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WorkshopScreen(
          levelIndex: 0,
          progress: progress,
          onProgressSaved: (_) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('START WAVE'));
    await tester.pump();

    expect(progress.boosterCount(vanguardBoosterId), 2);
    expect(find.text('1 opening soldier deployed'), findsOneWidget);
  });
}
