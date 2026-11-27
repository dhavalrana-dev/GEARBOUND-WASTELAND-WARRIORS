import 'dart:convert';

import 'package:flutter/services.dart';

import '../combat/battle_session.dart';
import '../features/workshop/workshop_controller.dart';
import 'shared_rules.dart';

/// Runtime view of the shared JSON bundled under assets/shared (synced from
/// the repository's shared/ folder by tools/build/sync_flutter_shared.py).
class SharedContent {
  SharedContent._(
    this._routeWaves, {
    required this.workshopRules,
    required this.gears,
    required this.enemies,
    required this.shop,
  });

  static const assetRoot = 'assets/shared';

  final WorkshopRules workshopRules;
  final List<GearDefinition> gears;
  final List<EnemyDefinition> enemies;
  final ShopConfig shop;
  final Map<String, List<AuthoredWave>> _routeWaves;

  static Future<SharedContent> load(AssetBundle bundle) async {
    Future<String> read(String rel) => bundle.loadString('$assetRoot/$rel');
    final route = jsonDecode(
      await read('missions/campaign_route.json'),
    ) as Map<String, Object?>;
    if (route['schemaVersion'] != 1) {
      throw const FormatException('Unsupported campaign route schema.');
    }
    final missions = <String, List<AuthoredWave>>{};
    final routeWaves = <String, List<AuthoredWave>>{};
    for (final node in (route['nodes'] as List).cast<Map<String, Object?>>()) {
      final mission = node['mission'] as String;
      final waves = missions[mission] ??= loadMissionWaves(await read(mission));
      final waveIds = (node['waveIds'] as List).cast<String>();
      if (waveIds.isEmpty) {
        throw FormatException('Route node ${node['id']} has no waves.');
      }
      routeWaves[node['id'] as String] = [
        for (final id in waveIds)
          waves.firstWhere(
            (w) => w.id == id,
            orElse: () => throw FormatException(
              'Route node ${node['id']} names unknown $id.',
            ),
          ),
      ];
    }
    return SharedContent._(
      routeWaves,
      workshopRules: WorkshopRules.fromJson(
        await read('configs/gear_rules.json'),
      ),
      gears: loadGears(await read('gears/starter_gears.json')),
      enemies: loadEnemies(await read('enemies/enemies.json')),
      shop: loadShop(await read('economy/shop.json')),
    );
  }

  bool hasEncounter(String nodeId) => _routeWaves.containsKey(nodeId);

  /// Every wave of a route node's shared mission, in order, or null if the
  /// node has not been migrated yet.
  List<WaveDefinition>? encounterWavesFor(String nodeId) {
    final waves = _routeWaves[nodeId];
    if (waves == null) return null;
    return [
      for (var i = 0; i < waves.length; i++)
        () {
          final built = buildWave(waves[i], enemies);
          return WaveDefinition(
            id: i == 0 ? 'wave-$nodeId' : 'wave-$nodeId-${i + 1}',
            spawns: built.spawns,
            rewardScrap: built.rewardScrap,
          );
        }(),
    ];
  }

  /// The first wave of a route node's shared mission, or null.
  WaveDefinition? encounterFor(String nodeId) =>
      encounterWavesFor(nodeId)?.first;
}
