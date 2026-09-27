import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Delete feedback with a visible countdown. Disappears by itself after
/// [seconds] and reports back via [onExpired]; [onUndo] restores the entry.
/// Own timer -> never gets stuck on screen.
///
/// Accessibility: the countdown is announced every second to the screen
/// reader (liveRegion); when the time is up and [expiredText] is given a
/// SnackBar is shown and the same text is announced.
class UndoBar extends StatefulWidget {
  final String text;
  final String undoLabel;

  /// Message to show/announce when the time is up. Closes silently if null.
  final String? expiredText;
  final double seconds;
  final VoidCallback onUndo;
  final VoidCallback onExpired;

  const UndoBar({
    super.key,
    required this.text,
    required this.undoLabel,
    this.expiredText,
    required this.onUndo,
    required this.onExpired,
    this.seconds = 4,
  });

  @override
  State<UndoBar> createState() => _UndoBarState();
}

class _UndoBarState extends State<UndoBar> {
  late double _left;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _left = widget.seconds;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _left -= 0.1);
      if (_left <= 0 && !_done) {
        _done = true;
        _timer?.cancel();
        _notifyExpired();
        widget.onExpired();
      }
    });
  }

  /// Time is up: visual SnackBar + screen reader announcement.
  void _notifyExpired() {
    final msg = widget.expiredText;
    if (msg == null) return;
    try {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
      );
    } catch (_) {}
    try {
      SemanticsService.sendAnnouncement(
        View.of(context),
        msg,
        Directionality.of(context),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secs = _left.clamp(0, widget.seconds).toStringAsFixed(0);
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.delete_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  // The screen reader announces the new value on every change.
                  child: Semantics(
                    liveRegion: true,
                    excludeSemantics: true,
                    label: '${widget.text} ($secs)',
                    child: Text(
                      '${widget.text} ($secs)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_done) return;
                    _done = true;
                    _timer?.cancel();
                    widget.onUndo();
                  },
                  child: Text(widget.undoLabel),
                ),
              ],
            ),
            const SizedBox(height: 2),
            LinearProgressIndicator(
              value: (_left / widget.seconds).clamp(0.0, 1.0),
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }
}
