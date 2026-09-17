import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../data/models/study_task.dart';
import '../../state/activity_controller.dart';
import '../../state/app_state.dart';

/// Timeline & Clock: a live clock, the day as blocks, and today's tasks.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ActivityController activity = context.watch<ActivityController>();
    final AppTokens t = context.tokens;

    final int nowMinutes = _now.hour * 60 + _now.minute;
    final List<TimelineBlock> blocks = <TimelineBlock>[...app.catalog.timelineBlocks]
      ..sort((TimelineBlock a, TimelineBlock b) => a.startMinutes.compareTo(b.startMinutes));
    final List<StudyTask> tasks = activity.tasksOn(DayKey.today());

    TimelineBlock? current;
    TimelineBlock? next;
    for (final TimelineBlock block in blocks) {
      if (nowMinutes >= block.startMinutes && nowMinutes < block.endMinutes) {
        current = block;
      } else if (block.startMinutes > nowMinutes && next == null) {
        next = block;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Timeline & Clock',
          subtitle: DayKey.today().long,
          icon: Icons.schedule_rounded,
          accent: t.accentAmber,
        ),
        GlassCard(
          radius: 28,
          glowColor: t.accentAmber,
          glowStrength: 0.28,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Text(
                AppDateUtils.clockWithSeconds(_now),
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                current == null
                    ? (next == null
                        ? 'No block scheduled — free study time.'
                        : 'Next: ${next.title} at ${_label(next.startMinutes)}')
                    : 'Now: ${current.title} · until ${_label(current.endMinutes)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 14),
              NeonProgressBar(
                progress: nowMinutes / (24 * 60),
                colors: <Color>[t.accentAmber, t.accentMagenta],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('00:00', style: TextStyle(color: t.textMuted, fontSize: 9.5)),
                  Text('12:00', style: TextStyle(color: t.textMuted, fontSize: 9.5)),
                  Text('24:00', style: TextStyle(color: t.textMuted, fontSize: 9.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'The day as blocks',
          subtitle: '${blocks.length} planned · tap a block to plan a task',
          icon: Icons.view_timeline_rounded,
        ),
        for (final TimelineBlock block in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BlockRow(
              block: block,
              isNow: current?.id == block.id,
              isPast: nowMinutes >= block.endMinutes,
              onTap: () => activity.addTask(
                title: '${block.title} block',
                kind: StudyTaskKind.task,
                day: DayKey.today(),
                estimatedMinutes: block.durationMinutes,
                subject: block.kind,
              ),
            ),
          ),
        const SizedBox(height: 8),
        SectionHeader(
          title: 'Tasks for today',
          subtitle: tasks.isEmpty ? 'Nothing planned yet' : '${tasks.length} task(s)',
          icon: Icons.checklist_rounded,
        ),
        if (tasks.isEmpty)
          const GlassCard(
            radius: 22,
            child: EmptyState(
              title: 'No tasks',
              message: 'Tap any block above to drop it into today\'s task list.',
              icon: Icons.checklist_rounded,
            ),
          )
        else
          GlassCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < tasks.length; i++) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => activity.toggleTask(tasks[i].id),
                          child: Icon(
                            tasks[i].done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 19,
                            color: tasks[i].done ? t.accentMint : t.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${tasks[i].kind.emoji} ${tasks[i].title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tasks[i].done ? t.accentMint : t.textPrimary,
                              fontSize: 13,
                              fontWeight: tasks[i].done ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${tasks[i].estimatedMinutes}m',
                          style: TextStyle(color: t.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  String _label(int minutes) {
    final int hour = minutes ~/ 60;
    final int minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({
    required this.block,
    required this.isNow,
    required this.isPast,
    required this.onTap,
  });

  final TimelineBlock block;
  final bool isNow;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color accent = t.accent(accentFromKey(block.accent));

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      glowColor: accent,
      glowStrength: isNow ? 0.35 : 0.1,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: isPast ? t.accentGrey : accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  block.title,
                  style: TextStyle(
                    color: isPast ? t.textMuted : t.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_time(block.startMinutes)} – ${_time(block.endMinutes)} · '
                  '${block.durationMinutes}m · ${block.kind}',
                  style: TextStyle(color: t.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (isNow)
            NeonChip(label: 'NOW', dense: true, color: t.accentMint)
          else if (isPast)
            Icon(Icons.check_rounded, size: 16, color: t.accentGrey)
          else
            Icon(Icons.schedule_rounded, size: 15, color: t.textMuted),
        ],
      ),
    );
  }

  String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
