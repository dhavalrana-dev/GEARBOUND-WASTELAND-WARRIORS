import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/data/shared_content.dart';
import 'package:gearbound/data/shared_rules.dart';
import 'package:gearbound/economy/economy_rules.dart';
import 'package:gearbound/features/campaign/campaign_hub_screen.dart';
import 'package:gearbound/features/workshop/mission_snapshot.dart';
import 'package:gearbound/features/workshop/workshop_controller.dart';
import 'package:gearbound/features/workshop/workshop_screen.dart';
import 'package:gearbound/game/gearbound_game.dart';
import 'package:gearbound/mechanical/gear_network.dart';
import 'package:gearbound/progression/campaign_progress.dart';
import 'package:gearbound/progression/campaign_store.dart';

String _shared(String rel) => File('../shared/$rel').readAsStringSync();

class _MemoryStore extends CampaignStore {
  _MemoryStore(this.progress, {this.checkpoint});
  final CampaignProgress progress;
  String? checkpoint;
  @override
  Future<CampaignProgress> load({DateTime? at}) async => progress;
  @override
  Future<void> save(CampaignProgress progress) async {}
  @override
  Future<String?> loadMissionCheckpoint() async => checkpoint;
  @override
  Future<void> saveMissionCheckpoint(String? encoded) async =>
      checkpoint = encoded;
}

void main() {
  final catalog = loadGears(_shared('gears/starter_gears.json'));
  final shop = loadShop(_shared('economy/shop.json'));
  final rules = WorkshopRules.fromJson(_shared('configs/gear_rules.json'));

  group('snapshot and controller state', () {
    test('MissionSnapshot round-trips through JSON', () {
      final board = GearBoard();
      final w = WorkshopController(
        board: board,
        catalog: catalog,
        shop: shop,
        rules: rules,
        seed: 5,
      );
      final snap = MissionSnapshot(
        levelId: 'copperwash-01',
        levelIndex: 0,
        waveIndex: 1,
        waveCount: 3,
        atIntermission: true,
        fortressHealth: 82,
        heroLane: 2,
        heroHealth: 64,
        heroSp: 40,
        scrapReward: 3,
        openingLanes: const [1, 0],
        board: [...board.nodes],
        workshop: w.toJson(),
      );
      final back = MissionSnapshot.tryDecode(snap.encode())!;
      expect(back.encode(), snap.encode());
      expect(back.board.map((n) => '${n.id}@${n.x},${n.y}'), [
        for (final n in board.nodes) '${n.id}@${n.x},${n.y}',
      ]);
    });

    test('garbage and other schema versions decode to null', () {
      expect(MissionSnapshot.tryDecode(null), isNull);
      expect(MissionSnapshot.tryDecode(''), isNull);
      expect(MissionSnapshot.tryDecode('{"schemaVersion": 99}'), isNull);
      expect(MissionSnapshot.tryDecode('not json'), isNull);
    });

    test('a restored shop continues the exact RNG and keeps claim keys', () {
      final original = WorkshopController(
        board: GearBoard(),
        catalog: catalog,
        shop: shop,
        rules: rules,
        seed: 11,
      )..reroll();
      original.lock();
      original.beginIntermission(clearedWave: 1, rewardScrap: 4);
      final restored = WorkshopController.restore(
        board: GearBoard(),
        catalog: catalog,
        shop: shop,
        rules: rules,
        json: original.toJson(),
      );
      expect(restored.battleScrap, original.battleScrap);
      expect(restored.offers, original.offers);
      expect(restored.rerollPrice, original.rerollPrice);
      original.reroll();
      restored.reroll();
      expect(restored.offers, original.offers);
      // The wave-1 reward key survived, so it cannot be paid again.
      restored.lock();
      restored.beginIntermission(clearedWave: 1, rewardScrap: 4);
      expect(restored.battleScrap, original.battleScrap);
      expect(restored.wallet.balance(Currency.alloy), 0);
    });

    test('BattleSession.restoreCheckpoint rejects impossible values', () {
      BattleSession fresh() {
        final board = GearBoard();
        final wave = WaveDefinition(id: 'w', spawns: const []);
        return BattleSession(
          board: board,
          network: GearNetwork.rebuild(board),
          wave: wave,
          laterWaves: [wave],
          combat: CombatSimulation(),
        );
      }

      bool restore(
        BattleSession s, {
        int wave = 0,
        bool at = false,
        int fort = 50,
      }) => s.restoreCheckpoint(
        waveIndex: wave,
        atIntermission: at,
        fortressHealth: fort,
        heroLane: 1,
        heroHealth: 50,
        heroSp: 0,
        scrapReward: 0,
      );
      expect(restore(fresh(), wave: 5), isFalse);
      expect(restore(fresh(), wave: 1, at: true), isFalse); // final wave
      expect(restore(fresh(), fort: 0), isFalse);
      expect(restore(fresh(), fort: 999), isFalse);
      final started = fresh()..start();
      expect(restore(started), isFalse);
      expect(restore(fresh()), isTrue);
    });
  });

  group('workshop screen', () {
    void usePhone(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
    }

    late SharedContent content;
    final saved = <MissionSnapshot?>[];

    Future<GearboundGame> pump(
      WidgetTester tester, {
      MissionSnapshot? resume,
      int streak = 0,
    }) async {
      content = (await tester.runAsync(() => SharedContent.load(rootBundle)))!;
      saved.clear();
      await tester.pumpWidget(
        MaterialApp(
          // A fresh key per pump: a relaunch must build a new screen state.
          home: WorkshopScreen(
            key: UniqueKey(),
            levelIndex: 0,
            progress: CampaignProgress(winStreak: streak),
            onProgressSaved: (_) async {},
            content: content,
            shopSeed: 3,
            resume: resume,
            onCheckpoint: (s) async => saved.add(s),
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

    testWidgets('a wave start saves a checkpoint; resuming restarts that wave '
        'paused, with the same locked board and opening soldiers', (
      tester,
    ) async {
      usePhone(tester);
      final game = await pump(tester, streak: 2);
      coverSideLanes(game);
      await tester.tap(find.text('START WAVE'));
      await tester.pump();
      final snap = saved.whereType<MissionSnapshot>().last;
      expect(snap.atIntermission, isFalse);
      expect(snap.waveIndex, 0);
      expect(snap.openingLanes, [1, 0]);
      final cells = [for (final n in snap.board) '${n.id}@${n.x},${n.y}']
        ..sort();

      // Simulate the OS killing the app, then relaunching with the checkpoint.
      final resumed = await pump(
        tester,
        resume: MissionSnapshot.tryDecode(snap.encode()),
        streak: 2,
      );
      final s = resumed.session;
      expect(s.phase, BattlePhase.combat);
      expect(s.waveIndex, 0);
      expect(resumed.simulationPaused, isTrue);
      expect(find.text('PAUSED'), findsOneWidget);
      expect(
        [for (final n in s.board.nodes) '${n.id}@${n.x},${n.y}']..sort(),
        cells,
      );
      expect(
        s.combat.combatants.where((u) => u.id >= 90000 && u.id < 100000).length,
        2,
      );
      // The board is locked: a tap cannot place or select anything.
      resumed.onCellTap!(4, 4);
      expect(s.board.at(4, 4), isNull);
    });

    testWidgets('an intermission checkpoint resumes into the rebuild phase '
        'without paying the wave reward twice', (tester) async {
      usePhone(tester);
      final game = await pump(tester);
      coverSideLanes(game);
      await tester.tap(find.text('START WAVE'));
      await tester.pump();
      final s = game.session;
      for (var t = 0; t < 3600 && s.phase == BattlePhase.combat; t++) {
        s.tick();
      }
      game.onSessionChanged!();
      await tester.pump();
      final snap = saved.whereType<MissionSnapshot>().last;
      expect(snap.atIntermission, isTrue);
      expect(snap.waveIndex, 0);
      final scrap = (snap.workshop!['wallet'] as Map)['balances'] as Map;

      final resumed = await pump(
        tester,
        resume: MissionSnapshot.tryDecode(snap.encode()),
      );
      expect(resumed.session.phase, BattlePhase.intermission);
      expect(find.textContaining('Mission resumed'), findsOneWidget);
      expect(
        find.text('${scrap[Currency.battleScrap]} battle scrap'),
        findsOneWidget,
      );
      // Starting the next wave works and moves to wave 2.
      await tester.tap(find.text('START WAVE'));
      await tester.pump();
      expect(resumed.session.waveIndex, 1);
      expect(saved.whereType<MissionSnapshot>().last.waveIndex, 1);
    });

    testWidgets('victory clears the checkpoint', (tester) async {
      usePhone(tester);
      final game = await pump(tester);
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
      game.onSessionChanged!();
      await tester.pump();
      expect(saved.last, isNull);
    });

    testWidgets('a checkpoint that no longer fits the data is discarded', (
      tester,
    ) async {
      usePhone(tester);
      final bogus = MissionSnapshot(
        levelId: 'copperwash-01',
        levelIndex: 0,
        waveIndex: 0,
        waveCount: 99, // the mission no longer has 99 waves
        atIntermission: false,
        fortressHealth: 100,
        heroLane: 1,
        heroHealth: 100,
        heroSp: 0,
        scrapReward: 0,
        openingLanes: const [],
        board: const [],
        workshop: const {},
      );
      final game = await pump(tester, resume: bogus);
      expect(saved, [null]);
      expect(game.session.phase, BattlePhase.preparation);
      expect(game.session.board.at(0, 2)?.kind, GearKind.core);
    });
  });

  testWidgets('the route shows an interrupted mission; Abandon resets the '
      'streak and clears it', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final progress = CampaignProgress(winStreak: 3);
    final snap = MissionSnapshot(
      levelId: 'copperwash-01',
      levelIndex: 0,
      waveIndex: 0,
      waveCount: 3,
      atIntermission: true,
      fortressHealth: 90,
      heroLane: 1,
      heroHealth: 100,
      heroSp: 0,
      scrapReward: 3,
      openingLanes: const [],
      board: const [],
      workshop: const {},
    );
    final store = _MemoryStore(progress, checkpoint: snap.encode());
    await tester.pumpWidget(MaterialApp(home: CampaignHubScreen(store: store)));
    // The hub loads bundled assets with real I/O; let it finish.
    for (
      var i = 0;
      i < 20 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('MISSION INTERRUPTED'), findsOneWidget);
    expect(find.textContaining('rebuild before wave 2'), findsOneWidget);

    await tester.tap(find.text('ABANDON'));
    await tester.pumpAndSettle();
    expect(progress.winStreak, 0);
    expect(store.checkpoint, anyOf(isNull, isEmpty));
    expect(find.textContaining('MISSION INTERRUPTED'), findsNothing);
  });
}
