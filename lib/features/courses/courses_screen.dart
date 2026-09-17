import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../state/app_state.dart';

/// Courses: structured learning modules with progress that feeds the library
/// and the badge system.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _filter = 'All';
  final Map<String, double> _progress = <String, double>{};

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;
    final List<Course> courses = app.catalog.courses;
    final List<String> categories = <String>[
      'All',
      ...courses.map((Course c) => c.category).toSet(),
    ];

    final List<Course> visible = _filter == 'All'
        ? courses
        : courses.where((Course c) => c.category == _filter).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Courses',
          subtitle: '${courses.length} modules · placements, semester and skills',
          icon: Icons.school_rounded,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String category in categories)
              NeonChip(
                label: category,
                dense: true,
                color: _filter == category ? t.accentMagenta : t.primary,
                onTap: () => setState(() => _filter = category),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          const GlassCard(
            radius: 24,
            child: EmptyState(
              title: 'No courses in this category',
              message: 'Try another filter — or sync from the ifallertzia server in the Taunt Vault.',
              icon: Icons.school_rounded,
            ),
          )
        else
          for (final Course course in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseCard(
                course: course,
                progress: _progress[course.id] ?? course.progress,
                onAdvance: () {
                  final double current = _progress[course.id] ?? course.progress;
                  setState(() {
                    _progress[course.id] = (current + 0.1).clamp(0, 1);
                  });
                  EmojiBurst.fireFrom(context, emojis: EmojiBurst.rewardEmojis, count: 8);
                },
                onStart: () => AppRouter.go(context, AppRouter.ekagra),
              ),
            ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.progress,
    required this.onAdvance,
    required this.onStart,
  });

  final Course course;
  final double progress;
  final VoidCallback onAdvance;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color accent = t.accent(accentFromKey(course.accent));

    return GlassCard(
      radius: 26,
      glowColor: accent,
      glowStrength: 0.2,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Icon(Icons.school_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      course.title,
                      style: TextStyle(color: t.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${course.provider} · ${course.category}',
                      style: TextStyle(color: t.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              NeonChip(
                label: '★ ${course.rating}',
                dense: true,
                color: t.accentAmber,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course.description,
            style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _MetaPill(icon: Icons.play_lesson_rounded, label: '${course.lessons} lessons'),
              const SizedBox(width: 8),
              _MetaPill(icon: Icons.schedule_rounded, label: '${course.hours}h'),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          NeonProgressBar(progress: progress, colors: <Color>[accent, t.accentCyan]),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              GlowButton(
                label: progress == 0 ? 'Start course' : 'Continue',
                icon: Icons.play_arrow_rounded,
                compact: true,
                expand: false,
                gradient: <Color>[accent, t.accentMagenta],
                onPressed: onStart,
              ),
              const SizedBox(width: 8),
              GhostButton(
                label: 'Mark lesson done',
                icon: Icons.check_rounded,
                onPressed: onAdvance,
              ),
              const Spacer(),
              Text(
                '${((1 - progress) * course.hours).round()}h left',
                style: TextStyle(color: t.textMuted, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Row(
      children: <Widget>[
        Icon(icon, size: 13, color: t.textMuted),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: t.textMuted, fontSize: 11)),
      ],
    );
  }
}

/// Small helper reused by Library so both screens agree on the "time left" maths.
String remainingLabel(int hours, double progress) =>
    '${AppDateUtils.oneDecimal(hours * (1 - progress))}h left';
