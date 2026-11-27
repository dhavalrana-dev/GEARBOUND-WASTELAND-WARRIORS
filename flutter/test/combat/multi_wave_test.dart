import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/mechanical/gear_network.dart';

WaveSpawnEvent _weak(int tick) => WaveSpawnEvent(
  tick: tick,
  lane: 1,
  health: 10,
  armor: 0,
  damage: 1,
  attackRangeMm: 0,
  movementMmPerTick: 0,
  attackIntervalTicks: 1,
);

BattleSession _session(List<WaveDefinition> waves, {int fortress = 100}) {
  final combat = CombatSimulation(
    worldLengthMm: 1000,
    fortressHealth: fortress,
  );
  combat.add(
    Combatant(
      id: 1,
      faction: CombatFaction.friendly,
      lane: 1,
      positionMm: 0,
      health: 100,
      armor: 0,
      damage: 50,
      attackRangeMm: 1000,
      movementMmPerTick: 0,
      attackIntervalTicks: 1,
    ),
  );
  final board = GearBoard();
  return BattleSession(
    board: board,
    network: GearNetwork.rebuild(board),
    wave: waves.first,
    laterWaves: waves.skip(1).toList(),
    combat: combat,
  );
}

void runUntilPaused(BattleSession s) {
  for (var i = 0; i < 1000 && s.phase == BattlePhase.combat; i++) {
    s.tick();
  }
}

void main() {
  final w1 = WaveDefinition(id: 'w1', spawns: [_weak(2)], rewardScrap: 3);
  final w2 = WaveDefinition(
    id: 'w2',
    spawns: [_weak(5), _weak(9)],
    rewardScrap: 4,
  );
  final w3 = WaveDefinition(id: 'w3', spawns: [_weak(1)], rewardScrap: 6);

  test('clearing a non-final wave enters intermission with its reward', () {
    final s = _session([w1, w2, w3]);
    expect(s.start(), isTrue);
    runUntilPaused(s);
    expect(s.phase, BattlePhase.intermission);
    expect(s.waveIndex, 0);
    expect(s.lastWaveReward, 3);
    expect(s.scrapReward, 3);
  });

  test('intermission does not tick; start begins the next wave', () {
    final s = _session([w1, w2, w3])..start();
    runUntilPaused(s);
    final ticks = s.elapsedTicks;
    s.tick();
    expect(s.elapsedTicks, ticks);
    expect(s.start(), isTrue);
    expect(s.waveIndex, 1);
    expect(s.currentWave.id, 'w2');
  });

  test('spawn ticks are relative to each wave start', () {
    final s = _session([w1, w2])..start();
    runUntilPaused(s);
    final waveStart = s.elapsedTicks;
    s.start();
    for (var i = 0; i < 5; i++) {
      s.tick();
    }
    // w2's first spawn is at tick 5 of the wave, so none has spawned yet.
    expect(
      s.combat.combatants.where((u) => u.faction == CombatFaction.enemy).length,
      1, // only w1's (dead) enemy
    );
    s.tick();
    expect(
      s.combat.combatants
          .where((u) => u.faction == CombatFaction.enemy && u.isAlive)
          .length,
      lessThanOrEqualTo(1),
    );
    expect(s.elapsedTicks - waveStart, 6);
  });

  test('the final wave ends in victory with the total reward', () {
    final s = _session([w1, w2, w3])..start();
    for (var wave = 0; wave < 3; wave++) {
      runUntilPaused(s);
      if (s.phase == BattlePhase.intermission) s.start();
    }
    expect(s.phase, BattlePhase.victory);
    expect(s.scrapReward, 3 + 4 + 6);
    expect(s.start(), isFalse);
  });

  test('at intermission soldiers withdraw, the hero returns, damage stays', () {
    final s = _session([w1, w2]);
    final hero = s.combat.combatants.firstWhere((u) => u.id == 1);
    hero.positionMm = 400;
    s.combat.add(
      Combatant(
        id: 100000,
        faction: CombatFaction.friendly,
        lane: 0,
        positionMm: 300,
        health: 30,
        armor: 0,
        damage: 5,
        attackRangeMm: 250,
        movementMmPerTick: 0,
        attackIntervalTicks: 24,
      ),
    );
    s.start();
    runUntilPaused(s);
    expect(s.phase, BattlePhase.intermission);
    expect(s.combat.combatants.any((u) => u.id == 100000), isFalse);
    expect(s.combat.combatants.contains(hero), isTrue);
    expect(hero.positionMm, 0);
    expect(hero.isAlive, isTrue);
  });

  test('fortress damage carries into the next wave', () {
    final hurt = WaveDefinition(
      id: 'hurt',
      spawns: [
        WaveSpawnEvent(
          tick: 0,
          lane: 0,
          health: 1000,
          armor: 0,
          damage: 7,
          attackRangeMm: 0,
          movementMmPerTick: 1000,
          attackIntervalTicks: 1,
        ),
      ],
    );
    // The hero sits in lane 1 and cannot reach lane 0: the raider hits the
    // fortress until the test withdraws it.
    final s = _session([hurt, w2])..start();
    for (var i = 0; i < 5; i++) {
      s.tick();
    }
    final damaged = s.combat.fortressHealth;
    expect(damaged, lessThan(100));
    s.combat.withdraw((u) => u.faction == CombatFaction.enemy);
    s.tick();
    expect(s.phase, BattlePhase.intermission);
    s.start();
    expect(s.combat.fortressHealth, damaged);
  });

  test('a single-wave session still ends in victory, as before', () {
    final s = _session([w1])..start();
    runUntilPaused(s);
    expect(s.phase, BattlePhase.victory);
    expect(s.scrapReward, 3);
  });
}
