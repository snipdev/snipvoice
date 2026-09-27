import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snipvoice/l10n/app_localizations.dart';
import 'package:snipvoice/models/entry_badge.dart';
import 'package:snipvoice/models/voice_entry.dart';
import 'package:snipvoice/screens/home_screen.dart';
import 'package:snipvoice/services/badge_service.dart';
import 'package:snipvoice/services/library_service.dart';
import 'package:snipvoice/services/note_preset_service.dart';
import 'package:snipvoice/services/session_service.dart';
import 'package:snipvoice/services/storage_service.dart';
import 'package:snipvoice/widgets/entry_tile.dart';
import 'package:snipvoice/widgets/note_editor_dialog.dart';
import 'package:snipvoice/widgets/undo_bar.dart';

void main() {
  test('StorageService.init works under test', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    expect(storage.baseDir.contains('snipvoice'), isTrue);
    storage.dispose();
  });

  test('Constructing the player must not hang under test', () {
    // The AudioRecorder constructor touches the platform channel (no mock
    // in tests), so only the pure Dart constructor is tested.
    AudioPlayer();
  });
  test('Date format: 20/09/26 Sunday', () async {
    await initializeDateFormatting('tr');
    expect(EntryTile.fullDate(DateTime(2026, 9, 20), 'tr'), '20/09/26 Pazar');
    expect(EntryTile.fullDate(DateTime(2026, 9, 20), 'en'), '20/09/26 Sunday');
  });

  test('Session: NY AM is open, weekend is closed', () {
    // Mon 21 Sep 2026 13:45 UTC = 09:45 ET (EDT) -> NY AM, open
    final nyAm = SessionService.current(DateTime.utc(2026, 9, 21, 13, 45));
    expect(nyAm.label, 'NY AM');
    expect(nyAm.status, MarketStatus.open);

    // Sun 20 Sep 2026 -> closed
    final off = SessionService.current(DateTime.utc(2026, 9, 20, 13, 45));
    expect(off.status, MarketStatus.closed);

    // 06:30 UTC = 02:30 ET -> Pre-London (canonical label)
    final pre = SessionService.current(DateTime.utc(2026, 9, 21, 6, 30));
    expect(pre.label, 'Pre-London');
    expect(pre.status, MarketStatus.pre);
  });

  test('File size formatting', () {
    expect(formatBytes(842, 'en'), '842 B');
    expect(formatBytes(96 * 1024, 'en'), '96.0 KB');
    expect(formatBytes(1258291, 'en'), '1.2 MB');
    expect(formatBytes(1258291, 'tr'), '1,2 MB');
  });

  test('Trash: trash -> restore -> purge', () async {
    final lib = LibraryService();
    final dir = await Directory.systemTemp.createTemp('snipvoice_test');
    final file = File('${dir.path}/a.m4a');
    await file.writeAsBytes(List.filled(100, 0));
    final e = VoiceEntry(
      id: 'trash1',
      path: file.path,
      createdAt: DateTime(2026, 9, 20, 10, 0),
      durationSec: 5,
      sessionLabel: 'NY AM',
    );
    lib.add(e);
    // the offline upload fails silently; short wait
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(lib.entries.length, 1);

    final token = await lib.trash(e);
    expect(token, isNotNull);
    expect(lib.entries, isEmpty);
    expect(await file.exists(), isFalse);

    await lib.restore(token!);
    expect(lib.entries.length, 1);
    expect(await file.exists(), isTrue);

    final token2 = await lib.trash(e);
    await lib.purge(token2!);
    expect(lib.entries, isEmpty);
    expect(await file.exists(), isFalse);

    lib.dispose();
    await dir.delete(recursive: true);
  });

  test('Badge: setBadge and copyWith keep the value', () async {
    SharedPreferences.setMockInitialValues({});
    final lib = LibraryService();
    await lib.initBadges();
    final e = VoiceEntry(
      id: 'badge1',
      path: '/tmp/b.m4a',
      createdAt: DateTime(2026, 9, 21, 10, 0),
      durationSec: 5,
      sessionLabel: 'NY AM',
    );
    lib.add(e);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(lib.entries.first.badgeId, 'none');

    await lib.setBadge('badge1', EntryBadge.favorite.name);
    expect(lib.entries.first.badgeId, 'favorite');

    lib.updateDuration('badge1', 9);
    expect(lib.entries.first.badgeId, 'favorite');
    expect(lib.entries.first.durationSec, 9);

    expect(EntryBadgeX.fromId('warning'), EntryBadge.warning);
    expect(EntryBadgeX.fromId('bogus'), EntryBadge.none);
    lib.dispose();
  });

  test('Custom badge: add, resolve, delete', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = BadgeService.instance;
    // singleton service: clean start
    for (final c in svc.custom.toList()) {
      await svc.remove(c.id);
    }
    expect(svc.custom, isEmpty);

    final cb =
        await svc.add(label: 'Kirilim', iconKey: 'bolt', colorKey: 'purple');
    expect(svc.custom.length, 1);

    final def = svc.resolve(cb.id);
    expect(def.custom, isTrue);
    expect(def.label, 'Kirilim');
    expect(def.isNone, isFalse);
    expect(def.icon, BadgeIcons.of('bolt'));
    expect(def.color, BadgeColors.of('purple'));

    // built-in resolution and unknown id -> none
    expect(svc.resolve('favorite').isNone, isFalse);
    expect(svc.resolve('custom:yok').isNone, isTrue);
    // the picker list is built-in + custom
    expect(svc.all.any((d) => d.id == cb.id), isTrue);

    await svc.remove(cb.id);
    expect(svc.custom, isEmpty);
    expect(svc.resolve(cb.id).isNone, isTrue);
  });

  test('Broken entry: markBroken flags it, discardBroken cleans it', () async {
    SharedPreferences.setMockInitialValues({});
    final lib = LibraryService();
    await lib.initBadges();
    final e = VoiceEntry(
      id: 'brk1',
      path: '/tmp/brk1.m4a',
      createdAt: DateTime(2026, 9, 21, 10, 0),
      durationSec: 0,
      sessionLabel: 'NY AM',
    );
    lib.addScanned([e]);
    expect(lib.entries.first.broken, isFalse);

    lib.markBroken('brk1');
    expect(lib.entries.first.broken, isTrue);
    // the flag survives even if the duration is resolved later
    lib.updateDuration('brk1', 5);
    expect(lib.entries.first.broken, isTrue);

    lib.discardBroken('brk1');
    expect(lib.entries, isEmpty);
    lib.dispose();
  });

  test('Images: add, persist, remove, delete via purge', () async {
    SharedPreferences.setMockInitialValues({});
    final lib = LibraryService();
    await lib.initBadges();
    final dir = await Directory.systemTemp.createTemp('snipvoice_img');
    final e = VoiceEntry(
      id: 'img1',
      path: '${dir.path}/a.m4a',
      createdAt: DateTime(2026, 9, 21, 10, 0),
      durationSec: 5,
      sessionLabel: 'NY AM',
    );
    await File(e.path).writeAsBytes(List.filled(10, 0));
    lib.add(e);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final p1 = '${dir.path}/1.png';
    final p2 = '${dir.path}/2.png';
    await File(p1).writeAsBytes(List.filled(10, 0));
    await File(p2).writeAsBytes(List.filled(10, 0));

    await lib.addImages('img1', [p1, p2]);
    expect(lib.entries.first.images.length, 2);
    expect((await SharedPreferences.getInstance()).getString('entry_images'),
        contains('1.png'));

    // new instance: images are applied to the entry added with the same id
    final lib2 = LibraryService();
    await lib2.initImages();
    lib2.addScanned([e]);
    expect(lib2.entries.first.images.length, 2);
    lib2.dispose();

    // removing a single image: from the list and from disk
    await lib.removeImage('img1', p1);
    expect(lib.entries.first.images, [p2]);
    expect(await File(p1).exists(), isFalse);

    // purge: the remaining image is deleted too and the record is cleaned
    final token = await lib.trash(lib.entries.first);
    await lib.purge(token!);
    expect(await File(p2).exists(), isFalse);
    expect(
        (await SharedPreferences.getInstance()).getString('entry_images') ?? '',
        isNot(contains('2.png')));

    lib.dispose();
    await dir.delete(recursive: true);
  });

  test('Note presets: seed + add/edit/delete', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'tr'});
    final svc = NotePresetService.instance;
    await svc.load();
    // the TR seed templates are loaded
    expect(svc.items.length, 5);
    expect(svc.items.any((p) => p.text.contains('FOMO')), isTrue);

    final added = await svc.add('  Manuel not  ');
    expect(added.text, 'Manuel not');
    expect(svc.items.length, 6);
    expect((await SharedPreferences.getInstance()).getString('note_presets'),
        contains('Manuel not'));

    await svc.update(added.id, 'Guncellendi');
    expect(svc.items.firstWhere((p) => p.id == added.id).text, 'Guncellendi');

    await svc.remove(added.id);
    expect(svc.items.length, 5);
  });

  testWidgets('Note dialog: tapping a preset replaces the text',
      (WidgetTester tester) async {
    await initializeDateFormatting('tr');
    final svc = NotePresetService.instance;
    if (svc.items.isEmpty) {
      SharedPreferences.setMockInitialValues({});
      await svc.load();
    }
    expect(svc.items, isNotEmpty);
    final first = svc.items.first.text;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: FilledButton(
              onPressed: () => NoteEditorDialog.show(ctx, 'eski not'),
              child: const Text('ac'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ac'));
    await tester.pumpAndSettle();

    // the preset note chip replaces the whole text
    await tester.tap(find.text(first));
    await tester.pumpAndSettle();
    final tf = tester.widget<TextField>(find.byType(TextField));
    expect(tf.controller!.text, first);
  });

  testWidgets('HomeScreen smoke: session badge + record button',
      (WidgetTester tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
    SharedPreferences.setMockInitialValues({});
    // Widget tests run in fake time; use runAsync for real file IO.
    final storage = (await tester.runAsync(() => StorageService.init()))!;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HomeScreen(library: LibraryService(), storage: storage),
      ),
    ));
    await tester.pump();

    // the record button + session badge must be on screen
    expect(find.text('START'), findsOneWidget);

    final ctx = tester.element(find.byType(HomeScreen));
    final l = AppLocalizations.of(ctx);
    final expected = SessionService.current(DateTime.now()).displayLabel(l);
    expect(find.text(expected), findsOneWidget);

    storage.dispose();
  });

  testWidgets('UndoBar: undo and auto-close on the timer',
      (WidgetTester tester) async {
    var undone = 0;
    var expired = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UndoBar(
          text: 'deleted',
          undoLabel: 'UNDO',
          seconds: 2,
          onUndo: () => undone++,
          onExpired: () => expired++,
        ),
      ),
    ));
    expect(find.textContaining('deleted'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    expect(undone, 1);

    // new bar: closes by itself when the time is up
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UndoBar(
          key: const ValueKey('b2'),
          text: 'deleted',
          undoLabel: 'UNDO',
          seconds: 2,
          onUndo: () => undone++,
          onExpired: () => expired++,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 2500));
    expect(expired, 1);
  });

  testWidgets('UndoBar: shows a notice when the timer runs out',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UndoBar(
          text: 'deleted',
          undoLabel: 'UNDO',
          expiredText: 'expired-notice',
          seconds: 1,
          onUndo: () {},
          onExpired: () {},
        ),
      ),
    ));
    expect(find.text('expired-notice'), findsNothing);

    // when the time is up the SnackBar appears
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(find.text('expired-notice'), findsOneWidget);
  });

  testWidgets('EntryTile shows play, share and delete',
      (WidgetTester tester) async {
    await initializeDateFormatting('tr');
    var played = false;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EntryTile(
          entry: VoiceEntry(
            id: 't1',
            path: '/tmp/x.m4a',
            createdAt: DateTime(2026, 9, 20, 14, 32),
            durationSec: 84,
            sessionLabel: 'NY AM',
          ),
          playing: false,
          onPlay: () => played = true,
          onDelete: () {},
        ),
      ),
    ));

    expect(find.textContaining('20/09/26 Pazar'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    // secondary actions live in the overflow menu
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle));
    expect(played, isTrue);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Başka uygulamayla aç'), findsOneWidget);
    expect(find.text('Paylaş'), findsOneWidget);
    // the note menu item is there too
    expect(find.text('Not ekle'), findsOneWidget);
  });

  test('Note: setNote persists, add/addScanned apply it, purge clears it',
      () async {
    SharedPreferences.setMockInitialValues({});
    final lib = LibraryService();
    await lib.initBadges(); // loads the notes too

    final e = VoiceEntry(
      id: 'note1',
      path: '/tmp/note1.m4a',
      createdAt: DateTime(2026, 9, 21, 10, 0),
      durationSec: 5,
      sessionLabel: 'NY AM',
    );
    lib.add(e);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(lib.entries.first.note, isNull);

    await lib.setNote('note1', 'FOMO ile girdim');
    expect(lib.entries.first.note, 'FOMO ile girdim');

    // persistence: written to prefs as JSON
    final p = await SharedPreferences.getInstance();
    expect(p.getString('entry_notes'), contains('FOMO'));

    // a new instance applies the note to the entry with the same id
    final lib2 = LibraryService();
    await lib2.initNotes();
    lib2.addScanned([e]);
    expect(lib2.entries.first.note, 'FOMO ile girdim');
    lib2.dispose();

    // special characters (JSON safety)
    await lib.setNote('note1', 'tirnak " ve satir\nsonu');
    expect(lib.entries.first.note, 'tirnak " ve satir\nsonu');

    // empty note -> cleared (hidden on the tile)
    await lib.setNote('note1', '   ');
    expect(lib.entries.first.note, isNull);

    // purge also cleans the note from the persistent store
    await lib.setNote('note1', 'kalici test');
    final token = await lib.trash(lib.entries.first);
    await lib.purge(token!);
    final p2 = await SharedPreferences.getInstance();
    expect(p2.getString('entry_notes') ?? '', isNot(contains('kalici test')));

    lib.dispose();
  });

  testWidgets('EntryTile shows the note and it is editable from the dialog',
      (WidgetTester tester) async {
    await initializeDateFormatting('tr');
    String? saved;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EntryTile(
          entry: VoiceEntry(
            id: 't2',
            path: '/tmp/y.m4a',
            createdAt: DateTime(2026, 9, 20, 14, 32),
            durationSec: 84,
            sessionLabel: 'NY AM',
            note: 'deneme notu',
          ),
          playing: false,
          onPlay: () {},
          onDelete: () {},
          onNoteChanged: (v) => saved = v,
        ),
      ),
    ));

    // the note content is visible on the tile
    expect(find.text('deneme notu'), findsOneWidget);

    // menu -> Edit note -> dialog
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notu düzenle'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    // change the text and save
    await tester.enterText(find.byType(TextField), 'yeni not');
    // onChanged triggers setState; without a rebuild the button stays disabled.
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(saved, 'yeni not');
  });

  testWidgets('Note dialog: shows the delete button when the note is empty',
      (WidgetTester tester) async {
    await initializeDateFormatting('tr');
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: FilledButton(
              onPressed: () => NoteEditorDialog.show(ctx, 'eski not'),
              child: const Text('ac'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('ac'));
    await tester.pumpAndSettle();
    // the delete option appears once the text is cleared
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Notu sil'), findsOneWidget);
  });
}
