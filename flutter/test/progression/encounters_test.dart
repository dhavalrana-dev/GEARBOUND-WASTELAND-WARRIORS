import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/progression/encounters.dart';

void main() {
  test('first five route encounters have authored spawn patterns', () {
    final encounters = [
      for (var index = 0; index < 5; index++) encounterForLevel(index),
    ];
    expect(encounters.map((encounter) => encounter.spawns.length), [
      3,
      4,
      4,
      6,
      4,
    ]);
    expect(encounters.map((encounter) => encounter.id).toSet(), hasLength(5));

    final firstRunner = encounters[1].spawns.first;
    final heavy = encounters[2].spawns.first;
    final boss = encounters[4].spawns[2];
    expect(
      firstRunner.movementMmPerTick,
      greaterThan(encounters[0].spawns.first.movementMmPerTick),
    );
    expect(heavy.armor, greaterThan(0));
    expect(boss.health, greaterThan(100));
    expect(boss.armor, greaterThan(0));
  });

  test(
    'later route nodes use deterministic escalation and invalid nodes fail',
    () {
      final low = encounterForLevel(5);
      final high = encounterForLevel(11);
      expect(high.spawns.length, greaterThan(low.spawns.length));
      expect(high.spawns.first.health, greaterThan(low.spawns.first.health));
      expect(() => encounterForLevel(12), throwsRangeError);
    },
  );
}
