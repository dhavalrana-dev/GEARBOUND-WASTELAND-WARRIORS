import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/simulation/combat_scenario.dart';

/// Spec scenario 4: identical shared config and inputs must give identical
/// combat in both engines. Expected values come from the Unity C# simulation
/// (tools/simulation/generate_combat_traces.ps1).
void main() {
  String read(String relative) =>
      File('../shared/$relative').readAsStringSync();

  test('Dart combat reproduces the C# reference traces tick for tick', () {
    final results = runCombatScenarios(
      scenariosJson: read('test-fixtures/combat_scenarios.json'),
      missionJson: read('waves/mission_001.json'),
      enemiesJson: read('enemies/enemies.json'),
    );
    final expected =
        ((jsonDecode(read('test-fixtures/combat_traces.json'))
                    as Map<String, Object?>)['results']
                as List)
            .cast<Map<String, Object?>>();
    expect(results.map((r) => r.id), expected.map((e) => e['id']));

    for (var i = 0; i < expected.length; i++) {
      final e = expected[i];
      final r = results[i];
      final expectedCheckpoints = (e['checkpoints'] as List).cast<int>();
      // Report the first diverging 30-tick window before comparing totals.
      for (var c = 0; c < expectedCheckpoints.length; c++) {
        expect(
          c < r.checkpoints.length ? r.checkpoints[c] : null,
          expectedCheckpoints[c],
          reason: '${r.id}: diverged by tick ${(c + 1) * 30}',
        );
      }
      expect(
        [
          r.phase,
          r.elapsedTicks,
          r.fortressHealth,
          r.friendlyUnitsProduced,
          r.friendlyAlive,
          r.enemiesAlive,
          r.traceHash,
        ],
        [
          e['phase'],
          e['elapsedTicks'],
          e['fortressHealth'],
          e['friendlyUnitsProduced'],
          e['friendlyAlive'],
          e['enemiesAlive'],
          e['traceHash'],
        ],
        reason: r.id,
      );
    }
  });
}
