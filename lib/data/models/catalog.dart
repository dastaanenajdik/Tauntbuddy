import 'exam.dart';
import 'study_task.dart';
import 'tracking.dart';

/// A card in the Home feature grid — mirrors the "Nishtha / Ekagra dashboard"
/// style: heavily rounded, thin border, one glowing icon per card.
class FeatureCard {
  const FeatureCard({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.route,
    required this.accent,
    this.pro = false,
  });

  final String id;
  final String title;
  final String tagline;
  final String icon;
  final String route;
  final String accent;
  final bool pro;

  factory FeatureCard.fromJson(Map<String, dynamic> json) => FeatureCard(
        id: (json['id'] as String?) ?? 'feature',
        title: (json['title'] as String?) ?? 'Feature',
        tagline: (json['tagline'] as String?) ?? '',
        icon: (json['icon'] as String?) ?? 'bolt',
        route: (json['route'] as String?) ?? '/home',
        accent: (json['accent'] as String?) ?? 'violet',
        pro: (json['pro'] as bool?) ?? false,
      );
}

/// A gamification milestone. The dashboard shows unlocked ones and the
/// leaderboard screen shows the full shelf with progress.
class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.metric,
    required this.threshold,
  });

  final String id;
  final String title;
  final String description;
  final String icon;

  /// bronze / silver / gold / platinum
  final String tier;

  /// sessions | focus_minutes | streak | kavach_sessions | dhyan_sessions |
  /// early_sessions | late_sessions | goals_done | mood_checkins
  final String metric;
  final int threshold;

  factory BadgeDefinition.fromJson(Map<String, dynamic> json) => BadgeDefinition(
        id: (json['id'] as String?) ?? 'badge',
        title: (json['title'] as String?) ?? 'Badge',
        description: (json['description'] as String?) ?? '',
        icon: (json['icon'] as String?) ?? 'star',
        tier: (json['tier'] as String?) ?? 'bronze',
        metric: (json['metric'] as String?) ?? 'sessions',
        threshold: (json['threshold'] as num?)?.toInt() ?? 1,
      );
}

/// A progress level driven purely by accumulated focus minutes.
class LevelDefinition {
  const LevelDefinition({
    required this.level,
    required this.title,
    required this.minFocusMinutes,
    required this.accent,
  });

  final int level;
  final String title;
  final int minFocusMinutes;
  final String accent;

  factory LevelDefinition.fromJson(Map<String, dynamic> json) => LevelDefinition(
        level: (json['level'] as num?)?.toInt() ?? 1,
        title: (json['title'] as String?) ?? 'Level',
        minFocusMinutes: (json['minFocusMinutes'] as num?)?.toInt() ?? 0,
        accent: (json['accent'] as String?) ?? 'violet',
      );
}

/// A structured learning module shown in Courses / Library.
class Course {
  const Course({
    required this.id,
    required this.title,
    required this.provider,
    required this.category,
    required this.lessons,
    required this.hours,
    required this.rating,
    required this.progress,
    required this.accent,
    required this.description,
  });

  final String id;
  final String title;
  final String provider;
  final String category;
  final int lessons;
  final int hours;
  final double rating;
  final double progress;
  final String accent;
  final String description;

  Course copyWith({double? progress}) => Course(
        id: id,
        title: title,
        provider: provider,
        category: category,
        lessons: lessons,
        hours: hours,
        rating: rating,
        progress: progress ?? this.progress,
        accent: accent,
        description: description,
      );

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: (json['id'] as String?) ?? 'course',
        title: (json['title'] as String?) ?? 'Course',
        provider: (json['provider'] as String?) ?? 'TauntBuddy',
        category: (json['category'] as String?) ?? 'Skill',
        lessons: (json['lessons'] as num?)?.toInt() ?? 10,
        hours: (json['hours'] as num?)?.toInt() ?? 5,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
        progress: ((json['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1),
        accent: (json['accent'] as String?) ?? 'violet',
        description: (json['description'] as String?) ?? '',
      );
}

/// Mehfil (open co-working room) or Study Circle (small accountability group).
class StudyCircle {
  const StudyCircle({
    required this.id,
    required this.name,
    required this.subject,
    required this.members,
    required this.activity,
    required this.accent,
    required this.description,
  });

  final String id;
  final String name;
  final String subject;
  final int members;
  final String activity;
  final String accent;
  final String description;

  bool get isLive => activity.toLowerCase().contains('live');

  factory StudyCircle.fromJson(Map<String, dynamic> json) => StudyCircle(
        id: (json['id'] as String?) ?? 'circle',
        name: (json['name'] as String?) ?? 'Circle',
        subject: (json['subject'] as String?) ?? 'Study',
        members: (json['members'] as num?)?.toInt() ?? 0,
        activity: (json['activity'] as String?) ?? 'idle',
        accent: (json['accent'] as String?) ?? 'violet',
        description: (json['description'] as String?) ?? '',
      );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.handle,
    required this.focusMinutes,
    required this.streak,
    required this.badge,
  });

  final int rank;
  final String name;
  final String handle;
  final int focusMinutes;
  final int streak;
  final String badge;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?) ?? 'Learner',
        handle: (json['handle'] as String?) ?? '@learner',
        focusMinutes: (json['focusMinutes'] as num?)?.toInt() ?? 0,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        badge: (json['badge'] as String?) ?? 'Focus Flow',
      );
}

class DhyanTechnique {
  const DhyanTechnique({
    required this.id,
    required this.title,
    required this.minutes,
    required this.accent,
    required this.description,
  });

  final String id;
  final String title;
  final int minutes;
  final String accent;
  final String description;

  factory DhyanTechnique.fromJson(Map<String, dynamic> json) => DhyanTechnique(
        id: (json['id'] as String?) ?? 'technique',
        title: (json['title'] as String?) ?? 'Breath',
        minutes: (json['minutes'] as num?)?.toInt() ?? 5,
        accent: (json['accent'] as String?) ?? 'mint',
        description: (json['description'] as String?) ?? '',
      );
}

/// Exam Planner template: one tap turns a template into editable subjects.
class PlannerTemplate {
  const PlannerTemplate({
    required this.id,
    required this.title,
    required this.exam,
    required this.daysOut,
    required this.subjects,
  });

  final String id;
  final String title;
  final String exam;
  final int daysOut;
  final List<SyllabusSubject> subjects;

  factory PlannerTemplate.fromJson(Map<String, dynamic> json) {
    final List<dynamic> subjects = (json['subjects'] as List<dynamic>?) ?? const <dynamic>[];
    return PlannerTemplate(
      id: (json['id'] as String?) ?? 'template',
      title: (json['title'] as String?) ?? 'Plan',
      exam: (json['exam'] as String?) ?? 'Exam',
      daysOut: (json['daysOut'] as num?)?.toInt() ?? 30,
      subjects: subjects
          .whereType<Map<String, dynamic>>()
          .map(SyllabusSubject.fromSeed)
          .toList(growable: false),
    );
  }
}

/// A KAVACH focus-shield preset.
class KavachProfile {
  const KavachProfile({
    required this.id,
    required this.title,
    required this.strictness,
    required this.accent,
    required this.description,
    required this.blockedApps,
  });

  final String id;
  final String title;
  final String strictness;
  final String accent;
  final String description;
  final List<String> blockedApps;

  factory KavachProfile.fromJson(Map<String, dynamic> json) => KavachProfile(
        id: (json['id'] as String?) ?? 'kavach',
        title: (json['title'] as String?) ?? 'Shield',
        strictness: (json['strictness'] as String?) ?? 'soft',
        accent: (json['accent'] as String?) ?? 'violet',
        description: (json['description'] as String?) ?? '',
        blockedApps: (json['blockedApps'] as List<dynamic>?)
                ?.map((dynamic e) => e.toString())
                .toList(growable: false) ??
            const <String>[],
      );
}

/// A planned block on the day timeline.
class TimelineBlock {
  const TimelineBlock({
    required this.id,
    required this.title,
    required this.kind,
    required this.startMinutes,
    required this.endMinutes,
    required this.accent,
  });

  final String id;
  final String title;
  final String kind;

  /// Minutes from midnight — easier to reason about than strings.
  final int startMinutes;
  final int endMinutes;
  final String accent;

  int get durationMinutes => (endMinutes - startMinutes).clamp(0, 24 * 60);

  factory TimelineBlock.fromJson(Map<String, dynamic> json) {
    int parse(String? value) {
      if (value == null) return 0;
      final List<String> parts = value.split(':');
      if (parts.length != 2) return 0;
      final int h = int.tryParse(parts[0]) ?? 0;
      final int m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }

    return TimelineBlock(
      id: (json['id'] as String?) ?? 'block',
      title: (json['title'] as String?) ?? 'Block',
      kind: (json['kind'] as String?) ?? 'focus',
      startMinutes: parse(json['start'] as String?),
      endMinutes: parse(json['end'] as String?),
      accent: (json['accent'] as String?) ?? 'violet',
    );
  }
}

/// The whole bundled catalog parsed from `assets/data/seed_catalog.json`.
class SeedCatalog {
  const SeedCatalog({
    this.features = const <FeatureCard>[],
    this.badges = const <BadgeDefinition>[],
    this.levels = const <LevelDefinition>[],
    this.courses = const <Course>[],
    this.circles = const <StudyCircle>[],
    this.leaderboard = const <LeaderboardEntry>[],
    this.moods = const <MoodOption>[],
    this.dhyanTechniques = const <DhyanTechnique>[],
    this.plannerTemplates = const <PlannerTemplate>[],
    this.kavachProfiles = const <KavachProfile>[],
    this.timelineBlocks = const <TimelineBlock>[],
    this.exams = const <ExamBlueprint>[],
  });

  final List<FeatureCard> features;
  final List<BadgeDefinition> badges;
  final List<LevelDefinition> levels;
  final List<Course> courses;
  final List<StudyCircle> circles;
  final List<LeaderboardEntry> leaderboard;
  final List<MoodOption> moods;
  final List<DhyanTechnique> dhyanTechniques;
  final List<PlannerTemplate> plannerTemplates;
  final List<KavachProfile> kavachProfiles;
  final List<TimelineBlock> timelineBlocks;

  /// Indian exam blueprints: pattern, syllabus and the annual cycle.
  final List<ExamBlueprint> exams;

  static const SeedCatalog empty = SeedCatalog();

  List<T> _list<T>(Map<String, dynamic> json, String key, T Function(Map<String, dynamic>) build) {
    final List<dynamic> raw = (json[key] as List<dynamic>?) ?? const <dynamic>[];
    return raw.whereType<Map<String, dynamic>>().map(build).toList(growable: false);
  }

  factory SeedCatalog.fromJson(Map<String, dynamic> json) {
    final SeedCatalog emptyCatalog = SeedCatalog.empty;
    return SeedCatalog(
      features: emptyCatalog._list(json, 'features', FeatureCard.fromJson),
      badges: emptyCatalog._list(json, 'badges', BadgeDefinition.fromJson),
      levels: emptyCatalog._list(json, 'levels', LevelDefinition.fromJson),
      courses: emptyCatalog._list(json, 'courses', Course.fromJson),
      circles: emptyCatalog._list(json, 'circles', StudyCircle.fromJson),
      leaderboard: emptyCatalog._list(json, 'leaderboard', LeaderboardEntry.fromJson),
      moods: emptyCatalog._list(json, 'moods', MoodOption.fromJson),
      dhyanTechniques: emptyCatalog._list(json, 'dhyan_techniques', DhyanTechnique.fromJson),
      plannerTemplates: emptyCatalog._list(json, 'planner_templates', PlannerTemplate.fromJson),
      kavachProfiles: emptyCatalog._list(json, 'kavach_profiles', KavachProfile.fromJson),
      timelineBlocks: emptyCatalog._list(json, 'timeline_blocks', TimelineBlock.fromJson),
      exams: emptyCatalog._list(json, 'exams', ExamBlueprint.fromJson),
    );
  }

  /// The hand-written floor used if the asset ever fails to load, so the app
  /// never shows an empty shell.
  static const SeedCatalog fallback = SeedCatalog(
    features: <FeatureCard>[
      FeatureCard(
        id: 'ekagra',
        title: 'Focus Flow',
        tagline: 'Deep focus timer that measures your Focus Score.',
        icon: 'bolt',
        route: '/ekagra',
        accent: 'violet',
      ),
      FeatureCard(
        id: 'planner',
        title: 'Exam Planner',
        tagline: 'Syllabus tracking and exam countdowns.',
        icon: 'calendar',
        route: '/planner',
        accent: 'cyan',
        pro: true,
      ),
      FeatureCard(
        id: 'kavach',
        title: 'Distraction Shield',
        tagline: 'Focus shield against distractions.',
        icon: 'shield',
        route: '/kavach',
        accent: 'magenta',
      ),
      FeatureCard(
        id: 'dhyan',
        title: 'Mindful Reset',
        tagline: 'Mindfulness timers and resets.',
        icon: 'self_improvement',
        route: '/dhyan',
        accent: 'mint',
      ),
    ],
    levels: <LevelDefinition>[
      LevelDefinition(level: 1, title: 'Soja Beta', minFocusMinutes: 0, accent: 'grey'),
      LevelDefinition(level: 2, title: 'Uth Ja Bhai', minFocusMinutes: 60, accent: 'violet'),
      LevelDefinition(level: 3, title: 'Flow Builder', minFocusMinutes: 300, accent: 'cyan'),
    ],
  );
}
