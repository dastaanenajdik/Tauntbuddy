import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tauntbuddy/core/utils/icon_mapper.dart';
import 'package:tauntbuddy/data/models/catalog.dart';
import 'package:tauntbuddy/data/models/exam.dart';
import 'package:tauntbuddy/data/models/quote.dart';
import 'package:tauntbuddy/data/models/study_task.dart';
import 'package:tauntbuddy/data/models/taunt.dart';

/// The three JSON files in `assets/data/` are the app's content backbone: they
/// are bundled with the app *and* served from the ifallertzia server. CI must fail loudly
/// if any of them drifts out of schema, so these tests double as the contract
/// that `.github/workflows/taunts.yml` enforces for the published copy.
Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('taunts.json', () {
    late Map<String, dynamic> raw;
    late TauntDataset dataset;

    setUpAll(() {
      raw = _load('assets/data/taunts.json');
      dataset = TauntDataset.fromJson(raw);
    });

    test('declares a supported schema version', () {
      expect(raw['schemaVersion'], 1);
    });

    test('parses into packs and taunts', () {
      expect(dataset.packs, isNotEmpty);
      expect(dataset.length, greaterThanOrEqualTo(24),
          reason: 'the taunt engine needs a decent pool per trigger');
      expect(dataset.isEmpty, isFalse);
    });

    test('every pack is complete', () {
      for (final TauntPack pack in dataset.packs) {
        expect(pack.id, isNotEmpty);
        expect(pack.title, isNotEmpty);
        expect(pack.taunts, isNotEmpty, reason: 'pack ${pack.id} has no taunts');
      }
    });

    test('ids are unique and text is clean', () {
      final List<Taunt> all = dataset.all;
      final Set<String> ids = all.map((Taunt t) => t.id).toSet();
      expect(ids.length, all.length, reason: 'duplicate taunt ids');

      for (final Taunt taunt in all) {
        expect(taunt.text.trim(), isNotEmpty, reason: 'empty taunt ${taunt.id}');
        expect(taunt.text.length, lessThanOrEqualTo(220),
            reason: 'taunt ${taunt.id} is too long for a notification');
        expect(taunt.severity, inInclusiveRange(1, 3));
        expect(taunt.category, isNotEmpty);
      }
    });

    test('triggers round-trip through the enum', () {
      final List<dynamic> packs = raw['packs'] as List<dynamic>;
      for (final dynamic packEntry in packs) {
        final Map<String, dynamic> pack = packEntry as Map<String, dynamic>;
        final List<dynamic> taunts = pack['taunts'] as List<dynamic>;
        for (final dynamic tauntEntry in taunts) {
          final Map<String, dynamic> taunt = tauntEntry as Map<String, dynamic>;
          final String key = taunt['trigger'] as String;
          final TauntTrigger trigger = TauntTrigger.fromKey(key);
          expect(trigger.key, key, reason: 'unknown trigger key "$key"');
        }
      }
    });

    test('covers the triggers the reminder engine schedules', () {
      final Set<TauntTrigger> covered =
          dataset.all.map((Taunt t) => t.trigger).toSet();
      const List<TauntTrigger> required = <TauntTrigger>[
        TauntTrigger.morning,
        TauntTrigger.afternoon,
        TauntTrigger.evening,
        TauntTrigger.night,
        TauntTrigger.idle,
        TauntTrigger.goalMissed,
        TauntTrigger.streakLost,
        TauntTrigger.sessionEnd,
        TauntTrigger.breakOver,
        TauntTrigger.examSoon,
        TauntTrigger.kavachBreak,
      ];
      for (final TauntTrigger trigger in required) {
        expect(covered, contains(trigger),
            reason: 'no taunts for trigger ${trigger.key}');
      }
    });

    test('picks deterministically per slot and respects the severity cap', () {
      final Taunt? first = dataset.pick(
        triggers: <TauntTrigger>[TauntTrigger.idle],
        seed: 4242,
        maxSeverity: 2,
      );
      final Taunt? again = dataset.pick(
        triggers: <TauntTrigger>[TauntTrigger.idle],
        seed: 4242,
        maxSeverity: 2,
      );
      expect(first, isNotNull);
      expect(again?.id, first?.id, reason: 'same seed must give the same taunt');
      expect(first!.severity, lessThanOrEqualTo(2));

      final Taunt? ruthless = dataset.pick(
        triggers: <TauntTrigger>[TauntTrigger.idle],
        seed: 7,
        maxSeverity: 3,
      );
      expect(ruthless, isNotNull);
    });

    test('emoji + shortText stay UI-safe', () {
      for (final Taunt taunt in dataset.all) {
        expect(taunt.emoji, isNotEmpty);
        expect(taunt.shortText.length, lessThanOrEqualTo(100));
      }
    });
  });

  group('quotes.json', () {
    late QuoteDataset quotes;

    setUpAll(() {
      quotes = QuoteDataset.fromJson(_load('assets/data/quotes.json'));
    });

    test('parses at least a fortnight of quotes', () {
      expect(quotes.quotes.length, greaterThanOrEqualTo(14));
      for (final Quote quote in quotes.quotes) {
        expect(quote.text.trim(), isNotEmpty);
        expect(quote.author.trim(), isNotEmpty);
      }
    });

    test('quote of the day is stable for a given date', () {
      final DateTime day = DateTime(2026, 9, 16);
      expect(quotes.forDay(day).text, quotes.forDay(day).text);
      expect(quotes.forDay(day.add(const Duration(days: 1))).text,
          isNot(quotes.forDay(day).text));
    });

    test('an empty dataset still yields a usable quote', () {
      const QuoteDataset empty = QuoteDataset(quotes: <Quote>[]);
      expect(empty.isEmpty, isTrue);
      expect(empty.forDay(DateTime(2026, 1, 1)).text, isNotEmpty);
    });
  });

  group('seed_catalog.json', () {
    late SeedCatalog catalog;

    setUpAll(() {
      catalog = SeedCatalog.fromJson(_load('assets/data/seed_catalog.json'));
    });

    test('features cover the suite and exactly one is PRO', () {
      expect(catalog.features.length, greaterThanOrEqualTo(10));
      final List<FeatureCard> pro =
          catalog.features.where((FeatureCard f) => f.pro).toList();
      expect(pro.length, 1);
      expect(pro.single.id, 'planner',
          reason: 'the Exam Planner is the only PRO feature');
      for (final FeatureCard feature in catalog.features) {
        expect(feature.title, isNotEmpty);
        expect(feature.route.startsWith('/'), isTrue);
      }
    });

    test('badges reference known metrics with sane thresholds', () {
      const Set<String> metrics = <String>{
        'sessions',
        'focus_minutes',
        'streak',
        'dhyan_sessions',
        'early_sessions',
        'late_sessions',
        'goals_done',
        'mood_checkins',
        'kavach_sessions',
      };
      expect(catalog.badges.length, greaterThanOrEqualTo(10));
      for (final BadgeDefinition badge in catalog.badges) {
        expect(metrics, contains(badge.metric));
        expect(badge.threshold, greaterThan(0));
        expect(badge.title, isNotEmpty);
      }
    });

    test('levels ascend from zero focus minutes', () {
      final List<LevelDefinition> levels = catalog.levels;
      expect(levels.length, greaterThanOrEqualTo(3));
      expect(levels.first.minFocusMinutes, 0);
      for (int i = 1; i < levels.length; i++) {
        expect(levels[i].minFocusMinutes,
            greaterThan(levels[i - 1].minFocusMinutes));
      }
    });

    test('courses and honest community seed data are usable', () {
      for (final Course course in catalog.courses) {
        expect(course.lessons, greaterThan(0));
        expect(course.hours, greaterThan(0));
        expect(course.rating, inInclusiveRange(0, 5));
        expect(course.progress, inInclusiveRange(0, 1));
      }
      for (final StudyCircle circle in catalog.circles) {
        // Seed rooms have no verified remote presence yet; never fabricate it.
        expect(circle.members, greaterThanOrEqualTo(0));
        expect(circle.name, isNotEmpty);
      }
      for (final LeaderboardEntry entry in catalog.leaderboard) {
        // Community totals stay at zero until a real backend supplies them.
        expect(entry.focusMinutes, greaterThanOrEqualTo(0));
        expect(entry.name, isNotEmpty);
      }
    });

    test('moods, dhyan, planner, kavach and timeline sections are complete', () {
      expect(catalog.moods.length, greaterThanOrEqualTo(4));
      expect(catalog.dhyanTechniques.length, greaterThanOrEqualTo(4));
      expect(catalog.plannerTemplates.length, greaterThanOrEqualTo(2));
      expect(catalog.kavachProfiles.length, greaterThanOrEqualTo(2));
      expect(catalog.timelineBlocks.length, greaterThanOrEqualTo(4));

      for (final DhyanTechnique technique in catalog.dhyanTechniques) {
        expect(technique.minutes, greaterThan(0));
      }
      for (final PlannerTemplate template in catalog.plannerTemplates) {
        expect(template.daysOut, greaterThan(0));
        expect(template.subjects, isNotEmpty);
      }
      for (final KavachProfile profile in catalog.kavachProfiles) {
        expect(profile.title, isNotEmpty);
        expect(profile.blockedApps, isNotEmpty);
      }
      for (final TimelineBlock block in catalog.timelineBlocks) {
        expect(block.endMinutes, greaterThan(block.startMinutes));
        expect(block.durationMinutes, greaterThan(0));
      }
    });

    test('the exam hub ships the exams the product promises', () {
      final Set<String> ids =
          catalog.exams.map((ExamBlueprint exam) => exam.id).toSet();
      expect(ids.length, catalog.exams.length, reason: 'duplicate exam ids');
      expect(catalog.exams.length, greaterThanOrEqualTo(20));

      const List<String> required = <String>[
        'upsc-cse', // UPSC — all subjects, pattern and cycle
        'bpsc', // Bihar state PSC
        'ca', // Chartered Accountancy
        'clat-ug', // law entrance
        'cuet-ug', // university entrance
        'ssc-cgl',
        'ibps-po',
        'neet-ug',
        'jee-main',
        'gate',
      ];
      for (final String id in required) {
        expect(ids, contains(id), reason: '$id is missing from the exam dataset');
      }
    });

    test('every exam carries a pattern, a syllabus and a timeline', () {
      for (final ExamBlueprint exam in catalog.exams) {
        expect(exam.code, isNotEmpty, reason: '${exam.id} has no code');
        expect(exam.body, isNotEmpty, reason: '${exam.id} has no conducting body');
        expect(exam.about, isNotEmpty, reason: '${exam.id} has no overview');
        expect(exam.stages, isNotEmpty, reason: '${exam.id} has no exam pattern');
        expect(exam.syllabus, isNotEmpty, reason: '${exam.id} has no syllabus');
        expect(exam.timeline.length, greaterThanOrEqualTo(3),
            reason: '${exam.id} needs a full cycle');
        expect(
          const <String>{'violet', 'cyan', 'magenta', 'mint', 'amber', 'grey'},
          contains(exam.accent),
          reason: '${exam.id} uses an unknown accent key',
        );
        expect(iconFor(exam.icon), isNot(Icons.auto_awesome_rounded),
            reason: '${exam.id} uses an icon key the mapper does not know');

        for (final ExamStage stage in exam.stages) {
          expect(stage.name, isNotEmpty);
          expect(stage.type, isNotEmpty);
          expect(stage.negative, isNotEmpty,
              reason: '${exam.id}/${stage.name} must state the penalty');
        }
        for (final ExamSyllabusPaper paper in exam.syllabus) {
          expect(paper.subject, isNotEmpty);
          expect(paper.topics.length, greaterThanOrEqualTo(2),
              reason: '${exam.id}/${paper.subject} needs real topics');
          expect(paper.plannerUnits, lessThanOrEqualTo(20),
              reason: 'planner cards cap out at 20 units');
        }
        for (final ExamMilestone milestone in exam.timeline) {
          expect(milestone.month, inInclusiveRange(1, 12));
          expect(milestone.window, isNotEmpty,
              reason: '${exam.id}/${milestone.label} needs a window');
        }
      }
    });

    test('exam blueprints turn into usable planner templates', () {
      final DateTime now = DateTime(2026, 9, 17);
      for (final ExamBlueprint exam in catalog.exams) {
        final PlannerTemplate template = exam.toPlannerTemplate(now);
        expect(template.subjects, isNotEmpty);
        expect(template.daysOut, greaterThan(0));
        expect(template.daysOut, lessThanOrEqualTo(730));
        for (final SyllabusSubject subject in template.subjects) {
          expect(subject.totalUnits, greaterThan(0));
          expect(subject.examDate, isNotNull);
          expect(subject.examDate!.isAfter(now), isTrue,
              reason: '${exam.id} was planned into the past');
        }
        expect(exam.nextMilestoneLabel(now), contains('days out'));
      }
    });

    test('missing sections degrade to empty lists instead of throwing', () {
      final SeedCatalog bare = SeedCatalog.fromJson(<String, dynamic>{});
      expect(bare.features, isEmpty);
      expect(bare.badges, isEmpty);
      expect(bare.exams, isEmpty);
      expect(SeedCatalog.fallback.features, isNotEmpty);
    });
  });
}
