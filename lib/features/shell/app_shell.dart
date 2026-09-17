import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/taunt.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';
import '../../state/ekagra_controller.dart';
import '../../state/kavach_controller.dart';
import '../../state/shell_controller.dart';
import '../analytics/analytics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';

/// The application shell: glass app bar, side drawer, bottom navigation and the
/// floating taunt button that makes the mascot feel alive.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _lastTauntTick = 0;

  @override
  Widget build(BuildContext context) {
    final ShellController shell = context.watch<ShellController>();
    final AppState app = context.watch<AppState>();
    final EkagraController ekagra = context.watch<EkagraController>();

    // A new taunt arrives (notification tap, timer end, test ping) → celebrate.
    if (app.tauntTick != _lastTauntTick) {
      _lastTauntTick = app.tauntTick;
      final Taunt? taunt = app.activeTaunt;
      if (taunt != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          EmojiBurst.fireFrom(context, emojis: EmojiBurst.tauntEmojis, count: 9);
          _showTauntSheet(taunt);
        });
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: Colors.transparent,
      drawer: const _AppDrawer(),
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              _ShellTopBar(
                onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                onSearch: () => AppRouter.go(context, AppRouter.search),
              ),
              if (ekagra.isRunning || ekagra.isPaused) const _RunningSessionStrip(),
              Expanded(
                child: IndexedStack(
                  index: shell.index,
                  children: const <Widget>[
                    HomeScreen(),
                    DashboardScreen(),
                    LibraryScreen(),
                    AnalyticsScreen(),
                    SettingsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _TauntFab(
        onPressed: () {
          final Taunt? taunt = app.pickSituationalTaunt();
          if (taunt == null) return;
          app.setActiveTaunt(taunt);
          EmojiBurst.fireFrom(context, count: 12);
          _showTauntSheet(taunt);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _ShellBottomNav(
        index: shell.index,
        onSelect: shell.select,
      ),
    );
  }

  void _showTauntSheet(Taunt taunt) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _TauntSheet(taunt: taunt),
    );
  }
}

// ---------------------------------------------------------------- top bar ---

class _ShellTopBar extends StatelessWidget {
  const _ShellTopBar({required this.onMenu, required this.onSearch});

  final VoidCallback onMenu;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ShellController shell = context.watch<ShellController>();
    final AppTokens t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: <Widget>[
          _RoundIconButton(icon: Icons.menu_rounded, onTap: onMenu, tooltip: 'Menu'),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onSearch,
              child: GlassCard(
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                glowStrength: 0.12,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.search_rounded, size: 17, color: t.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shell.searchQuery.isEmpty
                            ? 'Search exams, features, courses, taunts...'
                            : shell.searchQuery,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.textMuted, fontSize: 12.5),
                      ),
                    ),
                    if (app.notificationsGranted)
                      Icon(Icons.notifications_active_rounded, size: 15, color: t.accentMint)
                    else
                      Icon(Icons.notifications_off_rounded, size: 15, color: t.accentGrey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const HamsterMascot(size: 40, showShell: false, showGlow: false, animate: true),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.tooltip, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: t.glassFill,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: t.glassBorder),
        ),
        child: Icon(icon, size: 19, color: color ?? t.textPrimary),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

// ------------------------------------------------------- running session ---

class _RunningSessionStrip extends StatelessWidget {
  const _RunningSessionStrip();

  @override
  Widget build(BuildContext context) {
    final EkagraController ekagra = context.watch<EkagraController>();
    final KavachController kavach = context.watch<KavachController>();
    final AppTokens t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        glowColor: t.accentMagenta,
        glowStrength: 0.3,
        onTap: () => AppRouter.go(context, AppRouter.ekagra),
        child: Row(
          children: <Widget>[
            Icon(ekagra.onBreak ? Icons.coffee_rounded : Icons.bolt_rounded,
                size: 17, color: t.accentMagenta),
            const SizedBox(width: 9),
            Text(
              ekagra.onBreak ? 'Break' : ekagra.subject,
              style: TextStyle(color: t.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (kavach.isActive)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.shield_rounded, size: 15, color: kavach.breaches == 0 ? t.accentMint : t.danger),
              ),
            Text(
              ekagra.clock,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ bottom nav ---

class _ShellBottomNav extends StatelessWidget {
  const _ShellBottomNav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const List<(IconData, IconData, String)> _items = <(IconData, IconData, String)>[
    (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'Home'),
    (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Dashboard'),
    (Icons.local_library_outlined, Icons.local_library_rounded, 'Library'),
    (Icons.insights_outlined, Icons.insights_rounded, 'Analytics'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: t.isDark ? const Color(0xFF1B1830) : const Color(0xFFFFFFFF),
            border: Border.all(color: t.glassBorder),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    selected: i == index,
                    icon: _items[i].$1,
                    selectedIcon: _items[i].$2,
                    label: _items[i].$3,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color color = selected ? t.primary : t.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? t.primary.withValues(alpha: 0.26) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(color: t.primary.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: -4),
                    ]
                  : null,
            ),
            child: Icon(selected ? selectedIcon : icon, size: 20, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ floating FAB --

class _TauntFab extends StatelessWidget {
  const _TauntFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: t.brandGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: <BoxShadow>[
            BoxShadow(color: t.primary.withValues(alpha: 0.55), blurRadius: 26, spreadRadius: -4),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Center(
          child: HamsterMascot(size: 48, showShell: false, showGlow: false, animate: true),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ drawer --

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  static const List<(String, String, IconData)> _entries = <(String, String, IconData)>[
    ('Home', AppRouter.home, Icons.auto_awesome_rounded),
    ('Dashboard', AppRouter.dashboard, Icons.space_dashboard_rounded),
    ('Focus Flow', AppRouter.ekagra, Icons.bolt_rounded),
    ('Exam Planner', AppRouter.planner, Icons.event_note_rounded),
    ('Exam Hub', AppRouter.exams, Icons.workspace_premium_rounded),
    ('Distraction Shield', AppRouter.kavach, Icons.shield_rounded),
    ('Progress Board', AppRouter.leaderboard, Icons.emoji_events_rounded),
    ('Courses', AppRouter.courses, Icons.school_rounded),
    ('Focus Rooms', AppRouter.circles, Icons.groups_rounded),
    ('Mindful Reset', AppRouter.dhyan, Icons.self_improvement_rounded),
    ('Dayline', AppRouter.timeline, Icons.schedule_rounded),
    ("Today's Goals", AppRouter.goals, Icons.checklist_rounded),
    ('Motivation Vault', AppRouter.taunts, Icons.campaign_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;

    return Drawer(
      backgroundColor: Colors.transparent,
      width: 292,
      child: AmbientBackground(
        showGrid: false,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GlassCard(
                  radius: 24,
                  glowStrength: 0.3,
                  child: Row(
                    children: <Widget>[
                      const HamsterMascot(size: 58, showShell: false, showGlow: false),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              app.profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${app.catalog.levelFor(activity.totalFocusMinutes).title} · '
                              '${activity.totalFocusMinutes ~/ 60}h focused',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: t.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 7),
                            NeonProgressBar(progress: app.levelProgress, height: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  children: <Widget>[
                    for (final (String label, String route, IconData icon) in _entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _DrawerTile(
                          label: label,
                          icon: icon,
                          pro: route == AppRouter.planner && !app.isPro,
                          onTap: () {
                            Navigator.of(context).pop();
                            AppRouter.go(context, route);
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    _DrawerTile(
                      label: 'Profile',
                      icon: Icons.person_rounded,
                      onTap: () {
                        Navigator.of(context).pop();
                        AppRouter.go(context, AppRouter.profile);
                      },
                    ),
                    _DrawerTile(
                      label: 'Settings',
                      icon: Icons.settings_rounded,
                      onTap: () {
                        Navigator.of(context).pop();
                        AppRouter.go(context, AppRouter.settings);
                      },
                    ),
                  ],
                ),
              ),
              const _DrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.pro = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: t.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (pro) const ProBadge(locked: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;
    final theme = app.themeController;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(theme?.icon ?? Icons.brightness_auto_rounded, size: 17, color: t.accentCyan),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Theme · ${theme?.label(context) ?? 'System'}',
                style: TextStyle(color: t.textMuted, fontSize: 11.5),
              ),
            ),
            GhostButton(
              label: 'Switch',
              compact: true,
              onPressed: () => theme?.cycle(),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ taunt sheet ---

class _TauntSheet extends StatelessWidget {
  const _TauntSheet({required this.taunt});

  final Taunt taunt;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final AppState app = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        radius: 26,
        glowStrength: 0.35,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const HamsterMascot(
                  size: 58,
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
                        'TauntBuddy says',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          NeonChip(label: taunt.packTitle, dense: true, color: t.accentCyan),
                          const SizedBox(width: 6),
                          NeonChip(
                            label: taunt.source == TauntSource.remote ? 'ifallertzia' : 'Bundled',
                            dense: true,
                            color: t.accentMint,
                            icon: taunt.source == TauntSource.remote
                                ? Icons.cloud_done_rounded
                                : Icons.inventory_2_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              taunt.text,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: GlowButton(
                    label: 'Open Focus Flow',
                    icon: Icons.bolt_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                      AppRouter.go(context, AppRouter.ekagra);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                GhostButton(
                  label: 'Dismiss',
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
