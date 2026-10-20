// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get commonReport => 'புகார்';

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
  String get commonReportThis => 'இதைப் புகார் செய்';

  @override
  String get commonNoPostsYet => 'இன்னும் பதிவுகள் இல்லை';

  @override
  String get commonShareWithCommunity => 'பகிர்';

  @override
  String get commonShare => 'பகிர்';

  @override
  String get commonSharing => 'பகிர்கிறது…';

  @override
  String get commonTitle => 'தலைப்பு';

  @override
  String get commonTitleHint => 'சுருக்கமான விவரம்';

  @override
  String get commonMessage => 'செய்தி';

  @override
  String get commonMessageHint => 'செய்தியை ஒட்டவும்';

  @override
  String get commonWhatKindOfScam => 'மோசடி வகை';

  @override
  String get commonShareIntro =>
      'ஒரு மோசடியைப் பகிருங்கள். முதலில் தனிப்பட்ட விவரங்களை நீக்கவும்.';

  @override
  String get commonPhotos => 'படங்கள் (விருப்பம்)';

  @override
  String get commonAddPhoto => 'படம் சேர்';

  @override
  String get commonRemovePhoto => 'படம் நீக்கு';

  @override
  String get commonImageTooLarge =>
      'ஒவ்வொரு படமும் 10 MB அல்லது குறைவாக இருக்க வேண்டும்.';

  @override
  String get reportTabPhotoProcessing => 'சரிபார்க்கிறது…';

  @override
  String get reportTabPhotoFailed => 'சரிபார்க்க முடியவில்லை';

  @override
  String get reportTabProcessingTitle =>
      'செயலாக்கப்படுகிறது. ஆப்ஸை மூட வேண்டாம்.';

  @override
  String get reportTabSignInToAddPhotos => 'படங்களைச் சேர்க்க உள்நுழையவும்.';

  @override
  String get reportTabFailedDialogTitle => 'சில படங்கள் தோல்வியடைந்தன';

  @override
  String reportTabFailedDialogBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count படங்கள் தோல்வியடைந்தன. மீண்டும் முயற்சிக்கவா, அல்லது அவை இல்லாமல் இடுகையிடவா?',
      one:
          '1 படம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவா, அல்லது அது இல்லாமல் இடுகையிடவா?',
    );
    return '$_temp0';
  }

  @override
  String get reportTabFailedRetry => 'மீண்டும் முயற்சி';

  @override
  String get reportTabFailedPostWithout => 'படங்கள் இல்லாமல் இடு';

  @override
  String get reportTabWaitForImages => 'படங்களுக்காகக் காத்திருங்கள்';

  @override
  String get reportTabCheckImages => 'படங்களைச் சரிபார்';

  @override
  String get reportTabReviewCheckbox =>
      'இந்தப் படங்களைப் பதிவிட ஒப்புக்கொள்கிறேன்';

  @override
  String get reportTabEditImage => 'படத்தைத் திருத்து';

  @override
  String get reportTabReuploading => 'திருத்திய படத்தைச் சேமிக்கிறது…';

  @override
  String get reportTabPosting => 'இடுகையிடுகிறது…';

  @override
  String get reportTabEditorSaveFailed =>
      'திருத்திய படத்தைச் சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get reportTabEditorLoadFailed =>
      'புகைப்படத்தைத் திறக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get reportTabViewPost => 'உங்கள் இடுகையைப் பார்';

  @override
  String get homeTitle => 'முகப்பு';

  @override
  String get homeWelcomePrefix => 'வணக்கம், ';

  @override
  String get homeWelcomeGuest => 'வணக்கம்';

  @override
  String get myProfileTitle => 'சுயவிவரம்';

  @override
  String get myProfileMemberSince => 'இணைந்த நாள்';

  @override
  String get myProfilePosts => 'பதிவுகள்';

  @override
  String get myProfileSignOut => 'வெளியேறு';

  @override
  String get myProfileSignOutHint =>
      'எப்போது வேண்டுமானாலும் மீண்டும் உள்நுழையலாம்';

  @override
  String get myProfileNotSignedInTitle => 'உள்நுழையவில்லை';

  @override
  String get myProfileNotSignedInBody => 'கணக்கைப் பார்க்க உள்நுழையுங்கள்.';

  @override
  String get myProfileSignIn => 'உள்நுழை';

  @override
  String get homeNewsTitle => 'மோசடி எச்சரிக்கைகள்';

  @override
  String get homeNewsError => 'எச்சரிக்கைகளை ஏற்ற முடியவில்லை.';

  @override
  String get homeNewsRetry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get homeQuickActionsTitle => 'நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்?';

  @override
  String get homeActionProfile => 'சுயவிவரம்';

  @override
  String get homeActionProfileBody => 'உங்கள் விவரங்களும் பதிவுகளும்';

  @override
  String get homeActionCalls => 'அழைப்புகள்';

  @override
  String get homeActionCallsBody =>
      'தெரியாத எண்களின் அழைப்புகளைச் சரிபார்க்கவும்';

  @override
  String get homeActionReport => 'மோசடியைப் புகார் செய்';

  @override
  String get homeActionReportBody => 'மற்றவர்களுக்கு எச்சரிக்கவும்';

  @override
  String get homeStatusOnBody =>
      'உங்கள் செய்திகளை மோசடிக்காகச் சரிபார்க்கிறோம்.';

  @override
  String get homeStatusOffBody => 'மோசடி எச்சரிக்கை பெற இதை இயக்கவும்.';

  @override
  String get homeStatusProblemTitle => 'பாதுகாப்பைச் சரிசெய்ய வேண்டும்';

  @override
  String get homeStatusProblemBody => 'ஏதோ தவறு. சரிசெய்ய தட்டவும்.';

  @override
  String get homeStatusStartingTitle => 'தொடங்குகிறது…';

  @override
  String get homeStatusStartingBody => 'இதற்கு ஒரு நிமிடம் ஆகலாம்.';

  @override
  String get homeStatusOpen => 'விவரங்கள்';

  @override
  String get homeStatusFix => 'சரிசெய்';

  @override
  String get homeNewsReadMore => 'மேலும் படிக்கவும்';

  @override
  String get homeNewsClose => 'மூடு';

  @override
  String homeNewsCount(Object current, Object total) {
    return '$total இல் $current';
  }

  @override
  String get homeNewsPrevious => 'முந்தையது';

  @override
  String get homeNewsNext => 'அடுத்தது';

  @override
  String get settingsProtection => 'பாதுகாப்பு';

  @override
  String get settingsStopProtection => 'பாதுகாப்பை நிறுத்து';

  @override
  String get settingsServiceRunning => 'இயக்கத்தில்';

  @override
  String get settingsServiceStopped => 'நிறுத்தப்பட்டது';

  @override
  String get settingsShowTutorial => 'சுற்றுப்பயணத்தை மீண்டும் காட்டு';

  @override
  String get settingsReplayTour => 'ஆப்ஸின் சுருக்கமான சுற்றுப்பயணம்';

  @override
  String get settingsRemove => 'நீக்கு';

  @override
  String settingsPercent(int pct) {
    return '$pct%';
  }

  @override
  String get settingsDownload => 'பதிவிறக்கு';

  @override
  String get settingsLanguage => 'மொழி';

  @override
  String get settingsLanguageSystem => 'தொலைபேசி இயல்புநிலை';

  @override
  String get settingsStatusTitle => 'நிலை';

  @override
  String get settingsGettingReady => 'தொடங்குகிறது…';

  @override
  String get settingsNeedsDownload => 'பதிவிறக்கம் தேவை';

  @override
  String settingsModelReady(String name) {
    return '$name தயார்';
  }

  @override
  String settingsModelNotDownloaded(String name) {
    return '$name பதிவிறக்கப்படவில்லை';
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
      'உங்கள் தொலைபேசியில் செய்திகளைச் சரிபார்க்கும். எதுவும் வெளியே போகாது.';

  @override
  String get settingsCheckingSupport => 'தொலைபேசியைச் சரிபார்க்கிறது…';

  @override
  String get settingsNotAvailable => 'இந்த தொலைபேசியில் கிடைக்கவில்லை';

  @override
  String get settingsReadyShort => 'தயார்';

  @override
  String get settingsBuiltInSubtitle => 'உள்ளமைந்தது. பதிவிறக்கம் இல்லை.';

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
      'சிக்கல் இல்லையெனில் தானியங்கியிலேயே விடவும்.';

  @override
  String get settingsSpeedAuto => 'தானியங்கி';

  @override
  String get settingsSpeedAutoBody => 'பெரும்பாலான தொலைபேசிகளுக்கு நல்லது';

  @override
  String get settingsSpeedCpu => 'அதிக இணக்கத்தன்மை';

  @override
  String get settingsSpeedCpuBody =>
      'எல்லா தொலைபேசிகளிலும் வேலை செய்யும். மிக மெதுவானது.';

  @override
  String get settingsSpeedGpu => 'வேகமானது';

  @override
  String get settingsSpeedGpuBody => 'கிராபிக்ஸ் சிப்பைப் பயன்படுத்தும்';

  @override
  String get settingsSpeedNpu => 'மிக வேகமானது';

  @override
  String get settingsSpeedNpuBody => 'புதிய தொலைபேசிகளில் மட்டும்';

  @override
  String get settingsAppSection => 'ஆப்ஸ்';

  @override
  String get settingsAppearance => 'தீம்';

  @override
  String get settingsThemeLight => 'ஒளி';

  @override
  String get settingsThemeDark => 'இருள்';

  @override
  String get settingsPermissionsSubtitle =>
      'ஆப்ஸ் என்ன செய்யும் என்று பாருங்கள்';

  @override
  String get settingsSignInSubtitle => 'பதிவிட தேவை';

  @override
  String get settingsProtectionOn => 'பாதுகாப்பு இயக்கத்தில் உள்ளது';

  @override
  String get settingsProtectionOff => 'பாதுகாப்பு நிறுத்தப்பட்டுள்ளது';

  @override
  String get settingsProtectionNeedsModel => 'பாதுகாப்புக்கு சரிபார்ப்பி தேவை';

  @override
  String settingsSettingUpProgress(int pct, int got, int total) {
    return 'அமைக்கிறது… $pct% · $total MB இல் $got MB';
  }

  @override
  String get settingsTextSize => 'எழுத்து அளவு';

  @override
  String get settingsTextNormal => 'இயல்பு';

  @override
  String get settingsTextLarge => 'பெரியது';

  @override
  String get settingsTextExtraLarge => 'மிகப் பெரியது';

  @override
  String get settingsSignOut => 'வெளியேறு';

  @override
  String get settingsSignOutSubtitle =>
      'எப்போது வேண்டுமானாலும் மீண்டும் உள்நுழையலாம்';

  @override
  String get settingsSignIn => 'உள்நுழை';

  @override
  String callIncoming(String who) {
    return '$who இடமிருந்து அழைப்பு';
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
  String get callHistoryTitle => 'அழைப்புகள்';

  @override
  String get callBlockedNumbers => 'தடுக்கப்பட்ட எண்கள்';

  @override
  String get callNoUnknown => 'தெரியாத எண்களில் இருந்து அழைப்பு இல்லை';

  @override
  String get callPhonePermNeeded => 'தொலைபேசி அணுகலை அனுமதி';

  @override
  String get callPhonePermBody =>
      'அழைப்புகளைக் காட்டவும் மோசடியைக் கண்டறியவும் தேவை.';

  @override
  String get callGrantPhone => 'அனுமதி';

  @override
  String get callCouldNotLoad => 'அழைப்புகளைக் காட்ட முடியவில்லை';

  @override
  String callDurationSuffix(int seconds) {
    return ' • $secondsவி';
  }

  @override
  String get callReportedSuffix => ' • புகார் செய்யப்பட்டது';

  @override
  String get callUnblock => 'தடைநீக்கு';

  @override
  String get callBlockNeedsScreening =>
      'அழைப்புகளைத் தடுக்க, இந்த ஆப்ஸை அழைப்புத் தடுப்பானாக அமைக்கவும்.';

  @override
  String get callHighRiskTitle => 'மோசடி அழைப்பாக இருக்கலாம்';

  @override
  String get callHighRiskBody =>
      'இந்த எண் மோசடி என்று பலர் புகார் செய்துள்ளனர். பணமோ தனிப்பட்ட விவரமோ கொடுக்க வேண்டாம்.';

  @override
  String callHighRiskScore(int score) {
    return 'மதிப்பெண்: $score/100';
  }

  @override
  String callHighRiskReports(int count) {
    return '$count புகார்கள்';
  }

  @override
  String get callHighRiskDismiss => 'புரிந்தது';

  @override
  String get callHighRiskBlock => 'இது மோசடி – தடு';

  @override
  String get callHighRiskSafe => 'பாதுகாப்பானது / மூடு';

  @override
  String get callChecking => 'சரிபார்க்கிறது…';

  @override
  String get callCheckTitle => 'எண்ணைச் சரிபார்';

  @override
  String get callCheckNumberLabel => 'சரிபார்த்த எண்';

  @override
  String get callCheckResultHighRisk => 'மோசடி இருக்கலாம்';

  @override
  String get callCheckResultUnknown => 'புகார் இல்லை';

  @override
  String get callCheckResultSafe => 'பாதுகாப்பாகத் தெரிகிறது';

  @override
  String get callCheckResultFailed => 'சரிபார்க்க முடியவில்லை';

  @override
  String get callCheckDetailHighRisk =>
      'இந்த எண் மோசடி என்று பலர் புகார் செய்துள்ளனர். திரும்ப அழைக்க வேண்டாம்.';

  @override
  String get callCheckDetailUnknown =>
      'புகார் இல்லை. இருந்தும் கவனமாக இருங்கள்.';

  @override
  String get callCheckDetailSafe =>
      'பாதுகாப்பாகத் தெரிகிறது. இருந்தும் கவனமாக இருங்கள்.';

  @override
  String get callCheckDetailFailed =>
      'இணையத்தைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String callCheckScore(int score) {
    return 'மதிப்பெண்: $score/100';
  }

  @override
  String callCheckReports(int count) {
    return '$count புகார்கள்';
  }

  @override
  String get reportNotSent =>
      'அனுப்ப முடியவில்லை. புகார் இன்னும் அமைக்கப்படவில்லை.';

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
      'இந்த ஆப்ஸை அழைப்புத் திரையிடலாக அமைக்கவும்';

  @override
  String get permScreeningUnavailable =>
      'இந்த தொலைபேசியில் அழைப்புத் திரையிடல் இல்லை';

  @override
  String get permNotificationAccess => 'செய்திகளைச் சரிபார்';

  @override
  String get permNotificationAccessSub =>
      'புதிய செய்திகளில் மோசடியைப் படிக்கிறது';

  @override
  String get permOverlay => 'அழைப்பு எச்சரிக்கைகள்';

  @override
  String get permOverlaySub => 'அழைப்பின் போது எச்சரிக்கை காட்டுகிறது';

  @override
  String get permAlerts => 'எச்சரிக்கைகள்';

  @override
  String get permAlertsSub => 'மோசடி எச்சரிக்கைகளை அனுப்புகிறது';

  @override
  String get permFullScreen => 'முழுத்திரை எச்சரிக்கைகள்';

  @override
  String get permFullScreenSub => 'பூட்டியிருக்கும் போது திரையை எழுப்பும்';

  @override
  String get permBackground => 'தொடர்ந்து இயங்கு';

  @override
  String get permBackgroundSub => 'திரை அணைந்தாலும் வேலை செய்யும்';

  @override
  String get permBatterySettings => 'ஆப்ஸை நிறுத்த வேண்டாம்';

  @override
  String get permBatterySettingsSub =>
      'இந்த ஆப்ஸை \"மேம்படுத்த வேண்டாம்\" என அமைக்கவும்.';

  @override
  String get permGranted => 'இயக்கத்தில்';

  @override
  String get permGrant => 'இயக்கு';

  @override
  String get permScreeningRole => 'அழைப்புகளைச் சரிபார்';

  @override
  String get permScreeningRoleSub =>
      'அழைப்புகளைச் சரிபார்த்து நீங்கள் தேர்வு செய்யும் எண்களைத் தடுக்கும்.';

  @override
  String get permScreeningActive => 'இயக்கத்தில்';

  @override
  String get permEnableScreening => 'இயக்கு';

  @override
  String get permScreeningNotGranted => 'அழைப்புச் சரிபார்ப்பு அணைந்துள்ளது';

  @override
  String get permScreeningTapHint => 'மேலே \"இயக்கு\" என்பதைத் தட்டவும்.';

  @override
  String get permTitle => 'அனுமதிகள்';

  @override
  String get permGrantFollowing => 'முழு பாதுகாப்புக்கு இவற்றை இயக்கவும்.';

  @override
  String get permPhoneCallLog => 'தொலைபேசி அழைப்புகள்';

  @override
  String get permPhoneGranted => 'தொலைபேசி அணுகல் அனுமதிக்கப்பட்டது';

  @override
  String get permContacts => 'தொடர்புகள்';

  @override
  String get permContactsGranted => 'தொடர்புகள் அனுமதிக்கப்பட்டது';

  @override
  String get permNotifications => 'அறிவிப்புகள்';

  @override
  String get permNotificationsGranted => 'அறிவிப்புகள் அனுமதிக்கப்பட்டது';

  @override
  String get permStillNotWorking => 'இன்னும் வேலை செய்யவில்லையா?';

  @override
  String get permOpenSettingsBody =>
      'தொலைபேசி அமைப்புகளில் அனுமதிகளை இயக்கவும்.';

  @override
  String get permOpenAppSettings => 'அமைப்புகளைத் திற';

  @override
  String get permNotChecked => 'சரிபார்க்கவில்லை';

  @override
  String get permStatusDenied => 'அணை';

  @override
  String get permPermanentlyDenied => 'அணை. அமைப்புகளில் இயக்கவும்';

  @override
  String get permNotGranted => 'அணை';

  @override
  String get contactsPermRequired => 'தொடர்புகளைப் பார்க்க அனுமதி கொடுங்கள்.';

  @override
  String get contactsTitle => 'தொடர்புகள்';

  @override
  String get contactsSearchHint => 'பெயர் அல்லது எண்ணைத் தேடு';

  @override
  String get contactsCouldNotLoad => 'தொடர்புகளை ஏற்ற முடியவில்லை';

  @override
  String get contactsNoneFound => 'தொடர்புகள் இல்லை';

  @override
  String get contactsNoDetails => 'விவரங்கள் இல்லை';

  @override
  String get contactsCouldNotCall => 'அழைப்பைத் தொடங்க முடியவில்லை';

  @override
  String get safetyTitle => 'பாதுகாப்பு';

  @override
  String get safetyRecentAlerts => 'சமீபத்திய எச்சரிக்கைகள்';

  @override
  String get safetyProtectedOn => 'பாதுகாப்பு இயக்கத்தில்';

  @override
  String get safetyProtectedOff => 'பாதுகாப்பு அணைந்துள்ளது';

  @override
  String get safetyWeCheck => 'உங்கள் செய்திகளில் மோசடியைச் சரிபார்க்கிறது.';

  @override
  String get safetyTurnOnToCheck => 'செய்திகளைச் சரிபார்க்க இயக்கவும்.';

  @override
  String get safetyTurnOff => 'பாதுகாப்பை அணை';

  @override
  String get safetyTurnOn => 'பாதுகாப்பை இயக்கு';

  @override
  String get safetyPressToStart => 'தொடங்க தட்டவும்';

  @override
  String get safetyDownloadingModel => 'பதிவிறக்குகிறது…';

  @override
  String get safetySettingUpModel => 'அமைக்கிறது…';

  @override
  String get safetyNoScams => 'மோசடிகள் இல்லை';

  @override
  String get safetyNoScamsBody => 'மோசடிகள் இங்கே தோன்றும்.';

  @override
  String get safetyMeteredTitle => 'மொபைல் தரவைப் பயன்படுத்தவா?';

  @override
  String safetyMeteredBody(int mb) {
    return 'பதிவிறக்கம் சுமார் $mb MB. Wi-Fi நல்லது.';
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
  String get safetyPillOn => 'பாதுகாப்பு';

  @override
  String get safetyPillOff => 'அணை';

  @override
  String get safetyPillError => 'சரிசெய்ய வேண்டும்';

  @override
  String get safetyPillChecking => 'சரிபார்ப்பு';

  @override
  String get safetyHeroOnBody => 'உங்கள் தொலைபேசியிலேயே சரிபார்க்கப்படுகிறது.';

  @override
  String get protectionChecked => 'சரிபார்க்கப்பட்டது';

  @override
  String get protectionAlerts => 'எச்சரிக்கைகள்';

  @override
  String get protectionOn => 'பாதுகாப்பு இயக்கத்தில்';

  @override
  String get protectionOff => 'பாதுகாப்பு அணைந்துள்ளது';

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
    return 'சரிபார்க்கவில்லை ($count)';
  }

  @override
  String get activityNoMessages => 'இன்னும் செய்திகள் இல்லை.';

  @override
  String get activityNotCheckedSuffix => ' · சரிபார்க்கவில்லை';

  @override
  String get activityCloudSuffix => ' · ஆன்லைன்';

  @override
  String get activityNotCheckedYet => 'இன்னும் சரிபார்க்கவில்லை.';

  @override
  String get activityVerdict => 'முடிவு';

  @override
  String get activityConfidence => 'நம்பகத்தன்மை';

  @override
  String get activityCheckedBy => 'சரிபார்த்தவர்';

  @override
  String activityEscalatedSuffix(String wire) {
    return '$wire (ஆன்லைன்)';
  }

  @override
  String get activityReason => 'காரணம்';

  @override
  String get activityAiThinking => 'முழு முடிவு';

  @override
  String get activityNoOutput => '(முடிவு இல்லை)';

  @override
  String get blockedNumbersTitle => 'தடுக்கப்பட்ட எண்கள்';

  @override
  String get blockedNoNumbers => 'தடுக்கப்பட்ட எண்கள் இல்லை';

  @override
  String get notificationsTitle => 'அறிவிப்புகள்';

  @override
  String get activityTitle => 'செயல்பாடு';

  @override
  String get notificationsTestTitle => 'ஒரு செய்தியைச் சோதி';

  @override
  String get notificationsTestHint =>
      'செய்தியை ஒட்டவும் அல்லது தட்டச்சு செய்யவும்';

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
  String get onboardingStart => 'தொடங்கு';

  @override
  String get onboardingAllow => 'அனுமதி';

  @override
  String get onboardingOpenSettings => 'அமைப்புகளைத் திற';

  @override
  String get onboardingNotNow => 'இப்போது வேண்டாம்';

  @override
  String get onboardingFinish => 'ஆப்ஸைத் திற';

  @override
  String onboardingStepCount(int step, int total) {
    return 'படி $step / $total';
  }

  @override
  String get onboardingWelcomeTitle => 'மோசடியிலிருந்து பாதுகாப்பாக இருங்கள்';

  @override
  String get onboardingWelcomeBody =>
      'மோசடி அழைப்புகள், செய்திகள் பற்றி எச்சரிக்கிறோம்.';

  @override
  String get onboardingWelcomeNote => 'அமைக்க ஒரு நிமிடம் ஆகும்.';

  @override
  String get onboardingPhoneTitle => 'தொலைபேசி அழைப்புகள்';

  @override
  String get onboardingPhoneBody => 'யார் அழைக்கிறார் என்று தெரியும்.';

  @override
  String get onboardingContactsTitle => 'தொடர்புகள்';

  @override
  String get onboardingContactsBody =>
      'உங்களுக்குத் தெரிந்தவர்களின் அழைப்புகள் குறிக்கப்படாது.';

  @override
  String get onboardingScreeningTitle => 'அழைப்புகளைச் சரிபார்';

  @override
  String get onboardingScreeningBody =>
      'அழைப்புகளைச் சரிபார்த்து நீங்கள் தேர்ந்தெடுக்கும் எண்களைத் தடுக்கும்.';

  @override
  String get onboardingNotificationsTitle => 'எச்சரிக்கைகள்';

  @override
  String get onboardingNotificationsBody =>
      'மோசடி இருக்கலாம் என்றால் எச்சரிக்கை வரும்.';

  @override
  String get onboardingMessagesTitle => 'செய்திகளைச் சரிபார்';

  @override
  String get onboardingMessagesBody =>
      'புதிய செய்திகளில் மோசடியைக் கண்டறிய படிக்கிறது.';

  @override
  String get onboardingOverlayTitle => 'அழைப்பு எச்சரிக்கைகள்';

  @override
  String get onboardingOverlayBody => 'ஆபத்தான அழைப்பில் எச்சரிக்கை காட்டும்.';

  @override
  String get onboardingFullScreenTitle => 'முழுத்திரை எச்சரிக்கைகள்';

  @override
  String get onboardingFullScreenBody =>
      'பூட்டிய தொலைபேசியில் எச்சரிக்கை காட்டும்.';

  @override
  String get onboardingBackgroundTitle => 'தொடர்ந்து இயங்கட்டும்';

  @override
  String get onboardingBackgroundBody =>
      'திரை அணைந்தாலும் சரிபார்த்துக்கொண்டே இருக்கும்.';

  @override
  String get onboardingBatterySettingsTitle => 'ஆப்ஸை நிறுத்த வேண்டாம்';

  @override
  String get onboardingBatterySettingsBody =>
      'தொலைபேசி ஆப்ஸை நிறுத்தாதபடி செய்யுங்கள்.';

  @override
  String get onboardingSettingsHint =>
      'அமைப்புகள் திறக்கும். இந்த ஆப்ஸை இயக்கவும்.';

  @override
  String get onboardingStatusOn => 'இயக்கத்தில்.';

  @override
  String get onboardingStatusSkipped =>
      'இயக்கத்தில் இல்லை. பின்னர் அமைப்புகளில் இயக்கலாம்.';

  @override
  String get onboardingStatusBlocked =>
      'இதை இயக்க \"அமைப்புகளைத் திற\" என்பதைத் தட்டவும்.';

  @override
  String get onboardingDoneTitle => 'எல்லாம் தயார்';

  @override
  String get onboardingDoneBody => 'மோசடியைக் கவனித்து வருகிறோம்.';

  @override
  String get onboardingDonePartialTitle => 'கிட்டத்தட்ட முடிந்தது';

  @override
  String get onboardingDonePartialBody =>
      'சிலவை அணைந்துள்ளன. அமைப்புகளில் இயக்கவும்.';

  @override
  String onboardingGrantedCount(int granted, int total) {
    return '$total இல் $granted இயக்கத்தில்';
  }

  @override
  String get onboardingWhy => 'ஏன்?';

  @override
  String get onboardingScreeningWhy =>
      'அழைப்புகளைச் சரிபார்க்க இந்த ஆப்ஸைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get onboardingMessagesWhy =>
      'விநோதமான இணைப்புகள் அல்லது பணக் கோரிக்கைகளைத் தேடுகிறோம்.';

  @override
  String get onboardingBatterySettingsHint =>
      'அமைப்புகள் திறக்கும். \"மேம்படுத்த வேண்டாம்\" என்பதைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get onboardingModelTitle => 'மோசடி சரிபார்ப்பான்';

  @override
  String get onboardingModelBody =>
      'உங்கள் தொலைபேசியில் செய்திகளைச் சரிபார்க்கும். Wi‑Fi பயன்படுத்தவும்.';

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
  String get onboardingModelKeepGoing => 'தொடரலாம். பதிவிறக்கம் தொடரும்.';

  @override
  String get onboardingModelReady => 'தயார்.';

  @override
  String get onboardingModelFailed =>
      'பதிவிறக்கம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get onboardingModelMeteredTitle => 'மொபைல் தரவைப் பயன்படுத்தவா?';

  @override
  String onboardingModelMeteredBody(String size) {
    return 'நீங்கள் Wi‑Fi இல் இல்லை. இது சுமார் $size பயன்படுத்தும்.';
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
      'எழுத்துகளும் எண்களும் மட்டும். ஒரு இடைவெளி அனுமதிக்கப்படும்.';

  @override
  String get authCreateAccount => 'கணக்கை உருவாக்கு';

  @override
  String get authSignIn => 'உள்நுழை';

  @override
  String get authRegisterIntro => 'மோசடிகளைப் பகிர சேருங்கள்.';

  @override
  String get authLoginIntro => 'பதிவிடவும் கருத்து சொல்லவும் உள்நுழையவும்.';

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
  String get authShowPassword => 'கடவுச்சொல்லைக் காட்டு';

  @override
  String get authHidePassword => 'கடவுச்சொல்லை மறை';

  @override
  String get authToggleToLogin => 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழை';

  @override
  String get authToggleToRegister => 'புதியவரா? கணக்கு உருவாக்கு';

  @override
  String get authGateTitle => 'தொடர உள்நுழையுங்கள்';

  @override
  String get authGateBody => 'கணக்கு தேவை. இலவசம்.';

  @override
  String get authGateAction => 'உள்நுழை';

  @override
  String get communityTitle => 'சமூகம்';

  @override
  String get communityShareScam => 'மோசடியைப் பகிர்';

  @override
  String get communityAll => 'அனைத்தும்';

  @override
  String get communityNoPostsBody => 'பகிரப்பட்ட மோசடிகள் இங்கே தோன்றும்.';

  @override
  String get createChooseType => 'ஒரு மோசடி வகையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get createAddTitle => 'தலைப்பு சேர்க்கவும்.';

  @override
  String get createAddMessage => 'செய்தி உரையைச் சேர்க்கவும்.';

  @override
  String get reportTabTitle => 'புகார்';

  @override
  String get reportTabThankYou => 'பகிரப்பட்டது. நன்றி!';

  @override
  String get reportTabTrackIt =>
      'பகிரப்பட்டது. கண்காணிக்க எனது சுயவிவரத்தைப் பாருங்கள்.';

  @override
  String get reportTabHeroTitle => 'மோசடி பற்றி மற்றவர்களுக்கு எச்சரிக்கவும்';

  @override
  String get reportTabNumberHeroTitle => 'எண்ணைப் புகார் செய்';

  @override
  String get reportTabNumberHeroBody =>
      'இந்த எண் ஏன் சந்தேகமானது என்று சொல்லுங்கள். உங்கள் புகார் மற்றவர்களுக்கு உதவும்.';

  @override
  String get reportTabPaste => 'ஒட்டு';

  @override
  String get reportTabPasteEmpty =>
      'ஒட்ட எதுவும் இல்லை. முதலில் செய்தியை நகலெடுக்கவும்.';

  @override
  String get reportTabNumberLabel => 'தொலைபேசி எண்';

  @override
  String get reportTabNumberHint => 'எ.கா. +65 9123 4567';

  @override
  String get reportTabNumberRequired => 'தொலைபேசி எண்ணை உள்ளிடவும்.';

  @override
  String get reportTabReasonLabel => 'என்ன நடந்தது?';

  @override
  String get reportTabReasonSpamBody =>
      'தேவையில்லாத அழைப்புகள் அல்லது விளம்பரங்கள்';

  @override
  String get reportTabReasonScamBody =>
      'என்னை ஏமாற்ற அல்லது பணத்தை எடுக்க முயன்றார்கள்';

  @override
  String get reportTabReasonOtherBody => 'வேறு ஏதோ தவறு';

  @override
  String get reportTabSuccessTitle => 'நன்றி';

  @override
  String get reportTabReportAnother => 'மற்றொன்றைப் புகார் செய்';

  @override
  String get reportTabDone => 'முடிந்தது';

  @override
  String get myPostsTitle => 'எனது இடுகைகள்';

  @override
  String get myPostsNoneBody => 'நீங்கள் பகிரும் புகார்கள் இங்கே தோன்றும்.';

  @override
  String get myPostsDelete => 'நீக்கு';

  @override
  String get myPostsDeleteConfirm => 'இந்த இடுகையை நீக்கவா?';

  @override
  String get myPostsDeleteConfirmBody =>
      'அனைவருக்கும் நீங்கும். மீண்டும் மீட்க முடியாது.';

  @override
  String get myPostsEdit => 'திருத்து';

  @override
  String get editPostTitle => 'இடுகையைத் திருத்து';

  @override
  String get editPostSave => 'சேமி';

  @override
  String get editPostSaving => 'சேமிக்கிறது…';

  @override
  String get editPostSaved => 'சேமிக்கப்பட்டது.';

  @override
  String get editPostReReview =>
      'திருத்தினால் இடுகை மீண்டும் பரிசீலனைக்குச் செல்லும்.';

  @override
  String get postDetailThankYou => 'நன்றி. இந்த இடுகையைப் பார்ப்போம்.';

  @override
  String get postDetailTitle => 'இடுகை';

  @override
  String get postDetailReportTooltip => 'இடுகையைப் புகார் செய்';

  @override
  String postDetailComments(int count) {
    return 'கருத்துகள் ($count)';
  }

  @override
  String get postDetailNoComments => 'இன்னும் கருத்துகள் இல்லை.';

  @override
  String get postDetailWriteComment => 'கருத்து எழுது';

  @override
  String get postDetailPostComment => 'இடு';

  @override
  String get postDetailFlagPersonalInfo => 'தனிப்பட்ட விவரம் காட்டுகிறது';

  @override
  String get postDetailFlagHarmful => 'தீங்கானது அல்லது ஆபத்தானது';

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
  String get postDetailWriteReply => 'பதில் எழுது';

  @override
  String get postDetailDeleteConfirm => 'இந்தக் கருத்தை நீக்கவா?';

  @override
  String get postDetailDeleteConfirmBody => 'இதை மீட்டெடுக்க முடியாது.';

  @override
  String get postDetailEdited => 'திருத்தப்பட்டது';

  @override
  String get postDetailRemovedComment => 'இந்தக் கருத்து நீக்கப்பட்டது.';

  @override
  String get postDetailAiBadge => 'AI';

  @override
  String get postDetailMentionHelpHint =>
      'இந்தப் பதிவைப் பற்றி NegevAI இடம் கேளுங்கள்';

  @override
  String get postDetailBotThinking => 'NegevAI யோசிக்கிறது...';

  @override
  String get guidanceClickedLink => 'நான் ஒரு இணைப்பைத் தட்டினேன்';

  @override
  String get guidanceGotMessage => 'எனக்கு ஒரு செய்தி வந்தது';

  @override
  String get guidanceSharedPassword => 'நான் என் கடவுச்சொல்லைப் பகிர்ந்தேன்';

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
      'என்ன நடந்தது என்பதைத் தேர்ந்தெடுத்து என்ன செய்வது என்று பாருங்கள்.';

  @override
  String get tourHomeTitle => 'பாதுகாப்பு';

  @override
  String get tourHomeBody =>
      'பச்சை என்றால் பாதுகாப்பு. பச்சை இல்லையெனில் தட்டவும்.';

  @override
  String get tourCallsTitle => 'சிவப்பு அழைப்புகள்';

  @override
  String get tourCallsBody =>
      'சிவப்பு அழைப்புகள் மோசடியாக இருக்கலாம். பதிலளிக்கவோ திரும்ப அழைக்கவோ வேண்டாம்.';

  @override
  String get tourBlockedTitle => 'தடுக்கப்பட்ட எண்கள்';

  @override
  String get tourBlockedBody =>
      'தடுக்கப்பட்ட எண்களைப் பார்க்க கோடு போட்ட கேடயத்தைத் தட்டவும்.';

  @override
  String get tourHelpTitle => 'உதவி தேவையா?';

  @override
  String get tourHelpBody => 'எந்தத் திரையிலும் ? ஐத் தட்டவும்.';

  @override
  String get tourSafetyTitle => 'பாதுகாப்பை இயக்கு';

  @override
  String get tourSafetyBody =>
      'இங்கே இயக்கவும் அல்லது அணைக்கவும். மோசடி செய்திகள் பற்றி எச்சரிக்கிறோம்.';

  @override
  String get tourReportTitle => 'மோசடியைப் புகார் செய்';

  @override
  String get tourReportBody => 'மற்றவர்கள் பாதுகாப்பாக இருக்கச் சொல்லுங்கள்.';

  @override
  String get tourReviewTitle => 'பெட்டியைத் தேர்வு செய்யுங்கள்';

  @override
  String get tourReviewBody =>
      'புகைப்படங்களைச் சேர்த்த பிறகு சரிபார்க்கவும். பின்னர் பகிர இந்தப் பெட்டியைத் தேர்வு செய்யவும்.';

  @override
  String get tourPostHelpTitle => 'AI உதவியாளரிடம் கேளுங்கள்';

  @override
  String get tourPostHelpBody =>
      'இது மோசடியா என்று உறுதியாகத் தெரியவில்லையா? கருத்தில் @help என்று தட்டச்சு செய்யுங்கள். எங்கள் AI மோசடி உதவியாளர் பதிலளிப்பார்.';

  @override
  String get tourPostAiTitle => 'பதில்களைப் படியுங்கள்';

  @override
  String get tourPostAiBody =>
      'AI குறியுடன் உள்ள பதில்கள் உதவியாளரிடமிருந்து வருபவை. அது தவறு செய்யலாம், எனவே நீங்கள் நம்பும் ஒருவரிடமும் கேளுங்கள்.';

  @override
  String get tourPostSampleReply =>
      'இது மோசடி போல் தெரிகிறது. இணைப்பைக் கிளிக் செய்ய வேண்டாம்.';

  @override
  String get tourProfileTitle => 'சுயவிவரம்';

  @override
  String get tourProfileBody =>
      'உங்கள் பதிவுகளையும் அமைப்புகளையும் இங்கே பாருங்கள். இந்தச் சுற்றுப்பயணத்தை அமைப்புகளில் மீண்டும் பார்க்கலாம்.';

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
  String get helpShowTour => 'சுற்றுப்பயணத்தை மீண்டும் காட்டு';

  @override
  String get helpCallsTitle => 'ஒவ்வொன்றின் அர்த்தம்';

  @override
  String get helpCallsHighRiskTitle => 'சிவப்பு அழைப்பு = மோசடி இருக்கலாம்';

  @override
  String get helpCallsHighRiskBody => 'பதிலளிக்கவோ திரும்ப அழைக்கவோ வேண்டாம்.';

  @override
  String get helpCallsNormalTitle => 'சாதாரண அழைப்பு';

  @override
  String get helpCallsNormalBody => 'மோசடி புகார் இல்லை.';

  @override
  String get helpCallsBlockedRowTitle => 'தடுக்கப்பட்ட அழைப்பு';

  @override
  String get helpCallsBlockedRowBody => 'இந்த எண் உங்களை அழைக்க முடியாது.';

  @override
  String get helpCallsBlockedListTitle => 'தடுக்கப்பட்ட எண்கள்';

  @override
  String get helpCallsBlockedListBody =>
      'எண்களைப் பார்க்க அல்லது தடைநீக்க தட்டவும்.';

  @override
  String get helpCallsMenuTitle => 'மேலும் விருப்பங்கள்';

  @override
  String get helpCallsMenuBody => 'எண்ணைச் சரிபார், தடு அல்லது புகார் செய்.';

  @override
  String get helpCallsRefreshTitle => 'புதுப்பி';

  @override
  String get helpCallsRefreshBody => 'அழைப்புகளை மீண்டும் சரிபார்.';

  @override
  String get helpCallsMissedBody => 'இந்த அழைப்பைத் தவறவிட்டீர்கள்.';

  @override
  String get helpCallsAnsweredBody => 'இந்த அழைப்புக்குப் பதிலளித்தீர்கள்.';

  @override
  String get helpCallsRejectedBody => 'இந்த அழைப்பை நிராகரித்தீர்கள்.';

  @override
  String get helpCallsBlockedIconBody => 'இந்த அழைப்பு தடுக்கப்பட்டது.';

  @override
  String get helpCallsOutgoingBody => 'இந்த எண்ணுக்கு நீங்கள் அழைத்தீர்கள்.';

  @override
  String get callsLikelyScam => 'மோசடி இருக்கலாம்';

  @override
  String get callsMoreOptions => 'மேலும் விருப்பங்கள்';

  @override
  String get callsBlockNumber => 'எண்ணைத் தடு';

  @override
  String get callsReportScam => 'மோசடி என்று புகார் செய்';

  @override
  String get callsBlockAndReport => 'தடுத்து புகார் செய்';

  @override
  String get callsCheckNumber => 'எண்ணைச் சரிபார்';

  @override
  String get callsLoadFailedBody => 'மீண்டும் முயற்சிக்கவும்.';

  @override
  String get callsBlockedEmptyBody => 'தடுக்கப்பட்ட எண்கள் இங்கே தோன்றும்.';

  @override
  String get callsContactsLoadFailed =>
      'தொடர்புகளைக் காட்ட முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get callsCallTooltip => 'அழை';
}
