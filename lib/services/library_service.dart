import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entry_badge.dart';
import '../models/voice_entry.dart';

/// Local list + Supabase sync.
/// Works on the device only when Supabase is not set up (offline).
class LibraryService {
  final List<VoiceEntry> entries = [];
  final _ctrl = StreamController<List<VoiceEntry>>.broadcast();
  Stream<List<VoiceEntry>> get stream => _ctrl.stream;

  static const _kBadges = 'entry_badges';
  final Map<String, String> _badges = {};
  bool _badgesLoaded = false;

  // Notes: in SharedPreferences while there is no DB (id=note;...). Same pattern as badges.
  static const _kNotes = 'entry_notes';
  final Map<String, String> _notes = {};
  bool _notesLoaded = false;

  // Images: id -> local file paths (JSON). Same pattern as notes.
  static const _kImages = 'entry_images';
  final Map<String, List<String>> _images = {};
  bool _imagesLoaded = false;

  /// Loads local notes and applies them to the list (JSON map; note is free text).
  Future<void> initNotes() async {
    if (_notesLoaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kNotes);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (k is String && v is String) _notes[k] = v;
          });
        }
      }
    } catch (_) {}
    _notesLoaded = true;
    var changed = false;
    for (var i = 0; i < entries.length; i++) {
      final n = _notes[entries[i].id];
      if (n != null && n != (entries[i].note ?? '')) {
        entries[i] = entries[i].copyWith(note: n);
        changed = true;
      }
    }
    if (changed) _ctrl.add(List.unmodifiable(entries));
  }

  Future<void> _ensureNotes() async {
    if (!_notesLoaded) await initNotes();
  }

  /// Loads local image paths and applies them to the list.
  Future<void> initImages() async {
    if (_imagesLoaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kImages);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (k is String && v is List) {
              _images[k] = v.whereType<String>().toList();
            }
          });
        }
      }
    } catch (_) {}
    _imagesLoaded = true;
    var changed = false;
    for (var i = 0; i < entries.length; i++) {
      final imgs = _images[entries[i].id];
      if (imgs != null && !_listEq(imgs, entries[i].images)) {
        entries[i] = entries[i].copyWith(images: List.unmodifiable(imgs));
        changed = true;
      }
    }
    if (changed) _ctrl.add(List.unmodifiable(entries));
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _ensureImages() async {
    if (!_imagesLoaded) await initImages();
  }

  Future<void> _saveImages() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kImages, jsonEncode(_images));
    } catch (_) {}
  }

  List<String> imagesOf(String id) => _images[id] ?? const [];

  /// Add image(s) to an entry (the caller has already copied the files into
  /// the media folder). Updates the list and persistent storage.
  Future<void> addImages(String id, List<String> paths) async {
    if (paths.isEmpty) return;
    await _ensureImages();
    final list = _images.putIfAbsent(id, () => []);
    list.addAll(paths);
    await _saveImages();
    final i = entries.indexWhere((x) => x.id == id);
    if (i >= 0) {
      entries[i] = entries[i].copyWith(images: List.unmodifiable(list));
      _ctrl.add(List.unmodifiable(entries));
    }
  }

  /// Removes a single image: delete the file, drop it from the list.
  Future<void> removeImage(String id, String path) async {
    await _ensureImages();
    final list = _images[id];
    if (list == null || !list.contains(path)) return;
    list.remove(path);
    if (list.isEmpty) _images.remove(id);
    await _saveImages();
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    final i = entries.indexWhere((x) => x.id == id);
    if (i >= 0) {
      entries[i] = entries[i].copyWith(images: List.unmodifiable(list));
      _ctrl.add(List.unmodifiable(entries));
    }
  }

  Future<void> _saveNotes() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kNotes, jsonEncode(_notes));
    } catch (_) {}
  }

  /// Add/update/clear a note. Updates the list and persistent storage, and
  /// updates Supabase in the background when sync is on.
  Future<void> setNote(String id, String? note) async {
    await _ensureNotes();
    final clean = (note ?? '').trim();
    if (clean.isEmpty) {
      _notes.remove(id);
    } else {
      _notes[id] = clean;
    }
    await _saveNotes();
    final i = entries.indexWhere((x) => x.id == id);
    if (i < 0) return;
    entries[i] = entries[i]
        .copyWith(note: clean.isEmpty ? null : clean, clearNote: clean.isEmpty);
    _ctrl.add(List.unmodifiable(entries));
    await uploadNote(id, clean.isEmpty ? null : clean);
  }

  /// Updates the Supabase note column (passes silently when offline).
  Future<void> uploadNote(String id, String? note) async {
    if (!syncEnabled) return;
    try {
      final client = Supabase.instance.client;
      await client.from('voice_entries').update({'note': note}).eq('id', id);
    } catch (_) {}
  }

  /// Loads local badges from SharedPreferences (persistence while there is no DB).
  Future<void> initBadges() async {
    if (_badgesLoaded) return;
    // Notes and images load at the same time (ready on startup).
    await initNotes();
    await initImages();
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kBadges);
      if (raw != null && raw.isNotEmpty) {
        // simple format: id=badge;id=badge
        for (final part in raw.split(';')) {
          final kv = part.split('=');
          if (kv.length == 2 && kv[0].isNotEmpty) _badges[kv[0]] = kv[1];
        }
      }
    } catch (_) {}
    _badgesLoaded = true;
    // apply the loaded badges to the current list
    var changed = false;
    for (var i = 0; i < entries.length; i++) {
      final b = _badges[entries[i].id] ?? EntryBadge.none.name;
      if (b != entries[i].badgeId) {
        entries[i] = entries[i].copyWith(badgeId: b);
        changed = true;
      }
    }
    if (changed) _ctrl.add(List.unmodifiable(entries));
  }

  Future<void> _ensureBadges() async {
    if (!_badgesLoaded) await initBadges();
  }

  Future<void> _saveBadges() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = _badges.entries.map((e) => '${e.key}=${e.value}').join(';');
      await p.setString(_kBadges, raw);
    } catch (_) {}
  }

  bool get syncEnabled {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  void add(VoiceEntry e) {
    final withBadge = e.copyWith(badgeId: _badges[e.id] ?? e.badgeId);
    // New entries arrive without a note; apply a leftover note for the same id.
    final savedNote = _notes[e.id];
    final withNote =
        savedNote != null ? withBadge.copyWith(note: savedNote) : withBadge;
    final savedImages = _images[e.id];
    final withImages = savedImages != null
        ? withNote.copyWith(images: List.unmodifiable(savedImages))
        : withNote;
    entries.insert(0, withImages);
    _ctrl.add(List.unmodifiable(entries));
    // upload in the background (fire & forget)
    unawaited(upload(withBadge));
  }

  /// Old entries coming from the disk scan: added to the list without uploading.
  void addScanned(List<VoiceEntry> list) {
    final known = entries.map((e) => e.path).toSet();
    for (final e in list) {
      if (!known.contains(e.path)) {
        final withBadge = e.copyWith(badgeId: _badges[e.id] ?? e.badgeId);
        final savedNote = _notes[e.id];
        final withNote =
            savedNote != null ? withBadge.copyWith(note: savedNote) : withBadge;
        final savedImages = _images[e.id];
        entries.add(savedImages != null
            ? withNote.copyWith(images: List.unmodifiable(savedImages))
            : withNote);
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _ctrl.add(List.unmodifiable(entries));
    // if badges are not loaded yet, load and apply them in the background
    if (!_badgesLoaded) unawaited(initBadges());
  }

  /// Change a badge: update the list + store it locally.
  /// [badgeId] can be a built-in enum name ('favorite') or a custom badge id.
  Future<void> setBadge(String id, String badgeId) async {
    await _ensureBadges();
    if (badgeId == EntryBadge.none.name) {
      _badges.remove(id);
    } else {
      _badges[id] = badgeId;
    }
    await _saveBadges();
    final i = entries.indexWhere((x) => x.id == id);
    if (i < 0) return;
    entries[i] = entries[i].copyWith(badgeId: badgeId);
    _ctrl.add(List.unmodifiable(entries));
  }

  /// Flags an entry found on disk during a scan that cannot be opened:
  /// it stays in the list (not deleted) and is shown as "not playable" on the tile.
  void markBroken(String id) {
    final i = entries.indexWhere((x) => x.id == id);
    if (i < 0 || entries[i].broken) return;
    entries[i] = entries[i].copyWith(broken: true);
    _ctrl.add(List.unmodifiable(entries));
  }

  /// Drops an empty/incomplete (0 byte) entry from the list; also clears its note/badge records.
  void discardBroken(String id) {
    final i = entries.indexWhere((x) => x.id == id);
    if (i < 0) return;
    entries.removeAt(i);
    _badges.remove(id);
    _notes.remove(id);
    unawaited(_saveBadges());
    unawaited(_saveNotes());
    _ctrl.add(List.unmodifiable(entries));
  }

  /// Updates the duration once it is known (disk scan).
  void updateDuration(String id, int sec) {
    final i = entries.indexWhere((x) => x.id == id);
    if (i < 0) return;
    final e = entries[i];
    entries[i] = e.copyWith(durationSec: sec);
    _ctrl.add(List.unmodifiable(entries));
  }

  Future<void> upload(VoiceEntry e) async {
    if (!syncEnabled) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      final file = File(e.path);
      if (!await file.exists()) return;
      final key = '${user?.id ?? 'anon'}/${e.dayKey}/${e.id}.m4a';
      await client.storage.from('voice-notes').upload(
            key,
            file,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'audio/mp4'),
          );
      await client.from('voice_entries').upsert(
            e.toSupabase(key)
              ..['user_id'] = user?.id
              ..['local_path'] = e.path,
          );
      final i = entries.indexWhere((x) => x.id == e.id);
      if (i >= 0) {
        entries[i] = entries[i].copyWith(uploaded: true);
        _ctrl.add(List.unmodifiable(entries));
      }
    } catch (_) {
      // offline: pass silently, the entry stays on the device
    }
  }

  Map<DateTime, List<VoiceEntry>> byDay() {
    final map = <DateTime, List<VoiceEntry>>{};
    for (final e in entries) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      map.putIfAbsent(d, () => []).add(e);
    }
    return map;
  }

  /// Delete + undo: the file is moved to the trash folder first.
  /// [trash] drops it from the list and moves it to temp, [restore] undoes that,
  /// [purge] deletes permanently (file + cloud). The UI waits for purge until the snackbar expires.
  /// [allowMissing]: also create a token for an entry that never made it into
  /// the list (a recording cancelled with a long press is not visible).
  Future<TrashToken?> trash(VoiceEntry e,
      {bool allowMissing = false, bool fromDiscard = false}) async {
    final i = entries.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      entries.removeAt(i);
      _ctrl.add(List.unmodifiable(entries));
    } else if (!allowMissing) {
      return null;
    }
    final trashDir = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}snipvoice_trash');
    try {
      await trashDir.create(recursive: true);
    } catch (_) {}
    final tempPath = '${trashDir.path}${Platform.pathSeparator}${e.id}.m4a';
    var moved = false;
    try {
      final f = File(e.path);
      if (await f.exists()) {
        try {
          await f.rename(tempPath);
        } catch (_) {
          // different drive: copy + delete
          await f.copy(tempPath);
          await f.delete();
        }
        moved = true;
      }
    } catch (_) {}
    return TrashToken(
        entry: e,
        index: i < 0 ? 0 : i,
        tempPath: tempPath,
        moved: moved,
        fromDiscard: fromDiscard);
  }

  Future<void> restore(TrashToken t) async {
    if (t.moved) {
      try {
        final f = File(t.tempPath);
        if (await f.exists()) {
          try {
            await f.rename(t.entry.path);
          } catch (_) {
            await f.copy(t.entry.path);
            await f.delete();
          }
        }
      } catch (_) {}
    }
    final at = t.index.clamp(0, entries.length);
    // Already in the list? Do not add it a second time (same entry deleted twice).
    final dup = entries.indexWhere((x) => x.id == t.entry.id);
    if (dup >= 0) return;
    entries.insert(at, t.entry);
    _ctrl.add(List.unmodifiable(entries));
  }

  Future<void> purge(TrashToken t) async {
    _badges.remove(t.entry.id);
    _notes.remove(t.entry.id);
    final imgs = {
      ...(_images.remove(t.entry.id) ?? const <String>[]),
      ...t.entry.images,
    };
    await _saveBadges();
    await _saveNotes();
    if (imgs.isNotEmpty) await _saveImages();
    for (final p in imgs) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    try {
      final f = File(t.tempPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    // already removed from the list during trash; if the file could not be moved, delete the original
    if (!t.moved) {
      try {
        final f = File(t.entry.path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    if (!syncEnabled) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      final key = '${user?.id ?? 'anon'}/${t.entry.dayKey}/${t.entry.id}.m4a';
      await client.storage.from('voice-notes').remove([key]);
      await client.from('voice_entries').delete().eq('id', t.entry.id);
    } catch (_) {}
  }

  void dispose() => _ctrl.close();
}

/// Trash token: the deleted entry + its index in the list + the temp file path.
class TrashToken {
  final VoiceEntry entry;
  final int index;
  final String tempPath;
  final bool moved;

  /// Does it come from a long-press cancel during recording (never entered the list)?
  final bool fromDiscard;
  TrashToken({
    required this.entry,
    required this.index,
    required this.tempPath,
    required this.moved,
    this.fromDiscard = false,
  });
}

String env(String k) => dotenv.isInitialized ? (dotenv.maybeGet(k) ?? '') : '';
