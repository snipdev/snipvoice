import 'dart:io';
import 'dart:ui' show AppExitResponse;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'services/audio_service.dart';
import 'services/badge_service.dart';
import 'services/library_service.dart';
import 'services/note_preset_service.dart';
import 'services/playback_service.dart';
import 'services/audio_session_setup.dart';
import 'services/storage_service.dart';
import 'widgets/recording_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('tr');
  final storage = await StorageService.init();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // no .env -> keep going offline
  }

  // dotenv.load throws when there is no .env, and then maybeGet would throw
  // NotInitializedError, hence the isInitialized guard.
  final url = dotenv.isInitialized ? dotenv.maybeGet('SUPABASE_URL') : null;
  final key = dotenv.isInitialized
      ? (dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ??
          dotenv.maybeGet('SUPABASE_ANON_KEY'))
      : null;
  if (url != null && key != null && url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: key);
  }

  // Custom badges: user-defined additions on top of the built-in ones.
  await BadgeService.instance.load();

  // Note presets: templates inserted with one tap in the note editor.
  await NotePresetService.instance.load();

  // Audio session: let incoming calls / other app audio drive recording and
  // playback (speech focused category, focus is ours while recording).
  await configureAudioSession();

  runApp(SnipVoiceApp(storage: storage));
}

class SnipVoiceApp extends StatefulWidget {
  final StorageService storage;
  const SnipVoiceApp({super.key, required this.storage});

  @override
  State<SnipVoiceApp> createState() => _SnipVoiceAppState();
}

class _SnipVoiceAppState extends State<SnipVoiceApp> {
  static const _kLocale = 'app_locale';
  static const _kTheme = 'app_theme';

  int _index = 0;
  final _library = LibraryService();
  final _audio = AudioService();
  late final AppLifecycleListener _lifecycle;
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    // Exit guard: if the window is closed while recording, stop and save the entry.
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        await _stopRecordingAndSave();
        return AppExitResponse.exit;
      },
      onStateChange: (state) {
        // On mobile the process can be killed in the background, so never leave a recording half-finished.
        if ((Platform.isAndroid || Platform.isIOS) &&
            (state == AppLifecycleState.paused ||
                state == AppLifecycleState.detached)) {
          _stopRecordingAndSave();
        }
      },
    );
    _loadPrefs();
  }

  /// Safely stops an in-progress recording and adds it to the library (silent if nothing is recording).
  Future<void> _stopRecordingAndSave() async {
    if (!_audio.isRecording) return;
    final entry = await _audio.stop();
    if (entry != null) _library.add(entry);
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _locale = Locale(p.getString(_kLocale) ?? 'en');
      _themeMode = switch (p.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
    });
  }

  Future<void> setLocale(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, code);
    if (mounted) setState(() => _locale = Locale(code));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kTheme,
        mode == ThemeMode.light
            ? 'light'
            : mode == ThemeMode.system
                ? 'system'
                : 'dark');
    if (mounted) setState(() => _themeMode = mode);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _audio.dispose();
    PlaybackService().dispose();
    _library.dispose();
    widget.storage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnipVoice',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF16A34A),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF16A34A),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: Builder(builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return StreamBuilder<bool>(
          stream: _audio.recordingStream,
          initialData: _audio.isRecording,
          builder: (context, snap) {
            final recording = snap.data ?? false;
            return PopScope(
              // Back button / app exit while recording: finish the recording first.
              canPop: !recording,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                await _stopRecordingAndSave();
                if (ctx.mounted) Navigator.of(ctx).maybePop();
              },
              child: Scaffold(
                appBar: AppBar(
                  leading: const Padding(
                    padding: EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      child: Image(image: AssetImage('assets/logo.png')),
                    ),
                  ),
                  title: Text(l.appTitle),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: _index,
                        children: [
                          HomeScreen(
                              library: _library, storage: widget.storage),
                          CalendarScreen(
                              library: _library, storage: widget.storage),
                          SettingsScreen(
                            storage: widget.storage,
                            localeCode: _locale.languageCode,
                            onLocaleChanged: setLocale,
                            themeMode: _themeMode,
                            onThemeChanged: setThemeMode,
                          ),
                        ],
                      ),
                    ),
                    // Persistent bar shown on the other tabs while recording.
                    if (recording && _index != 0)
                      RecordingBanner(
                        audio: _audio,
                        onStop: _stopRecordingAndSave,
                      ),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    NavigationDestination(
                        icon: const Icon(Icons.mic), label: l.tabRecord),
                    NavigationDestination(
                        icon: const Icon(Icons.calendar_month),
                        label: l.tabCalendar),
                    NavigationDestination(
                        icon: const Icon(Icons.settings), label: l.tabSettings),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
