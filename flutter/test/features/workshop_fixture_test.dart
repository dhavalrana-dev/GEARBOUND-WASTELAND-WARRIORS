import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/core/seeded_random.dart';

import '../../tool/workshop_cases.dart' as cases;

/// The shared workshop fixture (also replayed by Unity's WorkshopFixtureTests)
/// must match what the Dart controller produces today.
void main() {
  final fixture = jsonDecode(
    File(cases.fixturePath).readAsStringSync(),
  ) as Map<String, Object?>;

  test('workshop_cases.json is up to date with the Dart controller', () {
    expect(
      jsonEncode(cases.build()),
      jsonEncode(fixture),
      reason: 'run: dart run tool/workshop_cases.dart',
    );
  });

  test('mixSeed32 vectors', () {
    for (final v in (fixture['mixSeed32'] as List).cast<Map>()) {
      expect(mixSeed32(v['seed'] as int), v['mixed'], reason: '${v['seed']}');
    }
  });

  test('every case still exercises the results it was chosen for', () {
    for (final c in (fixture['cases'] as List).cast<Map>()) {
      final seen = {
        for (final s in (c['steps'] as List).cast<Map>()) s['result'],
      };
      final script = cases.scripts.firstWhere((s) => s['id'] == c['id']);
      expect(seen, containsAll(script['require'] as List), reason: c['id']);
    }
  });
}
