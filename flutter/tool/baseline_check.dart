// ignore_for_file: avoid_print

/// Replays the shared determinism fixtures outside the test runner, so the
/// same check runs on the Dart VM, in an ahead-of-time compiled binary (the
/// way release and phone builds execute Dart), and on an Android device
/// through `integration_test/baseline_device_test.dart`:
///
///   dart run tool/baseline_check.dart
///   dart compile exe tool/baseline_check.dart -o build/baseline_check.exe
///   build/baseline_check.exe
///   dart run tool/baseline_check.dart --write-device-fixtures
///
/// Checks random vectors, shop rolls, the wave schedule, every combat trace
/// and every workshop case. Run from `flutter/`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:gearbound/core/seeded_random.dart';
import 'package:gearbound/data/shared_rules.dart';
import 'package:gearbound/simulation/combat_scenario.dart';

import 'workshop_cases.dart' as workshop;

typedef SharedReader = String Function(String rel);

/// Every shared file the baseline reads, relative to `shared/`.
const baselineFiles = [
  'test-fixtures/random_vectors.json',
  'test-fixtures/shop_cases.json',
  'test-fixtures/mission_001_spawns.json',
  'test-fixtures/combat_scenarios.json',
  'test-fixtures/combat_traces.json',
  'test-fixtures/workshop_cases.json',
  'gears/starter_gears.json',
  'economy/shop.json',
  'configs/gear_rules.json',
  'enemies/enemies.json',
  'waves/mission_001.json',
];

class BaselineResult {
  BaselineResult(this.checks, this.combatTraces, this.workshopCases);
  final int checks;
  final int combatTraces;
  final int workshopCases;
}

/// Runs every check; throws [StateError] naming the first mismatch.
BaselineResult runBaseline(SharedReader read) {
  var checks = 0;
  Map<String, Object?> fixture(String name) =>
      jsonDecode(read('test-fixtures/$name')) as Map<String, Object?>;
  void expectEqual(Object? actual, Object? expected, String what) {
    checks++;
    if (jsonEncode(actual) != jsonEncode(expected)) {
      throw StateError(
        'MISMATCH $what\n  expected: ${jsonEncode(expected)}\n'
        '  actual:   ${jsonEncode(actual)}',
      );
    }
  }

  final rv = fixture('random_vectors.json');
  for (final c in (rv['nextUintCases'] as List).cast<Map<String, Object?>>()) {
    final rng = SeededRandom(c['seed'] as int);
    final expected = c['nextUint'] as List;
    expectEqual(
      [for (final _ in expected) rng.nextUint()],
      expected,
      'random seed ${c['seed']}',
    );
  }
  final intCase = rv['nextIntCase'] as Map<String, Object?>;
  final intRng = SeededRandom(intCase['seed'] as int);
  expectEqual(
    [
      for (final b in (intCase['bounds'] as List).cast<int>())
        intRng.nextInt(b),
    ],
    intCase['results'],
    'nextInt mapping',
  );

  final catalog = loadGears(read('gears/starter_gears.json'));
  final shop = loadShop(read('economy/shop.json'));
  final sc = fixture('shop_cases.json');
  expectEqual(
    [for (var k = 0; k < 7; k++) rerollCost(shop, k)],
    sc['rerollCosts'],
    'reroll costs',
  );
  for (final c in (sc['cases'] as List).cast<Map<String, Object?>>()) {
    final rng = SeededRandom(c['seed'] as int);
    for (final expected in (c['expectedOffers'] as List)) {
      expectEqual(
        rollShop(
          rng,
          catalog,
          shop,
          unlockedIds: (c['unlocked'] as List?)?.cast<String>().toSet(),
          lockedOffers: (c['locked'] as List?)?.cast<String?>(),
          boardHasGuaranteedCategory: c['boardHasGuaranteedCategory'] as bool,
        ),
        expected,
        'shop case ${c['id']}',
      );
    }
  }

  final waves = loadMissionWaves(read('waves/mission_001.json'));
  final spawns = fixture('mission_001_spawns.json')['waves'] as List;
  for (var w = 0; w < waves.length; w++) {
    expectEqual(
      [
        for (final s in scheduleWave(waves[w]))
          '${s.tick}:${s.lane}:${s.enemyId}',
      ],
      [
        for (final s in ((spawns[w] as Map)['spawns'] as List).cast<Map>())
          '${s['tick']}:${s['lane']}:${s['enemyId']}',
      ],
      'mission_001 wave ${w + 1} schedule',
    );
  }

  final results = runCombatScenarios(
    scenariosJson: read('test-fixtures/combat_scenarios.json'),
    missionJson: read('waves/mission_001.json'),
    enemiesJson: read('enemies/enemies.json'),
  );
  final traces = (fixture('combat_traces.json')['results'] as List)
      .cast<Map<String, Object?>>();
  expectEqual(
    results.map((r) => r.id).toList(),
    traces.map((e) => e['id']).toList(),
    'combat scenario list',
  );
  for (var i = 0; i < traces.length; i++) {
    final e = traces[i];
    final r = results[i];
    expectEqual(r.checkpoints, e['checkpoints'], '${r.id} checkpoints');
    expectEqual(
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
      '${r.id} result',
    );
  }

  final ws = fixture('workshop_cases.json');
  final vectors = (ws['mixSeed32'] as List).cast<Map>();
  expectEqual(
    [for (final v in vectors) mixSeed32(v['seed'] as int)],
    [for (final v in vectors) v['mixed']],
    'mixSeed32 vectors',
  );
  final cases = (ws['cases'] as List).cast<Map<String, Object?>>();
  for (final c in cases) {
    final script = workshop.scripts.firstWhere((s) => s['id'] == c['id']);
    expectEqual(
      workshop.run(script, c['seed'] as int, read: read),
      c['steps'],
      'workshop case ${c['id']}',
    );
  }
  return BaselineResult(checks, traces.length, cases.length);
}

const deviceFixturesPath = 'integration_test/shared_fixtures.g.dart';

void main(List<String> args) {
  String read(String rel) => File('../shared/$rel').readAsStringSync();
  if (args.contains('--write-device-fixtures')) {
    final out = StringBuffer()
      ..writeln(
        '// GENERATED by tool/baseline_check.dart --write-device-fixtures.',
      )
      ..writeln('// Not committed: regenerate before running the device test.')
      ..writeln('// ignore_for_file: lines_longer_than_80_chars')
      ..writeln()
      ..writeln('const sharedFixtures = <String, String>{');
    for (final rel in baselineFiles) {
      final text = read(rel);
      if (text.contains("'''")) throw StateError('$rel contains triple quotes');
      out.writeln("  '$rel': r'''$text''',");
    }
    out.writeln('};');
    File(deviceFixturesPath).writeAsStringSync(out.toString());
    print('wrote $deviceFixturesPath (${baselineFiles.length} files)');
    return;
  }
  final mode = const bool.fromEnvironment('dart.vm.product') ? 'AOT' : 'VM';
  try {
    final r = runBaseline(read);
    print(
      'baseline OK ($mode): ${r.checks} checks, ${r.combatTraces} combat '
      'traces, ${r.workshopCases} workshop cases',
    );
  } on StateError catch (e) {
    print(e.message);
    exit(1);
  }
}
