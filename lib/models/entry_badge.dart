import 'package:flutter/material.dart';

/// Entry badge: emotion/importance marker visible at a glance.
/// Stored locally (SharedPreferences) while there is no DB, sent to Supabase as a string id.
enum EntryBadge {
  none,
  important,
  question,
  favorite,
  warning,
}

extension EntryBadgeX on EntryBadge {
  String get id => name;

  static EntryBadge fromId(String? id) => EntryBadge.values.firstWhere(
        (b) => b.name == id,
        orElse: () => EntryBadge.none,
      );

  IconData get icon => switch (this) {
        EntryBadge.none => Icons.label_outline,
        EntryBadge.important => Icons.priority_high,
        EntryBadge.question => Icons.help_outline,
        EntryBadge.favorite => Icons.favorite,
        EntryBadge.warning => Icons.warning_amber_rounded,
      };

  Color get color => switch (this) {
        // Dark tones readable on a light theme (visible enough on dark too).
        EntryBadge.none => Colors.grey,
        EntryBadge.important => Colors.red.shade700,
        EntryBadge.question => Colors.blue.shade700,
        EntryBadge.favorite => Colors.pink.shade700,
        EntryBadge.warning => Colors.orange.shade800,
      };
}
