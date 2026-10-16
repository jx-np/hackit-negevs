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
  String get commonDownloadModelFirst =>
      'முதலில் அமைப்புகள் தாவலில் ஒரு மாதிரியைப் பதிவிறக்கவும்';

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
  String get commonTagsOptional => 'குறிச்சொற்கள் (விருப்பத்திற்குரியது)';

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
  String get reportTabPhotoReady => 'தயார்';

  @override
  String get reportTabPhotoFailed => 'பகுப்பாய்வு செய்ய முடியவில்லை';

  @override
  String get reportTabPhotoDropped =>
      'சில படங்களைப் பகுப்பாய்வு செய்ய முடியவில்லை, அவை அகற்றப்பட்டன.';

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
  String get reportTabWaitForImages => 'Wait for images to be processed';

  @override
  String get reportTabCheckImages => 'Check images';

  @override
  String get reportTabReviewCheckbox =>
      'I\'ve reviewed the images and the personal details are hidden correctly';

  @override
  String get reportTabEditImage => 'Edit image';

  @override
  String get reportTabReuploading => 'Re-uploading edited image...';

  @override
  String get reportTabPosting => 'Posting...';

  @override
  String get reportTabEditorSaveFailed =>
      'Couldn\'t re-upload the edited image. Try again.';

  @override
  String get reportTabViewPost => 'View your post';

  @override
  String get homeTitle => 'முகப்பு';

  @override
  String get homeWelcomePrefix => 'வரவேற்கிறோம், ';

  @override
  String get homeWelcomeGuestLabel => 'உள்நுழையவில்லை';

  @override
  String get homeWelcomeGuest => 'Welcome';

  @override
  String get myProfileTitle => 'எனது சுயவிவரம்';

  @override
  String get myProfileAccountSection => 'கணக்கு விவரங்கள்';

  @override
  String get myProfileName => 'பெயர்';

  @override
  String get myProfileEmail => 'மின்னஞ்சல்';

  @override
  String get myProfileMemberSince => 'இணைந்த நாள்';

  @override
  String get myProfilePosts => 'பதிவுகள்';

  @override
  String get myProfileRole => 'பங்கு';

  @override
  String get myProfileRoleResident => 'உறுப்பினர்';

  @override
  String get myProfileRoleModerator => 'இணை நிர்வாகி';

  @override
  String get myProfileRoleAdmin => 'நிர்வாகி';

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
  String get homeActionMyPosts => 'எனது பதிவுகள்';

  @override
  String get homeActionMyPostsBody =>
      'நீங்கள் புகாரளித்த மோசடிகளைப் பின்தொடரவும்';

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
  String get homeActionSafety => 'பாதுகாப்பு';

  @override
  String get homeActionSafetyBody => 'Scam Shield-ஐ இயக்கவும்';

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
  String get settingsDetectionModel => 'கண்டறிதல் மாதிரி';

  @override
  String get settingsProtection => 'பாதுகாப்பு';

  @override
  String get settingsClearNotifications => 'பிடிக்கப்பட்ட அறிவிப்புகளை அழி';

  @override
  String get settingsStopProtection => 'பின்னணி பாதுகாப்பை நிறுத்து';

  @override
  String get settingsServiceRunning => 'சேவை இயங்குகிறது';

  @override
  String get settingsServiceStopped => 'சேவை நிறுத்தப்பட்டது';

  @override
  String get settingsAccount => 'கணக்கு';

  @override
  String get settingsShowTutorial => 'பயிற்சியை மீண்டும் காட்டு';

  @override
  String get settingsReplayTour => 'செயலி அம்ச மேலோட்டத்தை மீண்டும் இயக்கு';

  @override
  String get settingsLogOut => 'வெளியேறு';

  @override
  String get settingsSignOutSubtitle => 'உங்கள் கணக்கிலிருந்து வெளியேறு';

  @override
  String get settingsAdvanced => 'மேம்பட்டவை';

  @override
  String get settingsAdvancedSubtitle =>
      'டெவலப்பர் மற்றும் மாதிரி-சரிசெய்தல் விருப்பங்கள்';

  @override
  String get settingsModelFromDevice => 'இந்த சாதனத்திலிருந்து மாதிரி (சோதனை)';

  @override
  String get settingsScanForModels => 'மாதிரி கோப்புகளை ஸ்கேன் செய்';

  @override
  String get settingsScanningStorage => 'சேமிப்பகத்தை ஸ்கேன் செய்கிறது…';

  @override
  String get settingsScanSubtitle =>
      'ஆப் ஏற்கெனவே பதிவிறக்கிய .litertlm மற்றும் .task கோப்புகளைக் கண்டறியும்';

  @override
  String get settingsModelFilePath => 'மாதிரி கோப்பு பாதை';

  @override
  String get settingsModelFilePathHelper =>
      'தட்டச்சு செய்த பாதைகளும் வேலை செய்யும். கோப்பு அப்படியே பயன்படுத்தப்படுகிறது — அது ஒருபோதும் நகலெடுக்கப்படாது.';

  @override
  String get settingsContextWindow => 'சூழல் சாளரம் (டோக்கன்கள்)';

  @override
  String settingsContextWindowHelper(int max) {
    return 'ஏற்றும்போது கோரும் சூழல். உங்கள் மாற்றம் kv_cache_max_len ஆக அமைத்ததை மீறக்கூடாது (MiniCPM5-2B $max வரை ஆதரிக்கிறது). பெரிய சாளரங்கள் ஒரு டோக்கனுக்கு சுமார் 40 KB RAM செலவாகும்.';
  }

  @override
  String settingsContextRange(int max) {
    return '1024 மற்றும் $max இடையே உள்ளிடவும்';
  }

  @override
  String get settingsThinking => 'சிந்தனை (பகுத்தறிவு)';

  @override
  String get settingsThinkingHelper =>
      'பதிலளிப்பதற்கு முன் மாதிரி பகுத்தறிய அனுமதிக்கிறது. அதிக டோக்கன்களைப் பயன்படுத்துகிறது மற்றும் மெதுவாக உள்ளது; பயனுள்ளதாக இருக்க 3000+ டோக்கன் சூழல் தேவை.';

  @override
  String get settingsLoadModelFromFile => 'கோப்பிலிருந்து மாதிரியை ஏற்று';

  @override
  String settingsCloudThreshold(int pct) {
    return 'கிளவுட் அதிகரிப்பு வரம்பு — $pct% க்கு கீழே அதிகரிக்கவும்';
  }

  @override
  String get settingsCloudReview => 'கிளவுட் மதிப்பாய்வு';

  @override
  String get settingsForceCloud => 'கிளவுட்டை கட்டாயப்படுத்து';

  @override
  String get settingsForceCloudHelper =>
      'ஒவ்வொரு செய்தியையும் கிளவுட் மாதிரிக்கு அனுப்பி சாதனத்தில் உள்ள மாதிரியைத் தவிர்க்கவும். கிளவுட் அணுக முடியாவிட்டால் மட்டுமே சாதனத்தில் உள்ள மாதிரிக்கு மாறும்.';

  @override
  String get settingsEndpoint => 'இறுதிப்புள்ளி';

  @override
  String get settingsEndpointHint =>
      'https://.../v1/chat/completions (காலியானது = முடக்கப்பட்டது)';

  @override
  String get settingsModelName => 'மாதிரியின் பெயர்';

  @override
  String settingsOnDeviceModel(String name) {
    return 'சாதனத்தில் உள்ள மாதிரி — $name';
  }

  @override
  String settingsReadyKept(int mb) {
    return 'தயார் · $mb MB · ஆப்பில் சேமிக்கப்பட்டுள்ளது (நிறுவல் நீக்கும்போது அகற்றப்படும்)';
  }

  @override
  String settingsReadyOffline(int mb) {
    return 'தயார் · $mb MB · ஆஃப்லைனில் இயங்கும்';
  }

  @override
  String settingsInstallingBundled(int pct) {
    return 'தொகுக்கப்பட்ட மாதிரியை நிறுவுகிறது $pct%';
  }

  @override
  String settingsDownloadingPct(int pct) {
    return 'பதிவிறக்குகிறது $pct%';
  }

  @override
  String get settingsBundledPreparing =>
      'செயலியுடன் தொகுக்கப்பட்டது · தயாராகிறது';

  @override
  String settingsNotDownloaded(int mb) {
    return 'பதிவிறக்கப்படவில்லை ($mb MB)';
  }

  @override
  String get settingsRemove => 'அகற்று';

  @override
  String settingsPercent(int pct) {
    return '$pct%';
  }

  @override
  String get settingsInstall => 'நிறுவு';

  @override
  String get settingsDownload => 'பதிவிறக்கு';

  @override
  String get settingsNoFilePicked => 'இன்னும் கோப்பு தேர்ந்தெடுக்கப்படவில்லை';

  @override
  String get settingsScanHint =>
      'இந்த தொலைபேசியில் ஏற்கனவே உள்ள மாதிரி கோப்பை ஸ்கேன் செய்யவும்.';

  @override
  String settingsCustomModelMeta(String path, int mb, int tokens) {
    return '$path · $mb MB · $tokens டோக்கன்கள்';
  }

  @override
  String get settingsForget => 'மற';

  @override
  String get settingsAllFilesAccess =>
      'Android அமைப்புகளில் Scam Shield க்கு \"அனைத்து கோப்புகளுக்கான அணுகல்\" அனுமதிக்கவும், பின்னர் மீண்டும் ஸ்கேன் செய்யவும்.';

  @override
  String get settingsNoModelFiles =>
      '.litertlm அல்லது .task கோப்புகள் எதுவும் இல்லை.\n\nமேலே ஒரு மாதிரியைப் பதிவிறக்கவும் (அல்லது கீழே கோப்புப் பாதையைத் தட்டச்சு செய்யவும்) பின்னர் மீண்டும் ஸ்கேன் செய்யவும்.';

  @override
  String settingsFileSizeMb(int mb) {
    return '$mb MB';
  }

  @override
  String get settingsEnterPathFirst =>
      'முதலில் ஒரு மாதிரி கோப்பு பாதையை உள்ளிடவும்';

  @override
  String settingsModelLoaded(String name) {
    return '$name ஏற்றப்பட்டது';
  }

  @override
  String get settingsModelForgotten =>
      'தேர்ந்தெடுத்த மாதிரி மறக்கப்பட்டது — கோப்பு சாதனத்தில் வைக்கப்பட்டுள்ளது';

  @override
  String settingsSizeFromDevice(int mb) {
    return '~$mb MB · இந்த சாதனத்திலிருந்து';
  }

  @override
  String settingsSizeBundled(int mb) {
    return '~$mb MB · தொகுக்கப்பட்டது';
  }

  @override
  String settingsSizeDownload(int mb) {
    return '~$mb MB · பதிவிறக்கம்';
  }

  @override
  String settingsFieldSaved(String label) {
    return '$label சேமிக்கப்பட்டது';
  }

  @override
  String get settingsSave => 'சேமி';

  @override
  String get settingsLanguage => 'மொழி';

  @override
  String get settingsLanguageSystem => 'கணினி இயல்புநிலை';

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
  String get callBlock => 'தடு';

  @override
  String get callUnblock => 'தடை நீக்கு';

  @override
  String get callBlockAndReport => 'தடுத்து புகாரளி';

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
  String get callCheckNumber => 'இந்த எண்ணைச் சரிபார்';

  @override
  String get callChecking => 'எண் சரிபார்க்கப்படுகிறது...';

  @override
  String callCheckSafe(String number) {
    return '$number பாதுகாப்பாகத் தெரிகிறது';
  }

  @override
  String callCheckUnknown(String number) {
    return '$number க்கு புகார்கள் இல்லை';
  }

  @override
  String callCheckHighRisk(String number) {
    return '$number அதிக ஆபத்து உடையது';
  }

  @override
  String get callCheckFailed => 'இந்த எண்ணைச் சரிபார்க்க முடியவில்லை';

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
  String get reportPhone => 'தொலைபேசி';

  @override
  String get reportUnknownApp => 'தெரியாத செயலி';

  @override
  String get reportSent => 'புகார் அனுப்பப்பட்டது';

  @override
  String get reportNotSent =>
      'புகார் அனுப்பப்படவில்லை — புகார் இறுதிப்புள்ளி இன்னும் கட்டமைக்கப்படவில்லை';

  @override
  String get reportAddAppFirst => 'முதலில் ஒரு செயலியைச் சேர்க்கவும்.';

  @override
  String get reportAsScam => 'இந்த செய்தியை மோசடி என புகாரளிக்கவா?';

  @override
  String get reportSuspiciousMessages => 'சந்தேகத்திற்குரிய செய்திகள்';

  @override
  String get reportTapHint =>
      'மோசடி போல் தோன்றும் எதையும் “இதைப் புகாரளி” என்பதைத் தட்டவும்.';

  @override
  String get reportNothingSuspicious =>
      'இப்போது சந்தேகத்திற்குரியது எதுவும் இல்லை';

  @override
  String reportVerdictSummary(String label, int pct) {
    return '$label · $pct% உறுதி';
  }

  @override
  String get reportRecentCalls => 'சமீபத்திய அழைப்புகள்';

  @override
  String get reportNoCalls => 'இன்னும் அழைப்புகள் பதிவு செய்யப்படவில்லை';

  @override
  String get reportSomethingElse => 'வேறு ஏதாவது புகாரளி';

  @override
  String get reportWriteOwn => 'உங்கள் சொந்த புகாரை எழுதுங்கள்';

  @override
  String get reportNumberOptional => 'எண் (விருப்பத்திற்குரியது)';

  @override
  String get reportAppRequired => 'செயலி (தேவை)';

  @override
  String get reportAppHint => 'WhatsApp, Telegram, தொலைபேசி…';

  @override
  String get reportMarkAs => 'இப்படி குறி';

  @override
  String get reportSpam => 'ஸ்பேம்';

  @override
  String get reportScam => 'மோசடி';

  @override
  String get reportOther => 'மற்றவை';

  @override
  String get reportReason => 'காரணம்';

  @override
  String get reportReasonHint => 'அவர்கள் என்ன செய்தார்கள் அல்லது சொன்னார்கள்?';

  @override
  String get reportOtherComments => 'பிற கருத்துகள்';

  @override
  String get reportOtherCommentsHint =>
      'நாங்கள் தெரிந்து கொள்ள வேண்டிய வேறு ஏதாவது (விருப்பத்திற்குரியது)';

  @override
  String get reportSubmit => 'புகாரைச் சமர்ப்பி';

  @override
  String reportSubjectTitle(String subject) {
    return '$subject புகாரளிக்கவா?';
  }

  @override
  String get reportReasonOptional => 'காரணம் (விருப்பத்திற்குரியது)';

  @override
  String get shieldTurnOnToRun => 'மாதிரியை இயக்க பாதுகாப்பை இயக்கவும்';

  @override
  String get shieldCheckingMessage => 'செய்தியைச் சரிபார்க்கிறது...';

  @override
  String get shieldScamAi => 'மோசடி AI';

  @override
  String get shieldModelReady => 'சாதனத்தில் உள்ள மாதிரி தயார்';

  @override
  String get shieldNoModel => 'சாதனத்தில் மாதிரி எதுவும் நிறுவப்படவில்லை';

  @override
  String shieldStats(int evaluated, int alerts) {
    return '$evaluated செய்திகள் சரிபார்க்கப்பட்டன, $alerts எச்சரிக்கைகள் எழுப்பப்பட்டன';
  }

  @override
  String get shieldTryMessage => 'ஒரு செய்தியை முயற்சிக்கவும்';

  @override
  String get shieldPasteHint => 'சந்தேகத்திற்குரிய செய்தியை ஒட்டவும்...';

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
  String contactsLoadFailed(String error) {
    return 'தொடர்புகளை ஏற்ற முடியவில்லை: $error';
  }

  @override
  String get contactsTitle => 'தொடர்புகள்';

  @override
  String get contactsOpenMenu => 'மெனுவைத் திற';

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
  String contactsCouldNotCallError(String error) {
    return 'அழைப்பைத் தொடங்க முடியவில்லை: $error';
  }

  @override
  String get safetyTitle => 'பாதுகாப்பு';

  @override
  String get safetyRecentAlerts => 'சமீபத்திய எச்சரிக்கைகள்';

  @override
  String get safetyProtectedOn => 'நீங்கள் பாதுகாக்கப்படுகிறீர்கள்';

  @override
  String get safetyProtectedOff => 'பாதுகாப்பு அணைக்கப்பட்டுள்ளது';

  @override
  String get safetyDownloadFirstPeriod =>
      'முதலில் அமைப்புகள் தாவலில் ஒரு மாதிரியைப் பதிவிறக்கவும்.';

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
  String get protectionChecked => 'சரிபார்க்கப்பட்டது';

  @override
  String get protectionAlerts => 'எச்சரிக்கைகள்';

  @override
  String get protectionOn => 'பாதுகாப்பு இயக்கத்தில் உள்ளது';

  @override
  String get protectionOff => 'பாதுகாப்பு அணைக்கப்பட்டுள்ளது';

  @override
  String get protectionReadsNotifications =>
      'செய்தியிடல் செயலிகளிலிருந்து அறிவிப்புகளைப் படிக்கிறது';

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
  String get notificationsTestTitle => 'Test the on-device AI';

  @override
  String get notificationsTestHint => 'Paste or type a message to check';

  @override
  String get notificationsTestRun => 'Check message';

  @override
  String get notificationsTestServiceOff =>
      'Turn protection on first so the model can run the check.';

  @override
  String get notificationsTestSent =>
      'Checking… the result will appear below once the model finishes.';

  @override
  String settingsScreenModelInstalled(String name) {
    return '$name நிறுவப்பட்டது';
  }

  @override
  String get settingsScreenTitle => 'அமைப்புகள்';

  @override
  String get settingsScreenModelTab => 'மாதிரி';

  @override
  String get settingsScreenPermissionsTab => 'அனுமதிகள்';

  @override
  String get loginAppName => 'Call Manager';

  @override
  String get loginTagline =>
      'மோசடி அழைப்புகள் மற்றும் செய்திகளிலிருந்து உங்களைப் பாதுகாக்கிறது.';

  @override
  String get loginGetStarted => 'தொடங்கு';

  @override
  String get onboardingTitle => 'அனுமதிகள்';

  @override
  String get onboardingContinue => 'தொடர்';

  @override
  String get onboardingBack => 'பின்செல்';

  @override
  String get onboardingStart => 'தொடங்குவோம்';

  @override
  String get onboardingNext => 'அடுத்து';

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
  String get authGateMessage => 'தொடர உள்நுழையவும்';

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
  String postDetailShowMoreReplies(int count) {
    return 'மேலும் $count பதில்களைக் காட்டவும்';
  }

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
  String get tourMyPostsTitle => 'எனது இடுகைகள்';

  @override
  String get tourMyPostsBody =>
      'நீங்கள் புகாரளிக்கும் அனைத்தும் இங்கே வரும். விவாதத்தைக் கண்காணித்து, ஒரு மதிப்பீட்டாளர் உங்கள் இடுகையை மதிப்பாய்வு செய்தபோது பார்க்கவும்.';

  @override
  String get tourProfileTitle => 'உங்கள் சுயவிவரம்';

  @override
  String get tourProfileBody =>
      'உங்கள் கணக்கு விவரங்களையும், இங்கே நீங்கள் புகாரளித்த மோசடிகளையும் பார்க்கவும்.';

  @override
  String get tourSettingsTitle => 'அமைப்புகள்';

  @override
  String get tourSettingsBody =>
      'ஒரு பாதுகாப்பு மாதிரியைப் பதிவிறக்கவும், அனுமதிகளை நிர்வகிக்கவும், கணக்கு பிரிவிலிருந்து எந்த நேரத்திலும் இந்த சுற்றுப்பயணத்தை மீண்டும் இயக்கவும்.';

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
}
