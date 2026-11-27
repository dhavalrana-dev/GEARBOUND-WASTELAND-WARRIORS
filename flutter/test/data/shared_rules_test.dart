import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/core/seeded_random.dart';
import 'package:gearbound/data/shared_rules.dart';

/// Parity checks against fixtures written by tools/simulation/reference_rules.py.
String readShared(String relative) =>
    File('../shared/$relative').readAsStringSync();
Map<String, Object?> fixture(String name) =>
    jsonDecode(readShared('test-fixtures/$name')) as Map<String, Object?>;

void main() {
  test('xorshift32-v1 matches shared vectors', () {
    final f = fixture('random_vectors.json');
    for (final c in (f['nextUintCases'] as List).cast<Map<String, Object?>>()) {
      final rng = SeededRandom(c['seed'] as int);
      final expected = (c['nextUint'] as List).cast<int>();
      expect([for (final _ in expected) rng.nextUint()], expected);
    }
    final intCase = f['nextIntCase'] as Map<String, Object?>;
    final rng = SeededRandom(intCase['seed'] as int);
    final results = [
      for (final b in (intCase['bounds'] as List).cast<int>()) rng.nextInt(b),
    ];
    expect(results, (intCase['results'] as List).cast<int>());
    expect(rng.draws, 8);
  });

  test('shop rolls and reroll costs match shared fixture', () {
    final catalog = loadGears(readShared('gears/starter_gears.json'));
    final config = loadShop(readShared('economy/shop.json'));
    final f = fixture('shop_cases.json');
    expect([
      for (var k = 0; k < 7; k++) rerollCost(config, k),
    ], (f['rerollCosts'] as List).cast<int>());
    for (final c in (f['cases'] as List).cast<Map<String, Object?>>()) {
      final rng = SeededRandom(c['seed'] as int);
      final unlocked = (c['unlocked'] as List?)?.cast<String>().toSet();
      final locked = (c['locked'] as List?)?.cast<String?>();
      for (final expected in (c['expectedOffers'] as List)) {
        expect(
          rollShop(
            rng,
            catalog,
            config,
            unlockedIds: unlocked,
            lockedOffers: locked,
            boardHasGuaranteedCategory: c['boardHasGuaranteedCategory'] as bool,
          ),
          (expected as List).cast<String?>(),
          reason: c['id'] as String,
        );
      }
    }
  });

  test('wave director matches shared spawn schedule', () {
    final waves = loadMissionWaves(readShared('waves/mission_001.json'));
    final enemies = loadEnemies(readShared('enemies/enemies.json'));
    final f = fixture('mission_001_spawns.json');
    final expectedWaves = (f['waves'] as List).cast<Map<String, Object?>>();
    expect(waves.length, expectedWaves.length);
    for (var w = 0; w < waves.length; w++) {
      final expected = [
        for (final s
            in (expectedWaves[w]['spawns'] as List)
                .cast<Map<String, Object?>>())
          '${s['tick']}:${s['lane']}:${s['enemyId']}',
      ];
      expect([
        for (final s in scheduleWave(waves[w]))
          '${s.tick}:${s.lane}:${s.enemyId}',
      ], expected);
      expect(buildWave(waves[w], enemies).spawns.length, expected.length);
    }
  });
}
