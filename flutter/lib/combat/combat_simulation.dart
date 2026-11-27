enum CombatFaction { friendly, enemy }

enum CombatState {
  idle,
  moving,
  acquiringTarget,
  attacking,
  recovering,
  stunned,
  knockedBack,
  dying,
  dead,
}

class Combatant {
  Combatant({
    required this.id,
    required this.faction,
    required this.lane,
    required this.positionMm,
    required int health,
    required this.armor,
    required this.damage,
    required this.attackRangeMm,
    required this.movementMmPerTick,
    required this.attackIntervalTicks,
    this.shield = 0,
    this.damageReductionPercent = 0,
    this.windupTicks = 0,
    this.cleave = false,
  }) : maxHealth = health,
       health = health {
    if (windupTicks < 0 ||
        (windupTicks > 0 && windupTicks >= attackIntervalTicks)) {
      throw ArgumentError.value(
        windupTicks,
        'windupTicks',
        'Wind-up must be 0 or shorter than the attack interval.',
      );
    }
    if (id <= 0 || lane < 0 || lane > 2) {
      throw ArgumentError('Invalid entity identity or lane.');
    }
    if (health <= 0 ||
        armor < 0 ||
        damage <= 0 ||
        attackRangeMm < 0 ||
        movementMmPerTick < 0 ||
        attackIntervalTicks < 1 ||
        shield < 0) {
      throw ArgumentError('Combat stats are outside their allowed range.');
    }
    if (damageReductionPercent < 0 || damageReductionPercent > 80) {
      throw ArgumentError.value(
        damageReductionPercent,
        'damageReductionPercent',
      );
    }
  }

  final int id;
  final CombatFaction faction;
  int lane;
  int positionMm;
  int health;
  final int maxHealth;
  final int armor;
  final int damage;
  final int damageReductionPercent;
  int shield;
  final int attackRangeMm;
  final int movementMmPerTick;
  final int attackIntervalTicks;
  int attackCooldownTicks = 0;

  /// Ticks between committing to an attack and the hit landing (0 = instant).
  final int windupTicks;

  /// When true, a wind-up hit lands on every opponent in range in the lane.
  final bool cleave;

  /// Ticks until a committed attack lands; the telegraph shows while > 0.
  int windupRemaining = 0;
  CombatState state = CombatState.idle;
  bool get isAlive => health > 0;
}

/// A friendly projectile travelling down a lane from the fortress line.
class Projectile {
  Projectile._(
    this.id,
    this.lane,
    this.positionMm,
    this.speedMmPerTick,
    this.damage,
  );
  final int id;
  final int lane;
  int positionMm;
  final int speedMmPerTick;
  final int damage;
}

class CombatSimulation {
  CombatSimulation({this.fortressHealth = 100, this.worldLengthMm = 20000})
    : fortressMaxHealth = fortressHealth {
    if (fortressHealth <= 0 || worldLengthMm <= 0) {
      throw ArgumentError(
        'Battle dimensions and fortress health must be positive.',
      );
    }
  }

  final List<Combatant> _combatants = [];
  final Set<int> _ids = {};
  int tickIndex = 0;
  int fortressHealth;
  final int fortressMaxHealth;
  final int worldLengthMm;
  bool get isDefeated => fortressHealth <= 0;
  List<Combatant> get combatants => List.unmodifiable(_combatants);

  bool add(Combatant combatant) {
    if (!_ids.add(combatant.id)) return false;
    _combatants.add(combatant);
    _combatants.sort((a, b) => a.id.compareTo(b.id));
    return true;
  }

  /// Removes matching combatants from the field (they are not killed, so no
  /// death is recorded). Returns how many were withdrawn. IDs stay reserved.
  int withdraw(bool Function(Combatant unit) test) {
    final before = _combatants.length;
    _combatants.removeWhere(test);
    return before - _combatants.length;
  }

  bool moveLane(int combatantId, int lane) {
    if (lane < 0 || lane > 2) return false;
    for (final combatant in _combatants) {
      if (combatant.id == combatantId && combatant.isAlive) {
        combatant.lane = lane;
        return true;
      }
    }
    return false;
  }

  /// Unit hits resolved during the most recent [tick], in resolution order.
  /// Fortress hits are not included. Read-only bookkeeping: it never changes
  /// combat outcomes.
  List<({int attackerId, int targetId})> get lastHits =>
      List.unmodifiable(_lastHits);
  final List<({int attackerId, int targetId})> _lastHits = [];

  final List<Projectile> _projectiles = [];
  int _nextProjectileId = 1;

  /// Hard cap on live projectiles; firing beyond it is refused.
  int maxActiveProjectiles = 24;
  List<Projectile> get projectiles => List.unmodifiable(_projectiles);

  /// Launches a friendly projectile. Each tick (projectile ID order) it
  /// advances by its speed and hits the nearest living enemy in its lane
  /// between its old and new position; it is removed on a hit or at the end
  /// of the field. Hits use attacker ID -projectileId (sorted before units,
  /// never colliding with unit IDs). Mirrors Unity's FireProjectile.
  bool fireProjectile({
    required int lane,
    required int startMm,
    required int speedMmPerTick,
    required int damage,
  }) {
    if (lane < 0 || lane > 2 || speedMmPerTick < 1 || damage < 1) {
      throw ArgumentError('Invalid projectile.');
    }
    if (_projectiles.length >= maxActiveProjectiles) return false;
    _projectiles.add(
      Projectile._(_nextProjectileId++, lane, startMm, speedMmPerTick, damage),
    );
    return true;
  }

  /// Deals [damage] (armor, reduction and shields apply as for a normal hit)
  /// to every living combatant of [faction] in [lane] within [radiusMm] of
  /// [centerMm], in entity ID order. Returns how many were hit.
  int areaDamage({
    required CombatFaction faction,
    required int lane,
    required int centerMm,
    required int radiusMm,
    required int damage,
  }) {
    final targets =
        _combatants
            .where(
              (u) =>
                  u.isAlive &&
                  u.faction == faction &&
                  u.lane == lane &&
                  (u.positionMm - centerMm).abs() <= radiusMm,
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    for (final target in targets) {
      _applyDamage(target, damage);
      if (target.health <= 0) target.state = CombatState.dead;
    }
    return targets.length;
  }

  void tick() {
    if (isDefeated) return;
    tickIndex++;
    _lastHits.clear();
    final living = _combatants.where((unit) => unit.isAlive).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // Snapshot before movement so entity iteration order cannot alter movement decisions.
    final startPositions = <int, int>{
      for (final unit in living) unit.id: unit.positionMm,
    };
    final nextPositions = <int, int>{};
    for (final unit in living) {
      if (unit.attackCooldownTicks > 0) unit.attackCooldownTicks--;
      final start = startPositions[unit.id]!;
      final hasNearbyTarget = living.any(
        (target) =>
            target.isAlive &&
            target.faction != unit.faction &&
            target.lane == unit.lane &&
            (startPositions[target.id]! - start).abs() <= unit.attackRangeMm,
      );
      final atFortress = unit.faction == CombatFaction.enemy && start <= 0;
      final atBoundary =
          unit.faction == CombatFaction.friendly && start >= worldLengthMm;
      // A unit winding up an attack holds its position until the hit lands.
      if (!hasNearbyTarget &&
          !atFortress &&
          !atBoundary &&
          unit.movementMmPerTick > 0 &&
          unit.windupRemaining == 0) {
        final delta = unit.faction == CombatFaction.friendly
            ? unit.movementMmPerTick
            : -unit.movementMmPerTick;
        nextPositions[unit.id] = (start + delta)
            .clamp(0, worldLengthMm)
            .toInt();
        unit.state = CombatState.moving;
      } else {
        nextPositions[unit.id] = start;
        unit.state = CombatState.idle;
      }
    }
    for (final unit in living) {
      unit.positionMm = nextPositions[unit.id]!;
    }

    final events = <({int targetId, int attackerId, int damage})>[];
    for (final shot in [
      ..._projectiles,
    ]..sort((a, b) => a.id.compareTo(b.id))) {
      final from = shot.positionMm;
      final to = from + shot.speedMmPerTick > worldLengthMm
          ? worldLengthMm
          : from + shot.speedMmPerTick;
      final hits =
          living
              .where(
                (u) =>
                    u.isAlive &&
                    u.faction == CombatFaction.enemy &&
                    u.lane == shot.lane &&
                    u.positionMm >= from &&
                    u.positionMm <= to,
              )
              .toList()
            ..sort((a, b) {
              final byPos = a.positionMm.compareTo(b.positionMm);
              return byPos != 0 ? byPos : a.id.compareTo(b.id);
            });
      if (hits.isNotEmpty) {
        events.add((
          targetId: hits.first.id,
          attackerId: -shot.id,
          damage: shot.damage,
        ));
        _projectiles.remove(shot);
      } else if (to >= worldLengthMm) {
        _projectiles.remove(shot);
      } else {
        shot.positionMm = to;
      }
    }
    for (final unit in living) {
      if (unit.windupRemaining > 0) {
        // Telegraphed attack: lands when the wind-up ends, on whoever is in
        // range then.
        unit.windupRemaining--;
        unit.state = CombatState.attacking;
        if (unit.windupRemaining == 0) _releaseWindup(unit, living, events);
        continue;
      }
      final target = _findTarget(unit, living);
      if (target != null) {
        if (unit.attackCooldownTicks == 0) {
          if (unit.windupTicks > 0) {
            unit.windupRemaining = unit.windupTicks;
          } else {
            events.add((
              targetId: target.id,
              attackerId: unit.id,
              damage: unit.damage,
            ));
          }
          unit.attackCooldownTicks = unit.attackIntervalTicks;
          unit.state = CombatState.attacking;
        } else if (unit.state != CombatState.moving) {
          unit.state = CombatState.recovering;
        }
      } else if (unit.faction == CombatFaction.enemy && unit.positionMm <= 0) {
        if (unit.attackCooldownTicks == 0) {
          if (unit.windupTicks > 0) {
            unit.windupRemaining = unit.windupTicks;
          } else {
            events.add((targetId: 0, attackerId: unit.id, damage: unit.damage));
          }
          unit.attackCooldownTicks = unit.attackIntervalTicks;
          unit.state = CombatState.attacking;
        } else {
          unit.state = CombatState.recovering;
        }
      }
    }

    events.sort((a, b) {
      final byTarget = a.targetId.compareTo(b.targetId);
      return byTarget != 0 ? byTarget : a.attackerId.compareTo(b.attackerId);
    });
    for (final event in events) {
      if (event.targetId == 0) {
        fortressHealth = (fortressHealth - event.damage)
            .clamp(0, fortressMaxHealth)
            .toInt();
      } else {
        final target = _combatants.firstWhere(
          (unit) => unit.id == event.targetId,
        );
        _applyDamage(target, event.damage);
        _lastHits.add((attackerId: event.attackerId, targetId: event.targetId));
      }
    }
    for (final unit in _combatants.where((unit) => unit.health <= 0)) {
      unit.state = CombatState.dead;
    }
  }

  /// Resolves a finished wind-up: cleave hits every opponent in range in the
  /// lane (ID order), otherwise the nearest. With nobody in range, an enemy at
  /// the fortress line hits the fortress; otherwise the attack misses.
  static void _releaseWindup(
    Combatant unit,
    List<Combatant> living,
    List<({int targetId, int attackerId, int damage})> events,
  ) {
    if (unit.cleave) {
      final targets =
          living
              .where(
                (t) =>
                    t.isAlive &&
                    t.faction != unit.faction &&
                    t.lane == unit.lane &&
                    (t.positionMm - unit.positionMm).abs() <=
                        unit.attackRangeMm,
              )
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      for (final t in targets) {
        events.add((targetId: t.id, attackerId: unit.id, damage: unit.damage));
      }
      if (targets.isNotEmpty) return;
    } else {
      final target = _findTarget(unit, living);
      if (target != null) {
        events.add((
          targetId: target.id,
          attackerId: unit.id,
          damage: unit.damage,
        ));
        return;
      }
    }
    if (unit.faction == CombatFaction.enemy && unit.positionMm <= 0) {
      events.add((targetId: 0, attackerId: unit.id, damage: unit.damage));
    }
  }

  static Combatant? _findTarget(
    Combatant attacker,
    Iterable<Combatant> candidates,
  ) {
    final targets = candidates
        .where(
          (target) =>
              target.isAlive &&
              target.faction != attacker.faction &&
              target.lane == attacker.lane &&
              (target.positionMm - attacker.positionMm).abs() <=
                  attacker.attackRangeMm,
        )
        .toList();
    targets.sort((a, b) {
      final byDistance = (a.positionMm - attacker.positionMm).abs().compareTo(
        (b.positionMm - attacker.positionMm).abs(),
      );
      return byDistance != 0 ? byDistance : a.id.compareTo(b.id);
    });
    return targets.isEmpty ? null : targets.first;
  }

  static void _applyDamage(Combatant target, int rawDamage) {
    final afterArmor = (rawDamage - target.armor).clamp(0, rawDamage).toInt();
    final afterReduction =
        afterArmor * (100 - target.damageReductionPercent) ~/ 100;
    final remaining = afterReduction < 1 ? 1 : afterReduction;
    final absorbed = target.shield < remaining ? target.shield : remaining;
    target.shield -= absorbed;
    target.health = (target.health - (remaining - absorbed))
        .clamp(0, target.maxHealth)
        .toInt();
  }
}
