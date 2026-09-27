import 'package:flutter/material.dart';
import 'package:record/record.dart';

/// Live waveform while recording. Feeds on the mic amplitude stream;
/// keeps the last [bars] levels and paints them as rounded bars.
class RecordingWave extends StatefulWidget {
  final Stream<Amplitude> stream;
  final Color color;
  final int bars;
  final double height;

  const RecordingWave({
    super.key,
    required this.stream,
    required this.color,
    this.bars = 36,
    this.height = 56,
  });

  @override
  State<RecordingWave> createState() => _RecordingWaveState();
}

class _RecordingWaveState extends State<RecordingWave> {
  final List<double> _levels = [];

  static double _norm(Amplitude a) {
    // dBFS: silence ~ -160, loud ~ 0. Map [-55, -5] -> [0.08, 1].
    if (a.current <= -160) return 0.08;
    return (((a.current + 55) / 50).clamp(0.0, 1.0) * 0.92 + 0.08);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: StreamBuilder<Amplitude>(
        stream: widget.stream,
        builder: (context, snap) {
          if (snap.hasData) {
            _levels.add(_norm(snap.data!));
            while (_levels.length > widget.bars) {
              _levels.removeAt(0);
            }
          }
          return CustomPaint(
            painter: _WavePainter(
              levels: List.of(_levels),
              bars: widget.bars,
              color: widget.color,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> levels;
  final int bars;
  final Color color;

  _WavePainter({required this.levels, required this.bars, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / bars;
    final w = slot * 0.45;
    final midY = size.height / 2;
    for (var i = 0; i < bars; i++) {
      final lvl = i < levels.length ? levels[i] : 0.08;
      final h = (size.height * lvl).clamp(4.0, size.height) / 2;
      final x = slot * i + slot / 2;
      final paint = Paint()
        // Level: height + opacity convey it, color comes from one source.
        ..color = color.withValues(alpha: 0.35 + 0.65 * lvl.clamp(0.0, 1.0))
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w;
      // symmetric: up + down from the center
      canvas.drawLine(Offset(x, midY - h), Offset(x, midY + h), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.levels != levels;
}
