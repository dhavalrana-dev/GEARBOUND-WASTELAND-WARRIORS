import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/progression/campaign_progress.dart';
import 'package:gearbound/progression/campaign_store.dart';
import 'package:gearbound/progression/rewards.dart';

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = {};
  final List<String> writes = [];
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    await Future<void>.delayed(Duration.zero);
    writes.add(key);
    values[key] = value;
  }
}

void main() {
  final cases =
      ((jsonDecode(
                File('../shared/test-fixtures/save_migration_cases.json')
                    .readAsStringSync(),
              ) as Map<String, Object?>)['cases']
              as List)
          .cast<Map<String, Object?>>();

  group('save migration fixture', () {
    for (final c in cases) {
      test(c['id'] as String, () {
        final progress = CampaignProgress.fromJson(
          c['save'] as Map<String, Object?>,
        );
        final e = c['expect'] as Map<String, Object?>;
        expect(progress.migratedFromVersion, e['migratedFrom']);
        expect(progress.scrap, e['workshop_scrap']);
        expect(progress.boosters, e['boosters']);
        expect(progress.bestStars, e['bestStars']);
        expect(progress.winStreak, e['winStreak']);
        expect(progress.loginStep, e['loginStep']);

        final scrapBefore = progress.scrap;
        for (final claim in (c['replayClaims'] as List).cast<String>()) {
          final refused = switch (claim) {
            'starChest:6' => !progress.claimStarChest(6),
            'eventTier:3' => !progress.claimEventTier(
              3,
              at: DateTime(2026, 11, 23, 13),
            ),
            'supplyLogSameDay' => !progress.claimLogin(
              at: DateTime(2026, 11, 23, 14),
            ),
            _ => throw StateError('unknown claim $claim'),
          };
          expect(refused, isTrue, reason: claim);
        }
        expect(progress.scrap, scrapBefore);

        // Round-trips through v3 without changing anything.
        final reloaded = CampaignProgress.decode(progress.encode());
        expect(reloaded.scrap, progress.scrap);
        expect(reloaded.boosters, progress.boosters);
        expect(reloaded.bestStars, progress.bestStars);
        expect(reloaded.migratedFromVersion, isNull);
      });
    }
  });

  group('CampaignStore', () {
    test('migrates the legacy key and writes backup before primary', () async {
      final kv = MemoryKeyValueStore()
        ..values[CampaignStore.legacyKey] =
            '{"saveVersion":2,"scrap":12,"bestStars":{"copperwash-01":1}}';
      final store = CampaignStore(storage: kv);
      final progress = await store.load(at: DateTime(2026, 11, 24));
      expect(store.lastLoadSource, SaveLoadSource.legacy);
      expect(progress.scrap, 12);
      expect(kv.writes, [CampaignStore.backupKey, CampaignStore.primaryKey]);
      // The legacy key stays untouched as a read-only fallback.
      expect(kv.values[CampaignStore.legacyKey], contains('"scrap":12'));

      final again = await CampaignStore(storage: kv).load();
      expect(again.scrap, 12);
    });

    test('recovers from a corrupted primary using the backup', () async {
      final kv = MemoryKeyValueStore();
      final store = CampaignStore(storage: kv);
      final progress = await store.load(at: DateTime(2026, 11, 24));
      progress.recordVictory('copperwash-01', 3, at: DateTime(2026, 11, 24));
      await store.save(progress);
      kv.values[CampaignStore.primaryKey] = '{"sequence": 9, "save": {trunc';

      final recovering = CampaignStore(storage: kv);
      final restored = await recovering.load();
      expect(recovering.lastLoadSource, SaveLoadSource.backup);
      expect(recovering.corruptSlots, [CampaignStore.primaryKey]);
      expect(restored.starsFor('copperwash-01'), 3);
      expect(restored.scrap, progress.scrap);
    });

    test('picks the newest valid slot by sequence', () async {
      final kv = MemoryKeyValueStore();
      String slot(int sequence, int stars) => jsonEncode({
        'sequence': sequence,
        'save': CampaignProgress(bestStars: {'copperwash-01': stars}).toJson(),
      });
      kv.values[CampaignStore.primaryKey] = slot(4, 1);
      kv.values[CampaignStore.backupKey] = slot(5, 2);
      final store = CampaignStore(storage: kv);
      final progress = await store.load();
      expect(store.lastLoadSource, SaveLoadSource.backup);
      expect(progress.starsFor('copperwash-01'), 2);
    });

    test('starts fresh when every slot is unreadable', () async {
      final kv = MemoryKeyValueStore()
        ..values[CampaignStore.primaryKey] = 'not json'
        ..values[CampaignStore.backupKey] = '[]'
        ..values[CampaignStore.legacyKey] = '{"scrap": "lots"';
      final store = CampaignStore(storage: kv);
      final progress = await store.load();
      expect(store.lastLoadSource, SaveLoadSource.fresh);
      expect(store.corruptSlots, hasLength(3));
      expect(progress.scrap, 0);
    });

    test('never overwrites a save written by a newer build', () async {
      final newer = jsonEncode({
        'sequence': 3,
        'save': {'saveVersion': 99},
      });
      final kv = MemoryKeyValueStore()
        ..values[CampaignStore.primaryKey] = newer;
      final store = CampaignStore(storage: kv);
      final progress = await store.load();
      expect(store.persistenceBlocked, isTrue);
      await store.save(progress);
      expect(kv.values[CampaignStore.primaryKey], newer);
      expect(kv.writes, isEmpty);
    });

    test('overlapping saves are serialized in call order', () async {
      final kv = MemoryKeyValueStore();
      final store = CampaignStore(storage: kv);
      final progress = await store.load();
      kv.writes.clear();
      progress.recordVictory('copperwash-01', 1, at: DateTime(2026, 11, 24));
      final first = store.save(progress);
      progress.recordVictory('copperwash-02', 2, at: DateTime(2026, 11, 24));
      final second = store.save(progress);
      await Future.wait([first, second]);
      expect(kv.writes, [
        CampaignStore.backupKey,
        CampaignStore.primaryKey,
        CampaignStore.backupKey,
        CampaignStore.primaryKey,
      ]);
      final saved = jsonDecode(
        kv.values[CampaignStore.primaryKey]!,
      ) as Map<String, Object?>;
      expect(saved['sequence'], 3);
    });
  });

  group('clock rollback', () {
    test('rolling the device clock back cannot reopen the Supply Log', () {
      final progress = CampaignProgress();
      final tuesday = DateTime(2026, 11, 24, 10);
      expect(progress.claimLogin(at: tuesday), isTrue);
      final monday = tuesday.subtract(const Duration(days: 1));
      expect(progress.canClaimLogin(at: monday), isFalse);
      expect(progress.claimLogin(at: monday), isFalse);
      expect(progress.clockRollbackDetected, isTrue);
      expect(progress.loginStep, 1);
      expect(
        progress.claimLogin(at: tuesday.add(const Duration(days: 1))),
        isTrue,
      );
    });

    test('rolling back does not reset daily contracts for a replay', () {
      final progress = CampaignProgress();
      final day = DateTime(2026, 11, 24, 10);
      progress.recordVictory('copperwash-01', 1, at: day);
      final scrap = progress.scrap;
      progress.recordVictory(
        'copperwash-01',
        1,
        at: day.subtract(const Duration(days: 2)),
      );
      expect(progress.dayKey, '2026-11-24');
      expect(progress.scrap, scrap);
    });

    test('the observed clock survives a save', () {
      final progress = CampaignProgress()
        ..claimLogin(at: DateTime(2026, 11, 24, 10));
      final restored = CampaignProgress.decode(progress.encode());
      expect(restored.canClaimLogin(at: DateTime(2026, 11, 20)), isFalse);
    });
  });

  test('booster consumption is idempotent per mission attempt', () {
    final progress = CampaignProgress(boosters: {vanguardBoosterId: 2});
    expect(
      progress.consumeBooster(vanguardBoosterId, attemptKey: 'attempt-1'),
      isTrue,
    );
    expect(
      progress.consumeBooster(vanguardBoosterId, attemptKey: 'attempt-1'),
      isTrue,
    );
    expect(progress.boosterCount(vanguardBoosterId), 1);
  });
}
