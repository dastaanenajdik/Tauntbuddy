import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/tracking.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';
import '../../state/ekagra_controller.dart';

/// Dhyan — mindfulness timers and mood-aware resets.
class DhyanScreen extends StatelessWidget {
  const DhyanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final EkagraController ekagra = context.watch<EkagraController>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;

    final List<DhyanTechnique> techniques = app.catalog.dhyanTechniques;
    final MoodEntry? mood = activity.moodOn(DayKey.today());
    final List<FocusSession> dhyanSessions = activity.sessions
        .where((FocusSession s) => s.kind == SessionKind.dhyan)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Dhyan',
          subtitle: 'Reset the mind between deep blocks',
          icon: Icons.self_improvement_rounded,
          accent: t.accentMint,
        ),
        GlassCard(
          radius: 28,
          glowColor: t.accentMint,
          glowStrength: 0.3,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              MetricRing(
                progress: ekagra.kind == SessionKind.dhyan ? ekagra.progress : 0,
                value: ekagra.kind == SessionKind.dhyan ? ekagra.clock : '10:00',
                label: 'DHYAN',
                size: 160,
                stroke: 11,
                colors: <Color>[t.accentMint, t.accentCyan],
              ),
              const SizedBox(height: 12),
              const HamsterMascot(size: 84, pose: MascotPose.sleepy, showShell: false),
              const SizedBox(height: 10),
              Text(
                mood == null
                    ? 'How is your head today? Check in on the dashboard and Dhyan will adapt.'
                    : 'You checked in as "${mood.moodId}". '
                        '${mood.score <= 2 ? 'Start with the 4-7-8 breath — two minutes is enough.' : 'A 10 minute body scan will sharpen the next block.'}',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.45),
              ),
              const SizedBox(height: 16),
              GlowButton(
                label: ekagra.isRunning && ekagra.kind == SessionKind.dhyan
                    ? 'Pause Dhyan'
                    : 'Start 10 minute Dhyan',
                icon: Icons.spa_rounded,
                gradient: <Color>[t.accentMint, t.accentCyan],
                onPressed: () async {
                  if (ekagra.kind != SessionKind.dhyan) {
                    ekagra.setKind(SessionKind.dhyan);
                    ekagra.setDurations(focus: 10);
                  }
                  if (ekagra.isRunning) {
                    ekagra.pause();
                  } else if (ekagra.isPaused) {
                    ekagra.resume();
                  } else {
                    await ekagra.start(armShield: false);
                  }
                },
              ),
              const SizedBox(height: 10),
              GhostButton(
                label: 'Open the full timer',
                icon: Icons.open_in_new_rounded,
                expand: true,
                compact: false,
                onPressed: () => AppRouter.go(context, AppRouter.ekagra),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'Dhyan this month',
                value: AppDateUtils.durationLabel(
                  dhyanSessions
                      .where((FocusSession s) => s.day.daysUntil(DayKey.today()) >= -30)
                      .fold(0, (int sum, FocusSession s) => sum + s.actualMinutes),
                ),
                caption: '${dhyanSessions.length} sessions all time',
                icon: Icons.spa_rounded,
                accent: t.accentMint,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Mood average',
                value: '${activity.snapshot(windowDays: 14).moodAverage}/5',
                caption: 'Last 14 days',
                icon: Icons.mood_rounded,
                accent: t.accentCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Techniques',
          subtitle: '${techniques.length} guided resets',
          icon: Icons.air_rounded,
        ),
        for (final DhyanTechnique technique in techniques)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              radius: 22,
              glowColor: t.accent(accentFromKey(technique.accent)),
              glowStrength: 0.16,
              padding: const EdgeInsets.all(16),
              onTap: () {
                ekagra.setKind(SessionKind.dhyan);
                ekagra.setDurations(focus: technique.minutes);
                ekagra.start(armShield: false);
              },
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.accent(accentFromKey(technique.accent)).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.self_improvement_rounded,
                      size: 17,
                      color: t.accent(accentFromKey(technique.accent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          technique.title,
                          style: TextStyle(color: t.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          technique.description,
                          style: TextStyle(color: t.textMuted, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  NeonChip(label: '${technique.minutes}m', dense: true),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
