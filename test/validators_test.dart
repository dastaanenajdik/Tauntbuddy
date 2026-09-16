import 'package:flutter_test/flutter_test.dart';
import 'package:tauntbuddy/core/utils/validators.dart';

void main() {
  group('email', () {
    test('accepts real-looking addresses', () {
      expect(Validators.email('studious@iitism.ac.in'), isNull);
      expect(Validators.email('  a.b+tag@gmail.com '), isNull);
    });

    test('rejects empty and malformed input', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
      expect(Validators.email('a@b'), 'Enter a valid email address');
    });
  });

  group('password', () {
    test('enforces the documented bounds', () {
      expect(Validators.password('ekagra123'), isNull);
      expect(Validators.password(''), 'Password is required');
      expect(Validators.password('12345'), 'Use at least 6 characters');
      expect(Validators.password('x' * 65), 'Keep it under 64 characters');
    });
  });

  group('displayName', () {
    test('rejects blanks and one-letter names', () {
      expect(Validators.displayName('Dastan'), isNull);
      expect(Validators.displayName('   '), 'Tell the hamster what to call you');
      expect(Validators.displayName('D'), 'That is a bit too short');
      expect(Validators.displayName('x' * 33), 'Keep it under 32 characters');
    });
  });

  group('required', () {
    test('uses the provided label', () {
      expect(Validators.required('ok'), isNull);
      expect(Validators.required('   ', label: 'Subject'), 'Subject is required');
    });
  });

  group('tauntRepoUrl', () {
    test('accepts github hosts and rejects random input', () {
      expect(Validators.tauntRepoUrl(''), isNull, reason: 'empty means "keep default"');
      expect(
        Validators.tauntRepoUrl(
            'https://raw.githubusercontent.com/dastaanenajdik/Tauntbuddy/main/assets/data/taunts.json'),
        isNull,
      );
      expect(Validators.tauntRepoUrl('github.com/user/repo'), isNull);
      expect(Validators.tauntRepoUrl('example.com/taunts.json'),
          'Use a github.com or raw.githubusercontent.com URL');
    });
  });

  group('maskEmail', () {
    test('hides the account name but keeps the domain', () {
      expect(Validators.maskEmail('dastan@github.com'), 'da***@github.com');
      expect(Validators.maskEmail('ab@gmail.com'), 'a***@gmail.com');
      expect(Validators.maskEmail(''), 'guest@tauntbuddy.app');
      expect(Validators.maskEmail('weird'), 'weird');
    });
  });
}
