import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';

/// Gamification hub: where you rank, and every badge on the shelf.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;

    final List<LeaderboardEntry> board = app.catalog.leaderboard;
    final List<BadgeDefinition> badges = app.catalog.badges;
    final Map<String, int> metrics = activity.badgeMetricValues(badges);
    final Set<String> unlocked = activity.satisfiedBadges(badges);

    // Merge the local user into the ranking so the board feels personal.
    final int myMinutes = activity.totalFocusMinutes;
    final List<LeaderboardEntry> merged = <LeaderboardEntry>[
      ...board,
      LeaderboardEntry(
        rank: 0,
        name: '${app.profile.name} (you)',
        handle: '@${app.profile.firstName.toLowerCase()}',
        focusMinutes: myMinutes,
        streak: activity.streak,
        badge: app.catalog.levelFor(myMinutes).title,
      ),
    ]..sort((LeaderboardEntry a, LeaderboardEntry b) => b.focusMinutes.compareTo(a.focusMinutes));

    final int myRank = merged.indexWhere((LeaderboardEntry e) => e.rank == 0) + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Progress Board',
          subtitle: 'Study longer, climb higher',
          icon: Icons.emoji_events_rounded,
          accent: t.accentAmber,
          trailing: NeonChip(
            label: 'Rank #$myRank',
            dense: true,
            color: t.accentAmber,
          ),
        ),
        GlassCard(
          radius: 26,
          glowColor: t.accentAmber,
          glowStrength: 0.26,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              const HamsterMascot(size: 76, pose: MascotPose.celebrate, showShell: false),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${AppDateUtils.durationLabel(myMinutes)} focused',
                      style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Streak ${activity.streak} · ${unlocked.length}/${badges.length} badges · '
                      'level ${app.catalog.levelFor(myMinutes).title}',
                      style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    NeonProgressBar(
                      progress: app.levelProgress,
                      colors: <Color>[t.accentAmber, t.accentMagenta],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Top learners',
          subtitle: 'Focus minutes this month',
          icon: Icons.leaderboard_rounded,
        ),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < merged.length; i++) ...<Widget>[
                _BoardRow(entry: merged[i], index: i + 1, isMe: merged[i].rank == 0),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Badge shelf',
          subtitle: '${unlocked.length} unlocked · ${badges.length - unlocked.length} to go',
          icon: Icons.military_tech_rounded,
          accent: t.accentMagenta,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (BuildContext context, int index) {
            final BadgeDefinition badge = badges[index];
            final int value = metrics[badge.metric] ?? 0;
            return _BadgeTile(
              badge: badge,
              value: value,
              unlocked: unlocked.contains(badge.id),
            );
          },
        ),
      ],
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.entry, required this.index, required this.isMe});

  final LeaderboardEntry entry;
  final int index;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color medal = index == 1
        ? t.accentAmber
        : index == 2
            ? t.accentCyan
            : index == 3
                ? t.accentMagenta
                : t.textMuted;

    return Container(
      color: isMe ? t.primary.withValues(alpha: 0.18) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 26,
            child: Text(
              '$index',
              style: TextStyle(color: medal, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: medal.withValues(alpha: 0.24),
              shape: BoxShape.circle,
              border: Border.all(color: medal.withValues(alpha: 0.7)),
            ),
            child: Center(
              child: Text(
                entry.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: medal, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13,
                    fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.handle} · ${entry.badge}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                AppDateUtils.durationLabel(entry.focusMinutes),
                style: TextStyle(color: t.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '🔥 ${entry.streak.toString().padLeft(2, '0')}d',
                style: TextStyle(color: t.textMuted, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.value, required this.unlocked});

  final BadgeDefinition badge;
  final int value;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color tier = switch (badge.tier) {
      'platinum' => t.accentCyan,
      'gold' => t.accentAmber,
      'silver' => t.textMuted,
      _ => t.accentMagenta,
    };
    final double progress = AppDateUtils.ratio(value, badge.threshold);

    return GlassCard(
      radius: 22,
      glowColor: unlocked ? tier : t.accentGrey,
      glowStrength: unlocked ? 0.3 : 0.05,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (unlocked ? tier : t.accentGrey).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  iconFor(badge.icon),
                  size: 17,
                  color: unlocked ? tier : t.textMuted,
                ),
              ),
              const Spacer(),
              if (unlocked)
                Icon(Icons.verified_rounded, size: 17, color: tier)
              else
                Icon(Icons.lock_outline_rounded, size: 15, color: t.textMuted),
            ],
          ),
          const Spacer(),
          Text(
            badge.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? t.textPrimary : t.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: t.textMuted, fontSize: 10, height: 1.3),
          ),
          const SizedBox(height: 8),
          NeonProgressBar(
            progress: progress,
            height: 5,
            colors: unlocked ? <Color>[tier, tier] : <Color>[t.accentGrey, t.accentGrey],
          ),
          const SizedBox(height: 5),
          Text(
            '$value / ${badge.threshold}',
            style: TextStyle(color: t.textMuted, fontSize: 9.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
