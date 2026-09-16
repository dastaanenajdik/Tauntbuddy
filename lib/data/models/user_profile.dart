/// The signed-in (or guest) TauntBuddy user.
///
/// Accounts are device-local by default — the app never sends personal data to
/// a server. Optional GitHub sync only pushes/pulls the *taunt dataset*.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.isGuest = false,
    this.isPro = false,
    this.avatarEmoji = '🐹',
    this.college = '',
    this.examTarget = '',
    this.createdAt,
    this.lastLoginAt,
  });

  final String name;
  final String email;
  final bool isGuest;
  final bool isPro;
  final String avatarEmoji;
  final String college;
  final String examTarget;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  static const UserProfile guest = UserProfile(
    name: 'Guest',
    email: 'guest@tauntbuddy.app',
    isGuest: true,
  );

  String get firstName {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return 'friend';
    return trimmed.split(' ').first;
  }

  String get initials {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'TB';
    final String first = parts.first;
    if (parts.length == 1) {
      return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
    }
    final String last = parts.last;
    return (first.substring(0, 1) + last.substring(0, 1)).toUpperCase();
  }

  String get greeting {
    final String target = examTarget.trim();
    if (target.isEmpty) return 'Your universe of focus awaits.';
    return '$target mode on. Your universe of focus awaits.';
  }

  UserProfile copyWith({
    String? name,
    String? email,
    bool? isGuest,
    bool? isPro,
    String? avatarEmoji,
    String? college,
    String? examTarget,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      isGuest: isGuest ?? this.isGuest,
      isPro: isPro ?? this.isPro,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      college: college ?? this.college,
      examTarget: examTarget ?? this.examTarget,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'isGuest': isGuest,
        'isPro': isPro,
        'avatarEmoji': avatarEmoji,
        'college': college,
        'examTarget': examTarget,
        'createdAt': createdAt?.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;
    return UserProfile(
      name: (json['name'] as String?) ?? 'Friend',
      email: (json['email'] as String?) ?? 'guest@tauntbuddy.app',
      isGuest: (json['isGuest'] as bool?) ?? false,
      isPro: (json['isPro'] as bool?) ?? false,
      avatarEmoji: (json['avatarEmoji'] as String?) ?? '🐹',
      college: (json['college'] as String?) ?? '',
      examTarget: (json['examTarget'] as String?) ?? '',
      createdAt: parse(json['createdAt']),
      lastLoginAt: parse(json['lastLoginAt']),
    );
  }
}
