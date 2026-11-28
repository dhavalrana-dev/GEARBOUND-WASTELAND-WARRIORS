// ignore_for_file: avoid_print

/// Generates or checks shared/test-fixtures/workshop_cases.json: scripted
/// workshop sessions replayed by both engines (Dart:
/// test/features/workshop_fixture_test.dart, Unity: WorkshopFixtureTests).
///
///   dart run tool/workshop_cases.dart          # rewrite the fixture
///   dart run tool/workshop_cases.dart --check  # fail if it is stale
///
/// Expected values come from the Dart controller; the Unity port is checked
/// against them. Each case lists results it must exercise, and the generator
/// picks the first seed whose script produces all of them.
library;

import 'dart:convert';
import 'dart:io';

import 'package:gearbound/core/seeded_random.dart';
import 'package:gearbound/data/shared_rules.dart';
import 'package:gearbound/features/workshop/workshop_controller.dart';
import 'package:gearbound/mechanical/gear_network.dart';

const fixturePath = '../shared/test-fixtures/workshop_cases.json';

/// Scripts. Ops: buy(slot), buyId(id: first slot offering it, else slot -1),
/// tap(x,y), drop(from,to), sell, undo, cancel, reroll, lock,
/// intermission(wave,reward), preview(x,y[,from]), hold(slot).
final scripts = <Map<String, Object?>>[
  {
    'id': 'place-merge-sell-undo',
    'require': ['ok', 'notMergeable', 'nothingToUndo'],
    'ops': [
      {'op': 'buyId', 'id': 'unit.rivetguard'},
      {'op': 'preview', 'x': 1, 'y': 3},
      {'op': 'tap', 'x': 1, 'y': 3},
      {'op': 'tap', 'x': 1, 'y': 2},
      {'op': 'tap', 'x': 1, 'y': 3},
      {'op': 'sell'},
      {'op': 'undo'},
      {'op': 'undo'},
      {'op': 'undo'},
      {'op': 'cancel'},
      {'op': 'tap', 'x': 0, 'y': 2},
      {'op': 'tap', 'x': 1, 'y': 2},
      {'op': 'buy', 'slot': 0},
      {'op': 'tap', 'x': 2, 'y': 2},
      {'op': 'tap', 'x': 1, 'y': 2},
      {'op': 'tap', 'x': 2, 'y': 2},
      {'op': 'undo'},
      {'op': 'undo'},
      {'op': 'cancel'},
      {'op': 'undo'},
    ],
  },
  {
    'id': 'drag-move-and-merge',
    'require': ['ok', 'occupied', 'handFull'],
    'ops': [
      {'op': 'buyId', 'id': 'unit.rivetguard'},
      {
        'op': 'drop',
        'from': [1, 2],
        'to': [3, 3],
      },
      {'op': 'tap', 'x': 1, 'y': 0},
      {
        'op': 'preview',
        'x': 2,
        'y': 0,
        'from': [1, 2],
      },
      {
        'op': 'drop',
        'from': [1, 2],
        'to': [0, 2],
      },
      {
        'op': 'drop',
        'from': [1, 2],
        'to': [2, 2],
      },
      {
        'op': 'preview',
        'x': 1,
        'y': 0,
        'from': [2, 2],
      },
      {
        'op': 'drop',
        'from': [2, 2],
        'to': [1, 0],
      },
      {
        'op': 'drop',
        'from': [1, 0],
        'to': [9, 9],
      },
      {'op': 'undo'},
      {'op': 'undo'},
      {'op': 'sell'},
    ],
  },
  {
    'id': 'reroll-escalation-and-poverty',
    'require': ['ok', 'insufficientScrap', 'noOffer'],
    'ops': [
      {'op': 'reroll'},
      {'op': 'reroll'},
      {'op': 'reroll'},
      {'op': 'buy', 'slot': 0},
      {'op': 'tap', 'x': 4, 'y': 4},
      {'op': 'buy', 'slot': 0},
      {'op': 'buy', 'slot': 1},
      {'op': 'tap', 'x': 3, 'y': 4},
      {'op': 'buy', 'slot': 2},
      {'op': 'reroll'},
      {'op': 'reroll'},
      {'op': 'reroll'},
    ],
  },
  {
    'id': 'lock-and-intermission',
    'require': ['ok', 'locked'],
    'ops': [
      {'op': 'reroll'},
      {'op': 'buy', 'slot': 1},
      {'op': 'lock'},
      {'op': 'tap', 'x': 3, 'y': 3},
      {'op': 'reroll'},
      {'op': 'undo'},
      {'op': 'intermission', 'wave': 1, 'reward': 9},
      {'op': 'intermission', 'wave': 1, 'reward': 9},
      {'op': 'buy', 'slot': 2},
      {'op': 'tap', 'x': 2, 'y': 4},
      {'op': 'lock'},
      {'op': 'intermission', 'wave': 1, 'reward': 9},
      {'op': 'lock'},
      {'op': 'intermission', 'wave': 2, 'reward': 7},
      {'op': 'reroll'},
    ],
  },
  {
    'id': 'offer-holds',
    'require': ['ok', 'allHeld', 'noOffer', 'locked'],
    'firstOpOk': true,
    'ops': [
      {'op': 'hold', 'slot': 0},
      {'op': 'reroll'},
      {'op': 'hold', 'slot': 2},
      {'op': 'reroll'},
      {'op': 'hold', 'slot': 1},
      {'op': 'reroll'},
      {'op': 'hold', 'slot': 1},
      {'op': 'buy', 'slot': 0},
      {'op': 'hold', 'slot': 0},
      {'op': 'cancel'},
      {'op': 'lock'},
      {'op': 'hold', 'slot': 1},
      {'op': 'intermission', 'wave': 1, 'reward': 6},
      {'op': 'reroll'},
      {'op': 'hold', 'slot': 2},
      {'op': 'reroll'},
    ],
  },
  {
    'id': 'turret-lanes-and-sale',
    'require': ['ok'],
    'firstOpOk': true,
    'ops': [
      {'op': 'buyId', 'id': 'turret.spark'},
      {'op': 'preview', 'x': 2, 'y': 2},
      {'op': 'tap', 'x': 2, 'y': 1},
      {'op': 'tap', 'x': 2, 'y': 1},
      {'op': 'sell'},
      {'op': 'undo'},
      {
        'op': 'drop',
        'from': [2, 1],
        'to': [2, 2],
      },
      {
        'op': 'preview',
        'x': 1,
        'y': 4,
        'from': [2, 2],
      },
      {
        'op': 'drop',
        'from': [2, 2],
        'to': [1, 4],
      },
      {'op': 'reroll'},
    ],
  },
];

String _node(GearNode n) =>
    '${n.id}|${n.definitionId}|t${n.tier}|${n.x},${n.y}|'
    'lane${n.targetLane}|${n.baseIntervalTicks}';

Map<String, Object?> _snapshot(WorkshopController w, String result) {
  final nodes = w.board.nodes.toList()
    ..sort((a, b) => a.y != b.y ? a.y - b.y : a.x - b.x);
  final sel = w.selected;
  return {
    'result': result,
    'scrap': w.battleScrap,
    'offers': w.offers,
    'hand': w.hand?.id,
    'selected': sel == null ? null : [sel.x, sel.y],
    'held': w.held,
    'rerollsTaken': w.rerollsTaken,
    'locked': w.locked,
    'board': [for (final n in nodes) _node(n)],
  };
}

List<Map<String, Object?>> run(
  Map<String, Object?> script,
  int seed, {
  String Function(String rel)? read,
}) {
  final readShared =
      read ?? (String rel) => File('../shared/$rel').readAsStringSync();
  final catalog = loadGears(readShared('gears/starter_gears.json'));
  final shop = loadShop(readShared('economy/shop.json'));
  final rules = WorkshopRules.fromJson(readShared('configs/gear_rules.json'));
  final w = WorkshopController(
    board: GearBoard(),
    catalog: catalog,
    shop: shop,
    rules: rules,
    seed: seed,
  );
  final steps = [_snapshot(w, 'start')];
  ({int x, int y}) cell(Object? v) {
    final l = (v as List).cast<int>();
    return (x: l[0], y: l[1]);
  }

  for (final op in (script['ops'] as List).cast<Map<String, Object?>>()) {
    final String result;
    switch (op['op']) {
      case 'buy':
        result = w.buy(op['slot'] as int).name;
      case 'buyId':
        result = w.buy(w.offers.indexOf(op['id'] as String)).name;
      case 'tap':
        result = w.tapCell(op['x'] as int, op['y'] as int).name;
      case 'drop':
        result = w.drop(cell(op['from']), cell(op['to'])).name;
      case 'sell':
        result = w.sellSelected().name;
      case 'undo':
        result = w.undo().name;
      case 'cancel':
        result = w.cancelHand().name;
      case 'reroll':
        result = w.reroll().name;
      case 'hold':
        result = w.toggleHold(op['slot'] as int).name;
      case 'lock':
        w.lock();
        result = 'ok';
      case 'intermission':
        result = w
            .beginIntermission(
              clearedWave: op['wave'] as int,
              rewardScrap: op['reward'] as int,
            )
            .name;
      case 'preview':
        final p = w.previewAt(
          op['x'] as int,
          op['y'] as int,
          from: op['from'] == null ? null : cell(op['from']),
        );
        result =
            'valid=${p.valid};state=${p.state?.name};'
            'interval=${p.intervalTicks};lane=${p.lane}';
      default:
        throw ArgumentError('unknown op ${op['op']}');
    }
    steps.add(_snapshot(w, result));
  }
  return steps;
}

Map<String, Object?> build() {
  final cases = <Map<String, Object?>>[];
  for (final script in scripts) {
    final require = (script['require'] as List).cast<String>();
    for (var seed = 1; ; seed++) {
      if (seed > 5000) throw StateError('no seed satisfies ${script['id']}');
      final steps = run(script, seed);
      final seen = steps.map((s) => s['result']).toSet();
      if (!require.every(seen.contains)) continue;
      if (script['firstOpOk'] == true && steps[1]['result'] != 'ok') continue;
      cases.add({
        'id': script['id'],
        'seed': seed,
        'ops': script['ops'],
        'steps': steps,
      });
      break;
    }
  }
  return {
    'schemaVersion': 1,
    'generatedBy': 'flutter/tool/workshop_cases.dart',
    'rules':
        'Replay ops on a fresh WorkshopController (shared gear_rules, shop, '
        'starter_gears). steps[0] is the state after construction; steps[i] '
        'after ops[i-1]. held[i] is true while offer slot i is held. Board '
        'entries: id|definition|tier|x,y|lane|interval, sorted by row then '
        'column.',
    'mixSeed32': [
      for (final s in [0, 1, 2, 42, 0x7FFFFFFF, 0xFFFFFFFF])
        {'seed': s, 'mixed': mixSeed32(s)},
    ],
    'cases': cases,
  };
}

void main(List<String> args) {
  final text = '${const JsonEncoder.withIndent('  ').convert(build())}\n';
  final file = File(fixturePath);
  if (args.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync() != text) {
      print(
        'workshop_cases.json is stale; run dart run tool/workshop_cases.dart',
      );
      exit(1);
    }
    print('workshop cases up to date');
    return;
  }
  file.writeAsStringSync(text);
  print('wrote $fixturePath');
}
