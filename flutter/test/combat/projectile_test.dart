import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/data/shared_rules.dart';
import 'package:gearbound/features/workshop/mission_snapshot.dart';
import 'package:gearbound/features/workshop/workshop_controller.dart';
import 'package:gearbound/mechanical/gear_network.dart';
import 'package:gearbound/mechanical/gear_output_system.dart';

String _shared(String rel) => File('../shared/$rel').readAsStringSync();

/// Projectiles and turret outputs. Mirrors Unity's ProjectileTests.
void main() {
  Combatant enemy(int id, {int lane = 1, int pos = 900, int armor = 0}) =>
      Combatant(
        id: id,
        faction: CombatFaction.enemy,
        lane: lane,
        positionMm: pos,
        health: 50,
        armor: armor,
        damage: 1,
        attackRangeMm: 0,
        movementMmPerTick: 0,
        attackIntervalTicks: 30,
      );

  test('a projectile travels and hits the nearest enemy in its lane', () {
    final sim = CombatSimulation(worldLengthMm: 2000)
      ..add(enemy(10, pos: 900, armor: 2))
      ..add(enemy(11, pos: 1200));
    expect(
      sim.fireProjectile(lane: 1, startMm: 0, speedMmPerTick: 300, damage: 8),
      isTrue,
    );
    sim.tick(); // 0 -> 300
    sim.tick(); // 300 -> 600
    expect(sim.projectiles.single.positionMm, 600);
    sim.tick(); // 600 -> 900: hits enemy 10 (armor 2 -> 6 damage)
    int hp(int id) => sim.combatants.firstWhere((u) => u.id == id).health;
    expect(hp(10), 44);
    expect(hp(11), 50);
    expect(sim.projectiles, isEmpty);
  });

  test('projectiles ignore other lanes and leave at the end of the field', () {
    final sim = CombatSimulation(worldLengthMm: 1000)
      ..add(enemy(10, lane: 0, pos: 500));
    sim.fireProjectile(lane: 1, startMm: 0, speedMmPerTick: 400, damage: 8);
    for (var i = 0; i < 3; i++) {
      sim.tick();
    }
    expect(sim.combatants.single.health, 50);
    expect(sim.projectiles, isEmpty);
  });

  test('the projectile cap refuses extra shots', () {
    final sim = CombatSimulation()..maxActiveProjectiles = 2;
    bool fire() =>
        sim.fireProjectile(lane: 0, startMm: 0, speedMmPerTick: 1, damage: 1);
    expect([fire(), fire(), fire()], [true, true, false]);
  });

  GearBoard turretBoard({bool powered = true}) {
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
      ..place(
        GearNode(
          id: 'turret',
          definitionId: 'turret.spark',
          kind: GearKind.output,
          x: powered ? 1 : 4,
          y: powered ? 2 : 4,
          localPorts: Direction.values.toSet(),
          baseIntervalTicks: 10,
          outputKind: GearOutputKind.fireProjectile,
          targetLane: 2,
          projectileDamage: 8,
          projectileSpeedMmPerTick: 300,
        ),
      );
    return board;
  }

  test('a powered turret fires down its lane each cycle', () {
    final board = turretBoard();
    final net = GearNetwork.rebuild(board);
    final sim = CombatSimulation();
    final outputs = GearOutputSystem();
    for (var i = 0; i < 10; i++) {
      outputs.tick(board, net, sim);
    }
    expect(sim.projectiles, hasLength(1));
    expect(sim.projectiles.single.lane, 2);
    expect(sim.projectiles.single.damage, 8);
  });

  test('an unpowered turret never fires, and a capped one holds', () {
    final idle = turretBoard(powered: false);
    final sim = CombatSimulation();
    final outputs = GearOutputSystem();
    for (var i = 0; i < 40; i++) {
      outputs.tick(idle, GearNetwork.rebuild(idle), sim);
    }
    expect(sim.projectiles, isEmpty);

    final board = turretBoard();
    final capped = CombatSimulation()..maxActiveProjectiles = 1;
    final out2 = GearOutputSystem();
    final net = GearNetwork.rebuild(board);
    for (var i = 0; i < 30; i++) {
      out2.tick(board, net, capped);
    }
    expect(capped.projectiles, hasLength(1));
    expect(
      out2.clocks.values.single.status,
      GearOutputStatus.unitCapacityReached,
    );
  });

  test('Spark Turret loads its projectile and keeps it through the workshop, '
      'merges and checkpoints', () {
    final catalog = loadGears(_shared('gears/starter_gears.json'));
    final spark = catalog.firstWhere((g) => g.id == 'turret.spark');
    expect([spark.projectileDamage, spark.projectileSpeedMmPerTick], [8, 300]);

    final rules = WorkshopRules.fromJson(_shared('configs/gear_rules.json'));
    expect(rules.shopCategories, contains('turret'));
    final shop = loadShop(_shared('economy/shop.json'));
    WorkshopController? w;
    for (var seed = 1; seed < 500 && w == null; seed++) {
      final c = WorkshopController(
        board: GearBoard(),
        catalog: catalog,
        shop: shop,
        rules: rules,
        seed: seed,
      );
      if (c.offers.contains('turret.spark')) w = c;
    }
    expect(w, isNotNull, reason: 'the shop should sometimes offer a turret');
    w!.buy(w.offers.indexOf('turret.spark'));
    w.tapCell(0, 1);
    final placed = w.board.at(0, 1)!;
    expect(placed.outputKind, GearOutputKind.fireProjectile);
    expect(placed.projectileDamage, 8);

    final back = MissionSnapshot.nodeFromJson(
      MissionSnapshot.nodeToJson(placed),
    );
    expect([back.projectileDamage, back.projectileSpeedMmPerTick], [8, 300]);

    final board = GearBoard()
      ..place(placed)
      ..place(
        GearNode(
          id: 'twin',
          definitionId: 'turret.spark',
          kind: GearKind.output,
          x: 0,
          y: 0,
          localPorts: Direction.values.toSet(),
          baseIntervalTicks: placed.baseIntervalTicks,
          outputKind: GearOutputKind.fireProjectile,
          targetLane: placed.targetLane,
          projectileDamage: 8,
          projectileSpeedMmPerTick: 300,
        ),
      );
    final merged = board.merge(
      0,
      0,
      0,
      1,
      maxTier: 3,
      nextTierBaseIntervalTicks: rules.intervalFor(45, 2),
    )!;
    expect(
      [merged.projectileDamage, merged.projectileSpeedMmPerTick],
      [8, 300],
    );
  });
}
