import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_zh.dart';

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
    Locale('ms'),
    Locale('ta'),
    Locale('zh'),
  ];

  /// No description provided for @commonReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commonReport;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get commonReviewed;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonReportThis.
  ///
  /// In en, this message translates to:
  /// **'Report this'**
  String get commonReportThis;

  /// No description provided for @commonNoPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get commonNoPostsYet;

  /// No description provided for @commonShareWithCommunity.
  ///
  /// In en, this message translates to:
  /// **'Share with community'**
  String get commonShareWithCommunity;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing...'**
  String get commonSharing;

  /// No description provided for @commonTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get commonTitle;

  /// No description provided for @commonTitleHint.
  ///
  /// In en, this message translates to:
  /// **'A short summary'**
  String get commonTitleHint;

  /// No description provided for @commonMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get commonMessage;

  /// No description provided for @commonMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the scam message here'**
  String get commonMessageHint;

  /// No description provided for @commonWhatKindOfScam.
  ///
  /// In en, this message translates to:
  /// **'What kind of scam?'**
  String get commonWhatKindOfScam;

  /// No description provided for @commonShareIntro.
  ///
  /// In en, this message translates to:
  /// **'Help others by sharing a scam you received. Remove any personal details first.'**
  String get commonShareIntro;

  /// No description provided for @commonPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos (optional)'**
  String get commonPhotos;

  /// No description provided for @commonAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get commonAddPhoto;

  /// No description provided for @commonRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get commonRemovePhoto;

  /// No description provided for @commonImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Each image must be 10 MB or smaller.'**
  String get commonImageTooLarge;

  /// No description provided for @reportTabPhotoProcessing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get reportTabPhotoProcessing;

  /// No description provided for @reportTabPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t analyze'**
  String get reportTabPhotoFailed;

  /// No description provided for @reportTabProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Do not close the application. Processing'**
  String get reportTabProcessingTitle;

  /// No description provided for @reportTabSignInToAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Sign in to attach photos.'**
  String get reportTabSignInToAddPhotos;

  /// No description provided for @reportTabFailedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Some photos couldn\'t be analyzed'**
  String get reportTabFailedDialogTitle;

  /// No description provided for @reportTabFailedDialogBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 photo failed to upload or analyze. Retry it, or post without it?} other{{count} photos failed to upload or analyze. Retry them, or post without them?}}'**
  String reportTabFailedDialogBody(int count);

  /// No description provided for @reportTabFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get reportTabFailedRetry;

  /// No description provided for @reportTabFailedPostWithout.
  ///
  /// In en, this message translates to:
  /// **'Post without photos'**
  String get reportTabFailedPostWithout;

  /// No description provided for @reportTabWaitForImages.
  ///
  /// In en, this message translates to:
  /// **'Wait for images to be processed'**
  String get reportTabWaitForImages;

  /// No description provided for @reportTabCheckImages.
  ///
  /// In en, this message translates to:
  /// **'Check images'**
  String get reportTabCheckImages;

  /// No description provided for @reportTabReviewCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I\'ve reviewed the images and the personal details are hidden correctly'**
  String get reportTabReviewCheckbox;

  /// No description provided for @reportTabEditImage.
  ///
  /// In en, this message translates to:
  /// **'Edit image'**
  String get reportTabEditImage;

  /// No description provided for @reportTabReuploading.
  ///
  /// In en, this message translates to:
  /// **'Re-uploading edited image...'**
  String get reportTabReuploading;

  /// No description provided for @reportTabPosting.
  ///
  /// In en, this message translates to:
  /// **'Posting...'**
  String get reportTabPosting;

  /// No description provided for @reportTabEditorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t re-upload the edited image. Try again.'**
  String get reportTabEditorSaveFailed;

  /// No description provided for @reportTabEditorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the image to edit. Try again.'**
  String get reportTabEditorLoadFailed;

  /// No description provided for @reportTabViewPost.
  ///
  /// In en, this message translates to:
  /// **'View your post'**
  String get reportTabViewPost;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeWelcomePrefix.
  ///
  /// In en, this message translates to:
  /// **'Welcome, '**
  String get homeWelcomePrefix;

  /// No description provided for @homeWelcomeGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcomeGuest;

  /// No description provided for @myProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfileTitle;

  /// No description provided for @myProfileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get myProfileMemberSince;

  /// No description provided for @myProfilePosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get myProfilePosts;

  /// No description provided for @myProfileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get myProfileSignOut;

  /// No description provided for @myProfileSignOutHint.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in at any time'**
  String get myProfileSignOutHint;

  /// No description provided for @myProfileNotSignedInTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re not signed in'**
  String get myProfileNotSignedInTitle;

  /// No description provided for @myProfileNotSignedInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your account.'**
  String get myProfileNotSignedInBody;

  /// No description provided for @myProfileSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get myProfileSignIn;

  /// No description provided for @homeNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scam alerts & news'**
  String get homeNewsTitle;

  /// No description provided for @homeNewsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the latest alerts.'**
  String get homeNewsError;

  /// No description provided for @homeNewsRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get homeNewsRetry;

  /// No description provided for @homeQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get homeQuickActionsTitle;

  /// No description provided for @homeActionProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get homeActionProfile;

  /// No description provided for @homeActionProfileBody.
  ///
  /// In en, this message translates to:
  /// **'See your details and your posts'**
  String get homeActionProfileBody;

  /// No description provided for @homeActionCalls.
  ///
  /// In en, this message translates to:
  /// **'Recent calls'**
  String get homeActionCalls;

  /// No description provided for @homeActionCallsBody.
  ///
  /// In en, this message translates to:
  /// **'Review calls from unknown numbers'**
  String get homeActionCallsBody;

  /// No description provided for @homeActionReport.
  ///
  /// In en, this message translates to:
  /// **'Report a scam'**
  String get homeActionReport;

  /// No description provided for @homeActionReportBody.
  ///
  /// In en, this message translates to:
  /// **'Warn others in the community'**
  String get homeActionReportBody;

  /// No description provided for @homeStatusOnBody.
  ///
  /// In en, this message translates to:
  /// **'We are checking your messages for scams.'**
  String get homeStatusOnBody;

  /// No description provided for @homeStatusOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it on so we can warn you about scam messages.'**
  String get homeStatusOffBody;

  /// No description provided for @homeStatusProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Protection needs attention'**
  String get homeStatusProblemTitle;

  /// No description provided for @homeStatusProblemBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Tap below to fix it.'**
  String get homeStatusProblemBody;

  /// No description provided for @homeStatusStartingTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting ready'**
  String get homeStatusStartingTitle;

  /// No description provided for @homeStatusStartingBody.
  ///
  /// In en, this message translates to:
  /// **'Protection is starting up. This can take a minute.'**
  String get homeStatusStartingBody;

  /// No description provided for @homeStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'See details'**
  String get homeStatusOpen;

  /// No description provided for @homeStatusFix.
  ///
  /// In en, this message translates to:
  /// **'Fix it now'**
  String get homeStatusFix;

  /// No description provided for @homeNewsReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get homeNewsReadMore;

  /// No description provided for @homeNewsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get homeNewsClose;

  /// No description provided for @homeNewsCount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String homeNewsCount(Object current, Object total);

  /// No description provided for @homeNewsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous alert'**
  String get homeNewsPrevious;

  /// No description provided for @homeNewsNext.
  ///
  /// In en, this message translates to:
  /// **'Next alert'**
  String get homeNewsNext;

  /// No description provided for @settingsProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get settingsProtection;

  /// No description provided for @settingsStopProtection.
  ///
  /// In en, this message translates to:
  /// **'Pause protection'**
  String get settingsStopProtection;

  /// No description provided for @settingsServiceRunning.
  ///
  /// In en, this message translates to:
  /// **'Running now'**
  String get settingsServiceRunning;

  /// No description provided for @settingsServiceStopped.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get settingsServiceStopped;

  /// No description provided for @settingsShowTutorial.
  ///
  /// In en, this message translates to:
  /// **'Show the tour again'**
  String get settingsShowTutorial;

  /// No description provided for @settingsReplayTour.
  ///
  /// In en, this message translates to:
  /// **'A quick look at the app'**
  String get settingsReplayTour;

  /// No description provided for @settingsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get settingsRemove;

  /// No description provided for @settingsPercent.
  ///
  /// In en, this message translates to:
  /// **'{pct}%'**
  String settingsPercent(int pct);

  /// No description provided for @settingsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get settingsDownload;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get settingsStatusTitle;

  /// No description provided for @settingsGettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get settingsGettingReady;

  /// No description provided for @settingsNeedsDownload.
  ///
  /// In en, this message translates to:
  /// **'Protection needs a download'**
  String get settingsNeedsDownload;

  /// No description provided for @settingsModelReady.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready'**
  String settingsModelReady(String name);

  /// No description provided for @settingsModelNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{name} is not downloaded yet'**
  String settingsModelNotDownloaded(String name);

  /// No description provided for @settingsSettingUpPct.
  ///
  /// In en, this message translates to:
  /// **'Setting up… {pct}%'**
  String settingsSettingUpPct(int pct);

  /// No description provided for @settingsSettingUpMb.
  ///
  /// In en, this message translates to:
  /// **'Setting up… {mb} MB'**
  String settingsSettingUpMb(int mb);

  /// No description provided for @settingsCheckerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scam checker'**
  String get settingsCheckerTitle;

  /// No description provided for @settingsCheckerCaption.
  ///
  /// In en, this message translates to:
  /// **'Checks your messages on your phone. Nothing is sent away.'**
  String get settingsCheckerCaption;

  /// No description provided for @settingsCheckingSupport.
  ///
  /// In en, this message translates to:
  /// **'Checking your phone…'**
  String get settingsCheckingSupport;

  /// No description provided for @settingsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this phone'**
  String get settingsNotAvailable;

  /// No description provided for @settingsReadyShort.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get settingsReadyShort;

  /// No description provided for @settingsBuiltInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Built into your phone. No download.'**
  String get settingsBuiltInSubtitle;

  /// No description provided for @settingsAboutMb.
  ///
  /// In en, this message translates to:
  /// **'About {mb} MB'**
  String settingsAboutMb(int mb);

  /// No description provided for @settingsPrepare.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get settingsPrepare;

  /// No description provided for @settingsSpeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get settingsSpeedTitle;

  /// No description provided for @settingsSpeedCaption.
  ///
  /// In en, this message translates to:
  /// **'Leave this on Automatic unless the checker has trouble.'**
  String get settingsSpeedCaption;

  /// No description provided for @settingsSpeedAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsSpeedAuto;

  /// No description provided for @settingsSpeedAutoBody.
  ///
  /// In en, this message translates to:
  /// **'Best for most phones'**
  String get settingsSpeedAutoBody;

  /// No description provided for @settingsSpeedCpu.
  ///
  /// In en, this message translates to:
  /// **'Most compatible'**
  String get settingsSpeedCpu;

  /// No description provided for @settingsSpeedCpuBody.
  ///
  /// In en, this message translates to:
  /// **'Works on every phone. Slowest.'**
  String get settingsSpeedCpuBody;

  /// No description provided for @settingsSpeedGpu.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get settingsSpeedGpu;

  /// No description provided for @settingsSpeedGpuBody.
  ///
  /// In en, this message translates to:
  /// **'Uses your phone\'s graphics chip'**
  String get settingsSpeedGpuBody;

  /// No description provided for @settingsSpeedNpu.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get settingsSpeedNpu;

  /// No description provided for @settingsSpeedNpuBody.
  ///
  /// In en, this message translates to:
  /// **'Only on some newer phones'**
  String get settingsSpeedNpuBody;

  /// No description provided for @settingsAppSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppSection;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See what the app is allowed to do'**
  String get settingsPermissionsSubtitle;

  /// No description provided for @settingsSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Needed to post in the community'**
  String get settingsSignInSubtitle;

  /// No description provided for @callIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming call: {who}'**
  String callIncoming(String who);

  /// No description provided for @callBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked {number}'**
  String callBlocked(String number);

  /// No description provided for @callUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Unblocked {number}'**
  String callUnblocked(String number);

  /// No description provided for @callReported.
  ///
  /// In en, this message translates to:
  /// **'Reported {number}'**
  String callReported(String number);

  /// No description provided for @callOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get callOutgoing;

  /// No description provided for @callAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get callAnswered;

  /// No description provided for @callRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get callRejected;

  /// No description provided for @callMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get callMissed;

  /// No description provided for @callBlockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get callBlockedLabel;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get navCalls;

  /// No description provided for @navSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get navSafety;

  /// No description provided for @navReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get navReport;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @callHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Call history'**
  String get callHistoryTitle;

  /// No description provided for @callBlockedNumbers.
  ///
  /// In en, this message translates to:
  /// **'Blocked numbers'**
  String get callBlockedNumbers;

  /// No description provided for @callNoUnknown.
  ///
  /// In en, this message translates to:
  /// **'No calls from unknown numbers'**
  String get callNoUnknown;

  /// No description provided for @callPhonePermNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow phone access'**
  String get callPhonePermNeeded;

  /// No description provided for @callPhonePermBody.
  ///
  /// In en, this message translates to:
  /// **'We need this to show your calls and spot scams.'**
  String get callPhonePermBody;

  /// No description provided for @callGrantPhone.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get callGrantPhone;

  /// No description provided for @callCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t show your calls'**
  String get callCouldNotLoad;

  /// No description provided for @callDurationSuffix.
  ///
  /// In en, this message translates to:
  /// **' • {seconds}s'**
  String callDurationSuffix(int seconds);

  /// No description provided for @callReportedSuffix.
  ///
  /// In en, this message translates to:
  /// **' • Reported'**
  String get callReportedSuffix;

  /// No description provided for @callUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get callUnblock;

  /// No description provided for @callBlockNeedsScreening.
  ///
  /// In en, this message translates to:
  /// **'To stop blocked calls ringing, set this app as your call blocker.'**
  String get callBlockNeedsScreening;

  /// No description provided for @callHighRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Likely scam call'**
  String get callHighRiskTitle;

  /// No description provided for @callHighRiskBody.
  ///
  /// In en, this message translates to:
  /// **'People reported this number as a scam. Never share money or personal details.'**
  String get callHighRiskBody;

  /// No description provided for @callHighRiskScore.
  ///
  /// In en, this message translates to:
  /// **'Trust score: {score}/100'**
  String callHighRiskScore(int score);

  /// No description provided for @callHighRiskReports.
  ///
  /// In en, this message translates to:
  /// **'Reported {count} times'**
  String callHighRiskReports(int count);

  /// No description provided for @callHighRiskDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get callHighRiskDismiss;

  /// No description provided for @callChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking number...'**
  String get callChecking;

  /// No description provided for @callCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check number'**
  String get callCheckTitle;

  /// No description provided for @callCheckNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Number checked'**
  String get callCheckNumberLabel;

  /// No description provided for @callCheckResultHighRisk.
  ///
  /// In en, this message translates to:
  /// **'Likely scam'**
  String get callCheckResultHighRisk;

  /// No description provided for @callCheckResultUnknown.
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get callCheckResultUnknown;

  /// No description provided for @callCheckResultSafe.
  ///
  /// In en, this message translates to:
  /// **'Looks safe'**
  String get callCheckResultSafe;

  /// No description provided for @callCheckResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check'**
  String get callCheckResultFailed;

  /// No description provided for @callCheckDetailHighRisk.
  ///
  /// In en, this message translates to:
  /// **'People reported this number as a scam. Don\'t answer or call back.'**
  String get callCheckDetailHighRisk;

  /// No description provided for @callCheckDetailUnknown.
  ///
  /// In en, this message translates to:
  /// **'No one has reported this number. Still be careful.'**
  String get callCheckDetailUnknown;

  /// No description provided for @callCheckDetailSafe.
  ///
  /// In en, this message translates to:
  /// **'This number looks safe. Still be careful.'**
  String get callCheckDetailSafe;

  /// No description provided for @callCheckDetailFailed.
  ///
  /// In en, this message translates to:
  /// **'Check your internet and try again.'**
  String get callCheckDetailFailed;

  /// No description provided for @callCheckScore.
  ///
  /// In en, this message translates to:
  /// **'Trust score: {score}/100'**
  String callCheckScore(int score);

  /// No description provided for @callCheckReports.
  ///
  /// In en, this message translates to:
  /// **'Reported {count} times'**
  String callCheckReports(int count);

  /// No description provided for @reportNotSent.
  ///
  /// In en, this message translates to:
  /// **'Report not sent — reporting endpoint is not configured yet'**
  String get reportNotSent;

  /// No description provided for @reportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportSpam;

  /// No description provided for @reportScam.
  ///
  /// In en, this message translates to:
  /// **'Scam'**
  String get reportScam;

  /// No description provided for @reportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportOther;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReason;

  /// No description provided for @shieldCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get shieldCheck;

  /// No description provided for @permDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permDenied;

  /// No description provided for @permConfirmScreening.
  ///
  /// In en, this message translates to:
  /// **'Confirm Call Manager for call screening'**
  String get permConfirmScreening;

  /// No description provided for @permScreeningUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Call screening is not available on this device'**
  String get permScreeningUnavailable;

  /// No description provided for @permNotificationAccess.
  ///
  /// In en, this message translates to:
  /// **'Check messages'**
  String get permNotificationAccess;

  /// No description provided for @permNotificationAccessSub.
  ///
  /// In en, this message translates to:
  /// **'Reads new messages to spot scams'**
  String get permNotificationAccessSub;

  /// No description provided for @permOverlay.
  ///
  /// In en, this message translates to:
  /// **'Warnings during calls'**
  String get permOverlay;

  /// No description provided for @permOverlaySub.
  ///
  /// In en, this message translates to:
  /// **'Shows a warning while a call rings'**
  String get permOverlaySub;

  /// No description provided for @permAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get permAlerts;

  /// No description provided for @permAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Sends you scam alerts'**
  String get permAlertsSub;

  /// No description provided for @permBackground.
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get permBackground;

  /// No description provided for @permBackgroundSub.
  ///
  /// In en, this message translates to:
  /// **'Keeps working when the screen is off'**
  String get permBackgroundSub;

  /// No description provided for @permBatterySettings.
  ///
  /// In en, this message translates to:
  /// **'Don\'t pause the app'**
  String get permBatterySettings;

  /// No description provided for @permBatterySettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Set this app to \"Don\'t optimize\".'**
  String get permBatterySettingsSub;

  /// No description provided for @permGranted.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get permGranted;

  /// No description provided for @permGrant.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get permGrant;

  /// No description provided for @permScreeningRole.
  ///
  /// In en, this message translates to:
  /// **'Check calls'**
  String get permScreeningRole;

  /// No description provided for @permScreeningRoleSub.
  ///
  /// In en, this message translates to:
  /// **'Checks calls and stops numbers you block.'**
  String get permScreeningRoleSub;

  /// No description provided for @permScreeningActive.
  ///
  /// In en, this message translates to:
  /// **'Turned on'**
  String get permScreeningActive;

  /// No description provided for @permEnableScreening.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get permEnableScreening;

  /// No description provided for @permScreeningNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Call checking is off'**
  String get permScreeningNotGranted;

  /// No description provided for @permScreeningTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Turn on\" above.'**
  String get permScreeningTapHint;

  /// No description provided for @permTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permTitle;

  /// No description provided for @permGrantFollowing.
  ///
  /// In en, this message translates to:
  /// **'Turn these on for full protection.'**
  String get permGrantFollowing;

  /// No description provided for @permPhoneCallLog.
  ///
  /// In en, this message translates to:
  /// **'Phone calls'**
  String get permPhoneCallLog;

  /// No description provided for @permPhoneGranted.
  ///
  /// In en, this message translates to:
  /// **'Phone permission granted'**
  String get permPhoneGranted;

  /// No description provided for @permContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get permContacts;

  /// No description provided for @permContactsGranted.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission granted'**
  String get permContactsGranted;

  /// No description provided for @permNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotifications;

  /// No description provided for @permNotificationsGranted.
  ///
  /// In en, this message translates to:
  /// **'Notification permission granted'**
  String get permNotificationsGranted;

  /// No description provided for @permStillNotWorking.
  ///
  /// In en, this message translates to:
  /// **'Still not working?'**
  String get permStillNotWorking;

  /// No description provided for @permOpenSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Turn things on yourself in your phone\'s settings.'**
  String get permOpenSettingsBody;

  /// No description provided for @permOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permOpenAppSettings;

  /// No description provided for @permNotChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked'**
  String get permNotChecked;

  /// No description provided for @permStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get permStatusDenied;

  /// No description provided for @permPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Off. Turn on in settings'**
  String get permPermanentlyDenied;

  /// No description provided for @permNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get permNotGranted;

  /// No description provided for @contactsPermRequired.
  ///
  /// In en, this message translates to:
  /// **'Allow contacts access to see your contacts.'**
  String get contactsPermRequired;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @contactsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or number'**
  String get contactsSearchHint;

  /// No description provided for @contactsCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load contacts'**
  String get contactsCouldNotLoad;

  /// No description provided for @contactsNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get contactsNoneFound;

  /// No description provided for @contactsNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No details'**
  String get contactsNoDetails;

  /// No description provided for @contactsCouldNotCall.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the call'**
  String get contactsCouldNotCall;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safetyTitle;

  /// No description provided for @safetyRecentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent alerts'**
  String get safetyRecentAlerts;

  /// No description provided for @safetyProtectedOn.
  ///
  /// In en, this message translates to:
  /// **'You are protected'**
  String get safetyProtectedOn;

  /// No description provided for @safetyProtectedOff.
  ///
  /// In en, this message translates to:
  /// **'Protection is off'**
  String get safetyProtectedOff;

  /// No description provided for @safetyWeCheck.
  ///
  /// In en, this message translates to:
  /// **'We check your messages for scams.'**
  String get safetyWeCheck;

  /// No description provided for @safetyTurnOnToCheck.
  ///
  /// In en, this message translates to:
  /// **'Turn this on to check messages for scams.'**
  String get safetyTurnOnToCheck;

  /// No description provided for @safetyTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn protection off'**
  String get safetyTurnOff;

  /// No description provided for @safetyTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn protection on'**
  String get safetyTurnOn;

  /// No description provided for @safetyPressToStart.
  ///
  /// In en, this message translates to:
  /// **'Press to start'**
  String get safetyPressToStart;

  /// No description provided for @safetyDownloadingModel.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get safetyDownloadingModel;

  /// No description provided for @safetySettingUpModel.
  ///
  /// In en, this message translates to:
  /// **'Setting up…'**
  String get safetySettingUpModel;

  /// No description provided for @safetyNoScams.
  ///
  /// In en, this message translates to:
  /// **'No scams found'**
  String get safetyNoScams;

  /// No description provided for @safetyNoScamsBody.
  ///
  /// In en, this message translates to:
  /// **'Scam messages will show here.'**
  String get safetyNoScamsBody;

  /// No description provided for @safetyMeteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Use mobile data?'**
  String get safetyMeteredTitle;

  /// No description provided for @safetyMeteredBody.
  ///
  /// In en, this message translates to:
  /// **'This download is about {mb} MB. Wi-Fi is better.'**
  String safetyMeteredBody(int mb);

  /// No description provided for @safetyNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get safetyNotNow;

  /// No description provided for @safetyDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get safetyDownload;

  /// No description provided for @safetyCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Protection could not start. Please try again.'**
  String get safetyCouldNotStart;

  /// No description provided for @safetyShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get safetyShowMore;

  /// No description provided for @safetyShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get safetyShowLess;

  /// No description provided for @safetyPillOn.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get safetyPillOn;

  /// No description provided for @safetyPillOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get safetyPillOff;

  /// No description provided for @safetyPillError.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get safetyPillError;

  /// No description provided for @safetyPillChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get safetyPillChecking;

  /// No description provided for @safetyHeroOnBody.
  ///
  /// In en, this message translates to:
  /// **'Checked privately on your phone.'**
  String get safetyHeroOnBody;

  /// No description provided for @protectionChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get protectionChecked;

  /// No description provided for @protectionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get protectionAlerts;

  /// No description provided for @protectionOn.
  ///
  /// In en, this message translates to:
  /// **'Protection is on'**
  String get protectionOn;

  /// No description provided for @protectionOff.
  ///
  /// In en, this message translates to:
  /// **'Protection is off'**
  String get protectionOff;

  /// No description provided for @activityAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String activityAll(int count);

  /// No description provided for @activityScams.
  ///
  /// In en, this message translates to:
  /// **'Scams ({count})'**
  String activityScams(int count);

  /// No description provided for @activityUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Unchecked ({count})'**
  String activityUnchecked(int count);

  /// No description provided for @activityNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get activityNoMessages;

  /// No description provided for @activityNotCheckedSuffix.
  ///
  /// In en, this message translates to:
  /// **' · not checked'**
  String get activityNotCheckedSuffix;

  /// No description provided for @activityCloudSuffix.
  ///
  /// In en, this message translates to:
  /// **' · online'**
  String get activityCloudSuffix;

  /// No description provided for @activityNotCheckedYet.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet.'**
  String get activityNotCheckedYet;

  /// No description provided for @activityVerdict.
  ///
  /// In en, this message translates to:
  /// **'Verdict'**
  String get activityVerdict;

  /// No description provided for @activityConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get activityConfidence;

  /// No description provided for @activityCheckedBy.
  ///
  /// In en, this message translates to:
  /// **'Checked by'**
  String get activityCheckedBy;

  /// No description provided for @activityEscalatedSuffix.
  ///
  /// In en, this message translates to:
  /// **'{wire} (online check)'**
  String activityEscalatedSuffix(String wire);

  /// No description provided for @activityReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get activityReason;

  /// No description provided for @activityAiThinking.
  ///
  /// In en, this message translates to:
  /// **'Full result'**
  String get activityAiThinking;

  /// No description provided for @activityNoOutput.
  ///
  /// In en, this message translates to:
  /// **'(No result)'**
  String get activityNoOutput;

  /// No description provided for @blockedNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked numbers'**
  String get blockedNumbersTitle;

  /// No description provided for @blockedNoNumbers.
  ///
  /// In en, this message translates to:
  /// **'No blocked numbers'**
  String get blockedNoNumbers;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test a message'**
  String get notificationsTestTitle;

  /// No description provided for @notificationsTestHint.
  ///
  /// In en, this message translates to:
  /// **'Paste or type a message'**
  String get notificationsTestHint;

  /// No description provided for @notificationsTestRun.
  ///
  /// In en, this message translates to:
  /// **'Check message'**
  String get notificationsTestRun;

  /// No description provided for @notificationsTestServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on protection first.'**
  String get notificationsTestServiceOff;

  /// No description provided for @notificationsTestSent.
  ///
  /// In en, this message translates to:
  /// **'Checking. The result will show below.'**
  String get notificationsTestSent;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @settingsScreenPermissionsTab.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get settingsScreenPermissionsTab;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @onboardingAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get onboardingAllow;

  /// No description provided for @onboardingOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get onboardingOpenSettings;

  /// No description provided for @onboardingNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotNow;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Go to the app'**
  String get onboardingFinish;

  /// No description provided for @onboardingStepCount.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepCount(int step, int total);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay safe from scams'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'We warn you about scam calls and messages. Setup takes a few taps.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingWelcomeNote.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get onboardingWelcomeNote;

  /// No description provided for @onboardingPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone calls'**
  String get onboardingPhoneTitle;

  /// No description provided for @onboardingPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'See who is calling, so we can warn you.'**
  String get onboardingPhoneBody;

  /// No description provided for @onboardingContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get onboardingContactsTitle;

  /// No description provided for @onboardingContactsBody.
  ///
  /// In en, this message translates to:
  /// **'Calls from people you know are never flagged.'**
  String get onboardingContactsBody;

  /// No description provided for @onboardingScreeningTitle.
  ///
  /// In en, this message translates to:
  /// **'Check calls'**
  String get onboardingScreeningTitle;

  /// No description provided for @onboardingScreeningBody.
  ///
  /// In en, this message translates to:
  /// **'Check calls and stop numbers you block.'**
  String get onboardingScreeningBody;

  /// No description provided for @onboardingNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get onboardingNotificationsTitle;

  /// No description provided for @onboardingNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Get an alert when something looks like a scam.'**
  String get onboardingNotificationsBody;

  /// No description provided for @onboardingMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Check messages'**
  String get onboardingMessagesTitle;

  /// No description provided for @onboardingMessagesBody.
  ///
  /// In en, this message translates to:
  /// **'Read new messages to warn you about scams.'**
  String get onboardingMessagesBody;

  /// No description provided for @onboardingOverlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Warnings during calls'**
  String get onboardingOverlayTitle;

  /// No description provided for @onboardingOverlayBody.
  ///
  /// In en, this message translates to:
  /// **'Show a warning on screen during a risky call.'**
  String get onboardingOverlayBody;

  /// No description provided for @onboardingBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get onboardingBackgroundTitle;

  /// No description provided for @onboardingBackgroundBody.
  ///
  /// In en, this message translates to:
  /// **'Keep watching for scams when the screen is off.'**
  String get onboardingBackgroundBody;

  /// No description provided for @onboardingBatterySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t pause the app'**
  String get onboardingBatterySettingsTitle;

  /// No description provided for @onboardingBatterySettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Some phones pause apps to save battery. Stop that for this app.'**
  String get onboardingBatterySettingsBody;

  /// No description provided for @onboardingSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Settings will open. Find this app and turn it on.'**
  String get onboardingSettingsHint;

  /// No description provided for @onboardingStatusOn.
  ///
  /// In en, this message translates to:
  /// **'Turned on.'**
  String get onboardingStatusOn;

  /// No description provided for @onboardingStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Not on yet. You can turn it on later in Settings.'**
  String get onboardingStatusSkipped;

  /// No description provided for @onboardingStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Your phone won\'t ask again. Tap \"Open settings\".'**
  String get onboardingStatusBlocked;

  /// No description provided for @onboardingDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get onboardingDoneTitle;

  /// No description provided for @onboardingDoneBody.
  ///
  /// In en, this message translates to:
  /// **'We are watching for scams for you.'**
  String get onboardingDoneBody;

  /// No description provided for @onboardingDonePartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost done'**
  String get onboardingDonePartialTitle;

  /// No description provided for @onboardingDonePartialBody.
  ///
  /// In en, this message translates to:
  /// **'Some things are off. You can turn them on later in Settings.'**
  String get onboardingDonePartialBody;

  /// No description provided for @onboardingGrantedCount.
  ///
  /// In en, this message translates to:
  /// **'{granted} of {total} turned on'**
  String onboardingGrantedCount(int granted, int total);

  /// No description provided for @onboardingWhy.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get onboardingWhy;

  /// No description provided for @onboardingScreeningWhy.
  ///
  /// In en, this message translates to:
  /// **'Your phone will ask you to choose this app. Pick it so calls can be checked.'**
  String get onboardingScreeningWhy;

  /// No description provided for @onboardingMessagesWhy.
  ///
  /// In en, this message translates to:
  /// **'We look for scam signs, like odd links or requests for money.'**
  String get onboardingMessagesWhy;

  /// No description provided for @onboardingBatterySettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Settings will open. Find this app and choose \"Don\'t optimize\".'**
  String get onboardingBatterySettingsHint;

  /// No description provided for @onboardingModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Scam checker'**
  String get onboardingModelTitle;

  /// No description provided for @onboardingModelBody.
  ///
  /// In en, this message translates to:
  /// **'Checks messages on your phone. Use Wi‑Fi.'**
  String get onboardingModelBody;

  /// No description provided for @onboardingModelDownload.
  ///
  /// In en, this message translates to:
  /// **'Download ({size})'**
  String onboardingModelDownload(String size);

  /// No description provided for @onboardingModelDownloadShort.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get onboardingModelDownloadShort;

  /// No description provided for @onboardingModelDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String onboardingModelDownloading(int percent);

  /// No description provided for @onboardingModelKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'You can continue. It keeps downloading.'**
  String get onboardingModelKeepGoing;

  /// No description provided for @onboardingModelReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to use.'**
  String get onboardingModelReady;

  /// No description provided for @onboardingModelFailed.
  ///
  /// In en, this message translates to:
  /// **'Download did not finish. Try again, or later in Settings.'**
  String get onboardingModelFailed;

  /// No description provided for @onboardingModelMeteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Use mobile data?'**
  String get onboardingModelMeteredTitle;

  /// No description provided for @onboardingModelMeteredBody.
  ///
  /// In en, this message translates to:
  /// **'You are not on Wi‑Fi. This uses about {size} of data.'**
  String onboardingModelMeteredBody(String size);

  /// No description provided for @setupOpenSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open settings.'**
  String get setupOpenSettingsFailed;

  /// No description provided for @authEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get authEnterEmail;

  /// No description provided for @authValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get authValidEmail;

  /// No description provided for @authEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get authEnterPassword;

  /// No description provided for @authPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get authPasswordLength;

  /// No description provided for @authEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get authEnterName;

  /// No description provided for @authNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use only letters and numbers. One space is allowed.'**
  String get authNameInvalid;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authRegisterIntro.
  ///
  /// In en, this message translates to:
  /// **'Join to share scams and learn from others.'**
  String get authRegisterIntro;

  /// No description provided for @authLoginIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign in to post and comment.'**
  String get authLoginIntro;

  /// No description provided for @authYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get authYourName;

  /// No description provided for @authYourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get authYourNameHint;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authToggleToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authToggleToLogin;

  /// No description provided for @authToggleToRegister.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authToggleToRegister;

  /// No description provided for @authGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get authGateTitle;

  /// No description provided for @authGateBody.
  ///
  /// In en, this message translates to:
  /// **'You need an account for this. It is free.'**
  String get authGateBody;

  /// No description provided for @authGateAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authGateAction;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @communityShareScam.
  ///
  /// In en, this message translates to:
  /// **'Share a scam'**
  String get communityShareScam;

  /// No description provided for @communityAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communityAll;

  /// No description provided for @communityNoPostsBody.
  ///
  /// In en, this message translates to:
  /// **'Scams shared by others will show here.'**
  String get communityNoPostsBody;

  /// No description provided for @createChooseType.
  ///
  /// In en, this message translates to:
  /// **'Please choose a scam type.'**
  String get createChooseType;

  /// No description provided for @createAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Please add a title.'**
  String get createAddTitle;

  /// No description provided for @createAddMessage.
  ///
  /// In en, this message translates to:
  /// **'Please add the message text.'**
  String get createAddMessage;

  /// No description provided for @reportTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTabTitle;

  /// No description provided for @reportTabThankYou.
  ///
  /// In en, this message translates to:
  /// **'Shared with the community. Thank you!'**
  String get reportTabThankYou;

  /// No description provided for @reportTabTrackIt.
  ///
  /// In en, this message translates to:
  /// **'Shared with the community. Check My Profile to track it.'**
  String get reportTabTrackIt;

  /// No description provided for @reportTabHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Warn others about a scam'**
  String get reportTabHeroTitle;

  /// No description provided for @reportTabNumberHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a phone number'**
  String get reportTabNumberHeroTitle;

  /// No description provided for @reportTabNumberHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us why this number is suspicious. Your report helps protect others.'**
  String get reportTabNumberHeroBody;

  /// No description provided for @reportTabPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get reportTabPaste;

  /// No description provided for @reportTabPasteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to paste. Copy the message first.'**
  String get reportTabPasteEmpty;

  /// No description provided for @reportTabNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get reportTabNumberLabel;

  /// No description provided for @reportTabNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. +65 9123 4567'**
  String get reportTabNumberHint;

  /// No description provided for @reportTabNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the phone number.'**
  String get reportTabNumberRequired;

  /// No description provided for @reportTabReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get reportTabReasonLabel;

  /// No description provided for @reportTabReasonSpamBody.
  ///
  /// In en, this message translates to:
  /// **'Unwanted calls or adverts'**
  String get reportTabReasonSpamBody;

  /// No description provided for @reportTabReasonScamBody.
  ///
  /// In en, this message translates to:
  /// **'They tried to trick me or take my money'**
  String get reportTabReasonScamBody;

  /// No description provided for @reportTabReasonOtherBody.
  ///
  /// In en, this message translates to:
  /// **'Something else felt wrong'**
  String get reportTabReasonOtherBody;

  /// No description provided for @reportTabSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for helping'**
  String get reportTabSuccessTitle;

  /// No description provided for @reportTabReportAnother.
  ///
  /// In en, this message translates to:
  /// **'Report another'**
  String get reportTabReportAnother;

  /// No description provided for @reportTabDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reportTabDone;

  /// No description provided for @myPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get myPostsTitle;

  /// No description provided for @myPostsNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Scams you report will show up here so you can track them.'**
  String get myPostsNoneBody;

  /// No description provided for @myPostsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get myPostsDelete;

  /// No description provided for @myPostsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get myPostsDeleteConfirm;

  /// No description provided for @myPostsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from the community. This cannot be undone.'**
  String get myPostsDeleteConfirmBody;

  /// No description provided for @myPostsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get myPostsEdit;

  /// No description provided for @editPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get editPostTitle;

  /// No description provided for @editPostSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editPostSave;

  /// No description provided for @editPostSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get editPostSaving;

  /// No description provided for @editPostSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get editPostSaved;

  /// No description provided for @editPostReReview.
  ///
  /// In en, this message translates to:
  /// **'Editing the message sends the post back for review.'**
  String get editPostReReview;

  /// No description provided for @postDetailThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Our team will review this post.'**
  String get postDetailThankYou;

  /// No description provided for @postDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postDetailTitle;

  /// No description provided for @postDetailReportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report this post'**
  String get postDetailReportTooltip;

  /// No description provided for @postDetailComments.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String postDetailComments(int count);

  /// No description provided for @postDetailNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get postDetailNoComments;

  /// No description provided for @postDetailWriteComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get postDetailWriteComment;

  /// No description provided for @postDetailPostComment.
  ///
  /// In en, this message translates to:
  /// **'Post comment'**
  String get postDetailPostComment;

  /// No description provided for @postDetailFlagPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Shows personal information'**
  String get postDetailFlagPersonalInfo;

  /// No description provided for @postDetailFlagHarmful.
  ///
  /// In en, this message translates to:
  /// **'Harmful or dangerous'**
  String get postDetailFlagHarmful;

  /// No description provided for @postDetailFlagSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get postDetailFlagSpam;

  /// No description provided for @postDetailFlagMisinfo.
  ///
  /// In en, this message translates to:
  /// **'Misinformation'**
  String get postDetailFlagMisinfo;

  /// No description provided for @postDetailFlagOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get postDetailFlagOther;

  /// No description provided for @postDetailReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get postDetailReply;

  /// No description provided for @postDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get postDetailEdit;

  /// No description provided for @postDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get postDetailDelete;

  /// No description provided for @postDetailSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get postDetailSave;

  /// No description provided for @postDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get postDetailCancel;

  /// No description provided for @postDetailReplying.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String postDetailReplying(String name);

  /// No description provided for @postDetailWriteReply.
  ///
  /// In en, this message translates to:
  /// **'Write a reply'**
  String get postDetailWriteReply;

  /// No description provided for @postDetailDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get postDetailDeleteConfirm;

  /// No description provided for @postDetailDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get postDetailDeleteConfirmBody;

  /// No description provided for @postDetailEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get postDetailEdited;

  /// No description provided for @postDetailRemovedComment.
  ///
  /// In en, this message translates to:
  /// **'This comment was removed.'**
  String get postDetailRemovedComment;

  /// No description provided for @guidanceClickedLink.
  ///
  /// In en, this message translates to:
  /// **'I clicked a link'**
  String get guidanceClickedLink;

  /// No description provided for @guidanceGotMessage.
  ///
  /// In en, this message translates to:
  /// **'I just got a message'**
  String get guidanceGotMessage;

  /// No description provided for @guidanceSharedPassword.
  ///
  /// In en, this message translates to:
  /// **'I shared my password'**
  String get guidanceSharedPassword;

  /// No description provided for @guidanceSentMoney.
  ///
  /// In en, this message translates to:
  /// **'I sent money'**
  String get guidanceSentMoney;

  /// No description provided for @guidanceCouldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get guidanceCouldNotOpenLink;

  /// No description provided for @guidanceCouldNotCall.
  ///
  /// In en, this message translates to:
  /// **'Could not start the call.'**
  String get guidanceCouldNotCall;

  /// No description provided for @guidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get guidanceTitle;

  /// No description provided for @guidanceWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get guidanceWhatHappened;

  /// No description provided for @guidanceWhoToContact.
  ///
  /// In en, this message translates to:
  /// **'Who to contact'**
  String get guidanceWhoToContact;

  /// No description provided for @guidanceShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get guidanceShowAll;

  /// No description provided for @guidanceOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open website'**
  String get guidanceOpenWebsite;

  /// No description provided for @guidanceNoAdvice.
  ///
  /// In en, this message translates to:
  /// **'No advice yet'**
  String get guidanceNoAdvice;

  /// No description provided for @guidanceNoAdviceBody.
  ///
  /// In en, this message translates to:
  /// **'Pick what happened to see what to do.'**
  String get guidanceNoAdviceBody;

  /// No description provided for @tourHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you protected?'**
  String get tourHomeTitle;

  /// No description provided for @tourHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Green means you are protected. If it is not green, tap it to turn protection on.'**
  String get tourHomeBody;

  /// No description provided for @tourCallsTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch for red calls'**
  String get tourCallsTitle;

  /// No description provided for @tourCallsBody.
  ///
  /// In en, this message translates to:
  /// **'Calls shown in red may be scams. Don\'t answer or call back.'**
  String get tourCallsBody;

  /// No description provided for @tourBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your blocked numbers'**
  String get tourBlockedTitle;

  /// No description provided for @tourBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the shield with a line through it to see numbers you blocked.'**
  String get tourBlockedBody;

  /// No description provided for @tourHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get tourHelpTitle;

  /// No description provided for @tourHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Tap ? on any screen to see what things mean.'**
  String get tourHelpBody;

  /// No description provided for @tourSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn protection on'**
  String get tourSafetyTitle;

  /// No description provided for @tourSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Turn protection on or off here. We warn you about scam messages.'**
  String get tourSafetyBody;

  /// No description provided for @tourReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a scam'**
  String get tourReportTitle;

  /// No description provided for @tourReportBody.
  ///
  /// In en, this message translates to:
  /// **'Tell others about a scam here so they can stay safe.'**
  String get tourReportBody;

  /// No description provided for @tourProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get tourProfileTitle;

  /// No description provided for @tourProfileBody.
  ///
  /// In en, this message translates to:
  /// **'See your posts and open settings here. You can replay this tour from settings.'**
  String get tourProfileBody;

  /// No description provided for @tourStepCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String tourStepCounter(int current, int total);

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// No description provided for @tourDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tourDone;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tourBack;

  /// No description provided for @helpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTooltip;

  /// No description provided for @helpGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get helpGotIt;

  /// No description provided for @helpShowTour.
  ///
  /// In en, this message translates to:
  /// **'Show the app tour again'**
  String get helpShowTour;

  /// No description provided for @helpCallsTitle.
  ///
  /// In en, this message translates to:
  /// **'What things mean'**
  String get helpCallsTitle;

  /// No description provided for @helpCallsHighRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Red call = likely scam'**
  String get helpCallsHighRiskTitle;

  /// No description provided for @helpCallsHighRiskBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t answer or call back.'**
  String get helpCallsHighRiskBody;

  /// No description provided for @helpCallsNormalTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal call'**
  String get helpCallsNormalTitle;

  /// No description provided for @helpCallsNormalBody.
  ///
  /// In en, this message translates to:
  /// **'No scam reports for this number.'**
  String get helpCallsNormalBody;

  /// No description provided for @helpCallsBlockedRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked call'**
  String get helpCallsBlockedRowTitle;

  /// No description provided for @helpCallsBlockedRowBody.
  ///
  /// In en, this message translates to:
  /// **'You blocked this number. It can\'t ring you.'**
  String get helpCallsBlockedRowBody;

  /// No description provided for @helpCallsBlockedListTitle.
  ///
  /// In en, this message translates to:
  /// **'Your blocked numbers'**
  String get helpCallsBlockedListTitle;

  /// No description provided for @helpCallsBlockedListBody.
  ///
  /// In en, this message translates to:
  /// **'Tap this to see or unblock numbers.'**
  String get helpCallsBlockedListBody;

  /// No description provided for @helpCallsMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get helpCallsMenuTitle;

  /// No description provided for @helpCallsMenuBody.
  ///
  /// In en, this message translates to:
  /// **'Check, block or report a number.'**
  String get helpCallsMenuBody;

  /// No description provided for @helpCallsRefreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get helpCallsRefreshTitle;

  /// No description provided for @helpCallsRefreshBody.
  ///
  /// In en, this message translates to:
  /// **'Check your calls again.'**
  String get helpCallsRefreshBody;

  /// No description provided for @helpCallsMissedBody.
  ///
  /// In en, this message translates to:
  /// **'You did not answer this call.'**
  String get helpCallsMissedBody;

  /// No description provided for @helpCallsAnsweredBody.
  ///
  /// In en, this message translates to:
  /// **'You answered this call.'**
  String get helpCallsAnsweredBody;

  /// No description provided for @helpCallsRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'You turned down this call.'**
  String get helpCallsRejectedBody;

  /// No description provided for @helpCallsBlockedIconBody.
  ///
  /// In en, this message translates to:
  /// **'This call was stopped.'**
  String get helpCallsBlockedIconBody;

  /// No description provided for @helpCallsOutgoingBody.
  ///
  /// In en, this message translates to:
  /// **'You called this number.'**
  String get helpCallsOutgoingBody;

  /// No description provided for @callsLikelyScam.
  ///
  /// In en, this message translates to:
  /// **'Likely scam'**
  String get callsLikelyScam;

  /// No description provided for @callsMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get callsMoreOptions;

  /// No description provided for @callsBlockNumber.
  ///
  /// In en, this message translates to:
  /// **'Block number'**
  String get callsBlockNumber;

  /// No description provided for @callsReportScam.
  ///
  /// In en, this message translates to:
  /// **'Report as scam'**
  String get callsReportScam;

  /// No description provided for @callsBlockAndReport.
  ///
  /// In en, this message translates to:
  /// **'Block and report'**
  String get callsBlockAndReport;

  /// No description provided for @callsCheckNumber.
  ///
  /// In en, this message translates to:
  /// **'Check number'**
  String get callsCheckNumber;

  /// No description provided for @callsLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get callsLoadFailedBody;

  /// No description provided for @callsBlockedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Numbers you block will show here.'**
  String get callsBlockedEmptyBody;

  /// No description provided for @callsContactsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t show your contacts. Please try again.'**
  String get callsContactsLoadFailed;

  /// No description provided for @callsCallTooltip.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callsCallTooltip;
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
      <String>['en', 'ms', 'ta', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'ta':
      return AppLocalizationsTa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
