import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_session_setup.dart';

/// A single player for the whole app: Home and Calendar share the same
/// AudioPlayer. That way two tabs never play sound at once, the playing entry
/// does not get lost between tabs and duration resolution is cached in one place.
class PlaybackService {
  static final PlaybackService _instance = PlaybackService._();
  factory PlaybackService() => _instance;
  PlaybackService._();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  StreamSubscription<PlayerState>? _sub;
  StreamSubscription<AudioInterruptionEvent>? _intSub;
  StreamSubscription<void>? _noisySub;
  bool _pausedByInterruption = false;
  bool _sessionInit = false;

  final _playingCtrl = StreamController<String?>.broadcast();
  String? _playingId;

  /// Id of the entry playing right now (null if none). Kept across tab changes.
  String? get playingId => _playingId;

  /// Listen for playback state changes (both screens use this).
  Stream<String?> get playingStream => _playingCtrl.stream;

  void _init() {
    _sub ??= _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        // Entry finished -> the badge should close again (automatic on long files).
        stop().catchError((_) {});
      }
    });
    unawaited(_initSession());
  }

  /// audio_session: an incoming call / another app playing pauses playback and
  /// resumes when it ends; unplugging headphones cuts the sound.
  Future<void> _initSession() async {
    if (_sessionInit) return;
    _sessionInit = true;
    try {
      await configureAudioSession();
      final s = await AudioSession.instance;
      _intSub = s.interruptionEventStream.listen((e) {
        if (e.begin) {
          if (_playingId == null || e.type == AudioInterruptionType.unknown) {
            return;
          }
          _pausedByInterruption = true;
          _player.pause();
        } else if (_pausedByInterruption) {
          _pausedByInterruption = false;
          _player.play();
        }
      });
      _noisySub = s.becomingNoisyEventStream.listen((_) => stop());
    } catch (_) {
      // Unsupported platform (Windows): pass silently.
    }
  }

  /// Plays an entry; asking for the same entry again stops it (toggle).
  Future<void> toggle(String id, String path) async {
    _init();
    if (_playingId == id) {
      await stop();
      return;
    }
    await _player.setFilePath(path);
    _playingId = id;
    _playingCtrl.add(_playingId);
    await _player.play();
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _playingId = null;
    _playingCtrl.add(_playingId);
  }

  /// Returns a file's duration in seconds; used for entries whose duration is
  /// unknown during a disk scan. The result is cached.
  /// Returned value: >=0 resolved (may be 0, a valid very short recording),
  /// -1 file could not be opened (corrupt) or cannot be resolved right now (playback running).
  final Map<String, int> _durationCache = {};
  Future<int> resolveDuration(String path) async {
    final hit = _durationCache[path];
    if (hit != null) return hit;
    if (_playingId != null) return -1;
    try {
      final d = await _player.setFilePath(path);
      final sec = d?.inSeconds ?? 0;
      _durationCache[path] = sec;
      return sec;
    } catch (_) {
      return -1;
    }
  }

  void dispose() {
    _sub?.cancel();
    _intSub?.cancel();
    _noisySub?.cancel();
    _player.dispose();
    _playingCtrl.close();
  }
}
