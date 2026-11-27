/// Engine-independent wallet with an idempotent, all-or-nothing transaction
/// ledger. Rules are shared with Unity's `Gearbound.Economy.Wallet` and checked
/// against shared/test-fixtures/reward_transaction_cases.json.
///
/// Validation order: duplicate key → invalid request → unverified premium
/// grant → insufficient balance → currency overflow. Boosters above their
/// stack cap are clamped (the entry records the amount actually applied);
/// currencies above their max are rejected. Rejected requests do not consume
/// their idempotency key, so a corrected retry can succeed.
library;

enum TxnStatus { applied, duplicate, rejected }

enum TxnVerification { local, verified }

class AssetRules {
  const AssetRules({
    required this.currencyMax,
    required this.premiumCurrencies,
    required this.boosterMaxStack,
  });

  /// Currency ID → maximum balance (overflow is rejected).
  final Map<String, int> currencyMax;
  final Set<String> premiumCurrencies;

  /// Booster ID → stack cap (excess is clamped).
  final Map<String, int> boosterMaxStack;

  bool isKnown(String asset) =>
      currencyMax.containsKey(asset) || boosterMaxStack.containsKey(asset);
}

class TxnDelta {
  const TxnDelta(this.asset, this.amount);
  final String asset;
  final int amount;
}

class TxnRequest {
  const TxnRequest({
    required this.idempotencyKey,
    required this.type,
    required this.source,
    required this.deltas,
    this.referenceId = '',
    this.verification = TxnVerification.local,
  });

  final String idempotencyKey;

  /// grant, spend, purchase, ad_reward, refund, migration, ...
  final String type;
  final String source;
  final String referenceId;
  final TxnVerification verification;
  final List<TxnDelta> deltas;
}

class LedgerEntry {
  const LedgerEntry({
    required this.transactionId,
    required this.idempotencyKey,
    required this.profileId,
    required this.asset,
    required this.amount,
    required this.type,
    required this.source,
    required this.referenceId,
    required this.verification,
    required this.createdAtUtc,
  });

  final String transactionId;
  final String idempotencyKey;
  final String profileId;
  final String asset;
  final int amount;
  final String type;
  final String source;
  final String referenceId;
  final TxnVerification verification;
  final String createdAtUtc;

  Map<String, Object?> toJson() => {
    'txn': transactionId,
    'key': idempotencyKey,
    'profile': profileId,
    'asset': asset,
    'amount': amount,
    'type': type,
    'source': source,
    'ref': referenceId,
    'verification': verification.name,
    'at': createdAtUtc,
  };

  factory LedgerEntry.fromJson(Map<String, Object?> json) => LedgerEntry(
    transactionId: json['txn'] as String,
    idempotencyKey: json['key'] as String,
    profileId: json['profile'] as String? ?? '',
    asset: json['asset'] as String,
    amount: json['amount'] as int,
    type: json['type'] as String,
    source: json['source'] as String? ?? '',
    referenceId: json['ref'] as String? ?? '',
    verification: json['verification'] == 'verified'
        ? TxnVerification.verified
        : TxnVerification.local,
    createdAtUtc: json['at'] as String? ?? '',
  );
}

class TxnResult {
  const TxnResult(this.status, {this.reason = '', this.entries = const []});
  final TxnStatus status;
  final String reason;
  final List<LedgerEntry> entries;
  bool get applied => status == TxnStatus.applied;
}

class Wallet {
  Wallet({
    required this.rules,
    this.profileId = 'local',
    Map<String, int>? balances,
    List<LedgerEntry>? ledger,
    Set<String>? processedKeys,
    this.sequence = 0,
  }) : _balances = balances ?? {},
       _ledger = ledger ?? [],
       _processedKeys = processedKeys ?? {};

  /// Ledger entries kept in the save; balances and processed keys are kept
  /// in full, so trimming old entries never re-enables a duplicate claim.
  static const ledgerRetention = 500;

  final AssetRules rules;
  final String profileId;
  final Map<String, int> _balances;
  final List<LedgerEntry> _ledger;
  final Set<String> _processedKeys;
  int sequence;

  int balance(String asset) => _balances[asset] ?? 0;
  Map<String, int> get balances => Map.unmodifiable(_balances);
  List<LedgerEntry> get ledger => List.unmodifiable(_ledger);
  bool hasProcessed(String key) => _processedKeys.contains(key);

  /// Records keys whose rewards were paid before the ledger existed (save
  /// migration), so those claims can never be paid again.
  void markProcessed(Iterable<String> keys) => _processedKeys.addAll(keys);

  TxnResult apply(TxnRequest request, {DateTime? at}) {
    if (_processedKeys.contains(request.idempotencyKey)) {
      return TxnResult(
        TxnStatus.duplicate,
        entries: _ledger
            .where((e) => e.idempotencyKey == request.idempotencyKey)
            .toList(),
      );
    }
    final seen = <String>{};
    if (request.idempotencyKey.isEmpty ||
        request.deltas.isEmpty ||
        request.deltas.any(
          (d) => d.amount == 0 || !rules.isKnown(d.asset) || !seen.add(d.asset),
        )) {
      return const TxnResult(TxnStatus.rejected, reason: 'invalid');
    }
    if (request.verification != TxnVerification.verified &&
        request.deltas.any(
          (d) => d.amount > 0 && rules.premiumCurrencies.contains(d.asset),
        )) {
      return const TxnResult(TxnStatus.rejected, reason: 'unverified_premium');
    }
    final next = <String, int>{};
    for (final d in request.deltas) {
      final result = balance(d.asset) + d.amount;
      if (result < 0) {
        return const TxnResult(TxnStatus.rejected, reason: 'insufficient');
      }
      final currencyMax = rules.currencyMax[d.asset];
      if (currencyMax != null && result > currencyMax) {
        return const TxnResult(TxnStatus.rejected, reason: 'overflow');
      }
      final stack = rules.boosterMaxStack[d.asset];
      next[d.asset] = stack != null && result > stack ? stack : result;
    }

    final createdAt = (at ?? DateTime.now()).toUtc().toIso8601String();
    final entries = <LedgerEntry>[];
    for (final d in request.deltas) {
      sequence++;
      entries.add(
        LedgerEntry(
          transactionId: 'txn-$sequence',
          idempotencyKey: request.idempotencyKey,
          profileId: profileId,
          asset: d.asset,
          amount: next[d.asset]! - balance(d.asset),
          type: request.type,
          source: request.source,
          referenceId: request.referenceId,
          verification: request.verification,
          createdAtUtc: createdAt,
        ),
      );
    }
    _balances.addAll(next);
    _balances.removeWhere((_, value) => value == 0);
    _processedKeys.add(request.idempotencyKey);
    _ledger.addAll(entries);
    if (_ledger.length > ledgerRetention) {
      _ledger.removeRange(0, _ledger.length - ledgerRetention);
    }
    return TxnResult(TxnStatus.applied, entries: entries);
  }

  Map<String, Object?> toJson() => {
    'profileId': profileId,
    'sequence': sequence,
    'balances': _balances,
    'processedKeys': _processedKeys.toList()..sort(),
    'ledger': [for (final e in _ledger) e.toJson()],
  };

  factory Wallet.fromJson(Map<String, Object?> json, AssetRules rules) =>
      Wallet(
        rules: rules,
        profileId: json['profileId'] as String? ?? 'local',
        sequence: json['sequence'] as int? ?? 0,
        balances: {
          for (final e
              in (json['balances'] as Map<String, Object?>? ?? {}).entries)
            if (e.value is int && (e.value as int) > 0) e.key: e.value as int,
        },
        processedKeys: (json['processedKeys'] as List<Object?>? ?? [])
            .whereType<String>()
            .toSet(),
        ledger: [
          for (final e in (json['ledger'] as List<Object?>? ?? []))
            LedgerEntry.fromJson(e as Map<String, Object?>),
        ],
      );
}
