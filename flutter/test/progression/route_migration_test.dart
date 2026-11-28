import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/data/shared_rules.dart';
import 'package:gearbound/mechanical/gear_network.dart';
import 'package:gearbound/progression/encounters.dart';

String _shared(String rel) => File('../shared/$rel').readAsStringSync();

/// GB-024: route nodes 2-12 moved from scripted Dart encounters to shared
/// mission JSON. This pins the reviewed balance change: every node gives the
/// same outcome and fortress health as its old script for the reference
/// builds below; only some clear times differ.
void main() {
  final enemies = loadEnemies(_shared('enemies/enemies.json'));
  final route =
      (jsonDecode(_shared('missions/campaign_route.json'))
              as Map<String, Object?>)['nodes']
          as List;

  WaveDefinition sharedWave(int node) {
    final entry = route[node] as Map<String, Object?>;
    return buildWave(
      loadMissionWaves(_shared(entry['mission'] as String)).first,
      enemies,
    );
  }

  GearNode press(String id, int x, int y, int lane) => GearNode(
    id: id,
    definitionId: 'unit.rivetguard',
    kind: GearKind.output,
    x: x,
    y: y,
    localPorts: Direction.values.toSet(),
    baseIntervalTicks: 90,
    outputKind: GearOutputKind.spawnInfantry,
    targetLane: lane,
  );

  final booster = GearNode(
    id: 'boost',
    definitionId: 'boost.ratchet',
    kind: GearKind.booster,
    x: 1,
    y: 3,
    localPorts: Direction.values.toSet(),
  );

  /// Reference builds: starter only; one extra press; both side lanes
  /// covered; both side lanes plus a booster.
  final builds = <String, List<GearNode>>{
    'starter': [],
    'one press': [press('p1', 0, 1, 0)],
    'side lanes': [press('p1', 0, 1, 0), press('p2', 0, 3, 2)],
    'side lanes + booster': [
      press('p1', 0, 1, 0),
      press('p2', 0, 3, 2),
      booster,
    ],
  };

  String outcome(WaveDefinition wave, List<GearNode> extra) {
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
      ..place(press('starter', 1, 2, 1));
    for (final g in extra) {
      board.place(g);
    }
    final s = BattleSession(
      board: board,
      network: GearNetwork.rebuild(board),
      wave: wave,
      combat: CombatSimulation(worldLengthMm: 10000),
    );
    s.start();
    for (var t = 0; t < 5400 && s.phase == BattlePhase.combat; t++) {
      s.tick();
    }
    return '${s.phase.name}@${s.combat.fortressHealth}';
  }

  String spawnKey(WaveSpawnEvent e) =>
      '${e.tick}:${e.lane}:${e.health}:${e.armor}:${e.damage}:'
      '${e.attackRangeMm}:${e.movementMmPerTick}:${e.attackIntervalTicks}';

  test('the route lists all 12 campaign nodes in order', () {
    expect([for (final n in route) (n as Map)['id']], campaignEncounterIds);
  });

  test('nodes 2-4 and 10-12 spawn exactly what their scripts did', () {
    for (final node in [1, 2, 3, 9, 10, 11]) {
      expect(
        sharedWave(node).spawns.map(spawnKey),
        encounterForLevel(node).spawns.map(spawnKey),
        reason: campaignEncounterIds[node],
      );
    }
  });

  test('every node keeps its outcome and fortress health for the reference '
      'builds', () {
    for (var node = 1; node < 12; node++) {
      for (final build in builds.entries) {
        expect(
          outcome(sharedWave(node), build.value),
          outcome(encounterForLevel(node), build.value),
          reason: '${campaignEncounterIds[node]} with ${build.key}',
        );
      }
    }
  });

  test('the difficulty curve still rises: late nodes cost fortress health', () {
    final late = outcome(sharedWave(11), builds['side lanes']!);
    expect(late, 'victory@10');
    expect(outcome(sharedWave(1), builds['side lanes']!), 'victory@100');
  });
}
