import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Dialog for editing a preset note text. Cannot be empty.
class NotePresetEditorDialog extends StatefulWidget {
  final String? initial;
  const NotePresetEditorDialog({super.key, this.initial});

  static Future<String?> show(BuildContext context, {String? initial}) =>
      showDialog<String>(
        context: context,
        builder: (_) => NotePresetEditorDialog(initial: initial),
      );

  @override
  State<NotePresetEditorDialog> createState() => _NotePresetEditorDialogState();
}

class _NotePresetEditorDialogState extends State<NotePresetEditorDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final valid = _ctrl.text.trim().isNotEmpty;
    return AlertDialog(
      title:
          Text(widget.initial == null ? l.presetNewTitle : l.presetEditTitle),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        maxLength: 200,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: l.presetHint,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed:
              valid ? () => Navigator.of(context).pop(_ctrl.text.trim()) : null,
          child: Text(l.save),
        ),
      ],
    );
  }
}
