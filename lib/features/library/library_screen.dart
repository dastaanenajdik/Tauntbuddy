import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../data/models/quote.dart';
import '../../data/models/taunt.dart';
import '../../state/app_state.dart';

/// Library: the shelf. Courses in progress, saved taunts and dataset resources.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Library',
          subtitle: 'Everything you have collected',
          icon: Icons.local_library_rounded,
        ),
        SegmentedNeonPicker(
          options: const <String>['Courses', 'Saved taunts', 'Resources'],
          selectedIndex: _tab,
          onSelected: (int index) => setState(() => _tab = index),
        ),
        const SizedBox(height: 16),
        if (_tab == 0) ..._courses(context, app, t),
        if (_tab == 1) ..._savedTaunts(context, app, t),
        if (_tab == 2) ..._resources(context, app, t),
      ],
    );
  }

  List<Widget> _courses(BuildContext context, AppState app, AppTokens t) {
    final List<Course> courses = app.catalog.courses;
    if (courses.isEmpty) {
      return <Widget>[
        const GlassCard(
          radius: 24,
          child: EmptyState(
            title: 'Shelf is empty',
            message: 'Sync from the ifallertzia server in the Taunt Vault to load the course catalog.',
            icon: Icons.school_rounded,
          ),
        ),
      ];
    }
    return <Widget>[
      for (final Course course in courses)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            radius: 22,
            padding: const EdgeInsets.all(16),
            glowColor: t.accent(accentFromKey(course.accent)),
            glowStrength: 0.14,
            onTap: () => AppRouter.go(context, AppRouter.courses),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.accent(accentFromKey(course.accent)).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: t.accent(accentFromKey(course.accent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        course.title,
                        style: TextStyle(color: t.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      NeonProgressBar(progress: course.progress, height: 5),
                      const SizedBox(height: 5),
                      Text(
                        '${(course.progress * 100).round()}% · ${course.lessons} lessons · ${course.hours}h',
                        style: TextStyle(color: t.textMuted, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: t.textMuted),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _savedTaunts(BuildContext context, AppState app, AppTokens t) {
    final List<Taunt> favourites = app.taunts.favourites;
    if (favourites.isEmpty) {
      return <Widget>[
        GlassCard(
          radius: 24,
          child: EmptyState(
            title: 'No saved taunts',
            message: 'Bookmark the lines that hit hardest — they stay available offline.',
            icon: Icons.bookmark_border_rounded,
            action: GlowButton(
              label: 'Open Taunt Vault',
              icon: Icons.campaign_rounded,
              compact: true,
              expand: false,
              onPressed: () => AppRouter.go(context, AppRouter.taunts),
            ),
          ),
        ),
      ];
    }
    return <Widget>[
      for (final Taunt taunt in favourites)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            radius: 22,
            padding: const EdgeInsets.all(16),
            onTap: () => app.taunts.toggleFavourite(taunt.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  taunt.text,
                  style: TextStyle(color: t.textPrimary, fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    NeonChip(label: taunt.packTitle, dense: true, color: t.accentViolet),
                    const Spacer(),
                    Text(
                      'tap to remove',
                      style: TextStyle(color: t.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _resources(BuildContext context, AppState app, AppTokens t) {
    final Quote quote = app.catalog.quoteOfTheDay;
    return <Widget>[
      GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ifallertzia server status',
              style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _ResourceRow(label: 'Taunts loaded', value: '${app.taunts.count}'),
            _ResourceRow(label: 'Packs', value: '${app.taunts.packs.length}'),
            _ResourceRow(label: 'Quotes', value: '${app.catalog.quotes.quotes.length}'),
            _ResourceRow(label: 'Courses', value: '${app.catalog.courses.length}'),
            _ResourceRow(label: 'Badges', value: '${app.catalog.badges.length}'),
            _ResourceRow(
              label: 'Source',
              value: app.taunts.dataset.source == TauntSource.remote ? 'ifallertzia server' : 'Bundled asset',
            ),
            const SizedBox(height: 12),
            Text(
              'Dataset updated: ${app.taunts.updatedAt ?? 'unknown'}',
              style: TextStyle(color: t.textMuted, fontSize: 10.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Quote of the day',
              style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              quote.text,
              style: TextStyle(color: t.textPrimary, fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 6),
            Text('— ${quote.author}', style: TextStyle(color: t.textMuted, fontSize: 11.5)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'How the taunts reach you',
              style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '1. CI validates assets/data/taunts.json on every PR.\n'
              '2. The app fetches the same file from the ifallertzia server.\n'
              '3. The reminder engine schedules 1–6 daily taunts with the OS.\n'
              '4. Offline? The bundled pack and your last sync keep it running.',
              style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.6),
            ),
          ],
        ),
      ),
    ];
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: TextStyle(color: t.textMuted, fontSize: 11.5))),
          Text(
            value,
            style: TextStyle(color: t.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
