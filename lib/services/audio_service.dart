import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../services/audio_session_setup.dart';
import '../services/session_service.dart';
import '../models/voice_entry.dart';

/// Single-button recording service: start/stop. Records m4a (AAC).
///
/// If an interruption arrives (incoming call, another app taking the mic) the
/// running recording is stopped safely and reported through [onAutoStopped];
/// this way no truncated/corrupt file is left behind.
class AudioService {
  /// Single recording service for the whole app: the app shell (exit guard,
  /// tab bar) reaches the same state whether Home started the recording or not.
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final AudioRecorder _rec = AudioRecorder();
  bool _recording = false;
  DateTime? _startedAt;
  String? _path;

  final _recCtrl = StreamController<bool>.broadcast();

  /// Recording state changes (started / stopped / cancelled).
  Stream<bool> get recordingStream => _recCtrl.stream;

  void _emit() {
    if (!_recCtrl.isClosed) _recCtrl.add(_recording);
  }

  StreamSubscription<AudioInterruptionEvent>? _intSub;
  bool _sessionInit = false;

  /// Called when a recording is auto-stopped by an interruption; the finished
  /// [VoiceEntry] is delivered if there is one (the UI adds and reports it).
  void Function(VoiceEntry? entry)? onAutoStopped;

  bool get isRecording => _recording;
  DateTime? get startedAt => _startedAt;

  /// If [request] is true the system permission is asked for when needed; if
  /// false only the current state is queried (always true on desktop).
  Future<bool> hasPermission({bool request = true}) async =>
      await _rec.hasPermission(request: request);

  /// Live mic levels (dBFS) for the waveform. Windows + Android supported.
  Stream<Amplitude> amplitudes() =>
      _rec.onAmplitudeChanged(const Duration(milliseconds: 120));

  /// Start listening for interruptions once (idempotent).
  Future<void> _initSession() async {
    if (_sessionInit) return;
    _sessionInit = true;
    try {
      await configureAudioSession();
      final s = await AudioSession.instance;
      _intSub = s.interruptionEventStream.listen((e) {
        // Interruption started while recording: stop without losing data.
        if (e.begin && _recording) {
          unawaited(_autoStopForInterruption());
        }
      });
    } catch (_) {
      // Unsupported platform (Windows): pass silently.
    }
  }

  Future<void> _autoStopForInterruption() async {
    if (!_recording) return;
    VoiceEntry? entry;
    try {
      entry = await stop();
    } catch (_) {
      entry = null;
    }
    onAutoStopped?.call(entry);
  }

  /// dayDir: taken from StorageService.dayFolder() (supports a user folder).
  Future<String> start(Directory folder) async {
    await _initSession();
    final day = DateTime.now();
    await folder.create(recursive: true);
    _path =
        '${folder.path}${Platform.pathSeparator}${SessionService.fileTag(day)}_${const Uuid().v4().substring(0, 6)}.m4a';

    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _path!,
    );
    _recording = true;
    _startedAt = day;
    _emit();
    return _path!;
  }

  /// Stops and returns the VoiceEntry.
  Future<VoiceEntry?> stop() async {
    if (!_recording) return null;
    final p = await _rec.stop();
    _recording = false;
    _emit();
    final start = _startedAt ?? DateTime.now();
    final end = DateTime.now();
    final filePath = p ?? _path;
    if (filePath == null) return null;
    final session = SessionService.current(start);
    return VoiceEntry(
      id: const Uuid().v4(),
      path: filePath,
      createdAt: start,
      durationSec: end.difference(start).inSeconds,
      sessionLabel: session.label,
    );
  }

  void dispose() {
    _intSub?.cancel();
    _rec.dispose();
    _recCtrl.close();
  }
}
