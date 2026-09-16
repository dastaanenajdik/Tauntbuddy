import 'package:flutter_test/flutter_test.dart';
import 'package:tauntbuddy/data/models/taunt.dart';

Taunt _taunt(String id, TauntTrigger trigger, int severity) => Taunt(
      id: id,
      text: 'taunt $id',
      category: 'focus',
      trigger: trigger,
      severity: severity,
    );

TauntDataset _dataset(List<Taunt> taunts) => TauntDataset(
      schemaVersion: 1,
      packs: <TauntPack>[
        TauntPack(
          id: 'test-pack',
          title: 'Test Pack',
          description: '',
          taunts: taunts,
        ),
      ],
    );

void main() {
  group('TauntTrigger', () {
    test('maps JSON keys to labels', () {
      expect(TauntTrigger.fromKey('streak_lost'), TauntTrigger.streakLost);
      expect(TauntTrigger.fromKey('goal_missed').label, 'Goal missed');
      expect(TauntTrigger.fromKey('kavach_break'), TauntTrigger.kavachBreak);
    });

    test('unknown or null keys fall back to manual', () {
      expect(TauntTrigger.fromKey('nonsense'), TauntTrigger.manual);
      expect(TauntTrigger.fromKey(null), TauntTrigger.manual);
      expect(TauntTrigger.fromKey('  EXAM_SOON '), TauntTrigger.examSoon);
    });

    test('every trigger has a non-empty key and label', () {
      for (final TauntTrigger trigger in TauntTrigger.values) {
        expect(trigger.key.trim(), isNotEmpty);
        expect(trigger.label.trim(), isNotEmpty);
      }
    });
  });

  group('TauntDataset.pick', () {
    final TauntDataset dataset = _dataset(<Taunt>[
      _taunt('a', TauntTrigger.idle, 1),
      _taunt('b', TauntTrigger.idle, 2),
      _taunt('c', TauntTrigger.idle, 3),
      _taunt('d', TauntTrigger.morning, 2),
    ]);

    test('filters by trigger', () {
      final List<Taunt> matches =
          dataset.byTriggers(<TauntTrigger>[TauntTrigger.morning]);
      expect(matches.map((Taunt t) => t.id), <String>['d']);
    });

    test('gentle ordering starts soft and escalates', () {
      final List<Taunt> soft = dataset.byTriggers(<TauntTrigger>[TauntTrigger.idle]);
      expect(soft.map((Taunt t) => t.severity), <int>[1, 2, 3]);

      final List<Taunt> harsh = dataset.byTriggers(
        <TauntTrigger>[TauntTrigger.idle],
        gentle: false,
      );
      expect(harsh.map((Taunt t) => t.severity), <int>[3, 2, 1]);
    });

    test('same seed yields the same taunt, different seeds can rotate', () {
      final Set<String> seen = <String>{};
      for (int seed = 0; seed < 12; seed++) {
        final Taunt? picked = dataset.pick(
          triggers: <TauntTrigger>[TauntTrigger.idle],
          seed: seed,
        );
        expect(picked, isNotNull);
        seen.add(dataset.pick(triggers: <TauntTrigger>[TauntTrigger.idle], seed: seed)!.id);
      }
      expect(seen.length, greaterThan(1));
      expect(seen.length, lessThanOrEqualTo(3));
    });

    test('severity cap is honoured but relaxed when nothing fits', () {
      final Taunt? capped = dataset.pick(
        triggers: <TauntTrigger>[TauntTrigger.idle],
        seed: 1,
        maxSeverity: 1,
      );
      expect(capped!.severity, 1);

      final Taunt? relaxed = dataset.pick(
        triggers: <TauntTrigger>[TauntTrigger.idle],
        seed: 1,
        maxSeverity: 1,
        excludeIds: <String>{'a'},
      );
      expect(relaxed, isNotNull);
      expect(relaxed!.id, isNot('a'));
    });

    test('excludes recently seen taunts when alternatives exist', () {
      final Taunt? picked = dataset.pick(
        triggers: <TauntTrigger>[TauntTrigger.idle],
        seed: 99,
        excludeIds: <String>{'a', 'b'},
      );
      expect(picked!.id, 'c');
    });

    test('empty dataset returns null instead of throwing', () {
      const TauntDataset empty = TauntDataset(schemaVersion: 1, packs: <TauntPack>[]);
      expect(empty.pick(triggers: <TauntTrigger>[TauntTrigger.idle]), isNull);
      expect(empty.isEmpty, isTrue);
    });
  });

  group('Taunt model', () {
    test('fromJson clamps severity and defaults the pack', () {
      final Taunt taunt = Taunt.fromJson(<String, dynamic>{
        'id': 'x',
        'text': 'text',
        'category': 'exam',
        'trigger': 'exam_soon',
        'severity': 9,
      });
      expect(taunt.severity, 3);
      expect(taunt.trigger, TauntTrigger.examSoon);
      expect(taunt.emoji, '📚');
      expect(taunt.isRoast, isTrue);
      expect(taunt.packId, 'core-roasts');
    });

    test('equality is id-based and copyWith keeps identity', () {
      final Taunt one = _taunt('same', TauntTrigger.idle, 1);
      final Taunt two = one.copyWith(severity: 3, source: TauntSource.remote);
      expect(one, two);
      expect(two.severity, 3);
      expect(two.source, TauntSource.remote);
    });

    test('dataset source is stamped onto every taunt', () {
      final TauntDataset remote = TauntDataset.fromJson(
        <String, dynamic>{
          'schemaVersion': 1,
          'packs': <dynamic>[
            <String, dynamic>{
              'id': 'p',
              'title': 'P',
              'taunts': <dynamic>[
                <String, dynamic>{'id': 'r1', 'text': 'hi', 'severity': 2},
              ],
            },
          ],
        },
        source: TauntSource.remote,
      );
      expect(remote.all.single.source, TauntSource.remote);
      expect(remote.all.single.severity, 2);
    });
  });
}
