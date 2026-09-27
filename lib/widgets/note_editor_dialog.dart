import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/note_preset_service.dart';

/// Note editing dialog: adds/updates a free text note on the entry.
/// Save stores it; empty plus an existing note shows Delete (removes it).
class NoteEditorDialog extends StatefulWidget {
  final String? initial;
  const NoteEditorDialog({super.key, this.initial});

  /// Result: the new note (null/empty = clear) or null = cancel.
  static Future<String?> show(BuildContext context, String? initial) {
    return showDialog<String>(
      context: context,
      builder: (_) => NoteEditorDialog(initial: initial),
    );
  }

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial ?? '');
  bool get _changed => _ctrl.text.trim() != (widget.initial ?? '').trim();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.noteTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preset notes: tapping one replaces the whole note.
            ListenableBuilder(
              listenable: NotePresetService.instance,
              builder: (context, _) {
                final presets = NotePresetService.instance.items;
                if (presets.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.settingsPresets,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in presets)
                          ActionChip(
                            label: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(p.text,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            onPressed: () {
                              _ctrl.text = p.text;
                              _ctrl.selection = TextSelection.collapsed(
                                  offset: _ctrl.text.length);
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 4,
              minLines: 2,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: l.noteHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
        if ((widget.initial ?? '').trim().isNotEmpty &&
            _ctrl.text.trim().isEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(l.noteDelete),
          ),
        FilledButton(
          // Disabled without changes: avoid writing the same value by accident.
          onPressed: _changed
              ? () => Navigator.of(context).pop(_ctrl.text.trim())
              : null,
          child: Text(l.noteSave),
        ),
      ],
    );
  }
}
