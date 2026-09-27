import 'package:flutter/material.dart';

/// Wide screens (desktop): keep content in a centered max-width column
/// instead of stretching edge to edge. Phones (<640px) are unaffected.
class CenterShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const CenterShell({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
