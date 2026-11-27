import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../data/shared_content.dart';
import '../../progression/campaign_progress.dart';
import '../../progression/campaign_store.dart';
import '../../progression/rewards.dart';
import '../../design_system/tokens.dart';
import '../workshop/workshop_screen.dart';

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
                              color: GbColors.cream,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Text(
                          '${progress.bestStars.values.fold<int>(0, (sum, stars) => sum + stars)} STARS',
                          style: const TextStyle(
                            color: GbColors.amber,
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
                    backgroundColor: GbColors.amber,
                    foregroundColor: GbColors.ink,
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
          color: GbColors.amber,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.settings, color: GbColors.ink),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GEARBOUND',
              style: TextStyle(
                color: GbColors.cream,
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
      const Icon(Icons.recycling, color: GbColors.amber, size: 18),
      const SizedBox(width: 5),
      Text(
        '$scrap',
        style: const TextStyle(
          color: GbColors.cream,
          fontWeight: FontWeight.bold,
        ),
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
            const Icon(Icons.local_fire_department, color: GbColors.amber),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCRAPSTORM',
                    style: TextStyle(
                      color: GbColors.cream,
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
                color: GbColors.cream,
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
            color: GbColors.amber,
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
        foregroundColor: claimed ? Colors.white54 : GbColors.cream,
        side: BorderSide(
          color: ready && !claimed ? GbColors.amber : Colors.white24,
        ),
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
      color: GbColors.panel,
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
                color: GbColors.cream,
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
                    color: GbColors.cream,
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
                      : GbColors.amber,
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
                  ? GbColors.amber
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
                  color: unlocked ? GbColors.amber : Colors.white12,
                ),
                child: Center(
                  child: unlocked
                      ? Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: GbColors.ink,
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
                    color: unlocked ? GbColors.cream : Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (stars > 0) ...[
                for (var star = 0; star < 3; star++)
                  Icon(
                    Icons.star,
                    size: 14,
                    color: star < stars ? GbColors.amber : Colors.white12,
                  ),
              ] else if (unlocked)
                const Text(
                  'PLAY',
                  style: TextStyle(
                    color: GbColors.amber,
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
        color: GbColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: GbColors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${winStreakName.toUpperCase()} · LEVEL ${progress.winStreak}/$winStreakMaxLevel',
                  style: const TextStyle(
                    color: GbColors.cream,
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
                    color: i < progress.winStreak
                        ? GbColors.amber
                        : Colors.white12,
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
      Icon(icon, color: GbColors.cream, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: GbColors.cream,
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
          foregroundColor: GbColors.cream,
          side: BorderSide(
            color: onAction != null ? GbColors.amber : Colors.white24,
          ),
        ),
        child: Text(
          actionLabel,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}
