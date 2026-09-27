import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Note preset: predefined text that can be written to an entry with one tap.
class NotePreset {
  final String id;
  final String text;
  const NotePreset({required this.id, required this.text});

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  static NotePreset? fromJson(Map m) {
    final id = m['id'];
    final text = m['text'];
    if (id is! String || text is! String) return null;
    return NotePreset(id: id, text: text);
  }
}

/// Note preset catalog: a few sample templates + the ones the user adds.
/// Singleton; notifies listeners on change (ChangeNotifier).
class NotePresetService extends ChangeNotifier {
  NotePresetService._();
  static final NotePresetService instance = NotePresetService._();

  static const _kPresets = 'note_presets';
  static const _kLocale = 'app_locale';

  static const List<String> _defaultsEn = [
    'FOMO — entered too late',
    'Off-plan entry',
    'Stopped out on noise',
    'Against the trend',
    'Waited patiently',
  ];
  static const List<String> _defaultsTr = [
    'FOMO — geç girdim',
    'Plan dışı giriş',
    'Gürültüde stop oldum',
    'Trende karşı',
    'Sabırla bekledim',
  ];

  final List<NotePreset> _items = [];
  bool _loaded = false;

  List<NotePreset> get items => List.unmodifiable(_items);

  /// Called once before the app is shown.
  /// On first launch a few samples are added based on the app language; after
  /// that they can be edited and deleted like normal entries.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kPresets);
      if (raw == null) {
        // Never saved before: seed the samples.
        final tr =
            (p.getString(_kLocale) ?? 'en').toLowerCase().startsWith('tr');
        for (final t in (tr ? _defaultsTr : _defaultsEn)) {
          _items.add(NotePreset(id: _newId(), text: t));
        }
        await _save();
      } else if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final np = NotePreset.fromJson(item);
              if (np != null) _items.add(np);
            }
          }
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  static String _newId() => 'preset:${const Uuid().v4().substring(0, 8)}';

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _kPresets, jsonEncode(_items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<NotePreset> add(String text) async {
    final np = NotePreset(id: _newId(), text: text.trim());
    _items.add(np);
    await _save();
    notifyListeners();
    return np;
  }

  Future<void> update(String id, String text) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = NotePreset(id: id, text: text.trim());
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }
}
