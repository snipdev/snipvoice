import 'package:audio_session/audio_session.dart';

/// App-wide audio session, configured once in main; called idempotently by the
/// player/recorder services too.
///
/// - playAndRecord + speaker by default: playing while recording does not hit a
///   category conflict on iOS; Bluetooth headset mic stays open.
/// - Android focus type gainTransient: other apps pause so they do not record
///   our mic; they resume once we are done.
/// - Interruption (incoming call) and becoming-noisy (headphones unplugged)
///   events are listened to by the services.
Future<void> configureAudioSession() async {
  try {
    final s = await AudioSession.instance;
    await s.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.allowBluetooth,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
    ));
  } catch (_) {
    // Unsupported platform (Windows): ignore.
  }
}
