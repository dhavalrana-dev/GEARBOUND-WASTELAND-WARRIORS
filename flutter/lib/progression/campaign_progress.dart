import 'dart:convert';

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

/// Local, offline campaign state. The event is a weekly score chase with fixed
/// rewards; it has no paid rolls, energy timer, or server requirement.
class CampaignProgress {
  CampaignProgress({
    this.scrap = 0,
    Map<String, int>? bestStars,
    this.dayKey = '',
    Map<String, int>? contractProgress,
    Set<String>? claimedContracts,
    this.weekKey = '',
    this.eventPoints = 0,
    Set<int>? claimedEventTiers,
    Map<String, int>? weeklyBestStars,
  }) : bestStars = bestStars ?? {},
       contractProgress = contractProgress ?? {},
       claimedContracts = claimedContracts ?? {},
       claimedEventTiers = claimedEventTiers ?? {},
       weeklyBestStars = weeklyBestStars ?? {};

  int scrap;
  final Map<String, int> bestStars;
  String dayKey;
  final Map<String, int> contractProgress;
  final Set<String> claimedContracts;
  String weekKey;
  int eventPoints;
  final Set<int> claimedEventTiers;
  final Map<String, int> weeklyBestStars;

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

  void refreshPeriods({DateTime? at}) => _ensurePeriods(at ?? DateTime.now());

  void recordSetup(int poweredGearCount, {DateTime? at}) {
    _ensurePeriods(at ?? DateTime.now());
    final def = dailyContracts.firstWhere((task) => task.id == 'daily-power');
    if (claimedContracts.contains(def.id)) return;
    final setupCount = poweredGearCount.clamp(0, def.target).toInt();
    final bestSetup = contractProgress[def.id] ?? 0;
    contractProgress[def.id] = setupCount > bestSetup ? setupCount : bestSetup;
    _completeContractIfReady(def);
  }

  void recordLaneCommand({DateTime? at}) {
    _ensurePeriods(at ?? DateTime.now());
    _advanceContract(
      dailyContracts.firstWhere((task) => task.id == 'daily-command'),
      1,
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
    _ensurePeriods(at ?? DateTime.now());
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
    if (firstClear) scrap += 3 + stars;
    _advanceContract(
      dailyContracts.firstWhere((task) => task.id == 'daily-win'),
      1,
    );
    return true;
  }

  bool claimEventTier(int points) {
    final tier = eventRewardTiers
        .where((item) => item.points == points)
        .firstOrNull;
    if (tier == null ||
        eventPoints < tier.points ||
        !claimedEventTiers.add(points)) {
      return false;
    }
    scrap += tier.scrap;
    return true;
  }

  void _advanceContract(ContractDefinition task, int amount) {
    if (claimedContracts.contains(task.id)) return;
    final next = (contractProgress[task.id] ?? 0) + amount;
    contractProgress[task.id] = next.clamp(0, task.target).toInt();
    _completeContractIfReady(task);
  }

  void _completeContractIfReady(ContractDefinition task) {
    if (contractProgress[task.id] == task.target &&
        claimedContracts.add(task.id)) {
      scrap += task.scrapReward;
    }
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

  Map<String, Object?> toJson() => {
    'scrap': scrap,
    'bestStars': bestStars,
    'dayKey': dayKey,
    'contractProgress': contractProgress,
    'claimedContracts': claimedContracts.toList()..sort(),
    'weekKey': weekKey,
    'eventPoints': eventPoints,
    'claimedEventTiers': claimedEventTiers.toList()..sort(),
    'weeklyBestStars': weeklyBestStars,
  };

  factory CampaignProgress.fromJson(Map<String, Object?> json) =>
      CampaignProgress(
        scrap: json['scrap'] as int? ?? 0,
        bestStars: _intMap(json['bestStars']),
        dayKey: json['dayKey'] as String? ?? '',
        contractProgress: _intMap(json['contractProgress']),
        claimedContracts: (json['claimedContracts'] as List<Object?>? ?? [])
            .whereType<String>()
            .toSet(),
        weekKey: json['weekKey'] as String? ?? '',
        eventPoints: json['eventPoints'] as int? ?? 0,
        claimedEventTiers: (json['claimedEventTiers'] as List<Object?>? ?? [])
            .whereType<int>()
            .toSet(),
        weeklyBestStars: _intMap(json['weeklyBestStars']),
      );

  String encode() => jsonEncode(toJson());
  factory CampaignProgress.decode(String source) =>
      CampaignProgress.fromJson(jsonDecode(source) as Map<String, Object?>);

  static Map<String, int> _intMap(Object? value) => {
    if (value is Map<Object?, Object?>)
      for (final entry in value.entries)
        if (entry.key is String && entry.value is int)
          entry.key as String: entry.value as int,
  };

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
