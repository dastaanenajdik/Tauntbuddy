import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/taunt.dart';
import '../../data/services/ifallertzia_source.dart';
import '../../state/app_state.dart';

/// Taunt Vault — the ifallertzia-server synced taunt engine, made visible.
///
/// Users can see where the taunts come from, sync a fresh dataset, tune how
/// brutal the hamster is, fire a test notification and favourite lines.
class TauntsScreen extends StatefulWidget {
  const TauntsScreen({super.key});

  @override
  State<TauntsScreen> createState() => _TauntsScreenState();
}

class _TauntsScreenState extends State<TauntsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  TauntTrigger? _filter;
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Taunt> _visible(AppState app) {
    final String query = _query.trim().toLowerCase();
    return app.taunts.all.where((Taunt taunt) {
      final bool matchesQuery = query.isEmpty ||
          taunt.text.toLowerCase().contains(query) ||
          taunt.category.contains(query) ||
          taunt.packTitle.toLowerCase().contains(query);
      final bool matchesFilter = _filter == null || taunt.trigger == _filter;
      return matchesQuery && matchesFilter;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;
    final List<Taunt> visible = _visible(app);
    final SyncResult sync = app.taunts.lastSync;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Motivation Vault',
          subtitle: '${app.taunts.count} taunts · ${app.taunts.packs.length} packs',
          icon: Icons.campaign_rounded,
          accent: t.accentMagenta,
          trailing: NeonChip(
            label: sync.status.name.toUpperCase(),
            dense: true,
            color: sync.isOk ? t.accentMint : t.accentAmber,
          ),
        ),
        _SyncCard(
          settings: app.settings,
          sync: sync,
          busy: _busy,
          onSync: () async {
            setState(() => _busy = true);
            final SyncResult result = await app.syncTaunts();
            if (!context.mounted) return;
            setState(() => _busy = false);
            EmojiBurst.fireFrom(context, emojis: EmojiBurst.rewardEmojis, count: 8);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: t.surfaceHigh,
              ),
            );
          },
          onTest: () async {
            final bool ok = await app.sendTestTaunt();
            if (!context.mounted) return;
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('No taunts loaded yet. Try syncing first.'),
                  backgroundColor: t.surfaceHigh,
                ),
              );
            }
          },
          onOpenSettings: () => app.notifications.openSystemSettings(),
        ),
        const SizedBox(height: 16),
        _IntensityCard(app: app),
        const SizedBox(height: 16),
        GlassField(
          controller: _search,
          label: 'Search taunts',
          hint: 'reels, attendance, deadline...',
          prefixIcon: Icons.search_rounded,
          onChanged: (String value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            NeonChip(
              label: 'All',
              dense: true,
              color: _filter == null ? t.accentMagenta : t.primary,
              onTap: () => setState(() => _filter = null),
            ),
            for (final TauntTrigger trigger in app.taunts.groupedByTrigger().keys)
              NeonChip(
                label: trigger.label,
                dense: true,
                color: _filter == trigger ? t.accentMagenta : t.primary,
                onTap: () => setState(() => _filter = trigger),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          const GlassCard(
            radius: 24,
            child: EmptyState(
              title: 'No taunts match',
              message: 'Clear the filters, or sync a fresh dataset from the ifallertzia server.',
              icon: Icons.search_off_rounded,
            ),
          )
        else
          for (final Taunt taunt in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TauntCard(
                taunt: taunt,
                favourite: app.taunts.isFavourite(taunt.id),
                onFavourite: () => app.taunts.toggleFavourite(taunt.id),
                onCopy: () async {
                  await Clipboard.setData(ClipboardData(text: taunt.text));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Taunt copied'), backgroundColor: t.surfaceHigh),
                  );
                },
                onSend: () => app.setActiveTaunt(taunt),
              ),
            ),
      ],
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.settings,
    required this.sync,
    required this.busy,
    required this.onSync,
    required this.onTest,
    required this.onOpenSettings,
  });

  final AppSettings settings;
  final SyncResult sync;
  final bool busy;
  final VoidCallback onSync;
  final VoidCallback onTest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final AppState app = context.watch<AppState>();

    return GlassCard(
      radius: 26,
      glowStrength: 0.26,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.cloud_sync_rounded, color: t.accentCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ifallertzia server taunt sync',
                  style: TextStyle(color: t.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (settings.lastSyncAt != null)
                Text(
                  'synced ${AppDateUtils.clock(settings.lastSyncAt!)}',
                  style: TextStyle(color: t.textMuted, fontSize: 10.5),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sync.message,
            style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 6),
          Text(
            app.settings.tauntRepoUrl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: t.accentCyan, fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              GlowButton(
                label: busy ? 'Syncing...' : 'Sync now',
                icon: Icons.refresh_rounded,
                compact: true,
                expand: false,
                busy: busy,
                onPressed: busy ? null : onSync,
              ),
              const SizedBox(width: 8),
              GhostButton(
                label: 'Test taunt',
                icon: Icons.notifications_active_rounded,
                onPressed: onTest,
              ),
              const SizedBox(width: 8),
              GhostButton(
                label: 'App settings',
                icon: Icons.settings_rounded,
                onPressed: onOpenSettings,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                app.notificationsGranted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                size: 15,
                color: app.notificationsGranted ? t.accentMint : t.accentAmber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  app.notificationsGranted
                      ? 'Notifications enabled · ${app.plan.length} daily slots scheduled'
                      : 'Notifications are blocked at OS level — tap "App settings" to fix',
                  style: TextStyle(color: t.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntensityCard extends StatelessWidget {
  const _IntensityCard({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final int intensity = app.settings.tauntIntensity;

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const HamsterMascot(
                size: 54,
                pose: MascotPose.judging,
                showShell: false,
                showGlow: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Taunt intensity · ${app.settings.intensityLabel}',
                      style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Caps how brutal the hamster is allowed to be.',
                      style: TextStyle(color: t.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedNeonPicker(
            options: const <String>['Polite', 'Judgemental', 'Ruthless'],
            selectedIndex: intensity - 1,
            accent: t.accentMagenta,
            onSelected: (int index) =>
                app.updateSettings(app.settings.copyWith(tauntIntensity: index + 1)),
          ),
        ],
      ),
    );
  }
}

class _TauntCard extends StatelessWidget {
  const _TauntCard({
    required this.taunt,
    required this.favourite,
    required this.onFavourite,
    required this.onCopy,
    required this.onSend,
  });

  final Taunt taunt;
  final bool favourite;
  final VoidCallback onFavourite;
  final VoidCallback onCopy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final int severity = taunt.severity;
    final Color severityColor = severity >= 3
        ? t.danger
        : severity == 2
            ? t.accentAmber
            : t.accentMint;

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      glowColor: severityColor,
      glowStrength: 0.12,
      onTap: onSend,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(taunt.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  taunt.packTitle,
                  style: TextStyle(color: t.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
              NeonChip(
                label: severity >= 3 ? 'SAVAGE' : severity == 2 ? 'SNARKY' : 'GENTLE',
                dense: true,
                color: severityColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            taunt.text,
            style: TextStyle(color: t.textPrimary, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              NeonChip(
                label: taunt.trigger.label,
                dense: true,
                color: t.accentCyan,
              ),
              const SizedBox(width: 6),
              NeonChip(
                label: taunt.source == TauntSource.remote ? 'ifallertzia' : 'Bundled',
                dense: true,
                color: taunt.source == TauntSource.remote ? t.accentMint : t.accentGrey,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Favourite',
                onPressed: onFavourite,
                icon: Icon(
                  favourite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 18,
                  color: favourite ? t.accentAmber : t.textMuted,
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                onPressed: onCopy,
                icon: Icon(Icons.copy_rounded, size: 16, color: t.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
