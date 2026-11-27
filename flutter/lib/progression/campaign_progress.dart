import 'dart:convert';

import '../economy/economy_rules.dart';
import '../economy/wallet.dart';
import 'rewards.dart';

const campaignLevels = <CampaignLevel>[
  CampaignLevel(
    id: 'copperwash-01',
    chapter: 'COPPERWASH PASS',
    name: 'The First Link',
  ),
  CampaignLevel(
    id: 'copperwash-02',
    chapter: 'COPPERWASH PASS',
    name: 'Rivet Ridge',
  ),
  CampaignLevel(
    id: 'copperwash-03',
    chapter: 'COPPERWASH PASS',
    name: 'The Split Gear',
  ),
  CampaignLevel(
    id: 'copperwash-04',
    chapter: 'COPPERWASH PASS',
    name: 'Dust Devil Run',
  ),
  CampaignLevel(
    id: 'copperwash-05',
    chapter: 'COPPERWASH PASS',
    name: 'Scrapjaw',
  ),
  CampaignLevel(
    id: 'ironwood-01',
    chapter: 'IRONWOOD FRONTIER',
    name: 'A New Route',
  ),
  CampaignLevel(
    id: 'ironwood-02',
    chapter: 'IRONWOOD FRONTIER',
    name: 'Rust Orchard',
  ),
  CampaignLevel(
    id: 'ironwood-03',
    chapter: 'IRONWOOD FRONTIER',
    name: 'Broken Convoy',
  ),
  CampaignLevel(
    id: 'ironwood-04',
    chapter: 'IRONWOOD FRONTIER',
    name: 'The Long Climb',
  ),
  CampaignLevel(
    id: 'ironwood-05',
    chapter: 'IRONWOOD FRONTIER',
    name: 'Mossback',
  ),
  CampaignLevel(id: 'sunken-01', chapter: 'THE SUNKEN YARD', name: 'Low Water'),
  CampaignLevel(
    id: 'sunken-02',
    chapter: 'THE SUNKEN YARD',
    name: 'The Deep Press',
  ),
];

class CampaignLevel {
  const CampaignLevel({
    required this.id,
    required this.chapter,
    required this.name,
  });

  final String id;
  final String chapter;
  final String name;
}

class ContractDefinition {
  const ContractDefinition({
    required this.id,
    required this.title,
    required this.target,
    required this.scrapReward,
  });

  final String id;
  final String title;
  final int target;
  final int scrapReward;
}

const dailyContracts = <ContractDefinition>[
  ContractDefinition(
    id: 'daily-win',
    title: 'Clear a route',
    target: 1,
    scrapReward: 5,
  ),
  ContractDefinition(
    id: 'daily-power',
    title: 'Power gears in one setup',
    target: 4,
    scrapReward: 4,
  ),
  ContractDefinition(
    id: 'daily-command',
    title: 'Shift Rivet between lanes',
    target: 3,
    scrapReward: 4,
  ),
];

const eventRewardTiers = <EventRewardTier>[
  EventRewardTier(points: 3, scrap: 5),
  EventRewardTier(points: 6, scrap: 8),
  EventRewardTier(points: 10, scrap: 12),
];

class EventRewardTier {
  const EventRewardTier({required this.points, required this.scrap});

  final int points;
  final int scrap;
}

/// Thrown when a save was written by a newer build; the store must not
/// overwrite it.
class UnsupportedSaveVersion implements Exception {
  const UnsupportedSaveVersion(this.version);
  final int version;
  @override
  String toString() => 'UnsupportedSaveVersion($version)';
}

/// Local, offline campaign state. Every reward goes through [wallet], an
/// idempotent ledger, so a claim replayed after a crash or a duplicate tap can
/// never pay twice. See docs/REWARD_TRANSACTION_SYSTEM.md and
/// docs/SAVE_MIGRATION.md.
class CampaignProgress {
  CampaignProgress({
    int scrap = 0,
    Map<String, int>? bestStars,
    this.dayKey = '',
    Map<String, int>? contractProgress,
    Set<String>? claimedContracts,
    this.weekKey = '',
    this.eventPoints = 0,
    Set<int>? claimedEventTiers,
    Map<String, int>? weeklyBestStars,
    this.winStreak = 0,
    Map<String, int>? boosters,
    Set<int>? claimedStarChests,
    this.loginStep = 0,
    this.lastLoginClaimDay = '',
    Wallet? wallet,
    this.lastObservedUtc = '',
    this.migratedFromVersion,
  }) : wallet = wallet ?? Wallet(rules: defaultAssetRules()),
       claimedStarChests = claimedStarChests ?? {},
       bestStars = bestStars ?? {},
       contractProgress = contractProgress ?? {},
       claimedContracts = claimedContracts ?? {},
       claimedEventTiers = claimedEventTiers ?? {},
       weeklyBestStars = weeklyBestStars ?? {} {
    if (wallet == null) {
      _seedLegacyBalances(scrap, boosters ?? const {}, 'seed');
    }
  }

  static const saveVersion = 3;

  final Wallet wallet;
  final Map<String, int> bestStars;
  String dayKey;
  final Map<String, int> contractProgress;
  final Set<String> claimedContracts;
  String weekKey;
  int eventPoints;
  final Set<int> claimedEventTiers;
  final Map<String, int> weeklyBestStars;

  /// Consecutive victories, capped at [winStreakMaxLevel]; a defeat resets it.
  int winStreak;
  final Set<int> claimedStarChests;

  /// Supply Log days claimed so far. Missed days pause the track, never reset it.
  int loginStep;
  String lastLoginClaimDay;

  /// Latest device time seen (UTC ISO-8601). Earlier readings are treated as
  /// this time, so rolling the clock back cannot reopen daily or weekly claims.
  String lastObservedUtc;
  bool clockRollbackDetected = false;

  /// Set when this object was migrated from an older save format.
  final int? migratedFromVersion;

  /// Permanent earned currency (pre-v3 saves called this `scrap`).
  int get scrap => wallet.balance(Currency.workshopScrap);
  Map<String, int> get boosters => {
    for (final b in boosterDefinitions)
      if (wallet.balance(b.id) > 0) b.id: wallet.balance(b.id),
  };

  int get totalStars => bestStars.values.fold(0, (sum, stars) => sum + stars);
  int boosterCount(String id) => wallet.balance(id);
  RewardBundle get nextLoginReward =>
      loginTrackDays[loginStep % loginTrackDays.length];

  bool canClaimLogin({DateTime? at}) =>
      lastLoginClaimDay != _dateKey(_effectiveNow(at, observe: false));

  bool claimLogin({DateTime? at}) {
    final now = _effectiveNow(at);
    _ensurePeriods(now);
    if (lastLoginClaimDay == _dateKey(now)) return false;
    if (!_grant(nextLoginReward, 'supply_log:$loginStep', 'supply_log', now)) {
      return false;
    }
    loginStep++;
    lastLoginClaimDay = _dateKey(now);
    return true;
  }

  bool canClaimStarChest(int stars) =>
      starChests.any((chest) => chest.stars == stars) &&
      totalStars >= stars &&
      !claimedStarChests.contains(stars);

  bool claimStarChest(int stars, {DateTime? at}) {
    if (!canClaimStarChest(stars)) return false;
    final reward = starChests
        .firstWhere((chest) => chest.stars == stars)
        .reward;
    if (!_grant(reward, 'star_chest:$stars', 'star_chest', _effectiveNow(at))) {
      return false;
    }
    claimedStarChests.add(stars);
    return true;
  }

  /// Removes one booster for a mission attempt. [attemptKey] identifies the
  /// attempt so a retried start never consumes twice.
  bool consumeBooster(String id, {String? attemptKey, DateTime? at}) {
    final key = 'booster_use:${attemptKey ?? 'auto-${wallet.sequence}'}:$id';
    if (wallet.hasProcessed(key)) return true;
    return wallet
        .apply(
          TxnRequest(
            idempotencyKey: key,
            type: 'spend',
            source: 'mission_start',
            referenceId: attemptKey ?? '',
            deltas: [TxnDelta(id, -1)],
          ),
          at: _effectiveNow(at, observe: false),
        )
        .applied;
  }

  void recordDefeat() => winStreak = 0;

  /// Leaving a mission after its first wave started counts as a loss for the
  /// Overclock Streak, so quitting cannot protect a streak. Nothing else is
  /// lost: no currency, stars or inventory are touched.
  void recordAbandon() => winStreak = 0;

  bool _grant(RewardBundle reward, String key, String source, DateTime at) {
    final deltas = [
      if (reward.scrap > 0) TxnDelta(Currency.workshopScrap, reward.scrap),
      for (final entry in reward.boosters.entries)
        if (entry.value > 0) TxnDelta(entry.key, entry.value),
    ];
    if (deltas.isEmpty) return true;
    final result = wallet.apply(
      TxnRequest(
        idempotencyKey: key,
        type: 'grant',
        source: source,
        deltas: deltas,
      ),
      at: at,
    );
    return result.status != TxnStatus.rejected;
  }

  int get unlockedLevelIndex {
    var index = 0;
    while (index < campaignLevels.length - 1 &&
        bestStars.containsKey(campaignLevels[index].id)) {
      index++;
    }
    return index;
  }

  bool isUnlocked(int index) => index >= 0 && index <= unlockedLevelIndex;
  int starsFor(String levelId) => bestStars[levelId] ?? 0;
  int contractValue(String id) => contractProgress[id] ?? 0;

  void refreshPeriods({DateTime? at}) => _ensurePeriods(_effectiveNow(at));

  void recordSetup(int poweredGearCount, {DateTime? at}) {
    final now = _effectiveNow(at);
    _ensurePeriods(now);
    final def = dailyContracts.firstWhere((task) => task.id == 'daily-power');
    if (claimedContracts.contains(def.id)) return;
    final setupCount = poweredGearCount.clamp(0, def.target).toInt();
    final bestSetup = contractProgress[def.id] ?? 0;
    contractProgress[def.id] = setupCount > bestSetup ? setupCount : bestSetup;
    _completeContractIfReady(def, now);
  }

  void recordLaneCommand({DateTime? at}) {
    final now = _effectiveNow(at);
    _ensurePeriods(now);
    _advanceContract(
      dailyContracts.firstWhere((task) => task.id == 'daily-command'),
      1,
      now,
    );
  }

  /// Records only the best score per level in a week, so replaying a cleared
  /// node cannot be farmed for unlimited event points or first-clear scrap.
  bool recordVictory(String levelId, int stars, {DateTime? at}) {
    if (!campaignLevels.any((level) => level.id == levelId) ||
        stars < 1 ||
        stars > 3) {
      return false;
    }
    final now = _effectiveNow(at);
    _ensurePeriods(now);
    final levelIndex = campaignLevels.indexWhere(
      (level) => level.id == levelId,
    );
    if (!isUnlocked(levelIndex)) return false;

    final previous = bestStars[levelId] ?? 0;
    final previousWeekly = weeklyBestStars[levelId] ?? 0;
    final firstClear = previous == 0;
    bestStars[levelId] = stars > previous ? stars : previous;
    if (stars > previousWeekly) {
      weeklyBestStars[levelId] = stars;
      eventPoints += stars - previousWeekly;
    }
    if (firstClear) {
      _grant(
        RewardBundle(scrap: 3 + stars),
        'first_clear:$levelId',
        'campaign',
        now,
      );
    }
    if (winStreak < winStreakMaxLevel) winStreak++;
    _advanceContract(
      dailyContracts.firstWhere((task) => task.id == 'daily-win'),
      1,
      now,
    );
    return true;
  }

  bool claimEventTier(int points, {DateTime? at}) {
    final tier = eventRewardTiers
        .where((item) => item.points == points)
        .firstOrNull;
    if (tier == null ||
        eventPoints < tier.points ||
        claimedEventTiers.contains(points)) {
      return false;
    }
    if (!_grant(
      RewardBundle(scrap: tier.scrap),
      'scrapstorm:$weekKey:$points',
      'scrapstorm',
      _effectiveNow(at),
    )) {
      return false;
    }
    claimedEventTiers.add(points);
    return true;
  }

  void _advanceContract(ContractDefinition task, int amount, DateTime now) {
    if (claimedContracts.contains(task.id)) return;
    final next = (contractProgress[task.id] ?? 0) + amount;
    contractProgress[task.id] = next.clamp(0, task.target).toInt();
    _completeContractIfReady(task, now);
  }

  void _completeContractIfReady(ContractDefinition task, DateTime now) {
    if (contractProgress[task.id] == task.target &&
        !claimedContracts.contains(task.id) &&
        _grant(
          RewardBundle(scrap: task.scrapReward),
          'contract:$dayKey:${task.id}',
          'daily_contract',
          now,
        )) {
      claimedContracts.add(task.id);
    }
  }

  /// Monotonic clock: a reading earlier than the latest one seen is replaced
  /// by the latest, so daily and weekly periods never move backwards.
  DateTime _effectiveNow(DateTime? at, {bool observe = true}) {
    final now = at ?? DateTime.now();
    final last = DateTime.tryParse(lastObservedUtc);
    if (last != null && now.toUtc().isBefore(last)) {
      if (observe) clockRollbackDetected = true;
      return now.isUtc ? last : last.toLocal();
    }
    if (observe) lastObservedUtc = now.toUtc().toIso8601String();
    return now;
  }

  void _ensurePeriods(DateTime now) {
    final today = _dateKey(now);
    if (dayKey != today) {
      dayKey = today;
      contractProgress.clear();
      claimedContracts.clear();
    }
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final currentWeek = _dateKey(monday);
    if (weekKey != currentWeek) {
      weekKey = currentWeek;
      eventPoints = 0;
      claimedEventTiers.clear();
      weeklyBestStars.clear();
    }
  }

  void _seedLegacyBalances(int scrap, Map<String, int> boosters, String tag) {
    if (scrap > 0) {
      wallet.apply(
        TxnRequest(
          idempotencyKey: 'migration:$tag:workshop_scrap',
          type: 'migration',
          source: 'save_v2',
          deltas: [TxnDelta(Currency.workshopScrap, scrap)],
        ),
        at: DateTime.utc(2026),
      );
    }
    final known = {
      for (final entry in boosters.entries)
        if (entry.value > 0 &&
            wallet.rules.boosterMaxStack.containsKey(entry.key))
          entry.key: entry.value,
    };
    if (known.isNotEmpty) {
      wallet.apply(
        TxnRequest(
          idempotencyKey: 'migration:$tag:boosters',
          type: 'migration',
          source: 'save_v2',
          deltas: [for (final e in known.entries) TxnDelta(e.key, e.value)],
        ),
        at: DateTime.utc(2026),
      );
    }
  }

  Map<String, Object?> toJson() => {
    'saveVersion': saveVersion,
    'campaign': {
      'bestStars': bestStars,
      'winStreak': winStreak,
      'claimedStarChests': claimedStarChests.toList()..sort(),
      'loginStep': loginStep,
      'lastLoginClaimDay': lastLoginClaimDay,
    },
    'periods': {
      'dayKey': dayKey,
      'contractProgress': contractProgress,
      'claimedContracts': claimedContracts.toList()..sort(),
      'weekKey': weekKey,
      'eventPoints': eventPoints,
      'claimedEventTiers': claimedEventTiers.toList()..sort(),
      'weeklyBestStars': weeklyBestStars,
    },
    'wallet': wallet.toJson(),
    'clock': {'lastObservedUtc': lastObservedUtc},
  };

  /// Reads save versions 1–3. Versions 1 and 2 were flat maps whose `scrap`
  /// and `boosters` become ledger-backed `workshop_scrap` and booster balances.
  factory CampaignProgress.fromJson(Map<String, Object?> json) {
    final version = json['saveVersion'] as int? ?? 1;
    if (version > saveVersion) throw UnsupportedSaveVersion(version);
    if (version < 3) return _fromLegacy(json, version);

    final campaign = json['campaign'] as Map<String, Object?>? ?? {};
    final periods = json['periods'] as Map<String, Object?>? ?? {};
    final clock = json['clock'] as Map<String, Object?>? ?? {};
    return CampaignProgress(
      bestStars: _stars(campaign['bestStars']),
      winStreak: _streak(campaign['winStreak']),
      claimedStarChests: _ints(campaign['claimedStarChests']),
      loginStep: _nonNegative(campaign['loginStep']),
      lastLoginClaimDay: campaign['lastLoginClaimDay'] as String? ?? '',
      dayKey: periods['dayKey'] as String? ?? '',
      contractProgress: _intMap(periods['contractProgress']),
      claimedContracts: _strings(periods['claimedContracts']),
      weekKey: periods['weekKey'] as String? ?? '',
      eventPoints: _nonNegative(periods['eventPoints']),
      claimedEventTiers: _ints(periods['claimedEventTiers']),
      weeklyBestStars: _stars(periods['weeklyBestStars']),
      wallet: Wallet.fromJson(
        json['wallet'] as Map<String, Object?>? ?? {},
        defaultAssetRules(),
      ),
      lastObservedUtc: clock['lastObservedUtc'] as String? ?? '',
    );
  }

  static CampaignProgress _fromLegacy(Map<String, Object?> json, int version) {
    final progress = CampaignProgress(
      bestStars: _stars(json['bestStars']),
      dayKey: json['dayKey'] as String? ?? '',
      contractProgress: _intMap(json['contractProgress']),
      claimedContracts: _strings(json['claimedContracts']),
      weekKey: json['weekKey'] as String? ?? '',
      eventPoints: _nonNegative(json['eventPoints']),
      claimedEventTiers: _ints(json['claimedEventTiers']),
      weeklyBestStars: _stars(json['weeklyBestStars']),
      winStreak: _streak(json['winStreak']),
      claimedStarChests: _ints(json['claimedStarChests']),
      loginStep: _nonNegative(json['loginStep']),
      lastLoginClaimDay: json['lastLoginClaimDay'] as String? ?? '',
      wallet: Wallet(rules: defaultAssetRules()),
      migratedFromVersion: version,
    );
    progress._seedLegacyBalances(
      _nonNegative(json['scrap']),
      _intMap(json['boosters']),
      'v$version',
    );
    // Contracts and event tiers paid out before v3 have no ledger entry;
    // mark their keys processed so they can never be paid again.
    final legacyKeys = [
      for (final id in progress.claimedContracts)
        'contract:${progress.dayKey}:$id',
      for (final points in progress.claimedEventTiers)
        'scrapstorm:${progress.weekKey}:$points',
      for (final stars in progress.claimedStarChests) 'star_chest:$stars',
      for (final id in progress.bestStars.keys) 'first_clear:$id',
      for (var step = 0; step < progress.loginStep; step++) 'supply_log:$step',
    ];
    progress.wallet.markProcessed(legacyKeys);
    return progress;
  }

  String encode() => jsonEncode(toJson());
  factory CampaignProgress.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Save root is not an object.');
    }
    return CampaignProgress.fromJson(decoded);
  }

  static Map<String, int> _intMap(Object? value) => {
    if (value is Map<Object?, Object?>)
      for (final entry in value.entries)
        if (entry.key is String && entry.value is int)
          entry.key as String: entry.value as int,
  };

  static Map<String, int> _stars(Object? value) => {
    for (final entry in _intMap(value).entries)
      if (entry.value >= 1) entry.key: entry.value > 3 ? 3 : entry.value,
  };

  static Set<int> _ints(Object? value) =>
      (value is List ? value : const []).whereType<int>().toSet();
  static Set<String> _strings(Object? value) =>
      (value is List ? value : const []).whereType<String>().toSet();
  static int _nonNegative(Object? value) =>
      value is int && value > 0 ? value : 0;
  static int _streak(Object? value) =>
      _nonNegative(value).clamp(0, winStreakMaxLevel).toInt();

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
