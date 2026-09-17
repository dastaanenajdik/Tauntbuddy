import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../data/models/tracking.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';

/// Home: the personalised entry point.
///
/// * greeting + level header
/// * quick-access cards for the core features (heavily rounded, subtle border)
/// * the full feature list so nothing is hidden behind the drawer
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;

    final String headline = AppDateUtils.homeHeadline(
      now: DateTime.now(),
      name: app.profile.firstName,
    );
    final int depth = activity.repository.depthOn(DayKey.today());
    final int streak = activity.streak;
    final DaySummary today = activity.todaySummary();
    final int unlocked = app.catalog.badges
        .where((BadgeDefinition b) => activity.satisfiedBadges(app.catalog.badges).contains(b.id))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        Text(
          headline,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 6),
        Text(
          app.profile.examTarget.trim().isEmpty
              ? 'One focus block at a time. The hamster is watching.'
              : '${app.profile.examTarget.trim()} mode on. The hamster is watching.',
          style: TextStyle(color: t.textMuted, fontSize: 13.5, height: 1.5),
        ),
        const SizedBox(height: 18),
        _HeroCard(
          levelTitle: app.catalog.levelFor(activity.totalFocusMinutes).title,
          levelProgress: app.levelProgress,
          totalMinutes: activity.totalFocusMinutes,
          nextLevel: app.catalog.nextLevelFor(activity.totalFocusMinutes),
          onTap: () {
            EmojiBurst.fireFrom(context, emojis: EmojiBurst.focusEmojis, count: 10);
            AppRouter.go(context, AppRouter.ekagra);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'Focus score',
                value: '${depth}m',
                caption: 'Focused today',
                icon: Icons.bolt_rounded,
                accent: t.accentViolet,
                onTap: () => AppRouter.go(context, AppRouter.analytics),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Streak',
                value: '$streak ${streak == 1 ? 'day' : 'days'}',
                caption: 'Longest ${activity.longestStreak}',
                icon: Icons.local_fire_department_rounded,
                accent: t.accentAmber,
                onTap: () => AppRouter.go(context, AppRouter.leaderboard),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: "Today's goals",
                value: '${today.goalsDone}/${today.goalsTotal}',
                caption: 'Tap to tick them off',
                icon: Icons.checklist_rounded,
                accent: t.accentMint,
                onTap: () => AppRouter.go(context, AppRouter.goals),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Badges',
                value: '$unlocked/${app.catalog.badges.length}',
                caption: 'Unlocked',
                icon: Icons.emoji_events_rounded,
                accent: t.accentMagenta,
                onTap: () => AppRouter.go(context, AppRouter.leaderboard),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Quick access',
          subtitle: 'Your focus universe in one tap',
          icon: Icons.grid_view_rounded,
          trailing: GhostButton(
            label: 'Search',
            icon: Icons.search_rounded,
            onPressed: () => AppRouter.go(context, AppRouter.search),
          ),
        ),
        _FeatureGrid(features: app.catalog.features, isPro: app.isPro),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'All core features',
          subtitle: 'Everything TauntBuddy can do',
          icon: Icons.list_alt_rounded,
        ),
        _FeatureList(features: app.catalog.features, isPro: app.isPro),
        const SizedBox(height: 24),
        _MascotInvite(
          onTap: () {
            final taunt = app.pickSituationalTaunt();
            if (taunt != null) app.setActiveTaunt(taunt);
            EmojiBurst.fireFrom(context, count: 12);
          },
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.levelTitle,
    required this.levelProgress,
    required this.totalMinutes,
    required this.nextLevel,
    required this.onTap,
  });

  final String levelTitle;
  final double levelProgress;
  final int totalMinutes;
  final LevelDefinition? nextLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 28,
      glowStrength: 0.32,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        children: <Widget>[
          MetricRing(
            progress: levelProgress,
            value: '${(levelProgress * 100).round()}%',
            label: 'LEVEL',
            size: 88,
            stroke: 8,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  levelTitle,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppDateUtils.durationLabel(totalMinutes)} of lifetime focus',
                  style: TextStyle(color: t.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  nextLevel == null
                      ? 'Maximum level reached. The hamster bows. 🐹'
                      : '${nextLevel!.minFocusMinutes - totalMinutes} more minutes to '
                          '${nextLevel!.title}',
                  style: TextStyle(color: t.accentCyan, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features, required this.isPro});

  final List<FeatureCard> features;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) {
      return const SizedBox.shrink();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.02,
      ),
      itemBuilder: (BuildContext context, int index) {
        final FeatureCard feature = features[index];
        return _FeatureCardTile(feature: feature, locked: feature.pro && !isPro);
      },
    );
  }
}

class _FeatureCardTile extends StatelessWidget {
  const _FeatureCardTile({required this.feature, required this.locked});

  final FeatureCard feature;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color accent = t.accent(accentFromKey(feature.accent));

    return GlassCard(
      radius: 24,
      glowColor: accent,
      glowStrength: 0.22,
      padding: const EdgeInsets.all(15),
      onTap: () {
        EmojiBurst.fire(context, _centerOf(context), emojis: EmojiBurst.focusEmojis, count: 7);
        AppRouter.go(context, feature.route);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.62)),
                ),
                child: Icon(iconFor(feature.icon), size: 18, color: accent),
              ),
              const Spacer(),
              if (feature.pro) ProBadge(locked: locked),
            ],
          ),
          const Spacer(),
          Text(
            feature.title,
            style: TextStyle(color: t.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            feature.tagline,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: t.textMuted, fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }

  Offset _centerOf(BuildContext context) {
    final RenderObject? box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(box.size.center(Offset.zero));
    }
    return const Offset(180, 300);
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.features, required this.isPro});

  final List<FeatureCard> features;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < features.length; i++) ...<Widget>[
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => AppRouter.go(context, features[i].route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: t.accent(accentFromKey(features[i].accent)).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          iconFor(features[i].icon),
                          size: 16,
                          color: t.accent(accentFromKey(features[i].accent)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  features[i].title,
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (features[i].pro) ...<Widget>[
                                  const SizedBox(width: 8),
                                  ProBadge(locked: !isPro),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              features[i].tagline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: t.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: t.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MascotInvite extends StatelessWidget {
  const _MascotInvite({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 28,
      glowStrength: 0.3,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          const HamsterMascot(size: 86, pose: MascotPose.judging),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Ask the hamster for a verdict',
                  style: TextStyle(color: t.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  'It reads your streak, goals and exam countdown, then says exactly what you need to hear.',
                  style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                NeonChip(label: 'Tap for a taunt', icon: Icons.campaign_rounded, color: t.accentMagenta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
