import 'package:flutter/material.dart';

import 'entry_badge.dart';

/// Resolved visual definition of a badge (built-in or custom).
///
/// [id] is the persistent key: the enum name for built-ins ('favorite'), 'custom:<uuid>' for custom
/// ones. [label] is only filled for custom badges; built-in labels are resolved
/// through l10n (see BadgePicker.labelFor).
class BadgeDef {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool custom;

  const BadgeDef({
    required this.id,
    required this.icon,
    required this.color,
    this.label = '',
    this.custom = false,
  });

  /// Is this the "None" badge (id == none).
  bool get isNone => id == EntryBadge.none.name;
}
