import '../combat/battle_session.dart';
import '../data/shared_content.dart';

/// Hand-authored starter route scripts. Later nodes use a deterministic
/// escalation fallback until their encounters receive their own content pass.
///
/// When [content] is supplied, nodes listed in shared/missions/campaign_route.json
/// use the shared mission data instead of the scripts below.
WaveDefinition encounterForLevel(int levelIndex, {SharedContent? content}) {
  if (levelIndex < 0 || levelIndex >= 12) {
    throw RangeError.range(levelIndex, 0, 11, 'levelIndex');
  }
  final id = campaignEncounterIds[levelIndex];
  final shared = content?.encounterFor(id);
  if (shared != null) return shared;
  final spawns = switch (levelIndex) {
    0 => [
      _spawn(0, 0, 32, 0, 6, 60),
      _spawn(45, 1, 32, 0, 6, 60),
      _spawn(90, 2, 32, 0, 6, 60),
    ],
    1 => [
      _spawn(0, 0, 22, 0, 4, 95, interval: 38),
      _spawn(22, 2, 22, 0, 4, 95, interval: 38),
      _spawn(48, 1, 22, 0, 4, 95, interval: 38),
      _spawn(70, 0, 22, 0, 4, 95, interval: 38),
    ],
    2 => [
      _spawn(0, 1, 56, 2, 8, 38, interval: 40),
      _spawn(24, 0, 24, 0, 5, 76, interval: 35),
      _spawn(54, 2, 56, 2, 8, 38, interval: 40),
      _spawn(76, 1, 24, 0, 5, 76, interval: 35),
    ],
    3 => [
      _spawn(0, 0, 24, 0, 5, 100, interval: 36),
      _spawn(16, 1, 24, 0, 5, 100, interval: 36),
      _spawn(32, 2, 24, 0, 5, 100, interval: 36),
      _spawn(62, 2, 24, 0, 5, 100, interval: 36),
      _spawn(78, 1, 24, 0, 5, 100, interval: 36),
      _spawn(94, 0, 24, 0, 5, 100, interval: 36),
    ],
    4 => [
      _spawn(0, 0, 34, 0, 6, 58),
      _spawn(20, 2, 34, 0, 6, 58),
      _spawn(45, 1, 140, 2, 10, 24, interval: 42, range: 320),
      _spawn(90, 1, 22, 0, 5, 80, interval: 38),
    ],
    _ => _escalatedSpawns(levelIndex),
  };
  return WaveDefinition(id: 'wave-$id', spawns: spawns, rewardScrap: 3);
}

const campaignEncounterIds = [
  'copperwash-01',
  'copperwash-02',
  'copperwash-03',
  'copperwash-04',
  'copperwash-05',
  'ironwood-01',
  'ironwood-02',
  'ironwood-03',
  'ironwood-04',
  'ironwood-05',
  'sunken-01',
  'sunken-02',
];

WaveSpawnEvent _spawn(
  int tick,
  int lane,
  int health,
  int armor,
  int damage,
  int speed, {
  int interval = 30,
  int range = 250,
}) => WaveSpawnEvent(
  tick: tick,
  lane: lane,
  health: health,
  armor: armor,
  damage: damage,
  attackRangeMm: range,
  movementMmPerTick: speed,
  attackIntervalTicks: interval,
);

List<WaveSpawnEvent> _escalatedSpawns(int levelIndex) => [
  for (var index = 0; index < 3 + levelIndex ~/ 4; index++)
    _spawn(
      index * 45,
      index % 3,
      32 + levelIndex * 4,
      levelIndex ~/ 5,
      6 + levelIndex ~/ 3,
      60 + levelIndex * 2,
      range: 250 + levelIndex * 10,
    ),
];
