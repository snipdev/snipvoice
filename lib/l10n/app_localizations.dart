import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SnipVoice'**
  String get appTitle;

  /// No description provided for @tabRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get tabRecord;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get stop;

  /// No description provided for @recordingHint.
  ///
  /// In en, this message translates to:
  /// **'recording… tap to stop'**
  String get recordingHint;

  /// No description provided for @recordingActive.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingActive;

  /// No description provided for @micPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get micPermission;

  /// No description provided for @micIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable the microphone'**
  String get micIntroTitle;

  /// No description provided for @micIntroBody.
  ///
  /// In en, this message translates to:
  /// **'SnipVoice records your voice notes. The microphone is only used while you record.'**
  String get micIntroBody;

  /// No description provided for @micDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off'**
  String get micDeniedTitle;

  /// No description provided for @micDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Permission was denied permanently. Turn on the microphone in system settings to keep recording.'**
  String get micDeniedBody;

  /// No description provided for @micContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get micContinue;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @offlineNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline mode: recordings stay on device. They auto-upload once Supabase .env is added.'**
  String get offlineNotice;

  /// No description provided for @recordingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recordings ({count})'**
  String recordingsTitle(int count);

  /// No description provided for @emptyList.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet.\nBefore a trade, hit the button and talk through what\'s on your mind.'**
  String get emptyList;

  /// No description provided for @playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play: {err}'**
  String playbackFailed(Object err);

  /// No description provided for @customFolder.
  ///
  /// In en, this message translates to:
  /// **'custom folder'**
  String get customFolder;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @changeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change folder'**
  String get changeFolder;

  /// No description provided for @newFolderNotice.
  ///
  /// In en, this message translates to:
  /// **'New recordings will go to this folder'**
  String get newFolderNotice;

  /// No description provided for @pathCopied.
  ///
  /// In en, this message translates to:
  /// **'Folder path copied to clipboard'**
  String get pathCopied;

  /// No description provided for @folderTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording folder'**
  String get folderTitle;

  /// No description provided for @resetDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetDefault;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @pickFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose recording folder'**
  String get pickFolderTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @settingsFolder.
  ///
  /// In en, this message translates to:
  /// **'Recording folder'**
  String get settingsFolder;

  /// No description provided for @backedUp.
  ///
  /// In en, this message translates to:
  /// **'backed up'**
  String get backedUp;

  /// No description provided for @onDevice.
  ///
  /// In en, this message translates to:
  /// **'on device'**
  String get onDevice;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @badgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get badgeTitle;

  /// No description provided for @badgeNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get badgeNone;

  /// No description provided for @badgeImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get badgeImportant;

  /// No description provided for @badgeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get badgeQuestion;

  /// No description provided for @badgeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get badgeFavorite;

  /// No description provided for @badgeWarning.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get badgeWarning;

  /// No description provided for @badgeChange.
  ///
  /// In en, this message translates to:
  /// **'Change badge'**
  String get badgeChange;

  /// No description provided for @settingsBadges.
  ///
  /// In en, this message translates to:
  /// **'Custom badges'**
  String get settingsBadges;

  /// No description provided for @customBadgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your own badges with a name, icon and color. They show up in the badge picker.'**
  String get customBadgeDesc;

  /// No description provided for @badgeAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add badge'**
  String get badgeAddNew;

  /// No description provided for @badgeNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New badge'**
  String get badgeNewTitle;

  /// No description provided for @badgeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit badge'**
  String get badgeEditTitle;

  /// No description provided for @badgeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get badgeNameLabel;

  /// No description provided for @badgeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Breakout'**
  String get badgeNameHint;

  /// No description provided for @badgeIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get badgeIconLabel;

  /// No description provided for @badgeColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get badgeColorLabel;

  /// No description provided for @badgeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom badges yet.'**
  String get badgeEmpty;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @settingsPresets.
  ///
  /// In en, this message translates to:
  /// **'Preset notes'**
  String get settingsPresets;

  /// No description provided for @presetDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick texts you can drop into a recording note. Tap one in the note editor to use it.'**
  String get presetDesc;

  /// No description provided for @presetAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get presetAddNew;

  /// No description provided for @presetNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New preset'**
  String get presetNewTitle;

  /// No description provided for @presetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit preset'**
  String get presetEditTitle;

  /// No description provided for @presetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Entered too late'**
  String get presetHint;

  /// No description provided for @presetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No preset notes yet.'**
  String get presetEmpty;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteTitle;

  /// No description provided for @noteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get noteAdd;

  /// No description provided for @noteEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEdit;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'What were you thinking?'**
  String get noteHint;

  /// No description provided for @noteSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get noteSave;

  /// No description provided for @noteDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get noteDelete;

  /// No description provided for @imageAdd.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get imageAdd;

  /// No description provided for @imageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get imageRemove;

  /// No description provided for @pickImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get pickImagesTitle;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @openWith.
  ///
  /// In en, this message translates to:
  /// **'Open with another app'**
  String get openWith;

  /// No description provided for @cannotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open file'**
  String get cannotOpen;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Recording deleted'**
  String get deleted;

  /// No description provided for @discarded.
  ///
  /// In en, this message translates to:
  /// **'Recording discarded'**
  String get discarded;

  /// No description provided for @unplayable.
  ///
  /// In en, this message translates to:
  /// **'Unplayable'**
  String get unplayable;

  /// No description provided for @unplayableNotice.
  ///
  /// In en, this message translates to:
  /// **'{count} recordings couldn\'t be opened. They\'re marked; you can delete them.'**
  String unplayableNotice(int count);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @undoExpired.
  ///
  /// In en, this message translates to:
  /// **'Undo time is up — removed permanently'**
  String get undoExpired;

  /// No description provided for @recordSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved • {duration}'**
  String recordSaved(String duration);

  /// No description provided for @recLongPress.
  ///
  /// In en, this message translates to:
  /// **'hold to cancel'**
  String get recLongPress;

  /// No description provided for @recElapsed.
  ///
  /// In en, this message translates to:
  /// **'elapsed time {time}'**
  String recElapsed(String time);

  /// No description provided for @recDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Recording discarded'**
  String get recDiscarded;

  /// No description provided for @recInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Call or audio interruption — recording saved'**
  String get recInterrupted;

  /// No description provided for @emptyDay.
  ///
  /// In en, this message translates to:
  /// **'No recordings on this day.\nTap another day or add one from the Record tab.'**
  String get emptyDay;

  /// No description provided for @sess_asia.
  ///
  /// In en, this message translates to:
  /// **'Asia'**
  String get sess_asia;

  /// No description provided for @sess_preLondon.
  ///
  /// In en, this message translates to:
  /// **'Pre-London'**
  String get sess_preLondon;

  /// No description provided for @sess_londonAm.
  ///
  /// In en, this message translates to:
  /// **'London AM'**
  String get sess_londonAm;

  /// No description provided for @sess_preNy.
  ///
  /// In en, this message translates to:
  /// **'Pre-NY'**
  String get sess_preNy;

  /// No description provided for @sess_nyPre.
  ///
  /// In en, this message translates to:
  /// **'NY Premarket'**
  String get sess_nyPre;

  /// No description provided for @sess_nyAm.
  ///
  /// In en, this message translates to:
  /// **'NY AM'**
  String get sess_nyAm;

  /// No description provided for @sess_nyLunch.
  ///
  /// In en, this message translates to:
  /// **'NY Lunch'**
  String get sess_nyLunch;

  /// No description provided for @sess_nyPm.
  ///
  /// In en, this message translates to:
  /// **'NY PM'**
  String get sess_nyPm;

  /// No description provided for @sess_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get sess_closed;

  /// No description provided for @sess_afterHours.
  ///
  /// In en, this message translates to:
  /// **'After hours'**
  String get sess_afterHours;

  /// No description provided for @sess_weekendLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get sess_weekendLabel;

  /// No description provided for @schTitle.
  ///
  /// In en, this message translates to:
  /// **'Market schedule'**
  String get schTitle;

  /// No description provided for @schTime.
  ///
  /// In en, this message translates to:
  /// **'Time (ET)'**
  String get schTime;

  /// No description provided for @schState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get schState;

  /// No description provided for @schSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get schSession;

  /// No description provided for @schOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get schOpen;

  /// No description provided for @schPre.
  ///
  /// In en, this message translates to:
  /// **'Pre'**
  String get schPre;

  /// No description provided for @schClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get schClosed;

  /// No description provided for @schNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get schNow;

  /// No description provided for @sessd_asia.
  ///
  /// In en, this message translates to:
  /// **'overnight flow'**
  String get sessd_asia;

  /// No description provided for @sessd_preLondon.
  ///
  /// In en, this message translates to:
  /// **'getting ready for the London open'**
  String get sessd_preLondon;

  /// No description provided for @sessd_londonAm.
  ///
  /// In en, this message translates to:
  /// **'open killzone'**
  String get sessd_londonAm;

  /// No description provided for @sessd_preNy.
  ///
  /// In en, this message translates to:
  /// **'London lunch • waiting on NY'**
  String get sessd_preNy;

  /// No description provided for @sessd_nyPre.
  ///
  /// In en, this message translates to:
  /// **'data • pre-open prep'**
  String get sessd_nyPre;

  /// No description provided for @sessd_nyAm.
  ///
  /// In en, this message translates to:
  /// **'09:30 open'**
  String get sessd_nyAm;

  /// No description provided for @sessd_nyLunch.
  ///
  /// In en, this message translates to:
  /// **'slow flow • usually wait'**
  String get sessd_nyLunch;

  /// No description provided for @sessd_nyPm.
  ///
  /// In en, this message translates to:
  /// **'power hour 15:00–16:00'**
  String get sessd_nyPm;

  /// No description provided for @sessd_afterHours.
  ///
  /// In en, this message translates to:
  /// **'after hours'**
  String get sessd_afterHours;

  /// No description provided for @sessd_weekend.
  ///
  /// In en, this message translates to:
  /// **'weekend'**
  String get sessd_weekend;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search session / date / note…'**
  String get searchHint;

  /// No description provided for @calShow.
  ///
  /// In en, this message translates to:
  /// **'Show calendar'**
  String get calShow;

  /// No description provided for @calHide.
  ///
  /// In en, this message translates to:
  /// **'Hide calendar'**
  String get calHide;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilters;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matches.\nTry another search or clear the filters.'**
  String get noResults;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Space used'**
  String get storageTitle;

  /// No description provided for @storageDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} recordings • {size}'**
  String storageDetail(int count, String size);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
