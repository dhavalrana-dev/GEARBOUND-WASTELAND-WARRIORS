import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/mechanical/gear_network.dart';

/// Mirrors unity/Assets/Tests/EditMode/HeroRecoveryTests.cs. The brute's
/// 950 mm reach covers the hero once it walks out, but not the fortress line,
/// so a revived hero survives its first tick back.
WaveSpawnEvent _brute(int tick) => WaveSpawnEvent(
  tick: tick,
  lane: 1,
  health: 500,
  armor: 0,
  damage: 200,
  attackRangeMm: 950,
  movementMmPerTick: 0,
  attackIntervalTicks: 30,
);

BattleSession _session({
  HeroRecovery? recovery = HeroRecovery.rivet,
  List<WaveDefinition> later = const [],
}) {
  final board = GearBoard();
  return BattleSession(
    board: board,
    network: GearNetwork.rebuild(board),
    wave: WaveDefinition(id: 'w1', spawns: [_brute(0)]),
    laterWaves: later,
    combat: CombatSimulation(worldLengthMm: 1000),
    recovery: recovery,
  );
}

Combatant _hero(BattleSession s) =>
    s.combat.combatants.firstWhere((u) => u.id == s.heroId);

/// Ticks until the hero is knocked out; returns that tick.
int _knockOut(BattleSession s) {
  while (_hero(s).isAlive) {
    s.tick();
    if (s.elapsedTicks > 300) fail('hero was never knocked out');
  }
  return s.elapsedTicks;
}

void main() {
  test('Dart Rivet recovery matches shared/heroes/heroes.json', () {
    final json = jsonDecode(
      File('../shared/heroes/heroes.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final rivet = (json['heroes'] as List).cast<Map<String, Object?>>().first;
    final recovery = rivet['recovery'] as Map<String, Object?>;
    expect(
      [HeroRecovery.rivet.ticks, HeroRecovery.rivet.healthPercent],
      [recovery['ticks'], recovery['healthPercent']],
    );
  });

  test('a knocked-out hero returns after exactly the recovery ticks', () {
    final s = _session()..start();
    _hero(s).lane = 1;
    final down = _knockOut(s);
    expect(s.heroRecoveryRemaining, HeroRecovery.rivet.ticks);
    expect(s.specialReady, isFalse);
    while (!_hero(s).isAlive) {
      s.tick();
      if (s.elapsedTicks > down + 400) fail('hero never recovered');
    }
    expect(s.elapsedTicks - down, HeroRecovery.rivet.ticks);
    final hero = _hero(s);
    expect(hero.health, 50);
    expect(hero.lane, 1);
    expect(hero.windupRemaining, 0);
    expect(s.heroRecoveryRemaining, 0);
  });

  test('without recovery the hero stays out for the wave', () {
    final s = _session(recovery: null)..start();
    _knockOut(s);
    for (var i = 0; i < 400; i++) {
      s.tick();
    }
    expect(_hero(s).isAlive, isFalse);
    expect(s.heroRecoveryRemaining, 0);
  });

  test('a hero who is down when the wave ends recovers for the next wave', () {
    final s = _session(
      later: [
        WaveDefinition(id: 'w2', spawns: [_brute(0)]),
      ],
    )..start();
    _knockOut(s);
    s.combat.areaDamage(
      faction: CombatFaction.enemy,
      lane: 1,
      centerMm: 1000,
      radiusMm: 5000,
      damage: 10000,
    );
    s.tick();
    expect(s.phase, BattlePhase.intermission);
    expect(_hero(s).health, 50);
    expect(_hero(s).positionMm, 0);
    expect(s.heroRecoveryRemaining, 0);
  });

  test('a checkpoint with the hero down restarts the recovery timer', () {
    final s = _session(
      later: [WaveDefinition(id: 'w2', spawns: [])],
    );
    expect(
      s.restoreCheckpoint(
        waveIndex: 0,
        atIntermission: false,
        fortressHealth: 100,
        heroLane: 2,
        heroHealth: 0,
        heroSp: 0,
        scrapReward: 0,
      ),
      isTrue,
    );
    expect(s.heroRecoveryRemaining, HeroRecovery.rivet.ticks);
  });
}
