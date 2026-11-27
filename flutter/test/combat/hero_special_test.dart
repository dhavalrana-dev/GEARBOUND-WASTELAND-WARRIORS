import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/mechanical/gear_network.dart';

WaveSpawnEvent _enemy(int tick, {int health = 200, int lane = 1}) =>
    WaveSpawnEvent(
      tick: tick,
      lane: lane,
      health: health,
      armor: 0,
      damage: 1,
      attackRangeMm: 0,
      movementMmPerTick: 0,
      attackIntervalTicks: 30,
    );

BattleSession _session(List<WaveSpawnEvent> spawns) {
  final board = GearBoard();
  return BattleSession(
    board: board,
    network: GearNetwork.rebuild(board),
    wave: WaveDefinition(id: 'w', spawns: spawns),
    combat: CombatSimulation(worldLengthMm: 1000),
  );
}

Combatant _hero(BattleSession s) =>
    s.combat.combatants.firstWhere((u) => u.id == s.heroId);

void main() {
  test('Dart Rivet special matches shared/heroes/heroes.json', () {
    final json = jsonDecode(
      File('../shared/heroes/heroes.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final rivet = (json['heroes'] as List).cast<Map<String, Object?>>().first;
    final sp = rivet['special'] as Map<String, Object?>;
    expect(
      [
        HeroSpecial.rivet.id,
        HeroSpecial.rivet.spMax,
        HeroSpecial.rivet.spPerHit,
        HeroSpecial.rivet.damage,
        HeroSpecial.rivet.radiusMm,
      ],
      [sp['id'], sp['spMax'], sp['spPerHit'], sp['damage'], sp['radiusMm']],
    );
    // The hero's base stats in BattleSession must also match the file.
    final s = _session([_enemy(0)]);
    final hero = _hero(s);
    expect(
      [
        hero.maxHealth,
        hero.armor,
        hero.damage,
        hero.attackRangeMm,
        hero.movementMmPerTick,
        hero.attackIntervalTicks,
      ],
      [
        rivet['health'],
        rivet['armor'],
        rivet['damage'],
        rivet['attackRangeMm'],
        rivet['movementMmPerTick'],
        rivet['attackIntervalTicks'],
      ],
    );
  });

  test('SP fills from landed hero hits and caps at the maximum', () {
    final s = _session([_enemy(0, health: 100000)])..start();
    expect(s.heroSp, 0);
    for (var i = 0; i < 2000; i++) {
      s.tick();
    }
    expect(s.heroSp, HeroSpecial.rivet.spMax);
  });

  test('the special is refused until the bar is full, and outside combat', () {
    final s = _session([_enemy(0, health: 100000)]);
    expect(s.useHeroSpecial(), isFalse); // preparation
    s.start();
    s.tick();
    expect(s.useHeroSpecial(), isFalse); // empty bar
  });

  test('the special hits enemies near the hero in its lane only, once', () {
    final s = _session([_enemy(0), _enemy(0, lane: 0)])..start();
    while (s.heroSp < HeroSpecial.rivet.spMax) {
      s.tick();
    }
    final hero = _hero(s);
    final near = s.combat.combatants.firstWhere(
      (u) => u.faction == CombatFaction.enemy && u.lane == hero.lane,
    );
    final otherLane = s.combat.combatants.firstWhere(
      (u) => u.faction == CombatFaction.enemy && u.lane != hero.lane,
    );
    final nearBefore = near.health;
    final otherBefore = otherLane.health;
    expect(s.useHeroSpecial(), isTrue);
    expect(s.useHeroSpecial(), isFalse); // already queued
    s.tick();
    expect(s.heroSp, lessThan(HeroSpecial.rivet.spMax));
    // The special's 25 damage lands, plus any normal hero hit this tick.
    expect(nearBefore - near.health, greaterThanOrEqualTo(25));
    expect(otherLane.health, otherBefore);
  });

  test('a queued special does nothing if the hero died before it applied', () {
    final s = _session([_enemy(0, health: 100000)])..start();
    while (s.heroSp < HeroSpecial.rivet.spMax) {
      s.tick();
    }
    expect(s.useHeroSpecial(), isTrue);
    _hero(s).health = 0;
    final enemy = s.combat.combatants.firstWhere(
      (u) => u.faction == CombatFaction.enemy,
    );
    final before = enemy.health;
    s.tick();
    expect(enemy.health, before);
  });
}
