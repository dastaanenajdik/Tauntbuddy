import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../data/models/quote.dart';
import '../../data/models/tracking.dart';
import '../../data/repositories/activity_repository.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';
import '../../state/ekagra_controller.dart';
import '../../state/shell_controller.dart';

/// Dashboard: quote of the day, mood check-in, goals, streak, badges and the
/// monthly analytics snapshot — the "Nishtha/Ekagra dashboard" surface.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ActivityController activity = context.watch<ActivityController>();
    final EkagraController ekagra = context.watch<EkagraController>();
    final AppTokens t = context.tokens;

    final AnalyticsSnapshot snapshot = activity.snapshot(windowDays: 30);
    final DaySummary today = activity.todaySummary();
    final Quote quote = app.catalog.quoteOfTheDay;
    final Set<String> unlocked = activity.satisfiedBadges(app.catalog.badges);
    final List<BadgeDefinition> unlockedBadges =
        app.catalog.badges.where((BadgeDefinition b) => unlocked.contains(b.id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        _SearchBar(onSubmit: (String value) {
          context.read<ShellController>().setSearchQuery(value);
          AppRouter.go(context, AppRouter.search);
        }),
        const SizedBox(height: 16),
        _QuoteCard(quote: quote, remote: app.catalog.quotes.fromRemote),
        const SizedBox(height: 16),
        _MoodCheckIn(
          selected: activity.moodOn(DayKey.today()),
          moods: app.catalog.moods.isEmpty ? MoodOption.fallback : app.catalog.moods,
          onPick: (MoodOption mood) async {
            await activity.setMood(mood);
            if (!context.mounted) return;
            EmojiBurst.fireFrom(context, emojis: <String>[mood.emoji, '✨', '💜'], count: 8);
          },
        ),
        const SizedBox(height: 16),
        _GoalsTracker(
          done: today.goalsDone,
          total: today.goalsTotal,
          onOpen: () => AppRouter.go(context, AppRouter.goals),
        ),
        const SizedBox(height: 16),
        _StreakAndBadges(
          streak: activity.streak,
          longest: activity.longestStreak,
          unlocked: unlockedBadges,
          totalBadges: app.catalog.badges.length,
          onOpen: () => AppRouter.go(context, AppRouter.leaderboard),
        ),
        const SizedBox(height: 16),
        _MonthlySnapshot(snapshot: snapshot),
        const SizedBox(height: 16),
        _NextExamCard(activity: activity),
        const SizedBox(height: 16),
        _StartSessionCard(
          ekagra: ekagra,
          onStart: () {
            EmojiBurst.fireFrom(context, emojis: EmojiBurst.focusEmojis, count: 10);
            AppRouter.go(context, AppRouter.ekagra);
          },
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Palette ${app.catalog.levels.isEmpty ? 'Neon Glass v1' : 'Neon Glass v1'} · '
            '${t.isDark ? 'Dark mode' : 'Light mode'}',
            style: TextStyle(color: t.textMuted, fontSize: 10.5),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassField(
      controller: _controller,
      label: 'Search / Dashboard',
      hint: 'Kavach, courses, taunts, goals...',
      onSubmitted: widget.onSubmit,
      suffix: IconButton(
        icon: Icon(Icons.arrow_forward_rounded, size: 18, color: t.primary),
        onPressed: () => widget.onSubmit(_controller.text),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote, required this.remote});

  final Quote quote;
  final bool remote;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 26,
      glowColor: t.accentCyan,
      glowStrength: 0.24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.format_quote_rounded, size: 20, color: t.accentCyan),
              const SizedBox(width: 8),
              Text(
                'DAILY INSPIRATION',
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              NeonChip(
                label: remote ? 'Synced' : 'Bundled',
                dense: true,
                color: remote ? t.accentMint : t.accentGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quote.text,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 15.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text('— ${quote.author}', style: TextStyle(color: t.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MoodCheckIn extends StatelessWidget {
  const _MoodCheckIn({required this.selected, required this.moods, required this.onPick});

  final MoodEntry? selected;
  final List<MoodOption> moods;
  final ValueChanged<MoodOption> onPick;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                "Today's mood",
                style: TextStyle(color: t.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                selected == null ? 'Not checked in' : 'Logged ✓',
                style: TextStyle(
                  color: selected == null ? t.textMuted : t.accentMint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final MoodOption mood in moods)
                NeonChip(
                  label: mood.label,
                  emoji: mood.emoji,
                  dense: false,
                  color: selected?.moodId == mood.id ? t.accentMint : t.primary,
                  onTap: () => onPick(mood),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalsTracker extends StatelessWidget {
  const _GoalsTracker({required this.done, required this.total, required this.onOpen});

  final int done;
  final int total;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final double progress = AppDateUtils.ratio(done, total);
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      onTap: onOpen,
      child: Row(
        children: <Widget>[
          MetricRing(
            progress: progress,
            value: '$done/$total',
            label: 'DONE',
            size: 74,
            stroke: 7,
            colors: <Color>[t.accentMint, t.accentCyan],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Today's goals",
                  style: TextStyle(color: t.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  total == 0
                      ? 'No goals yet — add one and the hamster will hold you to it.'
                      : done == total
                          ? 'All goals closed. The hamster is impressed (rare).'
                          : '${total - done} left. Finish them before midnight.',
                  style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                NeonProgressBar(
                  progress: progress,
                  colors: <Color>[t.accentMint, t.accentCyan],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakAndBadges extends StatelessWidget {
  const _StreakAndBadges({
    required this.streak,
    required this.longest,
    required this.unlocked,
    required this.totalBadges,
    required this.onOpen,
  });

  final int streak;
  final int longest;
  final List<BadgeDefinition> unlocked;
  final int totalBadges;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      glowColor: t.accentAmber,
      glowStrength: 0.2,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.local_fire_department_rounded, color: t.accentAmber),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Active streak · $streak ${streak == 1 ? 'day' : 'days'}',
                      style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Personal best $longest days',
                      style: TextStyle(color: t.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                child: NeonProgressBar(
                  progress: longest == 0 ? 0 : streak / longest,
                  colors: <Color>[t.accentAmber, t.accentMagenta],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Text(
                'UNLOCKED BADGES (${unlocked.length}/$totalBadges)',
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (unlocked.isEmpty)
            Text(
              'Nothing yet. One 25 minute Ekagra block unlocks your first badge.',
              style: TextStyle(color: t.textMuted, fontSize: 11.5),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final BadgeDefinition badge in unlocked.take(6))
                  NeonChip(
                    label: badge.title,
                    icon: iconFor(badge.icon),
                    color: t.accentAmber,
                    dense: true,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MonthlySnapshot extends StatelessWidget {
  const _MonthlySnapshot({required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: 'Monthly snapshot',
            subtitle: 'Last 30 days',
            icon: Icons.insights_rounded,
            accent: t.accentCyan,
            trailing: GhostButton(
              label: 'Details',
              onPressed: () => AppRouter.go(context, AppRouter.analytics),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: 'Consistency',
                  value: '${(snapshot.consistency * 100).round()}%',
                  caption: '${snapshot.activeDays} active days',
                  accent: t.accentCyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Completion',
                  value: '${(snapshot.completionRate * 100).round()}%',
                  caption: '${snapshot.completedSessions}/${snapshot.sessions} sessions',
                  accent: t.accentMint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: 'Avg depth / day',
                  value: '${snapshot.avgDepthPerDay}m',
                  caption: 'Quality weighted',
                  accent: t.accentViolet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Focus banked',
                  value: AppDateUtils.durationLabel(snapshot.focusMinutes),
                  caption: 'Best day ${AppDateUtils.durationLabel(snapshot.bestDayMinutes)}',
                  accent: t.accentMagenta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextExamCard extends StatelessWidget {
  const _NextExamCard({required this.activity});

  final ActivityController activity;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final subject = activity.nextExam;

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      glowColor: t.accentMagenta,
      glowStrength: subject == null ? 0.1 : 0.26,
      onTap: () => AppRouter.go(context, AppRouter.planner),
      child: Row(
        children: <Widget>[
          Icon(Icons.event_note_rounded, color: t.accentMagenta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  subject == null ? 'Exam Planner' : 'Next exam · ${subject.name}',
                  style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subject == null
                      ? 'Add your subjects and exam dates for countdowns + smart alerts.'
                      : '${subject.daysToExam} days left · ${subject.unitsPerDayToFinish} unit(s) per day to finish.',
                  style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
          if (subject != null)
            Text(
              '${subject.daysToExam}',
              style: TextStyle(color: t.accentMagenta, fontSize: 22, fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}

class _StartSessionCard extends StatelessWidget {
  const _StartSessionCard({required this.ekagra, required this.onStart});

  final EkagraController ekagra;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 26,
      glowStrength: 0.3,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          const HamsterMascot(size: 74, pose: MascotPose.focus, showShell: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ekagra.isRunning ? 'Session running · ${ekagra.clock}' : 'Start an Ekagra block',
                  style: TextStyle(color: t.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  ekagra.isRunning
                      ? 'Stay in the app. KAVACH is watching.'
                      : '${ekagra.focusMinutes} minute Pomodoro · KAVACH optional',
                  style: TextStyle(color: t.textMuted, fontSize: 11.5),
                ),
                const SizedBox(height: 10),
                GlowButton(
                  label: ekagra.isRunning ? 'Open timer' : 'Focus now',
                  icon: Icons.play_arrow_rounded,
                  compact: true,
                  expand: false,
                  onPressed: onStart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
