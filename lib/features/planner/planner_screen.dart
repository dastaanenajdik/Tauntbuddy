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
import '../../data/models/catalog.dart';
import '../../data/models/exam.dart';
import '../../data/models/study_task.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';

/// Exam Planner (PRO): syllabus tracking, exam countdowns and a structured
/// study timeline. One tap applies a template from the dataset; everything else
/// is editable and stored locally.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;

    final bool isPro = app.isPro;
    final List<SyllabusSubject> subjects = activity.subjects;
    final List<StudyTask> todayTasks = activity.tasksOn(DayKey.today());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Exam Planner',
          subtitle: 'Syllabus tracking, countdowns and study timeline',
          icon: Icons.event_note_rounded,
          accent: t.accentCyan,
          trailing: isPro ? null : const ProBadge(locked: true),
        ),
        if (!isPro) _ProTeaser(onUnlock: () => app.updateSettings(app.settings.copyWith(proUnlocked: true))),
        if (!isPro) const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'Syllabus done',
                value: '${(activity.syllabusProgress * 100).round()}%',
                caption: '${subjects.length} subjects',
                icon: Icons.menu_book_rounded,
                accent: t.accentCyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Next exam',
                value: activity.nextExam == null ? '—' : '${activity.nextExam!.daysToExam}d',
                caption: activity.nextExam?.name ?? 'No date set',
                icon: Icons.timer_rounded,
                accent: t.accentMagenta,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Syllabus tracker',
          subtitle: subjects.isEmpty ? 'Add a subject to start' : 'Tap + to log a finished unit',
          icon: Icons.checklist_rtl_rounded,
          trailing: GhostButton(
            label: 'Add',
            icon: Icons.add_rounded,
            onPressed: () => _showSubjectSheet(context, activity),
          ),
        ),
        if (subjects.isEmpty)
          GlassCard(
            radius: 24,
            child: EmptyState(
              title: 'No subjects yet',
              message: 'Add your subjects with unit counts and exam dates — TauntBuddy '
                  'will compute exactly how many units a day you need.',
              icon: Icons.menu_book_rounded,
              action: GlowButton(
                label: 'Apply a template',
                icon: Icons.auto_awesome_rounded,
                compact: true,
                expand: false,
                onPressed: () => _applyFirstTemplate(context, app, activity),
              ),
            ),
          )
        else
          Column(
            children: <Widget>[
              for (final SyllabusSubject subject in subjects)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SubjectCard(
                    subject: subject,
                    onBump: (int delta) => activity.bumpUnit(subject.id, delta),
                    onDelete: () => activity.deleteSubject(subject.id),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        SectionHeader(
          title: 'Templates',
          subtitle: 'Prebuilt plans from the dataset',
          icon: Icons.auto_awesome_rounded,
          trailing: GhostButton(
            label: 'Exam Hub',
            icon: Icons.workspace_premium_rounded,
            onPressed: () => AppRouter.go(context, AppRouter.exams),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final PlannerTemplate template in app.catalog.plannerTemplates)
              NeonChip(
                label: '${template.title} · ${template.daysOut}d',
                icon: Icons.playlist_add_rounded,
                dense: true,
                onTap: () => _applyTemplate(context, activity, template),
              ),
            for (final PlannerTemplate template in _examTemplates(app))
              NeonChip(
                label: '${template.exam} · ${template.daysOut}d',
                icon: Icons.workspace_premium_rounded,
                dense: true,
                color: context.tokens.accentAmber,
                onTap: () => _applyTemplate(context, activity, template),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Today\'s plan',
          subtitle: '${todayTasks.length} task(s) scheduled',
          icon: Icons.today_rounded,
          trailing: GhostButton(
            label: 'Add task',
            icon: Icons.add_rounded,
            onPressed: () => _showTaskSheet(context, activity),
          ),
        ),
        if (todayTasks.isEmpty)
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                const HamsterMascot(size: 62, pose: MascotPose.thinking, showShell: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nothing scheduled for today. A plan without a task is just a wish.',
                    style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.45),
                  ),
                ),
              ],
            ),
          )
        else
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < todayTasks.length; i++) ...<Widget>[
                  _TaskTile(
                    task: todayTasks[i],
                    onToggle: () async {
                      await activity.toggleTask(todayTasks[i].id);
                      if (context.mounted) {
                        EmojiBurst.fireFrom(context, emojis: EmojiBurst.rewardEmojis, count: 8);
                      }
                    },
                    onDelete: () => activity.deleteTask(todayTasks[i].id),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// The exams with the nearest cycle become one-tap planner templates straight
  /// from the Exam Hub dataset (amber chips, sorted by days out).
  List<PlannerTemplate> _examTemplates(AppState app) {
    final DateTime now = DateTime.now();
    final List<PlannerTemplate> templates = app.catalog.exams
        .map((ExamBlueprint exam) => exam.toPlannerTemplate(now))
        .toList(growable: true)
      ..sort((PlannerTemplate a, PlannerTemplate b) => a.daysOut.compareTo(b.daysOut));
    return templates.take(6).toList(growable: false);
  }

  Future<void> _applyFirstTemplate(
    BuildContext context,
    AppState app,
    ActivityController activity,
  ) async {
    if (app.catalog.plannerTemplates.isEmpty) return;
    await _applyTemplate(context, activity, app.catalog.plannerTemplates.first);
  }

  Future<void> _applyTemplate(
    BuildContext context,
    ActivityController activity,
    PlannerTemplate template,
  ) async {
    final DateTime examDate = DateTime.now().add(Duration(days: template.daysOut));
    for (final SyllabusSubject subject in template.subjects) {
      await activity.upsertSubject(
        subject.copyWith(examDate: examDate),
      );
    }
    if (!context.mounted) return;
    EmojiBurst.fireFrom(context, emojis: EmojiBurst.rewardEmojis, count: 10);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${template.title} applied · exam in ${template.daysOut} days'),
        backgroundColor: context.tokens.surfaceHigh,
      ),
    );
  }

  void _showSubjectSheet(BuildContext context, ActivityController activity) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => _AddSubjectSheet(activity: activity),
    );
  }

  void _showTaskSheet(BuildContext context, ActivityController activity) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => _AddTaskSheet(activity: activity),
    );
  }
}

class _ProTeaser extends StatelessWidget {
  const _ProTeaser({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 24,
      glowColor: t.accentAmber,
      glowStrength: 0.28,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          const HamsterMascot(size: 66, pose: MascotPose.celebrate, showShell: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'Exam Planner PRO',
                      style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    const ProBadge(),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Templates, per-day unit maths and exam countdown alerts. '
                  'Unlock locally — no payment, this is a demo build.',
                  style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                GlowButton(
                  label: 'Unlock PRO',
                  icon: Icons.lock_open_rounded,
                  compact: true,
                  expand: false,
                  gradient: <Color>[t.accentAmber, t.accentMagenta],
                  onPressed: onUnlock,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onBump, required this.onDelete});

  final SyllabusSubject subject;
  final ValueChanged<int> onBump;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color accent = t.accent(accentFromKey(subject.accent));

    return GlassCard(
      radius: 22,
      glowColor: accent,
      glowStrength: 0.16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  subject.name,
                  style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              if (subject.examDate != null)
                NeonChip(
                  label: '${subject.daysToExam}d',
                  icon: Icons.timer_rounded,
                  dense: true,
                  color: subject.daysToExam <= 7 ? t.danger : t.accentMagenta,
                ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, size: 17, color: t.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${subject.completedUnits}/${subject.totalUnits} units · '
            '${(subject.progress * 100).round()}%'
            '${subject.daysToExam < 900 && subject.unitsPerDayToFinish > 0 ? ' · ${subject.unitsPerDayToFinish} unit/day to finish' : ''}',
            style: TextStyle(color: t.textMuted, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          NeonProgressBar(progress: subject.progress, colors: <Color>[accent, t.accentCyan]),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              GhostButton(
                label: 'Undo',
                icon: Icons.remove_rounded,
                onPressed: () => onBump(-1),
              ),
              const SizedBox(width: 8),
              GhostButton(
                label: 'Unit done',
                icon: Icons.add_rounded,
                color: accent,
                onPressed: () => onBump(1),
              ),
              const Spacer(),
              if (subject.examDate != null)
                Text(
                  AppDateUtils.prettyDate(subject.examDate),
                  style: TextStyle(color: t.textMuted, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onToggle, required this.onDelete});

  final StudyTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.done ? t.accentMint.withValues(alpha: 0.32) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: task.done ? t.accentMint : t.textMuted,
                  width: 1.4,
                ),
              ),
              child: task.done ? Icon(Icons.check_rounded, size: 15, color: t.accentMint) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${task.kind.emoji} ${task.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: task.done ? t.accentMint : t.textPrimary,
                    fontSize: 13,
                    fontWeight: task.done ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${task.subject} · ${task.estimatedMinutes}m · '
                  '${task.priority == 3 ? 'high' : task.priority == 2 ? 'normal' : 'low'} priority',
                  style: TextStyle(color: t.textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.close_rounded, size: 16, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AddSubjectSheet extends StatefulWidget {
  const _AddSubjectSheet({required this.activity});

  final ActivityController activity;

  @override
  State<_AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends State<_AddSubjectSheet> {
  final TextEditingController _name = TextEditingController();
  int _units = 5;
  int _daysOut = 21;

  @override
  void dispose() {
    _name.dispose();
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
              'Add a subject',
              style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            GlassField(controller: _name, label: 'Subject', hint: 'Operating Systems'),
            const SizedBox(height: 14),
            Text(
              'UNITS: $_units',
              style: TextStyle(color: t.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            Slider(
              value: _units.toDouble(),
              min: 1,
              max: 15,
              divisions: 14,
              activeColor: t.primary,
              label: '$_units units',
              onChanged: (double value) => setState(() => _units = value.round()),
            ),
            Text(
              'EXAM IN: $_daysOut DAYS',
              style: TextStyle(color: t.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            Slider(
              value: _daysOut.toDouble(),
              min: 1,
              max: 120,
              divisions: 119,
              activeColor: t.accentCyan,
              label: '$_daysOut days',
              onChanged: (double value) => setState(() => _daysOut = value.round()),
            ),
            const SizedBox(height: 10),
            GlowButton(
              label: 'Save subject',
              icon: Icons.save_rounded,
              onPressed: () async {
                if (_name.text.trim().isEmpty) return;
                await widget.activity.addSubject(
                  name: _name.text,
                  totalUnits: _units,
                  examDate: DateTime.now().add(Duration(days: _daysOut)),
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

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({required this.activity});

  final ActivityController activity;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final TextEditingController _title = TextEditingController();
  StudyTaskKind _kind = StudyTaskKind.revision;
  int _minutes = 45;
  int _priority = 2;

  @override
  void dispose() {
    _title.dispose();
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
              'Plan a task for today',
              style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            GlassField(controller: _title, label: 'Task', hint: 'Solve 2 PYQs of CN'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final StudyTaskKind kind in StudyTaskKind.values)
                  NeonChip(
                    label: kind.label,
                    emoji: kind.emoji,
                    dense: true,
                    color: _kind == kind ? t.accentMagenta : t.primary,
                    onTap: () => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedNeonPicker(
              options: const <String>['30m', '45m', '90m'],
              selectedIndex: _minutes == 30 ? 0 : _minutes == 45 ? 1 : 2,
              onSelected: (int index) => setState(() => _minutes = <int>[30, 45, 90][index]),
            ),
            const SizedBox(height: 12),
            SegmentedNeonPicker(
              options: const <String>['Low', 'Normal', 'High'],
              selectedIndex: _priority - 1,
              accent: t.accentMagenta,
              onSelected: (int index) => setState(() => _priority = index + 1),
            ),
            const SizedBox(height: 16),
            GlowButton(
              label: 'Add to today',
              icon: Icons.add_task_rounded,
              onPressed: () async {
                if (_title.text.trim().isEmpty) return;
                await widget.activity.addTask(
                  title: _title.text,
                  kind: _kind,
                  day: DayKey.today(),
                  estimatedMinutes: _minutes,
                  priority: _priority,
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
