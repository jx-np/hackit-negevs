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
  String get reportTabPhotoFailed => 'Couldn\'t analyze';

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
  String get homeWelcomeGuest => 'Welcome';

  @override
  String get myProfileTitle => 'My Profile';

  @override
  String get myProfileMemberSince => 'Member since';

  @override
  String get myProfilePosts => 'Posts';

  @override
  String get myProfileSignOut => 'Sign out';

  @override
  String get myProfileSignOutHint => 'You can sign back in at any time';

  @override
  String get myProfileNotSignedInTitle => 'You\'re not signed in';

  @override
  String get myProfileNotSignedInBody => 'Sign in to see your account.';

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
  String get settingsProtection => 'Protection';

  @override
  String get settingsStopProtection => 'Pause protection';

  @override
  String get settingsServiceRunning => 'Running now';

  @override
  String get settingsServiceStopped => 'Paused';

  @override
  String get settingsShowTutorial => 'Show the tour again';

  @override
  String get settingsReplayTour => 'A quick look at the app';

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
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsStatusTitle => 'Status';

  @override
  String get settingsGettingReady => 'Getting ready…';

  @override
  String get settingsNeedsDownload => 'Protection needs a download';

  @override
  String settingsModelReady(String name) {
    return '$name is ready';
  }

  @override
  String settingsModelNotDownloaded(String name) {
    return '$name is not downloaded yet';
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
      'Checks your messages on your phone. Nothing is sent away.';

  @override
  String get settingsCheckingSupport => 'Checking your phone…';

  @override
  String get settingsNotAvailable => 'Not available on this phone';

  @override
  String get settingsReadyShort => 'Ready';

  @override
  String get settingsBuiltInSubtitle => 'Built into your phone. No download.';

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
      'Leave this on Automatic unless the checker has trouble.';

  @override
  String get settingsSpeedAuto => 'Automatic';

  @override
  String get settingsSpeedAutoBody => 'Best for most phones';

  @override
  String get settingsSpeedCpu => 'Most compatible';

  @override
  String get settingsSpeedCpuBody => 'Works on every phone. Slowest.';

  @override
  String get settingsSpeedGpu => 'Faster';

  @override
  String get settingsSpeedGpuBody => 'Uses your phone\'s graphics chip';

  @override
  String get settingsSpeedNpu => 'Fastest';

  @override
  String get settingsSpeedNpuBody => 'Only on some newer phones';

  @override
  String get settingsAppSection => 'App';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPermissionsSubtitle => 'See what the app is allowed to do';

  @override
  String get settingsSignInSubtitle => 'Needed to post in the community';

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
  String get callHistoryTitle => 'Call history';

  @override
  String get callBlockedNumbers => 'Blocked numbers';

  @override
  String get callNoUnknown => 'No calls from unknown numbers';

  @override
  String get callPhonePermNeeded => 'Allow phone access';

  @override
  String get callPhonePermBody =>
      'We need this to show your calls and spot scams.';

  @override
  String get callGrantPhone => 'Allow';

  @override
  String get callCouldNotLoad => 'Couldn\'t show your calls';

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
      'To stop blocked calls ringing, set this app as your call blocker.';

  @override
  String get callHighRiskTitle => 'Likely scam call';

  @override
  String get callHighRiskBody =>
      'People reported this number as a scam. Never share money or personal details.';

  @override
  String callHighRiskScore(int score) {
    return 'Trust score: $score/100';
  }

  @override
  String callHighRiskReports(int count) {
    return 'Reported $count times';
  }

  @override
  String get callHighRiskDismiss => 'Got it';

  @override
  String get callChecking => 'Checking number...';

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
      'People reported this number as a scam. Don\'t answer or call back.';

  @override
  String get callCheckDetailUnknown =>
      'No one has reported this number. Still be careful.';

  @override
  String get callCheckDetailSafe => 'This number looks safe. Still be careful.';

  @override
  String get callCheckDetailFailed => 'Check your internet and try again.';

  @override
  String callCheckScore(int score) {
    return 'Trust score: $score/100';
  }

  @override
  String callCheckReports(int count) {
    return 'Reported $count times';
  }

  @override
  String get reportNotSent =>
      'Report not sent — reporting endpoint is not configured yet';

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
  String get permConfirmScreening => 'Confirm Call Manager for call screening';

  @override
  String get permScreeningUnavailable =>
      'Call screening is not available on this device';

  @override
  String get permNotificationAccess => 'Check messages';

  @override
  String get permNotificationAccessSub => 'Reads new messages to spot scams';

  @override
  String get permOverlay => 'Warnings during calls';

  @override
  String get permOverlaySub => 'Shows a warning while a call rings';

  @override
  String get permAlerts => 'Alerts';

  @override
  String get permAlertsSub => 'Sends you scam alerts';

  @override
  String get permBackground => 'Keep running';

  @override
  String get permBackgroundSub => 'Keeps working when the screen is off';

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
      'Checks calls and stops numbers you block.';

  @override
  String get permScreeningActive => 'Turned on';

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
      'Turn things on yourself in your phone\'s settings.';

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
  String get contactsPermRequired =>
      'Allow contacts access to see your contacts.';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsSearchHint => 'Search name or number';

  @override
  String get contactsCouldNotLoad => 'Could not load contacts';

  @override
  String get contactsNoneFound => 'No contacts found';

  @override
  String get contactsNoDetails => 'No details';

  @override
  String get contactsCouldNotCall => 'Couldn\'t start the call';

  @override
  String get safetyTitle => 'Safety';

  @override
  String get safetyRecentAlerts => 'Recent alerts';

  @override
  String get safetyProtectedOn => 'You are protected';

  @override
  String get safetyProtectedOff => 'Protection is off';

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
  String get safetyDownloadingModel => 'Downloading…';

  @override
  String get safetySettingUpModel => 'Setting up…';

  @override
  String get safetyNoScams => 'No scams found';

  @override
  String get safetyNoScamsBody => 'Scam messages will show here.';

  @override
  String get safetyMeteredTitle => 'Use mobile data?';

  @override
  String safetyMeteredBody(int mb) {
    return 'This download is about $mb MB. Wi-Fi is better.';
  }

  @override
  String get safetyNotNow => 'Not now';

  @override
  String get safetyDownload => 'Download';

  @override
  String get safetyCouldNotStart =>
      'Protection could not start. Please try again.';

  @override
  String get safetyShowMore => 'Show more';

  @override
  String get safetyShowLess => 'Show less';

  @override
  String get safetyPillOn => 'Protected';

  @override
  String get safetyPillOff => 'Off';

  @override
  String get safetyPillError => 'Needs attention';

  @override
  String get safetyPillChecking => 'Checking';

  @override
  String get safetyHeroOnBody => 'Checked privately on your phone.';

  @override
  String get protectionChecked => 'Checked';

  @override
  String get protectionAlerts => 'Alerts';

  @override
  String get protectionOn => 'Protection is on';

  @override
  String get protectionOff => 'Protection is off';

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
  String get activityNoMessages => 'No messages yet.';

  @override
  String get activityNotCheckedSuffix => ' · not checked';

  @override
  String get activityCloudSuffix => ' · online';

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
    return '$wire (online check)';
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
  String get onboardingFinish => 'Go to the app';

  @override
  String onboardingStepCount(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Stay safe from scams';

  @override
  String get onboardingWelcomeBody =>
      'We warn you about scam calls and messages. Setup takes a few taps.';

  @override
  String get onboardingWelcomeNote => 'You can change this later in Settings.';

  @override
  String get onboardingPhoneTitle => 'Phone calls';

  @override
  String get onboardingPhoneBody => 'See who is calling, so we can warn you.';

  @override
  String get onboardingContactsTitle => 'Contacts';

  @override
  String get onboardingContactsBody =>
      'Calls from people you know are never flagged.';

  @override
  String get onboardingScreeningTitle => 'Check calls';

  @override
  String get onboardingScreeningBody =>
      'Check calls and stop numbers you block.';

  @override
  String get onboardingNotificationsTitle => 'Alerts';

  @override
  String get onboardingNotificationsBody =>
      'Get an alert when something looks like a scam.';

  @override
  String get onboardingMessagesTitle => 'Check messages';

  @override
  String get onboardingMessagesBody =>
      'Read new messages to warn you about scams.';

  @override
  String get onboardingOverlayTitle => 'Warnings during calls';

  @override
  String get onboardingOverlayBody =>
      'Show a warning on screen during a risky call.';

  @override
  String get onboardingBackgroundTitle => 'Keep running';

  @override
  String get onboardingBackgroundBody =>
      'Keep watching for scams when the screen is off.';

  @override
  String get onboardingBatterySettingsTitle => 'Don\'t pause the app';

  @override
  String get onboardingBatterySettingsBody =>
      'Some phones pause apps to save battery. Stop that for this app.';

  @override
  String get onboardingSettingsHint =>
      'Settings will open. Find this app and turn it on.';

  @override
  String get onboardingStatusOn => 'Turned on.';

  @override
  String get onboardingStatusSkipped =>
      'Not on yet. You can turn it on later in Settings.';

  @override
  String get onboardingStatusBlocked =>
      'Your phone won\'t ask again. Tap \"Open settings\".';

  @override
  String get onboardingDoneTitle => 'You\'re all set';

  @override
  String get onboardingDoneBody => 'We are watching for scams for you.';

  @override
  String get onboardingDonePartialTitle => 'Almost done';

  @override
  String get onboardingDonePartialBody =>
      'Some things are off. You can turn them on later in Settings.';

  @override
  String onboardingGrantedCount(int granted, int total) {
    return '$granted of $total turned on';
  }

  @override
  String get onboardingWhy => 'Why?';

  @override
  String get onboardingScreeningWhy =>
      'Your phone will ask you to choose this app. Pick it so calls can be checked.';

  @override
  String get onboardingMessagesWhy =>
      'We look for scam signs, like odd links or requests for money.';

  @override
  String get onboardingBatterySettingsHint =>
      'Settings will open. Find this app and choose \"Don\'t optimize\".';

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
  String get onboardingModelKeepGoing =>
      'You can continue. It keeps downloading.';

  @override
  String get onboardingModelReady => 'Ready to use.';

  @override
  String get onboardingModelFailed =>
      'Download did not finish. Try again, or later in Settings.';

  @override
  String get onboardingModelMeteredTitle => 'Use mobile data?';

  @override
  String onboardingModelMeteredBody(String size) {
    return 'You are not on Wi‑Fi. This uses about $size of data.';
  }

  @override
  String get setupOpenSettingsFailed => 'Could not open settings.';

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
      'Use only letters and numbers. One space is allowed.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authRegisterIntro => 'Join to share scams and learn from others.';

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
  String get authToggleToLogin => 'Already have an account? Sign in';

  @override
  String get authToggleToRegister => 'New here? Create an account';

  @override
  String get authGateTitle => 'Sign in to continue';

  @override
  String get authGateBody => 'You need an account for this. It is free.';

  @override
  String get authGateAction => 'Sign in';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityShareScam => 'Share a scam';

  @override
  String get communityAll => 'All';

  @override
  String get communityNoPostsBody => 'Scams shared by others will show here.';

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
  String get myPostsEdit => 'Edit';

  @override
  String get editPostTitle => 'Edit post';

  @override
  String get editPostSave => 'Save changes';

  @override
  String get editPostSaving => 'Saving...';

  @override
  String get editPostSaved => 'Changes saved.';

  @override
  String get editPostReReview =>
      'Editing the message sends the post back for review.';

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
  String get guidanceNoAdviceBody => 'Pick what happened to see what to do.';

  @override
  String get tourHomeTitle => 'Are you protected?';

  @override
  String get tourHomeBody =>
      'Green means you are protected. If it is not green, tap it to turn protection on.';

  @override
  String get tourCallsTitle => 'Watch for red calls';

  @override
  String get tourCallsBody =>
      'Calls shown in red may be scams. Don\'t answer or call back.';

  @override
  String get tourBlockedTitle => 'Your blocked numbers';

  @override
  String get tourBlockedBody =>
      'Tap the shield with a line through it to see numbers you blocked.';

  @override
  String get tourHelpTitle => 'Need help?';

  @override
  String get tourHelpBody => 'Tap ? on any screen to see what things mean.';

  @override
  String get tourSafetyTitle => 'Turn protection on';

  @override
  String get tourSafetyBody =>
      'Turn protection on or off here. We warn you about scam messages.';

  @override
  String get tourReportTitle => 'Report a scam';

  @override
  String get tourReportBody =>
      'Tell others about a scam here so they can stay safe.';

  @override
  String get tourProfileTitle => 'Your profile';

  @override
  String get tourProfileBody =>
      'See your posts and open settings here. You can replay this tour from settings.';

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
  String get helpShowTour => 'Show the app tour again';

  @override
  String get helpCallsTitle => 'What things mean';

  @override
  String get helpCallsHighRiskTitle => 'Red call = likely scam';

  @override
  String get helpCallsHighRiskBody => 'Don\'t answer or call back.';

  @override
  String get helpCallsNormalTitle => 'Normal call';

  @override
  String get helpCallsNormalBody => 'No scam reports for this number.';

  @override
  String get helpCallsBlockedRowTitle => 'Blocked call';

  @override
  String get helpCallsBlockedRowBody =>
      'You blocked this number. It can\'t ring you.';

  @override
  String get helpCallsBlockedListTitle => 'Your blocked numbers';

  @override
  String get helpCallsBlockedListBody => 'Tap this to see or unblock numbers.';

  @override
  String get helpCallsMenuTitle => 'More options';

  @override
  String get helpCallsMenuBody => 'Check, block or report a number.';

  @override
  String get helpCallsRefreshTitle => 'Refresh';

  @override
  String get helpCallsRefreshBody => 'Check your calls again.';

  @override
  String get helpCallsMissedBody => 'You did not answer this call.';

  @override
  String get helpCallsAnsweredBody => 'You answered this call.';

  @override
  String get helpCallsRejectedBody => 'You turned down this call.';

  @override
  String get helpCallsBlockedIconBody => 'This call was stopped.';

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
  String get callsLoadFailedBody => 'Please try again.';

  @override
  String get callsBlockedEmptyBody => 'Numbers you block will show here.';

  @override
  String get callsContactsLoadFailed =>
      'Couldn\'t show your contacts. Please try again.';

  @override
  String get callsCallTooltip => 'Call';
}
