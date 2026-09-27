// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SnipVoice';

  @override
  String get tabRecord => 'Record';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabSettings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Türkçe';

  @override
  String get start => 'START';

  @override
  String get stop => 'STOP';

  @override
  String get recordingHint => 'recording… tap to stop';

  @override
  String get recordingActive => 'Recording';

  @override
  String get micPermission => 'Microphone permission required';

  @override
  String get micIntroTitle => 'Enable the microphone';

  @override
  String get micIntroBody =>
      'SnipVoice records your voice notes. The microphone is only used while you record.';

  @override
  String get micDeniedTitle => 'Microphone access is off';

  @override
  String get micDeniedBody =>
      'Permission was denied permanently. Turn on the microphone in system settings to keep recording.';

  @override
  String get micContinue => 'Continue';

  @override
  String get openSettings => 'Open settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get offlineNotice =>
      'Offline mode: recordings stay on device. They auto-upload once Supabase .env is added.';

  @override
  String recordingsTitle(int count) {
    return 'Recordings ($count)';
  }

  @override
  String get emptyList =>
      'No recordings yet.\nBefore a trade, hit the button and talk through what\'s on your mind.';

  @override
  String playbackFailed(Object err) {
    return 'Could not play: $err';
  }

  @override
  String get customFolder => 'custom folder';

  @override
  String get openFolder => 'Open folder';

  @override
  String get changeFolder => 'Change folder';

  @override
  String get newFolderNotice => 'New recordings will go to this folder';

  @override
  String get pathCopied => 'Folder path copied to clipboard';

  @override
  String get folderTitle => 'Recording folder';

  @override
  String get resetDefault => 'Reset to default';

  @override
  String get copy => 'Copy';

  @override
  String get close => 'Close';

  @override
  String get pickFolderTitle => 'Choose recording folder';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsFolder => 'Recording folder';

  @override
  String get backedUp => 'backed up';

  @override
  String get onDevice => 'on device';

  @override
  String get delete => 'Delete';

  @override
  String get badgeTitle => 'Badge';

  @override
  String get badgeNone => 'None';

  @override
  String get badgeImportant => 'Important';

  @override
  String get badgeQuestion => 'Question';

  @override
  String get badgeFavorite => 'Favorite';

  @override
  String get badgeWarning => 'Danger';

  @override
  String get badgeChange => 'Change badge';

  @override
  String get settingsBadges => 'Custom badges';

  @override
  String get customBadgeDesc =>
      'Create your own badges with a name, icon and color. They show up in the badge picker.';

  @override
  String get badgeAddNew => 'Add badge';

  @override
  String get badgeNewTitle => 'New badge';

  @override
  String get badgeEditTitle => 'Edit badge';

  @override
  String get badgeNameLabel => 'Name';

  @override
  String get badgeNameHint => 'e.g. Breakout';

  @override
  String get badgeIconLabel => 'Icon';

  @override
  String get badgeColorLabel => 'Color';

  @override
  String get badgeEmpty => 'No custom badges yet.';

  @override
  String get save => 'Save';

  @override
  String get settingsPresets => 'Preset notes';

  @override
  String get presetDesc =>
      'Quick texts you can drop into a recording note. Tap one in the note editor to use it.';

  @override
  String get presetAddNew => 'Add note';

  @override
  String get presetNewTitle => 'New preset';

  @override
  String get presetEditTitle => 'Edit preset';

  @override
  String get presetHint => 'e.g. Entered too late';

  @override
  String get presetEmpty => 'No preset notes yet.';

  @override
  String get noteTitle => 'Note';

  @override
  String get noteAdd => 'Add note';

  @override
  String get noteEdit => 'Edit note';

  @override
  String get noteHint => 'What were you thinking?';

  @override
  String get noteSave => 'Save';

  @override
  String get noteDelete => 'Delete note';

  @override
  String get imageAdd => 'Add image';

  @override
  String get imageRemove => 'Remove image';

  @override
  String get pickImagesTitle => 'Choose image';

  @override
  String get share => 'Share';

  @override
  String get openWith => 'Open with another app';

  @override
  String get cannotOpen => 'Could not open file';

  @override
  String get deleted => 'Recording deleted';

  @override
  String get discarded => 'Recording discarded';

  @override
  String get unplayable => 'Unplayable';

  @override
  String unplayableNotice(int count) {
    return '$count recordings couldn\'t be opened. They\'re marked; you can delete them.';
  }

  @override
  String get undo => 'Undo';

  @override
  String get undoExpired => 'Undo time is up — removed permanently';

  @override
  String recordSaved(String duration) {
    return 'Recording saved • $duration';
  }

  @override
  String get recLongPress => 'hold to cancel';

  @override
  String recElapsed(String time) {
    return 'elapsed time $time';
  }

  @override
  String get recDiscarded => 'Recording discarded';

  @override
  String get recInterrupted => 'Call or audio interruption — recording saved';

  @override
  String get emptyDay =>
      'No recordings on this day.\nTap another day or add one from the Record tab.';

  @override
  String get sess_asia => 'Asia';

  @override
  String get sess_preLondon => 'Pre-London';

  @override
  String get sess_londonAm => 'London AM';

  @override
  String get sess_preNy => 'Pre-NY';

  @override
  String get sess_nyPre => 'NY Premarket';

  @override
  String get sess_nyAm => 'NY AM';

  @override
  String get sess_nyLunch => 'NY Lunch';

  @override
  String get sess_nyPm => 'NY PM';

  @override
  String get sess_closed => 'Closed';

  @override
  String get sess_afterHours => 'After hours';

  @override
  String get sess_weekendLabel => 'Weekend';

  @override
  String get schTitle => 'Market schedule';

  @override
  String get schTime => 'Time (ET)';

  @override
  String get schState => 'State';

  @override
  String get schSession => 'Session';

  @override
  String get schOpen => 'Open';

  @override
  String get schPre => 'Pre';

  @override
  String get schClosed => 'Closed';

  @override
  String get schNow => 'now';

  @override
  String get sessd_asia => 'overnight flow';

  @override
  String get sessd_preLondon => 'getting ready for the London open';

  @override
  String get sessd_londonAm => 'open killzone';

  @override
  String get sessd_preNy => 'London lunch • waiting on NY';

  @override
  String get sessd_nyPre => 'data • pre-open prep';

  @override
  String get sessd_nyAm => '09:30 open';

  @override
  String get sessd_nyLunch => 'slow flow • usually wait';

  @override
  String get sessd_nyPm => 'power hour 15:00–16:00';

  @override
  String get sessd_afterHours => 'after hours';

  @override
  String get sessd_weekend => 'weekend';

  @override
  String get searchHint => 'Search session / date / note…';

  @override
  String get calShow => 'Show calendar';

  @override
  String get calHide => 'Hide calendar';

  @override
  String get filterAll => 'All';

  @override
  String get clearFilters => 'Clear';

  @override
  String get noResults =>
      'No matches.\nTry another search or clear the filters.';

  @override
  String get storageTitle => 'Space used';

  @override
  String storageDetail(int count, String size) {
    return '$count recordings • $size';
  }
}
