// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'SnipVoice';

  @override
  String get tabRecord => 'Kaydet';

  @override
  String get tabCalendar => 'Takvim';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Türkçe';

  @override
  String get start => 'BAŞLA';

  @override
  String get stop => 'DURDUR';

  @override
  String get recordingHint => 'kaydediyor… durdurmak için dokun';

  @override
  String get recordingActive => 'Kayıt sürüyor';

  @override
  String get micPermission => 'Mikrofon izni gerekli';

  @override
  String get micIntroTitle => 'Mikrofonu aç';

  @override
  String get micIntroBody =>
      'SnipVoice sesli notlarını kaydeder. Mikrofon yalnızca kayıt sırasında kullanılır.';

  @override
  String get micDeniedTitle => 'Mikrofon erişimi kapalı';

  @override
  String get micDeniedBody =>
      'İzin kalıcı olarak reddedildi. Kayda devam etmek için sistem ayarlarından mikrofonu aç.';

  @override
  String get micContinue => 'Devam';

  @override
  String get openSettings => 'Ayarları aç';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get offlineNotice =>
      'Çevrimdışı mod: kayıtlar cihazda duruyor. Supabase .env eklenince otomatik yüklenir.';

  @override
  String recordingsTitle(int count) {
    return 'Kayıtlar ($count)';
  }

  @override
  String get emptyList =>
      'Henüz kayıt yok.\nTrade öncesi tek tuşa bas, içinden geçenleri anlat.';

  @override
  String playbackFailed(Object err) {
    return 'Çalınamadı: $err';
  }

  @override
  String get customFolder => 'özel klasör';

  @override
  String get openFolder => 'Klasörü aç';

  @override
  String get changeFolder => 'Klasörü değiştir';

  @override
  String get newFolderNotice => 'Yeni kayıtlar bu klasöre gidecek';

  @override
  String get pathCopied => 'Klasör yolu panoya kopyalandı';

  @override
  String get folderTitle => 'Kayıt klasörü';

  @override
  String get resetDefault => 'Varsayılana dön';

  @override
  String get copy => 'Kopyala';

  @override
  String get close => 'Kapat';

  @override
  String get pickFolderTitle => 'Kayıt klasörü seç';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get settingsFolder => 'Kayıt klasörü';

  @override
  String get backedUp => 'yedeklendi';

  @override
  String get onDevice => 'cihazda';

  @override
  String get delete => 'Sil';

  @override
  String get badgeTitle => 'Rozet';

  @override
  String get badgeNone => 'Yok';

  @override
  String get badgeImportant => 'Önemli';

  @override
  String get badgeQuestion => 'Soru';

  @override
  String get badgeFavorite => 'Favori';

  @override
  String get badgeWarning => 'Tehlike';

  @override
  String get badgeChange => 'Rozeti değiştir';

  @override
  String get settingsBadges => 'Özel rozetler';

  @override
  String get customBadgeDesc =>
      'Kendi rozetlerini isim, ikon ve renkle oluştur. Rozet seçicide görünürler.';

  @override
  String get badgeAddNew => 'Rozet ekle';

  @override
  String get badgeNewTitle => 'Yeni rozet';

  @override
  String get badgeEditTitle => 'Rozeti düzenle';

  @override
  String get badgeNameLabel => 'İsim';

  @override
  String get badgeNameHint => 'örn. Kırılım';

  @override
  String get badgeIconLabel => 'İkon';

  @override
  String get badgeColorLabel => 'Renk';

  @override
  String get badgeEmpty => 'Henüz özel rozet yok.';

  @override
  String get save => 'Kaydet';

  @override
  String get settingsPresets => 'Hazır notlar';

  @override
  String get presetDesc =>
      'Kayıt notuna tek dokunuşla yazılabilecek metinler. Not düzenleyicide birine dokunman yeterli.';

  @override
  String get presetAddNew => 'Not ekle';

  @override
  String get presetNewTitle => 'Yeni hazır not';

  @override
  String get presetEditTitle => 'Hazır notu düzenle';

  @override
  String get presetHint => 'örn. Geç girdim';

  @override
  String get presetEmpty => 'Henüz hazır not yok.';

  @override
  String get noteTitle => 'Not';

  @override
  String get noteAdd => 'Not ekle';

  @override
  String get noteEdit => 'Notu düzenle';

  @override
  String get noteHint => 'Ne düşünüyordun?';

  @override
  String get noteSave => 'Kaydet';

  @override
  String get noteDelete => 'Notu sil';

  @override
  String get imageAdd => 'Görsel ekle';

  @override
  String get imageRemove => 'Görseli kaldır';

  @override
  String get pickImagesTitle => 'Görsel seç';

  @override
  String get share => 'Paylaş';

  @override
  String get openWith => 'Başka uygulamayla aç';

  @override
  String get cannotOpen => 'Dosya açılamadı';

  @override
  String get deleted => 'Kayıt silindi';

  @override
  String get discarded => 'Kayıt iptal edildi';

  @override
  String get unplayable => 'Açılamıyor';

  @override
  String unplayableNotice(int count) {
    return '$count kayıt açılamadı. İşaretlendi; silebilirsin.';
  }

  @override
  String get undo => 'Geri al';

  @override
  String get undoExpired => 'Geri alma süresi doldu — kalıcı olarak silindi';

  @override
  String recordSaved(String duration) {
    return 'Kayıt kaydedildi • $duration';
  }

  @override
  String get recLongPress => 'iptal için basılı tut';

  @override
  String recElapsed(String time) {
    return 'geçen süre $time';
  }

  @override
  String get recDiscarded => 'Kayıt iptal edildi';

  @override
  String get recInterrupted => 'Arama/ses kesintisi — kayıt kaydedildi';

  @override
  String get emptyDay =>
      'Bu günde kayıt yok.\nBaşka bir güne dokun ya da Kaydet sekmesinden ekle.';

  @override
  String get sess_asia => 'Asya';

  @override
  String get sess_preLondon => 'Pre-Londra';

  @override
  String get sess_londonAm => 'Londra AM';

  @override
  String get sess_preNy => 'Pre-NY';

  @override
  String get sess_nyPre => 'NY Premarket';

  @override
  String get sess_nyAm => 'NY AM';

  @override
  String get sess_nyLunch => 'NY Öğle';

  @override
  String get sess_nyPm => 'NY PM';

  @override
  String get sess_closed => 'Kapalı';

  @override
  String get sess_afterHours => 'Mesai sonrası';

  @override
  String get sess_weekendLabel => 'Hafta sonu';

  @override
  String get schTitle => 'Piyasa çizelgesi';

  @override
  String get schTime => 'Saat (ET)';

  @override
  String get schState => 'Durum';

  @override
  String get schSession => 'Seans';

  @override
  String get schOpen => 'Açık';

  @override
  String get schPre => 'Öncesi';

  @override
  String get schClosed => 'Kapalı';

  @override
  String get schNow => 'şu an';

  @override
  String get sessd_asia => 'gece akışı';

  @override
  String get sessd_preLondon => 'Londra açılışına hazırlanıyor';

  @override
  String get sessd_londonAm => 'open killzone';

  @override
  String get sessd_preNy => 'Londra öğle • NY bekleniyor';

  @override
  String get sessd_nyPre => 'veriler • açılış hazırlığı';

  @override
  String get sessd_nyAm => '09:30 open';

  @override
  String get sessd_nyLunch => 'sakin akış • genelde bekle';

  @override
  String get sessd_nyPm => 'power hour 15:00-16:00';

  @override
  String get sessd_afterHours => 'after hours';

  @override
  String get sessd_weekend => 'hafta sonu';

  @override
  String get searchHint => 'Session / tarih / not ara…';

  @override
  String get calShow => 'Takvimi göster';

  @override
  String get calHide => 'Takvimi gizle';

  @override
  String get filterAll => 'Tümü';

  @override
  String get clearFilters => 'Temizle';

  @override
  String get noResults =>
      'Sonuç yok.\nBaşka bir arama dene ya da filtreleri temizle.';

  @override
  String get storageTitle => 'Kullanılan alan';

  @override
  String storageDetail(int count, String size) {
    return '$count kayıt • $size';
  }
}
