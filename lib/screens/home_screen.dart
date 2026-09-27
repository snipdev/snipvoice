import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/voice_entry.dart';
import '../services/audio_service.dart';
import '../services/entry_media.dart';
import '../services/library_service.dart';
import '../services/playback_service.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../widgets/center_shell.dart';
import '../widgets/entry_tile.dart';
import '../widgets/market_schedule_sheet.dart';
import '../widgets/now_header.dart';
import '../widgets/recording_wave.dart';
import '../widgets/undo_bar.dart';

class HomeScreen extends StatefulWidget {
  final LibraryService library;
  final StorageService storage;

  /// Optional: injectable in tests; nil means the app-wide singleton.
  final PlaybackService? playback;
  const HomeScreen(
      {super.key, required this.library, required this.storage, this.playback});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _audio = AudioService();
  static final _shared = PlaybackService();
  PlaybackService get _pb => widget.playback ?? _shared;
  StreamSubscription<String?>? _playingSub;
  StreamSubscription<bool>? _recSub;
  Timer? _recTick;
  int _recSec = 0;
  String? _playingId;
  static const _kOfflineHidden = 'offline_notice_hidden';
  static const _kMicIntro = 'mic_intro_shown';
  bool _offlineHidden = false;

  @override
  void initState() {
    super.initState();
    // Shared player: playback started/stopped in another tab reflects here too.
    _playingId = _pb.playingId;
    _playingSub = _pb.playingStream.listen((id) {
      if (mounted) setState(() => _playingId = id);
    });
    // An incoming call / audio interruption stops the recording: save and notify.
    _audio.onAutoStopped = _onInterruptionStop;
    // If the recording is stopped externally (exit guard / tab swiping), sync the UI.
    _recSub = _audio.recordingStream.listen((rec) {
      if (!mounted) return;
      if (!rec) _recTick?.cancel();
      setState(() {});
    });
    widget.storage.storageVersion.addListener(_onStorageChanged);
    _lib.initBadges();
    _loadOfflinePref();
    _scanDisk();
  }

  Future<void> _loadOfflinePref() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _offlineHidden = p.getBool(_kOfflineHidden) ?? false);
    } catch (_) {}
  }

  Future<void> _setOfflineHidden(bool v) async {
    setState(() => _offlineHidden = v);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kOfflineHidden, v);
    } catch (_) {}
  }

  void _onStorageChanged() {
    if (!mounted) return;
    setState(() {});
    _scanDisk();
  }

  /// Take files left over from previous sessions into the list, resolve their
  /// durations and rescue the unplayable ones: drop empty files, flag the rest.
  Future<void> _scanDisk() async {
    final found = await widget.storage.scan();
    if (found.isEmpty || !mounted) return;
    _lib.addScanned(found);
    var broken = 0;
    for (final e in found) {
      if (e.durationSec > 0) continue;
      // Do not touch the player while playback runs; leave it to the next scan.
      if (_pb.playingId != null) break;
      final sec = await _pb.resolveDuration(e.path);
      if (!mounted) return;
      if (sec >= 0) {
        if (sec > 0) _lib.updateDuration(e.id, sec);
        continue;
      }
      // Unresolved: delete the empty/truncated file, flag the one with data.
      final size = await _fileSize(e.path);
      if (size <= 0) {
        _lib.discardBroken(e.id);
        await _deleteQuiet(e.path);
      } else {
        _lib.markBroken(e.id);
        broken++;
      }
    }
    if (broken > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).unplayableNotice(broken)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<int> _fileSize(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return -1;
      return await f.length();
    } catch (_) {
      return -1;
    }
  }

  Future<void> _deleteQuiet(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }

  LibraryService get _lib => widget.library;

  Future<void> _openMarketSheet(SessionInfo s) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => MarketScheduleSheet(current: s),
    );
  }

  @override
  void dispose() {
    widget.storage.storageVersion.removeListener(_onStorageChanged);
    _playingSub?.cancel();
    _recSub?.cancel();
    _recTick?.cancel();
    // Shared singleton: not disposed here (the app shell uses it too).
    super.dispose();
  }

  /// Permission gate before starting a recording: on first use it shows a short
  /// explanation before the system dialog; a permanent denial goes to settings.
  Future<bool> _ensureMicPermission() async {
    final l = AppLocalizations.of(context);
    // On desktop (Windows) there is no mic permission dialog; record runs directly.
    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        if (await _audio.hasPermission(request: true)) return true;
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.micPermission)));
      }
      return false;
    }

    var status = await Permission.microphone.status;
    if (status.isGranted) return true;

    // Permanently denied: the system dialog will not show again -> go to settings.
    if (status.isPermanentlyDenied) {
      await _openMicSettings(l);
      return false;
    }

    // First use: show the explanation once.
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kMicIntro) ?? false)) {
      if (!mounted) return false;
      final cont = await _showMicIntro(l);
      if (cont != true) return false;
      await prefs.setBool(_kMicIntro, true);
    }

    status = await Permission.microphone.request();
    if (status.isGranted) return true;
    if (!mounted) return false;
    if (status.isPermanentlyDenied) {
      await _openMicSettings(l);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.micPermission)));
    }
    return false;
  }

  Future<bool?> _showMicIntro(AppLocalizations l) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.mic_none_outlined),
          title: Text(l.micIntroTitle),
          content: Text(l.micIntroBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.micContinue)),
          ],
        ),
      );

  Future<void> _openMicSettings(AppLocalizations l) async {
    if (!mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.mic_off_outlined),
        title: Text(l.micDeniedTitle),
        content: Text(l.micDeniedBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.openSettings)),
        ],
      ),
    );
    if (open == true) {
      try {
        await openAppSettings();
      } catch (_) {}
    }
  }

  Future<void> _startRecording() async {
    await HapticFeedback.lightImpact();
    await _audio.start(await widget.storage.dayFolder(DateTime.now()));
    setState(() => _recSec = 0);
    _recTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recSec++);
    });
    setState(() {});
  }

  Future<void> _toggleRecord() async {
    if (!_audio.isRecording) {
      if (!await _ensureMicPermission()) return;
      await _startRecording();
    } else {
      _recTick?.cancel();
      final entry = await _audio.stop();
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      if (entry != null) {
        _lib.add(entry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).recordSaved(entry.durationLabel)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      setState(() {});
    }
  }

  /// An interruption (a call, etc.) stopped the recording: save the file and notify.
  void _onInterruptionStop(VoiceEntry? entry) {
    _recTick?.cancel();
    if (!mounted) return;
    if (entry != null) {
      _lib.add(entry);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).recInterrupted),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    setState(() {});
  }

  /// Long press: cancel the recording. The file is not deleted on the spot; it
  /// moves to the trash, undoable until the UndoBar countdown expires, then purged.
  Future<void> _discardRecording() async {
    if (!_audio.isRecording) return;
    _recTick?.cancel();
    final entry = await _audio.stop();
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() {});
    if (entry == null) return;
    // Confirm the previous pending operation, load the new bin.
    if (_pending != null) {
      final old = _pending!;
      _pending = null;
      await _lib.purge(old);
    }
    final token =
        await _lib.trash(entry, allowMissing: true, fromDiscard: true);
    if (!mounted || token == null) return;
    setState(() => _pending = token);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).recDiscarded)));
  }

  /// Delete + timed undo bar. A new delete confirms the previous one.
  TrashToken? _pending;

  Future<void> _deleteEntry(VoiceEntry e) async {
    if (_playingId == e.id) await _pb.stop();
    if (_pending != null) {
      final old = _pending!;
      _pending = null;
      await _lib.purge(old);
    }
    final token = await _lib.trash(e);
    if (!mounted || token == null) return;
    await HapticFeedback.lightImpact();
    setState(() => _pending = token);
  }

  void _undoDelete() {
    final token = _pending;
    if (token == null) return;
    setState(() => _pending = null);
    _lib.restore(token);
    // A discarded entry never reached the list, so it was not uploaded; it is restored.
    if (token.fromDiscard) _lib.upload(token.entry);
  }

  void _expireDelete() {
    final token = _pending;
    if (token == null) return;
    setState(() => _pending = null);
    _lib.purge(token);
  }

  /// Attach images to an entry: pick files -> copy to the media folder -> save.
  Future<void> _addImages(VoiceEntry e) async {
    final title = AppLocalizations.of(context).pickImagesTitle;
    await attachImagesToEntry(
      library: _lib,
      storage: widget.storage,
      entry: e,
      dialogTitle: title,
    );
  }

  Future<void> _play(VoiceEntry e) async {
    try {
      await _pb.toggle(e.id, e.path);
      // If there is no error the stream change reports it; no need to wait.
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).playbackFailed(err))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rec = _audio.isRecording;
    final recLabel =
        '${(_recSec ~/ 60).toString().padLeft(2, '0')}:${(_recSec % 60).toString().padLeft(2, '0')}';

    return SafeArea(
      // The top block is fixed (clock + BIG BUTTON), the list scrolls on its own
      // below. On short screens the button shrinks (compact mode).
      child: CenterShell(
        child: LayoutBuilder(
          builder: (context, cons) {
            final compact = cons.maxHeight < 700;
            final diam = compact ? 140.0 : 210.0;
            final iconSize = compact ? 40.0 : 56.0;
            final labelSize = compact ? 20.0 : 26.0;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Clock + market badge: a separate widget with its own
                  // per-second timer, so the list is not rebuilt every second.
                  NowHeader(
                    syncEnabled: _lib.syncEnabled,
                    offlineHidden: _offlineHidden,
                    onShowOffline: () => _setOfflineHidden(false),
                    onOpenSchedule: _openMarketSheet,
                  ),
                  SizedBox(height: compact ? 4 : 8),
                  if (!_lib.syncEnabled && !_offlineHidden)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MaterialBanner(
                        content: Text(l.offlineNotice,
                            style: const TextStyle(fontSize: 12)),
                        leading: const Icon(Icons.cloud_off_outlined, size: 20),
                        padding: const EdgeInsets.all(12),
                        actions: [
                          TextButton(
                            onPressed: () => _setOfflineHidden(true),
                            child: Text(l.close),
                          ),
                        ],
                      ),
                    ),
                  // BIG BUTTON + live wave shape (fixed diameter: no layout shift)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onLongPress: _discardRecording,
                          child: Semantics(
                            button: true,
                            label: rec ? l.stop : l.start,
                            // While recording the long press hint is passed to
                            // the screen reader as well.
                            hint: rec ? l.recLongPress : null,
                            child: InkResponse(
                              onTap: _toggleRecord,
                              customBorder: const CircleBorder(),
                              containedInkWell: true,
                              highlightShape: BoxShape.circle,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: diam,
                                height: diam,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: rec
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (rec
                                              ? Colors.red
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(rec ? Icons.stop : Icons.mic,
                                        size: iconSize, color: Colors.white),
                                    const SizedBox(height: 4),
                                    if (rec)
                                      // Live counter: the duration, updated every
                                      // second, is announced to the screen reader.
                                      Semantics(
                                        liveRegion: true,
                                        // Do not read the child text too; the
                                        // announcement comes from the label only.
                                        excludeSemantics: true,
                                        label: l.recElapsed(recLabel),
                                        child: Text(
                                          recLabel,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: labelSize,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    else
                                      Text(
                                        l.start,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: labelSize,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    if (rec)
                                      Text(l.recLongPress,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: rec
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SizedBox(
                                    width: 280,
                                    child: RecordingWave(
                                      stream: _audio.amplitudes(),
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l.recordingsTitle(_lib.entries.length),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  if (_pending != null) ...[
                    const SizedBox(height: 4),
                    UndoBar(
                      key: ValueKey(_pending!),
                      text: _pending!.fromDiscard ? l.discarded : l.deleted,
                      undoLabel: l.undo,
                      expiredText: l.undoExpired,
                      onUndo: _undoDelete,
                      onExpired: _expireDelete,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Expanded(
                    child: StreamBuilder<List<VoiceEntry>>(
                      stream: _lib.stream,
                      builder: (context, snap) {
                        final list = snap.data ?? _lib.entries;
                        if (list.isEmpty) {
                          // No entries: icon + text (the record button is on top)
                          return Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic_none_outlined,
                                      size: 48,
                                      color: Theme.of(context).disabledColor),
                                  const SizedBox(height: 12),
                                  Text(l.emptyList,
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final e = list[i];
                            return EntryTile(
                              entry: e,
                              playing: _playingId == e.id,
                              player: _pb.player,
                              onPlay: () => _play(e),
                              onDelete: () => _deleteEntry(e),
                              onBadgeChanged: (b) => _lib.setBadge(e.id, b),
                              onNoteChanged: (n) => _lib.setNote(e.id, n),
                              onAddImages: () => _addImages(e),
                              onRemoveImage: (p) => _lib.removeImage(e.id, p),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
