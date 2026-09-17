import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../data/models/exam.dart';
import '../../data/models/study_task.dart';
import '../../data/models/taunt.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';
import '../../state/shell_controller.dart';
import '../exams/exams_screen.dart';

/// Global search across features, courses, circles, taunts and planner tasks.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: context.read<ShellController>().searchQuery);
  late String _query = _controller.text;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;
    final String query = _query.trim().toLowerCase();

    final List<FeatureCard> features = app.catalog.features
        .where((FeatureCard f) =>
            query.isEmpty ||
            f.title.toLowerCase().contains(query) ||
            f.tagline.toLowerCase().contains(query))
        .toList(growable: false);

    final List<Course> courses = app.catalog.courses
        .where((Course c) => query.isNotEmpty && c.title.toLowerCase().contains(query))
        .toList(growable: false);

    final List<ExamBlueprint> exams = query.isEmpty
        ? <ExamBlueprint>[]
        : app.catalog.exams
            .where((ExamBlueprint exam) =>
                exam.code.toLowerCase().contains(query) ||
                exam.name.toLowerCase().contains(query) ||
                exam.category.toLowerCase().contains(query) ||
                exam.body.toLowerCase().contains(query))
            .take(8)
            .toList(growable: false);

    final List<StudyCircle> circles = app.catalog.circles
        .where((StudyCircle c) => query.isNotEmpty && c.name.toLowerCase().contains(query))
        .toList(growable: false);

    final List<Taunt> taunts = query.isEmpty
        ? <Taunt>[]
        : app.taunts.all
            .where((Taunt taunt) => taunt.text.toLowerCase().contains(query))
            .take(8)
            .toList(growable: false);

    final List<StudyTask> tasks = query.isEmpty
        ? <StudyTask>[]
        : activity.tasks
            .where((StudyTask task) => task.title.toLowerCase().contains(query))
            .take(6)
            .toList(growable: false);

    return GlassScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              ),
              Expanded(
                child: GlassField(
                  controller: _controller,
                  label: 'Search TauntBuddy',
                  hint: 'UPSC, BPSC, CA, CLAT, CUET, kavach...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (String value) {
                    setState(() => _query = value);
                    context.read<ShellController>().setSearchQuery(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (query.isNotEmpty) ...<Widget>[
            SectionHeader(
              title: 'Features',
              subtitle: '${features.length} match(es)',
              icon: Icons.grid_view_rounded,
            ),
            for (final FeatureCard feature in features)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  glowColor: t.accent(accentFromKey(feature.accent)),
                  glowStrength: 0.14,
                  onTap: () => AppRouter.go(context, feature.route),
                  child: Row(
                    children: <Widget>[
                      Icon(iconFor(feature.icon), size: 17, color: t.accent(accentFromKey(feature.accent))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature.title,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 17, color: t.textMuted),
                    ],
                  ),
                ),
              ),
            if (exams.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              SectionHeader(
                title: 'Exams',
                subtitle: '${exams.length}',
                icon: Icons.workspace_premium_rounded,
              ),
              for (final ExamBlueprint exam in exams)
                _ResultTile(
                  title: '${exam.code} · ${exam.name}',
                  subtitle: '${exam.category} · ${exam.body}',
                  icon: iconFor(exam.icon),
                  onTap: () => openExamDetail(context, exam),
                ),
            ],
            if (courses.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              SectionHeader(title: 'Courses', subtitle: '${courses.length}', icon: Icons.school_rounded),
              for (final Course course in courses)
                _ResultTile(
                  title: course.title,
                  subtitle: '${course.category} · ${course.lessons} lessons',
                  icon: Icons.menu_book_rounded,
                  onTap: () => AppRouter.go(context, AppRouter.courses),
                ),
            ],
            if (circles.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              SectionHeader(title: 'Circles', subtitle: '${circles.length}', icon: Icons.groups_rounded),
              for (final StudyCircle circle in circles)
                _ResultTile(
                  title: circle.name,
                  subtitle: '${circle.members.toString().padLeft(2, '0')} members · ${circle.subject}',
                  icon: Icons.diversity_3_rounded,
                  onTap: () => AppRouter.go(context, AppRouter.circles),
                ),
            ],
            if (taunts.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              SectionHeader(title: 'Taunts', subtitle: '${taunts.length}', icon: Icons.campaign_rounded),
              for (final Taunt taunt in taunts)
                _ResultTile(
                  title: taunt.text,
                  subtitle: '${taunt.packTitle} · ${taunt.trigger.label}',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () {
                    app.setActiveTaunt(taunt);
                    Navigator.of(context).maybePop();
                  },
                ),
            ],
            if (tasks.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              SectionHeader(title: 'Planner tasks', subtitle: '${tasks.length}', icon: Icons.checklist_rounded),
              for (final StudyTask task in tasks)
                _ResultTile(
                  title: task.title,
                  subtitle: '${task.day.short} · ${task.subject}',
                  icon: Icons.task_alt_rounded,
                  onTap: () => AppRouter.go(context, AppRouter.planner),
                ),
            ],
            if (features.isEmpty &&
                exams.isEmpty &&
                courses.isEmpty &&
                circles.isEmpty &&
                taunts.isEmpty &&
                tasks.isEmpty)
              GlassCard(
                radius: 24,
                child: EmptyState(
                  title: 'Nothing found',
                  message: 'Try "upsc", "bpsc", "ca", "clat", "cuet", "kavach" or a course name.',
                  icon: Icons.search_off_rounded,
                ),
              ),
          ] else ...<Widget>[
            SectionHeader(
              title: 'Jump to',
              subtitle: 'Popular destinations',
              icon: Icons.flash_on_rounded,
            ),
            for (final FeatureCard feature in app.catalog.features.take(8))
              _ResultTile(
                title: feature.title,
                subtitle: feature.tagline,
                icon: iconFor(feature.icon),
                onTap: () => AppRouter.go(context, feature.route),
              ),
          ],
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Icon(icon, size: 17, color: t.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textMuted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 17, color: t.textMuted),
          ],
        ),
      ),
    );
  }
}
