import 'catalog.dart';
import 'study_task.dart';

/// Month names used to turn a milestone's month number into a readable window.
const List<String> kMonthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// What a milestone represents in the annual cycle. Drives the icon and colour
/// of each timeline row.
enum ExamMilestoneKind {
  notification,
  application,
  admitCard,
  exam,
  result,
  interview,
  counselling,
  training,
}

ExamMilestoneKind examMilestoneKindFromKey(String? key) {
  switch ((key ?? '').toLowerCase()) {
    case 'application':
    case 'apply':
      return ExamMilestoneKind.application;
    case 'admit':
    case 'admitcard':
    case 'admit_card':
      return ExamMilestoneKind.admitCard;
    case 'exam':
      return ExamMilestoneKind.exam;
    case 'result':
      return ExamMilestoneKind.result;
    case 'interview':
    case 'personality':
      return ExamMilestoneKind.interview;
    case 'counselling':
    case 'counseling':
      return ExamMilestoneKind.counselling;
    case 'training':
    case 'articleship':
      return ExamMilestoneKind.training;
    case 'notification':
    default:
      return ExamMilestoneKind.notification;
  }
}

extension ExamMilestoneKindX on ExamMilestoneKind {
  String get label {
    switch (this) {
      case ExamMilestoneKind.notification:
        return 'Notification';
      case ExamMilestoneKind.application:
        return 'Application';
      case ExamMilestoneKind.admitCard:
        return 'Admit card';
      case ExamMilestoneKind.exam:
        return 'Exam';
      case ExamMilestoneKind.result:
        return 'Result';
      case ExamMilestoneKind.interview:
        return 'Interview';
      case ExamMilestoneKind.counselling:
        return 'Counselling';
      case ExamMilestoneKind.training:
        return 'Training';
    }
  }

  String get iconKey {
    switch (this) {
      case ExamMilestoneKind.notification:
        return 'campaign';
      case ExamMilestoneKind.application:
        return 'checklist';
      case ExamMilestoneKind.admitCard:
        return 'badge';
      case ExamMilestoneKind.exam:
        return 'workspace_premium';
      case ExamMilestoneKind.result:
        return 'insights';
      case ExamMilestoneKind.interview:
        return 'person';
      case ExamMilestoneKind.counselling:
        return 'school';
      case ExamMilestoneKind.training:
        return 'hourglass';
    }
  }
}

/// One section (or sub-paper) inside an [ExamStage].
class ExamSection {
  const ExamSection({
    required this.name,
    this.questions = 0,
    this.marks = 0,
    this.minutes = 0,
  });

  final String name;
  final int questions;
  final int marks;
  final int minutes;

  factory ExamSection.fromJson(Map<String, dynamic> json) => ExamSection(
        name: (json['name'] as String?) ?? 'Section',
        questions: ((json['questions'] as num?)?.toInt() ?? 0).clamp(0, 999),
        marks: ((json['marks'] as num?)?.toInt() ?? 0).clamp(0, 9999),
        minutes: ((json['minutes'] as num?)?.toInt() ?? 0).clamp(0, 999),
      );
}

/// One stage of the selection process: Prelims, Mains, Interview, Articleship…
class ExamStage {
  const ExamStage({
    required this.name,
    required this.type,
    this.mode = '',
    this.questions = 0,
    this.marks = 0,
    this.minutes = 0,
    this.negative = 'None',
    this.merit = true,
    this.note = '',
    this.sections = const <ExamSection>[],
  });

  final String name;

  /// "Objective MCQ", "Descriptive", "Oral", "Practical training"…
  final String type;

  /// "Offline (OMR)", "Computer based test"…
  final String mode;
  final int questions;
  final int marks;
  final int minutes;

  /// Human readable penalty, e.g. "1/3 mark per wrong answer".
  final String negative;

  /// Whether the stage's marks are added to the final merit list.
  final bool merit;
  final String note;
  final List<ExamSection> sections;

  String get durationLabel {
    if (minutes <= 0) return '—';
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (hours == 0) return '$mins min';
    if (mins == 0) return hours == 1 ? '1 hour' : '$hours hours';
    return '${hours}h ${mins}m';
  }

  factory ExamStage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = (json['sections'] as List<dynamic>?) ?? const <dynamic>[];
    return ExamStage(
      name: (json['name'] as String?) ?? 'Stage',
      type: (json['type'] as String?) ?? 'Objective',
      mode: (json['mode'] as String?) ?? '',
      questions: ((json['questions'] as num?)?.toInt() ?? 0).clamp(0, 9999),
      marks: ((json['marks'] as num?)?.toInt() ?? 0).clamp(0, 9999),
      minutes: ((json['minutes'] as num?)?.toInt() ?? 0).clamp(0, 9999),
      negative: (json['negative'] as String?) ?? 'None',
      merit: (json['merit'] as bool?) ?? true,
      note: (json['note'] as String?) ?? '',
      sections: raw.whereType<Map<String, dynamic>>().map(ExamSection.fromJson).toList(growable: false),
    );
  }
}

/// A syllabus paper with the topics TauntBuddy tracks as planner units.
class ExamSyllabusPaper {
  const ExamSyllabusPaper({
    required this.subject,
    this.stage = '',
    this.marks = 0,
    this.topics = const <String>[],
  });

  final String subject;

  /// Which stage the paper belongs to ("Prelims", "Mains", "Foundation"…).
  final String stage;
  final int marks;
  final List<String> topics;

  /// Units handed to the Exam Planner: one unit per topic.
  int get plannerUnits => topics.length.clamp(1, 20);

  factory ExamSyllabusPaper.fromJson(Map<String, dynamic> json) => ExamSyllabusPaper(
        subject: (json['subject'] as String?) ?? 'Subject',
        stage: (json['stage'] as String?) ?? '',
        marks: ((json['marks'] as num?)?.toInt() ?? 0).clamp(0, 9999),
        topics: ((json['topics'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .where((String e) => e.trim().isNotEmpty)
            .toList(growable: false),
      );
}

/// One dated step of the exam's yearly cycle.
class ExamMilestone {
  const ExamMilestone({
    required this.label,
    required this.month,
    this.window = '',
    this.kind = ExamMilestoneKind.notification,
    this.note = '',
  });

  final String label;

  /// 1 – 12. The month the window usually opens in.
  final int month;

  /// Display text, e.g. "Late January – February" or "First week of May".
  final String window;
  final ExamMilestoneKind kind;
  final String note;

  /// Always in range — [month] is clamped to 1–12 when the JSON is parsed.
  String get monthName => kMonthNames[month < 1 ? 0 : (month > 12 ? 11 : month - 1)];

  /// Convenience for a parsed [DateTime]: "May 2027".
  static String monthYear(DateTime date) => '${kMonthNames[date.month - 1]} ${date.year}';

  /// When this milestone next happens, rolling into next year if it passed.
  DateTime nextOccurrence(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime thisYear = DateTime(now.year, month, 1);
    return thisYear.isBefore(today) ? DateTime(now.year + 1, month, 1) : thisYear;
  }

  factory ExamMilestone.fromJson(Map<String, dynamic> json) => ExamMilestone(
        label: (json['label'] as String?) ?? 'Milestone',
        month: ((json['month'] as num?)?.toInt() ?? 1).clamp(1, 12),
        window: (json['window'] as String?) ?? '',
        kind: examMilestoneKindFromKey(json['kind'] as String?),
        note: (json['note'] as String?) ?? '',
      );
}

/// Everything TauntBuddy knows about one Indian exam: who runs it, how the
/// paper is structured, what is in the syllabus and when the cycle repeats.
///
/// The whole list lives in `assets/data/seed_catalog.json` so adding an exam is
/// a data change, never a code change.
class ExamBlueprint {
  const ExamBlueprint({
    required this.id,
    required this.code,
    required this.name,
    this.fullName = '',
    this.body = '',
    this.category = 'National',
    this.level = 'National',
    this.about = '',
    this.eligibility = '',
    this.attempts = '',
    this.mode = '',
    this.website = '',
    this.accent = 'violet',
    this.icon = 'workspace_premium',
    this.dailyHours = 6,
    this.stages = const <ExamStage>[],
    this.syllabus = const <ExamSyllabusPaper>[],
    this.timeline = const <ExamMilestone>[],
  });

  final String id;

  /// Short label shown on cards: "UPSC CSE", "BPSC", "CA", "CLAT", "CUET UG"…
  final String code;
  final String name;
  final String fullName;

  /// Conducting body, e.g. "Union Public Service Commission".
  final String body;

  /// Filter bucket: "Civil Services", "State PSC", "Banking", "Law"…
  final String category;

  /// "National" / "State (Bihar)" / "Professional"…
  final String level;
  final String about;
  final String eligibility;
  final String attempts;
  final String mode;
  final String website;
  final String accent;
  final String icon;

  /// Recommended focused hours per day during the last stretch.
  final int dailyHours;
  final List<ExamStage> stages;
  final List<ExamSyllabusPaper> syllabus;
  final List<ExamMilestone> timeline;

  String get displayName => fullName.trim().isEmpty ? '$code · $name' : fullName;

  /// "Prelims 400 · Mains 1750 · Interview 275".
  String get patternSummary => stages
      .map((ExamStage s) => s.marks > 0 ? '${s.name} ${s.marks}' : s.name)
      .join(' · ');

  int get totalMarks => stages.fold(0, (int sum, ExamStage s) => sum + s.marks);

  int get meritMarks =>
      stages.where((ExamStage s) => s.merit).fold(0, (int sum, ExamStage s) => sum + s.marks);

  int get syllabusTopics =>
      syllabus.fold(0, (int sum, ExamSyllabusPaper p) => sum + p.topics.length);

  /// The nearest milestone of any kind, sorted by the calendar.
  ExamMilestone? nextMilestone(DateTime now) {
    ExamMilestone? best;
    DateTime? bestDate;
    for (final ExamMilestone milestone in timeline) {
      final DateTime date = milestone.nextOccurrence(now);
      if (bestDate == null || date.isBefore(bestDate)) {
        bestDate = date;
        best = milestone;
      }
    }
    return best;
  }

  /// The next written exam date, used as the planner's countdown target.
  DateTime? nextExamDate(DateTime now) {
    DateTime? best;
    for (final ExamMilestone milestone in timeline) {
      if (milestone.kind != ExamMilestoneKind.exam) continue;
      final DateTime date = milestone.nextOccurrence(now);
      if (best == null || date.isBefore(best)) best = date;
    }
    return best;
  }

  int daysUntil(DateTime? date, DateTime now) {
    if (date == null) return -1;
    final DateTime today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
  }

  /// "Prelims · May 2027 · 226 days out"
  String nextMilestoneLabel(DateTime now) {
    final ExamMilestone? milestone = nextMilestone(now);
    if (milestone == null) return 'Cycle dates not published yet';
    final DateTime date = milestone.nextOccurrence(now);
    return '${milestone.label} · ${milestone.monthName} ${date.year} · '
        '${daysUntil(date, now)} days out';
  }

  /// Turns the blueprint into an Exam Planner template: every syllabus paper
  /// becomes a tracked subject whose unit count is its topic count.
  PlannerTemplate toPlannerTemplate(DateTime now) {
    final DateTime? examDate = nextExamDate(now) ?? nextMilestone(now)?.nextOccurrence(now);
    final DateTime target = examDate ?? now.add(const Duration(days: 120));
    final int daysOut = daysUntil(target, now).clamp(1, 730);

    return PlannerTemplate(
      id: 'exam-$id',
      title: '$code · ${timeline.isEmpty ? 'next cycle' : 'next exam'}',
      exam: code,
      daysOut: daysOut,
      subjects: syllabus
          .map(
            (ExamSyllabusPaper paper) => SyllabusSubject(
              id: '$id-${paper.subject.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
              name: paper.subject,
              totalUnits: paper.plannerUnits,
              examDate: target,
              accent: accent,
              mentor: body,
            ),
          )
          .toList(growable: false),
    );
  }

  factory ExamBlueprint.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) build) {
      final List<dynamic> raw = (json[key] as List<dynamic>?) ?? const <dynamic>[];
      return raw.whereType<Map<String, dynamic>>().map(build).toList(growable: false);
    }

    return ExamBlueprint(
      id: (json['id'] as String?) ?? 'exam',
      code: (json['code'] as String?) ?? 'EXAM',
      name: (json['name'] as String?) ?? 'Exam',
      fullName: (json['fullName'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'National',
      level: (json['level'] as String?) ?? 'National',
      about: (json['about'] as String?) ?? '',
      eligibility: (json['eligibility'] as String?) ?? '',
      attempts: (json['attempts'] as String?) ?? '',
      mode: (json['mode'] as String?) ?? '',
      website: (json['website'] as String?) ?? '',
      accent: (json['accent'] as String?) ?? 'violet',
      icon: (json['icon'] as String?) ?? 'workspace_premium',
      dailyHours: ((json['dailyHours'] as num?)?.toInt() ?? 6).clamp(1, 16),
      stages: list('stages', ExamStage.fromJson),
      syllabus: list('syllabus', ExamSyllabusPaper.fromJson),
      timeline: list('timeline', ExamMilestone.fromJson),
    );
  }

  /// Never-empty floor so the Exams screen still works if the asset is missing.
  static const List<ExamBlueprint> fallback = <ExamBlueprint>[
    ExamBlueprint(
      id: 'upsc-cse',
      code: 'UPSC CSE',
      name: 'Civil Services Examination',
      fullName: 'UPSC Civil Services Examination (IAS · IPS · IFS)',
      body: 'Union Public Service Commission',
      category: 'Civil Services',
      about: 'India\'s toughest annual cycle: Prelims, nine Mains papers and a '
          'personality test that decides the service allotment.',
      icon: 'workspace_premium',
      accent: 'violet',
      dailyHours: 9,
      stages: <ExamStage>[
        ExamStage(
          name: 'Prelims',
          type: 'Objective MCQ',
          mode: 'Offline (OMR)',
          questions: 200,
          marks: 400,
          minutes: 240,
          negative: '1/3 mark per wrong answer',
          merit: false,
          sections: <ExamSection>[
            ExamSection(name: 'General Studies I', questions: 100, marks: 200, minutes: 120),
            ExamSection(name: 'CSAT (General Studies II)', questions: 80, marks: 200, minutes: 120),
          ],
        ),
      ],
    ),
  ];
}
