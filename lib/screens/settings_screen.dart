import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/badge_service.dart';
import '../services/note_preset_service.dart';
import '../services/storage_service.dart';
import '../widgets/badge_editor_dialog.dart';
import '../widgets/center_shell.dart';
import '../widgets/note_preset_editor_dialog.dart';
import '../widgets/entry_tile.dart' show formatBytes;

/// Settings: language, theme, recording folder.
class SettingsScreen extends StatefulWidget {
  final StorageService storage;
  final String localeCode;
  final ValueChanged<String> onLocaleChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.storage,
    required this.localeCode,
    required this.onLocaleChanged,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _openFolder() async {
    final l = AppLocalizations.of(context);
    final opened = await widget.storage.openFolder();
    if (!mounted) return;
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: widget.storage.baseDir));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.pathCopied)));
    }
  }

  Future<void> _changeFolder() async {
    final l = AppLocalizations.of(context);
    final ok = await widget.storage.pickCustomDir(l.pickFolderTitle);
    if (!mounted) return;
    if (ok) {
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.newFolderNotice)));
    }
  }

  Future<void> _resetFolder() async {
    await widget.storage.resetToDefault();
    if (mounted) setState(() {});
  }

  Future<void> _addBadge() async {
    final draft = await BadgeEditorDialog.show(context);
    if (draft == null) return;
    await BadgeService.instance.add(
        label: draft.label, iconKey: draft.iconKey, colorKey: draft.colorKey);
  }

  Future<void> _editBadge(CustomBadge c) async {
    final draft = await BadgeEditorDialog.show(
      context,
      initial:
          BadgeDraft(label: c.label, iconKey: c.iconKey, colorKey: c.colorKey),
    );
    if (draft == null) return;
    await BadgeService.instance.update(c.id,
        label: draft.label, iconKey: draft.iconKey, colorKey: draft.colorKey);
  }

  Future<void> _deleteBadge(CustomBadge c) async {
    await BadgeService.instance.remove(c.id);
  }

  Future<void> _addPreset() async {
    final text = await NotePresetEditorDialog.show(context);
    if (text == null) return;
    await NotePresetService.instance.add(text);
  }

  Future<void> _editPreset(NotePreset p) async {
    final text = await NotePresetEditorDialog.show(context, initial: p.text);
    if (text == null) return;
    await NotePresetService.instance.update(p.id, text);
  }

  Future<void> _deletePreset(NotePreset p) async {
    await NotePresetService.instance.remove(p.id);
  }

  Widget _presetRow(BuildContext context, AppLocalizations l, NotePreset p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.sticky_note_2_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(p.text, maxLines: 2, overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: l.presetEditTitle,
            onPressed: () => _editPreset(p),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: Colors.redAccent),
            tooltip: l.delete,
            onPressed: () => _deletePreset(p),
          ),
        ],
      ),
    );
  }

  Widget _badgeRow(BuildContext context, AppLocalizations l, CustomBadge c) {
    final def = BadgeService.instance.resolve(c.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(def.icon, color: def.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: l.badgeEditTitle,
            onPressed: () => _editBadge(c),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: Colors.redAccent),
            tooltip: l.delete,
            onPressed: () => _deleteBadge(c),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final code = Localizations.localeOf(context).languageCode;
    final dir = widget.storage.baseDir;

    return SafeArea(
      child: CenterShell(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- Language ---
            Text(l.settingsLanguage,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'en', label: Text(l.english)),
                ButtonSegment(value: 'tr', label: Text(l.turkish)),
              ],
              selected: {widget.localeCode},
              onSelectionChanged: (s) => widget.onLocaleChanged(s.first),
            ),
            const SizedBox(height: 24),
            // --- Theme ---
            Text(l.settingsTheme,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l.themeDark),
                    icon: const Icon(Icons.dark_mode)),
                ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l.themeLight),
                    icon: const Icon(Icons.light_mode)),
                ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l.themeSystem),
                    icon: const Icon(Icons.settings_suggest)),
              ],
              selected: {widget.themeMode},
              onSelectionChanged: (s) => widget.onThemeChanged(s.first),
            ),
            const SizedBox(height: 24),
            // --- Custom badges ---
            Text(l.settingsBadges,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l.customBadgeDesc,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: BadgeService.instance,
              builder: (context, _) {
                final customs = BadgeService.instance.custom;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (customs.isEmpty)
                          Text(l.badgeEmpty,
                              style: const TextStyle(fontSize: 12))
                        else
                          for (final c in customs) _badgeRow(context, l, c),
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FilledButton.tonalIcon(
                            onPressed: _addBadge,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l.badgeAddNew),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // --- Preset notes ---
            Text(l.settingsPresets,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l.presetDesc, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: NotePresetService.instance,
              builder: (context, _) {
                final presets = NotePresetService.instance.items;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (presets.isEmpty)
                          Text(l.presetEmpty,
                              style: const TextStyle(fontSize: 12))
                        else
                          for (final p in presets) _presetRow(context, l, p),
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FilledButton.tonalIcon(
                            onPressed: _addPreset,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l.presetAddNew),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // --- Folder ---
            Text(l.settingsFolder,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(dir,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Local usage: entry count + total size (no Supabase)
                    FutureBuilder<({int count, int bytes})>(
                      future: widget.storage.usage(),
                      builder: (context, snap) {
                        final u = snap.data;
                        final text = u == null
                            ? '…'
                            : l.storageDetail(
                                u.count, formatBytes(u.bytes, code));
                        return Row(
                          children: [
                            const Icon(Icons.audio_file_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l.storageTitle}: $text',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (widget.storage.isCustom)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(l.customFolder,
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.tertiary)),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _openFolder,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text(l.openFolder),
                        ),
                        OutlinedButton.icon(
                          onPressed: _changeFolder,
                          icon: const Icon(Icons.edit_location_alt_outlined,
                              size: 18),
                          label: Text(l.changeFolder),
                        ),
                        if (widget.storage.isCustom)
                          TextButton(
                            onPressed: _resetFolder,
                            child: Text(l.resetDefault),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
