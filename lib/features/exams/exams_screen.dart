import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../data/models/exam.dart';
import '../../data/models/study_task.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';

/// Exam Hub — every Indian exam the dataset knows about.
///
/// Each blueprint carries the full picture: who conducts it, the stage-wise
/// exam pattern, the paper-wise syllabus and the yearly cycle. One tap pushes
/// the whole syllabus into the Exam Planner with the next exam date attached.
class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _category = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;
    final List<ExamBlueprint> exams = app.catalog.exams;
    final List<String> categories = app.catalog.examCategories;
    final String query = _query.trim().toLowerCase();

    final List<ExamBlueprint> visible = exams.where((ExamBlueprint exam) {
      final bool matchesCategory = _category == 'All' || exam.category == _category;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      return exam.code.toLowerCase().contains(query) ||
          exam.name.toLowerCase().contains(query) ||
          exam.fullName.toLowerCase().contains(query) ||
          exam.body.toLowerCase().contains(query) ||
          exam.category.toLowerCase().contains(query) ||
          exam.syllabus.any(
            (ExamSyllabusPaper paper) => paper.subject.toLowerCase().contains(query),
          );
    }).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Exams',
          subtitle: '${exams.length} Indian exams · pattern, syllabus and timeline',
          icon: Icons.workspace_premium_rounded,
          accent: t.accentAmber,
          trailing: GhostButton(
            label: 'Planner',
            icon: Icons.event_note_rounded,
            onPressed: () => AppRouter.go(context, AppRouter.planner),
          ),
        ),
        GlassField(
          controller: _search,
          label: 'Find an exam',
          hint: 'UPSC, BPSC, CA, CLAT, CUET, SSC, IBPS…',
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
              color: _category == 'All' ? t.accentMagenta : t.primary,
              onTap: () => setState(() => _category = 'All'),
            ),
            for (final String category in categories)
              NeonChip(
                label: category,
                dense: true,
                color: _category == category ? t.accentMagenta : t.primary,
                onTap: () => setState(() => _category = category),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          GlassCard(
            radius: 24,
            child: EmptyState(
              title: 'No exam matches that',
              message: 'Try a code like UPSC, BPSC, CA, CLAT or CUET — or clear the filter.',
              icon: Icons.search_off_rounded,
            ),
          )
        else
          for (final ExamBlueprint exam in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExamCard(exam: exam),
            ),
      ],
    );
  }
}

/// Shared navigation helper so search, the planner and the hub all open the
/// same detail screen.
void openExamDetail(BuildContext context, ExamBlueprint? exam) {
  if (exam == null) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => ExamDetailScreen(exam: exam),
    ),
  );
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});

  final ExamBlueprint exam;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color accent = t.accent(accentFromKey(exam.accent));
    final DateTime now = DateTime.now();

    return GlassCard(
      radius: 26,
      glowColor: accent,
      glowStrength: 0.18,
      padding: const EdgeInsets.all(16),
      onTap: () => openExamDetail(context, exam),
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
                child: Icon(iconFor(exam.icon), size: 19, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            exam.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        NeonChip(label: exam.category, dense: true, color: accent),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      exam.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: t.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exam.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniStat(
                  icon: Icons.layers_rounded,
                  label: '${exam.stages.length} stages',
                  accent: accent,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.menu_book_rounded,
                  label: '${exam.syllabus.length} papers',
                  accent: accent,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.checklist_rounded,
                  label: '${exam.syllabusTopics} topics',
                  accent: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.glassBorder),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.event_available_rounded, size: 15, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exam.nextMilestoneLabel(now),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.accent});

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Row(
      children: <Widget>[
        Icon(icon, size: 13, color: accent),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- detail ---

class ExamDetailScreen extends StatefulWidget {
  const ExamDetailScreen({super.key, required this.exam});

  final ExamBlueprint exam;

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  final Set<String> _openPapers = <String>{};

  Future<void> _addToPlanner() async {
    final ActivityController activity = context.read<ActivityController>();
    final PlannerTemplate template = widget.exam.toPlannerTemplate(DateTime.now());
    for (final SyllabusSubject subject in template.subjects) {
      await activity.upsertSubject(subject);
    }
    if (!mounted) return;
    EmojiBurst.fireFrom(context, emojis: EmojiBurst.rewardEmojis, count: 10);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${template.subjects.length} syllabus papers tracked · '
          '${widget.exam.code} exam in ${template.daysOut} days',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final ExamBlueprint exam = widget.exam;
    final Color accent = t.accent(accentFromKey(exam.accent));
    final DateTime now = DateTime.now();

    final List<ExamMilestone> ordered = <ExamMilestone>[...exam.timeline]
      ..sort(
        (ExamMilestone a, ExamMilestone b) =>
            a.nextOccurrence(now).compareTo(b.nextOccurrence(now)),
      );
    final DateTime? examDate = exam.nextExamDate(now);
    final int daysToExam = exam.daysUntil(examDate, now);
    final String examWindow =
        examDate == null ? 'Cycle not announced' : ExamMilestone.monthYear(examDate);

    return GlassScaffold(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 16, 4),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
                ),
                Expanded(
                  child: Text(
                    exam.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                NeonChip(label: exam.category, dense: true, color: accent),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
              children: <Widget>[
                _HeroCard(exam: exam, accent: accent),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatTile(
                        label: 'Next exam',
                        value: daysToExam < 0 ? '—' : '${daysToExam}d',
                        caption: examWindow,
                        icon: Icons.timer_rounded,
                        accent: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'Merit marks',
                        value: exam.meritMarks > 0 ? '${exam.meritMarks}' : '—',
                        caption: '${exam.stages.length} stages',
                        icon: Icons.insights_rounded,
                        accent: t.accentCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlowButton(
                  label: 'Add syllabus to Exam Planner',
                  icon: Icons.playlist_add_check_rounded,
                  gradient: <Color>[accent, t.accentMagenta],
                  onPressed: _addToPlanner,
                ),
                const SizedBox(height: 22),

                // ------------------------------------------------ timeline --
                SectionHeader(
                  title: 'Timeline',
                  subtitle: 'How the ${exam.code} cycle repeats every year',
                  icon: Icons.timeline_rounded,
                  accent: t.accentAmber,
                ),
                GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < ordered.length; i++)
                        _TimelineRow(
                          milestone: ordered[i],
                          isNext: i == 0,
                          year: ordered[i].nextOccurrence(now).year,
                          accent: accent,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ------------------------------------------------- pattern --
                SectionHeader(
                  title: 'Exam pattern',
                  subtitle: exam.patternSummary,
                  icon: Icons.grid_view_rounded,
                  accent: t.accentCyan,
                ),
                for (final ExamStage stage in exam.stages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StageCard(stage: stage, accent: accent),
                  ),
                const SizedBox(height: 10),

                // ------------------------------------------------ syllabus --
                SectionHeader(
                  title: 'Syllabus',
                  subtitle: '${exam.syllabus.length} papers · ${exam.syllabusTopics} topics',
                  icon: Icons.menu_book_rounded,
                  accent: t.accentViolet,
                ),
                for (final ExamSyllabusPaper paper in exam.syllabus)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SyllabusCard(
                      paper: paper,
                      accent: accent,
                      open: _openPapers.contains(paper.subject),
                      onToggle: () => setState(() {
                        if (_openPapers.contains(paper.subject)) {
                          _openPapers.remove(paper.subject);
                        } else {
                          _openPapers.add(paper.subject);
                        }
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.exam, required this.accent});

  final ExamBlueprint exam;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Icon(iconFor(exam.icon), size: 22, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      exam.name,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      exam.body,
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              NeonChip(label: exam.level, dense: true, color: accent),
              if (exam.mode.isNotEmpty)
                NeonChip(
                  label: exam.mode,
                  dense: true,
                  icon: Icons.devices_rounded,
                  color: t.accentCyan,
                ),
              if (exam.website.isNotEmpty)
                NeonChip(
                  label: exam.website,
                  dense: true,
                  icon: Icons.language_rounded,
                  color: t.accentMint,
                ),
              NeonChip(
                label: '~${exam.dailyHours}h/day',
                dense: true,
                icon: Icons.schedule_rounded,
                color: t.accentAmber,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            exam.about,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 12.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (exam.eligibility.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _LabelledText(label: 'Eligibility', value: exam.eligibility, accent: accent),
          ],
          if (exam.attempts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _LabelledText(label: 'Attempts', value: exam.attempts, accent: accent),
          ],
        ],
      ),
    );
  }
}

class _LabelledText extends StatelessWidget {
  const _LabelledText({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.5),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.milestone,
    required this.isNext,
    required this.year,
    required this.accent,
  });

  final ExamMilestone milestone;
  final bool isNext;
  final int year;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color c = milestone.kind == ExamMilestoneKind.exam ? t.accentMagenta : accent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isNext ? c.withValues(alpha: 0.28) : t.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isNext ? c : t.glassBorder),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  milestone.monthName.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    color: isNext ? t.textPrimary : t.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '$year',
                  style: TextStyle(
                    color: isNext ? t.textPrimary : t.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        milestone.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeonChip(
                      label: milestone.kind.label,
                      dense: true,
                      icon: iconFor(milestone.kind.iconKey),
                      color: c,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  milestone.window,
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (milestone.note.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    milestone.note,
                    style: TextStyle(color: t.textMuted, fontSize: 11, height: 1.45),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage, required this.accent});

  final ExamStage stage;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 22,
      glowColor: accent,
      glowStrength: 0.12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  stage.name,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              NeonChip(
                label: stage.merit ? 'Counts for merit' : 'Qualifying',
                dense: true,
                color: stage.merit ? t.accentMint : t.accentAmber,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Fact(icon: Icons.style_rounded, label: stage.type, accent: accent),
              if (stage.mode.isNotEmpty)
                _Fact(icon: Icons.devices_rounded, label: stage.mode, accent: accent),
              if (stage.questions > 0)
                _Fact(
                  icon: Icons.help_outline_rounded,
                  label: '${stage.questions} questions',
                  accent: accent,
                ),
              if (stage.marks > 0)
                _Fact(icon: Icons.star_rounded, label: '${stage.marks} marks', accent: accent),
              if (stage.minutes > 0)
                _Fact(
                  icon: Icons.hourglass_bottom_rounded,
                  label: stage.durationLabel,
                  accent: accent,
                ),
              _Fact(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Negative: ${stage.negative}',
                accent: t.danger,
              ),
            ],
          ),
          if (stage.note.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: t.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.glassBorder),
              ),
              child: Text(
                stage.note,
                style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.5),
              ),
            ),
          ],
          if (stage.sections.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'SECTIONS',
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            for (final ExamSection section in stage.sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SectionRow(section: section),
              ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.accent});

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: t.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.section});

  final ExamSection section;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final List<String> meta = <String>[
      if (section.questions > 0) '${section.questions} Q',
      if (section.marks > 0) '${section.marks} marks',
      if (section.minutes > 0) '${section.minutes} min',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            section.name,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          meta.join(' · '),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: t.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SyllabusCard extends StatelessWidget {
  const _SyllabusCard({
    required this.paper,
    required this.accent,
    required this.open,
    required this.onToggle,
  });

  final ExamSyllabusPaper paper;
  final Color accent;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 20,
      glowColor: accent,
      glowStrength: 0.1,
      padding: const EdgeInsets.all(14),
      onTap: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  paper.subject,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (paper.marks > 0)
                NeonChip(label: '${paper.marks} marks', dense: true, color: accent),
              Icon(
                open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 18,
                color: t.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              if (paper.stage.isNotEmpty) ...<Widget>[
                Icon(Icons.flag_rounded, size: 12, color: t.textMuted),
                const SizedBox(width: 5),
                Text(
                  paper.stage,
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Icon(Icons.checklist_rounded, size: 12, color: t.textMuted),
              const SizedBox(width: 5),
              Text(
                '${paper.topics.length} topics',
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (open) ...<Widget>[
            const SizedBox(height: 12),
            for (int i = 0; i < paper.topics.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${i + 1}.',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        paper.topics[i],
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 11.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
