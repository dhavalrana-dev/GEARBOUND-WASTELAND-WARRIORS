import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/combat_simulation.dart';
import 'package:gearbound/mechanical/gear_network.dart';
import 'package:gearbound/mechanical/gear_output_system.dart';

final _ports = Direction.values.toSet();

GearBoard _connectedBoard(int interval) {
  final board = GearBoard();
  board.place(
    GearNode(
      id: 'core',
      definitionId: 'core',
      kind: GearKind.core,
      x: 0,
      y: 0,
      localPorts: _ports,
    ),
  );
  board.place(
    GearNode(
      id: 'drive',
      definitionId: 'drive',
      kind: GearKind.transmission,
      x: 1,
      y: 0,
      localPorts: _ports,
    ),
  );
  board.place(
    GearNode(
      id: 'press',
      definitionId: 'unit.rivetguard',
      kind: GearKind.output,
      x: 2,
      y: 0,
      localPorts: _ports,
      baseIntervalTicks: interval,
      outputKind: GearOutputKind.spawnInfantry,
    ),
  );
  return board;
}

void main() {
  group('GearOutputSystem', () {
    test('spawns infantry at the powered gear fixed-tick interval', () {
      final board = _connectedBoard(3);
      final network = GearNetwork.rebuild(board);
      final combat = CombatSimulation();
      final output = GearOutputSystem();
      for (var tick = 0; tick < 9; tick++) {
        output.tick(board, network, combat);
      }
      expect(combat.combatants.length, 3);
      expect(output.clocks['press']!.progressTicks, 0);
      expect(output.clocks['press']!.status, GearOutputStatus.produced);
    });

    test('disconnect pauses output and leaves produced units in battle', () {
      final board = _connectedBoard(3);
      final combat = CombatSimulation();
      final output = GearOutputSystem();
      var network = GearNetwork.rebuild(board);
      for (var tick = 0; tick < 3; tick++) {
        output.tick(board, network, combat);
      }
      expect(combat.combatants.length, 1);
      board.removeAt(1, 0);
      network = GearNetwork.rebuild(board);
      output.tick(board, network, combat);
      expect(combat.combatants.length, 1);
      expect(output.clocks['press']!.status, GearOutputStatus.inactive);
    });

    test('unit cap holds one pending spawn', () {
      final board = _connectedBoard(1);
      final combat = CombatSimulation();
      combat.add(
        Combatant(
          id: 5,
          faction: CombatFaction.friendly,
          lane: 1,
          positionMm: 0,
          health: 30,
          armor: 0,
          damage: 1,
          attackRangeMm: 0,
          movementMmPerTick: 0,
          attackIntervalTicks: 1,
        ),
      );
      final output = GearOutputSystem(unitCapPerLane: 1);
      output.tick(board, GearNetwork.rebuild(board), combat);
      expect(combat.combatants.length, 1);
      expect(output.clocks['press']!.pendingSpawn, isTrue);
      expect(
        output.clocks['press']!.status,
        GearOutputStatus.unitCapacityReached,
      );
    });
  });
}
