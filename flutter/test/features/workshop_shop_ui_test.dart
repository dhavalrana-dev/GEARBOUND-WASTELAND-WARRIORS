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
import 'package:gearbound/progression/encounters.dart';

void main() {
  void useTallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
  }

  Future<GearboundGame> pumpWorkshop(
    WidgetTester tester,
    SharedContent content,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkshopScreen(
          levelIndex: 0,
          progress: CampaignProgress(),
          onProgressSaved: (_) async {},
          content: content,
          shopSeed: 3,
        ),
      ),
    );
    await tester.pump();
    return tester
        .widget<GameWidget<GearboundGame>>(
          find.byType(GameWidget<GearboundGame>),
        )
        .game!;
  }

  testWidgets('buy an offer, place it, then the wave locks the shop', (
    tester,
  ) async {
    useTallPhone(tester);
    final content = (await tester.runAsync(
      () => SharedContent.load(rootBundle),
    ))!;
    final game = await pumpWorkshop(tester, content);
    final board = game.session.board;

    expect(find.text('12 battle scrap'), findsOneWidget);
    expect(find.text('MOVE PRESS'), findsNothing);
    expect(board.at(0, 2)?.kind, GearKind.core);

    // Seed 3 with no transmission on the board guarantees a coupler offer.
    final couplerSlot = [0, 1, 2].firstWhere(
      (slot) => find
          .descendant(
            of: find.byKey(ValueKey('offer-$slot')),
            matching: find.text('Drive Coupler'),
          )
          .evaluate()
          .isNotEmpty,
      orElse: () => -1,
    );
    expect(couplerSlot, isNot(-1));
    await tester.tap(find.byKey(ValueKey('offer-$couplerSlot')));
    await tester.pump();
    expect(find.text('10 battle scrap'), findsOneWidget);
    expect(find.textContaining('Placing Drive Coupler'), findsOneWidget);
    expect(find.text('CANCEL (+2)'), findsOneWidget);

    game.onCellTap!(2, 2);
    await tester.pump();
    expect(board.at(2, 2)?.definitionId, 'drive.coupler');
    expect(
      game.session.network.nodes[board.at(2, 2)!.id]?.state,
      NetworkState.powered,
    );

    // Select the starter press and sell it.
    game.onCellTap!(1, 2);
    await tester.pump();
    expect(find.text('SELL (+2)'), findsOneWidget);
    await tester.tap(find.text('SELL (+2)'));
    await tester.pump();
    expect(board.at(1, 2), isNull);
    expect(find.text('12 battle scrap'), findsOneWidget);

    await tester.tap(find.text('START WAVE'));
    await tester.pump();
    expect(game.session.phase, BattlePhase.combat);
    expect(find.textContaining('battle scrap'), findsNothing);
    game.onCellTap!(3, 3);
    expect(board.at(3, 3), isNull);
  });

  testWidgets('drag hooks move a gear, show status, and undo restores it', (
    tester,
  ) async {
    useTallPhone(tester);
    final content = (await tester.runAsync(
      () => SharedContent.load(rootBundle),
    ))!;
    final game = await pumpWorkshop(tester, content);
    final board = game.session.board;

    expect(game.onDragStartCell!(0, 2), isFalse); // the core cannot be dragged
    expect(game.onDragStartCell!(1, 2), isTrue);
    expect(game.previewCell!(0, 1), (valid: true, powered: true));
    expect(game.previewCell!(4, 4), (valid: true, powered: false));
    expect(game.previewCell!(0, 2)?.valid, isFalse);
    game.onDropCell!(0, 1);
    await tester.pump();
    expect(board.at(0, 1)?.definitionId, 'unit.rivetguard');
    expect(board.at(1, 2), isNull);
    expect(find.textContaining('Powered · lane 1'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    await tester.pump();
    expect(board.at(1, 2)?.definitionId, 'unit.rivetguard');
    expect(board.at(0, 1), isNull);
    expect(find.text('Nothing to undo.'), findsNothing);
  });

  testWidgets(
    'output gear labels include tier, rate and lane in both layouts',
    (tester) async {
      useTallPhone(tester);
      final content = (await tester.runAsync(
        () => SharedContent.load(rootBundle),
      ))!;
      final game = await pumpWorkshop(tester, content);
      await tester.pump(const Duration(milliseconds: 50));
      final view = game.world.children.whereType<WorkshopBoardView>().single;
      final output = game.session.board.nodes.firstWhere(
        (node) => node.outputKind != GearOutputKind.none,
      );

      for (final size in [Vector2(432, 1280), Vector2(1280, 432)]) {
        view.resizeTo(size);
        expect(
          view.outputRateLabel(output),
          matches(RegExp(r'^T\d+  \d+\.\d{2}/s$')),
        );
        expect(view.outputLaneLabel(output), 'L${output.targetLane + 1}');
      }
    },
  );

  testWidgets('a real pointer drag on the canvas moves a gear', (tester) async {
    useTallPhone(tester);
    final content = (await tester.runAsync(
      () => SharedContent.load(rootBundle),
    ))!;
    final game = await pumpWorkshop(tester, content);
    await tester.pump(const Duration(milliseconds: 50));
    final view = game.world.children.whereType<WorkshopBoardView>().single;

    Offset centerOf(int x, int y) {
      // Average every probe point that maps to the cell.
      var sx = 0.0, sy = 0.0, n = 0;
      for (var px = 0.0; px < view.size.x; px += 2) {
        for (var py = 0.0; py < view.size.y; py += 2) {
          if (view.cellAt(Vector2(px, py)) == (x: x, y: y)) {
            sx += px;
            sy += py;
            n++;
          }
        }
      }
      expect(n, greaterThan(0));
      final origin = tester.getTopLeft(find.byType(GameWidget<GearboundGame>));
      return origin + Offset(sx / n, sy / n);
    }

    final from = centerOf(1, 2);
    final to = centerOf(0, 1);
    await tester.dragFrom(from, to - from);
    // Let the gesture recognizers' timers finish before teardown.
    await tester.pump(const Duration(milliseconds: 100));
    final board = game.session.board;
    expect(board.at(0, 1)?.definitionId, 'unit.rivetguard');
    expect(board.at(1, 2), isNull);
  });

  testWidgets('clearing wave 1 opens a rebuild phase, then wave 2 starts', (
    tester,
  ) async {
    useTallPhone(tester);
    final content = (await tester.runAsync(
      () => SharedContent.load(rootBundle),
    ))!;
    final game = await pumpWorkshop(tester, content);
    final session = game.session;
    // Cover both side lanes (a build measured to clear wave 1).
    for (final (id, y) in [('side-a', 1), ('side-b', 3)]) {
      session.board.place(
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
    expect(find.textContaining('Wave 1/3'), findsOneWidget);

    await tester.tap(find.text('START WAVE'));
    await tester.pump();
    expect(
      find.textContaining('battle scrap'),
      findsNothing,
    ); // shop hidden in combat
    for (var t = 0; t < 3600 && session.phase == BattlePhase.combat; t++) {
      session.tick();
    }
    expect(session.phase, BattlePhase.intermission);
    game.onSessionChanged!();
    await tester.pump();

    expect(find.textContaining('Wave 1/3 · REBUILD'), findsOneWidget);
    expect(
      find.textContaining('Wave 1 cleared: +3 battle scrap'),
      findsOneWidget,
    );
    expect(find.textContaining('battle scrap'), findsWidgets);
    // The board survived and can be edited again.
    expect(session.board.at(0, 1), isNotNull);
    expect(game.onDragStartCell!(0, 1), isTrue);
    game.onDragCancelled!();

    await tester.tap(find.text('START WAVE'));
    await tester.pump();
    expect(session.phase, BattlePhase.combat);
    expect(session.waveIndex, 1);
    expect(find.textContaining('Wave 2/3'), findsOneWidget);
  });

  for (final (name, size) in [
    ('phone landscape', const Size(2400, 1080)),
    ('small phone portrait', const Size(720, 1520)),
    ('tablet landscape', const Size(2732, 2048)),
  ]) {
    testWidgets('shop layout does not overflow on $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = size.width > 2000 && size.height > 2000
          ? 2.0
          : 2.5;
      addTearDown(tester.view.reset);
      final content = (await tester.runAsync(
        () => SharedContent.load(rootBundle),
      ))!;
      await pumpWorkshop(tester, content);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('battle scrap'), findsOneWidget);
    });
  }

  testWidgets('falls back to the demo board when shared content is missing', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: WorkshopScreen(
          levelIndex: 0,
          progress: CampaignProgress(),
          onProgressSaved: (_) async {},
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('battle scrap'), findsNothing);
    expect(find.text('START WAVE'), findsOneWidget);
  });

  test('board taps map to the drawn cells in portrait and landscape', () {
    final session = BattleSession(
      board: GearBoard(),
      network: GearNetwork.rebuild(GearBoard()),
      wave: encounterForLevel(0),
    );
    final view = WorkshopBoardView(session);
    for (final size in [Vector2(400, 800), Vector2(900, 420)]) {
      view.resizeTo(size);
      // Find the cell size by probing: the top-left cell must map to (0, 0)
      // and a point far outside must map to nothing.
      final hits = <({int x, int y})>{};
      for (var px = 0.0; px < size.x; px += 4) {
        for (var py = 0.0; py < size.y; py += 4) {
          final cell = view.cellAt(Vector2(px, py));
          if (cell != null) hits.add(cell);
        }
      }
      expect(hits, hasLength(25), reason: '$size');
      expect(view.cellAt(Vector2(-10, -10)), isNull);
    }
  });
}
