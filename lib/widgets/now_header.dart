import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/session_service.dart';

/// Top block: clock + date + market badge.
///
/// It owns its per-second timer, so the rest of the Home screen (the
/// recording list included) is not rebuilt every second.
class NowHeader extends StatefulWidget {
  /// Whether Supabase is configured (to show the offline reopen icon).
  final bool syncEnabled;

  /// Whether the offline banner is hidden (then the reopen icon is shown).
  final bool offlineHidden;

  /// Bring back the hidden offline banner.
  final VoidCallback onShowOffline;

  /// Opens the schedule modal when the market badge is tapped.
  final ValueChanged<SessionInfo> onOpenSchedule;

  const NowHeader({
    super.key,
    required this.syncEnabled,
    required this.offlineHidden,
    required this.onShowOffline,
    required this.onOpenSchedule,
  });

  @override
  State<NowHeader> createState() => _NowHeaderState();
}

class _NowHeaderState extends State<NowHeader> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final code = Localizations.localeOf(context).languageCode;
    final cs = Theme.of(context).colorScheme;
    final session = SessionService.current(_now);
    final time = DateFormat('HH:mm:ss').format(_now);
    final date = DateFormat('d MMM EEEE', code).format(_now);

    final container = switch (session.status) {
      MarketStatus.open => cs.primaryContainer,
      MarketStatus.pre => cs.tertiaryContainer,
      MarketStatus.closed => cs.errorContainer,
    };
    final onContainer = switch (session.status) {
      MarketStatus.open => cs.onPrimaryContainer,
      MarketStatus.pre => cs.onTertiaryContainer,
      MarketStatus.closed => cs.onErrorContainer,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(date, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Banner hidden: a fixed top icon brings it back
        if (!widget.syncEnabled && widget.offlineHidden)
          IconButton(
            icon: const Icon(Icons.cloud_off_outlined, size: 20),
            tooltip: l.offlineNotice,
            onPressed: widget.onShowOffline,
          ),
        const SizedBox(width: 12),
        // Market badge button: tap friendly color, opens the modal.
        Flexible(
          child: Material(
            color: container,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => widget.onOpenSchedule(session),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(session.displayLabel(l),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: onContainer)),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.expand_more, size: 16, color: onContainer),
                      ],
                    ),
                    Text(session.displayDetail(l),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: onContainer)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
