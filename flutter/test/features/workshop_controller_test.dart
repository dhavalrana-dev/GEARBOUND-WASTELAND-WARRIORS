import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/data/shared_rules.dart';
import 'package:gearbound/economy/economy_rules.dart';
import 'package:gearbound/features/workshop/workshop_controller.dart';
import 'package:gearbound/mechanical/gear_network.dart';

String _shared(String rel) => File('../shared/$rel').readAsStringSync();

void main() {
  final catalog = loadGears(_shared('gears/starter_gears.json'));
  final shop = loadShop(_shared('economy/shop.json'));
  final rules = WorkshopRules.fromJson(_shared('configs/gear_rules.json'));

  WorkshopController make({int seed = 1}) => WorkshopController(
    board: GearBoard(),
    catalog: catalog,
    shop: shop,
    rules: rules,
    seed: seed,
  );

  /// Finds a seed whose opening offers contain [id], so tests do not depend
  /// on one particular roll.
  WorkshopController withOffer(String id) {
    for (var seed = 1; seed < 500; seed++) {
      final c = make(seed: seed);
      if (c.offers.contains(id)) return c;
    }
    fail('no seed offers $id');
  }

  test('starts with the starter gears, shared starting scrap and 3 offers', () {
    final c = make();
    expect(c.board.at(0, 2)?.kind, GearKind.core);
    expect(c.board.at(1, 2)?.definitionId, 'unit.rivetguard');
    expect(c.battleScrap, shop.startingScrap);
    expect(c.offers, hasLength(shop.offerCount));
  });

  test('the shop never offers cores or gears without implemented behavior', () {
    for (var seed = 1; seed < 200; seed++) {
      for (final id in make(seed: seed).offers.whereType<String>()) {
        expect(rules.shopCategories, contains(c(catalog, id).category));
      }
    }
  });

  test('offers are deterministic for a seed', () {
    expect(make(seed: 42).offers, make(seed: 42).offers);
  });

  test('buy then place spends battle scrap and powers by row lane', () {
    final c = withOffer('unit.rivetguard');
    final slot = c.offers.indexOf('unit.rivetguard');
    expect(c.buy(slot), WorkshopAction.ok);
    expect(c.battleScrap, shop.startingScrap - 5);
    expect(c.offers[slot], isNull);
    expect(c.buy(slot), WorkshopAction.handFull);
    expect(c.tapCell(1, 2), WorkshopAction.occupied);
    expect(c.tapCell(0, 1), WorkshopAction.ok);
    final placed = c.board.at(0, 1)!;
    expect(placed.targetLane, rules.laneForRow(1));
    expect(placed.outputKind, GearOutputKind.spawnInfantry);
    expect(
      GearNetwork.rebuild(c.board).nodes[placed.id]?.state,
      NetworkState.powered,
    );
    // Every spend is in the mission ledger.
    expect(c.wallet.ledger.where((e) => e.type == 'spend').single.amount, -5);
  });

  test('cancelling an unplaced purchase refunds it in full', () {
    final c = withOffer('unit.rivetguard');
    c.buy(c.offers.indexOf('unit.rivetguard'));
    expect(c.cancelHand(), WorkshopAction.ok);
    expect(c.battleScrap, shop.startingScrap);
    expect(c.hand, isNull);
  });

  test('cannot buy what battle scrap cannot cover', () {
    final c = make(seed: 3);
    // Rerolls cost 1+2+3+4 = 10 of the 12 starting scrap.
    for (var i = 0; i < 4; i++) {
      expect(c.reroll(), WorkshopAction.ok);
    }
    expect(c.battleScrap, shop.startingScrap - 10);
    expect(c.reroll(), WorkshopAction.insufficientScrap);
    // The board has no transmission, so a coupler (cost 2) is guaranteed.
    final coupler = c.offers.indexOf('drive.coupler');
    expect(c.buy(coupler), WorkshopAction.ok);
    expect(c.tapCell(4, 4), WorkshopAction.ok);
    expect(c.battleScrap, 0);
    final other = c.offers.indexWhere((id) => id != null);
    expect(c.buy(other), WorkshopAction.insufficientScrap);
    expect(c.hand, isNull);
  });

  test('rerolls cost more each time and replace the offers', () {
    final c = make(seed: 9);
    expect(c.rerollPrice, 1);
    expect(c.reroll(), WorkshopAction.ok);
    expect(c.rerollPrice, 2);
    expect(c.battleScrap, shop.startingScrap - 1);
  });

  test('merging two tier-1 presses makes one faster-per-gear tier-2 press', () {
    final c = make();
    // Give the board a second press next to the starter press.
    c.board.place(
      GearNode(
        id: 'extra',
        definitionId: 'unit.rivetguard',
        kind: GearKind.output,
        x: 1,
        y: 3,
        localPorts: Direction.values.toSet(),
        baseIntervalTicks: 90,
        outputKind: GearOutputKind.spawnInfantry,
        targetLane: rules.laneForRow(3),
      ),
    );
    expect(c.tapCell(1, 3), WorkshopAction.ok);
    expect(c.selected, (x: 1, y: 3));
    expect(c.tapCell(1, 2), WorkshopAction.ok);
    final merged = c.board.at(1, 2)!;
    expect(merged.tier, 2);
    expect(merged.baseIntervalTicks, rules.intervalFor(90, 2));
    expect(merged.targetLane, rules.laneForRow(2));
    expect(c.board.at(1, 3), isNull);
    // Merging is a trade-off: one tier-2 press is slower than two tier-1s.
    expect(rules.intervalFor(90, 2), greaterThan(90 ~/ 2));
  });

  test('mismatched gears do not merge; the tap moves the selection', () {
    final c = withOffer('drive.coupler');
    c.buy(c.offers.indexOf('drive.coupler'));
    c.tapCell(2, 2);
    c.tapCell(2, 2);
    expect(c.tapCell(1, 2), WorkshopAction.notMergeable);
    expect(c.selected, (x: 1, y: 2));
    expect(c.board.at(2, 2)?.definitionId, 'drive.coupler');
  });

  test('selling refunds half the purchase cost per merged copy', () {
    final c = make();
    c.tapCell(1, 2);
    expect(c.selectedSellValue, 5 * shop.sellRefundPercent ~/ 100);
    expect(c.sellSelected(), WorkshopAction.ok);
    expect(c.board.at(1, 2), isNull);
    expect(
      c.battleScrap,
      shop.startingScrap + 5 * shop.sellRefundPercent ~/ 100,
    );
    c.tapCell(0, 2);
    expect(c.sellSelected(), WorkshopAction.nothingSelected);
  });

  test('locking refunds the hand and blocks every edit', () {
    final c = withOffer('drive.coupler');
    c.buy(c.offers.indexOf('drive.coupler'));
    c.lock();
    expect(c.battleScrap, shop.startingScrap);
    expect(c.buy(0), WorkshopAction.locked);
    expect(c.reroll(), WorkshopAction.locked);
    expect(c.tapCell(3, 3), WorkshopAction.locked);
    expect(c.sellSelected(), WorkshopAction.locked);
  });

  test('the starter board alone holds the first route node with hero help', () {
    // Not a balance guarantee: documents that the opening loadout is viable.
    final c = make();
    c.board.place(
      GearNode(
        id: 'side-a',
        definitionId: 'unit.rivetguard',
        kind: GearKind.output,
        x: 0,
        y: 1,
        localPorts: Direction.values.toSet(),
        baseIntervalTicks: 90,
        outputKind: GearOutputKind.spawnInfantry,
        targetLane: rules.laneForRow(1),
      ),
    );
    c.board.place(
      GearNode(
        id: 'side-b',
        definitionId: 'unit.rivetguard',
        kind: GearKind.output,
        x: 0,
        y: 3,
        localPorts: Direction.values.toSet(),
        baseIntervalTicks: 90,
        outputKind: GearOutputKind.spawnInfantry,
        targetLane: rules.laneForRow(3),
      ),
    );
    final enemies = loadEnemies(_shared('enemies/enemies.json'));
    final waves = loadMissionWaves(_shared('waves/mission_001.json'));
    final session = BattleSession(
      board: c.board,
      network: GearNetwork.rebuild(c.board),
      wave: buildWave(waves.first, enemies),
      combat: CombatSimulation(worldLengthMm: 10000),
    )..start();
    for (var t = 0; t < 3600 && session.phase == BattlePhase.combat; t++) {
      session.tick();
    }
    expect(session.phase, BattlePhase.victory);
    expect(c.wallet.balance(Currency.alloy), 0);
  });
}

GearDefinition c(List<GearDefinition> catalog, String id) =>
    catalog.firstWhere((g) => g.id == id);
