import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/session_service.dart';

class _Row {
  final String label;
  final String time;
  final MarketStatus status;
  final SessionKind kind;
  const _Row(this.label, this.time, this.status, this.kind);
}

/// Market schedule (ET times) - opens when the home market badge is tapped.
class MarketScheduleSheet extends StatelessWidget {
  final SessionInfo current;
  const MarketScheduleSheet({super.key, required this.current});

  List<_Row> _rows(AppLocalizations l) => [
        _Row(l.sess_asia, '19:00 – 02:00', MarketStatus.open, SessionKind.asia),
        _Row(l.sess_preLondon, '02:00 – 03:00', MarketStatus.pre,
            SessionKind.preLondon),
        _Row(l.sess_londonAm, '03:00 – 05:00', MarketStatus.open,
            SessionKind.londonAm),
        _Row(l.sess_preNy, '05:00 – 07:00', MarketStatus.pre,
            SessionKind.preNewYork),
        _Row(
            l.sess_nyPre, '07:00 – 09:30', MarketStatus.pre, SessionKind.nyPre),
        _Row(l.sess_nyAm, '09:30 – 11:00', MarketStatus.open, SessionKind.nyAm),
        _Row(l.sess_nyLunch, '11:00 – 13:00', MarketStatus.pre,
            SessionKind.nyLunch),
        _Row(l.sess_nyPm, '13:00 – 16:00', MarketStatus.open, SessionKind.nyPm),
        _Row(l.sess_afterHours, '16:00 – 19:00', MarketStatus.closed,
            SessionKind.afterHours),
        _Row(
            l.sess_weekendLabel, '—', MarketStatus.closed, SessionKind.weekend),
      ];

  Color _statusColor(BuildContext context, MarketStatus s) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (s) {
      MarketStatus.open => dark ? Colors.green.shade400 : Colors.green.shade700,
      MarketStatus.pre =>
        dark ? Colors.orange.shade300 : Colors.orange.shade800,
      MarketStatus.closed => dark ? Colors.red.shade300 : Colors.red.shade700,
    };
  }

  String _statusLabel(AppLocalizations l, MarketStatus s) => switch (s) {
        MarketStatus.open => l.schOpen,
        MarketStatus.pre => l.schPre,
        MarketStatus.closed => l.schClosed,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final hl = current.status == MarketStatus.open
        ? cs.primaryContainer
        : cs.tertiaryContainer;
    final onHl = current.status == MarketStatus.open
        ? cs.onPrimaryContainer
        : cs.onTertiaryContainer;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.schedule, color: cs.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.schTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: l.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // Active session summary
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: hl,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: _statusColor(context, current.status),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${current.displayLabel(l)} • ${current.displayDetail(l)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontWeight: FontWeight.w600, color: onHl),
                      ),
                    ),
                    if (current.status != MarketStatus.closed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: onHl.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(l.schNow,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: onHl)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Table header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(l.schSession,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.outline)),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(l.schTime,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.outline)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(l.schState,
                          textAlign: TextAlign.end,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.outline)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in _rows(l))
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: r.kind == current.kind
                            ? BoxDecoration(
                                color: hl,
                                borderRadius: BorderRadius.circular(10))
                            : null,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: _statusColor(context, r.status),
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(r.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: r.kind == current.kind
                                                ? FontWeight.bold
                                                : FontWeight.w400,
                                            color: r.kind == current.kind
                                                ? onHl
                                                : null)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(r.time,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ])),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                _statusLabel(l, r.status),
                                textAlign: TextAlign.end,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: _statusColor(context, r.status),
                                        fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
