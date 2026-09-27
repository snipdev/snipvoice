# SnipVoice - UI/UX Review (22.09.2026)

Scope: `lib/screens/home_screen.dart`, `calendar_screen.dart`, `settings_screen.dart`,
`lib/widgets/entry_tile.dart`, `badge_picker.dart`, `recording_wave.dart`, `undo_bar.dart`, `center_shell.dart`.

## Strengths

- Consistent philosophy: one screen, one huge button, 3 tabs (Record / Calendar / Settings).
- The session badge (green/orange/red + TR/EN detail) gives the right trade context.
- Delete with a 4s undo `UndoBar`, the badge system and the offline notice are all good.
- `CenterShell(640)` preserves readability on desktop and is a no-op on phones.
- TR/EN localization is complete and the M3 theme seed (`0xFF16A34A`) is consistent.

## Findings

### P0 - do these first

1. **The Home list hides the record button**
   - With the `SingleChildScrollView + shrinkWrap + NeverScrollable` setup, at 20+ entries
     the record button scrolls off screen.
   - Suggestion: keep the button sticky/fixed (e.g. `CustomScrollView` + `SliverAppBar` or a
     fixed record bar at the bottom) and let the list scroll separately.

2. **No seek during playback**
   - Only play/stop plus a duration label; no position or scrubbing.
   - Suggestion: use the `just_audio` position stream for a thin progress bar + duration
     (`00:12 / 01:40`) and tap-to-seek.

3. **The EntryTile row risks overflowing on narrow phones**
   - 1 FilledButton + 4 IconButtons (~330px) is cramped on a 360px phone.
   - Suggestion: keep play + delete visible, move badge/open/share into a `PopupMenuButton`.

4. **Player listener leak**
   - `_play()` adds a `playerStateStream.listen` on every call and never cancels it.
   - Suggestion: one subscription (`initState`), cancel it in `dispose` + reset on `completed`.

### P1 - second round

5. **The `RecordingWave(color:)` prop is dead**
   - `recording_wave.dart:71-72` `_levelColor()` always yields the same green->red, the
     `color` passed in from outside is never used.
   - Suggestion: either drop the prop or derive the color from it with `Color.lerp` based
     on the level.

6. **Calendar localization + stale list**
   - `locale: code` is not passed to `TableCalendar` (`code` is only used for `fullDate`).
   - `dayEntries` is computed from the old `_all` before the StreamBuilder (1 frame delay).
   - Suggestion: add `locale`, move the `_all` update into `onData`/state.

7. **Subtitle IO jank**
   - `entry_tile.dart:187-188` does `File.exists + length` on every build.
   - Suggestion: resolve the size once during `StorageService.scan` and cache it.

8. **Badge contrast**
   - `question=lightBlueAccent` is washed out on the light theme; `important=red` clashes
     with the record red.
   - Suggestion: darker variants (`blue700`, `red700`) + a separate tone for dark/light.

### P2 - small improvements

- The offline Card takes too much space -> a thin banner/`MaterialBanner`.
- The record button animates the layout as it shrinks 220->190, `BAŞLA` is huge at 30sp
  -> fixed size + swap the inner content.
- Settings has no storage usage, Supabase status or bulk export.
- No search / badge / session filters.
- Empty states (`emptyList`, `emptyDay`) are text only -> small illustration + CTA.

## File references

- `lib/screens/home_screen.dart:182-360` - scrolling body + embedded list
- `lib/screens/home_screen.dart:149-169` - play listener
- `lib/screens/calendar_screen.dart:111-136` - calendar + stream
- `lib/widgets/entry_tile.dart:123-168` - control row
- `lib/widgets/entry_tile.dart:187-198` - subtitle IO
- `lib/widgets/recording_wave.dart:68-72` - color logic
