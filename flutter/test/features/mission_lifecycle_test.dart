import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/data/shared_content.dart';
import 'package:gearbound/features/workshop/workshop_screen.dart';
import 'package:gearbound/game/gearbound_game.dart';
import 'package:gearbound/mechanical/gear_network.dart';
import 'package:gearbound/progression/campaign_progress.dart';

void main() {
  void usePhone(WidgetTester tester, {bool landscape = false}) {
    tester.view.physicalSize = landscape
        ? const Size(3200, 1080)
        : const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
  }

  late SharedContent content;
  late CampaignProgress progress;
  late int saves;

  /// Launcher route with a button that opens the workshop, so Back has
  /// somewhere to go.
  Future<GearboundGame> open(WidgetTester tester, {int streak = 0}) async {
    content = (await tester.runAsync(() => SharedContent.load(rootBundle)))!;
    progress = CampaignProgress(winStreak: streak);
    saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkshopScreen(
                      levelIndex: 0,
                      progress: progress,
                      onProgressSaved: (_) async => saves++,
                      content: content,
                      shopSeed: 3,
                    ),
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return tester
        .widget<GameWidget<GearboundGame>>(
          find.byType(GameWidget<GearboundGame>),
        )
        .game!;
  }

  void coverSideLanes(GearboundGame game) {
    for (final (id, y) in [('side-a', 1), ('side-b', 3)]) {
      game.session.board.place(
        GearNode(
          id: id,
          definitionId: 'unit.rivetguard',
          kind: GearKind.output,
          x: 0,
          y: y,
          localPorts: Direction.values.toSet(),
          baseIntervalTicks: 90,
          outputKind: GearOutputKind.spawnInfantry,
          targetLane: content.workshopRules.laneForRow(y),
        ),
      );
    }
    game.refreshNetwork();
  }

  testWidgets('pause freezes the simulation and resume continues it', (
    tester,
  ) async {
    usePhone(tester);
    final game = await open(tester);
    await tester.tap(find.text('START WAVE'));
    await tester.pump(const Duration(milliseconds: 500));
    final running = game.session.elapsedTicks;
    expect(running, greaterThan(0));

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    final frozen = game.session.elapsedTicks;
    await tester.pump(const Duration(seconds: 1));
    expect(game.session.elapsedTicks, frozen);
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('START WAVE'), findsNothing);

    await tester.tap(find.text('RESUME'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(game.session.elapsedTicks, greaterThan(frozen));
    expect(find.text('PAUSED'), findsNothing);
  });

  testWidgets('backgrounding during combat pauses until the player resumes', (
    tester,
  ) async {
    usePhone(tester);
    final game = await open(tester);
    await tester.tap(find.text('START WAVE'));
    await tester.pump(const Duration(milliseconds: 200));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(game.simulationPaused, isTrue);
    final frozen = game.session.elapsedTicks;
    await tester.pump(const Duration(seconds: 1));
    expect(game.session.elapsedTicks, frozen);
    expect(find.text('PAUSED'), findsOneWidget);
  });

  testWidgets('backgrounding during preparation does not pause anything', (
    tester,
  ) async {
    usePhone(tester);
    final game = await open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(game.simulationPaused, isFalse);
    expect(find.text('PAUSED'), findsNothing);
  });

  testWidgets('a long frame stall is capped instead of fast-forwarded', (
    tester,
  ) async {
    usePhone(tester);
    final game = await open(tester);
    await tester.tap(find.text('START WAVE'));
    await tester.pump();
    final before = game.session.elapsedTicks;
    game.update(10); // a 10-second stall
    final caught = game.session.elapsedTicks - before;
    expect(caught, lessThanOrEqualTo(8));
    expect(caught, greaterThan(0));
  });

  testWidgets('system Back before the first wave leaves freely', (
    tester,
  ) async {
    usePhone(tester);
    await open(tester, streak: 2);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('OPEN'), findsOneWidget);
    expect(progress.winStreak, 2);
  });

  testWidgets('system Back mid-mission opens the pause menu instead', (
    tester,
  ) async {
    usePhone(tester);
    final game = await open(tester, streak: 2);
    await tester.tap(find.text('START WAVE'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('OPEN'), findsNothing);
    expect(game.simulationPaused, isTrue);
    expect(progress.winStreak, 2);
  });

  testWidgets('abandoning asks first, resets the streak and returns', (
    tester,
  ) async {
    usePhone(tester);
    await open(tester, streak: 2);
    await tester.tap(find.text('START WAVE'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    await tester.tap(find.text('ABANDON MISSION…'));
    await tester.pump();
    expect(find.textContaining('Overclock Streak resets'), findsOneWidget);
    await tester.tap(find.text('KEEP PLAYING'));
    await tester.pump();
    expect(progress.winStreak, 2);

    await tester.tap(find.text('ABANDON MISSION…'));
    await tester.pump();
    await tester.tap(find.text('ABANDON MISSION'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('OPEN'), findsOneWidget);
    expect(progress.winStreak, 0);
    expect(saves, greaterThan(0));
  });

  testWidgets('rotating mid-combat keeps the same game, board and clock', (
    tester,
  ) async {
    usePhone(tester);
    final game = await open(tester);
    await tester.tap(find.text('START WAVE'));
    await tester.pump(const Duration(milliseconds: 300));
    final ticks = game.session.elapsedTicks;
    final cells = [for (final n in game.session.board.nodes) n.id]..sort();

    tester.view.physicalSize = const Size(3200, 1080);
    await tester.pump(const Duration(milliseconds: 300));
    final after = tester
        .widget<GameWidget<GearboundGame>>(
          find.byType(GameWidget<GearboundGame>),
        )
        .game!;
    expect(identical(after, game), isTrue);
    // Rotation is not backgrounding: the mission keeps running.
    expect(game.simulationPaused, isFalse);
    expect(game.session.elapsedTicks, greaterThan(ticks));
    expect([for (final n in game.session.board.nodes) n.id]..sort(), cells);
    expect(tester.takeException(), isNull);
  });

  testWidgets('victory is recorded exactly once', (tester) async {
    usePhone(tester);
    final game = await open(tester);
    coverSideLanes(game);
    await tester.tap(find.text('START WAVE'));
    await tester.pump();
    final s = game.session;
    while (s.phase == BattlePhase.combat ||
        s.phase == BattlePhase.intermission) {
      if (s.phase == BattlePhase.intermission) s.start();
      for (var t = 0; t < 3600 && s.phase == BattlePhase.combat; t++) {
        s.tick();
      }
    }
    expect(s.phase, BattlePhase.victory);
    for (var i = 0; i < 3; i++) {
      game.onSessionChanged!();
    }
    await tester.pump();
    expect(progress.winStreak, 1);
    final scrap = progress.scrap;
    game.onSessionChanged!();
    expect(progress.scrap, scrap);
    expect(progress.starsFor('copperwash-01'), 3);
  });

  testWidgets('Wrench Quake enables at full SP and fires through the session', (
    tester,
  ) async {
    usePhone(tester);
    final game = await open(tester);
    await tester.tap(find.text('START WAVE'));
    await tester.pump();
    final s = game.session;
    FilledButton quake() => tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('WRENCH QUAKE'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(quake().onPressed, isNull);
    s.heroSp = s.special.spMax;
    game.onSessionChanged!();
    await tester.pump();
    expect(quake().onPressed, isNotNull);
    await tester.tap(find.text('WRENCH QUAKE'));
    await tester.pump();
    expect(s.specialReady, isFalse); // queued
    s.tick();
    expect(s.heroSp, lessThan(s.special.spMax));
  });
}
