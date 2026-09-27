// Session calculation: based on New York time (ET).
// Badge: open = green, pre = orange, closed = red.
// label: canonical English (fixed for the file name and the record model).
// Use the SessionDisplay extension for on-screen display.

import '../l10n/app_localizations.dart';

enum MarketStatus { open, pre, closed }

enum SessionKind {
  asia,
  preLondon,
  londonAm,
  preNewYork,
  nyPre,
  nyAm,
  nyLunch,
  nyPm,
  afterHours,
  weekend,
}

class SessionInfo {
  final SessionKind kind;
  final MarketStatus status;
  final String label; // canonical: "NY AM", "Pre-London" ...
  final String detail; // canonical English description
  const SessionInfo(this.kind, this.status, this.label, this.detail);
}

/// Localized session texts shown on screen.
extension SessionDisplay on SessionInfo {
  String displayLabel(AppLocalizations l) => switch (kind) {
        SessionKind.asia => l.sess_asia,
        SessionKind.preLondon => l.sess_preLondon,
        SessionKind.londonAm => l.sess_londonAm,
        SessionKind.preNewYork => l.sess_preNy,
        SessionKind.nyPre => l.sess_nyPre,
        SessionKind.nyAm => l.sess_nyAm,
        SessionKind.nyLunch => l.sess_nyLunch,
        SessionKind.nyPm => l.sess_nyPm,
        SessionKind.afterHours => l.sess_closed,
        SessionKind.weekend => l.sess_closed,
      };

  String displayDetail(AppLocalizations l) => switch (kind) {
        SessionKind.asia => l.sessd_asia,
        SessionKind.preLondon => l.sessd_preLondon,
        SessionKind.londonAm => l.sessd_londonAm,
        SessionKind.preNewYork => l.sessd_preNy,
        SessionKind.nyPre => l.sessd_nyPre,
        SessionKind.nyAm => l.sessd_nyAm,
        SessionKind.nyLunch => l.sessd_nyLunch,
        SessionKind.nyPm => l.sessd_nyPm,
        SessionKind.afterHours => l.sessd_afterHours,
        SessionKind.weekend => l.sessd_weekend,
      };
}

/// Converts a stored (canonical) session label to the active language.
String localizeSessionLabel(String canonical, AppLocalizations l) =>
    switch (canonical) {
      'Asia' => l.sess_asia,
      'Pre-London' => l.sess_preLondon,
      'London AM' => l.sess_londonAm,
      'Pre-NY' => l.sess_preNy,
      'NY Premarket' => l.sess_nyPre,
      'NY AM' => l.sess_nyAm,
      'NY Lunch' => l.sess_nyLunch,
      'NY PM' => l.sess_nyPm,
      'Closed' => l.sess_closed,
      // backwards compatibility for old files (v1 labels)
      'NY-NOON' => l.sess_nyLunch,
      'NY-PRE' => l.sess_nyPre,
      'PRE-NY' => l.sess_preNy,
      'PRE-LON' => l.sess_preLondon,
      'LONDON' => l.sess_londonAm,
      'ASIA' => l.sess_asia,
      'OFF' => l.sess_closed,
      _ => canonical,
    };

class SessionService {
  /// now: device clock (local). Converted to NY time.
  static SessionInfo current(DateTime now) {
    // ET offset approximation: April-October is EDT (UTC-4), otherwise EST (UTC-5).
    final ny = now.toUtc().add(_etOffset(now));
    final mins = ny.hour * 60 + ny.minute;
    if (ny.weekday >= 6) {
      return const SessionInfo(SessionKind.weekend, MarketStatus.closed,
          'Closed', 'weekend — market closed');
    }
    if (mins < 120) {
      return const SessionInfo(SessionKind.asia, MarketStatus.open, 'Asia',
          'market open • overnight flow');
    }
    if (mins < 180) {
      return const SessionInfo(SessionKind.preLondon, MarketStatus.pre,
          'Pre-London', 'getting ready for the London open');
    }
    if (mins < 300) {
      return const SessionInfo(SessionKind.londonAm, MarketStatus.open,
          'London AM', 'market open • open killzone');
    }
    if (mins < 420) {
      return const SessionInfo(SessionKind.preNewYork, MarketStatus.pre,
          'Pre-NY', 'London lunch • waiting on NY');
    }
    if (mins < 570) {
      return const SessionInfo(SessionKind.nyPre, MarketStatus.pre,
          'NY Premarket', 'data • pre-open prep');
    }
    if (mins < 660) {
      return const SessionInfo(SessionKind.nyAm, MarketStatus.open, 'NY AM',
          'market open • 09:30 open');
    }
    if (mins < 780) {
      return const SessionInfo(SessionKind.nyLunch, MarketStatus.pre,
          'NY Lunch', 'slow flow • usually wait');
    }
    if (mins < 960) {
      return const SessionInfo(SessionKind.nyPm, MarketStatus.open, 'NY PM',
          'market open • power hour 15:00–16:00');
    }
    if (mins < 1140) {
      return const SessionInfo(SessionKind.afterHours, MarketStatus.closed,
          'Closed', 'after hours — market closed');
    }
    return const SessionInfo(SessionKind.asia, MarketStatus.open, 'Asia',
        'market open • Sydney/Tokyo');
  }

  static Duration _etOffset(DateTime now) {
    // Rough DST: April-October is EDT (-4), otherwise -5
    final m = now.month;
    final dst = m >= 4 && m <= 10;
    return Duration(hours: dst ? -4 : -5);
  }

  /// Label for the file name: 2026-09-20_0932_NY-AM.m4a
  static String fileTag(DateTime now) {
    final tag = switch (current(now).kind) {
      SessionKind.asia => 'ASIA',
      SessionKind.preLondon => 'PRE-LON',
      SessionKind.londonAm => 'LONDON',
      SessionKind.preNewYork => 'PRE-NY',
      SessionKind.nyPre => 'NY-PRE',
      SessionKind.nyAm => 'NY-AM',
      SessionKind.nyLunch => 'NY-NOON',
      SessionKind.nyPm => 'NY-PM',
      SessionKind.afterHours => 'OFF',
      SessionKind.weekend => 'OFF',
    };
    final d = now;
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)}_${p(d.hour)}${p(d.minute)}_$tag';
  }
}
