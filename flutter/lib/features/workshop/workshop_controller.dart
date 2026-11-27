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
  }) : _rng = SeededRandom(seed),
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

  final GearBoard board;
  final List<GearDefinition> catalog;
  final ShopConfig shop;
  final WorkshopRules rules;
  final int seed;
  final Wallet wallet;
  final SeededRandom _rng;

  List<String?> offers = const [];
  int rerollsTaken = 0;
  bool locked = false;

  /// Definition bought but not yet placed.
  GearDefinition? hand;
  ({int x, int y})? selected;
  int _nextGearNumber = 1;
  int _nextTxn = 1;

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
    return WorkshopAction.ok;
  }

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
    if (merged == null) return WorkshopAction.notMergeable;
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
    board.removeAt(cell.x, cell.y);
    if (refund > 0) _grant(refund, 'sell', node.id);
    selected = null;
    return WorkshopAction.ok;
  }

  /// Called when the wave starts; returns any unplaced purchase as scrap.
  void lock() {
    if (hand != null) cancelHand();
    selected = null;
    locked = true;
  }

  void _rollOffers() {
    final boardHasTransmission = board.nodes.any(
      (n) => n.kind == GearKind.transmission,
    );
    offers = rollShop(
      _rng,
      catalog,
      shop,
      unlockedIds: _shopPool,
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
    kind: switch (gear.category) {
      'power-core' => GearKind.core,
      'transmission' => GearKind.transmission,
      'booster' => GearKind.booster,
      _ => GearKind.output,
    },
    x: x,
    y: y,
    localPorts: {for (final port in gear.ports) Direction.values.byName(port)},
    baseIntervalTicks: gear.baseIntervalTicks == 0
        ? 0
        : rules.intervalFor(gear.baseIntervalTicks, tier),
    tier: tier,
    outputKind: gear.category == 'infantry'
        ? GearOutputKind.spawnInfantry
        : GearOutputKind.none,
    targetLane: rules.laneForRow(y),
  );
}
