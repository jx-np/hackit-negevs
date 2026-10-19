// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get commonReport => 'புகாரளி';

  @override
  String get commonCancel => 'ரத்து';

  @override
  String get commonRetry => 'மீண்டும் முயற்சி';

  @override
  String get commonRefresh => 'புதுப்பி';

  @override
  String get commonReviewed => 'பரிசீலிக்கப்பட்டது';

  @override
  String get commonClear => 'அழி';

  @override
  String get commonUnknown => 'தெரியாதது';

  @override
  String get commonReportThis => 'இதைப் புகாரளி';

  @override
  String get commonNoPostsYet => 'இன்னும் இடுகைகள் இல்லை';

  @override
  String get commonShareWithCommunity => 'சமூகத்துடன் பகிர்';

  @override
  String get commonShare => 'பகிர்';

  @override
  String get commonSharing => 'பகிரப்படுகிறது...';

  @override
  String get commonTitle => 'தலைப்பு';

  @override
  String get commonTitleHint => 'ஒரு சுருக்கமான சுருக்கம்';

  @override
  String get commonMessage => 'செய்தி';

  @override
  String get commonMessageHint => 'மோசடி செய்தியை இங்கே ஒட்டவும்';

  @override
  String get commonWhatKindOfScam => 'எந்த வகையான மோசடி?';

  @override
  String get commonShareIntro =>
      'நீங்கள் பெற்ற மோசடியைப் பகிர்ந்து மற்றவர்களுக்கு உதவுங்கள். முதலில் தனிப்பட்ட விவரங்களை நீக்கவும்.';

  @override
  String get commonPhotos => 'புகைப்படங்கள் (விருப்பத்திற்குரியது)';

  @override
  String get commonAddPhoto => 'புகைப்படத்தைச் சேர்';

  @override
  String get commonRemovePhoto => 'புகைப்படத்தை அகற்று';

  @override
  String get commonImageTooLarge =>
      'ஒவ்வொரு படமும் 10 MB அல்லது அதற்குக் குறைவாக இருக்க வேண்டும்.';

  @override
  String get reportTabPhotoProcessing => 'பகுப்பாய்வு செய்கிறது...';

  @override
  String get reportTabPhotoFailed => 'பகுப்பாய்வு செய்ய முடியவில்லை';

  @override
  String get reportTabProcessingTitle =>
      'செயலியை மூட வேண்டாம். செயலாக்கப்படுகிறது';

  @override
  String get reportTabSignInToAddPhotos => 'படங்களை இணைக்க உள்நுழையவும்.';

  @override
  String get reportTabFailedDialogTitle =>
      'சில படங்களைப் பகுப்பாய்வு செய்ய முடியவில்லை';

  @override
  String reportTabFailedDialogBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count படங்களைப் பதிவேற்ற அல்லது பகுப்பாய்வு செய்ய முடியவில்லை. மீண்டும் முயற்சிக்கவா, அல்லது அவை இல்லாமல் இடுகையிடவா?',
      one:
          '1 படத்தைப் பதிவேற்ற அல்லது பகுப்பாய்வு செய்ய முடியவில்லை. மீண்டும் முயற்சிக்கவா, அல்லது அது இல்லாமல் இடுகையிடவா?',
    );
    return '$_temp0';
  }

  @override
  String get reportTabFailedRetry => 'மீண்டும் முயற்சி';

  @override
  String get reportTabFailedPostWithout => 'படங்கள் இல்லாமல் இடுகையிடு';

  @override
  String get reportTabWaitForImages =>
      'படங்கள் செயலாக்கப்படும் வரை காத்திருக்கவும்';

  @override
  String get reportTabCheckImages => 'படங்களைச் சரிபார்';

  @override
  String get reportTabReviewCheckbox =>
      'படங்களை மதிப்பாய்வு செய்தேன், தனிப்பட்ட விவரங்கள் சரியாக மறைக்கப்பட்டுள்ளன';

  @override
  String get reportTabEditImage => 'படத்தைத் திருத்து';

  @override
  String get reportTabReuploading =>
      'திருத்தப்பட்ட படம் மீண்டும் பதிவேற்றப்படுகிறது...';

  @override
  String get reportTabPosting => 'இடுகையிடப்படுகிறது...';

  @override
  String get reportTabEditorSaveFailed =>
      'திருத்தப்பட்ட படத்தை மீண்டும் பதிவேற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get reportTabEditorLoadFailed =>
      'Couldn\'t load the image to edit. Try again.';

  @override
  String get reportTabViewPost => 'உங்கள் இடுகையைப் பார்';

  @override
  String get homeTitle => 'முகப்பு';

  @override
  String get homeWelcomePrefix => 'வரவேற்கிறோம், ';

  @override
  String get homeWelcomeGuest => 'Welcome';

  @override
  String get myProfileTitle => 'எனது சுயவிவரம்';

  @override
  String get myProfileMemberSince => 'இணைந்த நாள்';

  @override
  String get myProfilePosts => 'பதிவுகள்';

  @override
  String get myProfileSignOut => 'வெளியேறு';

  @override
  String get myProfileSignOutHint =>
      'நீங்கள் எப்போது வேண்டுமானாலும் மீண்டும் உள்நுழையலாம்';

  @override
  String get myProfileNotSignedInTitle => 'நீங்கள் உள்நுழையவில்லை';

  @override
  String get myProfileNotSignedInBody =>
      'உங்கள் கணக்கு விவரங்களைக் காணவும், சுயவிவரத்தை நிர்வகிக்கவும் உள்நுழையவும்.';

  @override
  String get myProfileSignIn => 'உள்நுழை';

  @override
  String get homeNewsTitle => 'மோசடி எச்சரிக்கைகள் & செய்திகள்';

  @override
  String get homeNewsError => 'சமீபத்திய எச்சரிக்கைகளை ஏற்ற முடியவில்லை.';

  @override
  String get homeNewsRetry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get homeQuickActionsTitle => 'நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்?';

  @override
  String get homeActionProfile => 'எனது சுயவிவரம்';

  @override
  String get homeActionProfileBody =>
      'உங்கள் விவரங்களையும் பதிவுகளையும் பார்க்கவும்';

  @override
  String get homeActionCalls => 'சமீபத்திய அழைப்புகள்';

  @override
  String get homeActionCallsBody =>
      'அறியப்படாத எண்களிலிருந்து வரும் அழைப்புகளைச் சரிபார்க்கவும்';

  @override
  String get homeActionReport => 'மோசடியைப் புகாரளிக்கவும்';

  @override
  String get homeActionReportBody =>
      'சமூகத்தில் உள்ள மற்றவர்களுக்கு எச்சரிக்கவும்';

  @override
  String get homeStatusOnBody =>
      'உங்கள் செய்திகளில் மோசடி இருக்கிறதா என்று நாங்கள் சரிபார்க்கிறோம்.';

  @override
  String get homeStatusOffBody =>
      'மோசடி செய்திகள் பற்றி உங்களுக்கு எச்சரிக்க அதை இயக்கவும்.';

  @override
  String get homeStatusProblemTitle => 'பாதுகாப்புக்கு உங்கள் கவனம் தேவை';

  @override
  String get homeStatusProblemBody =>
      'ஏதோ தவறு நடந்தது. சரிசெய்ய கீழே தட்டவும்.';

  @override
  String get homeStatusStartingTitle => 'தயாராகிறது';

  @override
  String get homeStatusStartingBody =>
      'பாதுகாப்பு தொடங்குகிறது. இதற்கு ஒரு நிமிடம் ஆகலாம்.';

  @override
  String get homeStatusOpen => 'விவரங்களைப் பார்க்கவும்';

  @override
  String get homeStatusFix => 'இப்போது சரிசெய்யவும்';

  @override
  String get homeNewsReadMore => 'மேலும் படிக்கவும்';

  @override
  String get homeNewsClose => 'மூடவும்';

  @override
  String homeNewsCount(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get homeNewsPrevious => 'முந்தைய எச்சரிக்கை';

  @override
  String get homeNewsNext => 'அடுத்த எச்சரிக்கை';

  @override
  String get settingsProtection => 'பாதுகாப்பு';

  @override
  String get settingsStopProtection => 'பின்னணி பாதுகாப்பை நிறுத்து';

  @override
  String get settingsServiceRunning => 'சேவை இயங்குகிறது';

  @override
  String get settingsServiceStopped => 'சேவை நிறுத்தப்பட்டது';

  @override
  String get settingsShowTutorial => 'பயிற்சியை மீண்டும் காட்டு';

  @override
  String get settingsReplayTour => 'செயலி அம்ச மேலோட்டத்தை மீண்டும் இயக்கு';

  @override
  String get settingsRemove => 'அகற்று';

  @override
  String settingsPercent(int pct) {
    return '$pct%';
  }

  @override
  String get settingsDownload => 'பதிவிறக்கு';

  @override
  String get settingsLanguage => 'மொழி';

  @override
  String get settingsLanguageSystem => 'கணினி இயல்புநிலை';

  @override
  String get settingsStatusTitle => 'நிலை';

  @override
  String get settingsGettingReady => 'தயாராகிறது…';

  @override
  String get settingsNeedsDownload => 'பாதுகாப்பிற்கு ஒரு பதிவிறக்கம் தேவை';

  @override
  String settingsModelReady(String name) {
    return '$name தயார்';
  }

  @override
  String settingsModelNotDownloaded(String name) {
    return '$name இன்னும் பதிவிறக்கப்படவில்லை';
  }

  @override
  String settingsSettingUpPct(int pct) {
    return 'அமைக்கிறது… $pct%';
  }

  @override
  String settingsSettingUpMb(int mb) {
    return 'அமைக்கிறது… $mb MB';
  }

  @override
  String get settingsCheckerTitle => 'மோசடி சரிபார்ப்பான்';

  @override
  String get settingsCheckerCaption =>
      'உங்கள் தொலைபேசியிலேயே செய்திகளைச் சரிபார்க்கிறது. எதுவும் வெளியே அனுப்பப்படாது.';

  @override
  String get settingsCheckingSupport => 'உங்கள் தொலைபேசி சரிபார்க்கப்படுகிறது…';

  @override
  String get settingsNotAvailable => 'இந்த தொலைபேசியில் கிடைக்கவில்லை';

  @override
  String get settingsReadyShort => 'தயார்';

  @override
  String get settingsBuiltInSubtitle =>
      'உங்கள் தொலைபேசியில் உள்ளமைந்தது. பதிவிறக்கம் தேவையில்லை.';

  @override
  String settingsAboutMb(int mb) {
    return 'சுமார் $mb MB';
  }

  @override
  String get settingsPrepare => 'அமை';

  @override
  String get settingsSpeedTitle => 'வேகம்';

  @override
  String get settingsSpeedCaption =>
      'சரிபார்ப்பானில் சிக்கல் இல்லாத வரை இதை தானியங்கியில் விடவும்.';

  @override
  String get settingsSpeedAuto => 'தானியங்கி';

  @override
  String get settingsSpeedAutoBody => 'பெரும்பாலான தொலைபேசிகளுக்கு சிறந்தது';

  @override
  String get settingsSpeedCpu => 'அதிக இணக்கத்தன்மை';

  @override
  String get settingsSpeedCpuBody =>
      'எல்லா தொலைபேசிகளிலும் வேலை செய்யும். மிக மெதுவானது.';

  @override
  String get settingsSpeedGpu => 'வேகமானது';

  @override
  String get settingsSpeedGpuBody =>
      'உங்கள் தொலைபேசியின் கிராபிக்ஸ் சிப்பைப் பயன்படுத்துகிறது';

  @override
  String get settingsSpeedNpu => 'மிக வேகமானது';

  @override
  String get settingsSpeedNpuBody => 'சில புதிய தொலைபேசிகளில் மட்டும்';

  @override
  String get settingsAppSection => 'செயலி';

  @override
  String get settingsAppearance => 'தோற்றம்';

  @override
  String get settingsThemeLight => 'ஒளி';

  @override
  String get settingsThemeDark => 'இருள்';

  @override
  String get settingsPermissionsSubtitle =>
      'செயலி என்ன செய்ய அனுமதிக்கப்படுகிறது என்பதைப் பார்க்கவும்';

  @override
  String get settingsSignInSubtitle => 'சமூகத்தில் இடுகையிட தேவை';

  @override
  String callIncoming(String who) {
    return 'உள்வரும் அழைப்பு: $who';
  }

  @override
  String callBlocked(String number) {
    return '$number தடுக்கப்பட்டது';
  }

  @override
  String callUnblocked(String number) {
    return '$number தடை நீக்கப்பட்டது';
  }

  @override
  String callReported(String number) {
    return '$number புகாரளிக்கப்பட்டது';
  }

  @override
  String get callOutgoing => 'வெளிச்செல்லும்';

  @override
  String get callAnswered => 'பதிலளிக்கப்பட்டது';

  @override
  String get callRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get callMissed => 'தவறவிட்டது';

  @override
  String get callBlockedLabel => 'தடுக்கப்பட்டது';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navCalls => 'அழைப்புகள்';

  @override
  String get navSafety => 'பாதுகாப்பு';

  @override
  String get navReport => 'புகாரளி';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String get callHistoryTitle => 'அழைப்பு வரலாறு';

  @override
  String get callBlockedNumbers => 'தடுக்கப்பட்ட எண்கள்';

  @override
  String get callNoUnknown => 'தெரியாத எண் அழைப்புகள் எதுவும் இல்லை';

  @override
  String get callPhonePermNeeded => 'தொலைபேசி அனுமதி தேவை';

  @override
  String get callPhonePermBody =>
      'உங்கள் அழைப்பு வரலாற்றைப் படிக்க Call Manager க்கு தொலைபேசி அனுமதி தேவை.';

  @override
  String get callGrantPhone => 'தொலைபேசி அனுமதி வழங்கு';

  @override
  String get callCouldNotLoad => 'அழைப்பு வரலாற்றை ஏற்ற முடியவில்லை';

  @override
  String callDurationSuffix(int seconds) {
    return ' • $secondsவி';
  }

  @override
  String get callReportedSuffix => ' • புகாரளிக்கப்பட்டது';

  @override
  String get callUnblock => 'தடை நீக்கு';

  @override
  String get callBlockNeedsScreening =>
      'தடுக்கப்பட்ட எண்கள் ஒலிக்காமல் இருக்க, அழைப்பு வடிகட்டலுக்கு இந்த ஆப்ஸைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get callHighRiskTitle => 'அதிக ஆபத்துள்ள அழைப்பாளர்';

  @override
  String get callHighRiskBody =>
      'இந்த எண் மோசடி என்று புகாரளிக்கப்பட்டுள்ளது. தனிப்பட்ட விவரங்களையோ பணத்தையோ பகிர வேண்டாம்.';

  @override
  String callHighRiskScore(int score) {
    return 'நம்பக மதிப்பெண்: $score/100';
  }

  @override
  String callHighRiskReports(int count) {
    return '$count முறை புகாரளிக்கப்பட்டது';
  }

  @override
  String get callHighRiskDismiss => 'நிராகரி';

  @override
  String get callChecking => 'எண் சரிபார்க்கப்படுகிறது...';

  @override
  String get callCheckTitle => 'எண் சரிபார்ப்பு';

  @override
  String get callCheckNumberLabel => 'சரிபார்க்கப்படும் எண்';

  @override
  String get callCheckResultHighRisk => 'அதிக ஆபத்துள்ள எண்';

  @override
  String get callCheckResultUnknown => 'இதுவரை பதிவு இல்லை';

  @override
  String get callCheckResultSafe => 'பாதுகாப்பாகத் தெரிகிறது';

  @override
  String get callCheckResultFailed => 'சரிபார்ப்பு தோல்வி';

  @override
  String get callCheckDetailHighRisk =>
      'இந்த எண் மோசடி என்று புகாரளிக்கப்பட்டுள்ளது. தனிப்பட்ட தகவல் அல்லது பணத்தைப் பகிர வேண்டாம்.';

  @override
  String get callCheckDetailUnknown =>
      'இந்த எண்ணுக்கு புகார்கள் இல்லை. எச்சரிக்கையாக இருங்கள்.';

  @override
  String get callCheckDetailSafe => 'இந்த எண்ணுக்கு மோசடி புகார்கள் இல்லை.';

  @override
  String get callCheckDetailFailed =>
      'இப்போது இந்த எண்ணைச் சரிபார்க்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String callCheckScore(int score) {
    return 'நம்பிக்கை மதிப்பெண்: $score/100';
  }

  @override
  String callCheckReports(int count) {
    return '$count முறை புகாரளிக்கப்பட்டது';
  }

  @override
  String get reportNotSent =>
      'புகார் அனுப்பப்படவில்லை — புகார் இறுதிப்புள்ளி இன்னும் கட்டமைக்கப்படவில்லை';

  @override
  String get reportSpam => 'ஸ்பேம்';

  @override
  String get reportScam => 'மோசடி';

  @override
  String get reportOther => 'மற்றவை';

  @override
  String get reportReason => 'காரணம்';

  @override
  String get shieldCheck => 'சரிபார்';

  @override
  String get permDenied => 'அனுமதி மறுக்கப்பட்டது';

  @override
  String get permConfirmScreening =>
      'அழைப்பு திரையிடலுக்கு Call Manager ஐ உறுதிப்படுத்தவும்';

  @override
  String get permScreeningUnavailable =>
      'இந்த சாதனத்தில் அழைப்பு திரையிடல் கிடைக்கவில்லை';

  @override
  String get permNotificationAccess => 'அறிவிப்பு அணுகல்';

  @override
  String get permNotificationAccessSub =>
      'அறிவிப்புகளிலிருந்து செய்திகளைப் படிக்கிறது';

  @override
  String get permOverlay => 'பிற செயலிகளுக்கு மேல் காட்டு';

  @override
  String get permOverlaySub =>
      'அழைப்பு ஒலிக்கும்போது மோசடி எச்சரிக்கையைக் காட்டுகிறது';

  @override
  String get permAlerts => 'எச்சரிக்கைகள் அனுமதிக்கப்பட்டன';

  @override
  String get permAlertsSub => 'மோசடி எச்சரிக்கைகளை அறிவிப்புகளாக இடுகிறது';

  @override
  String get permBackground => 'பின்னணியில் இயக்கு';

  @override
  String get permBackgroundSub =>
      'பாதுகாப்பு தொடர்ந்து இயங்க பேட்டரி மேம்படுத்தலைப் புறக்கணி';

  @override
  String get permBatterySettings => 'பேட்டரி மேம்படுத்தல் அமைப்புகள்';

  @override
  String get permBatterySettingsSub =>
      'சில தொலைபேசிகள் இன்னும் செயலிகளைக் கட்டுப்படுத்துகின்றன. பட்டியலைத் திறந்து இந்த செயலியை \"மேம்படுத்த வேண்டாம்\" என அமைக்கவும்.';

  @override
  String get permGranted => 'வழங்கப்பட்டது';

  @override
  String get permGrant => 'வழங்கு';

  @override
  String get permScreeningRole => 'அழைப்பு திரையிடல் பங்கு';

  @override
  String get permScreeningRoleSub =>
      'உள்வரும் அழைப்புகளைத் திரையிட்டு, ஸ்பேம் என நீங்கள் குறிக்கும் எண்களைத் தடுக்க செயலியை அனுமதிக்கிறது.';

  @override
  String get permScreeningActive => 'திரையிடல் செயலில் உள்ளது';

  @override
  String get permEnableScreening => 'அழைப்பு திரையிடலை இயக்கு';

  @override
  String get permScreeningNotGranted =>
      'அழைப்பு திரையிடல் இன்னும் வழங்கப்படவில்லை';

  @override
  String get permScreeningTapHint =>
      'மேலே உள்ள \"அழைப்பு திரையிடலை இயக்கு\" என்பதைத் தட்டவும், இல்லையெனில் அழைப்புகள் தொடர்ந்து ஒலிக்கும்.';

  @override
  String get permTitle => 'அனுமதிகள்';

  @override
  String get permGrantFollowing =>
      'முழு அணுகலுக்கு பின்வரும் அனுமதிகளை வழங்கவும்.';

  @override
  String get permPhoneCallLog => 'தொலைபேசி & அழைப்பு பதிவு';

  @override
  String get permPhoneGranted => 'தொலைபேசி அனுமதி வழங்கப்பட்டது';

  @override
  String get permContacts => 'தொடர்புகள்';

  @override
  String get permContactsGranted => 'தொடர்பு அனுமதி வழங்கப்பட்டது';

  @override
  String get permNotifications => 'அறிவிப்புகள்';

  @override
  String get permNotificationsGranted => 'அறிவிப்பு அனுமதி வழங்கப்பட்டது';

  @override
  String get permStillNotWorking => 'இன்னும் வேலை செய்யவில்லையா?';

  @override
  String get permOpenSettingsBody =>
      'அழைப்பு திரையிடல் பங்கு மற்றும் அனுமதிகளை கைமுறையாக ஒதுக்க இந்த செயலிக்கான கணினி அமைப்புகளைத் திறக்கவும்.';

  @override
  String get permOpenAppSettings => 'செயலி அமைப்புகளைத் திற';

  @override
  String get permNotChecked => 'சரிபார்க்கப்படவில்லை';

  @override
  String get permStatusDenied => 'மறுக்கப்பட்டது';

  @override
  String get permPermanentlyDenied => 'நிரந்தரமாக மறுக்கப்பட்டது';

  @override
  String get permNotGranted => 'வழங்கப்படவில்லை';

  @override
  String get contactsPermRequired => 'தொடர்புகளைப் பார்க்க தொடர்பு அனுமதி தேவை';

  @override
  String get contactsTitle => 'தொடர்புகள்';

  @override
  String get contactsSearchHint => 'தொடர்புகளைத் தேடு...';

  @override
  String get contactsCouldNotLoad => 'தொடர்புகளை ஏற்ற முடியவில்லை';

  @override
  String get contactsNoneFound => 'தொடர்புகள் எதுவும் இல்லை';

  @override
  String get contactsNoDetails => 'விவரங்கள் இல்லை';

  @override
  String get contactsCouldNotCall => 'அழைப்பைத் தொடங்க முடியவில்லை';

  @override
  String get safetyTitle => 'பாதுகாப்பு';

  @override
  String get safetyRecentAlerts => 'சமீபத்திய எச்சரிக்கைகள்';

  @override
  String get safetyProtectedOn => 'நீங்கள் பாதுகாக்கப்படுகிறீர்கள்';

  @override
  String get safetyProtectedOff => 'பாதுகாப்பு அணைக்கப்பட்டுள்ளது';

  @override
  String get safetyWeCheck =>
      'உங்கள் செய்திகளில் மோசடிகளை நாங்கள் சரிபார்க்கிறோம்.';

  @override
  String get safetyTurnOnToCheck =>
      'செய்திகளில் மோசடிகளைச் சரிபார்க்க இதை இயக்கவும்.';

  @override
  String get safetyTurnOff => 'பாதுகாப்பை அணை';

  @override
  String get safetyTurnOn => 'பாதுகாப்பை இயக்கு';

  @override
  String get safetyPressToStart => 'தொடங்க அழுத்தவும்';

  @override
  String get safetyDownloadingModel => 'மாதிரியைப் பதிவிறக்குகிறது…';

  @override
  String get safetySettingUpModel => 'மாதிரியை அமைக்கிறது…';

  @override
  String get safetyNoScams => 'மோசடிகள் எதுவும் இல்லை';

  @override
  String get safetyNoScamsBody => 'சந்தேகத்திற்குரிய செய்திகள் இங்கே தோன்றும்.';

  @override
  String get safetyMeteredTitle => 'மொபைல் தரவைப் பயன்படுத்தவா?';

  @override
  String safetyMeteredBody(int mb) {
    return 'இந்த பதிவிறக்கம் சுமார் $mb MB. Wi-Fi சிறந்தது.';
  }

  @override
  String get safetyNotNow => 'இப்போது வேண்டாம்';

  @override
  String get safetyDownload => 'பதிவிறக்கு';

  @override
  String get safetyCouldNotStart =>
      'பாதுகாப்பைத் தொடங்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get safetyShowMore => 'மேலும் காட்டு';

  @override
  String get safetyShowLess => 'குறைவாகக் காட்டு';

  @override
  String get safetyPillOn => 'பாதுகாக்கப்படுகிறது';

  @override
  String get safetyPillOff => 'அணைக்கப்பட்டது';

  @override
  String get safetyPillError => 'கவனம் தேவை';

  @override
  String get safetyPillChecking => 'சரிபார்க்கிறது';

  @override
  String get safetyHeroOnBody =>
      'உங்கள் தொலைபேசியில் தனிப்பட்ட முறையில் சரிபார்க்கப்படுகிறது.';

  @override
  String get protectionChecked => 'சரிபார்க்கப்பட்டது';

  @override
  String get protectionAlerts => 'எச்சரிக்கைகள்';

  @override
  String get protectionOn => 'பாதுகாப்பு இயக்கத்தில் உள்ளது';

  @override
  String get protectionOff => 'பாதுகாப்பு அணைக்கப்பட்டுள்ளது';

  @override
  String activityAll(int count) {
    return 'அனைத்தும் ($count)';
  }

  @override
  String activityScams(int count) {
    return 'மோசடிகள் ($count)';
  }

  @override
  String activityUnchecked(int count) {
    return 'சரிபார்க்கப்படாதவை ($count)';
  }

  @override
  String get activityNoMessages =>
      'இன்னும் செய்திகள் எதுவும் பிடிக்கப்படவில்லை.';

  @override
  String get activityNotCheckedSuffix => ' · சரிபார்க்கப்படவில்லை';

  @override
  String get activityCloudSuffix => ' · கிளவுட்';

  @override
  String get activityNotCheckedYet => 'இன்னும் சரிபார்க்கப்படவில்லை.';

  @override
  String get activityVerdict => 'தீர்ப்பு';

  @override
  String get activityConfidence => 'நம்பிக்கை';

  @override
  String get activityCheckedBy => 'சரிபார்த்தவர்';

  @override
  String activityEscalatedSuffix(String wire) {
    return '$wire (அதிகரிக்கப்பட்டது)';
  }

  @override
  String get activityReason => 'காரணம்';

  @override
  String get activityAiThinking => 'AI சிந்தனை';

  @override
  String get activityNoOutput =>
      '(மாதிரி படிக்கக்கூடிய வெளியீட்டை உருவாக்கவில்லை)';

  @override
  String get blockedNumbersTitle => 'தடுக்கப்பட்ட எண்கள்';

  @override
  String get blockedNoNumbers => 'தடுக்கப்பட்ட எண்கள் இல்லை';

  @override
  String get notificationsTitle => 'அறிவிப்புகள்';

  @override
  String get notificationsTestTitle => 'ஒரு செய்தியைச் சோதி';

  @override
  String get notificationsTestHint =>
      'ஒரு செய்தியை ஒட்டவும் அல்லது தட்டச்சு செய்யவும்';

  @override
  String get notificationsTestRun => 'செய்தியைச் சரிபார்';

  @override
  String get notificationsTestServiceOff => 'முதலில் பாதுகாப்பை இயக்கவும்.';

  @override
  String get notificationsTestSent => 'சரிபார்க்கிறது. முடிவு கீழே தோன்றும்.';

  @override
  String get settingsScreenTitle => 'அமைப்புகள்';

  @override
  String get settingsScreenPermissionsTab => 'அனுமதிகள்';

  @override
  String get onboardingContinue => 'தொடர்';

  @override
  String get onboardingBack => 'பின்செல்';

  @override
  String get onboardingStart => 'தொடங்குவோம்';

  @override
  String get onboardingAllow => 'அனுமதி';

  @override
  String get onboardingOpenSettings => 'அமைப்புகளைத் திற';

  @override
  String get onboardingNotNow => 'இப்போது வேண்டாம்';

  @override
  String get onboardingFinish => 'செயலிக்குச் செல்';

  @override
  String onboardingStepCount(int step, int total) {
    return 'படி $step / $total';
  }

  @override
  String get onboardingWelcomeTitle => 'வரவேற்கிறோம்';

  @override
  String get onboardingWelcomeBody =>
      'மோசடி அழைப்புகள் மற்றும் செய்திகளைக் கண்டறிய இந்த செயலி உதவுகிறது. இதற்கு உங்கள் தொலைபேசியிலிருந்து சில அனுமதிகள் தேவை. அவற்றை ஒவ்வொன்றாகப் பார்ப்போம்.';

  @override
  String get onboardingWelcomeNote =>
      'எல்லாம் உங்கள் தொலைபேசியிலேயே இருக்கும். இந்தத் தேர்வுகளை எப்போது வேண்டுமானாலும் அமைப்புகளில் மாற்றலாம்.';

  @override
  String get onboardingPhoneTitle => 'தொலைபேசி அழைப்புகள்';

  @override
  String get onboardingPhoneBody =>
      'யார் உங்களை அழைக்கிறார்கள் என்பதை செயலி பார்க்க இது உதவுகிறது, அதனால் அந்த எண் மோசடிக்குத் தெரிந்ததா என்று சொல்ல முடியும்.';

  @override
  String get onboardingContactsTitle => 'தொடர்புகள்';

  @override
  String get onboardingContactsBody =>
      'உங்களுக்குத் தெரிந்தவர்களை செயலி அடையாளம் காண இது உதவுகிறது, அதனால் அவர்களின் அழைப்புகள் சந்தேகத்திற்குரியதாகக் குறிக்கப்படாது.';

  @override
  String get onboardingScreeningTitle => 'அழைப்புச் சரிபார்ப்பு';

  @override
  String get onboardingScreeningBody =>
      'உள்வரும் அழைப்புகளைச் சரிபார்த்து, நீங்கள் தடுத்த எண்களை அமைதியாக நிறுத்த இது உதவுகிறது. அழைப்புத் திரையிடலுக்கு இந்த செயலியைத் தேர்ந்தெடுக்க உங்கள் தொலைபேசி கேட்கும்.';

  @override
  String get onboardingNotificationsTitle => 'எச்சரிக்கைகள்';

  @override
  String get onboardingNotificationsBody =>
      'ஏதேனும் மோசடி போலத் தோன்றினால் செயலி உங்களுக்குச் சுருக்கமான எச்சரிக்கையை அனுப்ப இது உதவுகிறது.';

  @override
  String get onboardingMessagesTitle => 'செய்திச் சரிபார்ப்பு';

  @override
  String get onboardingMessagesBody =>
      'புதிய செய்திகள் வரும்போது செயலி அவற்றைப் படிக்க இது உதவுகிறது, அதனால் சந்தேகமான இணைப்புகள் அல்லது பணக் கோரிக்கைகள் பற்றி எச்சரிக்க முடியும்.';

  @override
  String get onboardingOverlayTitle => 'அழைப்பின் போது எச்சரிக்கைகளைக் காட்டு';

  @override
  String get onboardingOverlayBody =>
      'சந்தேகமான அழைப்பு ஒலிக்கும்போது திரையில் ஒரு சிறிய அறிவிப்பைக் காட்ட இது உதவுகிறது.';

  @override
  String get onboardingBackgroundTitle => 'பின்னணியில் தொடர்ந்து இயங்கும்';

  @override
  String get onboardingBackgroundBody =>
      'உங்கள் திரை அணைக்கப்பட்டாலும் மோசடிகளைக் கண்காணிக்க, பேட்டரி மேம்படுத்தலைப் புறக்கணிக்க செயலியை அனுமதிக்கவும்.';

  @override
  String get onboardingBatterySettingsTitle => 'பேட்டரி மேம்படுத்தலை நிறுத்து';

  @override
  String get onboardingBatterySettingsBody =>
      'சில தொலைபேசிகள் முதல் கோரிக்கைக்குப் பிறகும் செயலிகளைக் கட்டுப்படுத்துகின்றன. பேட்டரி அமைப்புகளைத் திறந்து, இந்த செயலியைக் கண்டுபிடித்து, பாதுகாப்பு நிற்காமல் இருக்க \"மேம்படுத்த வேண்டாம்\" என அமைக்கவும்.';

  @override
  String get onboardingSettingsHint =>
      'உங்கள் தொலைபேசி அமைப்புகள் திறக்கும். பட்டியலில் இந்த செயலியைக் கண்டுபிடித்து இயக்கி, பின் இங்கே திரும்புங்கள்.';

  @override
  String get onboardingStatusOn => 'இது இயக்கப்பட்டுள்ளது.';

  @override
  String get onboardingStatusSkipped =>
      'இது இன்னும் இயக்கப்படவில்லை. மீண்டும் முயற்சிக்கலாம், அல்லது பின்னர் அமைப்புகளில் இயக்கலாம்.';

  @override
  String get onboardingStatusBlocked =>
      'உங்கள் தொலைபேசி மீண்டும் கேட்காது. இதை நீங்களே இயக்க \"அமைப்புகளைத் திற\" என்பதைத் தட்டவும்.';

  @override
  String get onboardingDoneTitle => 'எல்லாம் தயார்';

  @override
  String get onboardingDoneBody =>
      'செயலி இப்போது உங்களுக்காக மோசடி அழைப்புகள் மற்றும் செய்திகளைக் கவனித்து வருகிறது.';

  @override
  String get onboardingDonePartialTitle => 'கிட்டத்தட்ட முடிந்தது';

  @override
  String get onboardingDonePartialBody =>
      'சில பாதுகாப்புகள் இன்னும் இயக்கப்படவில்லை. செயலி இன்னும் வேலை செய்யும், மீதமுள்ளவற்றைப் பின்னர் அமைப்புகளில் இயக்கலாம்.';

  @override
  String onboardingGrantedCount(int granted, int total) {
    return '$total இல் $granted இயக்கப்பட்டுள்ளது';
  }

  @override
  String get onboardingWhy => 'ஏன்?';

  @override
  String get onboardingScreeningWhy =>
      'உங்கள் தொலைபேசி இந்த செயலியைத் தேர்ந்தெடுக்கக் கேட்கும். அழைப்புகளைச் சரிபார்க்க அதைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get onboardingMessagesWhy =>
      'வித்தியாசமான இணைப்புகள் அல்லது பணக் கோரிக்கைகள் போன்ற மோசடி அறிகுறிகளை நாங்கள் தேடுகிறோம்.';

  @override
  String get onboardingBatterySettingsHint =>
      'அமைப்புகள் திறக்கும். இந்த செயலியைக் கண்டுபிடித்து \"மேம்படுத்த வேண்டாம்\" எனத் தேர்ந்தெடுக்கவும்.';

  @override
  String get onboardingModelTitle => 'மோசடி சரிபார்ப்பான்';

  @override
  String get onboardingModelBody =>
      'உங்கள் தொலைபேசியில் செய்திகளைச் சரிபார்க்கிறது. Wi‑Fi பயன்படுத்தவும்.';

  @override
  String onboardingModelDownload(String size) {
    return 'பதிவிறக்கு ($size)';
  }

  @override
  String get onboardingModelDownloadShort => 'பதிவிறக்கு';

  @override
  String onboardingModelDownloading(int percent) {
    return 'பதிவிறக்குகிறது… $percent%';
  }

  @override
  String get onboardingModelKeepGoing =>
      'நீங்கள் தொடரலாம். பதிவிறக்கம் தொடரும்.';

  @override
  String get onboardingModelReady => 'பயன்படுத்தத் தயார்.';

  @override
  String get onboardingModelFailed =>
      'பதிவிறக்கம் முடிவடையவில்லை. மீண்டும் முயற்சிக்கவும், அல்லது பின்னர் அமைப்புகளில்.';

  @override
  String get onboardingModelMeteredTitle => 'மொபைல் தரவைப் பயன்படுத்தவா?';

  @override
  String onboardingModelMeteredBody(String size) {
    return 'நீங்கள் Wi‑Fi இல் இல்லை. இது சுமார் $size தரவைப் பயன்படுத்தும்.';
  }

  @override
  String get setupOpenSettingsFailed => 'அமைப்புகளைத் திறக்க முடியவில்லை.';

  @override
  String get authEnterEmail => 'உங்கள் மின்னஞ்சலை உள்ளிடவும்.';

  @override
  String get authValidEmail => 'சரியான மின்னஞ்சலை உள்ளிடவும்.';

  @override
  String get authEnterPassword => 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்.';

  @override
  String get authPasswordLength => 'குறைந்தது 8 எழுத்துகளைப் பயன்படுத்தவும்.';

  @override
  String get authEnterName => 'உங்கள் பெயரை உள்ளிடவும்.';

  @override
  String get authNameInvalid =>
      'எழுத்துகள் மற்றும் எண்களை மட்டுமே பயன்படுத்தவும், இரண்டு சொற்களுக்கு இடையே அதிகபட்சம் ஒரு இடைவெளி.';

  @override
  String get authCreateAccount => 'கணக்கை உருவாக்கு';

  @override
  String get authSignIn => 'உள்நுழை';

  @override
  String get authRegisterIntro =>
      'மோசடிகள் பற்றி பகிர்ந்து கற்றுக்கொள்ள சமூகத்தில் சேரவும்.';

  @override
  String get authLoginIntro =>
      'இடுகையிட மற்றும் விவாதங்களில் சேர உள்நுழையவும்.';

  @override
  String get authYourName => 'உங்கள் பெயர்';

  @override
  String get authYourNameHint => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get authEmail => 'மின்னஞ்சல்';

  @override
  String get authEmailHint => 'உங்கள் மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get authPassword => 'கடவுச்சொல்';

  @override
  String get authPasswordHint => 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get authToggleToLogin => 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழை';

  @override
  String get authToggleToRegister => 'புதியவரா? கணக்கை உருவாக்கு';

  @override
  String get authGateTitle => 'உள்நுழைவு தேவை';

  @override
  String get authGateBody =>
      'இந்த அம்சத்தைப் பயன்படுத்த நீங்கள் உள்நுழைய வேண்டும்.';

  @override
  String get authGateAction => 'உள்நுழை';

  @override
  String get communityTitle => 'சமூகம்';

  @override
  String get communityShareScam => 'ஒரு மோசடியைப் பகிர்';

  @override
  String get communityAll => 'அனைத்தும்';

  @override
  String get communityNoPostsBody =>
      'சமூகத்தால் பகிரப்பட்ட மோசடி புகார்கள் இங்கே தோன்றும்.';

  @override
  String get createChooseType => 'ஒரு மோசடி வகையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get createAddTitle => 'ஒரு தலைப்பைச் சேர்க்கவும்.';

  @override
  String get createAddMessage => 'செய்தி உரையைச் சேர்க்கவும்.';

  @override
  String get reportTabTitle => 'புகாரளி';

  @override
  String get reportTabThankYou => 'சமூகத்துடன் பகிரப்பட்டது. நன்றி!';

  @override
  String get reportTabTrackIt =>
      'சமூகத்துடன் பகிரப்பட்டது. கண்காணிக்க எனது இடுகைகளைப் பார்க்கவும்.';

  @override
  String get reportTabHeroTitle => 'மோசடியைப் புகாரளிக்கவும்';

  @override
  String get reportTabNumberHeroTitle => 'எண்ணைப் புகாரளிக்கவும்';

  @override
  String get reportTabNumberHeroBody =>
      'உங்களை ஏமாற்றிய அல்லது ஸ்பேம் செய்த தொலைபேசி எண்ணைப் புகாரளிக்கவும்.';

  @override
  String get reportTabPaste => 'ஒட்டவும்';

  @override
  String get reportTabPasteEmpty => 'கிளிப்போர்டு காலியாக உள்ளது';

  @override
  String get reportTabNumberLabel => 'தொலைபேசி எண்';

  @override
  String get reportTabNumberHint => 'எ.கா. +65 8123 4567';

  @override
  String get reportTabNumberRequired => 'தொலைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get reportTabReasonLabel => 'என்ன நடந்தது?';

  @override
  String get reportTabReasonSpamBody =>
      'வேண்டாத விளம்பரம் அல்லது மீண்டும் மீண்டும் வரும் அழைப்புகள்';

  @override
  String get reportTabReasonScamBody =>
      'பணம் அல்லது தனிப்பட்ட விவரங்களைத் திருட முயன்றது';

  @override
  String get reportTabReasonOtherBody => 'வேறு ஏதோ';

  @override
  String get reportTabSuccessTitle => 'புகாரளித்ததற்கு நன்றி';

  @override
  String get reportTabReportAnother => 'மற்றொன்றைப் புகாரளிக்கவும்';

  @override
  String get reportTabDone => 'முடிந்தது';

  @override
  String get myPostsTitle => 'எனது இடுகைகள்';

  @override
  String get myPostsNoneBody =>
      'நீங்கள் புகாரளிக்கும் மோசடிகள் இங்கே தோன்றும், அதனால் அவற்றைக் கண்காணிக்கலாம்.';

  @override
  String get myPostsDelete => 'நீக்கு';

  @override
  String get myPostsDeleteConfirm => 'இந்த இடுகையை நீக்கவா?';

  @override
  String get myPostsDeleteConfirmBody =>
      'இது சமூகத்திலிருந்து அகற்றப்படும். இதை மீட்டெடுக்க முடியாது.';

  @override
  String get myPostsEdit => 'திருத்து';

  @override
  String get editPostTitle => 'இடுகையைத் திருத்து';

  @override
  String get editPostSave => 'மாற்றங்களைச் சேமி';

  @override
  String get editPostSaving => 'சேமிக்கிறது...';

  @override
  String get editPostSaved => 'மாற்றங்கள் சேமிக்கப்பட்டன.';

  @override
  String get editPostReReview =>
      'செய்தியைத் திருத்தினால் இடுகை மீண்டும் மதிப்பாய்வுக்கு அனுப்பப்படும்.';

  @override
  String get postDetailThankYou =>
      'நன்றி. எங்கள் குழு இந்த இடுகையை மதிப்பாய்வு செய்யும்.';

  @override
  String get postDetailTitle => 'இடுகை';

  @override
  String get postDetailReportTooltip => 'இந்த இடுகையைப் புகாரளி';

  @override
  String postDetailComments(int count) {
    return 'கருத்துகள் ($count)';
  }

  @override
  String get postDetailNoComments => 'இன்னும் கருத்துகள் இல்லை.';

  @override
  String get postDetailWriteComment => 'ஒரு கருத்தை எழுது';

  @override
  String get postDetailPostComment => 'கருத்தை இடு';

  @override
  String get postDetailFlagPersonalInfo => 'தனிப்பட்ட தகவலைக் காட்டுகிறது';

  @override
  String get postDetailFlagHarmful => 'தீங்கு விளைவிக்கும் அல்லது ஆபத்தானது';

  @override
  String get postDetailFlagSpam => 'ஸ்பேம்';

  @override
  String get postDetailFlagMisinfo => 'தவறான தகவல்';

  @override
  String get postDetailFlagOther => 'மற்றவை';

  @override
  String get postDetailReply => 'பதில்';

  @override
  String get postDetailEdit => 'திருத்து';

  @override
  String get postDetailDelete => 'நீக்கு';

  @override
  String get postDetailSave => 'சேமி';

  @override
  String get postDetailCancel => 'ரத்து';

  @override
  String postDetailReplying(String name) {
    return '$name க்கு பதில்';
  }

  @override
  String get postDetailWriteReply => 'பதில் எழுதுங்கள்';

  @override
  String get postDetailDeleteConfirm => 'இந்தக் கருத்தை நீக்கவா?';

  @override
  String get postDetailDeleteConfirmBody => 'இதை மீட்டெடுக்க முடியாது.';

  @override
  String get postDetailEdited => 'திருத்தப்பட்டது';

  @override
  String get postDetailRemovedComment => 'இந்தக் கருத்து அகற்றப்பட்டது.';

  @override
  String get guidanceClickedLink => 'நான் ஒரு இணைப்பைக் கிளிக் செய்தேன்';

  @override
  String get guidanceGotMessage => 'எனக்கு இப்போது ஒரு செய்தி வந்தது';

  @override
  String get guidanceSharedPassword => 'நான் எனது கடவுச்சொல்லைப் பகிர்ந்தேன்';

  @override
  String get guidanceSentMoney => 'நான் பணம் அனுப்பினேன்';

  @override
  String get guidanceCouldNotOpenLink => 'இணைப்பைத் திறக்க முடியவில்லை.';

  @override
  String get guidanceCouldNotCall => 'அழைப்பைத் தொடங்க முடியவில்லை.';

  @override
  String get guidanceTitle => 'உதவி பெறு';

  @override
  String get guidanceWhatHappened => 'என்ன நடந்தது?';

  @override
  String get guidanceWhoToContact => 'யாரைத் தொடர்பு கொள்வது';

  @override
  String get guidanceShowAll => 'அனைத்தையும் காட்டு';

  @override
  String get guidanceOpenWebsite => 'இணையதளத்தைத் திற';

  @override
  String get guidanceNoAdvice => 'இன்னும் ஆலோசனை இல்லை';

  @override
  String get guidanceNoAdviceBody =>
      'நீங்கள் எடுக்கக்கூடிய நடவடிக்கைகளைப் பார்க்க மேலே என்ன நடந்தது என்பதைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get tourHomeTitle => 'ScamWatch-க்கு வரவேற்கிறோம்';

  @override
  String get tourHomeBody =>
      'உங்கள் முகப்புத் திரை உங்கள் பாதுகாப்பு நிலையையும் விரைவான செயல்களையும் காட்டுகிறது.';

  @override
  String get tourCallsTitle => 'அழைப்புகள்';

  @override
  String get tourCallsBody =>
      'தெரியாத எண்களிலிருந்து வரும் அழைப்புகள் இங்கே தோன்றும். விவரங்களைப் பார்க்க ஒரு அழைப்பைத் தட்டவும், மேலும் நீங்கள் மீண்டும் கேட்க விரும்பாத எண்களை நிர்வகிக்க மேல் மூலையில் உள்ள தடை ஐகானைப் பயன்படுத்தவும்.';

  @override
  String get tourBlockedTitle => 'உங்கள் தடுக்கப்பட்ட எண்கள்';

  @override
  String get tourBlockedBody =>
      'நீங்கள் தடுத்த எண்களைக் காண கோடு குறுக்கிட்ட கேடயச் சின்னத்தைத் தட்டவும்.';

  @override
  String get tourHelpTitle => 'உதவி தேவையா?';

  @override
  String get tourHelpBody =>
      'எந்தத் திரையிலும் ? என்பதைத் தட்டி ஒவ்வொன்றின் அர்த்தத்தைப் பார்க்கவும்.';

  @override
  String get tourSafetyTitle => 'பாதுகாப்பு';

  @override
  String get tourSafetyBody =>
      'இங்கே பாதுகாப்பை இயக்கவும். ஒரு மாதிரி பதிவிறக்கப்பட்டவுடன், Scam Shield உங்கள் சாதனத்தில் உள்வரும் செய்திகளைப் படித்து மோசடிகள் குறித்து எச்சரிக்கிறது.';

  @override
  String get tourReportTitle => 'புகாரளி';

  @override
  String get tourReportBody =>
      'ஒரு மோசடியைக் கண்டறிந்தீர்களா? இந்த தாவலிலிருந்து அதை சமூகத்துடன் பகிர்ந்து கொள்ளுங்கள், அதனால் மற்றவர்கள் அதே தந்திரத்தை அடையாளம் கண்டு பாதுகாப்பாக இருக்கலாம்.';

  @override
  String get tourProfileTitle => 'உங்கள் சுயவிவரம்';

  @override
  String get tourProfileBody =>
      'உங்கள் கணக்கு விவரங்களையும், இங்கே நீங்கள் புகாரளித்த மோசடிகளையும் பார்க்கவும்.';

  @override
  String tourStepCounter(int current, int total) {
    return '$total இல் $current';
  }

  @override
  String get tourSkip => 'தவிர்';

  @override
  String get tourDone => 'முடிந்தது';

  @override
  String get tourNext => 'அடுத்து';

  @override
  String get tourBack => 'பின்செல்';

  @override
  String get helpTooltip => 'உதவி';

  @override
  String get helpGotIt => 'புரிந்தது';

  @override
  String get helpShowTour => 'செயலி சுற்றுப்பயணத்தை மீண்டும் காட்டு';

  @override
  String get helpCallsTitle => 'ஒவ்வொன்றின் அர்த்தம்';

  @override
  String get helpCallsHighRiskTitle => 'சிவப்பு அழைப்பு = மோசடி வாய்ப்பு';

  @override
  String get helpCallsHighRiskBody => 'பதிலளிக்கவோ திரும்ப அழைக்கவோ வேண்டாம்.';

  @override
  String get helpCallsNormalTitle => 'சாதாரண அழைப்பு';

  @override
  String get helpCallsNormalBody => 'இந்த எண்ணுக்கு மோசடி புகார்கள் இல்லை.';

  @override
  String get helpCallsBlockedRowTitle => 'தடுக்கப்பட்ட அழைப்பு';

  @override
  String get helpCallsBlockedRowBody =>
      'நீங்கள் இந்த எண்ணைத் தடுத்துள்ளீர்கள். அது உங்களை அழைக்க முடியாது.';

  @override
  String get helpCallsBlockedListTitle => 'உங்கள் தடுக்கப்பட்ட எண்கள்';

  @override
  String get helpCallsBlockedListBody =>
      'எண்களைப் பார்க்க அல்லது தடை நீக்க இதைத் தட்டவும்.';

  @override
  String get helpCallsMenuTitle => 'மேலும் விருப்பங்கள்';

  @override
  String get helpCallsMenuBody =>
      'ஒரு எண்ணைச் சரிபார்க்கவும், தடுக்கவும் அல்லது புகாரளிக்கவும்.';

  @override
  String get helpCallsRefreshTitle => 'புதுப்பி';

  @override
  String get helpCallsRefreshBody =>
      'உங்கள் அழைப்புகளை மீண்டும் சரிபார்க்கவும்.';

  @override
  String get helpCallsMissedBody => 'இந்த அழைப்புக்கு நீங்கள் பதிலளிக்கவில்லை.';

  @override
  String get helpCallsAnsweredBody =>
      'இந்த அழைப்புக்கு நீங்கள் பதிலளித்தீர்கள்.';

  @override
  String get helpCallsRejectedBody => 'இந்த அழைப்பை நீங்கள் நிராகரித்தீர்கள்.';

  @override
  String get helpCallsBlockedIconBody => 'இந்த அழைப்பு தடுக்கப்பட்டது.';

  @override
  String get helpCallsOutgoingBody => 'இந்த எண்ணுக்கு நீங்கள் அழைத்தீர்கள்.';

  @override
  String get callsLikelyScam => 'மோசடி வாய்ப்பு';

  @override
  String get callsMoreOptions => 'மேலும் விருப்பங்கள்';

  @override
  String get callsBlockNumber => 'எண்ணைத் தடு';

  @override
  String get callsReportScam => 'மோசடி எனப் புகாரளி';

  @override
  String get callsBlockAndReport => 'தடுத்து புகாரளி';

  @override
  String get callsCheckNumber => 'எண்ணைச் சரிபார்';

  @override
  String get callsLoadFailedBody => 'மீண்டும் முயற்சிக்கவும்.';

  @override
  String get callsBlockedEmptyBody =>
      'நீங்கள் தடுக்கும் எண்கள் இங்கே தோன்றும்.';

  @override
  String get callsContactsLoadFailed =>
      'உங்கள் தொடர்புகளைக் காட்ட முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get callsCallTooltip => 'அழை';
}
