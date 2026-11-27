import '../mechanical/gear_network.dart';
import '../mechanical/gear_output_system.dart';
import 'combat_simulation.dart';

/// Mission phases. `intermission` sits between waves: combat is paused, the
/// fortress keeps its damage, the hero returns to the fortress line keeping
/// its health and lane, and gear-produced soldiers
/// withdraw, so each wave tests the machine rather than a carried-over army.
/// The workshop may be edited before [BattleSession.start] begins the next wave.
enum BattlePhase { preparation, combat, intermission, victory, defeat }

class WaveSpawnEvent {
  WaveSpawnEvent({
    required this.tick,
    required this.lane,
    required this.health,
    required this.armor,
    required this.damage,
    required this.attackRangeMm,
    required this.movementMmPerTick,
    required this.attackIntervalTicks,
  }) {
    if (tick < 0 ||
        lane < 0 ||
        lane > 2 ||
        health <= 0 ||
        armor < 0 ||
        damage <= 0 ||
        attackRangeMm < 0 ||
        movementMmPerTick < 0 ||
        attackIntervalTicks < 1) {
      throw ArgumentError('Wave spawn data is outside its allowed range.');
    }
  }

  final int tick;
  final int lane;
  final int health;
  final int armor;
  final int damage;
  final int attackRangeMm;
  final int movementMmPerTick;
  final int attackIntervalTicks;
}

class WaveDefinition {
  WaveDefinition({
    required this.id,
    required List<WaveSpawnEvent> spawns,
    this.rewardScrap = 0,
  }) : spawns = List.unmodifiable(_ordered(spawns)) {
    if (id.trim().isEmpty || rewardScrap < 0) {
      throw ArgumentError('Invalid wave definition.');
    }
  }

  final String id;
  final List<WaveSpawnEvent> spawns;
  final int rewardScrap;

  static List<WaveSpawnEvent> _ordered(List<WaveSpawnEvent> spawns) {
    final indexed = spawns.asMap().entries.toList();
    indexed.sort((a, b) {
      final tickOrder = a.value.tick.compareTo(b.value.tick);
      if (tickOrder != 0) return tickOrder;
      final laneOrder = a.value.lane.compareTo(b.value.lane);
      return laneOrder != 0 ? laneOrder : a.key.compareTo(b.key);
    });
    return indexed.map((entry) => entry.value).toList();
  }
}

class BattleSession {
  BattleSession({
    required this.board,
    required this.network,
    required this.wave,
    List<WaveDefinition> laterWaves = const [],
    int heroId = 1,
    CombatSimulation? combat,
    GearOutputSystem? outputs,
  }) : waves = List.unmodifiable([wave, ...laterWaves]),
       heroId = heroId,
       combat = combat ?? CombatSimulation(),
       outputs = outputs ?? GearOutputSystem() {
    if (!this.combat.combatants.any((unit) => unit.id == heroId)) {
      this.combat.add(
        Combatant(
          id: heroId,
          faction: CombatFaction.friendly,
          lane: 1,
          positionMm: 0,
          health: 100,
          armor: 2,
          damage: 12,
          attackRangeMm: 900,
          movementMmPerTick: 35,
          attackIntervalTicks: 18,
        ),
      );
    }
  }

  final GearBoard board;
  GearNetworkResult network;

  /// First wave (kept for single-wave callers).
  final WaveDefinition wave;

  /// Every wave in order; a single-wave session behaves exactly as before.
  final List<WaveDefinition> waves;
  final CombatSimulation combat;
  final GearOutputSystem outputs;
  final int heroId;
  BattlePhase phase = BattlePhase.preparation;
  int elapsedTicks = 0;

  /// Total wave rewards earned so far this mission.
  int scrapReward = 0;

  /// Reward of the most recently cleared wave.
  int lastWaveReward = 0;
  int waveIndex = 0;
  int _waveStartTick = 0;
  int _nextSpawnIndex = 0;
  int _nextEnemyId = 1000;

  void refreshNetwork() => network = GearNetwork.rebuild(board);
  bool moveHeroToLane(int lane) => combat.moveLane(heroId, lane);

  WaveDefinition get currentWave => waves[waveIndex];
  bool get isFinalWave => waveIndex == waves.length - 1;

  /// Starts the first wave from preparation, or the next wave from an
  /// intermission. Spawn ticks are relative to each wave's start.
  bool start() {
    if (phase == BattlePhase.intermission) {
      waveIndex++;
      _nextSpawnIndex = 0;
      _waveStartTick = elapsedTicks;
    } else if (phase != BattlePhase.preparation) {
      return false;
    }
    phase = BattlePhase.combat;
    return true;
  }

  void tick() {
    if (phase != BattlePhase.combat) return;
    final wave = currentWave;
    while (_nextSpawnIndex < wave.spawns.length &&
        wave.spawns[_nextSpawnIndex].tick <= elapsedTicks - _waveStartTick) {
      final spawn = wave.spawns[_nextSpawnIndex++];
      combat.add(
        Combatant(
          id: _nextEnemyId++,
          faction: CombatFaction.enemy,
          lane: spawn.lane,
          positionMm: combat.worldLengthMm,
          health: spawn.health,
          armor: spawn.armor,
          damage: spawn.damage,
          attackRangeMm: spawn.attackRangeMm,
          movementMmPerTick: spawn.movementMmPerTick,
          attackIntervalTicks: spawn.attackIntervalTicks,
        ),
      );
    }

    combat.tick();
    outputs.tick(board, network, combat);
    elapsedTicks++;

    if (combat.isDefeated) {
      phase = BattlePhase.defeat;
    } else if (_nextSpawnIndex >= wave.spawns.length &&
        !combat.combatants.any(
          (unit) => unit.isAlive && unit.faction == CombatFaction.enemy,
        )) {
      lastWaveReward = wave.rewardScrap;
      scrapReward += wave.rewardScrap;
      if (isFinalWave) {
        phase = BattlePhase.victory;
      } else {
        phase = BattlePhase.intermission;
        combat.withdraw(
          (unit) => unit.faction == CombatFaction.friendly && unit.id != heroId,
        );
        // The hero returns to the fortress line (health and lane are kept),
        // so every wave starts from the same position.
        for (final unit in combat.combatants) {
          if (unit.id == heroId) unit.positionMm = 0;
        }
      }
    }
  }
}
