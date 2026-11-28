import 'dart:convert';

import '../../core/seeded_random.dart';
import '../../data/shared_rules.dart';
import '../../economy/economy_rules.dart';
import '../../economy/wallet.dart';
import '../../mechanical/gear_network.dart';

/// Workshop tuning from shared/configs/gear_rules.json (`merge`, `workshop`).
class WorkshopRules {
  const WorkshopRules({
    required this.maxTier,
    required this.intervalPercentByTier,
    required this.outputLaneByRow,
    required this.starterGears,
    required this.shopCategories,
  });

  final int maxTier;
  final List<int> intervalPercentByTier;
  final List<int> outputLaneByRow;
  final List<({String definitionId, int x, int y})> starterGears;
  final Set<String> shopCategories;

  factory WorkshopRules.fromJson(String source) {
    final root = jsonDecode(source) as Map<String, Object?>;
    final merge = root['merge'] as Map<String, Object?>;
    final workshop = root['workshop'] as Map<String, Object?>;
    return WorkshopRules(
      maxTier: merge['maxTier'] as int,
      intervalPercentByTier: (merge['intervalPercentByTier'] as List)
          .cast<int>(),
      outputLaneByRow: (workshop['outputLaneByRow'] as List).cast<int>(),
      starterGears: [
        for (final g
            in (workshop['starterGears'] as List).cast<Map<String, Object?>>())
          (
            definitionId: g['definitionId'] as String,
            x: g['x'] as int,
            y: g['y'] as int,
          ),
      ],
      shopCategories: (workshop['shopCategories'] as List)
          .cast<String>()
          .toSet(),
    );
  }

  /// Output interval for a gear tier: base × percent / 100, rounded up.
  int intervalFor(int baseIntervalTicks, int tier) {
    final percent = intervalPercentByTier[tier - 1];
    return (baseIntervalTicks * percent + 99) ~/ 100;
  }

  int laneForRow(int row) => outputLaneByRow[row];
}

enum WorkshopAction {
  ok,
  locked,
  noOffer,
  handFull,
  insufficientScrap,
  occupied,
  nothingToPlace,
  notMergeable,
  maxTier,
  cannotSellCore,
  nothingSelected,
  nothingToUndo,
  allHeld,
}

/// What would happen if a gear were placed or moved to a cell.
class PlacementPreview {
  const PlacementPreview({
    required this.valid,
    required this.state,
    required this.intervalTicks,
    required this.lane,
  });

  /// False when the cell is occupied by a gear that cannot merge.
  final bool valid;
  final NetworkState? state;

  /// Effective output interval after boosters; 0 for non-output gears.
  final int intervalTicks;
  final int? lane;
}

/// One undoable board edit. Buys and rerolls are deliberately not undoable:
/// Cancel already refunds an unplaced buy, and undoing a reroll would let a
/// player preview offers for free.
class _UndoEntry {
  _UndoEntry(this.board, this.hand, this.scrapGained);
  final List<GearNode> board;
  final GearDefinition? hand;

  /// Battle scrap the edit returned (selling); undo charges it back.
  final int scrapGained;
}

/// Preparation-phase state for one mission attempt: battle scrap (a
/// mission-scoped wallet that is never saved), seeded shop offers, the gear in
/// hand, and the selected board gear.
///
/// Board edits happen only through this controller and only while unlocked.
/// Battle scrap moves through the same idempotent ledger rules as permanent
/// currency, so every spend and refund is audited.
class WorkshopController {
  WorkshopController({
    required this.board,
    required this.catalog,
    required this.shop,
    required this.rules,
    required int seed,
  }) : _rng = SeededRandom(mixSeed32(seed)),
       seed = seed,
       wallet = Wallet(rules: defaultAssetRules(), profileId: 'mission') {
    for (final starter in rules.starterGears) {
      board.place(
        _node(_definition(starter.definitionId), starter.x, starter.y, 1),
      );
    }
    wallet.apply(
      TxnRequest(
        idempotencyKey: 'mission_start',
        type: 'grant',
        source: 'mission_start',
        deltas: [TxnDelta(Currency.battleScrap, shop.startingScrap)],
      ),
    );
    _rollOffers();
  }

  /// Rebuilds a controller from [toJson] output at a wave boundary: the
  /// mission wallet (with its processed claim keys, so no wave reward can be
  /// paid twice), offers, reroll count, ID counters and RNG state, so the
  /// shop continues exactly where it stopped. Starter gears are not placed
  /// again; the board comes from the checkpoint.
  WorkshopController.restore({
    required this.board,
    required this.catalog,
    required this.shop,
    required this.rules,
    required Map<String, Object?> json,
  }) : seed = json['seed'] as int,
       _rng = SeededRandom(json['rngState'] as int)
         ..draws = json['rngDraws'] as int,
       wallet = Wallet.fromJson(
         json['wallet'] as Map<String, Object?>,
         defaultAssetRules(),
       ) {
    offers = (json['offers'] as List).cast<String?>();
    // Checkpoints written before offer holds existed have no 'held' list.
    final heldJson = json['held'] as List?;
    held = heldJson == null
        ? List<bool>.filled(offers.length, false)
        : heldJson.cast<bool>().toList();
    rerollsTaken = json['rerollsTaken'] as int;
    locked = json['locked'] as bool;
    final handId = json['hand'] as String?;
    hand = handId == null ? null : _definition(handId);
    _nextGearNumber = json['nextGearNumber'] as int;
    _nextTxn = json['nextTxn'] as int;
  }

  Map<String, Object?> toJson() => {
    'seed': seed,
    'rngState': _rng.state,
    'rngDraws': _rng.draws,
    'wallet': wallet.toJson(),
    'offers': offers,
    'held': held,
    'rerollsTaken': rerollsTaken,
    'locked': locked,
    'hand': hand?.id,
    'nextGearNumber': _nextGearNumber,
    'nextTxn': _nextTxn,
  };

  final GearBoard board;
  final List<GearDefinition> catalog;
  final ShopConfig shop;
  final WorkshopRules rules;
  final int seed;
  final Wallet wallet;
  final SeededRandom _rng;

  List<String?> offers = const [];

  /// Offers the player is holding: a reroll and a new wave's shop keep them.
  List<bool> held = const [];
  int rerollsTaken = 0;
  bool locked = false;

  /// Definition bought but not yet placed.
  GearDefinition? hand;
  ({int x, int y})? selected;
  int _nextGearNumber = 1;
  int _nextTxn = 1;
  final List<_UndoEntry> _undo = [];

  bool get canUndo => !locked && _undo.isNotEmpty;

  int get battleScrap => wallet.balance(Currency.battleScrap);
  int get rerollPrice => rerollCost(shop, rerollsTaken);

  Set<String> get _shopPool => {
    for (final g in catalog)
      if (rules.shopCategories.contains(g.category)) g.id,
  };

  GearDefinition definitionFor(String id) => _definition(id);
  GearDefinition? get selectedDefinition {
    final cell = selected;
    if (cell == null) return null;
    final node = board.at(cell.x, cell.y);
    return node == null ? null : _definition(node.definitionId);
  }

  /// Battle scrap returned when selling the selected gear: the refund share of
  /// every tier-1 gear merged into it.
  int get selectedSellValue {
    final cell = selected;
    final node = cell == null ? null : board.at(cell.x, cell.y);
    if (node == null) return 0;
    final copies = 1 << (node.tier - 1);
    return sellValue(shop, _definition(node.definitionId)) * copies;
  }

  WorkshopAction buy(int slot) {
    if (locked) return WorkshopAction.locked;
    if (hand != null) return WorkshopAction.handFull;
    final id = slot >= 0 && slot < offers.length ? offers[slot] : null;
    if (id == null) return WorkshopAction.noOffer;
    final gear = _definition(id);
    if (!_spend(gear.cost, 'buy', id)) return WorkshopAction.insufficientScrap;
    hand = gear;
    selected = null;
    offers = [...offers]..[slot] = null;
    held = [...held]..[slot] = false;
    return WorkshopAction.ok;
  }

  /// Holds or releases an offer. Free; a held offer survives rerolls and the
  /// next wave's shop until it is bought or released.
  WorkshopAction toggleHold(int slot) {
    if (locked) return WorkshopAction.locked;
    if (slot < 0 || slot >= offers.length || offers[slot] == null) {
      return WorkshopAction.noOffer;
    }
    held = [...held]..[slot] = !held[slot];
    return WorkshopAction.ok;
  }

  /// True when every slot is held, so a reroll could not change anything.
  bool get allHeld => held.isNotEmpty && held.every((h) => h);

  /// Undo an unplaced purchase for a full refund.
  WorkshopAction cancelHand() {
    final gear = hand;
    if (gear == null) return WorkshopAction.nothingToPlace;
    _grant(gear.cost, 'undo_buy', gear.id);
    hand = null;
    return WorkshopAction.ok;
  }

  WorkshopAction reroll() {
    if (locked) return WorkshopAction.locked;
    if (allHeld) return WorkshopAction.allHeld;
    if (!_spend(rerollPrice, 'reroll', 'shop')) {
      return WorkshopAction.insufficientScrap;
    }
    rerollsTaken++;
    _rollOffers();
    return WorkshopAction.ok;
  }

  /// Places the gear in hand, selects/deselects a gear, or merges the selected
  /// gear into a matching one.
  WorkshopAction tapCell(int x, int y) {
    if (locked) return WorkshopAction.locked;
    if (x < 0 || y < 0 || x >= board.width || y >= board.height) {
      return WorkshopAction.occupied;
    }
    final gear = hand;
    final node = board.at(x, y);
    if (gear != null) {
      if (node != null) return WorkshopAction.occupied;
      _pushUndo();
      board.place(_node(gear, x, y, 1));
      hand = null;
      return WorkshopAction.ok;
    }
    if (node == null || node.kind == GearKind.core) {
      selected = null;
      return node == null ? WorkshopAction.nothingSelected : WorkshopAction.ok;
    }
    final current = selected;
    if (current == null || (current.x == x && current.y == y)) {
      selected = current == null ? (x: x, y: y) : null;
      return WorkshopAction.ok;
    }
    final other = board.at(current.x, current.y)!;
    if (other.definitionId != node.definitionId || other.tier != node.tier) {
      selected = (x: x, y: y);
      return WorkshopAction.notMergeable;
    }
    if (node.tier >= rules.maxTier) return WorkshopAction.maxTier;
    final definition = _definition(node.definitionId);
    _pushUndo();
    final merged = board.merge(
      current.x,
      current.y,
      x,
      y,
      maxTier: rules.maxTier,
      nextTierBaseIntervalTicks: definition.baseIntervalTicks == 0
          ? 0
          : rules.intervalFor(definition.baseIntervalTicks, node.tier + 1),
    );
    // The merged gear keeps the top-left cell, so its lane still follows its row.
    if (merged == null) {
      _undo.removeLast();
      return WorkshopAction.notMergeable;
    }
    selected = (x: merged.x, y: merged.y);
    return WorkshopAction.ok;
  }

  WorkshopAction sellSelected() {
    if (locked) return WorkshopAction.locked;
    final cell = selected;
    final node = cell == null ? null : board.at(cell.x, cell.y);
    if (cell == null || node == null) return WorkshopAction.nothingSelected;
    if (node.kind == GearKind.core) return WorkshopAction.cannotSellCore;
    final refund = selectedSellValue;
    _pushUndo(scrapGained: refund);
    board.removeAt(cell.x, cell.y);
    if (refund > 0) _grant(refund, 'sell', node.id);
    selected = null;
    return WorkshopAction.ok;
  }

  /// Called when the wave starts; returns any unplaced purchase as scrap.
  void lock() {
    if (hand != null) cancelHand();
    selected = null;
    _undo.clear();
    locked = true;
  }

  /// Reopens the workshop between waves: pays the cleared wave's reward in
  /// battle scrap (once per wave number, through the ledger), resets the
  /// reroll price and rolls fresh offers around any held ones. The board is
  /// kept as built.
  WorkshopAction beginIntermission({
    required int clearedWave,
    required int rewardScrap,
  }) {
    if (!locked) return WorkshopAction.ok;
    if (rewardScrap > 0) {
      wallet.apply(
        TxnRequest(
          idempotencyKey: 'wave_reward:$clearedWave',
          type: 'grant',
          source: 'wave_reward',
          referenceId: 'wave $clearedWave',
          deltas: [TxnDelta(Currency.battleScrap, rewardScrap)],
        ),
      );
    }
    locked = false;
    rerollsTaken = 0;
    _rollOffers();
    return WorkshopAction.ok;
  }

  /// Drops a dragged gear from [from] onto [to]: moves it to an empty cell,
  /// merges it into an identical gear, or is refused. Moving is free; the
  /// gear's lane follows its new row.
  WorkshopAction drop(({int x, int y}) from, ({int x, int y}) to) {
    if (locked) return WorkshopAction.locked;
    if (hand != null) return WorkshopAction.handFull;
    final node = board.at(from.x, from.y);
    if (node == null) return WorkshopAction.nothingSelected;
    if (to.x < 0 || to.y < 0 || to.x >= board.width || to.y >= board.height) {
      return WorkshopAction.occupied;
    }
    if (from == to) return WorkshopAction.ok;
    final target = board.at(to.x, to.y);
    if (target != null) {
      if (target.kind == GearKind.core) return WorkshopAction.occupied;
      selected = from;
      return tapCell(to.x, to.y);
    }
    _pushUndo();
    board.removeAt(from.x, from.y);
    board.place(_moved(node, to.x, to.y));
    selected = to;
    return WorkshopAction.ok;
  }

  /// Reverts the most recent place, move, merge or sell.
  WorkshopAction undo() {
    if (locked) return WorkshopAction.locked;
    if (_undo.isEmpty) return WorkshopAction.nothingToUndo;
    final entry = _undo.last;
    if (entry.hand != null && hand != null) return WorkshopAction.handFull;
    if (entry.scrapGained > battleScrap) {
      return WorkshopAction.insufficientScrap;
    }
    if (entry.scrapGained > 0 &&
        !_spend(entry.scrapGained, 'undo_sell', 'undo')) {
      return WorkshopAction.insufficientScrap;
    }
    _undo.removeLast();
    for (final node in board.nodes.toList()) {
      board.removeAt(node.x, node.y);
    }
    for (final node in entry.board) {
      board.place(_copy(node));
    }
    hand = entry.hand ?? hand;
    selected = null;
    return WorkshopAction.ok;
  }

  /// Network outcome of putting the hand gear, or the gear at [from], on
  /// ([x], [y]), computed on a copy of the board.
  PlacementPreview previewAt(int x, int y, {({int x, int y})? from}) {
    final trial = GearBoard(width: board.width, height: board.height);
    for (final node in board.nodes) {
      if (from != null && node.x == from.x && node.y == from.y) continue;
      trial.place(_copy(node));
    }
    final GearNode? candidate;
    final moving = from == null ? null : board.at(from.x, from.y);
    if (moving != null) {
      candidate = _moved(moving, x, y);
    } else if (hand != null) {
      candidate = GearNode(
        id: '__preview__',
        definitionId: hand!.id,
        kind: _kindOf(hand!),
        x: x,
        y: y,
        localPorts: {for (final p in hand!.ports) Direction.values.byName(p)},
        baseIntervalTicks: hand!.baseIntervalTicks,
        outputKind: _outputKindOf(hand!),
        targetLane: rules.laneForRow(y),
        projectileDamage: hand!.projectileDamage,
        projectileSpeedMmPerTick: hand!.projectileSpeedMmPerTick,
      );
    } else {
      candidate = null;
    }
    if (candidate == null) {
      return const PlacementPreview(
        valid: false,
        state: null,
        intervalTicks: 0,
        lane: null,
      );
    }
    final occupant = trial.at(x, y);
    if (occupant != null) {
      final mergeable =
          occupant.definitionId == candidate.definitionId &&
          occupant.tier == candidate.tier &&
          occupant.tier < rules.maxTier;
      return PlacementPreview(
        valid: mergeable,
        state: null,
        intervalTicks: 0,
        lane: null,
      );
    }
    trial.place(candidate);
    final result = GearNetwork.rebuild(trial).nodes[candidate.id];
    return PlacementPreview(
      valid: true,
      state: result?.state,
      intervalTicks: result?.effectiveIntervalTicks ?? 0,
      lane: candidate.outputKind == GearOutputKind.none
          ? null
          : candidate.targetLane,
    );
  }

  static GearKind _kindOf(GearDefinition gear) => switch (gear.category) {
    'power-core' => GearKind.core,
    'transmission' => GearKind.transmission,
    'booster' => GearKind.booster,
    _ => GearKind.output,
  };

  void _pushUndo({int scrapGained = 0}) => _undo.add(
    _UndoEntry([for (final n in board.nodes) _copy(n)], hand, scrapGained),
  );

  GearNode _copy(GearNode n) => _moved(n, n.x, n.y);

  GearNode _moved(GearNode n, int x, int y) => GearNode(
    id: n.id,
    definitionId: n.definitionId,
    kind: n.kind,
    x: x,
    y: y,
    localPorts: n.localPorts,
    baseIntervalTicks: n.baseIntervalTicks,
    rotationQuarterTurns: n.rotationQuarterTurns,
    tier: n.tier,
    outputKind: n.outputKind,
    targetLane: n.outputKind == GearOutputKind.none
        ? n.targetLane
        : rules.laneForRow(y),
    projectileDamage: n.projectileDamage,
    projectileSpeedMmPerTick: n.projectileSpeedMmPerTick,
  );

  void _rollOffers() {
    final boardHasTransmission = board.nodes.any(
      (n) => n.kind == GearKind.transmission,
    );
    if (held.length != shop.offerCount) {
      held = List<bool>.filled(shop.offerCount, false);
    }
    offers = rollShop(
      _rng,
      catalog,
      shop,
      unlockedIds: _shopPool,
      lockedOffers: held.contains(true)
          ? [for (var i = 0; i < held.length; i++) held[i] ? offers[i] : null]
          : null,
      boardHasGuaranteedCategory: boardHasTransmission,
    );
  }

  bool _spend(int amount, String type, String ref) {
    if (amount <= 0) return true;
    return wallet
        .apply(
          TxnRequest(
            idempotencyKey: '$type:${_nextTxn++}',
            type: 'spend',
            source: type,
            referenceId: ref,
            deltas: [TxnDelta(Currency.battleScrap, -amount)],
          ),
        )
        .applied;
  }

  void _grant(int amount, String type, String ref) => wallet.apply(
    TxnRequest(
      idempotencyKey: '$type:${_nextTxn++}',
      type: 'refund',
      source: type,
      referenceId: ref,
      deltas: [TxnDelta(Currency.battleScrap, amount)],
    ),
  );

  GearDefinition _definition(String id) =>
      catalog.firstWhere((g) => g.id == id);

  GearNode _node(GearDefinition gear, int x, int y, int tier) => GearNode(
    id: '${gear.id}#${_nextGearNumber++}',
    definitionId: gear.id,
    kind: _kindOf(gear),
    x: x,
    y: y,
    localPorts: {for (final port in gear.ports) Direction.values.byName(port)},
    baseIntervalTicks: gear.baseIntervalTicks == 0
        ? 0
        : rules.intervalFor(gear.baseIntervalTicks, tier),
    tier: tier,
    outputKind: _outputKindOf(gear),
    targetLane: rules.laneForRow(y),
    projectileDamage: gear.projectileDamage,
    projectileSpeedMmPerTick: gear.projectileSpeedMmPerTick,
  );

  static GearOutputKind _outputKindOf(GearDefinition gear) =>
      switch (gear.category) {
        'infantry' => GearOutputKind.spawnInfantry,
        'turret' => GearOutputKind.fireProjectile,
        _ => GearOutputKind.none,
      };
}
