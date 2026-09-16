import 'package:flutter_test/flutter_test.dart';
import 'package:tauntbuddy/core/utils/app_date_utils.dart';

void main() {
  group('DayKey', () {
    test('formats and round-trips through storage ids', () {
      const DayKey day = DayKey(2026, 9, 6);
      expect(day.id, '2026-09-06');
      expect(DayKey.parse('2026-09-06'), day);
      expect(day.dateTime, DateTime(2026, 9, 6));
    });

    test('unparseable ids fall back to today rather than throwing', () {
      expect(DayKey.parse('garbage'), DayKey.today());
      expect(DayKey.parse('2026-09'), DayKey.today());
    });

    test('adds and measures whole days across month ends', () {
      const DayKey end = DayKey(2026, 8, 31);
      expect(end.add(1).id, '2026-09-01');
      const DayKey start = DayKey(2026, 9, 1);
      expect(start.daysUntil(end), -1);
      expect(end.daysUntil(start), 1);
      expect(end.daysUntil(end), 0);
      expect(DayKey(2026, 9, 10).add(-10).id, '2026-08-31');
    });

    test('pretty labels stay stable for the UI', () {
      const DayKey day = DayKey(2026, 9, 16);
      expect(day.weekdayShort, 'Wed');
      expect(day.short, '16 Sep');
      expect(day.long, contains('September'));
    });
  });

  group('AppDateUtils', () {
    test('greeting covers every part of the day', () {
      String greet(int hour) => AppDateUtils.greeting(DateTime(2026, 9, 16, hour));
      expect(greet(2), 'Still up');
      expect(greet(8), 'Good morning');
      expect(greet(14), 'Good afternoon');
      expect(greet(19), 'Good evening');
      expect(greet(23), 'Good night');
    });

    test('time buckets drive the taunt packs', () {
      expect(AppDateUtils.timeBucket(DateTime(2026, 9, 16, 3)), 'night');
      expect(AppDateUtils.timeBucket(DateTime(2026, 9, 16, 9)), 'morning');
      expect(AppDateUtils.timeBucket(DateTime(2026, 9, 16, 15)), 'afternoon');
      expect(AppDateUtils.timeBucket(DateTime(2026, 9, 16, 20)), 'evening');
      expect(AppDateUtils.timeBucket(DateTime(2026, 9, 16, 23)), 'night');
    });

    test('duration labels read like a human wrote them', () {
      expect(AppDateUtils.durationLabel(0), '0m');
      expect(AppDateUtils.durationLabel(45), '45m');
      expect(AppDateUtils.durationLabel(60), '1h');
      expect(AppDateUtils.durationLabel(145), '2h 25m');
    });

    test('countdown clamps negatives to zero', () {
      expect(AppDateUtils.countdown(const Duration(minutes: 25)), '25:00');
      expect(AppDateUtils.countdown(const Duration(seconds: 65)), '01:05');
      expect(AppDateUtils.countdown(const Duration(seconds: -10)), '00:00');
    });

    test('ratio never divides by zero', () {
      expect(AppDateUtils.ratio(0, 0), 0);
      expect(AppDateUtils.ratio(5, 10), 0.5);
      expect(AppDateUtils.ratio(20, 10), 1.0);
    });

    test('range and lastDays helpers produce inclusive windows', () {
      final List<DayKey> range =
          AppDateUtils.rangeInclusive(const DayKey(2026, 9, 14), const DayKey(2026, 9, 16));
      expect(range.map((DayKey d) => d.id), <String>[
        '2026-09-14',
        '2026-09-15',
        '2026-09-16',
      ]);
      expect(AppDateUtils.rangeInclusive(const DayKey(2026, 9, 16), const DayKey(2026, 9, 14)),
          isEmpty);

      final List<DayKey> last = AppDateUtils.lastDays(3, end: const DayKey(2026, 9, 16));
      expect(last.map((DayKey d) => d.id),
          <String>['2026-09-14', '2026-09-15', '2026-09-16']);
    });
  });

  group('StreakCalculator', () {
    final Set<DayKey> days = <DayKey>{
      const DayKey(2026, 9, 10),
      const DayKey(2026, 9, 11),
      const DayKey(2026, 9, 12),
      const DayKey(2026, 9, 15),
      const DayKey(2026, 9, 16),
    };

    test('counts the run ending today', () {
      expect(StreakCalculator.currentStreak(days, today: const DayKey(2026, 9, 16)), 2);
    });

    test('yesterday still counts while today is unfinished', () {
      expect(StreakCalculator.currentStreak(days, today: const DayKey(2026, 9, 17)), 2);
    });

    test('a missed day resets the current streak', () {
      expect(StreakCalculator.currentStreak(days, today: const DayKey(2026, 9, 14)), 0);
    });

    test('longest streak scans the whole history', () {
      expect(StreakCalculator.longestStreak(days), 3);
      expect(StreakCalculator.longestStreak(<DayKey>{}), 0);
      expect(StreakCalculator.currentStreak(<DayKey>{}), 0);
    });
  });
}
