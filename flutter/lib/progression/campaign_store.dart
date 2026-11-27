import 'package:shared_preferences/shared_preferences.dart';

import 'campaign_progress.dart';

class CampaignStore {
  CampaignStore({SharedPreferencesAsync? preferences})
    : _preferencesOverride = preferences;

  static const _key = 'gearbound.campaign.v1';
  final SharedPreferencesAsync? _preferencesOverride;
  SharedPreferencesAsync? _lazyPreferences;

  // Created on first use so tests can subclass the store without a platform
  // preferences implementation.
  SharedPreferencesAsync get _preferences =>
      _preferencesOverride ?? (_lazyPreferences ??= SharedPreferencesAsync());

  Future<CampaignProgress> load({DateTime? at}) async {
    final encoded = await _preferences.getString(_key);
    final progress = encoded == null
        ? CampaignProgress()
        : CampaignProgress.decode(encoded);
    progress.refreshPeriods(at: at);
    await save(progress);
    return progress;
  }

  Future<void> save(CampaignProgress progress) =>
      _preferences.setString(_key, progress.encode());
}
