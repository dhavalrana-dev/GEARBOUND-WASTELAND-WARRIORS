import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gearbound/economy/economy_rules.dart';
import 'package:gearbound/economy/wallet.dart';

Map<String, Object?> _read(String rel) =>
    jsonDecode(File('../shared/$rel').readAsStringSync())
        as Map<String, Object?>;

void main() {
  final fixture = _read('test-fixtures/reward_transaction_cases.json');
  final rules = assetRulesFromJson(
    currenciesJson: File('../shared/economy/currencies.json')
        .readAsStringSync(),
    boosterMaxStack: (fixture['boosterMaxStack'] as Map<String, Object?>).map(
      (k, v) => MapEntry(k, v as int),
    ),
  );

  test('built-in currency rules match shared/economy/currencies.json', () {
    final builtIn = defaultAssetRules();
    expect(builtIn.currencyMax, rules.currencyMax);
    expect(builtIn.premiumCurrencies, rules.premiumCurrencies);
  });

  for (final c in (fixture['cases'] as List).cast<Map<String, Object?>>()) {
    test('ledger case ${c['id']}', () {
      final wallet = Wallet(rules: rules);
      var stepIndex = 0;
      for (final step in (c['steps'] as List).cast<Map<String, Object?>>()) {
        final r = step['request'] as Map<String, Object?>;
        final e = step['expect'] as Map<String, Object?>;
        final result = wallet.apply(
          TxnRequest(
            idempotencyKey: r['key'] as String,
            type: r['type'] as String,
            source: r['source'] as String,
            verification: r['verification'] == 'verified'
                ? TxnVerification.verified
                : TxnVerification.local,
            deltas: [
              for (final d
                  in (r['deltas'] as List).cast<Map<String, Object?>>())
                TxnDelta(d['asset'] as String, d['amount'] as int),
            ],
          ),
          at: DateTime.utc(2026, 11, 27),
        );
        final where = '${c['id']} step $stepIndex';
        expect(result.status.name, e['status'], reason: where);
        if (e.containsKey('reason')) {
          expect(result.reason, e['reason'], reason: where);
        }
        for (final balance in (e['balances'] as Map<String, Object?>).entries) {
          expect(
            wallet.balance(balance.key),
            balance.value,
            reason: '$where ${balance.key}',
          );
        }
        stepIndex++;
      }
    });
  }

  test('ledger entries carry the required audit fields and survive a save', () {
    final wallet = Wallet(rules: defaultAssetRules(), profileId: 'p1');
    wallet.apply(
      const TxnRequest(
        idempotencyKey: 'k1',
        type: 'grant',
        source: 'campaign',
        referenceId: 'copperwash-01',
        deltas: [
          TxnDelta(Currency.workshopScrap, 5),
          TxnDelta(Currency.xp, 40),
        ],
      ),
      at: DateTime.utc(2026, 11, 27, 8),
    );
    final restored = Wallet.fromJson(
      jsonDecode(jsonEncode(wallet.toJson())) as Map<String, Object?>,
      defaultAssetRules(),
    );
    final entry = restored.ledger.first;
    expect(entry.transactionId, 'txn-1');
    expect(entry.profileId, 'p1');
    expect(entry.asset, Currency.workshopScrap);
    expect(entry.amount, 5);
    expect(entry.referenceId, 'copperwash-01');
    expect(entry.verification, TxnVerification.local);
    expect(entry.createdAtUtc, '2026-11-27T08:00:00.000Z');
    expect(restored.balance(Currency.xp), 40);
    expect(restored.hasProcessed('k1'), isTrue);
    expect(
      restored
          .apply(
            const TxnRequest(
              idempotencyKey: 'k1',
              type: 'grant',
              source: 'campaign',
              deltas: [TxnDelta(Currency.xp, 40)],
            ),
          )
          .status,
      TxnStatus.duplicate,
    );
  });

  test('trimming old ledger entries never re-enables a processed key', () {
    final wallet = Wallet(rules: defaultAssetRules());
    for (var i = 0; i < Wallet.ledgerRetention + 20; i++) {
      wallet.apply(
        TxnRequest(
          idempotencyKey: 'grant-$i',
          type: 'grant',
          source: 'test',
          deltas: const [TxnDelta(Currency.xp, 1)],
        ),
      );
    }
    expect(wallet.ledger.length, Wallet.ledgerRetention);
    expect(
      wallet
          .apply(
            const TxnRequest(
              idempotencyKey: 'grant-0',
              type: 'grant',
              source: 'test',
              deltas: [TxnDelta(Currency.xp, 1)],
            ),
          )
          .status,
      TxnStatus.duplicate,
    );
    expect(wallet.balance(Currency.xp), Wallet.ledgerRetention + 20);
  });
}
