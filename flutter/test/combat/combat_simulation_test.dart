import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/combat_simulation.dart';

void main() {
  group('CombatSimulation', () {
    test('moves units on fixed ticks and keeps lanes separate', () {
      final simulation = CombatSimulation(worldLengthMm: 1000);
      final friendly = Combatant(
        id: 1,
        faction: CombatFaction.friendly,
        lane: 0,
        positionMm: 0,
        health: 20,
        armor: 0,
        damage: 5,
        attackRangeMm: 20,
        movementMmPerTick: 100,
        attackIntervalTicks: 10,
      );
      final enemy = Combatant(
        id: 2,
        faction: CombatFaction.enemy,
        lane: 1,
        positionMm: 1000,
        health: 20,
        armor: 0,
        damage: 5,
        attackRangeMm: 20,
        movementMmPerTick: 100,
        attackIntervalTicks: 10,
      );
      simulation.add(friendly);
      simulation.add(enemy);
      simulation.tick();
      expect(friendly.positionMm, 100);
      expect(enemy.positionMm, 900);
      expect(friendly.health, 20);
      expect(enemy.health, 20);
    });

    test('applies armor, reduction, and shield in order', () {
      final simulation = CombatSimulation();
      final attacker = Combatant(
        id: 1,
        faction: CombatFaction.friendly,
        lane: 1,
        positionMm: 1000,
        health: 100,
        armor: 0,
        damage: 11,
        attackRangeMm: 100,
        movementMmPerTick: 0,
        attackIntervalTicks: 10,
      );
      final defender = Combatant(
        id: 2,
        faction: CombatFaction.enemy,
        lane: 1,
        positionMm: 1050,
        health: 20,
        armor: 2,
        damage: 1,
        attackRangeMm: 0,
        movementMmPerTick: 0,
        attackIntervalTicks: 10,
        shield: 2,
        damageReductionPercent: 25,
      );
      simulation.add(attacker);
      simulation.add(defender);
      simulation.tick();
      expect(defender.shield, 0);
      expect(defender.health, 16);
    });

    test('resolves both hits in a mutual knockout', () {
      final simulation = CombatSimulation();
      final friendly = Combatant(
        id: 1,
        faction: CombatFaction.friendly,
        lane: 0,
        positionMm: 1000,
        health: 5,
        armor: 0,
        damage: 5,
        attackRangeMm: 0,
        movementMmPerTick: 0,
        attackIntervalTicks: 1,
      );
      final enemy = Combatant(
        id: 2,
        faction: CombatFaction.enemy,
        lane: 0,
        positionMm: 1000,
        health: 5,
        armor: 0,
        damage: 5,
        attackRangeMm: 0,
        movementMmPerTick: 0,
        attackIntervalTicks: 1,
      );
      simulation.add(friendly);
      simulation.add(enemy);
      simulation.tick();
      expect(friendly.state, CombatState.dead);
      expect(enemy.state, CombatState.dead);
    });

    test('fortress defeat halts later ticks', () {
      final simulation = CombatSimulation(fortressHealth: 10);
      simulation.add(
        Combatant(
          id: 1,
          faction: CombatFaction.enemy,
          lane: 2,
          positionMm: 0,
          health: 20,
          armor: 0,
          damage: 10,
          attackRangeMm: 0,
          movementMmPerTick: 0,
          attackIntervalTicks: 1,
        ),
      );
      simulation.tick();
      simulation.tick();
      expect(simulation.fortressHealth, 0);
      expect(simulation.isDefeated, isTrue);
      expect(simulation.tickIndex, 1);
    });
  });
}
