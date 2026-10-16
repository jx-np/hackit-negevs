// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonReport => 'Report';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonReviewed => 'Reviewed';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonReportThis => 'Report this';

  @override
  String get commonNoPostsYet => 'No posts yet';

  @override
  String get commonShareWithCommunity => 'Share with community';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSharing => 'Sharing...';

  @override
  String get commonDownloadModelFirst =>
      'Download a model in the Settings tab first';

  @override
  String get commonTitle => 'Title';

  @override
  String get commonTitleHint => 'A short summary';

  @override
  String get commonMessage => 'Message';

  @override
  String get commonMessageHint => 'Paste the scam message here';

  @override
  String get commonWhatKindOfScam => 'What kind of scam?';

  @override
  String get commonTagsOptional => 'Tags (optional)';

  @override
  String get commonShareIntro =>
      'Help others by sharing a scam you received. Remove any personal details first.';

  @override
  String get commonPhotos => 'Photos (optional)';

  @override
  String get commonAddPhoto => 'Add photo';

  @override
  String get commonRemovePhoto => 'Remove photo';

  @override
  String get commonImageTooLarge => 'Each image must be 10 MB or smaller.';

  @override
  String get reportTabPhotoProcessing => 'Analyzing...';

  @override
  String get reportTabPhotoReady => 'Ready';

  @override
  String get reportTabPhotoFailed => 'Couldn\'t analyze';

  @override
  String get reportTabPhotoDropped =>
      'Some photos couldn\'t be analyzed and were removed.';

  @override
  String get reportTabProcessingTitle =>
      'Do not close the application. Processing';

  @override
  String get reportTabSignInToAddPhotos => 'Sign in to attach photos.';

  @override
  String get reportTabFailedDialogTitle => 'Some photos couldn\'t be analyzed';

  @override
  String reportTabFailedDialogBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count photos failed to upload or analyze. Retry them, or post without them?',
      one: '1 photo failed to upload or analyze. Retry it, or post without it?',
    );
    return '$_temp0';
  }

  @override
  String get reportTabFailedRetry => 'Retry';

  @override
  String get reportTabFailedPostWithout => 'Post without photos';

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
  String get homeTitle => 'Home';

  @override
  String get homeWelcomePrefix => 'Welcome, ';

  @override
  String get homeWelcomeGuestLabel => 'not signed in';

  @override
  String get homeWelcomeGuest => 'Welcome';

  @override
  String get myProfileTitle => 'My Profile';

  @override
  String get myProfileAccountSection => 'Account details';

  @override
  String get myProfileName => 'Name';

  @override
  String get myProfileEmail => 'Email';

  @override
  String get myProfileMemberSince => 'Member since';

  @override
  String get myProfilePosts => 'Posts';

  @override
  String get myProfileRole => 'Role';

  @override
  String get myProfileRoleResident => 'Member';

  @override
  String get myProfileRoleModerator => 'Moderator';

  @override
  String get myProfileRoleAdmin => 'Administrator';

  @override
  String get myProfileSignOut => 'Sign out';

  @override
  String get myProfileSignOutHint => 'You can sign back in at any time';

  @override
  String get myProfileNotSignedInTitle => 'You\'re not signed in';

  @override
  String get myProfileNotSignedInBody =>
      'Sign in to see your account details and manage your profile.';

  @override
  String get myProfileSignIn => 'Sign in';

  @override
  String get homeNewsTitle => 'Scam alerts & news';

  @override
  String get homeNewsError => 'Couldn\'t load the latest alerts.';

  @override
  String get homeNewsRetry => 'Try again';

  @override
  String get homeQuickActionsTitle => 'What would you like to do?';

  @override
  String get homeActionMyPosts => 'My posts';

  @override
  String get homeActionMyPostsBody => 'Track the scams you\'ve reported';

  @override
  String get homeActionProfile => 'My profile';

  @override
  String get homeActionProfileBody => 'See your details and your posts';

  @override
  String get homeActionCalls => 'Recent calls';

  @override
  String get homeActionCallsBody => 'Review calls from unknown numbers';

  @override
  String get homeActionReport => 'Report a scam';

  @override
  String get homeActionReportBody => 'Warn others in the community';

  @override
  String get homeActionSafety => 'Protection';

  @override
  String get homeActionSafetyBody => 'Turn on Scam Shield';

  @override
  String get homeStatusOnBody => 'We are checking your messages for scams.';

  @override
  String get homeStatusOffBody =>
      'Turn it on so we can warn you about scam messages.';

  @override
  String get homeStatusProblemTitle => 'Protection needs attention';

  @override
  String get homeStatusProblemBody =>
      'Something went wrong. Tap below to fix it.';

  @override
  String get homeStatusStartingTitle => 'Getting ready';

  @override
  String get homeStatusStartingBody =>
      'Protection is starting up. This can take a minute.';

  @override
  String get homeStatusOpen => 'See details';

  @override
  String get homeStatusFix => 'Fix it now';

  @override
  String get homeNewsReadMore => 'Read more';

  @override
  String get homeNewsClose => 'Close';

  @override
  String homeNewsCount(Object current, Object total) {
    return '$current of $total';
  }

  @override
  String get homeNewsPrevious => 'Previous alert';

  @override
  String get homeNewsNext => 'Next alert';

  @override
  String get settingsDetectionModel => 'Detection model';

  @override
  String get settingsProtection => 'Protection';

  @override
  String get settingsClearNotifications => 'Clear captured notifications';

  @override
  String get settingsStopProtection => 'Stop background protection';

  @override
  String get settingsServiceRunning => 'Service running';

  @override
  String get settingsServiceStopped => 'Service stopped';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsShowTutorial => 'Show tutorial again';

  @override
  String get settingsReplayTour => 'Replay the app feature overview';

  @override
  String get settingsLogOut => 'Log out';

  @override
  String get settingsSignOutSubtitle => 'Sign out of your account';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsAdvancedSubtitle => 'Developer and model-tuning options';

  @override
  String get settingsModelFromDevice => 'Model from this device (testing)';

  @override
  String get settingsScanForModels => 'Scan for model files';

  @override
  String get settingsScanningStorage => 'Scanning storage…';

  @override
  String get settingsScanSubtitle =>
      'Finds .litertlm and .task files the app has already downloaded';

  @override
  String get settingsModelFilePath => 'Model file path';

  @override
  String get settingsModelFilePathHelper =>
      'Typed paths work too. The file is used in place — it is never copied.';

  @override
  String get settingsContextWindow => 'Context window (tokens)';

  @override
  String settingsContextWindowHelper(int max) {
    return 'Context to request when loading. Must not exceed what your conversion baked in as kv_cache_max_len (MiniCPM5-2B supports up to $max). Larger windows cost roughly 40 KB of RAM per token.';
  }

  @override
  String settingsContextRange(int max) {
    return 'Enter between 1024 and $max';
  }

  @override
  String get settingsThinking => 'Thinking (reasoning)';

  @override
  String get settingsThinkingHelper =>
      'Lets the model reason before answering. Uses more tokens and is slower; needs a 3000+ token context to be useful.';

  @override
  String get settingsLoadModelFromFile => 'Load model from file';

  @override
  String settingsCloudThreshold(int pct) {
    return 'Cloud escalation threshold — escalate below $pct%';
  }

  @override
  String get settingsCloudReview => 'Cloud review';

  @override
  String get settingsForceCloud => 'Force cloud';

  @override
  String get settingsForceCloudHelper =>
      'Send every message to the cloud model and skip the on-device model. Falls back to on-device only if the cloud is unreachable.';

  @override
  String get settingsEndpoint => 'Endpoint';

  @override
  String get settingsEndpointHint =>
      'https://.../v1/chat/completions (empty = disabled)';

  @override
  String get settingsModelName => 'Model name';

  @override
  String settingsOnDeviceModel(String name) {
    return 'On-device model — $name';
  }

  @override
  String settingsReadyKept(int mb) {
    return 'Ready · $mb MB · stored in the app (removed on uninstall)';
  }

  @override
  String settingsReadyOffline(int mb) {
    return 'Ready · $mb MB · runs offline';
  }

  @override
  String settingsInstallingBundled(int pct) {
    return 'Installing bundled model $pct%';
  }

  @override
  String settingsDownloadingPct(int pct) {
    return 'Downloading $pct%';
  }

  @override
  String get settingsBundledPreparing => 'Bundled with the app · preparing';

  @override
  String settingsNotDownloaded(int mb) {
    return 'Not downloaded ($mb MB)';
  }

  @override
  String get settingsRemove => 'Remove';

  @override
  String settingsPercent(int pct) {
    return '$pct%';
  }

  @override
  String get settingsInstall => 'Install';

  @override
  String get settingsDownload => 'Download';

  @override
  String get settingsNoFilePicked => 'No file picked yet';

  @override
  String get settingsScanHint =>
      'Scan for a model file that is already on this phone.';

  @override
  String settingsCustomModelMeta(String path, int mb, int tokens) {
    return '$path · $mb MB · $tokens tokens';
  }

  @override
  String get settingsForget => 'Forget';

  @override
  String get settingsAllFilesAccess =>
      'Allow \"All files access\" for Scam Shield in Android settings, then scan again.';

  @override
  String get settingsNoModelFiles =>
      'No .litertlm or .task files found.\n\nDownload a model above (or type a file path below) and scan again.';

  @override
  String settingsFileSizeMb(int mb) {
    return '$mb MB';
  }

  @override
  String get settingsEnterPathFirst => 'Enter a model file path first';

  @override
  String settingsModelLoaded(String name) {
    return '$name loaded';
  }

  @override
  String get settingsModelForgotten =>
      'Picked model forgotten — file kept on device';

  @override
  String settingsSizeFromDevice(int mb) {
    return '~$mb MB · from this device';
  }

  @override
  String settingsSizeBundled(int mb) {
    return '~$mb MB · bundled';
  }

  @override
  String settingsSizeDownload(int mb) {
    return '~$mb MB · download';
  }

  @override
  String settingsFieldSaved(String label) {
    return '$label saved';
  }

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String callIncoming(String who) {
    return 'Incoming call: $who';
  }

  @override
  String callBlocked(String number) {
    return 'Blocked $number';
  }

  @override
  String callUnblocked(String number) {
    return 'Unblocked $number';
  }

  @override
  String callReported(String number) {
    return 'Reported $number';
  }

  @override
  String get callOutgoing => 'Outgoing';

  @override
  String get callAnswered => 'Answered';

  @override
  String get callRejected => 'Rejected';

  @override
  String get callMissed => 'Missed';

  @override
  String get callBlockedLabel => 'Blocked';

  @override
  String get callHistoryTitle => 'Call History';

  @override
  String get callBlockedNumbers => 'Blocked numbers';

  @override
  String get callNoUnknown => 'No unknown-number calls found';

  @override
  String get callPhonePermNeeded => 'Phone permission needed';

  @override
  String get callPhonePermBody =>
      'Call Manager needs the Phone permission to read your call history.';

  @override
  String get callGrantPhone => 'Grant phone permission';

  @override
  String get callCouldNotLoad => 'Could not load call history';

  @override
  String callDurationSuffix(int seconds) {
    return ' • ${seconds}s';
  }

  @override
  String get callReportedSuffix => ' • Reported';

  @override
  String get callBlock => 'Block';

  @override
  String get callUnblock => 'Unblock';

  @override
  String get callBlockAndReport => 'Block & Report';

  @override
  String get callBlockNeedsScreening =>
      'To stop blocked numbers from ringing, choose this app for call screening.';

  @override
  String get callHighRiskTitle => 'High-risk caller';

  @override
  String get callHighRiskBody =>
      'This number has been reported as a scam. Do not share personal details or money.';

  @override
  String callHighRiskScore(int score) {
    return 'Trust score: $score/100';
  }

  @override
  String callHighRiskReports(int count) {
    return 'Reported $count times';
  }

  @override
  String get callHighRiskDismiss => 'Dismiss';

  @override
  String get callCheckNumber => 'Check this number';

  @override
  String get callChecking => 'Checking number...';

  @override
  String callCheckSafe(String number) {
    return '$number looks safe';
  }

  @override
  String callCheckUnknown(String number) {
    return 'No reports for $number';
  }

  @override
  String callCheckHighRisk(String number) {
    return '$number is high risk';
  }

  @override
  String get callCheckFailed => 'Could not check this number';

  @override
  String get callCheckTitle => 'Number check';

  @override
  String get callCheckNumberLabel => 'Number checked';

  @override
  String get callCheckResultHighRisk => 'High risk';

  @override
  String get callCheckResultUnknown => 'No reports';

  @override
  String get callCheckResultSafe => 'Looks safe';

  @override
  String get callCheckResultFailed => 'Check failed';

  @override
  String get callCheckDetailHighRisk =>
      'This number has been reported as a scam. Do not share personal details or money.';

  @override
  String get callCheckDetailUnknown =>
      'We have no scam reports for this number yet. Stay cautious with unknown callers.';

  @override
  String get callCheckDetailSafe =>
      'This number has a good reputation. Stay alert if anything feels off.';

  @override
  String get callCheckDetailFailed =>
      'We couldn\'t check this number right now. Check your connection and try again.';

  @override
  String callCheckScore(int score) {
    return 'Trust score: $score/100';
  }

  @override
  String callCheckReports(int count) {
    return 'Reported $count times';
  }

  @override
  String get reportPhone => 'Phone';

  @override
  String get reportUnknownApp => 'Unknown app';

  @override
  String get reportSent => 'Report sent';

  @override
  String get reportNotSent =>
      'Report not sent — reporting endpoint is not configured yet';

  @override
  String get reportAddAppFirst => 'Add an application first.';

  @override
  String get reportAsScam => 'Report this message as a scam?';

  @override
  String get reportSuspiciousMessages => 'Suspicious messages';

  @override
  String get reportTapHint =>
      'Tap “Report this” on anything that looks like a scam.';

  @override
  String get reportNothingSuspicious => 'Nothing suspicious right now';

  @override
  String reportVerdictSummary(String label, int pct) {
    return '$label · $pct% sure';
  }

  @override
  String get reportRecentCalls => 'Recent calls';

  @override
  String get reportNoCalls => 'No calls recorded yet';

  @override
  String get reportSomethingElse => 'Report something else';

  @override
  String get reportWriteOwn => 'Write your own report';

  @override
  String get reportNumberOptional => 'Number (optional)';

  @override
  String get reportAppRequired => 'Application (required)';

  @override
  String get reportAppHint => 'WhatsApp, Telegram, Phone…';

  @override
  String get reportMarkAs => 'Mark as';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportScam => 'Scam';

  @override
  String get reportOther => 'Other';

  @override
  String get reportReason => 'Reason';

  @override
  String get reportReasonHint => 'What did they do or say?';

  @override
  String get reportOtherComments => 'Other comments';

  @override
  String get reportOtherCommentsHint =>
      'Anything else we should know (optional)';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String reportSubjectTitle(String subject) {
    return 'Report $subject?';
  }

  @override
  String get reportReasonOptional => 'Reason (optional)';

  @override
  String get shieldTurnOnToRun => 'Turn on protection to run the model';

  @override
  String get shieldCheckingMessage => 'Checking the message...';

  @override
  String get shieldScamAi => 'Scam AI';

  @override
  String get shieldModelReady => 'On-device model ready';

  @override
  String get shieldNoModel => 'No on-device model installed';

  @override
  String shieldStats(int evaluated, int alerts) {
    return 'Checked $evaluated messages, raised $alerts alerts';
  }

  @override
  String get shieldTryMessage => 'Try a message';

  @override
  String get shieldPasteHint => 'Paste a suspicious message...';

  @override
  String get shieldCheck => 'Check';

  @override
  String get permDenied => 'Permission denied';

  @override
  String get permConfirmScreening => 'Confirm Call Manager for call screening';

  @override
  String get permScreeningUnavailable =>
      'Call screening is not available on this device';

  @override
  String get permNotificationAccess => 'Notification access';

  @override
  String get permNotificationAccessSub => 'Reads messages from notifications';

  @override
  String get permOverlay => 'Display over other apps';

  @override
  String get permOverlaySub => 'Shows the scam alert while a call is ringing';

  @override
  String get permAlerts => 'Alerts allowed';

  @override
  String get permAlertsSub => 'Posts scam alerts as notifications';

  @override
  String get permBackground => 'Run in the background';

  @override
  String get permBackgroundSub =>
      'Ignore battery optimizations so protection keeps running';

  @override
  String get permBatterySettings => 'Battery optimization settings';

  @override
  String get permBatterySettingsSub =>
      'Some phones throttle apps anyway. Open the list and set this app to \"Don\'t optimize\".';

  @override
  String get permGranted => 'Granted';

  @override
  String get permGrant => 'Grant';

  @override
  String get permScreeningRole => 'Call screening role';

  @override
  String get permScreeningRoleSub =>
      'Lets the app screen incoming calls and block numbers you mark as spam.';

  @override
  String get permScreeningActive => 'Screening active';

  @override
  String get permEnableScreening => 'Enable call screening';

  @override
  String get permScreeningNotGranted => 'Call screening is not granted yet';

  @override
  String get permScreeningTapHint =>
      'Tap \"Enable call screening\" above, otherwise calls will still ring through.';

  @override
  String get permTitle => 'Permissions';

  @override
  String get permGrantFollowing =>
      'Grant the following permissions for full access.';

  @override
  String get permPhoneCallLog => 'Phone & Call Log';

  @override
  String get permPhoneGranted => 'Phone permission granted';

  @override
  String get permContacts => 'Contacts';

  @override
  String get permContactsGranted => 'Contacts permission granted';

  @override
  String get permNotifications => 'Notifications';

  @override
  String get permNotificationsGranted => 'Notification permission granted';

  @override
  String get permStillNotWorking => 'Still not working?';

  @override
  String get permOpenSettingsBody =>
      'Open the system settings for this app to manually assign the call screening role and permissions.';

  @override
  String get permOpenAppSettings => 'Open App Settings';

  @override
  String get permNotChecked => 'Not checked';

  @override
  String get permStatusDenied => 'Denied';

  @override
  String get permPermanentlyDenied => 'Permanently denied';

  @override
  String get permNotGranted => 'Not granted';

  @override
  String get contactsPermRequired =>
      'Contacts permission is required to view contacts';

  @override
  String contactsLoadFailed(String error) {
    return 'Failed to load contacts: $error';
  }

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsOpenMenu => 'Open menu';

  @override
  String get contactsSearchHint => 'Search contacts...';

  @override
  String get contactsCouldNotLoad => 'Could not load contacts';

  @override
  String get contactsNoneFound => 'No contacts found';

  @override
  String get contactsNoDetails => 'No details';

  @override
  String get contactsCouldNotCall => 'Could not initiate call';

  @override
  String contactsCouldNotCallError(String error) {
    return 'Could not initiate call: $error';
  }

  @override
  String get safetyTitle => 'Safety';

  @override
  String get safetyRecentAlerts => 'Recent alerts';

  @override
  String get safetyProtectedOn => 'You are protected';

  @override
  String get safetyProtectedOff => 'Protection is off';

  @override
  String get safetyDownloadFirstPeriod =>
      'Download a model in the Settings tab first.';

  @override
  String get safetyWeCheck => 'We check your messages for scams.';

  @override
  String get safetyTurnOnToCheck => 'Turn this on to check messages for scams.';

  @override
  String get safetyTurnOff => 'Turn protection off';

  @override
  String get safetyTurnOn => 'Turn protection on';

  @override
  String get safetyPressToStart => 'Press to start';

  @override
  String get safetyDownloadingModel => 'Downloading model…';

  @override
  String get safetySettingUpModel => 'Setting up the model…';

  @override
  String get safetyNoScams => 'No scams found';

  @override
  String get safetyNoScamsBody => 'Suspicious messages will show up here.';

  @override
  String get protectionChecked => 'Checked';

  @override
  String get protectionAlerts => 'Alerts';

  @override
  String get protectionOn => 'Protection is on';

  @override
  String get protectionOff => 'Protection is off';

  @override
  String get protectionReadsNotifications =>
      'Reads notifications from messaging apps';

  @override
  String activityAll(int count) {
    return 'All ($count)';
  }

  @override
  String activityScams(int count) {
    return 'Scams ($count)';
  }

  @override
  String activityUnchecked(int count) {
    return 'Unchecked ($count)';
  }

  @override
  String get activityNoMessages => 'No messages captured yet.';

  @override
  String get activityNotCheckedSuffix => ' · not checked';

  @override
  String get activityCloudSuffix => ' · cloud';

  @override
  String get activityNotCheckedYet => 'Not checked yet.';

  @override
  String get activityVerdict => 'Verdict';

  @override
  String get activityConfidence => 'Confidence';

  @override
  String get activityCheckedBy => 'Checked by';

  @override
  String activityEscalatedSuffix(String wire) {
    return '$wire (escalated)';
  }

  @override
  String get activityReason => 'Reason';

  @override
  String get activityAiThinking => 'AI thinking';

  @override
  String get activityNoOutput => '(the model produced no readable output)';

  @override
  String get blockedNumbersTitle => 'Blocked Numbers';

  @override
  String get blockedNoNumbers => 'No blocked numbers';

  @override
  String get notificationsTitle => 'Notifications';

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
    return '$name installed';
  }

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsScreenModelTab => 'Model';

  @override
  String get settingsScreenPermissionsTab => 'Permissions';

  @override
  String get loginAppName => 'Call Manager';

  @override
  String get loginTagline => 'Keeps you safe from scam calls and messages.';

  @override
  String get loginGetStarted => 'Get Started';

  @override
  String get onboardingTitle => 'Permissions';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingStart => 'Let\'s begin';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingAllow => 'Allow';

  @override
  String get onboardingOpenSettings => 'Open settings';

  @override
  String get onboardingNotNow => 'Not now';

  @override
  String get onboardingFinish => 'Go to the app';

  @override
  String onboardingStepCount(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Welcome';

  @override
  String get onboardingWelcomeBody =>
      'This app helps you spot scam calls and messages. To do that, it needs a few permissions from your phone. We will go through them one at a time.';

  @override
  String get onboardingWelcomeNote =>
      'Everything stays on your phone. You can change these choices at any time in Settings.';

  @override
  String get onboardingPhoneTitle => 'Phone calls';

  @override
  String get onboardingPhoneBody =>
      'This lets the app see who is calling you, so it can tell you if a number is known for scams.';

  @override
  String get onboardingContactsTitle => 'Contacts';

  @override
  String get onboardingContactsBody =>
      'This lets the app recognise people you already know, so their calls are never marked as suspicious.';

  @override
  String get onboardingScreeningTitle => 'Call checking';

  @override
  String get onboardingScreeningBody =>
      'This lets the app check incoming calls and quietly stop numbers you have blocked. Your phone will ask you to choose this app for call screening.';

  @override
  String get onboardingNotificationsTitle => 'Alerts';

  @override
  String get onboardingNotificationsBody =>
      'This lets the app send you a short alert when something looks like a scam.';

  @override
  String get onboardingMessagesTitle => 'Message checking';

  @override
  String get onboardingMessagesBody =>
      'This lets the app read new messages as they arrive, so it can warn you about suspicious links or requests for money.';

  @override
  String get onboardingOverlayTitle => 'Show warnings during calls';

  @override
  String get onboardingOverlayBody =>
      'This lets the app show a small notice on your screen while a suspicious call is ringing.';

  @override
  String get onboardingBackgroundTitle => 'Keep running in the background';

  @override
  String get onboardingBackgroundBody =>
      'Let the app ignore battery optimizations so it can keep watching for scams even when your screen is off.';

  @override
  String get onboardingBatterySettingsTitle => 'Stop battery optimization';

  @override
  String get onboardingBatterySettingsBody =>
      'Some phones keep throttling apps even after the first prompt. Open the battery settings, find this app, and set it to \"Don\'t optimize\" so protection never stops.';

  @override
  String get onboardingSettingsHint =>
      'Your phone\'s settings will open. Find this app in the list, turn it on, then come back here.';

  @override
  String get onboardingStatusOn => 'This is turned on.';

  @override
  String get onboardingStatusSkipped =>
      'This is not turned on yet. You can try again, or turn it on later in Settings.';

  @override
  String get onboardingStatusBlocked =>
      'Your phone will not ask again. Tap \"Open settings\" to turn this on yourself.';

  @override
  String get onboardingDoneTitle => 'You\'re all set';

  @override
  String get onboardingDoneBody =>
      'The app is now looking out for scam calls and messages for you.';

  @override
  String get onboardingDonePartialTitle => 'Almost done';

  @override
  String get onboardingDonePartialBody =>
      'Some protections are not turned on yet. The app will still work, and you can turn the rest on later in Settings.';

  @override
  String onboardingGrantedCount(int granted, int total) {
    return '$granted of $total turned on';
  }

  @override
  String get authEnterEmail => 'Please enter your email.';

  @override
  String get authValidEmail => 'Please enter a valid email.';

  @override
  String get authEnterPassword => 'Please enter your password.';

  @override
  String get authPasswordLength => 'Use at least 8 characters.';

  @override
  String get authEnterName => 'Please enter your name.';

  @override
  String get authNameInvalid =>
      'Use letters and numbers only, with at most one space between two words.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authRegisterIntro =>
      'Join the community to share and learn about scams.';

  @override
  String get authLoginIntro => 'Sign in to post and join discussions.';

  @override
  String get authYourName => 'Your name';

  @override
  String get authYourNameHint => 'Enter your name';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authToggleToLogin => 'Already have an account? Sign in';

  @override
  String get authToggleToRegister => 'New here? Create an account';

  @override
  String get authGateMessage => 'Sign in to use this feature.';

  @override
  String get authGateTitle => 'Sign in to continue';

  @override
  String get authGateBody =>
      'This feature needs an account. Sign in to post to the community, sync your reports, and keep everything in one place.';

  @override
  String get authGateAction => 'Sign in';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityShareScam => 'Share a scam';

  @override
  String get communityAll => 'All';

  @override
  String get communityNoPostsBody =>
      'Scam reports shared by the community will show up here.';

  @override
  String get createChooseType => 'Please choose a scam type.';

  @override
  String get createAddTitle => 'Please add a title.';

  @override
  String get createAddMessage => 'Please add the message text.';

  @override
  String get reportTabTitle => 'Report';

  @override
  String get reportTabThankYou => 'Shared with the community. Thank you!';

  @override
  String get reportTabTrackIt =>
      'Shared with the community. Check My Profile to track it.';

  @override
  String get reportTabHeroTitle => 'Warn others about a scam';

  @override
  String get reportTabNumberHeroTitle => 'Report a phone number';

  @override
  String get reportTabNumberHeroBody =>
      'Tell us why this number is suspicious. Your report helps protect others.';

  @override
  String get reportTabPaste => 'Paste';

  @override
  String get reportTabPasteEmpty => 'Nothing to paste. Copy the message first.';

  @override
  String get reportTabNumberLabel => 'Phone number';

  @override
  String get reportTabNumberHint => 'e.g. +65 9123 4567';

  @override
  String get reportTabNumberRequired => 'Please enter the phone number.';

  @override
  String get reportTabReasonLabel => 'What happened?';

  @override
  String get reportTabReasonSpamBody => 'Unwanted calls or adverts';

  @override
  String get reportTabReasonScamBody =>
      'They tried to trick me or take my money';

  @override
  String get reportTabReasonOtherBody => 'Something else felt wrong';

  @override
  String get reportTabSuccessTitle => 'Thank you for helping';

  @override
  String get reportTabReportAnother => 'Report another';

  @override
  String get reportTabDone => 'Done';

  @override
  String get myPostsTitle => 'My posts';

  @override
  String get myPostsNoneBody =>
      'Scams you report will show up here so you can track them.';

  @override
  String get myPostsDelete => 'Delete';

  @override
  String get myPostsDeleteConfirm => 'Delete this post?';

  @override
  String get myPostsDeleteConfirmBody =>
      'This removes it from the community. This cannot be undone.';

  @override
  String get postDetailThankYou => 'Thank you. Our team will review this post.';

  @override
  String get postDetailTitle => 'Post';

  @override
  String get postDetailReportTooltip => 'Report this post';

  @override
  String postDetailComments(int count) {
    return 'Comments ($count)';
  }

  @override
  String get postDetailNoComments => 'No comments yet.';

  @override
  String get postDetailWriteComment => 'Write a comment';

  @override
  String get postDetailPostComment => 'Post comment';

  @override
  String get postDetailFlagPersonalInfo => 'Shows personal information';

  @override
  String get postDetailFlagHarmful => 'Harmful or dangerous';

  @override
  String get postDetailFlagSpam => 'Spam';

  @override
  String get postDetailFlagMisinfo => 'Misinformation';

  @override
  String get postDetailFlagOther => 'Other';

  @override
  String get postDetailReply => 'Reply';

  @override
  String get postDetailEdit => 'Edit';

  @override
  String get postDetailDelete => 'Delete';

  @override
  String get postDetailSave => 'Save';

  @override
  String get postDetailCancel => 'Cancel';

  @override
  String postDetailReplying(String name) {
    return 'Replying to $name';
  }

  @override
  String get postDetailWriteReply => 'Write a reply';

  @override
  String get postDetailDeleteConfirm => 'Delete this comment?';

  @override
  String get postDetailDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get postDetailEdited => 'edited';

  @override
  String get postDetailRemovedComment => 'This comment was removed.';

  @override
  String postDetailShowMoreReplies(int count) {
    return 'Show $count more replies';
  }

  @override
  String get guidanceClickedLink => 'I clicked a link';

  @override
  String get guidanceGotMessage => 'I just got a message';

  @override
  String get guidanceSharedPassword => 'I shared my password';

  @override
  String get guidanceSentMoney => 'I sent money';

  @override
  String get guidanceCouldNotOpenLink => 'Could not open the link.';

  @override
  String get guidanceCouldNotCall => 'Could not start the call.';

  @override
  String get guidanceTitle => 'Get help';

  @override
  String get guidanceWhatHappened => 'What happened?';

  @override
  String get guidanceWhoToContact => 'Who to contact';

  @override
  String get guidanceShowAll => 'Show all';

  @override
  String get guidanceOpenWebsite => 'Open website';

  @override
  String get guidanceNoAdvice => 'No advice yet';

  @override
  String get guidanceNoAdviceBody =>
      'Pick what happened above to see steps you can take.';

  @override
  String get tourHomeTitle => 'Home';

  @override
  String get tourHomeBody =>
      'This is your home screen. See the latest scam alerts and quickly get to everything the app can do.';

  @override
  String get tourCallsTitle => 'Calls';

  @override
  String get tourCallsBody =>
      'This is where calls from unknown numbers show up. Tap a call to see details, and use the block icon in the top corner to manage numbers you never want to hear from again.';

  @override
  String get tourSafetyTitle => 'Safety';

  @override
  String get tourSafetyBody =>
      'Turn on protection here. Once a model is downloaded, Scam Shield reads incoming messages on your device and warns you about likely scams.';

  @override
  String get tourReportTitle => 'Report';

  @override
  String get tourReportBody =>
      'Spotted a scam? Share it with the community from this tab so other people can recognise the same trick and stay safe.';

  @override
  String get tourMyPostsTitle => 'My Posts';

  @override
  String get tourMyPostsBody =>
      'Everything you report lands here. Track the discussion and see when a moderator has reviewed your post.';

  @override
  String get tourProfileTitle => 'Your Profile';

  @override
  String get tourProfileBody =>
      'See your account details and all your posts in one place. Open settings or sign out from the buttons at the top.';

  @override
  String get tourSettingsTitle => 'Settings';

  @override
  String get tourSettingsBody =>
      'Download a protection model, manage permissions, and replay this tour any time from the Account section.';

  @override
  String tourStepCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourDone => 'Done';

  @override
  String get tourNext => 'Next';
}
