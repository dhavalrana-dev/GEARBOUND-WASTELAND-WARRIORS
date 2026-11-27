// ignore_for_file: avoid_print

import 'package:gearbound/mechanical/gear_network.dart';

void main() {
  var passed = 0;
  void check(String name, void Function() body) {
    body();
    passed++;
    print('PASS $name');
  }

  GearNode gear(String id, GearKind kind, int x, int y, {int interval = 0}) =>
      GearNode(
        id: id,
        definitionId: id,
        kind: kind,
        x: x,
        y: y,
        localPorts: Direction.values.toSet(),
        baseIntervalTicks: interval,
      );

  check('powered chain and alternating rotation', () {
    final board = GearBoard();
    board.place(gear('core', GearKind.core, 0, 0));
    board.place(gear('shaft', GearKind.transmission, 1, 0));
    board.place(gear('press', GearKind.output, 2, 0, interval: 90));
    final result = GearNetwork.rebuild(board);
    assert(result.nodes['press']!.state == NetworkState.powered);
    assert(
      result.nodes['shaft']!.rotationParity == 1 &&
          result.nodes['press']!.rotationParity == 0,
    );
  });
  check('disconnected output remains inactive', () {
    final board = GearBoard();
    board.place(gear('core', GearKind.core, 0, 0));
    board.place(gear('press', GearKind.output, 4, 4, interval: 90));
    assert(
      GearNetwork.rebuild(board).nodes['press']!.state ==
          NetworkState.unpowered,
    );
  });
  check('MVP board enforces a single core', () {
    final board = GearBoard();
    assert(board.place(gear('core-a', GearKind.core, 0, 0)));
    assert(!board.place(gear('core-b', GearKind.core, 4, 4)));
  });
  check('removal disables dependent output', () {
    final board = GearBoard();
    board.place(gear('core', GearKind.core, 0, 0));
    board.place(gear('shaft', GearKind.transmission, 1, 0));
    board.place(gear('press', GearKind.output, 2, 0, interval: 90));
    board.removeAt(1, 0);
    assert(
      GearNetwork.rebuild(board).nodes['press']!.state ==
          NetworkState.unpowered,
    );
  });
  check('booster cap and output interval match shared rule', () {
    final board = GearBoard();
    board.place(gear('core', GearKind.core, 0, 0));
    for (var x = 1; x <= 4; x++) {
      board.place(gear('boost-$x', GearKind.booster, x, 0));
    }
    board.place(gear('press', GearKind.output, 4, 1, interval: 90));
    final result = GearNetwork.rebuild(board).nodes['press']!;
    assert(
      result.boosterBonusPercent == 30 && result.effectiveIntervalTicks == 70,
    );
  });
  check('even loop and multiple-core conflict', () {
    final loop = GearBoard();
    loop.place(gear('core', GearKind.core, 0, 0));
    loop.place(gear('east', GearKind.transmission, 1, 0));
    loop.place(gear('south', GearKind.transmission, 0, 1));
    loop.place(gear('corner', GearKind.transmission, 1, 1));
    assert(
      GearNetwork.rebuild(loop).nodes['corner']!.state == NetworkState.powered,
    );
    final conflict = GearBoard(maxCores: 2);
    conflict.place(gear('core-a', GearKind.core, 0, 0));
    conflict.place(gear('core-b', GearKind.core, 1, 0));
    conflict.place(gear('press', GearKind.output, 2, 0, interval: 90));
    assert(
      GearNetwork.rebuild(conflict).nodes['press']!.state ==
          NetworkState.conflicted,
    );
  });
  check('merge uses deterministic anchor and configured interval', () {
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
    assert(
      merged.x == 1 &&
          merged.y == 0 &&
          merged.tier == 2 &&
          merged.baseIntervalTicks == 60,
    );
  });
  print('RESULT $passed checks passed.');
}
