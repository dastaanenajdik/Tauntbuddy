import '../../core/utils/app_date_utils.dart';

/// What kind of entry the planner/timeline row is.
enum StudyTaskKind { task, revision, exam, class_, project }

StudyTaskKind studyTaskKindFromKey(String? key) {
  switch ((key ?? '').toLowerCase()) {
    case 'revision':
      return StudyTaskKind.revision;
    case 'exam':
      return StudyTaskKind.exam;
    case 'class':
      return StudyTaskKind.class_;
    case 'project':
      return StudyTaskKind.project;
    case 'task':
    default:
      return StudyTaskKind.task;
  }
}

extension StudyTaskKindX on StudyTaskKind {
  String get key {
    switch (this) {
      case StudyTaskKind.task:
        return 'task';
      case StudyTaskKind.revision:
        return 'revision';
      case StudyTaskKind.exam:
        return 'exam';
      case StudyTaskKind.class_:
        return 'class';
      case StudyTaskKind.project:
        return 'project';
    }
  }

  String get label {
    switch (this) {
      case StudyTaskKind.task:
        return 'Task';
      case StudyTaskKind.revision:
        return 'Revision';
      case StudyTaskKind.exam:
        return 'Exam';
      case StudyTaskKind.class_:
        return 'Class';
      case StudyTaskKind.project:
        return 'Project';
    }
  }

  String get emoji {
    switch (this) {
      case StudyTaskKind.task:
        return '📝';
      case StudyTaskKind.revision:
        return '🔁';
      case StudyTaskKind.exam:
        return '🎯';
      case StudyTaskKind.class_:
        return '🏫';
      case StudyTaskKind.project:
        return '🛠️';
    }
  }
}

/// A single planner entry (task / revision slot / exam / class).
class StudyTask {
  const StudyTask({
    required this.id,
    required this.title,
    required this.kind,
    required this.day,
    this.subject = 'General',
    this.done = false,
    this.priority = 2,
    this.estimatedMinutes = 45,
    this.notes = '',
  });

  final String id;
  final String title;
  final StudyTaskKind kind;
  final DayKey day;
  final String subject;
  final bool done;

  /// 1 = chill, 2 = normal, 3 = must do today.
  final int priority;
  final int estimatedMinutes;
  final String notes;

  bool get isOverdue => !done && day.daysUntil(DayKey.today()) < 0;

  StudyTask copyWith({
    String? title,
    StudyTaskKind? kind,
    DayKey? day,
    String? subject,
    bool? done,
    int? priority,
    int? estimatedMinutes,
    String? notes,
  }) {
    return StudyTask(
      id: id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      day: day ?? this.day,
      subject: subject ?? this.subject,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'kind': kind.key,
        'day': day.id,
        'subject': subject,
        'done': done,
        'priority': priority,
        'estimatedMinutes': estimatedMinutes,
        'notes': notes,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      id: (json['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: (json['title'] as String?) ?? 'Untitled',
      kind: studyTaskKindFromKey(json['kind'] as String?),
      day: DayKey.parse((json['day'] as String?) ?? DayKey.today().id),
      subject: (json['subject'] as String?) ?? 'General',
      done: (json['done'] as bool?) ?? false,
      priority: ((json['priority'] as num?)?.toInt() ?? 2).clamp(1, 3),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 45,
      notes: (json['notes'] as String?) ?? '',
    );
  }
}

/// One syllabus subject with unit-level progress — the heart of the Exam
/// Planner's tracking view.
class SyllabusSubject {
  const SyllabusSubject({
    required this.id,
    required this.name,
    required this.totalUnits,
    this.completedUnits = 0,
    this.examDate,
    this.accent = 'violet',
    this.mentor = '',
  });

  final String id;
  final String name;
  final int totalUnits;
  final int completedUnits;
  final DateTime? examDate;
  final String accent;
  final String mentor;

  double get progress => AppDateUtils.ratio(completedUnits, totalUnits);

  int get daysToExam {
    if (examDate == null) return 999;
    final DateTime now = DateTime.now();
    return DateTime(examDate!.year, examDate!.month, examDate!.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  int get unitsPerDayToFinish {
    final int days = daysToExam;
    final int left = totalUnits - completedUnits;
    if (left <= 0) return 0;
    if (days <= 0) return left;
    return (left / days).ceil();
  }

  SyllabusSubject copyWith({
    String? name,
    int? totalUnits,
    int? completedUnits,
    DateTime? examDate,
    String? accent,
    String? mentor,
  }) {
    return SyllabusSubject(
      id: id,
      name: name ?? this.name,
      totalUnits: totalUnits ?? this.totalUnits,
      completedUnits: completedUnits ?? this.completedUnits,
      examDate: examDate ?? this.examDate,
      accent: accent ?? this.accent,
      mentor: mentor ?? this.mentor,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'totalUnits': totalUnits,
        'completedUnits': completedUnits,
        'examDate': examDate?.toIso8601String(),
        'accent': accent,
        'mentor': mentor,
      };

  factory SyllabusSubject.fromJson(Map<String, dynamic> json) {
    return SyllabusSubject(
      id: (json['id'] as String?) ?? json['name'].toString(),
      name: (json['name'] as String?) ?? 'Subject',
      totalUnits: ((json['totalUnits'] as num?)?.toInt() ?? 5).clamp(1, 99),
      completedUnits: ((json['completedUnits'] as num?)?.toInt() ?? 0).clamp(0, 99),
      examDate: json['examDate'] is String ? DateTime.tryParse(json['examDate'] as String) : null,
      accent: (json['accent'] as String?) ?? 'violet',
      mentor: (json['mentor'] as String?) ?? '',
    );
  }

  factory SyllabusSubject.fromSeed(Map<String, dynamic> json) {
    return SyllabusSubject(
      id: (json['name'] as String? ?? 'subject').toLowerCase().replaceAll(' ', '-'),
      name: (json['name'] as String?) ?? 'Subject',
      totalUnits: ((json['units'] as num?)?.toInt() ?? 5).clamp(1, 99),
      completedUnits: ((((json['progress'] as num?)?.toDouble() ?? 0) *
                  ((json['units'] as num?)?.toInt() ?? 5))
              .round())
          .clamp(0, 99),
    );
  }
}
