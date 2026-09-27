import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/audio_service.dart';

/// Persistent strip shown on the other tabs while recording.
/// It does not vanish on tab change so the user cannot forget the
/// recording and can stop it with a single safe tap.
class RecordingBanner extends StatefulWidget {
  final AudioService audio;
  final VoidCallback onStop;

  const RecordingBanner({super.key, required this.audio, required this.onStop});

  @override
  State<RecordingBanner> createState() => _RecordingBannerState();
}

class _RecordingBannerState extends State<RecordingBanner> {
  Timer? _tick;
  String _elapsed = '00:00';

  @override
  void initState() {
    super.initState();
    _update();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final start = widget.audio.startedAt;
    final d = start == null ? Duration.zero : DateTime.now().difference(start);
    final label =
        '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    if (mounted) setState(() => _elapsed = label);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          children: [
            Icon(Icons.fiber_manual_record, size: 14, color: cs.error),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                excludeSemantics: true,
                label: '${l.recordingActive} $_elapsed',
                child: Text(
                  '${l.recordingActive} • $_elapsed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: cs.onErrorContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onStop,
              child: Text(l.stop),
            ),
          ],
        ),
      ),
    );
  }
}
