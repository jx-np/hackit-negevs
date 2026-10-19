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
  String get commonShareWithCommunity => 'Kongsi dengan komuniti';

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
  String get commonMessageHint => 'Tampal mesej penipuan di sini';

  @override
  String get commonWhatKindOfScam => 'Jenis penipuan apa?';

  @override
  String get commonShareIntro =>
      'Bantu orang lain dengan berkongsi penipuan yang anda terima. Buang sebarang maklumat peribadi dahulu.';

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
  String get reportTabPhotoProcessing => 'Menganalisis...';

  @override
  String get reportTabPhotoFailed => 'Gagal dianalisis';

  @override
  String get reportTabProcessingTitle => 'Jangan tutup aplikasi. Memproses';

  @override
  String get reportTabSignInToAddPhotos => 'Log masuk untuk melampirkan foto.';

  @override
  String get reportTabFailedDialogTitle =>
      'Sesetengah foto tidak dapat dianalisis';

  @override
  String reportTabFailedDialogBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count foto gagal dimuat naik atau dianalisis. Cuba semula, atau siar tanpanya?',
      one:
          '1 foto gagal dimuat naik atau dianalisis. Cuba semula, atau siar tanpanya?',
    );
    return '$_temp0';
  }

  @override
  String get reportTabFailedRetry => 'Cuba semula';

  @override
  String get reportTabFailedPostWithout => 'Siar tanpa foto';

  @override
  String get reportTabWaitForImages => 'Tunggu imej diproses';

  @override
  String get reportTabCheckImages => 'Semak imej';

  @override
  String get reportTabReviewCheckbox =>
      'Saya telah menyemak imej dan butiran peribadi disembunyikan dengan betul';

  @override
  String get reportTabEditImage => 'Edit imej';

  @override
  String get reportTabReuploading =>
      'Memuat naik semula imej yang disunting...';

  @override
  String get reportTabPosting => 'Menyiarkan...';

  @override
  String get reportTabEditorSaveFailed =>
      'Tidak dapat memuat naik semula imej yang disunting. Cuba lagi.';

  @override
  String get reportTabEditorLoadFailed =>
      'Couldn\'t load the image to edit. Try again.';

  @override
  String get reportTabViewPost => 'Lihat siaran anda';

  @override
  String get homeTitle => 'Utama';

  @override
  String get homeWelcomePrefix => 'Selamat datang, ';

  @override
  String get homeWelcomeGuest => 'Welcome';

  @override
  String get myProfileTitle => 'Profil Saya';

  @override
  String get myProfileMemberSince => 'Ahli sejak';

  @override
  String get myProfilePosts => 'Kiriman';

  @override
  String get myProfileSignOut => 'Log keluar';

  @override
  String get myProfileSignOutHint =>
      'Anda boleh log masuk semula pada bila-bila masa';

  @override
  String get myProfileNotSignedInTitle => 'Anda belum log masuk';

  @override
  String get myProfileNotSignedInBody =>
      'Log masuk untuk melihat butiran akaun anda dan mengurus profil anda.';

  @override
  String get myProfileSignIn => 'Log masuk';

  @override
  String get homeNewsTitle => 'Amaran penipuan & berita';

  @override
  String get homeNewsError => 'Tidak dapat memuatkan amaran terkini.';

  @override
  String get homeNewsRetry => 'Cuba semula';

  @override
  String get homeQuickActionsTitle => 'Apa yang anda mahu lakukan?';

  @override
  String get homeActionProfile => 'Profil saya';

  @override
  String get homeActionProfileBody => 'Lihat butiran anda dan kiriman anda';

  @override
  String get homeActionCalls => 'Panggilan terkini';

  @override
  String get homeActionCallsBody =>
      'Semak panggilan daripada nombor yang tidak dikenali';

  @override
  String get homeActionReport => 'Laporkan penipuan';

  @override
  String get homeActionReportBody => 'Ingatkan orang lain dalam komuniti';

  @override
  String get homeStatusOnBody =>
      'Kami sedang menyemak mesej anda untuk mengesan penipuan.';

  @override
  String get homeStatusOffBody =>
      'Hidupkannya supaya kami dapat memberi amaran kepada anda tentang mesej penipuan.';

  @override
  String get homeStatusProblemTitle => 'Perlindungan memerlukan perhatian';

  @override
  String get homeStatusProblemBody =>
      'Sesuatu tidak kena. Ketik di bawah untuk membaikinya.';

  @override
  String get homeStatusStartingTitle => 'Sedang bersedia';

  @override
  String get homeStatusStartingBody =>
      'Perlindungan sedang bermula. Ini mungkin mengambil masa seminit.';

  @override
  String get homeStatusOpen => 'Lihat butiran';

  @override
  String get homeStatusFix => 'Baiki sekarang';

  @override
  String get homeNewsReadMore => 'Baca lagi';

  @override
  String get homeNewsClose => 'Tutup';

  @override
  String homeNewsCount(Object current, Object total) {
    return '$current daripada $total';
  }

  @override
  String get homeNewsPrevious => 'Amaran sebelumnya';

  @override
  String get homeNewsNext => 'Amaran seterusnya';

  @override
  String get settingsProtection => 'Perlindungan';

  @override
  String get settingsStopProtection => 'Hentikan perlindungan latar belakang';

  @override
  String get settingsServiceRunning => 'Perkhidmatan berjalan';

  @override
  String get settingsServiceStopped => 'Perkhidmatan dihentikan';

  @override
  String get settingsShowTutorial => 'Tunjuk tutorial semula';

  @override
  String get settingsReplayTour => 'Main semula gambaran keseluruhan ciri apl';

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
  String get settingsLanguageSystem => 'Lalai sistem';

  @override
  String get settingsStatusTitle => 'Status';

  @override
  String get settingsGettingReady => 'Sedang bersedia…';

  @override
  String get settingsNeedsDownload => 'Perlindungan memerlukan muat turun';

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
      'Menyemak mesej anda pada telefon anda. Tiada apa-apa dihantar keluar.';

  @override
  String get settingsCheckingSupport => 'Menyemak telefon anda…';

  @override
  String get settingsNotAvailable => 'Tidak tersedia pada telefon ini';

  @override
  String get settingsReadyShort => 'Sedia';

  @override
  String get settingsBuiltInSubtitle =>
      'Terbina dalam telefon anda. Tiada muat turun.';

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
      'Biarkan ini pada Automatik melainkan penyemak menghadapi masalah.';

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
  String get settingsSpeedGpuBody => 'Menggunakan cip grafik telefon anda';

  @override
  String get settingsSpeedNpu => 'Paling pantas';

  @override
  String get settingsSpeedNpuBody =>
      'Hanya pada sesetengah telefon yang lebih baharu';

  @override
  String get settingsAppSection => 'Apl';

  @override
  String get settingsAppearance => 'Penampilan';

  @override
  String get settingsThemeLight => 'Cerah';

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsPermissionsSubtitle =>
      'Lihat perkara yang apl dibenarkan lakukan';

  @override
  String get settingsSignInSubtitle =>
      'Diperlukan untuk menyiarkan dalam komuniti';

  @override
  String callIncoming(String who) {
    return 'Panggilan masuk: $who';
  }

  @override
  String callBlocked(String number) {
    return 'Disekat $number';
  }

  @override
  String callUnblocked(String number) {
    return 'Nyahsekat $number';
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
  String get callHistoryTitle => 'Sejarah Panggilan';

  @override
  String get callBlockedNumbers => 'Nombor disekat';

  @override
  String get callNoUnknown => 'Tiada panggilan nombor tidak diketahui dijumpai';

  @override
  String get callPhonePermNeeded => 'Kebenaran telefon diperlukan';

  @override
  String get callPhonePermBody =>
      'Call Manager memerlukan kebenaran Telefon untuk membaca sejarah panggilan anda.';

  @override
  String get callGrantPhone => 'Beri kebenaran telefon';

  @override
  String get callCouldNotLoad => 'Tidak dapat memuatkan sejarah panggilan';

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
      'Untuk menghentikan nombor yang disekat daripada berbunyi, pilih aplikasi ini untuk penapisan panggilan.';

  @override
  String get callHighRiskTitle => 'Pemanggil berisiko tinggi';

  @override
  String get callHighRiskBody =>
      'Nombor ini telah dilaporkan sebagai penipuan. Jangan kongsi butiran peribadi atau wang.';

  @override
  String callHighRiskScore(int score) {
    return 'Skor kepercayaan: $score/100';
  }

  @override
  String callHighRiskReports(int count) {
    return 'Dilaporkan $count kali';
  }

  @override
  String get callHighRiskDismiss => 'Tolak';

  @override
  String get callChecking => 'Menyemak nombor...';

  @override
  String get callCheckTitle => 'Semakan nombor';

  @override
  String get callCheckNumberLabel => 'Nombor yang disemak';

  @override
  String get callCheckResultHighRisk => 'Nombor berisiko tinggi';

  @override
  String get callCheckResultUnknown => 'Tiada rekod lagi';

  @override
  String get callCheckResultSafe => 'Nampak selamat';

  @override
  String get callCheckResultFailed => 'Semakan gagal';

  @override
  String get callCheckDetailHighRisk =>
      'Nombor ini telah dilaporkan sebagai penipuan. Jangan kongsi maklumat peribadi atau wang.';

  @override
  String get callCheckDetailUnknown =>
      'Tiada laporan untuk nombor ini. Kekal berwaspada.';

  @override
  String get callCheckDetailSafe => 'Nombor ini tiada laporan penipuan.';

  @override
  String get callCheckDetailFailed =>
      'Tidak dapat menyemak nombor ini sekarang. Sila cuba lagi.';

  @override
  String callCheckScore(int score) {
    return 'Skor kepercayaan: $score/100';
  }

  @override
  String callCheckReports(int count) {
    return 'Dilaporkan $count kali';
  }

  @override
  String get reportNotSent =>
      'Laporan tidak dihantar — titik akhir pelaporan belum dikonfigurasi';

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
      'Sahkan Call Manager untuk penyaringan panggilan';

  @override
  String get permScreeningUnavailable =>
      'Penyaringan panggilan tidak tersedia pada peranti ini';

  @override
  String get permNotificationAccess => 'Akses pemberitahuan';

  @override
  String get permNotificationAccessSub =>
      'Membaca mesej daripada pemberitahuan';

  @override
  String get permOverlay => 'Papar di atas apl lain';

  @override
  String get permOverlaySub =>
      'Menunjukkan amaran penipuan semasa panggilan berdering';

  @override
  String get permAlerts => 'Amaran dibenarkan';

  @override
  String get permAlertsSub =>
      'Menyiarkan amaran penipuan sebagai pemberitahuan';

  @override
  String get permBackground => 'Jalankan di latar belakang';

  @override
  String get permBackgroundSub =>
      'Abaikan pengoptimuman bateri supaya perlindungan terus berjalan';

  @override
  String get permBatterySettings => 'Tetapan pengoptimuman bateri';

  @override
  String get permBatterySettingsSub =>
      'Sesetengah telefon tetap mengehadkan aplikasi. Buka senarai dan tetapkan aplikasi ini kepada \"Jangan optimumkan\".';

  @override
  String get permGranted => 'Diberikan';

  @override
  String get permGrant => 'Beri';

  @override
  String get permScreeningRole => 'Peranan penyaringan panggilan';

  @override
  String get permScreeningRoleSub =>
      'Membolehkan apl menyaring panggilan masuk dan menyekat nombor yang anda tandakan sebagai spam.';

  @override
  String get permScreeningActive => 'Penyaringan aktif';

  @override
  String get permEnableScreening => 'Dayakan penyaringan panggilan';

  @override
  String get permScreeningNotGranted => 'Penyaringan panggilan belum diberikan';

  @override
  String get permScreeningTapHint =>
      'Ketik \"Dayakan penyaringan panggilan\" di atas, jika tidak panggilan masih akan berdering masuk.';

  @override
  String get permTitle => 'Kebenaran';

  @override
  String get permGrantFollowing => 'Beri kebenaran berikut untuk akses penuh.';

  @override
  String get permPhoneCallLog => 'Telefon & Log Panggilan';

  @override
  String get permPhoneGranted => 'Kebenaran telefon diberikan';

  @override
  String get permContacts => 'Kenalan';

  @override
  String get permContactsGranted => 'Kebenaran kenalan diberikan';

  @override
  String get permNotifications => 'Pemberitahuan';

  @override
  String get permNotificationsGranted => 'Kebenaran pemberitahuan diberikan';

  @override
  String get permStillNotWorking => 'Masih tidak berfungsi?';

  @override
  String get permOpenSettingsBody =>
      'Buka tetapan sistem untuk apl ini untuk menetapkan peranan penyaringan panggilan dan kebenaran secara manual.';

  @override
  String get permOpenAppSettings => 'Buka Tetapan Apl';

  @override
  String get permNotChecked => 'Belum disemak';

  @override
  String get permStatusDenied => 'Dinafikan';

  @override
  String get permPermanentlyDenied => 'Dinafikan secara kekal';

  @override
  String get permNotGranted => 'Tidak diberikan';

  @override
  String get contactsPermRequired =>
      'Kebenaran kenalan diperlukan untuk melihat kenalan';

  @override
  String get contactsTitle => 'Kenalan';

  @override
  String get contactsSearchHint => 'Cari kenalan...';

  @override
  String get contactsCouldNotLoad => 'Tidak dapat memuatkan kenalan';

  @override
  String get contactsNoneFound => 'Tiada kenalan dijumpai';

  @override
  String get contactsNoDetails => 'Tiada butiran';

  @override
  String get contactsCouldNotCall => 'Tidak dapat memulakan panggilan';

  @override
  String get safetyTitle => 'Keselamatan';

  @override
  String get safetyRecentAlerts => 'Amaran terkini';

  @override
  String get safetyProtectedOn => 'Anda dilindungi';

  @override
  String get safetyProtectedOff => 'Perlindungan dimatikan';

  @override
  String get safetyWeCheck => 'Kami menyemak mesej anda untuk penipuan.';

  @override
  String get safetyTurnOnToCheck =>
      'Hidupkan ini untuk menyemak mesej untuk penipuan.';

  @override
  String get safetyTurnOff => 'Matikan perlindungan';

  @override
  String get safetyTurnOn => 'Hidupkan perlindungan';

  @override
  String get safetyPressToStart => 'Tekan untuk mula';

  @override
  String get safetyDownloadingModel => 'Memuat turun model…';

  @override
  String get safetySettingUpModel => 'Menyediakan model…';

  @override
  String get safetyNoScams => 'Tiada penipuan dijumpai';

  @override
  String get safetyNoScamsBody => 'Mesej mencurigakan akan dipaparkan di sini.';

  @override
  String get safetyMeteredTitle => 'Guna data mudah alih?';

  @override
  String safetyMeteredBody(int mb) {
    return 'Muat turun ini kira-kira $mb MB. Wi-Fi lebih baik.';
  }

  @override
  String get safetyNotNow => 'Bukan sekarang';

  @override
  String get safetyDownload => 'Muat turun';

  @override
  String get safetyCouldNotStart =>
      'Perlindungan tidak dapat dimulakan. Sila cuba lagi.';

  @override
  String get safetyShowMore => 'Tunjuk lagi';

  @override
  String get safetyShowLess => 'Tunjuk kurang';

  @override
  String get safetyPillOn => 'Dilindungi';

  @override
  String get safetyPillOff => 'Dimatikan';

  @override
  String get safetyPillError => 'Perlukan perhatian';

  @override
  String get safetyPillChecking => 'Menyemak';

  @override
  String get safetyHeroOnBody => 'Disemak secara peribadi pada telefon anda.';

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
  String get activityNoMessages => 'Belum ada mesej ditangkap.';

  @override
  String get activityNotCheckedSuffix => ' · belum disemak';

  @override
  String get activityCloudSuffix => ' · awan';

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
    return '$wire (ditingkatkan)';
  }

  @override
  String get activityReason => 'Sebab';

  @override
  String get activityAiThinking => 'Pemikiran AI';

  @override
  String get activityNoOutput =>
      '(model tidak menghasilkan output yang boleh dibaca)';

  @override
  String get blockedNumbersTitle => 'Nombor Disekat';

  @override
  String get blockedNoNumbers => 'Tiada nombor disekat';

  @override
  String get notificationsTitle => 'Pemberitahuan';

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
  String get onboardingStart => 'Mari mula';

  @override
  String get onboardingAllow => 'Benarkan';

  @override
  String get onboardingOpenSettings => 'Buka tetapan';

  @override
  String get onboardingNotNow => 'Bukan sekarang';

  @override
  String get onboardingFinish => 'Pergi ke aplikasi';

  @override
  String onboardingStepCount(int step, int total) {
    return 'Langkah $step daripada $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Selamat datang';

  @override
  String get onboardingWelcomeBody =>
      'Aplikasi ini membantu anda mengenal pasti panggilan dan mesej penipuan. Untuk itu, ia memerlukan beberapa kebenaran daripada telefon anda. Kita akan melaluinya satu demi satu.';

  @override
  String get onboardingWelcomeNote =>
      'Semuanya kekal di telefon anda. Anda boleh menukar pilihan ini pada bila-bila masa di Tetapan.';

  @override
  String get onboardingPhoneTitle => 'Panggilan telefon';

  @override
  String get onboardingPhoneBody =>
      'Ini membolehkan aplikasi melihat siapa yang menghubungi anda, supaya ia boleh memberitahu jika nombor itu dikenali sebagai penipuan.';

  @override
  String get onboardingContactsTitle => 'Kenalan';

  @override
  String get onboardingContactsBody =>
      'Ini membolehkan aplikasi mengenali orang yang anda kenali, supaya panggilan mereka tidak ditanda sebagai mencurigakan.';

  @override
  String get onboardingScreeningTitle => 'Semakan panggilan';

  @override
  String get onboardingScreeningBody =>
      'Ini membolehkan aplikasi menyemak panggilan masuk dan menyekat nombor yang telah anda sekat. Telefon anda akan meminta anda memilih aplikasi ini untuk saringan panggilan.';

  @override
  String get onboardingNotificationsTitle => 'Makluman';

  @override
  String get onboardingNotificationsBody =>
      'Ini membolehkan aplikasi menghantar makluman ringkas apabila sesuatu kelihatan seperti penipuan.';

  @override
  String get onboardingMessagesTitle => 'Semakan mesej';

  @override
  String get onboardingMessagesBody =>
      'Ini membolehkan aplikasi membaca mesej baharu apabila ia tiba, supaya ia boleh memberi amaran tentang pautan mencurigakan atau permintaan wang.';

  @override
  String get onboardingOverlayTitle => 'Tunjukkan amaran semasa panggilan';

  @override
  String get onboardingOverlayBody =>
      'Ini membolehkan aplikasi menunjukkan notis kecil di skrin semasa panggilan mencurigakan berdering.';

  @override
  String get onboardingBackgroundTitle => 'Terus berjalan di latar belakang';

  @override
  String get onboardingBackgroundBody =>
      'Benarkan aplikasi mengabaikan pengoptimuman bateri supaya ia boleh terus mengawasi penipuan walaupun skrin anda dimatikan.';

  @override
  String get onboardingBatterySettingsTitle => 'Hentikan pengoptimuman bateri';

  @override
  String get onboardingBatterySettingsBody =>
      'Sesetengah telefon terus mengehadkan aplikasi walaupun selepas gesaan pertama. Buka tetapan bateri, cari aplikasi ini, dan tetapkannya kepada \"Jangan optimumkan\" supaya perlindungan tidak pernah berhenti.';

  @override
  String get onboardingSettingsHint =>
      'Tetapan telefon anda akan dibuka. Cari aplikasi ini dalam senarai, hidupkannya, kemudian kembali ke sini.';

  @override
  String get onboardingStatusOn => 'Ini telah dihidupkan.';

  @override
  String get onboardingStatusSkipped =>
      'Ini belum dihidupkan. Anda boleh cuba lagi, atau hidupkannya kemudian di Tetapan.';

  @override
  String get onboardingStatusBlocked =>
      'Telefon anda tidak akan bertanya lagi. Ketik \"Buka tetapan\" untuk menghidupkannya sendiri.';

  @override
  String get onboardingDoneTitle => 'Semuanya sedia';

  @override
  String get onboardingDoneBody =>
      'Aplikasi kini memerhati panggilan dan mesej penipuan untuk anda.';

  @override
  String get onboardingDonePartialTitle => 'Hampir selesai';

  @override
  String get onboardingDonePartialBody =>
      'Sesetengah perlindungan belum dihidupkan. Aplikasi masih berfungsi, dan anda boleh menghidupkan selebihnya kemudian di Tetapan.';

  @override
  String onboardingGrantedCount(int granted, int total) {
    return '$granted daripada $total dihidupkan';
  }

  @override
  String get onboardingWhy => 'Mengapa?';

  @override
  String get onboardingScreeningWhy =>
      'Telefon anda akan meminta anda memilih apl ini. Pilihnya supaya panggilan dapat disemak.';

  @override
  String get onboardingMessagesWhy =>
      'Kami mencari tanda penipuan, seperti pautan pelik atau permintaan wang.';

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
  String get onboardingModelReady => 'Sedia digunakan.';

  @override
  String get onboardingModelFailed =>
      'Muat turun tidak selesai. Cuba lagi, atau kemudian di Tetapan.';

  @override
  String get onboardingModelMeteredTitle => 'Guna data mudah alih?';

  @override
  String onboardingModelMeteredBody(String size) {
    return 'Anda tidak menggunakan Wi-Fi. Ini menggunakan kira-kira $size data.';
  }

  @override
  String get setupOpenSettingsFailed => 'Tidak dapat membuka tetapan.';

  @override
  String get authEnterEmail => 'Sila masukkan e-mel anda.';

  @override
  String get authValidEmail => 'Sila masukkan e-mel yang sah.';

  @override
  String get authEnterPassword => 'Sila masukkan kata laluan anda.';

  @override
  String get authPasswordLength => 'Gunakan sekurang-kurangnya 8 aksara.';

  @override
  String get authEnterName => 'Sila masukkan nama anda.';

  @override
  String get authNameInvalid =>
      'Gunakan huruf dan nombor sahaja, dengan paling banyak satu ruang antara dua perkataan.';

  @override
  String get authCreateAccount => 'Cipta akaun';

  @override
  String get authSignIn => 'Log masuk';

  @override
  String get authRegisterIntro =>
      'Sertai komuniti untuk berkongsi dan belajar tentang penipuan.';

  @override
  String get authLoginIntro =>
      'Log masuk untuk menyiarkan dan menyertai perbincangan.';

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
  String get authToggleToLogin => 'Sudah ada akaun? Log masuk';

  @override
  String get authToggleToRegister => 'Baru di sini? Cipta akaun';

  @override
  String get authGateTitle => 'Log masuk untuk meneruskan';

  @override
  String get authGateBody =>
      'Ciri ini memerlukan akaun. Log masuk untuk menyiarkan ke komuniti, menyelaraskan laporan anda, dan menyimpan semuanya di satu tempat.';

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
      'Laporan penipuan yang dikongsi oleh komuniti akan dipaparkan di sini.';

  @override
  String get createChooseType => 'Sila pilih jenis penipuan.';

  @override
  String get createAddTitle => 'Sila tambah tajuk.';

  @override
  String get createAddMessage => 'Sila tambah teks mesej.';

  @override
  String get reportTabTitle => 'Lapor';

  @override
  String get reportTabThankYou => 'Dikongsi dengan komuniti. Terima kasih!';

  @override
  String get reportTabTrackIt =>
      'Dikongsi dengan komuniti. Semak Siaran saya untuk menjejakinya.';

  @override
  String get reportTabHeroTitle => 'Ingatkan orang lain tentang penipuan';

  @override
  String get reportTabNumberHeroTitle => 'Laporkan nombor telefon';

  @override
  String get reportTabNumberHeroBody =>
      'Beritahu kami mengapa nombor ini mencurigakan. Laporan anda membantu melindungi orang lain.';

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
  String get reportTabNumberRequired => 'Sila masukkan nombor telefon.';

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
  String get reportTabSuccessTitle => 'Terima kasih kerana membantu';

  @override
  String get reportTabReportAnother => 'Laporkan satu lagi';

  @override
  String get reportTabDone => 'Selesai';

  @override
  String get myPostsTitle => 'Siaran saya';

  @override
  String get myPostsNoneBody =>
      'Penipuan yang anda laporkan akan dipaparkan di sini supaya anda boleh menjejakinya.';

  @override
  String get myPostsDelete => 'Padam';

  @override
  String get myPostsDeleteConfirm => 'Padam siaran ini?';

  @override
  String get myPostsDeleteConfirmBody =>
      'Ini mengeluarkannya daripada komuniti. Tindakan ini tidak boleh dibatalkan.';

  @override
  String get myPostsEdit => 'Edit';

  @override
  String get editPostTitle => 'Edit siaran';

  @override
  String get editPostSave => 'Simpan perubahan';

  @override
  String get editPostSaving => 'Menyimpan...';

  @override
  String get editPostSaved => 'Perubahan disimpan.';

  @override
  String get editPostReReview =>
      'Mengedit mesej menghantar semula siaran untuk semakan.';

  @override
  String get postDetailThankYou =>
      'Terima kasih. Pasukan kami akan menyemak siaran ini.';

  @override
  String get postDetailTitle => 'Siaran';

  @override
  String get postDetailReportTooltip => 'Lapor siaran ini';

  @override
  String postDetailComments(int count) {
    return 'Komen ($count)';
  }

  @override
  String get postDetailNoComments => 'Belum ada komen.';

  @override
  String get postDetailWriteComment => 'Tulis komen';

  @override
  String get postDetailPostComment => 'Siarkan komen';

  @override
  String get postDetailFlagPersonalInfo => 'Menunjukkan maklumat peribadi';

  @override
  String get postDetailFlagHarmful => 'Berbahaya atau merbahaya';

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
  String get guidanceClickedLink => 'Saya klik pautan';

  @override
  String get guidanceGotMessage => 'Saya baru terima mesej';

  @override
  String get guidanceSharedPassword => 'Saya kongsi kata laluan saya';

  @override
  String get guidanceSentMoney => 'Saya hantar wang';

  @override
  String get guidanceCouldNotOpenLink => 'Tidak dapat membuka pautan.';

  @override
  String get guidanceCouldNotCall => 'Tidak dapat memulakan panggilan.';

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
      'Pilih apa yang berlaku di atas untuk melihat langkah yang boleh anda ambil.';

  @override
  String get tourHomeTitle => 'Utama';

  @override
  String get tourHomeBody =>
      'Ini ialah skrin utama anda. Lihat amaran penipuan terkini dan capai dengan pantas segala yang aplikasi ini boleh lakukan.';

  @override
  String get tourCallsTitle => 'Panggilan';

  @override
  String get tourCallsBody =>
      'Di sinilah panggilan daripada nombor tidak diketahui muncul. Ketik panggilan untuk melihat butiran, dan gunakan ikon sekat di penjuru atas untuk mengurus nombor yang anda tidak mahu dengar lagi.';

  @override
  String get tourBlockedTitle => 'Nombor disekat anda';

  @override
  String get tourBlockedBody =>
      'Ketik perisai dengan garis melintang untuk melihat nombor yang anda sekat.';

  @override
  String get tourHelpTitle => 'Perlukan bantuan?';

  @override
  String get tourHelpBody =>
      'Ketik ? pada mana-mana skrin untuk melihat maksudnya.';

  @override
  String get tourSafetyTitle => 'Keselamatan';

  @override
  String get tourSafetyBody =>
      'Hidupkan perlindungan di sini. Setelah model dimuat turun, Scam Shield membaca mesej masuk pada peranti anda dan memberi amaran tentang kemungkinan penipuan.';

  @override
  String get tourReportTitle => 'Lapor';

  @override
  String get tourReportBody =>
      'Nampak penipuan? Kongsikannya dengan komuniti dari tab ini supaya orang lain dapat mengenali helah yang sama dan kekal selamat.';

  @override
  String get tourProfileTitle => 'Profil Anda';

  @override
  String get tourProfileBody =>
      'Lihat butiran akaun anda dan semua kiriman anda di satu tempat. Buka tetapan atau log keluar daripada butang di bahagian atas.';

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
  String get helpShowTour => 'Tunjuk semula gambaran keseluruhan apl';

  @override
  String get helpCallsTitle => 'Maksud setiap perkara';

  @override
  String get helpCallsHighRiskTitle => 'Panggilan merah = kemungkinan penipuan';

  @override
  String get helpCallsHighRiskBody => 'Jangan jawab atau hubungi semula.';

  @override
  String get helpCallsNormalTitle => 'Panggilan biasa';

  @override
  String get helpCallsNormalBody => 'Tiada laporan penipuan untuk nombor ini.';

  @override
  String get helpCallsBlockedRowTitle => 'Panggilan disekat';

  @override
  String get helpCallsBlockedRowBody =>
      'Anda menyekat nombor ini. Ia tidak boleh menghubungi anda.';

  @override
  String get helpCallsBlockedListTitle => 'Nombor disekat anda';

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
  String get helpCallsRefreshBody => 'Semak semula panggilan anda.';

  @override
  String get helpCallsMissedBody => 'Anda tidak menjawab panggilan ini.';

  @override
  String get helpCallsAnsweredBody => 'Anda menjawab panggilan ini.';

  @override
  String get helpCallsRejectedBody => 'Anda menolak panggilan ini.';

  @override
  String get helpCallsBlockedIconBody => 'Panggilan ini telah dihentikan.';

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
  String get callsLoadFailedBody => 'Sila cuba lagi.';

  @override
  String get callsBlockedEmptyBody =>
      'Nombor yang anda sekat akan dipaparkan di sini.';

  @override
  String get callsContactsLoadFailed =>
      'Tidak dapat memaparkan kenalan anda. Sila cuba lagi.';

  @override
  String get callsCallTooltip => 'Panggil';
}
