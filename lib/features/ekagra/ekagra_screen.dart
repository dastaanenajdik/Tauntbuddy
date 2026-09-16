import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/focus_session.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';
import '../../state/ekagra_controller.dart';
import '../../state/kavach_controller.dart';

/// Ekagra — the deep focus timer.
///
/// Pomodoro rounds with subject tagging, KAVACH integration and Ekagra Depth
/// accounting (minutes × quality, where quality drops with every shield breach).
class EkagraScreen extends StatelessWidget {
  const EkagraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EkagraController ekagra = context.watch<EkagraController>();
    final KavachController kavach = context.watch<KavachController>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;

    final List<FocusSession> todays = activity.sessionsOn(DayKey.today());
    final int depthToday = activity.repository.depthOn(DayKey.today());
    final int goalMinutes = app.settings.dailyFocusGoalMinutes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Ekagra',
          subtitle: 'Deep focus that actually gets measured',
          icon: Icons.bolt_rounded,
          trailing: NeonChip(
            label: ekagra.kind.label,
            emoji: ekagra.kind.emoji,
            dense: true,
          ),
        ),
        _TimerCard(ekagra: ekagra, kavach: kavach),
        const SizedBox(height: 16),
        _PresetRow(ekagra: ekagra),
        const SizedBox(height: 16),
        _ShieldRow(ekagra: ekagra, kavach: kavach, app: app),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'Depth today',
                value: '${depthToday}m',
                caption: 'Quality weighted',
                icon: Icons.bolt_rounded,
                accent: t.accentViolet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Sessions',
                value: '${todays.length}',
                caption: 'Today',
                icon: Icons.timer_rounded,
                accent: t.accentCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'Daily focus goal',
                    style: TextStyle(color: t.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${AppDateUtils.durationLabel(activity.repository.minutesOn(DayKey.today()))} / '
                    '${AppDateUtils.durationLabel(goalMinutes)}',
                    style: TextStyle(color: t.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              NeonProgressBar(
                progress: AppDateUtils.ratio(
                  activity.repository.minutesOn(DayKey.today()),
                  goalMinutes,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Today\'s sessions',
          subtitle: todays.isEmpty ? 'Nothing yet — the hamster is waiting' : '${todays.length} logged',
          icon: Icons.history_rounded,
        ),
        if (todays.isEmpty)
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(6),
            child: EmptyState(
              title: 'No Ekagra blocks yet',
              message: 'Start a 25 minute block. That is all it takes to open your '
                  'first badge and quiet the hamster.',
              icon: Icons.bolt_rounded,
              action: GlowButton(
                label: 'Start 25 minutes',
                icon: Icons.play_arrow_rounded,
                expand: false,
                compact: true,
                onPressed: () => ekagra.start(),
              ),
            ),
          )
        else
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < todays.length; i++) ...<Widget>[
                  _SessionTile(
                    session: todays[i],
                    onDelete: () => activity.deleteSession(todays[i].id),
                  ),
                  if (i != todays.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: NeonDivider(opacity: 0.12),
                    ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Icon(Icons.info_outline_rounded, size: 17, color: t.accentCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ekagra Depth = focused minutes × quality. Every KAVACH breach shaves '
                  '12% off the quality, so staying in the app literally pays off.',
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

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.ekagra, required this.kavach});

  final EkagraController ekagra;
  final KavachController kavach;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final bool running = ekagra.isRunning;

    return GlassCard(
      radius: 30,
      glowColor: ekagra.onBreak ? t.accentMint : t.accentViolet,
      glowStrength: 0.35,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              NeonChip(
                label: ekagra.onBreak
                    ? 'Break time'
                    : 'Round ${ekagra.currentRound}/${ekagra.rounds}',
                icon: ekagra.onBreak ? Icons.coffee_rounded : Icons.repeat_rounded,
                dense: true,
                color: ekagra.onBreak ? t.accentMint : t.accentViolet,
              ),
              const Spacer(),
              if (kavach.isActive)
                NeonChip(
                  label: kavach.statusLabel,
                  icon: Icons.shield_rounded,
                  dense: true,
                  color: kavach.breaches == 0 ? t.accentMint : t.danger,
                ),
            ],
          ),
          const SizedBox(height: 8),
          MetricRing(
            progress: ekagra.progress,
            value: ekagra.clock,
            label: ekagra.onBreak ? 'BREAK' : ekagra.kind.label.toUpperCase(),
            size: 208,
            stroke: 12,
            colors: ekagra.onBreak
                ? <Color>[t.accentMint, t.accentCyan]
                : <Color>[t.accentViolet, t.accentMagenta],
          ),
          const SizedBox(height: 6),
          HamsterMascot(
            size: 94,
            pose: ekagra.onBreak
                ? MascotPose.sleepy
                : running
                    ? MascotPose.focus
                    : MascotPose.idle,
            showShell: false,
          ),
          const SizedBox(height: 14),
          _SubjectField(initial: ekagra.subject, onChanged: ekagra.setSubject),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: GlowButton(
                  label: running
                      ? 'Pause'
                      : ekagra.isPaused
                          ? 'Resume'
                          : ekagra.onBreak
                              ? 'Start break'
                              : 'Start focus',
                  icon: running
                      ? Icons.pause_rounded
                      : ekagra.onBreak
                          ? Icons.coffee_rounded
                          : Icons.play_arrow_rounded,
                  onPressed: () {
                    if (running) {
                      ekagra.pause();
                    } else if (ekagra.isPaused) {
                      ekagra.resume();
                    } else {
                      ekagra.start(armShield: true);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              GhostButton(
                label: ekagra.onBreak ? 'Skip' : 'Stop',
                icon: ekagra.onBreak ? Icons.skip_next_rounded : Icons.stop_rounded,
                compact: false,
                onPressed: () async {
                  if (ekagra.onBreak) {
                    await ekagra.skipBreak();
                    return;
                  }
                  final FocusSession? session = await ekagra.stop(completed: false);
                  if (context.mounted && session != null) {
                    EmojiBurst.fireFrom(context, emojis: EmojiBurst.focusEmojis, count: 10);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Subject input that owns its controller (so typing never loses focus when
/// the timer ticks and rebuilds the screen every second).
class _SubjectField extends StatefulWidget {
  const _SubjectField({required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_SubjectField> createState() => _SubjectFieldState();
}

class _SubjectFieldState extends State<_SubjectField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassField(
      controller: _controller,
      label: 'Subject',
      hint: 'Operating Systems',
      onChanged: widget.onChanged,
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.ekagra});

  final EkagraController ekagra;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;

    final List<(String, int, SessionKind)> presets = <(String, int, SessionKind)>[
      ('25 min', 25, SessionKind.ekagra),
      ('50 min', 50, SessionKind.ekagra),
      ('90 min', 90, SessionKind.ekagra),
      ('Dhyan 10', 10, SessionKind.dhyan),
    ];

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'QUICK PRESETS',
            style: TextStyle(
              color: t.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final (String label, int minutes, SessionKind kind) in presets)
                NeonChip(
                  label: label,
                  color: ekagra.focusMinutes == minutes && ekagra.kind == kind
                      ? t.accentMagenta
                      : t.primary,
                  dense: false,
                  onTap: () {
                    ekagra.setKind(kind);
                    ekagra.setDurations(focus: minutes);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rounds: ${ekagra.rounds} · short break ${ekagra.shortBreakMinutes}m · '
            'long break ${ekagra.longBreakMinutes}m',
            style: TextStyle(color: t.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            'Configured in Settings (currently ${app.settings.pomodoroFocusMinutes}m focus)',
            style: TextStyle(color: t.textMuted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _ShieldRow extends StatelessWidget {
  const _ShieldRow({required this.ekagra, required this.kavach, required this.app});

  final EkagraController ekagra;
  final KavachController kavach;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      glowColor: t.accentMagenta,
      glowStrength: kavach.isActive ? 0.3 : 0.08,
      onTap: () => AppRouter.go(context, AppRouter.kavach),
      child: Row(
        children: <Widget>[
          Icon(
            kavach.isActive ? Icons.shield_rounded : Icons.shield_outlined,
            color: kavach.isActive ? t.accentMint : t.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'KAVACH shield',
                  style: TextStyle(color: t.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  kavach.isActive
                      ? '${kavach.statusLabel} · integrity ${(kavach.integrity * 100).round()}%'
                      : 'Arms automatically with every session (${app.settings.kavachAutoStart ? 'on' : 'off'})',
                  style: TextStyle(color: t.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: t.textMuted),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onDelete});

  final FocusSession session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: t.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(session.kind.emoji, style: const TextStyle(fontSize: 15))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  session.subject.isEmpty ? session.kind.label : session.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppDateUtils.clock(session.startedAt)} · '
                  '${session.actualMinutes}m · depth ${session.depthScore}'
                  '${session.completed ? '' : ' · stopped early'}',
                  style: TextStyle(color: t.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, size: 17, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}
