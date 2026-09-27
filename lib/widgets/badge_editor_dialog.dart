import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/badge_service.dart';

/// Edit result: name + the selected icon/color keys.
class BadgeDraft {
  final String label;
  final String iconKey;
  final String colorKey;
  const BadgeDraft({
    required this.label,
    required this.iconKey,
    required this.colorKey,
  });
}

/// Custom badge editor: name + ready icon palette + ready color palette.
class BadgeEditorDialog extends StatefulWidget {
  final BadgeDraft? initial;
  const BadgeEditorDialog({super.key, this.initial});

  static Future<BadgeDraft?> show(BuildContext context,
          {BadgeDraft? initial}) =>
      showDialog<BadgeDraft>(
        context: context,
        builder: (_) => BadgeEditorDialog(initial: initial),
      );

  @override
  State<BadgeEditorDialog> createState() => _BadgeEditorDialogState();
}

class _BadgeEditorDialogState extends State<BadgeEditorDialog> {
  late final TextEditingController _ctrl;
  late String _iconKey;
  late String _colorKey;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _ctrl = TextEditingController(text: i?.label ?? '');
    _iconKey = i?.iconKey ?? BadgeIcons.options.keys.first;
    _colorKey = i?.colorKey ?? BadgeColors.options.keys.first;
    // Refresh the "Save" button's enabled state when the name changes.
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = BadgeColors.of(_colorKey);
    final valid = _ctrl.text.trim().isNotEmpty;
    return AlertDialog(
      icon: Icon(BadgeIcons.of(_iconKey), color: color),
      title: Text(widget.initial == null ? l.badgeNewTitle : l.badgeEditTitle),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ctrl,
                autofocus: true,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: l.badgeNameLabel,
                  hintText: l.badgeNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              Text(l.badgeIconLabel,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in BadgeIcons.options.entries)
                    _IconChoice(
                      icon: e.value,
                      selected: e.key == _iconKey,
                      color: color,
                      onTap: () => setState(() => _iconKey = e.key),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l.badgeColorLabel,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in BadgeColors.options.entries)
                    _ColorChoice(
                      color: e.value,
                      selected: e.key == _colorKey,
                      onTap: () => setState(() => _colorKey = e.key),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop(
                    context,
                    BadgeDraft(
                        label: _ctrl.text.trim(),
                        iconKey: _iconKey,
                        colorKey: _colorKey),
                  )
              : null,
          child: Text(l.save),
        ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? color.withValues(alpha: 0.18)
              : cs.surfaceContainerHighest,
          border: selected ? Border.all(color: color, width: 2) : null,
        ),
        child:
            Icon(icon, size: 20, color: selected ? color : cs.onSurfaceVariant),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: selected ? Border.all(color: cs.onSurface, width: 3) : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}
