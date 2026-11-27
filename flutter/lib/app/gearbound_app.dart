import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flame/game.dart' show GameWidget;

import '../combat/battle_session.dart';
import '../combat/combat_simulation.dart';
import '../data/shared_content.dart';
import '../game/gearbound_game.dart';
import '../mechanical/gear_network.dart';
import '../progression/campaign_progress.dart';
import '../progression/encounters.dart';
import '../progression/campaign_store.dart';
import '../progression/rewards.dart';

const _ink = Color(0xFF1B2228);
const _panel = Color(0xFF28333A);
const _cream = Color(0xFFF2E4C9);
const _amber = Color(0xFFFFA84A);

class GearboundApp extends StatelessWidget {
  const GearboundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gearbound: Wasteland Warriors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _amber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _ink,
        useMaterial3: true,
      ),
      home: const CampaignHubScreen(),
    );
  }
}

class CampaignHubScreen extends StatefulWidget {
  const CampaignHubScreen({this.store, super.key});

  /// Injected in tests; defaults to the device-backed store.
  final CampaignStore? store;

  @override
  State<CampaignHubScreen> createState() => _CampaignHubScreenState();
}

class _CampaignHubScreenState extends State<CampaignHubScreen> {
  late final CampaignStore _store = widget.store ?? CampaignStore();
  CampaignProgress? _progress;
  SharedContent? _content;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await _store.load();
    SharedContent? content;
    try {
      content = await SharedContent.load(rootBundle);
    } on Object catch (error) {
      // Fall back to the built-in encounter scripts rather than blocking play.
      debugPrint('Shared content unavailable: $error');
    }
    if (mounted) {
      setState(() {
        _progress = progress;
        _content = content;
      });
    }
  }

  Future<void> _launchLevel(int index) async {
    final progress = _progress;
    if (progress == null || !progress.isUnlocked(index)) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkshopScreen(
          levelIndex: index,
          progress: progress,
          content: _content,
          onProgressSaved: _store.save,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final nextIndex = progress.unlockedLevelIndex;
    final nextLevel = campaignLevels[nextIndex];
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              sliver: SliverToBoxAdapter(
                child: _HubHeader(scrap: progress.scrap),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(
                child: _EventCard(progress: progress, onClaim: _save),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              sliver: SliverToBoxAdapter(
                child: _RewardsCard(progress: progress, onClaim: _save),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              sliver: SliverToBoxAdapter(
                child: _ContractCard(progress: progress),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'THE WASTELAND ROUTE',
                            style: TextStyle(
                              color: _cream,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Text(
                          '${progress.bestStars.values.fold<int>(0, (sum, stars) => sum + stars)} STARS',
                          style: const TextStyle(
                            color: _amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Protect the fortress: 3★ at 75% health, 2★ at 40%, 1★ for any clear. Every clear opens the next node.',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              sliver: SliverToBoxAdapter(
                child: _RouteMap(progress: progress, onSelect: _launchLevel),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              sliver: SliverToBoxAdapter(
                child: FilledButton.icon(
                  onPressed: () => _launchLevel(nextIndex),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('CONTINUE · ${nextLevel.name.toUpperCase()}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: _amber,
                    foregroundColor: _ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final progress = _progress;
    if (progress != null) await _store.save(progress);
    if (mounted) setState(() {});
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({required this.scrap});
  final int scrap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _amber,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.settings, color: _ink),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GEARBOUND',
              style: TextStyle(
                color: _cream,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'THE LONG ROAD HOME',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
      const Icon(Icons.recycling, color: _amber, size: 18),
      const SizedBox(width: 5),
      Text(
        '$scrap',
        style: const TextStyle(color: _cream, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.progress, required this.onClaim});
  final CampaignProgress progress;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF435B50), Color(0xFF2B3D39)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF718D72)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department, color: _amber),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCRAPSTORM',
                    style: TextStyle(
                      color: _cream,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Weekly route challenge · best stars count',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '${progress.eventPoints}/10',
              style: const TextStyle(
                color: _cream,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (progress.eventPoints / 10).clamp(0, 1).toDouble(),
            minHeight: 7,
            color: _amber,
            backgroundColor: Colors.black26,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 6,
          children: [
            for (final tier in eventRewardTiers)
              _TierChip(
                tier: tier,
                claimed: progress.claimedEventTiers.contains(tier.points),
                ready: progress.eventPoints >= tier.points,
                onClaim: () {
                  if (progress.claimEventTier(tier.points)) onClaim();
                },
              ),
          ],
        ),
      ],
    ),
  );
}

class _TierChip extends StatelessWidget {
  const _TierChip({
    required this.tier,
    required this.claimed,
    required this.ready,
    required this.onClaim,
  });
  final EventRewardTier tier;
  final bool claimed;
  final bool ready;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final label = claimed
        ? 'CLAIMED'
        : ready
        ? 'CLAIM ${tier.scrap} SCRAP'
        : '${tier.points}★ · ${tier.scrap} SCRAP';
    return OutlinedButton(
      onPressed: ready && !claimed ? onClaim : null,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        foregroundColor: claimed ? Colors.white54 : _cream,
        side: BorderSide(color: ready && !claimed ? _amber : Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.progress});
  final CampaignProgress progress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.assignment_turned_in,
              color: Color(0xFF97E077),
              size: 19,
            ),
            SizedBox(width: 8),
            Text(
              'DAILY CONTRACTS',
              style: TextStyle(
                color: _cream,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final task in dailyContracts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                Text(
                  '${progress.contractValue(task.id).clamp(0, task.target)}/${task.target}',
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  progress.claimedContracts.contains(task.id)
                      ? Icons.check_circle
                      : Icons.recycling,
                  size: 15,
                  color: progress.claimedContracts.contains(task.id)
                      ? const Color(0xFF97E077)
                      : _amber,
                ),
                const SizedBox(width: 3),
                Text(
                  '+${task.scrapReward}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        const Text(
          'Scrap is awarded automatically when a contract is complete.',
          style: TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    ),
  );
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.progress, required this.onSelect});
  final CampaignProgress progress;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final chapter
            in campaignLevels.map((level) => level.chapter).toSet())
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    chapter,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              for (var index = 0; index < campaignLevels.length; index++)
                if (campaignLevels[index].chapter == chapter)
                  _RouteNode(
                    index: index,
                    level: campaignLevels[index],
                    progress: progress,
                    onTap: () => onSelect(index),
                  ),
            ],
          ),
      ],
    );
  }
}

class _RouteNode extends StatelessWidget {
  const _RouteNode({
    required this.index,
    required this.level,
    required this.progress,
    required this.onTap,
  });
  final int index;
  final CampaignLevel level;
  final CampaignProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.isUnlocked(index);
    final stars = progress.starsFor(level.id);
    return Padding(
      padding: EdgeInsets.only(
        left: index.isEven ? 4 : 48,
        right: index.isEven ? 48 : 4,
        bottom: 5,
      ),
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: unlocked
                ? const Color(0xFF34434A)
                : Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: index == progress.unlockedLevelIndex
                  ? _amber
                  : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked ? _amber : Colors.white12,
                ),
                child: Center(
                  child: unlocked
                      ? Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : const Icon(Icons.lock, size: 15, color: Colors.white38),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  level.name,
                  style: TextStyle(
                    color: unlocked ? _cream : Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (stars > 0) ...[
                for (var star = 0; star < 3; star++)
                  Icon(
                    Icons.star,
                    size: 14,
                    color: star < stars ? _amber : Colors.white12,
                  ),
              ] else if (unlocked)
                const Text(
                  'PLAY',
                  style: TextStyle(
                    color: _amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkshopScreen extends StatefulWidget {
  const WorkshopScreen({
    required this.levelIndex,
    required this.progress,
    required this.onProgressSaved,
    this.content,
    super.key,
  });
  final int levelIndex;
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
  bool _resultRecorded = false;
  bool _useVanguard = false;
  int _openingSoldiers = 0;

  @override
  void initState() {
    super.initState();
    _board = makeStarterBoard();
    _network = GearNetwork.rebuild(_board);
    _session = BattleSession(
      board: _board,
      network: _network,
      wave: encounterForLevel(widget.levelIndex, content: widget.content),
      combat: CombatSimulation(worldLengthMm: 10000),
    );
    _game = GearboundGame(_session);
    _game.onSessionChanged = () {
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

  void _rotateOutput() {
    _board.at(4, 2)?.rotateClockwise();
    _refreshNetwork();
  }

  void _movePress() {
    if (_session.phase != BattlePhase.preparation) return;
    if (_board.removeAt(4, 2)) {
      _board.place(
        GearNode(
          id: 'press-demo',
          definitionId: 'unit.rivetguard',
          kind: GearKind.output,
          x: 4,
          y: 3,
          localPorts: Direction.values.toSet(),
          baseIntervalTicks: 90,
        ),
      );
    } else {
      _board.removeAt(4, 3);
      _board.place(
        GearNode(
          id: 'press-demo',
          definitionId: 'unit.rivetguard',
          kind: GearKind.output,
          x: 4,
          y: 2,
          localPorts: Direction.values.toSet(),
          baseIntervalTicks: 90,
        ),
      );
    }
    _refreshNetwork();
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
    if (_session.phase != BattlePhase.preparation) return;
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

  Widget _buildPortrait() {
    final powered = _network.nodes.values
        .where((node) => node.state == NetworkState.powered)
        .length;
    final enemies = _session.combat.combatants
        .where((unit) => unit.isAlive && unit.faction == CombatFaction.enemy)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(scrap: widget.progress.scrap),
        const SizedBox(height: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GearboundGameWidget(game: _game),
          ),
        ),
        const SizedBox(height: 10),
        _StatusCard(
          poweredGears: powered,
          enemiesRemaining: enemies,
          phase: _session.phase,
          onRotate: _rotateOutput,
        ),
        const SizedBox(height: 8),
        _loadout(),
        const SizedBox(height: 8),
        _Actions(
          onMovePress: _movePress,
          onLaneDown: () => _moveHero(-1),
          onLaneUp: () => _moveHero(1),
          onStartWave: _startWave,
          canStartWave: _session.phase == BattlePhase.preparation,
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
      ],
    );
  }

  Widget _buildLandscape() {
    final powered = _network.nodes.values
        .where((node) => node.state == NetworkState.powered)
        .length;
    final enemies = _session.combat.combatants
        .where((unit) => unit.isAlive && unit.faction == CombatFaction.enemy)
        .length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GearboundGameWidget(game: _game),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(compact: true, scrap: widget.progress.scrap),
              const Spacer(),
              _StatusCard(
                poweredGears: powered,
                enemiesRemaining: enemies,
                phase: _session.phase,
                onRotate: _rotateOutput,
              ),
              const SizedBox(height: 8),
              _loadout(),
              const SizedBox(height: 8),
              _Actions(
                onMovePress: _movePress,
                onLaneDown: () => _moveHero(-1),
                onLaneUp: () => _moveHero(1),
                onStartWave: _startWave,
                canStartWave: _session.phase == BattlePhase.preparation,
                isCombat: _session.phase == BattlePhase.combat,
              ),
              if (_session.phase == BattlePhase.victory ||
                  _session.phase == BattlePhase.defeat)
                OutlinedButton(
                  onPressed: _returnToRoute,
                  child: const Text('BACK TO ROUTE'),
                ),
              const Spacer(),
              const Text(
                'Prototype · Workshop 01',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
          color: _amber,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.settings, color: _ink),
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
                color: _cream,
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
      const Icon(Icons.recycling, color: _amber, size: 18),
      const SizedBox(width: 4),
      Text('$scrap', style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.poweredGears,
    required this.enemiesRemaining,
    required this.phase,
    required this.onRotate,
  });
  final int poweredGears;
  final int enemiesRemaining;
  final BattlePhase phase;
  final VoidCallback onRotate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.bolt, color: Color(0xFF97E077)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$poweredGears powered · ${_phaseLabel(phase)} · $enemiesRemaining raiders',
            style: const TextStyle(color: _cream, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: phase == BattlePhase.preparation ? onRotate : null,
          tooltip: 'Rotate output gear',
          icon: const Icon(Icons.rotate_right, color: _amber),
        ),
      ],
    ),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onMovePress,
    required this.onLaneDown,
    required this.onLaneUp,
    required this.onStartWave,
    required this.canStartWave,
    required this.isCombat,
  });
  final VoidCallback onMovePress;
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
            child: OutlinedButton.icon(
              onPressed: canStartWave ? onMovePress : null,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('MOVE PRESS'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: _cream,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: canStartWave ? onStartWave : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('START WAVE'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: _amber,
                foregroundColor: _ink,
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
              icon: const Icon(Icons.keyboard_arrow_down, color: _cream),
            ),
            IconButton(
              onPressed: onLaneUp,
              tooltip: 'Move up one lane',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_up, color: _cream),
            ),
          ],
        ),
      ],
    ],
  );
}

String _phaseLabel(BattlePhase phase) => switch (phase) {
  BattlePhase.preparation => 'PREP',
  BattlePhase.combat => 'LIVE',
  BattlePhase.victory => 'CLEAR',
  BattlePhase.defeat => 'DEFEAT',
};

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.progress, required this.onClaim});
  final CampaignProgress progress;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final canLogin = progress.canClaimLogin();
    final day = progress.loginStep % loginTrackDays.length + 1;
    final nextChest = starChests
        .where((chest) => !progress.claimedStarChests.contains(chest.stars))
        .firstOrNull;
    final chestReady =
        nextChest != null && progress.canClaimStarChest(nextChest.stars);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: _amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${winStreakName.toUpperCase()} · LEVEL ${progress.winStreak}/$winStreakMaxLevel',
                  style: const TextStyle(
                    color: _cream,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              for (var i = 0; i < winStreakMaxLevel; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Icon(
                    Icons.bolt,
                    size: 16,
                    color: i < progress.winStreak ? _amber : Colors.white12,
                  ),
                ),
            ],
          ),
          const Text(
            'Each win in a row adds a free soldier at wave start. A defeat resets the streak.',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const Divider(color: Colors.white12, height: 18),
          _RewardRow(
            icon: Icons.calendar_today,
            title: '$loginTrackName · Day $day',
            detail: describeReward(progress.nextLoginReward),
            actionLabel: canLogin ? 'CLAIM' : 'TOMORROW',
            onAction: canLogin
                ? () {
                    if (progress.claimLogin()) onClaim();
                  }
                : null,
          ),
          const SizedBox(height: 6),
          _RewardRow(
            icon: Icons.inventory_2,
            title: nextChest == null
                ? 'All star chests opened'
                : 'Star chest · ${progress.totalStars}/${nextChest.stars}★',
            detail: nextChest == null ? '' : describeReward(nextChest.reward),
            actionLabel: chestReady ? 'OPEN' : 'LOCKED',
            onAction: chestReady
                ? () {
                    if (progress.claimStarChest(nextChest.stars)) onClaim();
                  }
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            'Boosters: ${progress.boosterCount(vanguardBoosterId)}× Vanguard Drop · earned only, never sold',
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _cream, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _cream,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (detail.isNotEmpty)
              Text(
                detail,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
          ],
        ),
      ),
      OutlinedButton(
        onPressed: onAction,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(72, 36),
          foregroundColor: _cream,
          side: BorderSide(color: onAction != null ? _amber : Colors.white24),
        ),
        child: Text(
          actionLabel,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}

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
      color: _panel,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.speed, color: _amber, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isPreparation
                ? 'Streak $streakLevel: +$streakLevel soldier${streakLevel == 1 ? '' : 's'} at start'
                : '$deployedSoldiers opening soldier${deployedSoldiers == 1 ? '' : 's'} deployed',
            style: const TextStyle(color: _cream, fontSize: 11),
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
            activeThumbColor: _amber,
          ),
        ],
      ],
    ),
  );
}
