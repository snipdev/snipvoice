import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/voice_entry.dart';

/// Recording folder management:
/// - default: Documents/snipvoice (Windows) or the app directory (Android)
/// - the user can pick another location with "Change folder", the choice is stored
/// - "Open folder": Explorer on Windows, copies the path to the clipboard on Android
class StorageService {
  static const _kCustomDir = 'voice_base_dir';
  late final SharedPreferences _prefs;
  String? _customDir;

  /// Increments on a folder change; the main screen listens and rescans from scratch.
  final storageVersion = ValueNotifier<int>(0);

  String get defaultDir => _defaultDir;
  String _defaultDir = '';

  /// Root folder for images attached to entries (kept separate from the recording folder).
  String _mediaDir = '';
  String get mediaDir => _mediaDir;
  String get baseDir => (_customDir != null && _customDir!.isNotEmpty)
      ? _customDir!
      : _defaultDir;
  bool get isCustom => _customDir != null && _customDir!.isNotEmpty;

  static Future<StorageService> init() async {
    final s = StorageService();
    s._prefs = await SharedPreferences.getInstance();
    s._customDir = s._prefs.getString(_kCustomDir);
    final docs = await getApplicationDocumentsDirectory();
    // On Windows path_provider returns the Documents folder.
    s._defaultDir = '${docs.path}${Platform.pathSeparator}snipvoice';
    s._mediaDir = '${docs.path}${Platform.pathSeparator}snipvoice_media';
    await Directory(s.baseDir).create(recursive: true);
    await Directory(s._mediaDir).create(recursive: true);
    return s;
  }

  /// Picks images (multiple) and copies them into the entry's media folder.
  /// Returns the new file paths (an empty list on cancel).
  Future<List<String>> importImages(String entryId, String dialogTitle) async {
    // file_picker 13: multi-select by default (returns a List).
    final picked = await FilePicker.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.image,
    );
    if (picked.isEmpty) return const [];
    final dir = Directory('$_mediaDir${Platform.pathSeparator}$entryId');
    await dir.create(recursive: true);
    final out = <String>[];
    for (final f in picked) {
      final dest =
          '${dir.path}${Platform.pathSeparator}${const Uuid().v4().substring(0, 8)}${_extOf(f.name)}';
      try {
        // XFile.saveTo: also copies non-local sources such as content-uri.
        await f.xFile.saveTo(dest);
        out.add(dest);
      } catch (_) {}
    }
    return out;
  }

  static String _extOf(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0) return '.png';
    final e = name.substring(i).toLowerCase();
    return e.length <= 5 ? e : '.png';
  }

  /// Silently deletes a single image file.
  Future<void> deleteMediaFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Deletes all images of an entry (when the entry is permanently deleted).
  Future<void> deleteEntryMedia(String entryId) async {
    try {
      final d = Directory('$_mediaDir${Platform.pathSeparator}$entryId');
      if (await d.exists()) await d.delete(recursive: true);
    } catch (_) {}
  }

  void dispose() => storageVersion.dispose();

  /// Day folder: <base>/2026-09-20
  Future<Directory> dayFolder(DateTime day) async {
    String p(int n) => n.toString().padLeft(2, '0');
    final dir = Directory(
        '$baseDir${Platform.pathSeparator}${day.year}-${p(day.month)}-${p(day.day)}');
    await dir.create(recursive: true);
    return dir;
  }

  /// Sets a new location with the folder picker.
  Future<bool> pickCustomDir(String dialogTitle) async {
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: dialogTitle,
    );
    if (picked == null) return false;
    _customDir = picked;
    await _prefs.setString(_kCustomDir, picked);
    await Directory(baseDir).create(recursive: true);
    storageVersion.value++;
    return true;
  }

  /// Back to the default.
  Future<void> resetToDefault() async {
    _customDir = null;
    await _prefs.remove(_kCustomDir);
    storageVersion.value++;
  }

  /// Open the folder: Explorer on Windows; copies the path to the clipboard on Android.
  /// true means the folder was opened, false means the path was shared/copied.
  Future<bool> openFolder() async {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', [baseDir]);
      return true;
    }
    return false;
  }

  /// Folder usage: recording count + total bytes (local, no Supabase).
  Future<({int count, int bytes})> usage() async {
    final root = Directory(baseDir);
    if (!await root.exists()) return (count: 0, bytes: 0);
    var count = 0;
    var bytes = 0;
    await for (final ent in root.list(recursive: true, followLinks: false)) {
      if (ent is File && ent.path.toLowerCase().endsWith('.m4a')) {
        count++;
        try {
          bytes += await ent.length();
        } catch (_) {}
      }
    }
    return (count: count, bytes: bytes);
  }

  /// Scans the existing .m4a files on disk (leftovers from earlier sessions).
  Future<List<VoiceEntry>> scan() async {
    final out = <VoiceEntry>[];
    final root = Directory(baseDir);
    if (!await root.exists()) return out;
    await for (final ent in root.list(recursive: true, followLinks: false)) {
      if (ent is File && ent.path.toLowerCase().endsWith('.m4a')) {
        try {
          final stat = await ent.stat();
          final name = ent.uri.pathSegments.last;
          out.add(VoiceEntry(
            id: 'disk-${stat.modified.millisecondsSinceEpoch}-${name.hashCode}',
            path: ent.path,
            createdAt: stat.modified,
            durationSec: 0,
            sessionLabel: _sessionFromName(name),
          ));
        } catch (_) {}
      }
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  /// Canonical session from the tag in the file name: ..._NY-AM_xxxxxx.m4a
  static String _sessionFromName(String name) {
    if (name.contains('PRE-LON')) return 'Pre-London';
    if (name.contains('NY-PRE')) return 'NY Premarket';
    if (name.contains('PRE-NY')) return 'Pre-NY';
    if (name.contains('NY-NOON')) return 'NY Lunch';
    if (name.contains('NY-AM')) return 'NY AM';
    if (name.contains('NY-PM')) return 'NY PM';
    if (name.contains('LONDON')) return 'London AM';
    if (name.contains('ASIA')) return 'Asia';
    if (name.contains('OFF')) return 'Closed';
    return '';
  }
}
