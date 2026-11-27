import 'dart:convert';

import '../progression/rewards.dart';
import 'wallet.dart';

/// Currency IDs from shared/economy/currencies.json.
abstract final class Currency {
  static const battleScrap = 'battle_scrap';
  static const workshopScrap = 'workshop_scrap';
  static const alloy = 'alloy';
  static const blueprints = 'blueprints';
  static const eventTokens = 'event_tokens';
  static const xp = 'xp';
}

/// Built-in rules matching shared/economy/currencies.json; the parity test in
/// test/economy/wallet_test.dart fails if the two drift.
const defaultCurrencyMax = <String, int>{
  Currency.battleScrap: 100000,
  Currency.workshopScrap: 10000000,
  Currency.alloy: 10000000,
  Currency.blueprints: 1000000,
  Currency.eventTokens: 1000000,
  Currency.xp: 2000000000,
};

AssetRules defaultAssetRules() => AssetRules(
  currencyMax: defaultCurrencyMax,
  premiumCurrencies: const {Currency.alloy},
  boosterMaxStack: {for (final b in boosterDefinitions) b.id: b.maxStack},
);

/// Builds asset rules from shared JSON (currencies + booster stack caps).
AssetRules assetRulesFromJson({
  required String currenciesJson,
  required Map<String, int> boosterMaxStack,
}) {
  final root = jsonDecode(currenciesJson) as Map<String, Object?>;
  if (root['schemaVersion'] != 1) {
    throw const FormatException('Unsupported currencies schema.');
  }
  final currencies = (root['currencies'] as List).cast<Map<String, Object?>>();
  return AssetRules(
    currencyMax: {
      for (final c in currencies) c['id'] as String: c['max'] as int,
    },
    premiumCurrencies: {
      for (final c in currencies)
        if (c['premium'] == true) c['id'] as String,
    },
    boosterMaxStack: boosterMaxStack,
  );
}
