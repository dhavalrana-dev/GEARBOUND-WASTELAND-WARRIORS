enum Direction { north, east, south, west }

enum GearKind { core, transmission, booster, output }

enum GearOutputKind { none, spawnInfantry, fireProjectile }

enum NetworkState { unpowered, powered, jammed, conflicted }

class GearNode {
  GearNode({
    required this.id,
    required this.definitionId,
    required this.kind,
    required this.x,
    required this.y,
    required Set<Direction> localPorts,
    this.baseIntervalTicks = 0,
    this.rotationQuarterTurns = 0,
    this.tier = 1,
    this.outputKind = GearOutputKind.none,
    this.targetLane = 1,
    this.projectileDamage = 0,
    this.projectileSpeedMmPerTick = 0,
  }) : localPorts = Set<Direction>.of(localPorts) {
    if (tier < 1) throw ArgumentError.value(tier, 'tier');
    if (outputKind == GearOutputKind.fireProjectile &&
        (projectileDamage < 1 || projectileSpeedMmPerTick < 1)) {
      throw ArgumentError('Projectile outputs need positive damage and speed.');
    }
    if (targetLane < 0 || targetLane > 2) {
      throw ArgumentError.value(targetLane, 'targetLane');
    }
    rotationQuarterTurns = (rotationQuarterTurns % 4 + 4) % 4;
  }

  final String id;
  final String definitionId;
  final GearKind kind;
  final int x;
  final int y;
  final Set<Direction> localPorts;
  final int baseIntervalTicks;
  int rotationQuarterTurns;
  final int tier;
  final GearOutputKind outputKind;
  final int targetLane;

  /// Turret outputs only: damage and speed of each fired projectile.
  final int projectileDamage;
  final int projectileSpeedMmPerTick;

  bool hasPort(Direction worldDirection) {
    final local = (worldDirection.index - rotationQuarterTurns + 4) % 4;
    return localPorts.contains(Direction.values[local]);
  }

  void rotateClockwise() =>
      rotationQuarterTurns = (rotationQuarterTurns + 1) % 4;
}

class GearBoard {
  GearBoard({this.width = 5, this.height = 5, this.maxCores = 1}) {
    if (width < 1 || height < 1) {
      throw ArgumentError('Board dimensions must be positive.');
    }
    if (maxCores < 1) throw ArgumentError.value(maxCores, 'maxCores');
  }

  final int width;
  final int height;
  final int maxCores;
  final Map<int, GearNode> _cells = {};
  Iterable<GearNode> get nodes => _cells.values;

  int _key(int x, int y) => y * width + x;
  GearNode? at(int x, int y) => _cells[_key(x, y)];

  bool place(GearNode node) {
    if (node.x < 0 || node.y < 0 || node.x >= width || node.y >= height) {
      return false;
    }
    if (_cells.containsKey(_key(node.x, node.y))) return false;
    if (_cells.values.any((existing) => existing.id == node.id)) return false;
    if (node.kind == GearKind.core &&
        _cells.values
                .where((existing) => existing.kind == GearKind.core)
                .length >=
            maxCores) {
      return false;
    }
    _cells[_key(node.x, node.y)] = node;
    return true;
  }

  bool removeAt(int x, int y) => _cells.remove(_key(x, y)) != null;

  GearNode? merge(
    int x1,
    int y1,
    int x2,
    int y2, {
    required int maxTier,
    required int nextTierBaseIntervalTicks,
  }) {
    final first = at(x1, y1);
    final second = at(x2, y2);
    if (first == null || second == null || identical(first, second)) {
      return null;
    }
    if (first.kind == GearKind.core || second.kind == GearKind.core) {
      return null;
    }
    if (first.definitionId != second.definitionId ||
        first.kind != second.kind ||
        first.tier != second.tier) {
      return null;
    }
    if (first.tier >= maxTier || nextTierBaseIntervalTicks < 0) return null;
    final anchor =
        (first.y < second.y || (first.y == second.y && first.x <= second.x))
        ? first
        : second;
    final id =
        '${anchor.definitionId}:t${anchor.tier + 1}@${anchor.x},${anchor.y}';
    if (_cells.values.any(
      (node) =>
          node.id == id && !identical(node, first) && !identical(node, second),
    )) {
      return null;
    }
    _cells.remove(_key(first.x, first.y));
    _cells.remove(_key(second.x, second.y));
    final merged = GearNode(
      id: id,
      definitionId: anchor.definitionId,
      kind: anchor.kind,
      x: anchor.x,
      y: anchor.y,
      localPorts: anchor.localPorts,
      baseIntervalTicks: nextTierBaseIntervalTicks,
      rotationQuarterTurns: anchor.rotationQuarterTurns,
      tier: anchor.tier + 1,
      outputKind: anchor.outputKind,
      targetLane: anchor.targetLane,
      projectileDamage: anchor.projectileDamage,
      projectileSpeedMmPerTick: anchor.projectileSpeedMmPerTick,
    );
    _cells[_key(merged.x, merged.y)] = merged;
    return merged;
  }
}

class GearNodeResult {
  const GearNodeResult({
    required this.id,
    required this.state,
    required this.rotationParity,
    required this.boosterBonusPercent,
    required this.effectiveIntervalTicks,
  });

  final String id;
  final NetworkState state;
  final int rotationParity;
  final int boosterBonusPercent;
  final int effectiveIntervalTicks;
}

class GearNetworkResult {
  const GearNetworkResult({required this.nodes, required this.edges});
  final Map<String, GearNodeResult> nodes;
  final List<(String, String)> edges;
}

class GearNetwork {
  static const _steps = <(Direction, int, int)>[
    (Direction.north, 0, -1),
    (Direction.east, 1, 0),
    (Direction.south, 0, 1),
    (Direction.west, -1, 0),
  ];

  static GearNetworkResult rebuild(
    GearBoard board, {
    int boosterEachPercent = 10,
    int boosterCapPercent = 30,
  }) {
    if (boosterEachPercent < 0 || boosterCapPercent < 0) {
      throw ArgumentError('Booster modifiers must be non-negative.');
    }
    final ordered = board.nodes.toList()
      ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
    final adjacency = <String, List<GearNode>>{
      for (final node in ordered) node.id: <GearNode>[],
    };
    final edges = <(String, String)>[];
    for (final node in ordered) {
      for (final (direction, dx, dy) in _steps) {
        final neighbor = board.at(node.x + dx, node.y + dy);
        if (neighbor == null || node.id.compareTo(neighbor.id) >= 0) continue;
        final reciprocal = Direction.values[(direction.index + 2) % 4];
        if (!node.hasPort(direction) || !neighbor.hasPort(reciprocal)) continue;
        adjacency[node.id]!.add(neighbor);
        adjacency[neighbor.id]!.add(node);
        edges.add((node.id, neighbor.id));
      }
    }

    final results = <String, GearNodeResult>{};
    final visited = <String>{};
    for (final root in ordered) {
      if (!visited.add(root.id)) continue;
      final component = <GearNode>[];
      final parity = <String, int>{root.id: 0};
      final queue = <GearNode>[root];
      var head = 0;
      var oddLoop = false;
      while (head < queue.length) {
        final current = queue[head++];
        component.add(current);
        for (final neighbor in adjacency[current.id]!) {
          final expected = 1 - parity[current.id]!;
          if (!parity.containsKey(neighbor.id)) {
            parity[neighbor.id] = expected;
            visited.add(neighbor.id);
            queue.add(neighbor);
          } else if (parity[neighbor.id] != expected) {
            oddLoop = true;
          }
        }
      }

      final coreCount = component
          .where((node) => node.kind == GearKind.core)
          .length;
      final state = coreCount == 0
          ? NetworkState.unpowered
          : coreCount > 1
          ? NetworkState.conflicted
          : oddLoop
          ? NetworkState.jammed
          : NetworkState.powered;
      final boosters = component
          .where((node) => node.kind == GearKind.booster)
          .length;
      final bonus = boosters * boosterEachPercent < boosterCapPercent
          ? boosters * boosterEachPercent
          : boosterCapPercent;
      for (final node in component) {
        final nodeBonus =
            node.kind == GearKind.output && state == NetworkState.powered
            ? bonus
            : 0;
        final interval =
            node.kind == GearKind.output &&
                state == NetworkState.powered &&
                node.baseIntervalTicks > 0
            ? ((node.baseIntervalTicks * 100 + 100 + nodeBonus - 1) ~/
                  (100 + nodeBonus))
            : 0;
        results[node.id] = GearNodeResult(
          id: node.id,
          state: state,
          rotationParity: parity[node.id]!,
          boosterBonusPercent: nodeBonus,
          effectiveIntervalTicks: interval,
        );
      }
    }
    return GearNetworkResult(nodes: results, edges: edges);
  }
}

GearBoard makeStarterBoard() {
  final board = GearBoard();
  GearNode node(String id, GearKind kind, int x, int y, {int interval = 0}) =>
      GearNode(
        id: id,
        definitionId: id,
        kind: kind,
        x: x,
        y: y,
        localPorts: Direction.values.toSet(),
        baseIntervalTicks: interval,
      );
  board.place(node('core-wayfarer', GearKind.core, 0, 2));
  board.place(node('drive-a', GearKind.transmission, 1, 2));
  board.place(node('booster-a', GearKind.booster, 2, 2));
  board.place(node('drive-b', GearKind.transmission, 3, 2));
  board.place(
    GearNode(
      id: 'press-demo',
      definitionId: 'unit.rivetguard',
      kind: GearKind.output,
      x: 4,
      y: 2,
      localPorts: Direction.values.toSet(),
      baseIntervalTicks: 90,
      outputKind: GearOutputKind.spawnInfantry,
    ),
  );
  board.place(node('turret-demo', GearKind.output, 3, 1, interval: 45));
  return board;
}
