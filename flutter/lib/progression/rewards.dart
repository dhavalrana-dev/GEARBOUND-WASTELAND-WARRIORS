/// Earn-only reward tuning mirrored from shared/events/progression_rewards.json.
/// test/progression/rewards_parity_test.dart fails if the two drift apart.
library;

class BoosterDefinition {
  const BoosterDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.maxStack,
  });
  final String id;
  final String name;
  final String description;
  final int maxStack;
}

class RewardBundle {
  const RewardBundle({this.scrap = 0, this.boosters = const {}});
  final int scrap;
  final Map<String, int> boosters;
}

class StarChest {
  const StarChest({required this.stars, required this.reward});
  final int stars;
  final RewardBundle reward;
}

const vanguardBoosterId = 'booster.vanguard';

const boosterDefinitions = <BoosterDefinition>[
  BoosterDefinition(
    id: vanguardBoosterId,
    name: 'Vanguard Drop',
    description:
        'One Rivetguard soldier waits in every lane when the wave starts.',
    maxStack: 9,
  ),
];

const winStreakName = 'Overclock Streak';
const winStreakMaxLevel = 3;
const streakSoldierLaneOrder = [1, 0, 2];

const starChests = <StarChest>[
  StarChest(
    stars: 6,
    reward: RewardBundle(scrap: 10, boosters: {vanguardBoosterId: 1}),
  ),
  StarChest(
    stars: 12,
    reward: RewardBundle(scrap: 15, boosters: {vanguardBoosterId: 1}),
  ),
  StarChest(
    stars: 18,
    reward: RewardBundle(scrap: 20, boosters: {vanguardBoosterId: 2}),
  ),
  StarChest(
    stars: 24,
    reward: RewardBundle(scrap: 25, boosters: {vanguardBoosterId: 2}),
  ),
  StarChest(
    stars: 30,
    reward: RewardBundle(scrap: 30, boosters: {vanguardBoosterId: 3}),
  ),
  StarChest(
    stars: 36,
    reward: RewardBundle(scrap: 40, boosters: {vanguardBoosterId: 3}),
  ),
];

const loginTrackName = 'Supply Log';
const loginTrackDays = <RewardBundle>[
  RewardBundle(scrap: 3),
  RewardBundle(boosters: {vanguardBoosterId: 1}),
  RewardBundle(scrap: 5),
  RewardBundle(scrap: 5),
  RewardBundle(boosters: {vanguardBoosterId: 1}),
  RewardBundle(scrap: 8),
  RewardBundle(scrap: 4, boosters: {vanguardBoosterId: 2}),
];

int boosterMaxStack(String id) =>
    boosterDefinitions.where((b) => b.id == id).firstOrNull?.maxStack ?? 0;

/// Lanes that receive a free soldier at wave start, in spawn order: streak
/// soldiers first (following [streakSoldierLaneOrder]), then one per lane for
/// an equipped Vanguard Drop.
List<int> openingSoldierLanes({
  required int streakLevel,
  required bool vanguard,
}) => [
  ...streakSoldierLaneOrder.take(streakLevel.clamp(0, winStreakMaxLevel)),
  if (vanguard) ...[0, 1, 2],
];

String describeReward(RewardBundle reward) {
  final parts = <String>[
    if (reward.scrap > 0) '${reward.scrap} scrap',
    for (final entry in reward.boosters.entries)
      if (entry.value > 0)
        '${entry.value}× ${boosterDefinitions.firstWhere((b) => b.id == entry.key).name}',
  ];
  return parts.join(' + ');
}
