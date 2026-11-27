import 'dart:convert';

import '../combat/battle_session.dart';
import '../core/seeded_random.dart';

/// Shared-data definitions and rules mirrored from Unity's Gearbound.Core and
/// tools/simulation/reference_rules.py. Inputs are raw JSON strings so the
/// caller decides whether they come from bundled assets or the repo's shared/.

class GearDefinition {
  const GearDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.tier,
    required this.rarity,
    required this.ports,
    required this.baseIntervalTicks,
    required this.cost,
    this.projectileDamage = 0,
    this.projectileSpeedMmPerTick = 0,
  });

  final String id;
  final String name;
  final String category;
  final int projectileDamage;
  final int projectileSpeedMmPerTick;
  final int tier;
  final String rarity;
  final List<String> ports;
  final int baseIntervalTicks;
  final int cost;
}

class EnemyDefinition {
  const EnemyDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.health,
    required this.armor,
    required this.damage,
    required this.attackRangeMm,
    required this.movementMmPerTick,
    required this.attackIntervalTicks,
    required this.rewardScrap,
    this.windupTicks = 0,
    this.cleave = false,
  });

  final String id;
  final String name;
  final String role;
  final int health;
  final int armor;
  final int damage;
  final int attackRangeMm;
  final int movementMmPerTick;
  final int attackIntervalTicks;
  final int rewardScrap;
  final int windupTicks;
  final bool cleave;
}

class ShopConfig {
  const ShopConfig({
    required this.offerCount,
    required this.maxCopiesPerOffer,
    required this.rarityWeights,
    required this.excludedCategories,
    required this.guaranteedCategory,
    required this.rerollBaseCost,
    required this.rerollCostStep,
    required this.rerollCostCap,
    required this.sellRefundPercent,
    required this.startingScrap,
  });

  final int offerCount;
  final int maxCopiesPerOffer;
  final Map<String, int> rarityWeights;
  final Set<String> excludedCategories;
  final String? guaranteedCategory;
  final int rerollBaseCost;
  final int rerollCostStep;
  final int rerollCostCap;
  final int sellRefundPercent;
  final int startingScrap;
}

class WaveGroup {
  const WaveGroup({
    required this.enemyId,
    required this.count,
    required this.firstSpawnTick,
    required this.intervalTicks,
    required this.lanePattern,
  });

  final String enemyId;
  final int count;
  final int firstSpawnTick;
  final int intervalTicks;
  final List<int> lanePattern;
}

class AuthoredWave {
  const AuthoredWave({
    required this.id,
    required this.rewardScrap,
    required this.boss,
    required this.groups,
  });

  final String id;
  final int rewardScrap;
  final bool boss;
  final List<WaveGroup> groups;
}

class ScheduledSpawn {
  const ScheduledSpawn(this.tick, this.lane, this.enemyId);
  final int tick;
  final int lane;
  final String enemyId;
}

Map<String, Object?> _root(String json) {
  final root = jsonDecode(json) as Map<String, Object?>;
  if (root['schemaVersion'] != 1) {
    throw const FormatException('Unsupported schemaVersion.');
  }
  return root;
}

List<Map<String, Object?>> _items(Map<String, Object?> root, String key) =>
    (root[key] as List<Object?>).cast<Map<String, Object?>>();

void _requireUnique(Iterable<String> ids, String what) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw FormatException('Duplicate $what ID $id.');
  }
}

List<GearDefinition> loadGears(String json) {
  final gears = [
    for (final g in _items(_root(json), 'gears'))
      GearDefinition(
        id: g['id'] as String,
        name: g['name'] as String,
        category: g['category'] as String,
        tier: g['tier'] as int,
        rarity: g['rarity'] as String,
        ports: (g['ports'] as List<Object?>).cast<String>(),
        baseIntervalTicks: g['baseIntervalTicks'] as int,
        cost: g['cost'] as int,
        projectileDamage:
            (g['projectile'] as Map<String, Object?>?)?['damage'] as int? ?? 0,
        projectileSpeedMmPerTick:
            (g['projectile'] as Map<String, Object?>?)?['speedMmPerTick']
                as int? ??
            0,
      ),
  ];
  _requireUnique(gears.map((g) => g.id), 'gear');
  return gears;
}

List<EnemyDefinition> loadEnemies(String json) {
  final enemies = [
    for (final e in _items(_root(json), 'enemies'))
      EnemyDefinition(
        id: e['id'] as String,
        name: e['name'] as String,
        role: e['role'] as String,
        health: e['health'] as int,
        armor: e['armor'] as int,
        damage: e['damage'] as int,
        attackRangeMm: e['attackRangeMm'] as int,
        movementMmPerTick: e['movementMmPerTick'] as int,
        attackIntervalTicks: e['attackIntervalTicks'] as int,
        rewardScrap: e['rewardScrap'] as int,
        windupTicks: e['windupTicks'] as int? ?? 0,
        cleave: e['cleave'] as bool? ?? false,
      ),
  ];
  _requireUnique(enemies.map((e) => e.id), 'enemy');
  return enemies;
}

ShopConfig loadShop(String json) {
  final root = _root(json);
  final reroll = root['reroll'] as Map<String, Object?>;
  return ShopConfig(
    offerCount: root['offerCount'] as int,
    maxCopiesPerOffer: root['maxCopiesPerOffer'] as int,
    rarityWeights: (root['rarityWeights'] as Map<String, Object?>).map(
      (key, value) => MapEntry(key, value as int),
    ),
    excludedCategories: (root['excludedCategories'] as List<Object?>)
        .cast<String>()
        .toSet(),
    guaranteedCategory: root['guaranteedCategory'] as String?,
    rerollBaseCost: reroll['baseCost'] as int,
    rerollCostStep: reroll['costStep'] as int,
    rerollCostCap: reroll['costCap'] as int,
    sellRefundPercent: root['sellRefundPercent'] as int,
    startingScrap: root['startingScrap'] as int,
  );
}

List<AuthoredWave> loadMissionWaves(String json) {
  final waves = [
    for (final w in _items(_root(json), 'waves'))
      AuthoredWave(
        id: w['id'] as String,
        rewardScrap: w['rewardScrap'] as int,
        boss: w['boss'] as bool? ?? false,
        groups: [
          for (final g in _items(w, 'groups'))
            WaveGroup(
              enemyId: g['enemyId'] as String,
              count: g['count'] as int,
              firstSpawnTick: g['firstSpawnTick'] as int,
              intervalTicks: g['intervalTicks'] as int,
              lanePattern: (g['lanePattern'] as List<Object?>).cast<int>(),
            ),
        ],
      ),
  ];
  _requireUnique(waves.map((w) => w.id), 'wave');
  return waves;
}

int _ordinal(String a, String b) => a.compareTo(b);

/// Seeded weighted shop roll. See Unity `GearShop.Roll` for the rule text.
List<String?> rollShop(
  SeededRandom rng,
  List<GearDefinition> catalog,
  ShopConfig config, {
  Set<String>? unlockedIds,
  List<String?>? lockedOffers,
  bool boardHasGuaranteedCategory = true,
}) {
  final count = config.offerCount;
  if (lockedOffers != null && lockedOffers.length != count) {
    throw ArgumentError('Locked offers must match the offer count.');
  }
  int weight(GearDefinition g) => config.rarityWeights[g.rarity] ?? 0;
  final byId = {for (final g in catalog) g.id: g};
  final pool =
      catalog
          .where(
            (g) =>
                !config.excludedCategories.contains(g.category) &&
                (unlockedIds == null || unlockedIds.contains(g.id)) &&
                weight(g) > 0,
          )
          .toList()
        ..sort((a, b) => _ordinal(a.id, b.id));

  final offers = List<String?>.generate(count, (i) => lockedOffers?[i]);
  for (var slot = 0; slot < count; slot++) {
    if (lockedOffers?[slot] != null) continue;
    final candidates = pool
        .where(
          (g) =>
              offers.where((o) => o == g.id).length < config.maxCopiesPerOffer,
        )
        .toList();
    if (candidates.isEmpty) {
      offers[slot] = null;
      continue;
    }
    var roll = rng.nextInt(candidates.fold(0, (sum, g) => sum + weight(g)));
    for (final gear in candidates) {
      roll -= weight(gear);
      if (roll < 0) {
        offers[slot] = gear.id;
        break;
      }
    }
  }

  final category = config.guaranteedCategory;
  if (category != null &&
      category.isNotEmpty &&
      !boardHasGuaranteedCategory &&
      !offers.any((o) => o != null && byId[o]!.category == category)) {
    final unlockedSlots = [
      for (var i = 0; i < count; i++)
        if (lockedOffers?[i] == null) i,
    ];
    final options = pool.where((g) => g.category == category).toList()
      ..sort((a, b) {
        final byCost = a.cost.compareTo(b.cost);
        return byCost != 0 ? byCost : _ordinal(a.id, b.id);
      });
    if (unlockedSlots.isNotEmpty && options.isNotEmpty) {
      offers[unlockedSlots.last] = options.first.id;
    }
  }
  return offers;
}

int rerollCost(ShopConfig config, int rerollsTaken) {
  if (rerollsTaken < 0) throw RangeError.value(rerollsTaken, 'rerollsTaken');
  final cost = config.rerollBaseCost + config.rerollCostStep * rerollsTaken;
  return cost < config.rerollCostCap ? cost : config.rerollCostCap;
}

int sellValue(ShopConfig config, GearDefinition gear) =>
    gear.cost * config.sellRefundPercent ~/ 100;

/// Stable spawn order: tick, lane, group index, then spawn index.
List<ScheduledSpawn> scheduleWave(AuthoredWave wave) {
  final entries = <(int, int, int, int, String)>[];
  for (var g = 0; g < wave.groups.length; g++) {
    final group = wave.groups[g];
    if (group.count < 1 ||
        group.intervalTicks < 1 ||
        group.firstSpawnTick < 0) {
      throw ArgumentError('Spawn group timing is invalid.');
    }
    for (var k = 0; k < group.count; k++) {
      entries.add((
        group.firstSpawnTick + k * group.intervalTicks,
        group.lanePattern[k % group.lanePattern.length],
        g,
        k,
        group.enemyId,
      ));
    }
  }
  entries.sort((a, b) {
    for (final c in [
      a.$1.compareTo(b.$1),
      a.$2.compareTo(b.$2),
      a.$3.compareTo(b.$3),
      a.$4.compareTo(b.$4),
    ]) {
      if (c != 0) return c;
    }
    return 0;
  });
  return [for (final e in entries) ScheduledSpawn(e.$1, e.$2, e.$5)];
}

WaveDefinition buildWave(AuthoredWave wave, List<EnemyDefinition> enemies) {
  final byId = {for (final e in enemies) e.id: e};
  return WaveDefinition(
    id: wave.id,
    rewardScrap: wave.rewardScrap,
    spawns: [
      for (final spawn in scheduleWave(wave))
        () {
          final e = byId[spawn.enemyId];
          if (e == null) {
            throw StateError('Unknown enemy ${spawn.enemyId} in ${wave.id}.');
          }
          return WaveSpawnEvent(
            tick: spawn.tick,
            lane: spawn.lane,
            health: e.health,
            armor: e.armor,
            damage: e.damage,
            attackRangeMm: e.attackRangeMm,
            movementMmPerTick: e.movementMmPerTick,
            attackIntervalTicks: e.attackIntervalTicks,
            windupTicks: e.windupTicks,
            cleave: e.cleave,
          );
        }(),
    ],
  );
}
