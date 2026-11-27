import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/data/shared_content.dart';
import 'package:gearbound/data/shared_rules.dart';
import 'package:gearbound/features/workshop/workshop_screen.dart';
import 'package:gearbound/game/gearbound_game.dart';
import 'package:gearbound/progression/campaign_progress.dart';

/// Wind-up (telegraphed) attacks and cleave. Mirrors Unity's TelegraphTests.
void main() {
  Combatant boss({int windup = 5, bool cleave = false}) => Combatant(
    id: 500,
    faction: CombatFaction.enemy,
    lane: 1,
    positionMm: 1000,
    health: 1000,
    armor: 0,
    damage: 10,
    attackRangeMm: 300,
    movementMmPerTick: 0,
    attackIntervalTicks: 30,
    windupTicks: windup,
    cleave: cleave,
  );

  Combatant ally(int id, {int lane = 1, int pos = 900}) => Combatant(
    id: id,
    faction: CombatFaction.friendly,
    lane: lane,
    positionMm: pos,
    health: 100,
    armor: 0,
    damage: 1,
    attackRangeMm: 0, // cannot reach the boss, so it never hits back
    movementMmPerTick: 0,
    attackIntervalTicks: 10,
  );

  test('the hit lands exactly when the wind-up ends', () {
    final sim = CombatSimulation(worldLengthMm: 2000)
      ..add(boss())
      ..add(ally(10));
    final target = sim.combatants.firstWhere((u) => u.id == 10);
    sim.tick(); // commits: wind-up starts
    final attacker = sim.combatants.firstWhere((u) => u.id == 500);
    expect(attacker.windupRemaining, 5);
    expect(attacker.state, CombatState.attacking);
    for (var i = 0; i < 4; i++) {
      sim.tick();
    }
    expect(target.health, 100); // still winding up
    sim.tick(); // wind-up ends
    expect(target.health, 90);
    expect(attacker.windupRemaining, 0);
  });

  test('leaving the lane during the wind-up dodges the hit', () {
    final sim = CombatSimulation(worldLengthMm: 2000)
      ..add(boss())
      ..add(ally(10));
    final target = sim.combatants.firstWhere((u) => u.id == 10);
    sim.tick();
    sim.tick();
    expect(sim.moveLane(10, 0), isTrue);
    for (var i = 0; i < 6; i++) {
      sim.tick();
    }
    expect(target.health, 100);
  });

  test('cleave hits everyone in range in the lane, nobody elsewhere', () {
    final sim = CombatSimulation(worldLengthMm: 2000)
      ..add(boss(cleave: true))
      ..add(ally(10))
      ..add(ally(11, pos: 750))
      ..add(ally(12, lane: 0))
      ..add(ally(13, pos: 600)); // out of range (400 mm away)
    for (var i = 0; i < 6; i++) {
      sim.tick();
    }
    int hp(int id) => sim.combatants.firstWhere((u) => u.id == id).health;
    expect([hp(10), hp(11), hp(12), hp(13)], [90, 90, 100, 100]);
  });

  test('a winding-up attacker holds its position', () {
    final mover = Combatant(
      id: 501,
      faction: CombatFaction.enemy,
      lane: 1,
      positionMm: 1000,
      health: 1000,
      armor: 0,
      damage: 10,
      attackRangeMm: 300,
      movementMmPerTick: 50,
      attackIntervalTicks: 30,
      windupTicks: 5,
    );
    final sim = CombatSimulation(worldLengthMm: 2000)
      ..add(mover)
      ..add(ally(10));
    sim.tick();
    sim.combatants.firstWhere((u) => u.id == 10).health = 0; // target gone
    final held = mover.positionMm;
    sim.tick();
    sim.tick();
    expect(mover.positionMm, held);
  });

  test('a wind-up must be shorter than the attack interval', () {
    expect(() => boss(windup: 30), throwsArgumentError);
    expect(() => boss(windup: -1), throwsArgumentError);
  });

  test('Scrapmaw loads with its telegraph and cleave from enemies.json', () {
    final enemies = loadEnemies(
      File('../shared/enemies/enemies.json').readAsStringSync(),
    );
    final scrapmaw = enemies.firstWhere((e) => e.id == 'boss.scrapmaw');
    expect(scrapmaw.windupTicks, 18);
    expect(scrapmaw.cleave, isTrue);
    expect(
      enemies
          .where((e) => e.id != 'boss.scrapmaw')
          .every((e) => e.windupTicks == 0 && !e.cleave),
      isTrue,
    );
  });

  testWidgets('a winding-up enemy renders its telegraph without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final content = (await tester.runAsync(
      () => SharedContent.load(rootBundle),
    ))!;
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
    final game = tester
        .widget<GameWidget<GearboundGame>>(
          find.byType(GameWidget<GearboundGame>),
        )
        .game!;
    await tester.tap(find.text('START WAVE'));
    await tester.pump();
    final winding = boss()..windupRemaining = 3;
    game.session.combat.add(winding);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
  });
}
