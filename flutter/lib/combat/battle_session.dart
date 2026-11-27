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
    this.windupTicks = 0,
    this.cleave = false,
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
  final int windupTicks;
  final bool cleave;
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

/// A hero's special ability, from shared/heroes/heroes.json.
class HeroSpecial {
  const HeroSpecial({
    required this.id,
    required this.spMax,
    required this.spPerHit,
    required this.damage,
    required this.radiusMm,
  });

  /// Rivet's Wrench Quake. The parity test keeps this equal to heroes.json.
  static const rivet = HeroSpecial(
    id: 'special.wrench_quake',
    spMax: 100,
    spPerHit: 10,
    damage: 25,
    radiusMm: 1200,
  );

  final String id;
  final int spMax;
  final int spPerHit;
  final int damage;
  final int radiusMm;
}

class BattleSession {
  BattleSession({
    required this.board,
    required this.network,
    required this.wave,
    List<WaveDefinition> laterWaves = const [],
    int heroId = 1,
    this.special = HeroSpecial.rivet,
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
  final HeroSpecial special;

  /// Special points. Gained when the hero's attacks land; spent in full by
  /// [useHeroSpecial]. Carries across waves.
  int heroSp = 0;
  bool _specialQueued = false;

  bool get specialReady =>
      phase == BattlePhase.combat &&
      !_specialQueued &&
      heroSp >= special.spMax &&
      combat.combatants.any((u) => u.id == heroId && u.isAlive);

  /// Validated hero command. Accepted only in combat with a full SP bar and a
  /// living hero; the effect applies at the start of the next [tick], after
  /// spawns and before combat, so it is deterministic in both engines.
  bool useHeroSpecial() {
    if (!specialReady) return false;
    _specialQueued = true;
    return true;
  }

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

  /// Applies a wave-boundary checkpoint to a fresh session (see
  /// `MissionSnapshot`). At an intermission the session waits to start the
  /// wave after [waveIndex]; otherwise it is back in preparation for
  /// [waveIndex] itself. Returns false if the session already started or the
  /// values do not fit this mission.
  bool restoreCheckpoint({
    required int waveIndex,
    required bool atIntermission,
    required int fortressHealth,
    required int heroLane,
    required int heroHealth,
    required int heroSp,
    required int scrapReward,
  }) {
    if (phase != BattlePhase.preparation || elapsedTicks != 0) return false;
    if (waveIndex < 0 || waveIndex >= waves.length) return false;
    if (atIntermission && waveIndex == waves.length - 1) return false;
    if (fortressHealth < 1 || fortressHealth > combat.fortressMaxHealth) {
      return false;
    }
    if (heroLane < 0 || heroLane > 2) return false;
    final hero = combat.combatants.where((u) => u.id == heroId).firstOrNull;
    // A knocked-out hero (health 0) stays knocked out after a resume.
    if (hero == null || heroHealth < 0 || heroHealth > hero.maxHealth) {
      return false;
    }
    this.waveIndex = waveIndex;
    phase = atIntermission ? BattlePhase.intermission : BattlePhase.preparation;
    combat.fortressHealth = fortressHealth;
    hero
      ..lane = heroLane
      ..health = heroHealth
      ..positionMm = 0
      ..state = heroHealth == 0 ? CombatState.dead : CombatState.idle;
    this.heroSp = heroSp.clamp(0, special.spMax).toInt();
    this.scrapReward = scrapReward < 0 ? 0 : scrapReward;
    return true;
  }

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
          windupTicks: spawn.windupTicks,
          cleave: spawn.cleave,
        ),
      );
    }

    if (_specialQueued) {
      _specialQueued = false;
      for (final hero in combat.combatants) {
        if (hero.id != heroId || !hero.isAlive) continue;
        combat.areaDamage(
          faction: CombatFaction.enemy,
          lane: hero.lane,
          centerMm: hero.positionMm,
          radiusMm: special.radiusMm,
          damage: special.damage,
        );
        heroSp = 0;
      }
    }

    combat.tick();
    for (final hit in combat.lastHits) {
      if (hit.attackerId == heroId) {
        heroSp = heroSp + special.spPerHit > special.spMax
            ? special.spMax
            : heroSp + special.spPerHit;
      }
    }
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
