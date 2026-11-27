import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/mechanical/gear_network.dart';

void main() {
  group('BattleSession', () {
    test(
      'waits for scheduled spawns and awards the wave reward on victory',
      () {
        final board = GearBoard();
        final combat = CombatSimulation(worldLengthMm: 1000);
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
        final wave = WaveDefinition(
          id: 'test.wave',
          spawns: [
            WaveSpawnEvent(
              tick: 2,
              lane: 1,
              health: 10,
              armor: 0,
              damage: 1,
              attackRangeMm: 0,
              movementMmPerTick: 0,
              attackIntervalTicks: 1,
            ),
          ],
          rewardScrap: 4,
        );
        final session = BattleSession(
          board: board,
          network: GearNetwork.rebuild(board),
          wave: wave,
          combat: combat,
        );
        expect(session.start(), isTrue);
        session.tick();
        expect(session.phase, BattlePhase.combat);
        session.tick();
        expect(session.phase, BattlePhase.combat);
        session.tick();
        expect(session.phase, BattlePhase.victory);
        expect(session.scrapReward, 4);
      },
    );

    test('fortress defeat ends the active wave', () {
      final board = GearBoard();
      final combat = CombatSimulation(fortressHealth: 5);
      final wave = WaveDefinition(
        id: 'test.wave',
        spawns: [
          WaveSpawnEvent(
            tick: 0,
            lane: 0,
            health: 10,
            armor: 0,
            damage: 5,
            attackRangeMm: 0,
            movementMmPerTick: 20000,
            attackIntervalTicks: 1,
          ),
        ],
      );
      final session = BattleSession(
        board: board,
        network: GearNetwork.rebuild(board),
        wave: wave,
        combat: combat,
      );
      session.start();
      session.tick();
      expect(session.phase, BattlePhase.defeat);
    });

    test('hero lane command is preserved by the simulation', () {
      final board = GearBoard();
      final session = BattleSession(
        board: board,
        network: GearNetwork.rebuild(board),
        wave: WaveDefinition(id: 'empty', spawns: []),
      );
      expect(session.moveHeroToLane(2), isTrue);
      expect(
        session.combat.combatants
            .firstWhere((unit) => unit.id == session.heroId)
            .lane,
        2,
      );
    });
  });
}
