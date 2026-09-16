import '../../core/utils/app_date_utils.dart';

/// One of the "Today's Mood" options exposed on the dashboard.
class MoodOption {
  const MoodOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.score,
  });

  final String id;
  final String label;
  final String emoji;

  /// 1 (rough day) – 5 (locked in). Used for the monthly mood curve.
  final int score;

  factory MoodOption.fromJson(Map<String, dynamic> json) => MoodOption(
        id: (json['id'] as String?) ?? 'okay',
        label: (json['label'] as String?) ?? 'Okay',
        emoji: (json['emoji'] as String?) ?? '🙂',
        score: ((json['score'] as num?)?.toInt() ?? 3).clamp(1, 5),
      );

  static const List<MoodOption> fallback = <MoodOption>[
    MoodOption(id: 'focused', label: 'Focused', emoji: '🎯', score: 5),
    MoodOption(id: 'calm', label: 'Calm', emoji: '🌊', score: 4),
    MoodOption(id: 'okay', label: 'Okay', emoji: '🙂', score: 3),
    MoodOption(id: 'tired', label: 'Tired', emoji: '😮‍💨', score: 2),
    MoodOption(id: 'stressed', label: 'Stressed', emoji: '😵‍💫', score: 2),
    MoodOption(id: 'burnt', label: 'Burnt out', emoji: '🥀', score: 1),
  ];
}

/// A single day's check-in.
class MoodEntry {
  const MoodEntry({
    required this.day,
    required this.moodId,
    this.note = '',
    this.score = 3,
  });

  final DayKey day;
  final String moodId;
  final String note;
  final int score;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'day': day.id,
        'moodId': moodId,
        'note': note,
        'score': score,
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        day: DayKey.parse((json['day'] as String?) ?? DayKey.today().id),
        moodId: (json['moodId'] as String?) ?? 'okay',
        note: (json['note'] as String?) ?? '',
        score: ((json['score'] as num?)?.toInt() ?? 3).clamp(1, 5),
      );
}

/// A checkable goal for a given day. Closing goals is what keeps the streak.
class DailyGoal {
  const DailyGoal({
    required this.id,
    required this.title,
    required this.day,
    this.done = false,
    this.accent = 'violet',
    this.category = 'study',
    this.targetMinutes = 0,
  });

  final String id;
  final String title;
  final DayKey day;
  final bool done;
  final String accent;

  /// study / revision / wellbeing / admin
  final String category;

  /// Optional focus target that links the goal to Ekagra minutes.
  final int targetMinutes;

  DailyGoal copyWith({String? title, bool? done, String? accent, String? category, int? targetMinutes}) {
    return DailyGoal(
      id: id,
      title: title ?? this.title,
      day: day,
      done: done ?? this.done,
      accent: accent ?? this.accent,
      category: category ?? this.category,
      targetMinutes: targetMinutes ?? this.targetMinutes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'day': day.id,
        'done': done,
        'accent': accent,
        'category': category,
        'targetMinutes': targetMinutes,
      };

  factory DailyGoal.fromJson(Map<String, dynamic> json) => DailyGoal(
        id: (json['id'] as String?) ?? 'goal',
        title: (json['title'] as String?) ?? 'Study',
        day: DayKey.parse((json['day'] as String?) ?? DayKey.today().id),
        done: (json['done'] as bool?) ?? false,
        accent: (json['accent'] as String?) ?? 'violet',
        category: (json['category'] as String?) ?? 'study',
        targetMinutes: (json['targetMinutes'] as num?)?.toInt() ?? 0,
      );

  /// Starter goals offered the first time the app opens on a new day.
  static List<DailyGoal> starter({DayKey? day}) {
    final DayKey target = day ?? DayKey.today();
    return <DailyGoal>[
      DailyGoal(id: 'starter-1', title: 'One 25 minute Ekagra block', day: target),
      DailyGoal(
        id: 'starter-2',
        title: 'Revise yesterday\'s notes',
        day: target,
        accent: 'cyan',
        category: 'revision',
      ),
      DailyGoal(
        id: 'starter-3',
        title: '10 minute Dhyan reset',
        day: target,
        accent: 'mint',
        category: 'wellbeing',
      ),
    ];
  }
}

/// Aggregated analytics for a day — computed once and reused by the dashboard,
/// the analytics screen and the taunt engine (which needs to know whether the
/// user is slacking).
class DaySummary {
  const DaySummary({
    required this.day,
    required this.focusMinutes,
    required this.dhyanMinutes,
    required this.depthScore,
    required this.sessions,
    required this.completedSessions,
    required this.goalsDone,
    required this.goalsTotal,
    required this.kavachBreaches,
  });

  final DayKey day;
  final int focusMinutes;
  final int dhyanMinutes;
  final int depthScore;
  final int sessions;
  final int completedSessions;
  final int goalsDone;
  final int goalsTotal;
  final int kavachBreaches;

  double get goalCompletion => AppDateUtils.ratio(goalsDone, goalsTotal);

  bool get isEmpty => sessions == 0 && goalsTotal == 0;
}
