import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/badge_def.dart';
import '../models/entry_badge.dart';
import '../services/badge_service.dart';

/// Badge picker: built-in badges + the user's custom badges.
/// Returns the selection as a badge id (String).
class BadgePicker extends StatelessWidget {
  final String currentId;
  const BadgePicker({super.key, required this.currentId});

  /// Badge label: user text for custom badges, l10n for built-in ones.
  static String labelFor(BadgeDef d, AppLocalizations l) =>
      d.custom ? d.label : label(EntryBadgeX.fromId(d.id), l);

  static String label(EntryBadge b, AppLocalizations l) => switch (b) {
        EntryBadge.none => l.badgeNone,
        EntryBadge.important => l.badgeImportant,
        EntryBadge.question => l.badgeQuestion,
        EntryBadge.favorite => l.badgeFavorite,
        EntryBadge.warning => l.badgeWarning,
      };

  static Future<String?> show(BuildContext context, String currentId) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => BadgePicker(currentId: currentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.badgeTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            // Refresh the picker when the badge list changes (new custom badge).
            ListenableBuilder(
              listenable: BadgeService.instance,
              builder: (context, _) {
                final defs = BadgeService.instance.all;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in defs)
                      ChoiceChip(
                        selected: d.id == currentId,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(d.icon, size: 18, color: d.color),
                            const SizedBox(width: 6),
                            Text(labelFor(d, l)),
                          ],
                        ),
                        onSelected: (_) => Navigator.of(context).pop(d.id),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
