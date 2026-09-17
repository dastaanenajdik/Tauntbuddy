import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../state/app_state.dart';
import '../../state/ekagra_controller.dart';

/// Focus Rooms — honest, local co-working without fabricated presence counts.
class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  final List<StudyCircle> _createdRooms = <StudyCircle>[];

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final EkagraController focus = context.watch<EkagraController>();
    final AppTokens t = context.tokens;
    final List<StudyCircle> rooms = <StudyCircle>[..._createdRooms, ...app.catalog.circles];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Focus Rooms',
          subtitle: 'Create a room, invite your people, and study together',
          icon: Icons.groups_rounded,
          accent: t.accentCyan,
          trailing: GlowButton(
            label: 'Create',
            icon: Icons.add_rounded,
            expand: false,
            compact: true,
            onPressed: () => _showCreateRoom(context),
          ),
        ),
        GlassCard(
          radius: 24,
          glowStrength: 0.18,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.add_rounded, color: t.accentCyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Your room, your rules',
                        style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      'Add a room name, subject and optional invite list. Nothing is posted publicly.',
                      style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.4),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Create focus room',
                onPressed: () => _showCreateRoom(context),
                icon: const Icon(Icons.add_circle_rounded),
                color: t.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Available rooms',
          subtitle: 'Member totals stay 00 until real people join',
          icon: Icons.meeting_room_rounded,
        ),
        for (final StudyCircle room in rooms)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RoomCard(
              room: room,
              onJoin: () async {
                focus.setSubject(room.name);
                await focus.start(armShield: true);
                if (!context.mounted) return;
                EmojiBurst.fireFrom(context, emojis: EmojiBurst.focusEmojis, count: 10);
                AppRouter.go(context, AppRouter.ekagra);
              },
            ),
          ),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              const HamsterMascot(size: 58, pose: MascotPose.thinking, showShell: false),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Focus Rooms never invent live users. Joining starts a real focus block on this device; '
                  'created rooms remain private to this session.',
                  style: TextStyle(color: t.textMuted, fontSize: 11, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateRoom(BuildContext context) async {
    final TextEditingController name = TextEditingController();
    final TextEditingController subject = TextEditingController();
    final TextEditingController invites = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final StudyCircle? created = await showDialog<StudyCircle>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppTokens t = dialogContext.tokens;
        return AlertDialog(
          backgroundColor: t.surface,
          surfaceTintColor: Colors.transparent,
          title: const Row(
            children: <Widget>[
              Icon(Icons.add_circle_rounded),
              SizedBox(width: 10),
              Text('Create a focus room'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: name,
                    autofocus: true,
                    maxLength: 40,
                    decoration: const InputDecoration(labelText: 'Room name', hintText: 'e.g. Physics Power Hour'),
                    validator: (String? value) => (value ?? '').trim().isEmpty ? 'Enter a room name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: subject,
                    maxLength: 40,
                    decoration: const InputDecoration(labelText: 'Subject', hintText: 'What are you studying?'),
                    validator: (String? value) => (value ?? '').trim().isEmpty ? 'Enter a subject' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: invites,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Invite people (optional)',
                      hintText: 'Names or emails, separated by commas',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create room'),
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final String inviteText = invites.text.trim();
                Navigator.pop(
                  dialogContext,
                  StudyCircle(
                    id: 'local-${DateTime.now().microsecondsSinceEpoch}',
                    name: name.text.trim(),
                    subject: subject.text.trim(),
                    members: 0,
                    activity: 'ready',
                    accent: 'cyan',
                    description: inviteText.isEmpty
                        ? 'Private room · invite people whenever you are ready.'
                        : 'Invited: $inviteText',
                  ),
                );
              },
            ),
          ],
        );
      },
    );

    name.dispose();
    subject.dispose();
    invites.dispose();
    if (created == null || !mounted) return;
    setState(() => _createdRooms.insert(0, created));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${created.name} created · 00 members')),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onJoin});

  final StudyCircle room;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color accent = t.accent(accentFromKey(room.accent));

    return GlassCard(
      radius: 24,
      glowColor: accent,
      glowStrength: 0.14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(room.name,
                    style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              NeonChip(label: room.activity, dense: true, color: accent),
            ],
          ),
          const SizedBox(height: 7),
          Text(room.description, style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.45)),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(Icons.people_alt_rounded, size: 14, color: t.textMuted),
              const SizedBox(width: 6),
              Text('00 members', style: TextStyle(color: t.textMuted, fontSize: 11)),
              const SizedBox(width: 14),
              Icon(Icons.topic_rounded, size: 14, color: t.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(room.subject,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textMuted, fontSize: 11)),
              ),
              GhostButton(label: 'Join', icon: Icons.login_rounded, onPressed: onJoin),
            ],
          ),
        ],
      ),
    );
  }
}
