import '../combat/combat_simulation.dart';
import 'gear_network.dart';

enum GearOutputStatus { inactive, progressing, unitCapacityReached, produced }

class GearOutputClock {
  GearOutputClock(this.gearId);
  final String gearId;
  int progressTicks = 0;
  bool pendingSpawn = false;
  GearOutputStatus status = GearOutputStatus.inactive;
}

class GearOutputSystem {
  GearOutputSystem({this.unitCapPerLane = 4, int firstEntityId = 100000})
    : _nextEntityId = firstEntityId {
    if (unitCapPerLane < 1 || firstEntityId < 1) {
      throw ArgumentError('Output limits and IDs must be positive.');
    }
  }

  final int unitCapPerLane;
  int _nextEntityId;
  final Map<String, GearOutputClock> _clocks = {};
  Map<String, GearOutputClock> get clocks => Map.unmodifiable(_clocks);

  void tick(
    GearBoard board,
    GearNetworkResult network,
    CombatSimulation combat,
  ) {
    final activeGearIds = <String>{};
    final ordered = board.nodes.toList()
      ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
    for (final gear in ordered) {
      if (gear.kind != GearKind.output ||
          gear.outputKind != GearOutputKind.spawnInfantry) {
        continue;
      }
      activeGearIds.add(gear.id);
      final clock = _clocks.putIfAbsent(
        gear.id,
        () => GearOutputClock(gear.id),
      );
      final power = network.nodes[gear.id];
      if (power == null ||
          power.state != NetworkState.powered ||
          power.effectiveIntervalTicks < 1) {
        clock.status = GearOutputStatus.inactive;
        continue;
      }

      if (!clock.pendingSpawn) clock.progressTicks++;
      if (!clock.pendingSpawn &&
          clock.progressTicks < power.effectiveIntervalTicks) {
        clock.status = GearOutputStatus.progressing;
        continue;
      }

      final friendlyInLane = combat.combatants
          .where(
            (unit) =>
                unit.isAlive &&
                unit.faction == CombatFaction.friendly &&
                unit.lane == gear.targetLane,
          )
          .length;
      if (friendlyInLane >= unitCapPerLane) {
        clock.pendingSpawn = true;
        clock.progressTicks = power.effectiveIntervalTicks;
        clock.status = GearOutputStatus.unitCapacityReached;
        continue;
      }

      while (!combat.add(
        Combatant(
          id: _nextEntityId++,
          faction: CombatFaction.friendly,
          lane: gear.targetLane,
          positionMm: 0,
          health: 30,
          armor: 1,
          damage: 5,
          attackRangeMm: 250,
          movementMmPerTick: 40,
          attackIntervalTicks: 24,
        ),
      )) {}
      clock.pendingSpawn = false;
      clock.progressTicks = 0;
      clock.status = GearOutputStatus.produced;
    }
    _clocks.removeWhere((gearId, _) => !activeGearIds.contains(gearId));
  }
}
