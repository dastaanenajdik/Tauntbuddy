import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/app_settings.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';
import 'widgets/theme_chooser.dart';

/// Settings: theme, notifications, study config, KAVACH, data and about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _repo = TextEditingController();
  bool _repoInitialised = false;

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;
    final AppSettings settings = app.settings;

    if (!_repoInitialised) {
      _repo.text = settings.tauntRepoUrl;
      _repoInitialised = true;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Settings',
          subtitle: 'Tune the hamster',
          icon: Icons.settings_rounded,
        ),

        // ------------------------------------------------------------- theme --
        SectionHeader(
          title: 'Appearance',
          subtitle: 'Theme · ${app.themeController?.label(context) ?? 'System'}',
          icon: Icons.palette_rounded,
          accent: t.accentCyan,
        ),
        const ThemeChooserCards(),
        const SizedBox(height: 18),

        // ----------------------------------------------------- notifications --
        SectionHeader(
          title: 'Smart taunt notifications',
          subtitle: app.notificationsGranted ? 'Permission granted' : 'Permission required',
          icon: Icons.notifications_active_rounded,
          accent: t.accentMagenta,
        ),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _SwitchRow(
                title: 'Enable taunts',
                subtitle: 'The hamster pings you when you go quiet',
                value: settings.notificationsEnabled,
                onChanged: (bool value) async {
                  if (value && !app.notificationsGranted) {
                    await app.requestNotificationPermission();
                    return;
                  }
                  await app.updateSettings(settings.copyWith(notificationsEnabled: value));
                },
              ),
              const NeonDivider(opacity: 0.12),
              if (!app.notificationsGranted)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GhostButton(
                    label: 'Open system notification settings',
                    icon: Icons.open_in_new_rounded,
                    expand: true,
                    compact: false,
                    onPressed: app.notifications.openSystemSettings,
                  ),
                ),
              _SliderRow(
                title: 'Taunts per day',
                value: '${settings.remindersPerDay}',
                sliderValue: settings.remindersPerDay.toDouble(),
                min: 0,
                max: 6,
                divisions: 6,
                onChanged: (double value) =>
                    app.updateSettings(settings.copyWith(remindersPerDay: value.round())),
              ),
              _SliderRow(
                title: 'Last taunt of the day',
                value: '${settings.dailyReminderHour.toString().padLeft(2, '0')}:'
                    '${settings.dailyReminderMinute.toString().padLeft(2, '0')}',
                sliderValue: settings.dailyReminderHour.toDouble(),
                min: 17,
                max: 23,
                divisions: 6,
                onChanged: (double value) =>
                    app.updateSettings(settings.copyWith(dailyReminderHour: value.round())),
              ),
              const NeonDivider(opacity: 0.12),
              _SwitchRow(
                title: 'Sound',
                subtitle: 'Play a sound with each taunt',
                value: settings.soundEnabled,
                onChanged: (bool value) =>
                    app.updateSettings(settings.copyWith(soundEnabled: value)),
              ),
              _SwitchRow(
                title: 'Streak alerts',
                subtitle: 'Warn me before a streak dies',
                value: settings.streakAlerts,
                onChanged: (bool value) =>
                    app.updateSettings(settings.copyWith(streakAlerts: value)),
              ),
              _SwitchRow(
                title: 'Exam alerts',
                subtitle: 'Countdown pings in exam week',
                value: settings.examAlerts,
                onChanged: (bool value) =>
                    app.updateSettings(settings.copyWith(examAlerts: value)),
              ),
              _SwitchRow(
                title: 'Mood check-in reminder',
                subtitle: 'A gentle nudge to log how you feel',
                value: settings.moodReminder,
                onChanged: (bool value) =>
                    app.updateSettings(settings.copyWith(moodReminder: value)),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GhostButton(
                      label: 'Send test taunt',
                      icon: Icons.send_rounded,
                      expand: true,
                      compact: false,
                      onPressed: () => app.sendTestTaunt(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GhostButton(
                      label: 'Reschedule (${app.plan.length})',
                      icon: Icons.schedule_send_rounded,
                      expand: true,
                      compact: false,
                      onPressed: app.refreshReminders,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ----------------------------------------------------- study config --
        SectionHeader(
          title: 'Study configuration',
          subtitle: 'Pomodoro, goals and intensity',
          icon: Icons.tune_rounded,
          accent: t.accentViolet,
        ),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _SliderRow(
                title: 'Focus length',
                value: '${settings.pomodoroFocusMinutes} min',
                sliderValue: settings.pomodoroFocusMinutes.toDouble(),
                min: 10,
                max: 120,
                divisions: 22,
                onChanged: (double value) =>
                    app.updateSettings(settings.copyWith(pomodoroFocusMinutes: value.round())),
              ),
              _SliderRow(
                title: 'Short break',
                value: '${settings.pomodoroShortBreakMinutes} min',
                sliderValue: settings.pomodoroShortBreakMinutes.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (double value) =>
                    app.updateSettings(settings.copyWith(pomodoroShortBreakMinutes: value.round())),
              ),
              _SliderRow(
                title: 'Rounds per session',
                value: '${settings.pomodoroRounds}',
                sliderValue: settings.pomodoroRounds.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                onChanged: (double value) =>
                    app.updateSettings(settings.copyWith(pomodoroRounds: value.round())),
              ),
              _SliderRow(
                title: 'Daily focus goal',
                value: AppDateUtils.durationLabel(settings.dailyFocusGoalMinutes),
                sliderValue: settings.dailyFocusGoalMinutes.toDouble(),
                min: 30,
                max: 480,
                divisions: 15,
                onChanged: (double value) =>
                    app.updateSettings(settings.copyWith(dailyFocusGoalMinutes: value.round())),
              ),
              const SizedBox(height: 6),
              Text(
                'TAUNT INTENSITY · ${settings.intensityLabel.toUpperCase()}',
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedNeonPicker(
                options: const <String>['Polite', 'Judgemental', 'Ruthless'],
                selectedIndex: settings.tauntIntensity - 1,
                accent: t.accentMagenta,
                onSelected: (int index) =>
                    app.updateSettings(settings.copyWith(tauntIntensity: index + 1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ----------------------------------------------------------- kavach --
        SectionHeader(
          title: 'KAVACH shield',
          subtitle: 'Distraction guard',
          icon: Icons.shield_rounded,
          accent: t.accentMagenta,
        ),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _SwitchRow(
                title: 'Arm shield automatically',
                subtitle: 'Every new session starts protected',
                value: settings.kavachAutoStart,
                onChanged: (bool value) =>
                    app.updateSettings(settings.copyWith(kavachAutoStart: value)),
              ),
              _SwitchRow(
                title: 'Strict mode',
                subtitle: 'Pause the timer and log a breach when you leave',
                value: settings.kavachStrict,
                onChanged: (bool value) =>
                    app.updateSettings(settings.copyWith(kavachStrict: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ------------------------------------------------------------- data --
        SectionHeader(
          title: 'Data & sync',
          subtitle: app.taunts.lastSync.message,
          icon: Icons.cloud_sync_rounded,
          accent: t.accentCyan,
        ),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GlassField(
                controller: _repo,
                label: 'Taunt dataset URL',
                hint: 'https://raw.githubusercontent.com/...',
                onSubmitted: (String value) => app.updateSettings(
                  settings.copyWith(tauntRepoUrl: value.trim()),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GhostButton(
                      label: 'Save URL',
                      icon: Icons.link_rounded,
                      expand: true,
                      compact: false,
                      onPressed: () => app.updateSettings(
                        settings.copyWith(tauntRepoUrl: _repo.text.trim()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GhostButton(
                      label: 'Sync now',
                      icon: Icons.refresh_rounded,
                      expand: true,
                      compact: false,
                      onPressed: () => app.syncTaunts(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoRow(
                label: 'Taunts loaded',
                value: '${app.taunts.count} · ${app.taunts.dataset.source.name}',
              ),
              _InfoRow(
                label: 'Last sync',
                value: settings.lastSyncAt == null
                    ? 'Never'
                    : AppDateUtils.prettyDate(settings.lastSyncAt),
              ),
              _InfoRow(
                label: 'Sessions stored',
                value: '${activity.totalSessions}',
              ),
              _InfoRow(
                label: 'Notifications permission',
                value: app.notificationsGranted ? 'granted' : 'not granted',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ------------------------------------------------------------ about --
        SectionHeader(
          title: 'About',
          subtitle: 'TauntBuddy 1.0.0',
          icon: Icons.info_outline_rounded,
        ),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const HamsterMascot(size: 66, pose: MascotPose.idle, showShell: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'TauntBuddy',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"Kyuki kal karunga se degree nahi milti"',
                          style: TextStyle(
                            color: t.textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoRow(label: 'Version', value: '1.0.0+1'),
              _InfoRow(label: 'Palette', value: AppTheme.paletteName),
              _InfoRow(label: 'Platform', value: Theme.of(context).platform.name),
              _InfoRow(
                label: 'Level',
                value: '${app.catalog.levelFor(activity.totalFocusMinutes).title} · '
                    '${AppDateUtils.durationLabel(activity.totalFocusMinutes)}',
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GhostButton(
                      label: 'Profile',
                      icon: Icons.person_rounded,
                      expand: true,
                      compact: false,
                      onPressed: () => AppRouter.go(context, AppRouter.profile),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GhostButton(
                      label: 'Taunt Vault',
                      icon: Icons.campaign_rounded,
                      expand: true,
                      compact: false,
                      onPressed: () => AppRouter.go(context, AppRouter.taunts),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: t.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: t.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.title,
    required this.value,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String value;
  final double sliderValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              value,
              style: TextStyle(color: t.accentCyan, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: t.primary,
            inactiveTrackColor: t.glassBorder,
            thumbColor: t.glow,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: sliderValue.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: TextStyle(color: t.textMuted, fontSize: 11.5))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: t.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
