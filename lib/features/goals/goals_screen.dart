import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/tracking.dart';
import '../../state/activity_controller.dart';

/// Today's goals — small, finishable items that keep the streak alive.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;
    final List<DailyGoal> goals = activity.goalsOn(DayKey.today());
    final int done = goals.where((DailyGoal g) => g.done).length;
    final int total = goals.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: "Today's goals",
          subtitle: DateKeyLabel.of(DayKey.today()),
          icon: Icons.checklist_rounded,
          accent: t.accentMint,
          trailing: GhostButton(
            label: 'Add',
            icon: Icons.add_rounded,
            onPressed: () => _showAddSheet(context, activity),
          ),
        ),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              MetricRing(
                progress: AppDateUtils.ratio(done, total),
                value: '$done/$total',
                label: 'DONE',
                size: 78,
                stroke: 7,
                colors: <Color>[t.accentMint, t.accentCyan],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  total == 0
                      ? 'Add your first goal. Keep it stupidly small — 25 minutes of '
                          'revision counts.'
                      : done == total
                          ? 'All closed. Genuinely, well done. 🎉'
                          : '${total - done} remaining today. Tick them before the day flips.',
                  style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (goals.isEmpty)
          GlassCard(
            radius: 24,
            child: EmptyState(
              title: 'No goals for today',
              message: 'The hamster works best with a checklist. Add one or two.',
              icon: Icons.checklist_rounded,
              action: GlowButton(
                label: 'Add a goal',
                icon: Icons.add_rounded,
                compact: true,
                expand: false,
                onPressed: () => _showAddSheet(context, activity),
              ),
            ),
          )
        else
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < goals.length; i++) ...<Widget>[
                  _GoalTile(
                    title: goals[i].title,
                    done: goals[i].done,
                    accent: t.accent(accentFromKey(goals[i].accent)),
                    category: goals[i].category,
                    onToggle: () async {
                      final bool wasDone = goals[i].done;
                      await activity.toggleGoal(goals[i].id);
                      if (context.mounted && !wasDone) {
                        EmojiBurst.fireFrom(context, emojis: EmojiBurst.rewardEmojis, count: 9);
                      }
                    },
                    onDelete: () => activity.deleteGoal(goals[i].id),
                  ),
                  if (i != goals.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: NeonDivider(opacity: 0.12),
                    ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Starter goals',
          subtitle: 'Tap to add them to today',
          icon: Icons.auto_awesome_rounded,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String title in <String>[
              'One 25 minute Ekagra block',
              'Revise yesterday\'s notes',
              'Solve 2 previous year questions',
              '10 minute Dhyan reset',
              'No phone for the first hour',
            ])
              NeonChip(
                label: title,
                icon: Icons.add_rounded,
                dense: true,
                onTap: () => activity.addGoal(title),
              ),
          ],
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context, ActivityController activity) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => _AddGoalSheet(activity: activity),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet({required this.activity});

  final ActivityController activity;

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final TextEditingController _title = TextEditingController();
  String _category = 'study';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
      child: GlassCard(
        radius: 26,
        glowStrength: 0.3,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'New goal for today',
              style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            GlassField(
              controller: _title,
              label: 'Goal',
              hint: 'Finish DBMS unit 3',
            ),
            const SizedBox(height: 14),
            Text(
              'CATEGORY',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final String category in <String>['study', 'revision', 'wellbeing', 'admin'])
                  NeonChip(
                    label: category,
                    dense: true,
                    color: _category == category ? t.accentMagenta : t.primary,
                    onTap: () => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            GlowButton(
              label: 'Add goal',
              icon: Icons.add_rounded,
              onPressed: () async {
                if (_title.text.trim().isEmpty) return;
                await widget.activity.addGoal(_title.text, category: _category);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.title,
    required this.done,
    required this.accent,
    required this.category,
    required this.onToggle,
    required this.onDelete,
  });

  final String title;
  final bool done;
  final Color accent;
  final String category;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? accent.withValues(alpha: 0.28) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: done ? accent : t.textMuted.withValues(alpha: 0.5)),
              ),
              child: done ? Icon(Icons.check_rounded, size: 15, color: accent) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: done ? t.textMuted : t.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    category,
                    style: TextStyle(color: t.textMuted, fontSize: 10.5, letterSpacing: 0.4),
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
      ),
    );
  }
}

/// Tiny helper so the header subtitle can show a friendly date.
class DateKeyLabel {
  const DateKeyLabel._();

  static String of(DayKey day) => day.long;
}
