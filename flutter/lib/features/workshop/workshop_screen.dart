import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flame/game.dart' show GameWidget;

import '../../combat/battle_session.dart';
import '../../combat/combat_simulation.dart';
import '../../data/shared_content.dart';
import '../../game/gearbound_game.dart';
import '../../mechanical/gear_network.dart';
import '../../progression/campaign_progress.dart';
import '../../progression/encounters.dart';
import '../../progression/rewards.dart';
import '../../design_system/tokens.dart';
import 'workshop_controller.dart';

class WorkshopScreen extends StatefulWidget {
  const WorkshopScreen({
    required this.levelIndex,
    required this.progress,
    required this.onProgressSaved,
    this.content,
    this.shopSeed,
    super.key,
  });
  final int levelIndex;

  /// Fixed shop seed for tests; production seeds from the clock.
  final int? shopSeed;
  final CampaignProgress progress;
  final SharedContent? content;
  final Future<void> Function(CampaignProgress) onProgressSaved;

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  late final GearboundGame _game;
  late final GearBoard _board;
  late final BattleSession _session;
  late GearNetworkResult _network;
  WorkshopController? _workshop;
  late final List<WaveDefinition> _waves;
  int _intermissionsHandled = 0;

  /// Board edits are allowed before the first wave and between waves.
  bool get _canEdit =>
      _session.phase == BattlePhase.preparation ||
      _session.phase == BattlePhase.intermission;

  /// Board cell a drag started from; null while dragging the hand gear.
  ({int x, int y})? _dragFrom;
  String? _notice;
  bool _resultRecorded = false;
  bool _useVanguard = false;
  int _openingSoldiers = 0;

  @override
  void initState() {
    super.initState();
    final content = widget.content;
    if (content != null) {
      _board = GearBoard();
      _workshop = WorkshopController(
        board: _board,
        catalog: content.gears,
        shop: content.shop,
        rules: content.workshopRules,
        seed:
            widget.shopSeed ??
            (DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF),
      );
    } else {
      // Shared data failed to load: keep the mission playable on the
      // built-in demo board, without a shop.
      _board = makeStarterBoard();
    }
    _waves = encounterWavesForLevel(widget.levelIndex, content: widget.content);
    _network = GearNetwork.rebuild(_board);
    _session = BattleSession(
      board: _board,
      network: _network,
      wave: _waves.first,
      laterWaves: _waves.skip(1).toList(),
      combat: CombatSimulation(worldLengthMm: 10000),
    );
    _game = GearboundGame(_session)
      ..onCellTap = _onCellTap
      ..selectedCell = (() => _workshop?.selected)
      ..isPlacing = (() => _workshop?.hand != null)
      ..onDragStartCell = _onDragStart
      ..onDropCell = _onDrop
      ..onDragCancelled = (() => _dragFrom = null)
      ..previewCell = _previewCell;
    _game.onSessionChanged = () {
      if (_session.phase == BattlePhase.intermission &&
          _intermissionsHandled <= _session.waveIndex) {
        _intermissionsHandled = _session.waveIndex + 1;
        _workshop?.beginIntermission(
          clearedWave: _session.waveIndex + 1,
          rewardScrap: _session.lastWaveReward,
        );
        _notice =
            'Wave ${_session.waveIndex + 1} cleared: '
            '+${_session.lastWaveReward} battle scrap. Rebuild, then start the next wave.';
      }
      if (_session.phase == BattlePhase.victory && !_resultRecorded) {
        _resultRecorded = true;
        final health = _session.combat.fortressHealth;
        final stars = health >= 75
            ? 3
            : health >= 40
            ? 2
            : 1;
        widget.progress.recordVictory(
          campaignLevels[widget.levelIndex].id,
          stars,
        );
        unawaited(widget.onProgressSaved(widget.progress));
      }
      if (_session.phase == BattlePhase.defeat && !_resultRecorded) {
        _resultRecorded = true;
        widget.progress.recordDefeat();
        unawaited(widget.onProgressSaved(widget.progress));
      }
      if (mounted) setState(() {});
    };
  }

  void _refreshNetwork() {
    _game.refreshNetwork();
    setState(() {
      _network = _session.network;
    });
  }

  void _onCellTap(int x, int y) {
    final workshop = _workshop;
    if (workshop == null || !_canEdit) return;
    _show(workshop.tapCell(x, y));
    _refreshNetwork();
  }

  bool _onDragStart(int x, int y) {
    final workshop = _workshop;
    if (workshop == null || !_canEdit) {
      return false;
    }
    if (workshop.hand != null) {
      _dragFrom = null;
      return true;
    }
    final node = _board.at(x, y);
    if (node == null || node.kind == GearKind.core) return false;
    _dragFrom = (x: x, y: y);
    return true;
  }

  void _onDrop(int x, int y) {
    final workshop = _workshop;
    if (workshop == null) return;
    final from = _dragFrom;
    _dragFrom = null;
    _show(
      from == null ? workshop.tapCell(x, y) : workshop.drop(from, (x: x, y: y)),
    );
    _refreshNetwork();
  }

  ({bool valid, bool powered})? _previewCell(int x, int y) {
    final workshop = _workshop;
    if (workshop == null) return null;
    final preview = workshop.previewAt(x, y, from: _dragFrom);
    return (
      valid: preview.valid,
      powered: preview.state == NetworkState.powered,
    );
  }

  /// One-line status for the selected board gear.
  String? _selectedStatus() {
    final cell = _workshop?.selected;
    final node = cell == null ? null : _board.at(cell.x, cell.y);
    if (node == null) return null;
    final result = _network.nodes[node.id];
    final state = switch (result?.state) {
      NetworkState.powered => 'Powered',
      NetworkState.unpowered => 'Unpowered: connect it to the core',
      NetworkState.jammed => 'Jammed: odd gear loop',
      NetworkState.conflicted => 'Conflicted: more than one core',
      null => 'Unknown',
    };
    if (node.outputKind == GearOutputKind.none) {
      return 'Tier ${node.tier} · $state';
    }
    final interval = result?.effectiveIntervalTicks ?? 0;
    final seconds = interval == 0 ? '-' : (interval / 30).toStringAsFixed(1);
    return 'Tier ${node.tier} · $state · lane ${node.targetLane + 1} · one soldier every ${seconds}s';
  }

  void _show(WorkshopAction result) {
    _notice = switch (result) {
      WorkshopAction.ok => null,
      WorkshopAction.insufficientScrap => 'Not enough battle scrap.',
      WorkshopAction.occupied => 'That cell is taken.',
      WorkshopAction.notMergeable =>
        'Only identical gears of the same tier merge.',
      WorkshopAction.maxTier => 'That gear is already at its top tier.',
      WorkshopAction.handFull => 'Place or cancel the gear in hand first.',
      WorkshopAction.cannotSellCore => 'The power core cannot be sold.',
      WorkshopAction.locked => 'The workshop is locked during the wave.',
      WorkshopAction.nothingToUndo => 'Nothing to undo.',
      WorkshopAction.noOffer ||
      WorkshopAction.nothingToPlace ||
      WorkshopAction.nothingSelected => null,
    };
  }

  void _workshopAction(WorkshopAction Function(WorkshopController) action) {
    final workshop = _workshop;
    if (workshop == null) return;
    _show(action(workshop));
    _refreshNetwork();
  }

  Widget _shopPanel() {
    final workshop = _workshop;
    if (workshop == null || !_canEdit) {
      return const SizedBox.shrink();
    }
    return _ShopPanel(
      workshop: workshop,
      notice: _notice,
      status: _selectedStatus(),
      onUndo: () => _workshopAction((w) => w.undo()),
      onBuy: (slot) => _workshopAction((w) => w.buy(slot)),
      onReroll: () => _workshopAction((w) => w.reroll()),
      onCancel: () => _workshopAction((w) => w.cancelHand()),
      onSell: () => _workshopAction((w) => w.sellSelected()),
    );
  }

  void _moveHero(int delta) {
    final hero = _session.combat.combatants.firstWhere(
      (unit) => unit.id == _session.heroId,
    );
    final targetLane = (hero.lane + delta).clamp(0, 2).toInt();
    if (targetLane != hero.lane && _game.moveHeroToLane(targetLane)) {
      widget.progress.recordLaneCommand();
      unawaited(widget.onProgressSaved(widget.progress));
    }
    setState(() {});
  }

  void _startWave() {
    widget.progress.recordSetup(
      _network.nodes.values
          .where((node) => node.state == NetworkState.powered)
          .length,
    );
    if (_session.phase == BattlePhase.intermission) {
      _workshop?.lock();
      _refreshNetwork();
      _notice = null;
      if (_game.startWave()) setState(() {});
      return;
    }
    if (_session.phase != BattlePhase.preparation) return;
    _workshop?.lock();
    _refreshNetwork();
    final vanguard =
        _useVanguard && widget.progress.consumeBooster(vanguardBoosterId);
    final lanes = openingSoldierLanes(
      streakLevel: widget.progress.winStreak,
      vanguard: vanguard,
    );
    for (var i = 0; i < lanes.length; i++) {
      // Same stats as a Rivetguard Press soldier; IDs 90000+ are reserved for
      // opening reinforcements so they never collide with outputs or enemies.
      _session.combat.add(
        Combatant(
          id: 90000 + i,
          faction: CombatFaction.friendly,
          lane: lanes[i],
          positionMm: 0,
          health: 30,
          armor: 1,
          damage: 5,
          attackRangeMm: 250,
          movementMmPerTick: 40,
          attackIntervalTicks: 24,
        ),
      );
    }
    _openingSoldiers = lanes.length;
    unawaited(widget.onProgressSaved(widget.progress));
    if (_game.startWave()) setState(() {});
  }

  Widget _loadout() => _LoadoutBar(
    streakLevel: widget.progress.winStreak,
    vanguardOwned: widget.progress.boosterCount(vanguardBoosterId),
    useVanguard: _useVanguard,
    deployedSoldiers: _openingSoldiers,
    isPreparation: _session.phase == BattlePhase.preparation,
    onToggleVanguard: (value) => setState(() => _useVanguard = value),
  );

  Future<void> _returnToRoute() async {
    await widget.onProgressSaved(widget.progress);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > constraints.maxHeight;
            return Padding(
              padding: const EdgeInsets.all(12),
              child: wide ? _buildLandscape() : _buildPortrait(),
            );
          },
        ),
      ),
    );
  }

  /// Status, shop, loadout and actions. Shared by both orientations and
  /// scrollable, so small or short screens never overflow.
  List<Widget> _controls() {
    final powered = _network.nodes.values
        .where((node) => node.state == NetworkState.powered)
        .length;
    final enemies = _session.combat.combatants
        .where((unit) => unit.isAlive && unit.faction == CombatFaction.enemy)
        .length;
    return [
      _StatusCard(
        waveNumber: _session.waveIndex + 1,
        waveCount: _session.waves.length,
        poweredGears: powered,
        enemiesRemaining: enemies,
        phase: _session.phase,
      ),
      const SizedBox(height: 8),
      _shopPanel(),
      _loadout(),
      const SizedBox(height: 8),
      _Actions(
        onLaneDown: () => _moveHero(-1),
        onLaneUp: () => _moveHero(1),
        onStartWave: _startWave,
        canStartWave: _canEdit,
        isCombat: _session.phase == BattlePhase.combat,
      ),
      if (_session.phase == BattlePhase.victory ||
          _session.phase == BattlePhase.defeat) ...[
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: _returnToRoute,
          child: const Text('BACK TO ROUTE'),
        ),
      ],
    ];
  }

  Widget _buildPortrait() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Header(scrap: widget.progress.scrap),
      const SizedBox(height: 10),
      // The battlefield and board always keep at least ~55% of the height.
      Expanded(
        flex: 11,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: GearboundGameWidget(game: _game),
        ),
      ),
      const SizedBox(height: 10),
      Flexible(
        flex: 9,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _controls(),
          ),
        ),
      ),
    ],
  );

  Widget _buildLandscape() => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: GearboundGameWidget(game: _game),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(compact: true, scrap: widget.progress.scrap),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _controls(),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class GearboundGameWidget extends StatelessWidget {
  const GearboundGameWidget({required this.game, super.key});
  final GearboundGame game;

  @override
  Widget build(BuildContext context) => GameWidget<GearboundGame>(game: game);
}

class _Header extends StatelessWidget {
  const _Header({required this.scrap, this.compact = false});
  final bool compact;
  final int scrap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: GbColors.amber,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.settings, color: GbColors.ink),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              compact ? 'GEARBOUND' : 'GEARBOUND: WASTELAND WARRIORS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GbColors.cream,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const Text(
              'Build the machine. Command the battle.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      const Icon(Icons.recycling, color: GbColors.amber, size: 18),
      const SizedBox(width: 4),
      Text('$scrap', style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.waveNumber,
    required this.waveCount,
    required this.poweredGears,
    required this.enemiesRemaining,
    required this.phase,
  });
  final int waveNumber;
  final int waveCount;
  final int poweredGears;
  final int enemiesRemaining;
  final BattlePhase phase;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: GbColors.panel,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.bolt, color: Color(0xFF97E077)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Wave $waveNumber/$waveCount · ${_phaseLabel(phase)} · $poweredGears powered · $enemiesRemaining raiders',
            style: const TextStyle(
              color: GbColors.cream,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onLaneDown,
    required this.onLaneUp,
    required this.onStartWave,
    required this.canStartWave,
    required this.isCombat,
  });
  final VoidCallback onLaneDown;
  final VoidCallback onLaneUp;
  final VoidCallback onStartWave;
  final bool canStartWave;
  final bool isCombat;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: canStartWave ? onStartWave : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('START WAVE'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: GbColors.amber,
                foregroundColor: GbColors.ink,
              ),
            ),
          ),
        ],
      ),
      if (isCombat) ...[
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'COMMAND WAYFARER',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onLaneDown,
              tooltip: 'Move down one lane',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: GbColors.cream,
              ),
            ),
            IconButton(
              onPressed: onLaneUp,
              tooltip: 'Move up one lane',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_up, color: GbColors.cream),
            ),
          ],
        ),
      ],
    ],
  );
}

String _phaseLabel(BattlePhase phase) => switch (phase) {
  BattlePhase.preparation => 'PREP',
  BattlePhase.intermission => 'REBUILD',
  BattlePhase.combat => 'LIVE',
  BattlePhase.victory => 'CLEAR',
  BattlePhase.defeat => 'DEFEAT',
};

class _LoadoutBar extends StatelessWidget {
  const _LoadoutBar({
    required this.streakLevel,
    required this.vanguardOwned,
    required this.useVanguard,
    required this.deployedSoldiers,
    required this.isPreparation,
    required this.onToggleVanguard,
  });
  final int streakLevel;
  final int vanguardOwned;
  final bool useVanguard;
  final int deployedSoldiers;
  final bool isPreparation;
  final ValueChanged<bool> onToggleVanguard;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: GbColors.panel,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.speed, color: GbColors.amber, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isPreparation
                ? 'Streak $streakLevel: +$streakLevel soldier${streakLevel == 1 ? '' : 's'} at start'
                : '$deployedSoldiers opening soldier${deployedSoldiers == 1 ? '' : 's'} deployed',
            style: const TextStyle(color: GbColors.cream, fontSize: 11),
          ),
        ),
        if (isPreparation) ...[
          Text(
            'Vanguard ×$vanguardOwned',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Switch(
            value: useVanguard && vanguardOwned > 0,
            onChanged: vanguardOwned > 0 ? onToggleVanguard : null,
            activeThumbColor: GbColors.amber,
          ),
        ],
      ],
    ),
  );
}

class _ShopPanel extends StatelessWidget {
  const _ShopPanel({
    required this.workshop,
    required this.notice,
    required this.status,
    required this.onUndo,
    required this.onBuy,
    required this.onReroll,
    required this.onCancel,
    required this.onSell,
  });

  final WorkshopController workshop;
  final String? notice;
  final String? status;
  final VoidCallback onUndo;
  final ValueChanged<int> onBuy;
  final VoidCallback onReroll;
  final VoidCallback onCancel;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final hand = workshop.hand;
    final selected = workshop.selectedDefinition;
    final scrap = workshop.battleScrap;
    final hint = hand != null
        ? 'Placing ${hand.name}: tap or drag to an empty cell. Row sets the lane.'
        : selected != null
        ? '${selected.name} selected: drag to move, or onto an identical gear to merge.'
        : 'Buy a gear, then tap or drag it onto the board.';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GbColors.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.recycling, color: GbColors.amber, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$scrap battle scrap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GbColors.cream,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: hand == null && scrap >= workshop.rerollPrice
                    ? onReroll
                    : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('REROLL ${workshop.rerollPrice}'),
              ),
            ],
          ),
          Row(
            children: [
              for (var slot = 0; slot < workshop.offers.length; slot++) ...[
                if (slot > 0) const SizedBox(width: 6),
                Expanded(child: _offerCard(slot, scrap, hand == null)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notice ?? hint,
            style: TextStyle(
              color: notice == null ? Colors.white60 : GbColors.amber,
              fontSize: 11,
            ),
          ),
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                status!,
                style: const TextStyle(color: GbColors.cream, fontSize: 11),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: workshop.canUndo ? onUndo : null,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('UNDO'),
              ),
              if (hand != null || selected != null)
                hand != null
                    ? TextButton(
                        onPressed: onCancel,
                        child: Text('CANCEL (+${hand.cost})'),
                      )
                    : TextButton(
                        onPressed: onSell,
                        child: Text('SELL (+${workshop.selectedSellValue})'),
                      ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _offerCard(int slot, int scrap, bool handEmpty) {
    final id = workshop.offers[slot];
    if (id == null) {
      return const SizedBox(
        height: 58,
        child: Center(
          child: Text('SOLD', style: TextStyle(color: Colors.white24)),
        ),
      );
    }
    final gear = workshop.definitionFor(id);
    final affordable = gear.cost <= scrap;
    return OutlinedButton(
      key: ValueKey('offer-$slot'),
      onPressed: handEmpty && affordable ? () => onBuy(slot) : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        foregroundColor: GbColors.cream,
        side: BorderSide(color: affordable ? GbColors.amber : Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            gear.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Text(
            '${gear.category} · ${gear.cost}',
            style: const TextStyle(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
