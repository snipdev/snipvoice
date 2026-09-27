import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../l10n/app_localizations.dart';
import '../models/voice_entry.dart';
import '../services/badge_service.dart';
import '../services/entry_media.dart';
import '../services/library_service.dart';
import '../services/storage_service.dart';
import '../services/playback_service.dart';
import '../services/session_service.dart';
import '../widgets/badge_picker.dart';
import '../widgets/center_shell.dart';
import '../widgets/entry_tile.dart';
import '../widgets/undo_bar.dart';

/// Calendar: a dot on days that have entries; tapping a day lists them below.
class CalendarScreen extends StatefulWidget {
  final LibraryService library;
  final StorageService storage;

  /// Optional: injectable in tests; nil means the app-wide singleton.
  final PlaybackService? playback;
  const CalendarScreen(
      {super.key, required this.library, required this.storage, this.playback});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static final _shared = PlaybackService();
  PlaybackService get _pb => widget.playback ?? _shared;
  StreamSubscription<String?>? _playingSub;
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  String? _playingId;
  List<VoiceEntry> _all = [];
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _badgeFilter;
  bool _calCollapsed = true;
  bool _userToggled = false;
  bool _searchOpen = false;
  bool _lastCompact = false;

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  List<VoiceEntry> _eventsFor(DateTime day) {
    final k = _norm(day);
    return _all.where((e) => _norm(e.createdAt) == k).toList();
  }

  @override
  void initState() {
    super.initState();
    // Shared player: playback started in Home stays visible in this tab too.
    _playingId = _pb.playingId;
    _playingSub = _pb.playingStream.listen((id) {
      if (mounted) setState(() => _playingId = id);
    });
    widget.library.initBadges();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _playingSub?.cancel();
    super.dispose();
  }

  bool get _filtering => _query.isNotEmpty || _badgeFilter != null;

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _badgeFilter = null;
    });
  }

  void _stepDay(int d) {
    setState(() {
      _selected = _norm(_selected.add(Duration(days: d)));
      _focused = _selected;
    });
  }

  void _toggleCal() {
    final eff = _userToggled ? _calCollapsed : _lastCompact;
    setState(() {
      _userToggled = true;
      _calCollapsed = !eff;
    });
  } // Badge chips: scroll horizontally inside (mouse/trackpad supported).

  // Built-in badges + the user's own badges (refreshed when one is added).
  Widget _buildChips(AppLocalizations l) {
    return ListenableBuilder(
      listenable: BadgeService.instance,
      builder: (context, _) {
        final defs = BadgeService.instance.all.where((d) => !d.isNone).toList();
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l.filterAll),
                  selected: _badgeFilter == null,
                  onSelected: (_) => setState(() => _badgeFilter = null),
                ),
                for (final d in defs) ...[
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(d.icon, size: 16, color: d.color),
                        const SizedBox(width: 4),
                        Text(BadgePicker.labelFor(d, l)),
                      ],
                    ),
                    selected: _badgeFilter == d.id,
                    onSelected: (_) => setState(() =>
                        _badgeFilter = _badgeFilter == d.id ? null : d.id),
                  ),
                ],
                if (_filtering) ...[
                  const SizedBox(width: 6),
                  TextButton(
                      onPressed: _clearFilters, child: Text(l.clearFilters)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _matches(VoiceEntry e, AppLocalizations l, String code) {
    if (_badgeFilter != null && e.badgeId != _badgeFilter) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final hay = '${e.sessionLabel} '
            '${localizeSessionLabel(e.sessionLabel, l)} '
            '${EntryTile.fullDate(e.createdAt, code)} '
            '${e.durationLabel} '
            '${e.note ?? ''}'
        .toLowerCase();
    return hay.contains(q);
  }

  /// Attach images to an entry: pick files -> copy to the media folder -> save.
  Future<void> _addImages(VoiceEntry e) async {
    final title = AppLocalizations.of(context).pickImagesTitle;
    await attachImagesToEntry(
      library: widget.library,
      storage: widget.storage,
      entry: e,
      dialogTitle: title,
    );
  }

  Future<void> _play(VoiceEntry e) async {
    try {
      await _pb.toggle(e.id, e.path);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).playbackFailed(err))));
    }
  }

  /// Delete + timed undo bar. A new delete confirms the previous one.
  TrashToken? _pending;

  Future<void> _deleteEntry(VoiceEntry e) async {
    if (_playingId == e.id) await _pb.stop();
    if (_pending != null) {
      final old = _pending!;
      _pending = null;
      await widget.library.purge(old);
    }
    final token = await widget.library.trash(e);
    if (!mounted || token == null) return;
    setState(() => _pending = token);
  }

  void _undoDelete() {
    final token = _pending;
    if (token == null) return;
    setState(() => _pending = null);
    widget.library.restore(token);
  }

  void _expireDelete() {
    final token = _pending;
    if (token == null) return;
    setState(() => _pending = null);
    widget.library.purge(token);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final code = Localizations.localeOf(context).languageCode;

    return SafeArea(
      child: CenterShell(
        child: LayoutBuilder(
          builder: (context, cons) {
            final compact = cons.maxHeight < 700;
            _lastCompact = compact;
            final calCollapsed = _userToggled ? _calCollapsed : compact;
            final cs = Theme.of(context).colorScheme;
            return Padding(
              padding: EdgeInsets.all(compact ? 12 : 16),
              // One StreamBuilder: calendar + day list are fed by the same
              // snapshot, so the list is never a frame behind.
              child: StreamBuilder<List<VoiceEntry>>(
                stream: widget.library.stream,
                builder: (context, snap) {
                  _all = snap.data ?? widget.library.entries;
                  final rawDay = _eventsFor(_selected);
                  final dayEntries =
                      rawDay.where((e) => _matches(e, l, code)).toList();
                  // The title count is the row count of the list below. While
                  // filter/search is on the cell badges show the total, so it is
                  // written as "filtered/total" to keep both consistent.
                  final countLabel =
                      _filtering && dayEntries.length != rawDay.length
                          ? '${dayEntries.length}/${rawDay.length}'
                          : '${dayEntries.length}';
                  final showFilters = _all.isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Day header: arrows change the day, the middle date toggles open/closed.
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _stepDay(-1),
                            icon: const Icon(Icons.chevron_left),
                            tooltip: EntryTile.fullDate(
                                _norm(_selected.add(const Duration(days: -1))),
                                code),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _toggleCal,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  '${EntryTile.fullDate(_selected, code)} • $countLabel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _stepDay(1),
                            icon: const Icon(Icons.chevron_right),
                            tooltip: EntryTile.fullDate(
                                _norm(_selected.add(const Duration(days: 1))),
                                code),
                          ),
                          Tooltip(
                            message: calCollapsed ? l.calShow : l.calHide,
                            child: IconButton(
                              onPressed: _toggleCal,
                              icon: Icon(calCollapsed
                                  ? Icons.calendar_month_outlined
                                  : Icons.expand_less),
                            ),
                          ),
                        ],
                      ),
                      // Month grid: stays collapsed to leave room for the entries.
                      if (!calCollapsed)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: TableCalendar<VoiceEntry>(
                            firstDay: DateTime.utc(2024, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focused,
                            locale: code,
                            eventLoader: _eventsFor,
                            daysOfWeekHeight: compact ? 26 : 30,
                            rowHeight: compact ? 32 : 38,
                            selectedDayPredicate: (d) =>
                                isSameDay(_selected, d),
                            onDaySelected: (sel, foc) => setState(() {
                              _selected = sel;
                              _focused = foc;
                            }),
                            onPageChanged: (foc) => _focused = foc,
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, day, events) {
                                if (events.isEmpty) return null;
                                final cs = Theme.of(context).colorScheme;
                                return PositionedDirectional(
                                  top: 1,
                                  end: 2,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                        minWidth: 18, minHeight: 18),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: cs.tertiary,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      '${events.length}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onTertiary),
                                    ),
                                  ),
                                );
                              },
                            ),
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: cs.primary, width: 1.5)),
                              todayTextStyle: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold),
                              selectedDecoration: BoxDecoration(
                                  color: cs.primary, shape: BoxShape.circle),
                              selectedTextStyle: TextStyle(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold),
                            ),
                            headerStyle:
                                const HeaderStyle(formatButtonVisible: false),
                          ),
                        ),
                      if (showFilters) ...[
                        SizedBox(height: compact ? 6 : 8),
                        // Search: while closed it is a single row (search icon + chips).
                        Row(
                          children: [
                            IconButton(
                              // Closing does not clear the query; the filter stays,
                              // remove it with "Clear" or by reopening and deleting.
                              onPressed: () =>
                                  setState(() => _searchOpen = !_searchOpen),
                              icon: Icon(
                                  _searchOpen
                                      ? Icons.search_off_outlined
                                      : Icons.search,
                                  size: 20),
                              tooltip: _searchOpen ? l.close : l.searchHint,
                            ),
                            Expanded(
                              child: _searchOpen
                                  ? TextField(
                                      controller: _searchCtrl,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        hintText: l.searchHint,
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                        isDense: true,
                                      ),
                                      onChanged: (v) => setState(() =>
                                          _query = v.trim().toLowerCase()),
                                    )
                                  : _buildChips(l),
                            ),
                          ],
                        ),
                        if (_searchOpen) ...[
                          const SizedBox(height: 4),
                          _buildChips(l),
                          SizedBox(height: compact ? 4 : 8),
                        ],
                      ],
                      if (_pending != null) ...[
                        const SizedBox(height: 4),
                        UndoBar(
                          key: ValueKey(_pending!),
                          text: l.deleted,
                          undoLabel: l.undo,
                          expiredText: l.undoExpired,
                          onUndo: _undoDelete,
                          onExpired: _expireDelete,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Expanded(
                        child: dayEntries.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          _filtering
                                              ? Icons.search_off_outlined
                                              : Icons.event_note_outlined,
                                          size: 48,
                                          color:
                                              Theme.of(context).disabledColor),
                                      const SizedBox(height: 12),
                                      Text(
                                        _filtering && rawDay.isNotEmpty
                                            ? l.noResults
                                            : l.emptyDay,
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_filtering && rawDay.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        FilledButton.tonal(
                                          onPressed: _clearFilters,
                                          child: Text(l.clearFilters),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: dayEntries.length,
                                itemBuilder: (_, i) {
                                  final e = dayEntries[i];
                                  return EntryTile(
                                    entry: e,
                                    playing: _playingId == e.id,
                                    player: _pb.player,
                                    onPlay: () => _play(e),
                                    onDelete: () => _deleteEntry(e),
                                    onBadgeChanged: (b) =>
                                        widget.library.setBadge(e.id, b),
                                    onNoteChanged: (n) =>
                                        widget.library.setNote(e.id, n),
                                    onAddImages: () => _addImages(e),
                                    onRemoveImage: (p) =>
                                        widget.library.removeImage(e.id, p),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
