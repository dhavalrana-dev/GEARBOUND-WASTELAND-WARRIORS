import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/combat/battle_session.dart';
import 'package:gearbound/data/shared_content.dart';
import 'package:gearbound/progression/encounters.dart';

String _spawnKey(WaveSpawnEvent s) =>
    '${s.tick}:${s.lane}:${s.health}:${s.armor}:${s.damage}:'
    '${s.attackRangeMm}:${s.movementMmPerTick}:${s.attackIntervalTicks}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled assets are byte-identical to the repository shared data', () {
    const files = [
      'configs/gear_rules.json',
      'gears/starter_gears.json',
      'enemies/enemies.json',
      'economy/shop.json',
      'economy/currencies.json',
      'monetization/ad_policy.json',
      'waves/mission_001.json',
      'waves/copperwash_01.json',
      'missions/campaign_route.json',
      'events/progression_rewards.json',
    ];
    for (final rel in files) {
      expect(
        File('assets/shared/$rel').readAsBytesSync(),
        File('../shared/$rel').readAsBytesSync(),
        reason:
            '$rel is stale: run python -I tools/build/sync_flutter_shared.py',
      );
    }
  });

  test('shared content loads from the real asset bundle', () async {
    final content = await SharedContent.load(rootBundle);
    expect(content.gears.map((g) => g.id), contains('drive.coupler'));
    expect(content.enemies.map((e) => e.id), contains('boss.scrapmaw'));
    expect(content.shop.offerCount, 3);
    for (final id in campaignEncounterIds) {
      expect(content.hasEncounter(id), isTrue, reason: id);
    }
  });

  test(
    'migrating copperwash-01 to shared data keeps the same balance',
    () async {
      final content = await SharedContent.load(rootBundle);
      final shared = encounterForLevel(0, content: content);
      final legacy = encounterForLevel(0);
      expect(shared.id, legacy.id);
      expect(shared.rewardScrap, legacy.rewardScrap);
      expect(shared.spawns.map(_spawnKey), legacy.spawns.map(_spawnKey));
      // Every node now comes from shared data (GB-024); node 2 kept its
      // scripted spawns exactly.
      expect(
        encounterForLevel(1, content: content).spawns.map(_spawnKey),
        encounterForLevel(1).spawns.map(_spawnKey),
      );
      expect(
        encounterForLevel(5, content: content).id,
        'wave-${campaignEncounterIds[5]}',
      );
    },
  );
}
