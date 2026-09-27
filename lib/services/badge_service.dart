import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/badge_def.dart';
import '../models/entry_badge.dart';

/// Custom badge icon palette (Material). persistent key -> icon mapping.
class BadgeIcons {
  static const Map<String, IconData> options = {
    'flag': Icons.flag,
    'star': Icons.star,
    'bolt': Icons.bolt,
    'target': Icons.gps_fixed,
    'up': Icons.trending_up,
    'down': Icons.trending_down,
    'brain': Icons.psychology,
    'idea': Icons.lightbulb_outline,
    'bookmark': Icons.bookmark_border,
    'repeat': Icons.repeat,
    'money': Icons.attach_money,
    'save': Icons.savings_outlined,
    'error': Icons.error_outline,
    'check': Icons.check_circle_outline,
    'watch': Icons.visibility_outlined,
    'clock': Icons.schedule,
    'sell': Icons.sell_outlined,
    'fire': Icons.local_fire_department_outlined,
    'school': Icons.school_outlined,
    'warning': Icons.warning_amber_rounded,
    'question': Icons.help_outline,
    'heart': Icons.favorite_border,
    'urgent': Icons.priority_high,
  };

  static IconData of(String key) => options[key] ?? Icons.label_outline;
}

/// Custom badge color palette: fixed tones readable on light/dark themes.
class BadgeColors {
  static const Map<String, Color> options = {
    'red': Color(0xFFC62828),
    'orange': Color(0xFFEF6C00),
    'amber': Color(0xFFB26A00),
    'green': Color(0xFF2E7D32),
    'teal': Color(0xFF00695C),
    'blue': Color(0xFF1565C0),
    'indigo': Color(0xFF3949AB),
    'purple': Color(0xFF6A1B9A),
    'pink': Color(0xFFAD1457),
    'brown': Color(0xFF6D4C41),
    'grey': Color(0xFF616161),
  };

  static Color of(String key) => options[key] ?? options['grey']!;
}

/// User-defined badge (stored with persistent keys).
class CustomBadge {
  final String id;
  final String label;
  final String iconKey;
  final String colorKey;

  const CustomBadge({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.colorKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'icon': iconKey,
        'color': colorKey,
      };

  static CustomBadge? fromJson(Map m) {
    final id = m['id'];
    final label = m['label'];
    final icon = m['icon'];
    final color = m['color'];
    if (id is! String ||
        label is! String ||
        icon is! String ||
        color is! String) {
      return null;
    }
    return CustomBadge(id: id, label: label, iconKey: icon, colorKey: color);
  }
}

/// Badge catalog: built-in badges + the user's custom badges.
/// Singleton; notifies listeners on change (ChangeNotifier).
class BadgeService extends ChangeNotifier {
  BadgeService._();
  static final BadgeService instance = BadgeService._();

  static const _kCustom = 'custom_badges';

  final List<CustomBadge> _custom = [];

  List<CustomBadge> get custom => List.unmodifiable(_custom);

  /// Called once before the app is shown.
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCustom);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final cb = CustomBadge.fromJson(item);
              if (cb != null && !_custom.any((e) => e.id == cb.id)) {
                _custom.add(cb);
              }
            }
          }
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _kCustom, jsonEncode(_custom.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<CustomBadge> add({
    required String label,
    required String iconKey,
    required String colorKey,
  }) async {
    final cb = CustomBadge(
      id: 'custom:${const Uuid().v4().substring(0, 8)}',
      label: label.trim(),
      iconKey: iconKey,
      colorKey: colorKey,
    );
    _custom.add(cb);
    await _save();
    notifyListeners();
    return cb;
  }

  Future<void> update(
    String id, {
    required String label,
    required String iconKey,
    required String colorKey,
  }) async {
    final i = _custom.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _custom[i] = CustomBadge(
        id: id, label: label.trim(), iconKey: iconKey, colorKey: colorKey);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _custom.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  BadgeDef _builtinDef(EntryBadge b) =>
      BadgeDef(id: b.name, icon: b.icon, color: b.color);

  BadgeDef _customDef(CustomBadge c) => BadgeDef(
        id: c.id,
        label: c.label,
        custom: true,
        icon: BadgeIcons.of(c.iconKey),
        color: BadgeColors.of(c.colorKey),
      );

  /// Built-in badges (including none) + custom badges, in picker order.
  List<BadgeDef> get all => [
        for (final b in EntryBadge.values) _builtinDef(b),
        for (final c in _custom) _customDef(c),
      ];

  /// id -> resolved definition; an unknown id returns "none".
  BadgeDef resolve(String id) {
    for (final b in EntryBadge.values) {
      if (b.name == id) return _builtinDef(b);
    }
    for (final c in _custom) {
      if (c.id == id) return _customDef(c);
    }
    return _builtinDef(EntryBadge.none);
  }
}
