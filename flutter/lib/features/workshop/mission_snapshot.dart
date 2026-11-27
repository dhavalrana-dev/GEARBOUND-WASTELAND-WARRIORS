import 'dart:convert';

import '../../mechanical/gear_network.dart';

/// Wave-boundary checkpoint of an active mission, saved so a mission survives
/// the OS killing the app. Mid-wave combat is not captured: resuming either
/// re-enters the rebuild phase ([atIntermission]) or **restarts the wave that
/// was in progress with the board locked as it was**, so killing the app can
/// never be used to rebuild against a wave already seen.
class MissionSnapshot {
  const MissionSnapshot({
    required this.levelId,
    required this.levelIndex,
    required this.waveIndex,
    required this.waveCount,
    required this.atIntermission,
    required this.fortressHealth,
    required this.heroLane,
    required this.heroHealth,
    required this.heroSp,
    required this.scrapReward,
    required this.openingLanes,
    required this.board,
    required this.workshop,
  });

  static const schemaVersion = 1;

  final String levelId;
  final int levelIndex;

  /// At an intermission: the wave just cleared. Otherwise: the wave to restart.
  final int waveIndex;
  final int waveCount;
  final bool atIntermission;
  final int fortressHealth;
  final int heroLane;
  final int heroHealth;
  final int heroSp;
  final int scrapReward;

  /// Opening soldier lanes (streak + Vanguard), re-deployed if wave 1 restarts.
  final List<int> openingLanes;
  final List<GearNode> board;

  /// `WorkshopController.toJson()`; null on the demo board (no shop).
  final Map<String, Object?>? workshop;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'levelId': levelId,
    'levelIndex': levelIndex,
    'waveIndex': waveIndex,
    'waveCount': waveCount,
    'atIntermission': atIntermission,
    'fortressHealth': fortressHealth,
    'hero': {'lane': heroLane, 'health': heroHealth, 'sp': heroSp},
    'scrapReward': scrapReward,
    'openingLanes': openingLanes,
    'board': [for (final n in board) nodeToJson(n)],
    'workshop': workshop,
  };

  String encode() => jsonEncode(toJson());

  /// Returns null for anything unreadable or from another schema version.
  static MissionSnapshot? tryDecode(String? source) {
    if (source == null) return null;
    try {
      final json = jsonDecode(source) as Map<String, Object?>;
      if (json['schemaVersion'] != schemaVersion) return null;
      final hero = json['hero'] as Map<String, Object?>;
      return MissionSnapshot(
        levelId: json['levelId'] as String,
        levelIndex: json['levelIndex'] as int,
        waveIndex: json['waveIndex'] as int,
        waveCount: json['waveCount'] as int,
        atIntermission: json['atIntermission'] as bool,
        fortressHealth: json['fortressHealth'] as int,
        heroLane: hero['lane'] as int,
        heroHealth: hero['health'] as int,
        heroSp: hero['sp'] as int,
        scrapReward: json['scrapReward'] as int,
        openingLanes: (json['openingLanes'] as List).cast<int>(),
        board: [
          for (final n in (json['board'] as List).cast<Map<String, Object?>>())
            nodeFromJson(n),
        ],
        workshop: json['workshop'] as Map<String, Object?>?,
      );
    } on Object {
      return null;
    }
  }

  static Map<String, Object?> nodeToJson(GearNode n) => {
    'id': n.id,
    'definitionId': n.definitionId,
    'kind': n.kind.name,
    'x': n.x,
    'y': n.y,
    'ports': [for (final p in n.localPorts) p.name]..sort(),
    'interval': n.baseIntervalTicks,
    'rotation': n.rotationQuarterTurns,
    'tier': n.tier,
    'output': n.outputKind.name,
    'lane': n.targetLane,
  };

  static GearNode nodeFromJson(Map<String, Object?> j) => GearNode(
    id: j['id'] as String,
    definitionId: j['definitionId'] as String,
    kind: GearKind.values.byName(j['kind'] as String),
    x: j['x'] as int,
    y: j['y'] as int,
    localPorts: {
      for (final p in (j['ports'] as List).cast<String>())
        Direction.values.byName(p),
    },
    baseIntervalTicks: j['interval'] as int,
    rotationQuarterTurns: j['rotation'] as int,
    tier: j['tier'] as int,
    outputKind: GearOutputKind.values.byName(j['output'] as String),
    targetLane: j['lane'] as int,
  );
}
