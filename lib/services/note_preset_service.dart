import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Note preset: predefined text that can be written to an entry with one tap.
class NotePreset {
  final String id;
  final String text;
  const NotePreset({required this.id, required this.text});

  /// Samples shipped with the app carry a stable `builtin:<n>` id so a
  /// language switch can replace them. Anything the user adds or edits keeps
  /// its random id and is never touched.
  static const builtinPrefix = 'builtin:';
  bool get isBuiltin => id.startsWith(builtinPrefix);

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

  /// The samples for one language, in a fixed order.
  static List<NotePreset> _samplesFor(String code) {
    final texts =
        code.toLowerCase().startsWith('tr') ? _defaultsTr : _defaultsEn;
    return [
      for (var i = 0; i < texts.length; i++)
        NotePreset(id: '${NotePreset.builtinPrefix}$i', text: texts[i]),
    ];
  }

  /// The `builtin:<n>` id a sample text belongs to, or null for user text.
  static String? _sampleIdOf(String text) {
    for (final texts in [_defaultsEn, _defaultsTr]) {
      final i = texts.indexOf(text);
      if (i >= 0) return '${NotePreset.builtinPrefix}$i';
    }
    return null;
  }

  /// Called once before the app is shown.
  /// On first launch a few samples are added based on the app language; after
  /// that they can be edited and deleted like normal entries.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    var dirty = false;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kPresets);
      if (raw == null) {
        // Never saved before: seed the samples for the current app language.
        _items.addAll(_samplesFor(p.getString(_kLocale) ?? 'en'));
        dirty = true;
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
        // Installs from before the samples got stable ids stored them with
        // random ones; adopt them so a later language switch can replace them.
        dirty = _adoptSamples();
      }
    } catch (_) {}
    if (dirty) await _save();
    notifyListeners();
  }

  /// Replaces the shipped samples when the app language changes. Presets the
  /// user added or edited are kept as they are.
  Future<void> syncLocale(String code) async {
    final want = _samplesFor(code);
    final current = _items.where((e) => e.isBuiltin).toList();
    // The user removed the samples on purpose: do not bring them back.
    if (current.isEmpty) return;
    if (current.length == want.length) {
      var same = true;
      for (var i = 0; i < want.length; i++) {
        if (current[i].id != want[i].id || current[i].text != want[i].text) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    _items.removeWhere((e) => e.isBuiltin);
    _items.insertAll(0, want);
    await _save();
    notifyListeners();
  }

  /// Gives the shipped samples their stable ids. Returns true when something
  /// changed (so the caller can persist it).
  bool _adoptSamples() {
    if (_items.any((e) => e.isBuiltin)) return false;
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      final id = _sampleIdOf(_items[i].text);
      if (id == null) continue;
      _items[i] = NotePreset(id: id, text: _items[i].text);
      changed = true;
    }
    return changed;
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
