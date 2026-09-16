import 'package:flutter/material.dart';

import 'emoji_burst.dart';

/// Neutral celebration used after destructive or account-level actions, where
/// confetti would feel tone-deaf.
class EmberFreeBurst {
  const EmberFreeBurst._();

  static void fireFrom(BuildContext context) {
    EmojiBurst.fireFrom(
      context,
      emojis: const <String>['🧹', '✨', '🫧'],
      count: 7,
    );
  }
}
