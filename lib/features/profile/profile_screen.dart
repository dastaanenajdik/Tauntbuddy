import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ember_free_burst.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/user_profile.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';

/// Profile & account details. Everything is device-local, and the screen says so.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;
    final UserProfile profile = app.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Profile',
          subtitle: profile.isGuest ? 'Guest session · stored on this device' : 'Signed in locally',
          icon: Icons.person_rounded,
          trailing: app.isPro ? const ProBadge(label: 'PRO') : null,
        ),
        GlassCard(
          radius: 28,
          glowStrength: 0.28,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              const HamsterMascot(size: 118, pose: MascotPose.celebrate),
              const SizedBox(height: 14),
              Text(
                '${profile.avatarEmoji} ${profile.name}',
                style: TextStyle(color: t.textPrimary, fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                Validators.maskEmail(profile.email),
                style: TextStyle(color: t.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                profile.college.isEmpty ? 'Add your college in Edit profile' : profile.college,
                style: TextStyle(color: t.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GlowButton(
                      label: 'Edit profile',
                      icon: Icons.edit_rounded,
                      compact: true,
                      onPressed: () => _showEditSheet(context, app),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GhostButton(
                    label: 'Settings',
                    icon: Icons.settings_rounded,
                    compact: true,
                    onPressed: () => AppRouter.go(context, AppRouter.settings),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'Focus banked',
                value: AppDateUtils.durationLabel(activity.totalFocusMinutes),
                caption: '${activity.totalSessions} sessions',
                icon: Icons.bolt_rounded,
                accent: t.accentViolet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Level',
                value: app.catalog.levelFor(activity.totalFocusMinutes).title,
                caption: '${app.catalog.levelFor(activity.totalFocusMinutes).minFocusMinutes}m+',
                icon: Icons.military_tech_rounded,
                accent: t.accentAmber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'Streak',
                value: '${activity.streak}d',
                caption: 'Best ${activity.longestStreak}d',
                icon: Icons.local_fire_department_rounded,
                accent: t.accentMagenta,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Syllabus',
                value: '${(activity.syllabusProgress * 100).round()}%',
                caption: '${activity.subjects.length} subjects',
                icon: Icons.menu_book_rounded,
                accent: t.accentCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Account details',
          subtitle: 'Nothing here leaves your device',
          icon: Icons.badge_rounded,
        ),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _DetailRow(label: 'Name', value: profile.name),
              _DetailRow(label: 'Email', value: profile.email),
              _DetailRow(label: 'Account type', value: profile.isGuest ? 'Guest (local)' : 'Local account'),
              _DetailRow(
                label: 'Member since',
                value: AppDateUtils.prettyDate(profile.createdAt, fallback: 'Today'),
              ),
              _DetailRow(
                label: 'Last active',
                value: profile.lastLoginAt == null
                    ? 'Now'
                    : AppDateUtils.clock(profile.lastLoginAt!),
              ),
              _DetailRow(label: 'Plan', value: app.isPro ? 'PRO (unlocked)' : 'Free'),
              _DetailRow(label: 'Target exam', value: profile.examTarget.isEmpty ? 'Not set' : profile.examTarget),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Account actions',
                style: TextStyle(color: t.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              GhostButton(
                label: profile.isGuest ? 'Create a local account' : 'Switch account',
                icon: Icons.login_rounded,
                expand: true,
                compact: false,
                onPressed: () => AppRouter.go(context, AppRouter.auth),
              ),
              const SizedBox(height: 10),
              GhostButton(
                label: 'Sign out',
                icon: Icons.logout_rounded,
                color: t.accentAmber,
                expand: true,
                compact: false,
                onPressed: () async {
                  await app.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.onboarding,
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              const SizedBox(height: 10),
              GhostButton(
                label: 'Reset all app data',
                icon: Icons.delete_forever_rounded,
                color: t.danger,
                expand: true,
                compact: false,
                onPressed: () => _confirmReset(context, app),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditSheet(BuildContext context, AppState app) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => _EditProfileSheet(app: app),
    );
  }

  Future<void> _confirmReset(BuildContext context, AppState app) async {
    final AppTokens t = context.tokens;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: const Text('Reset everything?'),
        content: const Text(
          'Sessions, goals, moods, planner tasks, badges and settings will be deleted '
          'from this device. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await app.resetEverything();
    if (!context.mounted) return;
    EmberFreeBurst.fireFrom(context);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: TextStyle(color: t.textMuted, fontSize: 12))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: t.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.app});

  final AppState app;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.app.profile.name);
  late final TextEditingController _college =
      TextEditingController(text: widget.app.profile.college);
  late final TextEditingController _exam =
      TextEditingController(text: widget.app.profile.examTarget);
  late String _emoji = widget.app.profile.avatarEmoji;
  String? _error;

  static const List<String> _emojis = <String>['🐹', '🎓', '⚡', '🛡️', '🧘', '📚', '🔥', '💜'];

  @override
  void dispose() {
    _name.dispose();
    _college.dispose();
    _exam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: GlassCard(
        radius: 26,
        padding: const EdgeInsets.all(18),
        glowStrength: 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Edit profile',
              style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            GlassField(controller: _name, label: 'Name', error: _error),
            const SizedBox(height: 14),
            GlassField(controller: _college, label: 'College / School', hint: 'IIT (ISM) Dhanbad'),
            const SizedBox(height: 14),
            GlassField(controller: _exam, label: 'Target exam', hint: 'GATE 2027'),
            const SizedBox(height: 14),
            Text(
              'AVATAR',
              style: TextStyle(color: t.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String emoji in _emojis)
                  GestureDetector(
                    onTap: () => setState(() => _emoji = emoji),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _emoji == emoji ? t.primary.withValues(alpha: 0.32) : t.surfaceHigh,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _emoji == emoji ? t.primary : t.glassBorder,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            GlowButton(
              label: 'Save profile',
              icon: Icons.save_rounded,
              onPressed: () async {
                final String? nameError = Validators.displayName(_name.text);
                if (nameError != null) {
                  setState(() => _error = nameError);
                  return;
                }
                await widget.app.updateProfile(
                  widget.app.profile.copyWith(
                    name: _name.text.trim(),
                    college: _college.text.trim(),
                    examTarget: _exam.text.trim(),
                    avatarEmoji: _emoji,
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
