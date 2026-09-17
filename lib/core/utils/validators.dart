/// Pure validation helpers shared by the auth/onboarding forms and the CI
/// widget tests. Keeping them pure makes them trivially testable.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns an error message, or `null` when the email looks valid.
  static String? email(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) return 'Email is required';
    if (!_email.hasMatch(input)) return 'Enter a valid email address';
    return null;
  }

  /// Local TauntBuddy accounts are device-local, but we still enforce a sane
  /// minimum so that "abc" cannot become a password.
  static String? password(String? value) {
    final String input = value ?? '';
    if (input.isEmpty) return 'Password is required';
    if (input.length < 6) return 'Use at least 6 characters';
    if (input.length > 64) return 'Keep it under 64 characters';
    return null;
  }

  static String? displayName(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) return 'Tell the hamster what to call you';
    if (input.length < 2) return 'That is a bit too short';
    if (input.length > 32) return 'Keep it under 32 characters';
    return null;
  }

  static String? required(String? value, {String label = 'This field'}) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  /// Accepts a full URL or an owner/repo path for the ifallertzia dataset
  /// server and normalises it into a raw URL for the taunt sync.
  static String? tauntRepoUrl(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) return null;
    if (!input.startsWith('http') && !input.contains('github')) {
      return 'Paste the ifallertzia server dataset URL.';
    }
    return null;
  }

  /// Email masked for the profile screen: `da***@gmail.com`.
  static String maskEmail(String? value) {
    final String input = (value ?? '').trim();
    final int at = input.indexOf('@');
    if (at <= 0) return input.isEmpty ? 'guest@tauntbuddy.app' : input;
    final String name = input.substring(0, at);
    final String domain = input.substring(at);
    if (name.length <= 2) return '${name[0]}***$domain';
    return '${name.substring(0, 2)}***$domain';
  }
}
