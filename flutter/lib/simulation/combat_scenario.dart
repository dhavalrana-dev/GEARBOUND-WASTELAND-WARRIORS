import 'dart:convert';

import '../combat/battle_session.dart';
import '../combat/combat_simulation.dart';
import '../data/shared_rules.dart';
import '../mechanical/gear_network.dart';

/// Dart mirror of Unity's `CombatScenarioRunner`. Must produce the exact
/// FNV-1a trace hashes recorded in shared/test-fixtures/combat_traces.json.
class CombatScenarioResult {
  const CombatScenarioResult({
    required this.id,
    required this.phase,
    required this.elapsedTicks,
    required this.fortressHealth,
    required this.friendlyUnitsProduced,
    required this.friendlyAlive,
    required this.enemiesAlive,
    required this.traceHash,
    required this.checkpoints,
  });

  final String id;
  final String phase;
  final int elapsedTicks;
  final int fortressHealth;
  final int friendlyUnitsProduced;
  final int friendlyAlive;
  final int enemiesAlive;
  final int traceHash;
  final List<int> checkpoints;
}

const _fnvOffset = 2166136261;
const _fnvPrime = 16777619;
const _mask32 = 0xFFFFFFFF;

List<CombatScenarioResult> runCombatScenarios({
  required String scenariosJson,
  required String missionJson,
  required String enemiesJson,
}) {
  final root = jsonDecode(scenariosJson) as Map<String, Object?>;
  final waves = loadMissionWaves(missionJson);
  final enemies = loadEnemies(enemiesJson);
  final every = root['checkpointEveryTicks'] as int;
  return [
    for (final s in (root['scenarios'] as List).cast<Map<String, Object?>>())
      _run(s, waves, enemies, every),
  ];
}

CombatScenarioResult _run(
  Map<String, Object?> s,
  List<AuthoredWave> waves,
  List<EnemyDefinition> enemies,
  int every,
) {
  final wave = waves.firstWhere((w) => w.id == s['waveId']);
  final board = GearBoard();
  for (final g in (s['gears'] as List).cast<Map<String, Object?>>()) {
    final kind = g['kind'] as String;
    final placed = board.place(
      GearNode(
        id: g['id'] as String,
        definitionId: g['id'] as String,
        kind: switch (kind) {
          'core' => GearKind.core,
          'transmission' => GearKind.transmission,
          'booster' => GearKind.booster,
          _ => GearKind.output,
        },
        x: g['x'] as int,
        y: g['y'] as int,
        localPorts: Direction.values.toSet(),
        baseIntervalTicks: g['intervalTicks'] as int? ?? 0,
        outputKind: kind == 'infantry'
            ? GearOutputKind.spawnInfantry
            : GearOutputKind.none,
        targetLane: g['targetLane'] as int? ?? 1,
      ),
    );
    if (!placed) throw StateError('Could not place ${g['id']}.');
  }
  final commands = [
    for (final c in (s['heroCommands'] as List).cast<Map<String, Object?>>())
      (tick: c['tick'] as int, lane: c['lane'] as int),
  ];

  final session = BattleSession(
    board: board,
    network: GearNetwork.rebuild(board),
    wave: buildWave(wave, enemies),
    combat: CombatSimulation(worldLengthMm: s['worldLengthMm'] as int),
  )..start();
  final maxTicks = s['maxTicks'] as int;
  var hash = _fnvOffset;
  final checkpoints = <int>[];
  while (session.phase == BattlePhase.combat &&
      session.elapsedTicks < maxTicks) {
    for (final command in commands) {
      if (command.tick == session.elapsedTicks) {
        session.moveHeroToLane(command.lane);
      }
    }
    session.tick();
    final line = StringBuffer()
      ..write(session.elapsedTicks)
      ..write('|')
      ..write(session.phase.name.toLowerCase())
      ..write('|')
      ..write(session.combat.fortressHealth)
      ..write('|');
    for (final u in session.combat.combatants) {
      line
        ..write(u.id)
        ..write(':')
        ..write(u.lane)
        ..write(':')
        ..write(u.positionMm)
        ..write(':')
        ..write(u.health)
        ..write(':')
        ..write(u.shield)
        ..write(':')
        ..write(u.state.name.toLowerCase())
        ..write(';');
    }
    for (final unit in line.toString().codeUnits) {
      hash = ((hash ^ unit) * _fnvPrime) & _mask32;
    }
    if (session.elapsedTicks % every == 0) checkpoints.add(hash);
  }

  final units = session.combat.combatants;
  return CombatScenarioResult(
    id: s['id'] as String,
    phase: session.phase.name.toLowerCase(),
    elapsedTicks: session.elapsedTicks,
    fortressHealth: session.combat.fortressHealth,
    friendlyUnitsProduced: units
        .where((u) => u.faction == CombatFaction.friendly && u.id >= 100000)
        .length,
    friendlyAlive: units
        .where((u) => u.isAlive && u.faction == CombatFaction.friendly)
        .length,
    enemiesAlive: units
        .where((u) => u.isAlive && u.faction == CombatFaction.enemy)
        .length,
    traceHash: hash,
    checkpoints: checkpoints,
  );
}
