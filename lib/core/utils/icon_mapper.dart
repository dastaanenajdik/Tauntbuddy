import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Maps the string icon keys used in `seed_catalog.json` to real icons.
///
/// Keeping the mapping here means a dataset update can introduce a new icon
/// name without breaking the build — unknown keys fall back gracefully.
IconData iconFor(String key, {IconData fallback = Icons.auto_awesome_rounded}) {
  switch (key) {
    case 'bolt':
      return Icons.bolt_rounded;
    case 'calendar':
      return Icons.event_note_rounded;
    case 'shield':
      return Icons.shield_rounded;
    case 'trophy':
      return Icons.emoji_events_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'groups':
      return Icons.groups_rounded;
    case 'self_improvement':
      return Icons.self_improvement_rounded;
    case 'schedule':
      return Icons.schedule_rounded;
    case 'checklist':
      return Icons.checklist_rounded;
    case 'campaign':
      return Icons.campaign_rounded;
    case 'menu_book':
      return Icons.menu_book_rounded;
    case 'insights':
      return Icons.insights_rounded;
    case 'search':
      return Icons.search_rounded;
    case 'dashboard':
      return Icons.dashboard_rounded;
    case 'person':
      return Icons.person_rounded;
    case 'settings':
      return Icons.settings_rounded;
    case 'hourglass':
      return Icons.hourglass_bottom_rounded;
    case 'psychology':
      return Icons.psychology_rounded;
    case 'workspace_premium':
      return Icons.workspace_premium_rounded;
    case 'local_fire_department':
      return Icons.local_fire_department_rounded;
    case 'whatshot':
      return Icons.whatshot_rounded;
    case 'wb_twilight':
      return Icons.wb_twilight_rounded;
    case 'dark_mode':
      return Icons.dark_mode_rounded;
    case 'check_circle':
      return Icons.check_circle_rounded;
    case 'mood':
      return Icons.mood_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'timeline':
      return Icons.timeline_rounded;
    case 'library':
      return Icons.local_library_rounded;
    case 'notifications':
      return Icons.notifications_active_rounded;
    default:
      return fallback;
  }
}

/// Convenience for widgets that render data-driven accents.
AppAccent accentKeyToEnum(String? key) => accentFromKey(key);
