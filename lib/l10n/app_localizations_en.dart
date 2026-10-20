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
  String get commonRetry => 'Try again';

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
  String get commonShareWithCommunity => 'Share';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSharing => 'Sharing…';

  @override
  String get commonTitle => 'Title';

  @override
  String get commonTitleHint => 'Short summary';

  @override
  String get commonMessage => 'Message';

  @override
  String get commonMessageHint => 'Paste the message';

  @override
  String get commonWhatKindOfScam => 'Scam type';

  @override
  String get commonShareIntro => 'Share a scam. Remove personal details first.';

  @override
  String get commonPhotos => 'Photos (optional)';

  @override
  String get commonAddPhoto => 'Add photo';

  @override
  String get commonRemovePhoto => 'Remove photo';

  @override
  String get commonImageTooLarge => 'Each image must be 10 MB or less.';

  @override
  String get reportTabPhotoProcessing => 'Checking…';

  @override
  String get reportTabPhotoFailed => 'Couldn\'t check';

  @override
  String get reportTabProcessingTitle => 'Processing. Don\'t close the app.';

  @override
  String get reportTabSignInToAddPhotos => 'Sign in to add photos.';

  @override
  String get reportTabFailedDialogTitle => 'Some photos failed';

  @override
  String reportTabFailedDialogBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos failed. Retry them, or post without them?',
      one: '1 photo failed. Retry it, or post without it?',
    );
    return '$_temp0';
  }

  @override
  String get reportTabFailedRetry => 'Try again';

  @override
  String get reportTabFailedPostWithout => 'Post without photos';

  @override
  String get reportTabWaitForImages => 'Wait for photos';

  @override
  String get reportTabCheckImages => 'Check photos';

  @override
  String get reportTabReviewCheckbox => 'I consent to posting these photos';

  @override
  String get reportTabEditImage => 'Edit photo';

  @override
  String get reportTabReuploading => 'Saving edited photo…';

  @override
  String get reportTabPosting => 'Posting…';

  @override
  String get reportTabEditorSaveFailed =>
      'Couldn\'t save the edited photo. Try again.';

  @override
  String get reportTabEditorLoadFailed =>
      'Couldn\'t open the photo. Try again.';

  @override
  String get reportTabViewPost => 'View your post';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeWelcomePrefix => 'Hi, ';

  @override
  String get homeWelcomeGuest => 'Hi';

  @override
  String get myProfileTitle => 'Profile';

  @override
  String get myProfileMemberSince => 'Member since';

  @override
  String get myProfilePosts => 'Posts';

  @override
  String get myProfileSignOut => 'Sign out';

  @override
  String get myProfileSignOutHint => 'You can sign in again any time';

  @override
  String get myProfileNotSignedInTitle => 'Not signed in';

  @override
  String get myProfileNotSignedInBody => 'Sign in to see your account.';

  @override
  String get myProfileSignIn => 'Sign in';

  @override
  String get homeNewsTitle => 'Scam alerts';

  @override
  String get homeNewsError => 'Couldn\'t load alerts.';

  @override
  String get homeNewsRetry => 'Try again';

  @override
  String get homeQuickActionsTitle => 'What do you want to do?';

  @override
  String get homeActionProfile => 'Profile';

  @override
  String get homeActionProfileBody => 'Your details and posts';

  @override
  String get homeActionCalls => 'Calls';

  @override
  String get homeActionCallsBody => 'Check calls from unknown numbers';

  @override
  String get homeActionReport => 'Report a scam';

  @override
  String get homeActionReportBody => 'Warn other people';

  @override
  String get homeStatusOnBody => 'Checking your messages for scams.';

  @override
  String get homeStatusOffBody => 'Turn on to get scam warnings.';

  @override
  String get homeStatusProblemTitle => 'Protection needs a fix';

  @override
  String get homeStatusProblemBody => 'Something is wrong. Tap to fix it.';

  @override
  String get homeStatusStartingTitle => 'Starting…';

  @override
  String get homeStatusStartingBody => 'This can take a minute.';

  @override
  String get homeStatusOpen => 'Details';

  @override
  String get homeStatusFix => 'Fix it';

  @override
  String get homeNewsReadMore => 'Read more';

  @override
  String get homeNewsClose => 'Close';

  @override
  String homeNewsCount(Object current, Object total) {
    return '$current of $total';
  }

  @override
  String get homeNewsPrevious => 'Previous';

  @override
  String get homeNewsNext => 'Next';

  @override
  String get settingsProtection => 'Protection';

  @override
  String get settingsStopProtection => 'Pause protection';

  @override
  String get settingsServiceRunning => 'On';

  @override
  String get settingsServiceStopped => 'Paused';

  @override
  String get settingsShowTutorial => 'Show tour again';

  @override
  String get settingsReplayTour => 'A quick tour of the app';

  @override
  String get settingsRemove => 'Remove';

  @override
  String settingsPercent(int pct) {
    return '$pct%';
  }

  @override
  String get settingsDownload => 'Download';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone default';

  @override
  String get settingsStatusTitle => 'Status';

  @override
  String get settingsGettingReady => 'Starting…';

  @override
  String get settingsNeedsDownload => 'Download needed';

  @override
  String settingsModelReady(String name) {
    return '$name is ready';
  }

  @override
  String settingsModelNotDownloaded(String name) {
    return '$name is not downloaded';
  }

  @override
  String settingsSettingUpPct(int pct) {
    return 'Setting up… $pct%';
  }

  @override
  String settingsSettingUpMb(int mb) {
    return 'Setting up… $mb MB';
  }

  @override
  String get settingsCheckerTitle => 'Scam checker';

  @override
  String get settingsCheckerCaption =>
      'Checks messages on your phone. Nothing leaves your phone.';

  @override
  String get settingsCheckingSupport => 'Checking your phone…';

  @override
  String get settingsNotAvailable => 'Not available on this phone';

  @override
  String get settingsReadyShort => 'Ready';

  @override
  String get settingsBuiltInSubtitle => 'Built in. No download.';

  @override
  String settingsAboutMb(int mb) {
    return 'About $mb MB';
  }

  @override
  String get settingsPrepare => 'Set up';

  @override
  String get settingsSpeedTitle => 'Speed';

  @override
  String get settingsSpeedCaption =>
      'Keep Automatic unless the checker has problems.';

  @override
  String get settingsSpeedAuto => 'Automatic';

  @override
  String get settingsSpeedAutoBody => 'Best for most phones';

  @override
  String get settingsSpeedCpu => 'Most compatible';

  @override
  String get settingsSpeedCpuBody => 'Works on all phones. Slowest.';

  @override
  String get settingsSpeedGpu => 'Faster';

  @override
  String get settingsSpeedGpuBody => 'Uses the graphics chip';

  @override
  String get settingsSpeedNpu => 'Fastest';

  @override
  String get settingsSpeedNpuBody => 'Newer phones only';

  @override
  String get settingsAppSection => 'App';

  @override
  String get settingsAppearance => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPermissionsSubtitle => 'See what the app can do';

  @override
  String get settingsSignInSubtitle => 'Needed to post';

  @override
  String get settingsProtectionOn => 'Protection is on';

  @override
  String get settingsProtectionOff => 'Protection is off';

  @override
  String get settingsProtectionNeedsModel => 'Protection needs a checker';

  @override
  String settingsSettingUpProgress(int pct, int got, int total) {
    return 'Setting up… $pct% · $got of $total MB';
  }

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get settingsTextNormal => 'Normal';

  @override
  String get settingsTextLarge => 'Large';

  @override
  String get settingsTextExtraLarge => 'Extra large';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutSubtitle => 'You can sign back in any time';

  @override
  String get settingsSignIn => 'Sign in';

  @override
  String callIncoming(String who) {
    return 'Call from $who';
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
  String get callRejected => 'Declined';

  @override
  String get callMissed => 'Missed';

  @override
  String get callBlockedLabel => 'Blocked';

  @override
  String get navHome => 'Home';

  @override
  String get navCalls => 'Calls';

  @override
  String get navSafety => 'Safety';

  @override
  String get navReport => 'Report';

  @override
  String get navProfile => 'Profile';

  @override
  String get callHistoryTitle => 'Calls';

  @override
  String get callBlockedNumbers => 'Blocked numbers';

  @override
  String get callNoUnknown => 'No calls from unknown numbers';

  @override
  String get callPhonePermNeeded => 'Allow phone access';

  @override
  String get callPhonePermBody => 'Needed to show calls and spot scams.';

  @override
  String get callGrantPhone => 'Allow';

  @override
  String get callCouldNotLoad => 'Couldn\'t show calls';

  @override
  String callDurationSuffix(int seconds) {
    return ' • ${seconds}s';
  }

  @override
  String get callReportedSuffix => ' • Reported';

  @override
  String get callUnblock => 'Unblock';

  @override
  String get callBlockNeedsScreening =>
      'To block calls, set this app as your call blocker.';

  @override
  String get callHighRiskTitle => 'Likely scam call';

  @override
  String get callHighRiskBody =>
      'People reported this number as a scam. Don\'t share money or personal details.';

  @override
  String callHighRiskScore(int score) {
    return 'Score: $score/100';
  }

  @override
  String callHighRiskReports(int count) {
    return '$count reports';
  }

  @override
  String get callHighRiskDismiss => 'Got it';

  @override
  String get callHighRiskBlock => 'This is a Scam – Block';

  @override
  String get callHighRiskSafe => 'It\'s Safe / Dismiss';

  @override
  String get callChecking => 'Checking…';

  @override
  String get callCheckTitle => 'Check number';

  @override
  String get callCheckNumberLabel => 'Number checked';

  @override
  String get callCheckResultHighRisk => 'Likely scam';

  @override
  String get callCheckResultUnknown => 'No reports';

  @override
  String get callCheckResultSafe => 'Looks safe';

  @override
  String get callCheckResultFailed => 'Couldn\'t check';

  @override
  String get callCheckDetailHighRisk =>
      'People reported this number as a scam. Don\'t call back.';

  @override
  String get callCheckDetailUnknown => 'No reports. Still be careful.';

  @override
  String get callCheckDetailSafe => 'Looks safe. Still be careful.';

  @override
  String get callCheckDetailFailed => 'Check your internet and try again.';

  @override
  String callCheckScore(int score) {
    return 'Score: $score/100';
  }

  @override
  String callCheckReports(int count) {
    return '$count reports';
  }

  @override
  String get reportNotSent => 'Could not send. Reporting is not set up yet.';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportScam => 'Scam';

  @override
  String get reportOther => 'Other';

  @override
  String get reportReason => 'Reason';

  @override
  String get shieldCheck => 'Check';

  @override
  String get permDenied => 'Permission denied';

  @override
  String get permConfirmScreening => 'Set this app as your call screener';

  @override
  String get permScreeningUnavailable =>
      'Call screening is not available on this phone';

  @override
  String get permNotificationAccess => 'Check messages';

  @override
  String get permNotificationAccessSub => 'Reads new messages for scams';

  @override
  String get permOverlay => 'Call warnings';

  @override
  String get permOverlaySub => 'Shows a warning during calls';

  @override
  String get permAlerts => 'Alerts';

  @override
  String get permAlertsSub => 'Sends scam alerts';

  @override
  String get permFullScreen => 'Full-screen alerts';

  @override
  String get permFullScreenSub => 'Wakes the screen when locked';

  @override
  String get permBackground => 'Keep running';

  @override
  String get permBackgroundSub => 'Works when the screen is off';

  @override
  String get permBatterySettings => 'Don\'t pause the app';

  @override
  String get permBatterySettingsSub => 'Set this app to \"Don\'t optimize\".';

  @override
  String get permGranted => 'On';

  @override
  String get permGrant => 'Turn on';

  @override
  String get permScreeningRole => 'Check calls';

  @override
  String get permScreeningRoleSub =>
      'Checks calls and blocks numbers you choose.';

  @override
  String get permScreeningActive => 'On';

  @override
  String get permEnableScreening => 'Turn on';

  @override
  String get permScreeningNotGranted => 'Call checking is off';

  @override
  String get permScreeningTapHint => 'Tap \"Turn on\" above.';

  @override
  String get permTitle => 'Permissions';

  @override
  String get permGrantFollowing => 'Turn these on for full protection.';

  @override
  String get permPhoneCallLog => 'Phone calls';

  @override
  String get permPhoneGranted => 'Phone access allowed';

  @override
  String get permContacts => 'Contacts';

  @override
  String get permContactsGranted => 'Contacts allowed';

  @override
  String get permNotifications => 'Notifications';

  @override
  String get permNotificationsGranted => 'Notifications allowed';

  @override
  String get permStillNotWorking => 'Still not working?';

  @override
  String get permOpenSettingsBody =>
      'Turn permissions on in your phone settings.';

  @override
  String get permOpenAppSettings => 'Open settings';

  @override
  String get permNotChecked => 'Not checked';

  @override
  String get permStatusDenied => 'Off';

  @override
  String get permPermanentlyDenied => 'Off. Turn on in settings';

  @override
  String get permNotGranted => 'Off';

  @override
  String get contactsPermRequired => 'Allow contacts to see your contacts.';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsSearchHint => 'Search name or number';

  @override
  String get contactsCouldNotLoad => 'Couldn\'t load contacts';

  @override
  String get contactsNoneFound => 'No contacts';

  @override
  String get contactsNoDetails => 'No details';

  @override
  String get contactsCouldNotCall => 'Couldn\'t start the call';

  @override
  String get safetyTitle => 'Safety';

  @override
  String get safetyRecentAlerts => 'Recent alerts';

  @override
  String get safetyProtectedOn => 'Protected';

  @override
  String get safetyProtectedOff => 'Protection off';

  @override
  String get safetyWeCheck => 'Checks your messages for scams.';

  @override
  String get safetyTurnOnToCheck => 'Turn on to check messages.';

  @override
  String get safetyTurnOff => 'Turn off protection';

  @override
  String get safetyTurnOn => 'Turn on protection';

  @override
  String get safetyPressToStart => 'Tap to start';

  @override
  String get safetyDownloadingModel => 'Downloading…';

  @override
  String get safetySettingUpModel => 'Setting up…';

  @override
  String get safetyNoScams => 'No scams';

  @override
  String get safetyNoScamsBody => 'Scams will show here.';

  @override
  String get safetyMeteredTitle => 'Use mobile data?';

  @override
  String safetyMeteredBody(int mb) {
    return 'Download is about $mb MB. Wi-Fi is better.';
  }

  @override
  String get safetyNotNow => 'Not now';

  @override
  String get safetyDownload => 'Download';

  @override
  String get safetyCouldNotStart => 'Couldn\'t start protection. Try again.';

  @override
  String get safetyShowMore => 'Show more';

  @override
  String get safetyShowLess => 'Show less';

  @override
  String get safetyPillOn => 'Protected';

  @override
  String get safetyPillOff => 'Off';

  @override
  String get safetyPillError => 'Fix needed';

  @override
  String get safetyPillChecking => 'Checking';

  @override
  String get safetyHeroOnBody => 'Checked on your phone.';

  @override
  String get protectionChecked => 'Checked';

  @override
  String get protectionAlerts => 'Alerts';

  @override
  String get protectionOn => 'Protection on';

  @override
  String get protectionOff => 'Protection off';

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
    return 'Not checked ($count)';
  }

  @override
  String get activityNoMessages => 'No messages yet.';

  @override
  String get activityNotCheckedSuffix => ' · not checked';

  @override
  String get activityCloudSuffix => ' · online';

  @override
  String get activityNotCheckedYet => 'Not checked yet.';

  @override
  String get activityVerdict => 'Result';

  @override
  String get activityConfidence => 'Confidence';

  @override
  String get activityCheckedBy => 'Checked by';

  @override
  String activityEscalatedSuffix(String wire) {
    return '$wire (online)';
  }

  @override
  String get activityReason => 'Reason';

  @override
  String get activityAiThinking => 'Full result';

  @override
  String get activityNoOutput => '(No result)';

  @override
  String get blockedNumbersTitle => 'Blocked numbers';

  @override
  String get blockedNoNumbers => 'No blocked numbers';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get activityTitle => 'Activity';

  @override
  String get notificationsTestTitle => 'Test a message';

  @override
  String get notificationsTestHint => 'Paste or type a message';

  @override
  String get notificationsTestRun => 'Check message';

  @override
  String get notificationsTestServiceOff => 'Turn on protection first.';

  @override
  String get notificationsTestSent => 'Checking. The result will show below.';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsScreenPermissionsTab => 'Permissions';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingAllow => 'Allow';

  @override
  String get onboardingOpenSettings => 'Open settings';

  @override
  String get onboardingNotNow => 'Not now';

  @override
  String get onboardingFinish => 'Open the app';

  @override
  String onboardingStepCount(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Stay safe from scams';

  @override
  String get onboardingWelcomeBody =>
      'We warn you about scam calls and messages.';

  @override
  String get onboardingWelcomeNote => 'Setup takes about a minute.';

  @override
  String get onboardingPhoneTitle => 'Phone calls';

  @override
  String get onboardingPhoneBody => 'See who is calling.';

  @override
  String get onboardingContactsTitle => 'Contacts';

  @override
  String get onboardingContactsBody =>
      'Calls from people you know are not flagged.';

  @override
  String get onboardingScreeningTitle => 'Check calls';

  @override
  String get onboardingScreeningBody =>
      'Check calls and block numbers you choose.';

  @override
  String get onboardingNotificationsTitle => 'Alerts';

  @override
  String get onboardingNotificationsBody => 'Get an alert for a possible scam.';

  @override
  String get onboardingMessagesTitle => 'Check messages';

  @override
  String get onboardingMessagesBody => 'Read new messages to find scams.';

  @override
  String get onboardingOverlayTitle => 'Call warnings';

  @override
  String get onboardingOverlayBody => 'Show a warning during a risky call.';

  @override
  String get onboardingFullScreenTitle => 'Full-screen alerts';

  @override
  String get onboardingFullScreenBody => 'Show warnings on a locked phone.';

  @override
  String get onboardingBackgroundTitle => 'Keep running';

  @override
  String get onboardingBackgroundBody =>
      'Keep checking when the screen is off.';

  @override
  String get onboardingBatterySettingsTitle => 'Don\'t pause the app';

  @override
  String get onboardingBatterySettingsBody =>
      'Stop your phone from pausing the app.';

  @override
  String get onboardingSettingsHint => 'Settings will open. Turn this app on.';

  @override
  String get onboardingStatusOn => 'On.';

  @override
  String get onboardingStatusSkipped =>
      'Off. You can turn it on later in Settings.';

  @override
  String get onboardingStatusBlocked =>
      'Tap \"Open settings\" to turn this on.';

  @override
  String get onboardingDoneTitle => 'You\'re all set';

  @override
  String get onboardingDoneBody => 'We are watching for scams.';

  @override
  String get onboardingDonePartialTitle => 'Almost done';

  @override
  String get onboardingDonePartialBody =>
      'Some things are off. Turn them on in Settings.';

  @override
  String onboardingGrantedCount(int granted, int total) {
    return '$granted of $total on';
  }

  @override
  String get onboardingWhy => 'Why?';

  @override
  String get onboardingScreeningWhy => 'Pick this app so calls can be checked.';

  @override
  String get onboardingMessagesWhy =>
      'We look for odd links or requests for money.';

  @override
  String get onboardingBatterySettingsHint =>
      'Settings will open. Choose \"Don\'t optimize\".';

  @override
  String get onboardingModelTitle => 'Scam checker';

  @override
  String get onboardingModelBody => 'Checks messages on your phone. Use Wi‑Fi.';

  @override
  String onboardingModelDownload(String size) {
    return 'Download ($size)';
  }

  @override
  String get onboardingModelDownloadShort => 'Download';

  @override
  String onboardingModelDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get onboardingModelKeepGoing => 'You can continue. It keeps going.';

  @override
  String get onboardingModelReady => 'Ready.';

  @override
  String get onboardingModelFailed => 'Download failed. Please try again.';

  @override
  String get onboardingModelMeteredTitle => 'Use mobile data?';

  @override
  String onboardingModelMeteredBody(String size) {
    return 'You\'re not on Wi‑Fi. This uses about $size.';
  }

  @override
  String get setupOpenSettingsFailed => 'Couldn\'t open settings.';

  @override
  String get authEnterEmail => 'Enter your email.';

  @override
  String get authValidEmail => 'Enter a valid email.';

  @override
  String get authEnterPassword => 'Enter your password.';

  @override
  String get authPasswordLength => 'Use at least 8 characters.';

  @override
  String get authEnterName => 'Enter your name.';

  @override
  String get authNameInvalid =>
      'Letters and numbers only. One space is allowed.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authRegisterIntro => 'Join to share scams.';

  @override
  String get authLoginIntro => 'Sign in to post and comment.';

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
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authToggleToLogin => 'Have an account? Sign in';

  @override
  String get authToggleToRegister => 'New? Create an account';

  @override
  String get authGateTitle => 'Sign in to continue';

  @override
  String get authGateBody => 'You need an account. It\'s free.';

  @override
  String get authGateAction => 'Sign in';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityShareScam => 'Share a scam';

  @override
  String get communityAll => 'All';

  @override
  String get communityNoPostsBody => 'Shared scams will show here.';

  @override
  String get createChooseType => 'Choose a scam type.';

  @override
  String get createAddTitle => 'Add a title.';

  @override
  String get createAddMessage => 'Add the message text.';

  @override
  String get reportTabTitle => 'Report';

  @override
  String get reportTabThankYou => 'Shared. Thank you!';

  @override
  String get reportTabTrackIt => 'Shared. See My Profile to track it.';

  @override
  String get reportTabHeroTitle => 'Warn others about a scam';

  @override
  String get reportTabNumberHeroTitle => 'Report a number';

  @override
  String get reportTabNumberHeroBody =>
      'Say why this number is suspicious. Your report helps others.';

  @override
  String get reportTabPaste => 'Paste';

  @override
  String get reportTabPasteEmpty => 'Nothing to paste. Copy the message first.';

  @override
  String get reportTabNumberLabel => 'Phone number';

  @override
  String get reportTabNumberHint => 'e.g. +65 9123 4567';

  @override
  String get reportTabNumberRequired => 'Enter the phone number.';

  @override
  String get reportTabReasonLabel => 'What happened?';

  @override
  String get reportTabReasonSpamBody => 'Unwanted calls or ads';

  @override
  String get reportTabReasonScamBody =>
      'They tried to trick me or take my money';

  @override
  String get reportTabReasonOtherBody => 'Something else was wrong';

  @override
  String get reportTabSuccessTitle => 'Thank you';

  @override
  String get reportTabReportAnother => 'Report another';

  @override
  String get reportTabDone => 'Done';

  @override
  String get myPostsTitle => 'My posts';

  @override
  String get myPostsNoneBody => 'Reports you share will show here.';

  @override
  String get myPostsDelete => 'Delete';

  @override
  String get myPostsDeleteConfirm => 'Delete this post?';

  @override
  String get myPostsDeleteConfirmBody =>
      'It will be removed for everyone. This can\'t be undone.';

  @override
  String get myPostsEdit => 'Edit';

  @override
  String get editPostTitle => 'Edit post';

  @override
  String get editPostSave => 'Save';

  @override
  String get editPostSaving => 'Saving…';

  @override
  String get editPostSaved => 'Saved.';

  @override
  String get editPostReReview => 'Editing sends the post back for review.';

  @override
  String get postDetailThankYou => 'Thank you. We will review this post.';

  @override
  String get postDetailTitle => 'Post';

  @override
  String get postDetailReportTooltip => 'Report post';

  @override
  String postDetailComments(int count) {
    return 'Comments ($count)';
  }

  @override
  String get postDetailNoComments => 'No comments yet.';

  @override
  String get postDetailWriteComment => 'Write a comment';

  @override
  String get postDetailPostComment => 'Post';

  @override
  String get postDetailFlagPersonalInfo => 'Shows personal information';

  @override
  String get postDetailFlagHarmful => 'Harmful or dangerous';

  @override
  String get postDetailFlagSpam => 'Spam';

  @override
  String get postDetailFlagMisinfo => 'Wrong information';

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
  String get postDetailDeleteConfirmBody => 'This can\'t be undone.';

  @override
  String get postDetailEdited => 'edited';

  @override
  String get postDetailRemovedComment => 'This comment was removed.';

  @override
  String get postDetailAiBadge => 'AI';

  @override
  String get postDetailMentionHelpHint => 'Ask NegevAI about this post';

  @override
  String get postDetailBotThinking => 'NegevAI is thinking...';

  @override
  String get guidanceClickedLink => 'I clicked a link';

  @override
  String get guidanceGotMessage => 'I got a message';

  @override
  String get guidanceSharedPassword => 'I shared my password';

  @override
  String get guidanceSentMoney => 'I sent money';

  @override
  String get guidanceCouldNotOpenLink => 'Couldn\'t open the link.';

  @override
  String get guidanceCouldNotCall => 'Couldn\'t start the call.';

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
  String get guidanceNoAdviceBody => 'Pick what happened to see what to do.';

  @override
  String get tourHomeTitle => 'Protection';

  @override
  String get tourHomeBody => 'Green means protected. Tap if it is not green.';

  @override
  String get tourCallsTitle => 'Red calls';

  @override
  String get tourCallsBody =>
      'Red calls may be scams. Don\'t answer or call back.';

  @override
  String get tourBlockedTitle => 'Blocked numbers';

  @override
  String get tourBlockedBody =>
      'Tap the crossed shield to see blocked numbers.';

  @override
  String get tourHelpTitle => 'Need help?';

  @override
  String get tourHelpBody => 'Tap ? on any screen.';

  @override
  String get tourSafetyTitle => 'Turn protection on';

  @override
  String get tourSafetyBody =>
      'Turn it on or off here. We warn you about scam messages.';

  @override
  String get tourReportTitle => 'Report a scam';

  @override
  String get tourReportBody => 'Tell others so they stay safe.';

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
  String get tourProfileTitle => 'Profile';

  @override
  String get tourProfileBody =>
      'See your posts and settings here. You can replay this tour in Settings.';

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

  @override
  String get tourBack => 'Back';

  @override
  String get helpTooltip => 'Help';

  @override
  String get helpGotIt => 'Got it';

  @override
  String get helpShowTour => 'Show tour again';

  @override
  String get helpCallsTitle => 'What things mean';

  @override
  String get helpCallsHighRiskTitle => 'Red call = likely scam';

  @override
  String get helpCallsHighRiskBody => 'Don\'t answer or call back.';

  @override
  String get helpCallsNormalTitle => 'Normal call';

  @override
  String get helpCallsNormalBody => 'No scam reports.';

  @override
  String get helpCallsBlockedRowTitle => 'Blocked call';

  @override
  String get helpCallsBlockedRowBody => 'This number can\'t ring you.';

  @override
  String get helpCallsBlockedListTitle => 'Blocked numbers';

  @override
  String get helpCallsBlockedListBody => 'Tap to see or unblock numbers.';

  @override
  String get helpCallsMenuTitle => 'More options';

  @override
  String get helpCallsMenuBody => 'Check, block or report a number.';

  @override
  String get helpCallsRefreshTitle => 'Refresh';

  @override
  String get helpCallsRefreshBody => 'Check calls again.';

  @override
  String get helpCallsMissedBody => 'You missed this call.';

  @override
  String get helpCallsAnsweredBody => 'You answered this call.';

  @override
  String get helpCallsRejectedBody => 'You declined this call.';

  @override
  String get helpCallsBlockedIconBody => 'This call was blocked.';

  @override
  String get helpCallsOutgoingBody => 'You called this number.';

  @override
  String get callsLikelyScam => 'Likely scam';

  @override
  String get callsMoreOptions => 'More options';

  @override
  String get callsBlockNumber => 'Block number';

  @override
  String get callsReportScam => 'Report as scam';

  @override
  String get callsBlockAndReport => 'Block and report';

  @override
  String get callsCheckNumber => 'Check number';

  @override
  String get callsLoadFailedBody => 'Try again.';

  @override
  String get callsBlockedEmptyBody => 'Blocked numbers will show here.';

  @override
  String get callsContactsLoadFailed => 'Couldn\'t show contacts. Try again.';

  @override
  String get callsCallTooltip => 'Call';
}
