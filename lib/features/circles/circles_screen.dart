import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../data/models/taunt.dart';
import '../../state/app_state.dart';
import '../../state/ekagra_controller.dart';

/// Mehfil & Study Circle — community co-working.
///
/// Rooms are community constructs, so joining one starts a real local session
/// (with the room name as the subject) and pings the hamster for a matching
/// taunt. That keeps the feature honest: no fake presence, real focus.
class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final EkagraController ekagra = context.watch<EkagraController>();
    final AppTokens t = context.tokens;

    final List<StudyCircle> circles = app.catalog.circles;
    final List<StudyCircle> mehfil =
        circles.where((StudyCircle c) => c.name.contains('Mehfil')).toList(growable: false);
    final List<StudyCircle> studyCircles =
        circles.where((StudyCircle c) => !c.name.contains('Mehfil')).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Mehfil & Study Circle',
          subtitle: 'Study together, judge each other kindly',
          icon: Icons.groups_rounded,
          accent: t.accentCyan,
        ),
        _JoinCard(
          liveCount: circles.where((StudyCircle c) => c.isLive).length,
          onJoinMehfil: () async {
            ekagra.setSubject('Mehfil co-working');
            await ekagra.start(armShield: true);
            if (!context.mounted) return;
            EmojiBurst.fireFrom(context, emojis: EmojiBurst.focusEmojis, count: 10);
            AppRouter.go(context, AppRouter.ekagra);
          },
        ),
        const SizedBox(height: 18),
        if (mehfil.isNotEmpty) ...<Widget>[
          SectionHeader(
            title: 'Mehfil',
            subtitle: 'Open rooms · silent co-working',
            icon: Icons.nightlife_rounded,
          ),
          for (final StudyCircle circle in mehfil)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CircleCard(
                circle: circle,
                actionLabel: 'Join room',
                onAction: () async {
                  ekagra.setSubject(circle.name);
                  await ekagra.start(armShield: true);
                  if (!context.mounted) return;
                  AppRouter.go(context, AppRouter.ekagra);
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (studyCircles.isNotEmpty) ...<Widget>[
          SectionHeader(
            title: 'Study Circles',
            subtitle: 'Small accountability groups',
            icon: Icons.diversity_3_rounded,
          ),
          for (final StudyCircle circle in studyCircles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CircleCard(
                circle: circle,
                actionLabel: 'Join circle',
                onAction: () async {
                  final Taunt? taunt = app.taunts.next(
                    triggers: <TauntTrigger>[TauntTrigger.examSoon, TauntTrigger.idle],
                    maxSeverity: app.settings.severityCap,
                  );
                  if (taunt != null) app.setActiveTaunt(taunt);
                },
              ),
            ),
        ],
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              const HamsterMascot(size: 58, pose: MascotPose.thinking, showShell: false),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rooms are community-run. TauntBuddy keeps your presence local — joining '
                  'simply starts a shared-time focus session for you.',
                  style: TextStyle(color: t.textMuted, fontSize: 11, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.liveCount, required this.onJoinMehfil});

  final int liveCount;
  final VoidCallback onJoinMehfil;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 26,
      glowStrength: 0.28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.podcasts_rounded, color: t.accentCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$liveCount room${liveCount == 1 ? '' : 's'} live right now',
                  style: TextStyle(color: t.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Drop into a silent room, start your own block, and let the group '
            'carry your focus. No cameras, no pressure.',
            style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 14),
          GlowButton(
            label: 'Start a co-working block',
            icon: Icons.play_circle_fill_rounded,
            expand: false,
            compact: true,
            onPressed: onJoinMehfil,
          ),
        ],
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle, required this.actionLabel, required this.onAction});

  final StudyCircle circle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color accent = t.accent(accentFromKey(circle.accent));

    return GlassCard(
      radius: 24,
      glowColor: accent,
      glowStrength: 0.18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  circle.name,
                  style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              NeonChip(
                label: circle.activity,
                dense: true,
                color: circle.isLive ? t.accentMint : t.accentAmber,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            circle.description,
            style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(Icons.people_alt_rounded, size: 14, color: t.textMuted),
              const SizedBox(width: 6),
              Text('${circle.members} members', style: TextStyle(color: t.textMuted, fontSize: 11)),
              const SizedBox(width: 14),
              Icon(Icons.topic_rounded, size: 14, color: t.textMuted),
              const SizedBox(width: 6),
              Text(circle.subject, style: TextStyle(color: t.textMuted, fontSize: 11)),
              const Spacer(),
              GhostButton(label: actionLabel, icon: Icons.login_rounded, onPressed: onAction),
            ],
          ),
        ],
      ),
    );
  }
}
