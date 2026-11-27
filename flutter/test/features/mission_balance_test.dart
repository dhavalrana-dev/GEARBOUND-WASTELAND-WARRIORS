import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/core/seeded_random.dart';
import 'package:gearbound/data/shared_rules.dart';
import 'package:gearbound/features/workshop/workshop_controller.dart';
import 'package:gearbound/mechanical/gear_network.dart';
import 'package:gearbound/progression/encounters.dart';

String _shared(String rel) => File('../shared/$rel').readAsStringSync();

/// Balance guards for route node `copperwash-01` (shared mission
/// `copperwash_01`), measured with headless simulation. These document the
/// current tuning; change them only with a recorded balance decision.
void main() {
  final rules = WorkshopRules.fromJson(_shared('configs/gear_rules.json'));
  final enemies = loadEnemies(_shared('enemies/enemies.json'));
  final catalog = loadGears(_shared('gears/starter_gears.json'));
  final shop = loadShop(_shared('economy/shop.json'));
  final waves = [
    for (final w in loadMissionWaves(_shared('waves/copperwash_01.json')))
      buildWave(w, enemies),
  ];

  GearNode press(String id, int x, int y) => GearNode(
    id: id,
    definitionId: 'unit.rivetguard',
    kind: GearKind.output,
    x: x,
    y: y,
    localPorts: Direction.values.toSet(),
    baseIntervalTicks: 90,
    outputKind: GearOutputKind.spawnInfantry,
    targetLane: rules.laneForRow(y),
  );

  BattleSession mission(List<GearNode> extra, {int? heroLane}) {
    final board = GearBoard()
      ..place(
        GearNode(
          id: 'core',
          definitionId: 'core.wayfarer',
          kind: GearKind.core,
          x: 0,
          y: 2,
          localPorts: Direction.values.toSet(),
        ),
      )
      ..place(press('starter', 1, 2));
    for (final g in extra) {
      board.place(g);
    }
    final s = BattleSession(
      board: board,
      network: GearNetwork.rebuild(board),
      wave: waves.first,
      laterWaves: waves.skip(1).toList(),
      combat: CombatSimulation(worldLengthMm: 10000),
    );
    if (heroLane != null) s.moveHeroToLane(heroLane);
    return s;
  }

  List<String> play(BattleSession s) {
    final log = <String>[];
    while (true) {
      s.start();
      for (var t = 0; t < 3600 && s.phase == BattlePhase.combat; t++) {
        s.tick();
      }
      log.add('${s.phase.name}@${s.combat.fortressHealth}');
      if (s.phase != BattlePhase.intermission) return log;
    }
  }

  test('route node 1 wave 1 is unchanged from the scripted encounter', () {
    String key(WaveSpawnEvent e) =>
        '${e.tick}:${e.lane}:${e.health}:${e.damage}';
    expect(waves.first.spawns.map(key), encounterForLevel(0).spawns.map(key));
    expect(waves, hasLength(3));
  });

  test('the starter board alone, with an idle hero, loses wave 1', () {
    expect(play(mission([])).first, 'defeat@0');
  });

  test(
    'one bought press plus moving the hero to the open lane wins wave 1',
    () {
      final s = mission([press('a', 0, 1)], heroLane: 2);
      s.start();
      for (var t = 0; t < 3600 && s.phase == BattlePhase.combat; t++) {
        s.tick();
      }
      expect(s.phase, BattlePhase.intermission);
      expect(s.combat.fortressHealth, 100);
    },
  );

  test(
    'covering both side lanes clears all three waves (gentle first node)',
    () {
      final log = play(mission([press('a', 0, 1), press('b', 0, 3)]));
      expect(log, ['intermission@100', 'intermission@100', 'victory@100']);
    },
  );

  test('openings: a press is usually offered and almost always reachable', () {
    var offered = 0, reachable = 0;
    for (var seed = 1; seed <= 500; seed++) {
      final w = WorkshopController(
        board: GearBoard(),
        catalog: catalog,
        shop: shop,
        rules: rules,
        seed: seed,
      );
      if (w.offers.contains('unit.rivetguard')) offered++;
      while (!w.offers.contains('unit.rivetguard') &&
          w.battleScrap - w.rerollPrice >= 5) {
        w.reroll();
      }
      if (w.offers.contains('unit.rivetguard')) reachable++;
    }
    // Measured 2026-11-27: 420/500 offered, 499/500 reachable.
    expect(offered, greaterThanOrEqualTo(400));
    expect(reachable, greaterThanOrEqualTo(495));
  });

  test('mixSeed32 matches murmur3 fmix32 reference values', () {
    expect(mixSeed32(0), 0);
    expect(mixSeed32(1), 0x514E28B7);
    expect(mixSeed32(42), 0x087FCD5C);
    expect(mixSeed32(0xFFFFFFFF), 0x81F16F39);
  });

  test('small sequential seeds no longer always open with the same slot', () {
    final first = <String?>{};
    for (var seed = 1; seed <= 50; seed++) {
      first.add(
        WorkshopController(
          board: GearBoard(),
          catalog: catalog,
          shop: shop,
          rules: rules,
          seed: seed,
        ).offers.first,
      );
    }
    expect(first.length, greaterThanOrEqualTo(3));
  });
}
