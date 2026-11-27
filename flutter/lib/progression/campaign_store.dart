import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'campaign_progress.dart';

/// Minimal key-value persistence, so tests can use memory instead of the
/// platform plugin.
abstract interface class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore([SharedPreferencesAsync? preferences])
    : _preferencesOverride = preferences;
  final SharedPreferencesAsync? _preferencesOverride;
  SharedPreferencesAsync? _lazy;
  SharedPreferencesAsync get _preferences =>
      _preferencesOverride ?? (_lazy ??= SharedPreferencesAsync());

  @override
  Future<String?> getString(String key) => _preferences.getString(key);
  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}

enum SaveLoadSource { fresh, primary, backup, legacy }

/// Local save with two slots and a monotonically increasing sequence:
/// - every save writes the backup slot first, then the primary slot, so a
///   crash between writes leaves at least one complete copy;
/// - load decodes both slots and keeps the valid one with the highest sequence;
/// - a slot written by a newer app version is never overwritten;
/// - writes are serialized, so overlapping saves cannot interleave.
///
/// SharedPreferences is user-editable and is not a store for purchased
/// currency; premium balances need server verification (see
/// docs/SAVE_MIGRATION.md).
class CampaignStore {
  CampaignStore({KeyValueStore? storage, this.preferences})
    : _storageOverride = storage;

  static const legacyKey = 'gearbound.campaign.v1';
  static const primaryKey = 'gearbound.save.primary';
  static const backupKey = 'gearbound.save.backup';

  final KeyValueStore? _storageOverride;
  final SharedPreferencesAsync? preferences;
  KeyValueStore? _lazyStorage;
  KeyValueStore get _storage =>
      _storageOverride ??
      (_lazyStorage ??= SharedPreferencesKeyValueStore(preferences));

  int _sequence = 0;
  Future<void> _pending = Future.value();

  SaveLoadSource lastLoadSource = SaveLoadSource.fresh;

  /// Slots that held unreadable data at the last load.
  final List<String> corruptSlots = [];

  /// True when a save from a newer build was found; saving is then disabled
  /// so that data is never overwritten.
  bool persistenceBlocked = false;

  Future<CampaignProgress> load({DateTime? at}) async {
    corruptSlots.clear();
    final candidates = <(int, CampaignProgress, SaveLoadSource)>[];
    for (final (key, source) in [
      (primaryKey, SaveLoadSource.primary),
      (backupKey, SaveLoadSource.backup),
    ]) {
      final raw = await _storage.getString(key);
      if (raw == null) continue;
      try {
        final envelope = jsonDecode(raw) as Map<String, Object?>;
        final sequence = envelope['sequence'] as int;
        final progress = CampaignProgress.fromJson(
          envelope['save'] as Map<String, Object?>,
        );
        candidates.add((sequence, progress, source));
      } on UnsupportedSaveVersion {
        persistenceBlocked = true;
      } on Object {
        corruptSlots.add(key);
      }
    }

    CampaignProgress progress;
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.$1.compareTo(a.$1));
      final (sequence, best, source) = candidates.first;
      _sequence = sequence;
      progress = best;
      lastLoadSource = source;
    } else {
      final legacy = await _storage.getString(legacyKey);
      progress = CampaignProgress();
      lastLoadSource = SaveLoadSource.fresh;
      if (legacy != null) {
        try {
          progress = CampaignProgress.decode(legacy);
          lastLoadSource = SaveLoadSource.legacy;
        } on UnsupportedSaveVersion {
          persistenceBlocked = true;
        } on Object {
          corruptSlots.add(legacyKey);
        }
      }
    }
    progress.refreshPeriods(at: at);
    if (!persistenceBlocked) await save(progress);
    return progress;
  }

  /// Queues a save behind any in-flight save. The legacy key is left in place
  /// as a read-only fallback until a later release removes it.
  Future<void> save(CampaignProgress progress) {
    if (persistenceBlocked) return Future.value();
    final payload = progress.toJson();
    final next = _pending.then((_) async {
      _sequence++;
      final encoded = jsonEncode({'sequence': _sequence, 'save': payload});
      await _storage.setString(backupKey, encoded);
      await _storage.setString(primaryKey, encoded);
    });
    _pending = next.catchError((Object _) {});
    return next;
  }
}
