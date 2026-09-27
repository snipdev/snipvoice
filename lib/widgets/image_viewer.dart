import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Shows the image fullscreen (zoom/pan); offers removal when requested.
class ImageViewerDialog extends StatelessWidget {
  final String path;
  final VoidCallback? onRemove;
  const ImageViewerDialog({super.key, required this.path, this.onRemove});

  /// Returns true when the image was removed.
  static Future<bool?> show(BuildContext context, String path,
          {VoidCallback? onRemove}) =>
      showDialog<bool>(
        context: context,
        builder: (_) => ImageViewerDialog(path: path, onRemove: onRemove),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: size.height * 0.7,
            ),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRemove != null)
                  TextButton.icon(
                    onPressed: () {
                      onRemove!();
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    label: Text(l.imageRemove),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.close),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
