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
  final Map<String, (List<AuthoredWave>, String)> _routeWaves;

  static Future<SharedContent> load(AssetBundle bundle) async {
    Future<String> read(String rel) => bundle.loadString('$assetRoot/$rel');
    final route = jsonDecode(
      await read('missions/campaign_route.json'),
    ) as Map<String, Object?>;
    if (route['schemaVersion'] != 1) {
      throw const FormatException('Unsupported campaign route schema.');
    }
    final missions = <String, List<AuthoredWave>>{};
    final routeWaves = <String, (List<AuthoredWave>, String)>{};
    for (final node in (route['nodes'] as List).cast<Map<String, Object?>>()) {
      final mission = node['mission'] as String;
      final waves = missions[mission] ??= loadMissionWaves(await read(mission));
      final waveId = node['waveId'] as String;
      if (!waves.any((w) => w.id == waveId)) {
        throw FormatException(
          'Route node ${node['id']} names unknown $waveId.',
        );
      }
      routeWaves[node['id'] as String] = (waves, waveId);
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

  /// The shared-data encounter for a route node, or null if it has not been
  /// migrated yet.
  WaveDefinition? encounterFor(String nodeId) {
    final entry = _routeWaves[nodeId];
    if (entry == null) return null;
    final (waves, waveId) = entry;
    final wave = waves.firstWhere((w) => w.id == waveId);
    final built = buildWave(wave, enemies);
    return WaveDefinition(
      id: 'wave-$nodeId',
      spawns: built.spawns,
      rewardScrap: built.rewardScrap,
    );
  }
}
