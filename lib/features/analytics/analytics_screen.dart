import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/focus_session.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/models/catalog.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';

/// Analytics: consistency, completion rate, focus depth trends and the session
/// log. All maths comes from [ActivityRepository] so the dashboard cards and
/// this screen can never disagree.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _window = 14;

  @override
  Widget build(BuildContext context) {
    final ActivityController activity = context.watch<ActivityController>();
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;

    final AnalyticsSnapshot snapshot = activity.snapshot(windowDays: _window);
    final Map<DayKey, int> perDay = activity.focusByDay(windowDays: _window);
    final List<int> sparkline = activity.moodTrend(windowDays: _window).map((double v) => v.round()).toList(growable: false);
    final List<FocusSession> recent = activity.recentSessions;
    final LevelDefinition level = app.catalog.levelFor(activity.totalFocusMinutes);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Analytics',
          subtitle: 'Proof that the grind is happening',
          icon: Icons.insights_rounded,
          accent: t.accentCyan,
        ),
        SegmentedNeonPicker(
          options: const <String>['7 days', '14 days', '30 days'],
          selectedIndex: _window == 7 ? 0 : _window == 14 ? 1 : 2,
          onSelected: (int index) => setState(() => _window = <int>[7, 14, 30][index]),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            MetricRing(
              progress: snapshot.consistency,
              value: '${(snapshot.consistency * 100).round()}%',
              label: 'CONSISTENCY',
              size: 104,
              stroke: 9,
              colors: <Color>[t.accentCyan, t.accentMint],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: <Widget>[
                  StatTile(
                    label: 'Completion rate',
                    value: '${(snapshot.completionRate * 100).round()}%',
                    caption: '${snapshot.completedSessions}/${snapshot.sessions} sessions finished',
                    accent: t.accentMint,
                  ),
                  const SizedBox(height: 10),
                  StatTile(
                    label: 'Avg focus depth / day',
                    value: '${snapshot.avgDepthPerDay}m',
                    caption: 'Quality weighted minutes',
                    accent: t.accentViolet,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'Focus minutes',
                    style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${AppDateUtils.durationLabel(snapshot.focusMinutes)} total',
                    style: TextStyle(color: t.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MiniBarChart(
                values: perDay.values.map((int v) => v.toDouble()).toList(growable: false),
                labels: perDay.keys.map((DayKey d) => d.weekdayShort).toList(growable: false),
                valueFormatter: (double value) => '${value.round()}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Mood curve',
                style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                sparkline.every((int v) => v == 0)
                    ? 'No check-ins yet — log your mood on the dashboard.'
                    : 'Average ${snapshot.moodAverage}/5 over $_window days',
                style: TextStyle(color: t.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 14),
              MiniBarChart(
                values: sparkline.map((int v) => v.toDouble()).toList(growable: false),
                labels: perDay.keys.map((DayKey d) => d.weekdayShort).toList(growable: false),
                height: 96,
                colors: <Color>[t.accentMint, t.accentCyan],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'Streak now',
                value: '${snapshot.currentStreak}d',
                caption: 'Best ${snapshot.longestStreak}d',
                icon: Icons.local_fire_department_rounded,
                accent: t.accentAmber,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Level',
                value: level.title,
                caption: '${AppDateUtils.durationLabel(activity.totalFocusMinutes)} lifetime',
                icon: Icons.military_tech_rounded,
                accent: t.accentMagenta,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Session log',
          subtitle: 'Most recent ${recent.length}',
          icon: Icons.history_rounded,
        ),
        if (recent.isEmpty)
          const GlassCard(
            radius: 24,
            child: EmptyState(
              title: 'No sessions yet',
              message: 'Finish one Ekagra block and this screen starts talking.',
              icon: Icons.insights_rounded,
            ),
          )
        else
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < recent.length; i++) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: <Widget>[
                        Text(recent[i].kind.emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                recent[i].subject.isEmpty ? recent[i].kind.label : recent[i].subject,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${recent[i].day.short} · ${AppDateUtils.clock(recent[i].startedAt)} · '
                                '${recent[i].actualMinutes}m planned ${recent[i].plannedMinutes}m',
                                style: TextStyle(color: t.textMuted, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              'depth ${recent[i].depthScore}',
                              style: TextStyle(color: t.accentViolet, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recent[i].completed ? 'completed' : 'stopped',
                              style: TextStyle(
                                color: recent[i].completed ? t.accentMint : t.accentAmber,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (i != recent.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: NeonDivider(opacity: 0.1),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
