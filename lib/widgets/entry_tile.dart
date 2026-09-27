import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/voice_entry.dart';
import '../services/badge_service.dart';
import '../services/session_service.dart';
import 'badge_picker.dart';
import 'image_viewer.dart';
import 'note_editor_dialog.dart';

/// Human file size: 842 B, 96 KB, 1.2 MB.
String formatBytes(int bytes, String localeCode) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) {
    final s = kb >= 100
        ? kb.toStringAsFixed(0)
        : kb.toStringAsFixed(1).replaceAll('.', localeCode == 'tr' ? ',' : '.');
    return '$s KB';
  }
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1).replaceAll('.', localeCode == 'tr' ? ',' : '.')} MB';
}

/// Shared recording row: play + badge + open + share + delete.
/// Date like "20/09/26 Sunday • 14:32" (locale-aware, compact for phones).
class EntryTile extends StatelessWidget {
  final VoiceEntry entry;
  final bool playing;
  final AudioPlayer? player;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final ValueChanged<String>? onBadgeChanged;
  final ValueChanged<String>? onNoteChanged;
  final VoidCallback? onAddImages;
  final ValueChanged<String>? onRemoveImage;

  const EntryTile({
    super.key,
    required this.entry,
    required this.playing,
    this.player,
    required this.onPlay,
    required this.onDelete,
    this.onBadgeChanged,
    this.onNoteChanged,
    this.onAddImages,
    this.onRemoveImage,
  });

  static String fullDate(DateTime d, String localeCode) =>
      DateFormat('dd/MM/yy EEEE', localeCode).format(d);

  /// System share sheet: WhatsApp, Bluetooth, Drive... (Android + Windows).
  static Future<void> share(VoiceEntry entry, AppLocalizations l) async {
    final when =
        '${fullDate(entry.createdAt, l.localeName)} • ${DateFormat('HH:mm').format(entry.createdAt)}';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(entry.path, mimeType: 'audio/mp4')],
        text: '${l.appTitle} • $when • ${entry.sessionLabel}',
      ),
    );
  }

  /// Open with an external app (music player, editor...).
  static Future<void> openWith(
      BuildContext context, VoiceEntry entry, AppLocalizations l) async {
    final res = await OpenFilex.open(entry.path, type: 'audio/mp4');
    if (res.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.cannotOpen}: ${res.message}')));
    }
  }

  /// Note editing: open the dialog, report the result (null = cancel) back.
  Future<void> _editNote(BuildContext context) async {
    final text = await NoteEditorDialog.show(context, entry.note);
    if (text != null) onNoteChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final code = Localizations.localeOf(context).languageCode;
    final badge = BadgeService.instance.resolve(entry.badgeId);
    final cs = Theme.of(context).colorScheme;
    final hasNote = (entry.note ?? '').trim().isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) Info on its own row: date + badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${fullDate(entry.createdAt, code)} • ${DateFormat('HH:mm').format(entry.createdAt)}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!badge.isNone) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badge.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badge.color),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badge.icon, size: 14, color: badge.color),
                        const SizedBox(width: 4),
                        Text(BadgePicker.labelFor(badge, l),
                            style: TextStyle(
                                fontSize: 12,
                                color: badge.color,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            // 2) Second row: session • duration • size • status
            _Subtitle(entry: entry, l: l, code: code),
            // 3) Note (if any): tapping it opens the edit dialog.
            if (hasNote) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _editNote(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.note!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Images: the pictures attached to the entry; they scroll right as the count grows.
            if (entry.images.isNotEmpty) ...[
              const SizedBox(height: 6),
              _ImageStrip(paths: entry.images, onRemove: onRemoveImage),
            ],
            const SizedBox(height: 8),
            // Controls: wide play + delete + overflow menu (does not overflow on
            // narrow screens). Fixed height: when the seek bar is added once
            // playback starts the row must not grow, the tile must not jump.
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    // A broken recording cannot be played: the button is disabled, a warning icon shows.
                    onPressed: entry.broken ? null : onPlay,
                    icon: Icon(entry.broken
                        ? Icons.warning_amber_rounded
                        : (playing ? Icons.stop_circle : Icons.play_circle)),
                    label:
                        Text(entry.broken ? l.unplayable : entry.durationLabel),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Seek bar while playing, empty space otherwise. Same slot -> no shift.
                  Expanded(
                    child: playing && player != null
                        ? _SeekBar(player: player!)
                        : const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    tooltip: l.delete,
                    onPressed: onDelete,
                  ),
                  PopupMenuButton<String>(
                    tooltip:
                        MaterialLocalizations.of(context).moreButtonTooltip,
                    onSelected: (v) async {
                      switch (v) {
                        case 'badge':
                          final picked =
                              await BadgePicker.show(context, entry.badgeId);
                          if (picked != null) onBadgeChanged?.call(picked);
                        case 'note':
                          await _editNote(context);
                        case 'image':
                          onAddImages?.call();
                        case 'open':
                          await openWith(context, entry, l);
                        case 'share':
                          await share(entry, l);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'image',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_outlined, size: 22),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(l.imageAdd,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'note',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasNote
                                  ? Icons.edit_note
                                  : Icons.note_add_outlined,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(hasNote ? l.noteEdit : l.noteAdd,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'badge',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              badge.isNone ? Icons.label_outline : badge.icon,
                              size: 20,
                              color: badge.isNone ? null : badge.color,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(l.badgeChange,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'open',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_new, size: 20),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(l.openWith,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.share_outlined, size: 20),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(l.share,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Images attached to an entry: a small horizontally scrollable strip.
/// On desktop it can be scrolled right by dragging with the mouse/trackpad
/// (added explicitly because mouse dragging is off by default) and a
/// scrollbar is shown.
class _ImageStrip extends StatefulWidget {
  final List<String> paths;
  final ValueChanged<String>? onRemove;
  const _ImageStrip({required this.paths, this.onRemove});

  @override
  State<_ImageStrip> createState() => _ImageStripState();
}

class _ImageStripState extends State<_ImageStrip> {
  final _ctrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Scrollbar(
          controller: _ctrl,
          child: ListView.separated(
            controller: _ctrl,
            scrollDirection: Axis.horizontal,
            itemCount: widget.paths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final p = widget.paths[i];
              return GestureDetector(
                onTap: () => ImageViewerDialog.show(
                  context,
                  p,
                  onRemove: widget.onRemove == null
                      ? null
                      : () => widget.onRemove!(p),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(p),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined, size: 20),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Seek bar: position + scrub while playing. Shown only on the active row.
class _SeekBar extends StatelessWidget {
  final AudioPlayer player;
  const _SeekBar({required this.player});

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      initialData: player.duration,
      builder: (context, durSnap) {
        final total = durSnap.data ?? player.duration ?? Duration.zero;
        final totalMs = total.inMilliseconds;
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          initialData: player.position,
          builder: (context, posSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final posMs = pos.inMilliseconds.clamp(0, totalMs);
            return Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 0,
                    max: totalMs > 0 ? totalMs.toDouble() : 1,
                    value: totalMs > 0 ? posMs.toDouble() : 0,
                    onChanged: totalMs > 0
                        ? (v) => player.seek(Duration(milliseconds: v.toInt()))
                        : null,
                  ),
                ),
                Text(
                  totalMs > 0 ? _fmt(pos) : '--:--',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Second row: session • duration • size • status.
/// Size is read from disk once and cached per path (entries do not change).
class _Subtitle extends StatelessWidget {
  final VoiceEntry entry;
  final AppLocalizations l;
  final String code;
  const _Subtitle({required this.entry, required this.l, required this.code});

  static final Map<String, int> _sizeCache = {};

  Future<int> _size(String path) async {
    final hit = _sizeCache[path];
    if (hit != null) return hit;
    try {
      final f = File(path);
      if (!await f.exists()) return -1;
      final len = await f.length();
      _sizeCache[path] = len;
      return len;
    } catch (_) {
      return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base =
        '${localizeSessionLabel(entry.sessionLabel, l)} • ${entry.durationLabel}';
    final tail = entry.uploaded ? l.backedUp : l.onDevice;
    return FutureBuilder<int>(
      future: _size(entry.path),
      builder: (context, snap) {
        final size = (snap.hasData && snap.data! >= 0)
            ? ' • ${formatBytes(snap.data!, code)}'
            : '';
        return Text('$base$size • $tail',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12));
      },
    );
  }
}
