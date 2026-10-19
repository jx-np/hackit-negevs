// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get commonReport => 'Lapor';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonRetry => 'Cuba lagi';

  @override
  String get commonRefresh => 'Muat semula';

  @override
  String get commonReviewed => 'Disemak';

  @override
  String get commonClear => 'Kosongkan';

  @override
  String get commonUnknown => 'Tidak diketahui';

  @override
  String get commonReportThis => 'Lapor ini';

  @override
  String get commonNoPostsYet => 'Tiada siaran lagi';

  @override
  String get commonShareWithCommunity => 'Kongsi';

  @override
  String get commonShare => 'Kongsi';

  @override
  String get commonSharing => 'Berkongsi...';

  @override
  String get commonTitle => 'Tajuk';

  @override
  String get commonTitleHint => 'Ringkasan pendek';

  @override
  String get commonMessage => 'Mesej';

  @override
  String get commonMessageHint => 'Tampal mesej';

  @override
  String get commonWhatKindOfScam => 'Jenis penipuan';

  @override
  String get commonShareIntro =>
      'Kongsi penipuan. Buang maklumat peribadi dahulu.';

  @override
  String get commonPhotos => 'Foto (pilihan)';

  @override
  String get commonAddPhoto => 'Tambah foto';

  @override
  String get commonRemovePhoto => 'Buang foto';

  @override
  String get commonImageTooLarge =>
      'Setiap imej mestilah 10 MB atau lebih kecil.';

  @override
  String get reportTabPhotoProcessing => 'Menyemak…';

  @override
  String get reportTabPhotoFailed => 'Tidak dapat semak';

  @override
  String get reportTabProcessingTitle => 'Sedang diproses. Jangan tutup apl.';

  @override
  String get reportTabSignInToAddPhotos => 'Log masuk untuk tambah foto.';

  @override
  String get reportTabFailedDialogTitle => 'Ada foto gagal';

  @override
  String reportTabFailedDialogBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto gagal. Cuba lagi, atau siar tanpanya?',
      one: '1 foto gagal. Cuba lagi, atau siar tanpanya?',
    );
    return '$_temp0';
  }

  @override
  String get reportTabFailedRetry => 'Cuba semula';

  @override
  String get reportTabFailedPostWithout => 'Siar tanpa foto';

  @override
  String get reportTabWaitForImages => 'Tunggu foto';

  @override
  String get reportTabCheckImages => 'Semak foto';

  @override
  String get reportTabReviewCheckbox => 'Saya setuju untuk siarkan foto ini';

  @override
  String get reportTabEditImage => 'Edit foto';

  @override
  String get reportTabReuploading => 'Menyimpan foto yang disunting…';

  @override
  String get reportTabPosting => 'Menyiarkan...';

  @override
  String get reportTabEditorSaveFailed =>
      'Tidak dapat simpan foto yang disunting. Cuba lagi.';

  @override
  String get reportTabEditorLoadFailed =>
      'Tidak dapat buka foto itu. Cuba lagi.';

  @override
  String get reportTabViewPost => 'Lihat siaran anda';

  @override
  String get homeTitle => 'Utama';

  @override
  String get homeWelcomePrefix => 'Hai, ';

  @override
  String get homeWelcomeGuest => 'Hai';

  @override
  String get myProfileTitle => 'Profil';

  @override
  String get myProfileMemberSince => 'Ahli sejak';

  @override
  String get myProfilePosts => 'Siaran';

  @override
  String get myProfileSignOut => 'Log keluar';

  @override
  String get myProfileSignOutHint =>
      'Anda boleh log masuk semula bila-bila masa.';

  @override
  String get myProfileNotSignedInTitle => 'Belum log masuk';

  @override
  String get myProfileNotSignedInBody => 'Log masuk untuk lihat akaun anda.';

  @override
  String get myProfileSignIn => 'Log masuk';

  @override
  String get homeNewsTitle => 'Amaran penipuan';

  @override
  String get homeNewsError => 'Tidak dapat muat amaran.';

  @override
  String get homeNewsRetry => 'Cuba semula';

  @override
  String get homeQuickActionsTitle => 'Apa yang anda mahu buat?';

  @override
  String get homeActionProfile => 'Profil';

  @override
  String get homeActionProfileBody => 'Butiran dan siaran anda';

  @override
  String get homeActionCalls => 'Panggilan';

  @override
  String get homeActionCallsBody =>
      'Semak panggilan daripada nombor yang tidak dikenali';

  @override
  String get homeActionReport => 'Laporkan penipuan';

  @override
  String get homeActionReportBody => 'Ingatkan orang lain';

  @override
  String get homeStatusOnBody => 'Menyemak mesej anda untuk penipuan.';

  @override
  String get homeStatusOffBody => 'Hidupkan untuk dapat amaran penipuan.';

  @override
  String get homeStatusProblemTitle => 'Perlindungan perlu dibaiki';

  @override
  String get homeStatusProblemBody => 'Ada masalah. Ketik untuk baiki.';

  @override
  String get homeStatusStartingTitle => 'Sedang bermula…';

  @override
  String get homeStatusStartingBody => 'Ini mungkin ambil masa seminit.';

  @override
  String get homeStatusOpen => 'Butiran';

  @override
  String get homeStatusFix => 'Baiki';

  @override
  String get homeNewsReadMore => 'Baca lagi';

  @override
  String get homeNewsClose => 'Tutup';

  @override
  String homeNewsCount(Object current, Object total) {
    return '$current daripada $total';
  }

  @override
  String get homeNewsPrevious => 'Sebelum';

  @override
  String get homeNewsNext => 'Seterusnya';

  @override
  String get settingsProtection => 'Perlindungan';

  @override
  String get settingsStopProtection => 'Jeda perlindungan';

  @override
  String get settingsServiceRunning => 'Hidup';

  @override
  String get settingsServiceStopped => 'Dijeda';

  @override
  String get settingsShowTutorial => 'Tunjuk lawatan semula';

  @override
  String get settingsReplayTour => 'Lawatan pantas apl';

  @override
  String get settingsRemove => 'Buang';

  @override
  String settingsPercent(int pct) {
    return '$pct%';
  }

  @override
  String get settingsDownload => 'Muat turun';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageSystem => 'Lalai telefon';

  @override
  String get settingsStatusTitle => 'Status';

  @override
  String get settingsGettingReady => 'Sedang bermula…';

  @override
  String get settingsNeedsDownload => 'Perlu muat turun';

  @override
  String settingsModelReady(String name) {
    return '$name sudah sedia';
  }

  @override
  String settingsModelNotDownloaded(String name) {
    return '$name belum dimuat turun';
  }

  @override
  String settingsSettingUpPct(int pct) {
    return 'Menyediakan… $pct%';
  }

  @override
  String settingsSettingUpMb(int mb) {
    return 'Menyediakan… $mb MB';
  }

  @override
  String get settingsCheckerTitle => 'Penyemak penipuan';

  @override
  String get settingsCheckerCaption =>
      'Menyemak mesej pada telefon anda. Tiada apa keluar dari telefon.';

  @override
  String get settingsCheckingSupport => 'Menyemak telefon anda…';

  @override
  String get settingsNotAvailable => 'Tidak tersedia pada telefon ini';

  @override
  String get settingsReadyShort => 'Sedia';

  @override
  String get settingsBuiltInSubtitle => 'Terbina dalam. Tiada muat turun.';

  @override
  String settingsAboutMb(int mb) {
    return 'Kira-kira $mb MB';
  }

  @override
  String get settingsPrepare => 'Sediakan';

  @override
  String get settingsSpeedTitle => 'Kelajuan';

  @override
  String get settingsSpeedCaption =>
      'Biarkan Automatik kecuali penyemak ada masalah.';

  @override
  String get settingsSpeedAuto => 'Automatik';

  @override
  String get settingsSpeedAutoBody => 'Terbaik untuk kebanyakan telefon';

  @override
  String get settingsSpeedCpu => 'Paling serasi';

  @override
  String get settingsSpeedCpuBody =>
      'Berfungsi pada setiap telefon. Paling perlahan.';

  @override
  String get settingsSpeedGpu => 'Lebih pantas';

  @override
  String get settingsSpeedGpuBody => 'Guna cip grafik';

  @override
  String get settingsSpeedNpu => 'Paling pantas';

  @override
  String get settingsSpeedNpuBody => 'Telefon baharu sahaja';

  @override
  String get settingsAppSection => 'Apl';

  @override
  String get settingsAppearance => 'Tema';

  @override
  String get settingsThemeLight => 'Cerah';

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsPermissionsSubtitle => 'Lihat apa apl boleh buat';

  @override
  String get settingsSignInSubtitle => 'Perlu untuk siar';

  @override
  String callIncoming(String who) {
    return 'Panggilan dari $who';
  }

  @override
  String callBlocked(String number) {
    return 'Disekat $number';
  }

  @override
  String callUnblocked(String number) {
    return 'Dinyahsekat $number';
  }

  @override
  String callReported(String number) {
    return 'Dilaporkan $number';
  }

  @override
  String get callOutgoing => 'Keluar';

  @override
  String get callAnswered => 'Dijawab';

  @override
  String get callRejected => 'Ditolak';

  @override
  String get callMissed => 'Terlepas';

  @override
  String get callBlockedLabel => 'Disekat';

  @override
  String get navHome => 'Utama';

  @override
  String get navCalls => 'Panggilan';

  @override
  String get navSafety => 'Keselamatan';

  @override
  String get navReport => 'Lapor';

  @override
  String get navProfile => 'Profil';

  @override
  String get callHistoryTitle => 'Panggilan';

  @override
  String get callBlockedNumbers => 'Nombor disekat';

  @override
  String get callNoUnknown => 'Tiada panggilan dari nombor tidak dikenali';

  @override
  String get callPhonePermNeeded => 'Benarkan akses telefon';

  @override
  String get callPhonePermBody =>
      'Perlu untuk tunjuk panggilan dan kesan penipuan.';

  @override
  String get callGrantPhone => 'Benarkan';

  @override
  String get callCouldNotLoad => 'Tidak dapat tunjuk panggilan';

  @override
  String callDurationSuffix(int seconds) {
    return ' • ${seconds}s';
  }

  @override
  String get callReportedSuffix => ' • Dilaporkan';

  @override
  String get callUnblock => 'Nyahsekat';

  @override
  String get callBlockNeedsScreening =>
      'Untuk sekat panggilan, tetapkan apl ini sebagai penyekat panggilan.';

  @override
  String get callHighRiskTitle => 'Panggilan mungkin penipuan';

  @override
  String get callHighRiskBody =>
      'Orang ramai lapor nombor ini sebagai penipuan. Jangan kongsi wang atau maklumat peribadi.';

  @override
  String callHighRiskScore(int score) {
    return 'Skor: $score/100';
  }

  @override
  String callHighRiskReports(int count) {
    return '$count laporan';
  }

  @override
  String get callHighRiskDismiss => 'Faham';

  @override
  String get callHighRiskBlock => 'Ini Penipuan – Sekat';

  @override
  String get callHighRiskSafe => 'Selamat / Tutup';

  @override
  String get callChecking => 'Menyemak…';

  @override
  String get callCheckTitle => 'Semak nombor';

  @override
  String get callCheckNumberLabel => 'Nombor yang disemak';

  @override
  String get callCheckResultHighRisk => 'Mungkin penipuan';

  @override
  String get callCheckResultUnknown => 'Tiada laporan';

  @override
  String get callCheckResultSafe => 'Nampak selamat';

  @override
  String get callCheckResultFailed => 'Tidak dapat semak';

  @override
  String get callCheckDetailHighRisk =>
      'Orang ramai lapor nombor ini sebagai penipuan. Jangan hubungi semula.';

  @override
  String get callCheckDetailUnknown => 'Tiada laporan. Tetap berhati-hati.';

  @override
  String get callCheckDetailSafe => 'Nampak selamat. Tetap berhati-hati.';

  @override
  String get callCheckDetailFailed => 'Semak internet anda dan cuba lagi.';

  @override
  String callCheckScore(int score) {
    return 'Skor: $score/100';
  }

  @override
  String callCheckReports(int count) {
    return '$count laporan';
  }

  @override
  String get reportNotSent => 'Tidak dapat hantar. Laporan belum disediakan.';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportScam => 'Penipuan';

  @override
  String get reportOther => 'Lain-lain';

  @override
  String get reportReason => 'Sebab';

  @override
  String get shieldCheck => 'Semak';

  @override
  String get permDenied => 'Kebenaran dinafikan';

  @override
  String get permConfirmScreening =>
      'Tetapkan apl ini sebagai penyemak panggilan';

  @override
  String get permScreeningUnavailable =>
      'Penyaringan panggilan tiada pada telefon ini';

  @override
  String get permNotificationAccess => 'Semak mesej';

  @override
  String get permNotificationAccessSub =>
      'Membaca mesej baharu untuk kesan penipuan';

  @override
  String get permOverlay => 'Amaran panggilan';

  @override
  String get permOverlaySub => 'Tunjuk amaran semasa panggilan';

  @override
  String get permAlerts => 'Amaran';

  @override
  String get permAlertsSub => 'Hantar amaran penipuan';

  @override
  String get permBackground => 'Terus berjalan';

  @override
  String get permBackgroundSub => 'Berfungsi bila skrin mati';

  @override
  String get permBatterySettings => 'Jangan jeda apl';

  @override
  String get permBatterySettingsSub =>
      'Tetapkan apl ini kepada \"Jangan optimumkan\".';

  @override
  String get permGranted => 'Hidup';

  @override
  String get permGrant => 'Hidupkan';

  @override
  String get permScreeningRole => 'Semak panggilan';

  @override
  String get permScreeningRoleSub =>
      'Menyemak panggilan dan menyekat nombor pilihan anda.';

  @override
  String get permScreeningActive => 'Hidup';

  @override
  String get permEnableScreening => 'Hidupkan';

  @override
  String get permScreeningNotGranted => 'Semakan panggilan dimatikan';

  @override
  String get permScreeningTapHint => 'Ketik \"Hidupkan\" di atas.';

  @override
  String get permTitle => 'Kebenaran';

  @override
  String get permGrantFollowing => 'Hidupkan ini untuk perlindungan penuh.';

  @override
  String get permPhoneCallLog => 'Panggilan telefon';

  @override
  String get permPhoneGranted => 'Akses telefon dibenarkan';

  @override
  String get permContacts => 'Kenalan';

  @override
  String get permContactsGranted => 'Kenalan dibenarkan';

  @override
  String get permNotifications => 'Pemberitahuan';

  @override
  String get permNotificationsGranted => 'Pemberitahuan dibenarkan';

  @override
  String get permStillNotWorking => 'Masih tidak berfungsi?';

  @override
  String get permOpenSettingsBody =>
      'Hidupkan kebenaran dalam tetapan telefon anda.';

  @override
  String get permOpenAppSettings => 'Buka tetapan';

  @override
  String get permNotChecked => 'Belum disemak';

  @override
  String get permStatusDenied => 'Mati';

  @override
  String get permPermanentlyDenied => 'Mati. Hidupkan di tetapan';

  @override
  String get permNotGranted => 'Mati';

  @override
  String get contactsPermRequired =>
      'Benarkan kenalan untuk lihat kenalan anda.';

  @override
  String get contactsTitle => 'Kenalan';

  @override
  String get contactsSearchHint => 'Cari nama atau nombor';

  @override
  String get contactsCouldNotLoad => 'Tidak dapat muat kenalan';

  @override
  String get contactsNoneFound => 'Tiada kenalan';

  @override
  String get contactsNoDetails => 'Tiada butiran';

  @override
  String get contactsCouldNotCall => 'Tidak dapat memulakan panggilan';

  @override
  String get safetyTitle => 'Keselamatan';

  @override
  String get safetyRecentAlerts => 'Amaran terkini';

  @override
  String get safetyProtectedOn => 'Dilindungi';

  @override
  String get safetyProtectedOff => 'Perlindungan mati';

  @override
  String get safetyWeCheck => 'Menyemak mesej anda untuk penipuan.';

  @override
  String get safetyTurnOnToCheck => 'Hidupkan untuk semak mesej.';

  @override
  String get safetyTurnOff => 'Matikan perlindungan';

  @override
  String get safetyTurnOn => 'Hidupkan perlindungan';

  @override
  String get safetyPressToStart => 'Tekan untuk mula';

  @override
  String get safetyDownloadingModel => 'Memuat turun…';

  @override
  String get safetySettingUpModel => 'Menyediakan…';

  @override
  String get safetyNoScams => 'Tiada penipuan';

  @override
  String get safetyNoScamsBody => 'Penipuan akan dipaparkan di sini.';

  @override
  String get safetyMeteredTitle => 'Guna data mudah alih?';

  @override
  String safetyMeteredBody(int mb) {
    return 'Muat turun kira-kira $mb MB. Wi-Fi lebih baik.';
  }

  @override
  String get safetyNotNow => 'Bukan sekarang';

  @override
  String get safetyDownload => 'Muat turun';

  @override
  String get safetyCouldNotStart =>
      'Tidak dapat mulakan perlindungan. Cuba lagi.';

  @override
  String get safetyShowMore => 'Tunjuk lagi';

  @override
  String get safetyShowLess => 'Tunjuk kurang';

  @override
  String get safetyPillOn => 'Dilindungi';

  @override
  String get safetyPillOff => 'Mati';

  @override
  String get safetyPillError => 'Perlu dibaiki';

  @override
  String get safetyPillChecking => 'Menyemak';

  @override
  String get safetyHeroOnBody => 'Disemak pada telefon anda.';

  @override
  String get protectionChecked => 'Disemak';

  @override
  String get protectionAlerts => 'Amaran';

  @override
  String get protectionOn => 'Perlindungan dihidupkan';

  @override
  String get protectionOff => 'Perlindungan dimatikan';

  @override
  String activityAll(int count) {
    return 'Semua ($count)';
  }

  @override
  String activityScams(int count) {
    return 'Penipuan ($count)';
  }

  @override
  String activityUnchecked(int count) {
    return 'Belum disemak ($count)';
  }

  @override
  String get activityNoMessages => 'Belum ada mesej.';

  @override
  String get activityNotCheckedSuffix => ' · belum disemak';

  @override
  String get activityCloudSuffix => ' · dalam talian';

  @override
  String get activityNotCheckedYet => 'Belum disemak.';

  @override
  String get activityVerdict => 'Keputusan';

  @override
  String get activityConfidence => 'Keyakinan';

  @override
  String get activityCheckedBy => 'Disemak oleh';

  @override
  String activityEscalatedSuffix(String wire) {
    return '$wire (dalam talian)';
  }

  @override
  String get activityReason => 'Sebab';

  @override
  String get activityAiThinking => 'Keputusan penuh';

  @override
  String get activityNoOutput => '(Tiada keputusan)';

  @override
  String get blockedNumbersTitle => 'Nombor Disekat';

  @override
  String get blockedNoNumbers => 'Tiada nombor disekat';

  @override
  String get notificationsTitle => 'Pemberitahuan';

  @override
  String get activityTitle => 'Aktiviti';

  @override
  String get notificationsTestTitle => 'Uji mesej';

  @override
  String get notificationsTestHint => 'Tampal atau taip mesej';

  @override
  String get notificationsTestRun => 'Semak mesej';

  @override
  String get notificationsTestServiceOff => 'Hidupkan perlindungan dahulu.';

  @override
  String get notificationsTestSent =>
      'Sedang menyemak. Keputusan akan dipaparkan di bawah.';

  @override
  String get settingsScreenTitle => 'Tetapan';

  @override
  String get settingsScreenPermissionsTab => 'Kebenaran';

  @override
  String get onboardingContinue => 'Teruskan';

  @override
  String get onboardingBack => 'Kembali';

  @override
  String get onboardingStart => 'Mula';

  @override
  String get onboardingAllow => 'Benarkan';

  @override
  String get onboardingOpenSettings => 'Buka tetapan';

  @override
  String get onboardingNotNow => 'Bukan sekarang';

  @override
  String get onboardingFinish => 'Buka apl';

  @override
  String onboardingStepCount(int step, int total) {
    return 'Langkah $step daripada $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Jauhi penipuan';

  @override
  String get onboardingWelcomeBody =>
      'Kami beri amaran tentang panggilan dan mesej penipuan. Persediaan pantas.';

  @override
  String get onboardingWelcomeNote =>
      'Anda boleh ubah ini kemudian di Tetapan.';

  @override
  String get onboardingPhoneTitle => 'Panggilan telefon';

  @override
  String get onboardingPhoneBody => 'Lihat siapa yang memanggil.';

  @override
  String get onboardingContactsTitle => 'Kenalan';

  @override
  String get onboardingContactsBody =>
      'Panggilan daripada orang yang anda kenal tidak ditanda.';

  @override
  String get onboardingScreeningTitle => 'Semak panggilan';

  @override
  String get onboardingScreeningBody =>
      'Semak panggilan dan sekat nombor pilihan anda.';

  @override
  String get onboardingNotificationsTitle => 'Amaran';

  @override
  String get onboardingNotificationsBody =>
      'Dapat amaran jika ada kemungkinan penipuan.';

  @override
  String get onboardingMessagesTitle => 'Semak mesej';

  @override
  String get onboardingMessagesBody =>
      'Baca mesej baharu untuk kesan penipuan.';

  @override
  String get onboardingOverlayTitle => 'Amaran panggilan';

  @override
  String get onboardingOverlayBody =>
      'Tunjuk amaran semasa panggilan berisiko.';

  @override
  String get onboardingBackgroundTitle => 'Terus berjalan';

  @override
  String get onboardingBackgroundBody => 'Terus semak bila skrin mati.';

  @override
  String get onboardingBatterySettingsTitle => 'Jangan jeda apl';

  @override
  String get onboardingBatterySettingsBody =>
      'Halang telefon daripada menjeda apl.';

  @override
  String get onboardingSettingsHint =>
      'Tetapan akan dibuka. Cari apl ini dan hidupkannya.';

  @override
  String get onboardingStatusOn => 'Hidup.';

  @override
  String get onboardingStatusSkipped =>
      'Tidak hidup. Anda boleh hidupkan di Tetapan.';

  @override
  String get onboardingStatusBlocked =>
      'Telefon anda tidak akan tanya lagi. Ketik \"Buka tetapan\".';

  @override
  String get onboardingDoneTitle => 'Semuanya sedia';

  @override
  String get onboardingDoneBody => 'Kami sedang memantau penipuan.';

  @override
  String get onboardingDonePartialTitle => 'Hampir selesai';

  @override
  String get onboardingDonePartialBody =>
      'Ada yang belum hidup. Anda boleh hidupkan di Tetapan.';

  @override
  String onboardingGrantedCount(int granted, int total) {
    return '$granted daripada $total dihidupkan';
  }

  @override
  String get onboardingWhy => 'Mengapa?';

  @override
  String get onboardingScreeningWhy =>
      'Pilih apl ini supaya panggilan boleh disemak.';

  @override
  String get onboardingMessagesWhy =>
      'Kami cari pautan pelik atau permintaan wang.';

  @override
  String get onboardingBatterySettingsHint =>
      'Tetapan akan dibuka. Cari apl ini dan pilih \"Jangan optimumkan\".';

  @override
  String get onboardingModelTitle => 'Penyemak penipuan';

  @override
  String get onboardingModelBody =>
      'Menyemak mesej pada telefon anda. Guna Wi-Fi.';

  @override
  String onboardingModelDownload(String size) {
    return 'Muat turun ($size)';
  }

  @override
  String get onboardingModelDownloadShort => 'Muat turun';

  @override
  String onboardingModelDownloading(int percent) {
    return 'Memuat turun… $percent%';
  }

  @override
  String get onboardingModelKeepGoing =>
      'Anda boleh teruskan. Muat turun diteruskan.';

  @override
  String get onboardingModelReady => 'Sedia.';

  @override
  String get onboardingModelFailed =>
      'Muat turun tidak selesai. Cuba lagi atau guna Tetapan.';

  @override
  String get onboardingModelMeteredTitle => 'Guna data mudah alih?';

  @override
  String onboardingModelMeteredBody(String size) {
    return 'Anda tidak guna Wi-Fi. Ini guna kira-kira $size.';
  }

  @override
  String get setupOpenSettingsFailed => 'Tidak dapat membuka tetapan.';

  @override
  String get authEnterEmail => 'Masukkan e-mel anda.';

  @override
  String get authValidEmail => 'Masukkan e-mel yang sah.';

  @override
  String get authEnterPassword => 'Masukkan kata laluan anda.';

  @override
  String get authPasswordLength => 'Guna sekurang-kurangnya 8 aksara.';

  @override
  String get authEnterName => 'Masukkan nama anda.';

  @override
  String get authNameInvalid =>
      'Huruf dan nombor sahaja. Satu ruang dibenarkan.';

  @override
  String get authCreateAccount => 'Cipta akaun';

  @override
  String get authSignIn => 'Log masuk';

  @override
  String get authRegisterIntro => 'Sertai untuk kongsi penipuan.';

  @override
  String get authLoginIntro => 'Log masuk untuk siar dan komen.';

  @override
  String get authYourName => 'Nama anda';

  @override
  String get authYourNameHint => 'Masukkan nama anda';

  @override
  String get authEmail => 'E-mel';

  @override
  String get authEmailHint => 'Masukkan e-mel anda';

  @override
  String get authPassword => 'Kata laluan';

  @override
  String get authPasswordHint => 'Masukkan kata laluan anda';

  @override
  String get authShowPassword => 'Tunjuk kata laluan';

  @override
  String get authHidePassword => 'Sembunyi kata laluan';

  @override
  String get authToggleToLogin => 'Sudah ada akaun? Log masuk';

  @override
  String get authToggleToRegister => 'Baru di sini? Cipta akaun';

  @override
  String get authGateTitle => 'Log masuk untuk meneruskan';

  @override
  String get authGateBody => 'Anda perlu akaun. Ia percuma.';

  @override
  String get authGateAction => 'Log masuk';

  @override
  String get communityTitle => 'Komuniti';

  @override
  String get communityShareScam => 'Kongsi penipuan';

  @override
  String get communityAll => 'Semua';

  @override
  String get communityNoPostsBody =>
      'Penipuan yang dikongsi akan dipaparkan di sini.';

  @override
  String get createChooseType => 'Pilih jenis penipuan.';

  @override
  String get createAddTitle => 'Tambah tajuk.';

  @override
  String get createAddMessage => 'Tambah teks mesej.';

  @override
  String get reportTabTitle => 'Lapor';

  @override
  String get reportTabThankYou => 'Dikongsi. Terima kasih!';

  @override
  String get reportTabTrackIt =>
      'Dikongsi. Lihat Profil Saya untuk menjejakinya.';

  @override
  String get reportTabHeroTitle => 'Ingatkan orang lain tentang penipuan';

  @override
  String get reportTabNumberHeroTitle => 'Laporkan nombor';

  @override
  String get reportTabNumberHeroBody =>
      'Beritahu kenapa nombor ini mencurigakan. Laporan anda membantu orang lain.';

  @override
  String get reportTabPaste => 'Tampal';

  @override
  String get reportTabPasteEmpty =>
      'Tiada apa-apa untuk ditampal. Salin mesej dahulu.';

  @override
  String get reportTabNumberLabel => 'Nombor telefon';

  @override
  String get reportTabNumberHint => 'cth. +65 9123 4567';

  @override
  String get reportTabNumberRequired => 'Masukkan nombor telefon.';

  @override
  String get reportTabReasonLabel => 'Apa yang berlaku?';

  @override
  String get reportTabReasonSpamBody =>
      'Panggilan atau iklan yang tidak diingini';

  @override
  String get reportTabReasonScamBody =>
      'Mereka cuba menipu saya atau mengambil wang saya';

  @override
  String get reportTabReasonOtherBody => 'Ada sesuatu yang tidak kena';

  @override
  String get reportTabSuccessTitle => 'Terima kasih';

  @override
  String get reportTabReportAnother => 'Laporkan satu lagi';

  @override
  String get reportTabDone => 'Selesai';

  @override
  String get myPostsTitle => 'Siaran saya';

  @override
  String get myPostsNoneBody =>
      'Laporan yang anda kongsi akan dipaparkan di sini.';

  @override
  String get myPostsDelete => 'Padam';

  @override
  String get myPostsDeleteConfirm => 'Padam siaran ini?';

  @override
  String get myPostsDeleteConfirmBody =>
      'Ia akan dibuang untuk semua orang. Ini tidak boleh dibatalkan.';

  @override
  String get myPostsEdit => 'Edit';

  @override
  String get editPostTitle => 'Edit siaran';

  @override
  String get editPostSave => 'Simpan';

  @override
  String get editPostSaving => 'Menyimpan...';

  @override
  String get editPostSaved => 'Disimpan.';

  @override
  String get editPostReReview =>
      'Suntingan menghantar siaran semula untuk semakan.';

  @override
  String get postDetailThankYou => 'Terima kasih. Kami akan semak siaran ini.';

  @override
  String get postDetailTitle => 'Siaran';

  @override
  String get postDetailReportTooltip => 'Lapor siaran';

  @override
  String postDetailComments(int count) {
    return 'Komen ($count)';
  }

  @override
  String get postDetailNoComments => 'Belum ada komen.';

  @override
  String get postDetailWriteComment => 'Tulis komen';

  @override
  String get postDetailPostComment => 'Siar';

  @override
  String get postDetailFlagPersonalInfo => 'Menunjukkan maklumat peribadi';

  @override
  String get postDetailFlagHarmful => 'Berbahaya';

  @override
  String get postDetailFlagSpam => 'Spam';

  @override
  String get postDetailFlagMisinfo => 'Maklumat salah';

  @override
  String get postDetailFlagOther => 'Lain-lain';

  @override
  String get postDetailReply => 'Balas';

  @override
  String get postDetailEdit => 'Edit';

  @override
  String get postDetailDelete => 'Padam';

  @override
  String get postDetailSave => 'Simpan';

  @override
  String get postDetailCancel => 'Batal';

  @override
  String postDetailReplying(String name) {
    return 'Membalas $name';
  }

  @override
  String get postDetailWriteReply => 'Tulis balasan';

  @override
  String get postDetailDeleteConfirm => 'Padam komen ini?';

  @override
  String get postDetailDeleteConfirmBody => 'Ini tidak boleh dibatalkan.';

  @override
  String get postDetailEdited => 'disunting';

  @override
  String get postDetailRemovedComment => 'Komen ini telah dialih keluar.';

  @override
  String get postDetailAiBadge => 'AI';

  @override
  String get postDetailMentionHelpHint => 'Ask NegevAI about this post';

  @override
  String get postDetailBotThinking => 'NegevAI is thinking...';

  @override
  String get guidanceClickedLink => 'Saya klik pautan';

  @override
  String get guidanceGotMessage => 'Saya terima mesej';

  @override
  String get guidanceSharedPassword => 'Saya kongsi kata laluan saya';

  @override
  String get guidanceSentMoney => 'Saya hantar wang';

  @override
  String get guidanceCouldNotOpenLink => 'Tidak dapat buka pautan.';

  @override
  String get guidanceCouldNotCall => 'Tidak dapat mulakan panggilan.';

  @override
  String get guidanceTitle => 'Dapatkan bantuan';

  @override
  String get guidanceWhatHappened => 'Apa yang berlaku?';

  @override
  String get guidanceWhoToContact => 'Siapa untuk dihubungi';

  @override
  String get guidanceShowAll => 'Tunjuk semua';

  @override
  String get guidanceOpenWebsite => 'Buka laman web';

  @override
  String get guidanceNoAdvice => 'Belum ada nasihat';

  @override
  String get guidanceNoAdviceBody =>
      'Pilih apa yang berlaku untuk lihat apa perlu buat.';

  @override
  String get tourHomeTitle => 'Perlindungan';

  @override
  String get tourHomeBody =>
      'Hijau bermaksud dilindungi. Ketik jika tidak hijau.';

  @override
  String get tourCallsTitle => 'Panggilan merah';

  @override
  String get tourCallsBody =>
      'Panggilan merah mungkin penipuan. Jangan jawab atau hubungi semula.';

  @override
  String get tourBlockedTitle => 'Nombor disekat';

  @override
  String get tourBlockedBody =>
      'Ketik perisai bergaris untuk lihat nombor disekat.';

  @override
  String get tourHelpTitle => 'Perlukan bantuan?';

  @override
  String get tourHelpBody => 'Ketik ? pada mana-mana skrin.';

  @override
  String get tourSafetyTitle => 'Hidupkan perlindungan';

  @override
  String get tourSafetyBody =>
      'Hidupkan atau matikan di sini. Kami beri amaran tentang mesej penipuan.';

  @override
  String get tourReportTitle => 'Laporkan penipuan';

  @override
  String get tourReportBody => 'Beritahu orang lain supaya mereka selamat.';

  @override
  String get tourReviewTitle => 'Tick the box';

  @override
  String get tourReviewBody =>
      'After you add photos, check them. Then tick this box to share.';

  @override
  String get tourPostHelpTitle => 'Ask the AI helper';

  @override
  String get tourPostHelpBody =>
      'Not sure if this is a scam? Type @help in a comment. Our AI scam helper will reply.';

  @override
  String get tourPostAiTitle => 'Read the replies';

  @override
  String get tourPostAiBody =>
      'Replies with an AI tag come from the helper. It can make mistakes, so ask someone you trust too.';

  @override
  String get tourPostSampleReply =>
      'This looks like a scam. Do not click the link.';

  @override
  String get tourProfileTitle => 'Profil';

  @override
  String get tourProfileBody =>
      'Lihat siaran dan tetapan anda di sini. Anda boleh ulang lawatan ini di Tetapan.';

  @override
  String tourStepCounter(int current, int total) {
    return '$current daripada $total';
  }

  @override
  String get tourSkip => 'Langkau';

  @override
  String get tourDone => 'Selesai';

  @override
  String get tourNext => 'Seterusnya';

  @override
  String get tourBack => 'Kembali';

  @override
  String get helpTooltip => 'Bantuan';

  @override
  String get helpGotIt => 'Faham';

  @override
  String get helpShowTour => 'Tunjuk lawatan semula';

  @override
  String get helpCallsTitle => 'Maksud setiap perkara';

  @override
  String get helpCallsHighRiskTitle => 'Panggilan merah = kemungkinan penipuan';

  @override
  String get helpCallsHighRiskBody => 'Jangan jawab atau hubungi semula.';

  @override
  String get helpCallsNormalTitle => 'Panggilan biasa';

  @override
  String get helpCallsNormalBody => 'Tiada laporan penipuan.';

  @override
  String get helpCallsBlockedRowTitle => 'Panggilan disekat';

  @override
  String get helpCallsBlockedRowBody =>
      'Nombor ini tidak boleh menghubungi anda.';

  @override
  String get helpCallsBlockedListTitle => 'Nombor disekat';

  @override
  String get helpCallsBlockedListBody =>
      'Ketik ini untuk melihat atau menyahsekat nombor.';

  @override
  String get helpCallsMenuTitle => 'Lebih banyak pilihan';

  @override
  String get helpCallsMenuBody => 'Semak, sekat atau laporkan nombor.';

  @override
  String get helpCallsRefreshTitle => 'Muat semula';

  @override
  String get helpCallsRefreshBody => 'Semak panggilan semula.';

  @override
  String get helpCallsMissedBody => 'Anda tidak menjawab panggilan ini.';

  @override
  String get helpCallsAnsweredBody => 'Anda menjawab panggilan ini.';

  @override
  String get helpCallsRejectedBody => 'Anda menolak panggilan ini.';

  @override
  String get helpCallsBlockedIconBody => 'Panggilan ini disekat.';

  @override
  String get helpCallsOutgoingBody => 'Anda memanggil nombor ini.';

  @override
  String get callsLikelyScam => 'Kemungkinan penipuan';

  @override
  String get callsMoreOptions => 'Lebih banyak pilihan';

  @override
  String get callsBlockNumber => 'Sekat nombor';

  @override
  String get callsReportScam => 'Lapor sebagai penipuan';

  @override
  String get callsBlockAndReport => 'Sekat dan lapor';

  @override
  String get callsCheckNumber => 'Semak nombor';

  @override
  String get callsLoadFailedBody => 'Cuba lagi.';

  @override
  String get callsBlockedEmptyBody =>
      'Nombor yang anda sekat akan dipaparkan di sini.';

  @override
  String get callsContactsLoadFailed =>
      'Tidak dapat tunjuk kenalan. Cuba lagi.';

  @override
  String get callsCallTooltip => 'Panggil';
}
