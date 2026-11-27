import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/mechanical/gear_network.dart';

GearNode _gear(String id, GearKind kind, int x, int y, {int interval = 0}) =>
    GearNode(
      id: id,
      definitionId: id,
      kind: kind,
      x: x,
      y: y,
      localPorts: Direction.values.toSet(),
      baseIntervalTicks: interval,
    );

void main() {
  group('GearNetwork', () {
    test('powers a chain and alternates rotation parity', () {
      final board = GearBoard();
      board.place(_gear('core', GearKind.core, 0, 0));
      board.place(_gear('shaft', GearKind.transmission, 1, 0));
      board.place(_gear('press', GearKind.output, 2, 0, interval: 90));
      final output = GearNetwork.rebuild(board).nodes['press']!;
      expect(output.state, NetworkState.powered);
      expect(output.effectiveIntervalTicks, 90);
    });

    test('leaves disconnected output inactive and removal cuts power', () {
      final board = GearBoard();
      board.place(_gear('core', GearKind.core, 0, 0));
      board.place(_gear('shaft', GearKind.transmission, 1, 0));
      board.place(_gear('press', GearKind.output, 2, 0, interval: 90));
      board.place(_gear('remote', GearKind.output, 4, 4, interval: 90));
      expect(
        GearNetwork.rebuild(board).nodes['remote']!.state,
        NetworkState.unpowered,
      );
      board.removeAt(1, 0);
      expect(
        GearNetwork.rebuild(board).nodes['press']!.state,
        NetworkState.unpowered,
      );
    });

    test('caps booster stacking at thirty percent', () {
      final board = GearBoard();
      board.place(_gear('core', GearKind.core, 0, 0));
      for (var x = 1; x <= 4; x++) {
        board.place(_gear('booster-$x', GearKind.booster, x, 0));
      }
      board.place(_gear('press', GearKind.output, 4, 1, interval: 90));
      final output = GearNetwork.rebuild(board).nodes['press']!;
      expect(output.boosterBonusPercent, 30);
      expect(output.effectiveIntervalTicks, 70);
    });

    test('accepts an even loop and disables a component with two cores', () {
      final loop = GearBoard();
      loop.place(_gear('core', GearKind.core, 0, 0));
      loop.place(_gear('east', GearKind.transmission, 1, 0));
      loop.place(_gear('south', GearKind.transmission, 0, 1));
      loop.place(_gear('corner', GearKind.transmission, 1, 1));
      expect(
        GearNetwork.rebuild(loop).nodes['corner']!.state,
        NetworkState.powered,
      );
      final conflict = GearBoard(maxCores: 2);
      conflict.place(_gear('core-a', GearKind.core, 0, 0));
      conflict.place(_gear('core-b', GearKind.core, 1, 0));
      conflict.place(_gear('press', GearKind.output, 2, 0, interval: 90));
      expect(
        GearNetwork.rebuild(conflict).nodes['press']!.state,
        NetworkState.conflicted,
      );
    });

    test('merges a matching pair into the deterministic anchor cell', () {
      final board = GearBoard();
      board.place(
        GearNode(
          id: 'p1',
          definitionId: 'unit.press',
          kind: GearKind.output,
          x: 2,
          y: 1,
          localPorts: Direction.values.toSet(),
          baseIntervalTicks: 90,
        ),
      );
      board.place(
        GearNode(
          id: 'p2',
          definitionId: 'unit.press',
          kind: GearKind.output,
          x: 1,
          y: 0,
          localPorts: Direction.values.toSet(),
          baseIntervalTicks: 90,
        ),
      );
      final merged = board.merge(
        2,
        1,
        1,
        0,
        maxTier: 3,
        nextTierBaseIntervalTicks: 60,
      )!;
      expect(
        (merged.x, merged.y, merged.tier, merged.baseIntervalTicks),
        (1, 0, 2, 60),
      );
      expect(board.at(2, 1), isNull);
    });

    test('rejects invalid and occupied cells', () {
      final board = GearBoard();
      expect(board.place(_gear('outside', GearKind.core, -1, 0)), isFalse);
      expect(board.place(_gear('core', GearKind.core, 0, 0)), isTrue);
      expect(
        board.place(_gear('duplicate-cell', GearKind.output, 0, 0)),
        isFalse,
      );
    });

    test('MVP board allows only one core', () {
      final board = GearBoard();
      expect(board.place(_gear('core-a', GearKind.core, 0, 0)), isTrue);
      expect(board.place(_gear('core-b', GearKind.core, 4, 4)), isFalse);
    });
  });
}
