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

  /// No description provided for @commonSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing...'**
  String get commonSharing;

  /// No description provided for @commonDownloadModelFirst.
  ///
  /// In en, this message translates to:
  /// **'Download a model in the Settings tab first'**
  String get commonDownloadModelFirst;

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

  /// No description provided for @commonTagsOptional.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional)'**
  String get commonTagsOptional;

  /// No description provided for @commonShareIntro.
  ///
  /// In en, this message translates to:
  /// **'Help others by sharing a scam you received. Remove any personal details first.'**
  String get commonShareIntro;

  /// No description provided for @settingsDetectionModel.
  ///
  /// In en, this message translates to:
  /// **'Detection model'**
  String get settingsDetectionModel;

  /// No description provided for @settingsProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get settingsProtection;

  /// No description provided for @settingsClearNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear captured notifications'**
  String get settingsClearNotifications;

  /// No description provided for @settingsStopProtection.
  ///
  /// In en, this message translates to:
  /// **'Stop background protection'**
  String get settingsStopProtection;

  /// No description provided for @settingsServiceRunning.
  ///
  /// In en, this message translates to:
  /// **'Service running'**
  String get settingsServiceRunning;

  /// No description provided for @settingsServiceStopped.
  ///
  /// In en, this message translates to:
  /// **'Service stopped'**
  String get settingsServiceStopped;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsShowTutorial.
  ///
  /// In en, this message translates to:
  /// **'Show tutorial again'**
  String get settingsShowTutorial;

  /// No description provided for @settingsReplayTour.
  ///
  /// In en, this message translates to:
  /// **'Replay the app feature overview'**
  String get settingsReplayTour;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogOut;

  /// No description provided for @settingsSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get settingsSignOutSubtitle;

  /// No description provided for @settingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvanced;

  /// No description provided for @settingsAdvancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Developer and model-tuning options'**
  String get settingsAdvancedSubtitle;

  /// No description provided for @settingsModelFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Model from this device (testing)'**
  String get settingsModelFromDevice;

  /// No description provided for @settingsScanForModels.
  ///
  /// In en, this message translates to:
  /// **'Scan for model files'**
  String get settingsScanForModels;

  /// No description provided for @settingsScanningStorage.
  ///
  /// In en, this message translates to:
  /// **'Scanning storage…'**
  String get settingsScanningStorage;

  /// No description provided for @settingsScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finds .litertlm and .task files in Downloads and Documents'**
  String get settingsScanSubtitle;

  /// No description provided for @settingsModelFilePath.
  ///
  /// In en, this message translates to:
  /// **'Model file path'**
  String get settingsModelFilePath;

  /// No description provided for @settingsModelFilePathHelper.
  ///
  /// In en, this message translates to:
  /// **'Typed paths work too. The file is used in place — it is never copied.'**
  String get settingsModelFilePathHelper;

  /// No description provided for @settingsContextWindow.
  ///
  /// In en, this message translates to:
  /// **'Context window (tokens)'**
  String get settingsContextWindow;

  /// No description provided for @settingsContextWindowHelper.
  ///
  /// In en, this message translates to:
  /// **'Context to request when loading. Must not exceed what your conversion baked in as kv_cache_max_len (MiniCPM5-2B supports up to {max}). Larger windows cost roughly 40 KB of RAM per token.'**
  String settingsContextWindowHelper(int max);

  /// No description provided for @settingsContextRange.
  ///
  /// In en, this message translates to:
  /// **'Enter between 1024 and {max}'**
  String settingsContextRange(int max);

  /// No description provided for @settingsThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking (reasoning)'**
  String get settingsThinking;

  /// No description provided for @settingsThinkingHelper.
  ///
  /// In en, this message translates to:
  /// **'Lets the model reason before answering. Uses more tokens and is slower; needs a 3000+ token context to be useful.'**
  String get settingsThinkingHelper;

  /// No description provided for @settingsLoadModelFromFile.
  ///
  /// In en, this message translates to:
  /// **'Load model from file'**
  String get settingsLoadModelFromFile;

  /// No description provided for @settingsCloudThreshold.
  ///
  /// In en, this message translates to:
  /// **'Cloud escalation threshold — escalate below {pct}%'**
  String settingsCloudThreshold(int pct);

  /// No description provided for @settingsCloudReview.
  ///
  /// In en, this message translates to:
  /// **'Cloud review'**
  String get settingsCloudReview;

  /// No description provided for @settingsForceCloud.
  ///
  /// In en, this message translates to:
  /// **'Force cloud'**
  String get settingsForceCloud;

  /// No description provided for @settingsForceCloudHelper.
  ///
  /// In en, this message translates to:
  /// **'Send every message to the cloud model and skip the on-device model. Falls back to on-device only if the cloud is unreachable.'**
  String get settingsForceCloudHelper;

  /// No description provided for @settingsEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get settingsEndpoint;

  /// No description provided for @settingsEndpointHint.
  ///
  /// In en, this message translates to:
  /// **'https://.../v1/chat/completions (empty = disabled)'**
  String get settingsEndpointHint;

  /// No description provided for @settingsModelName.
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get settingsModelName;

  /// No description provided for @settingsOnDeviceModel.
  ///
  /// In en, this message translates to:
  /// **'On-device model — {name}'**
  String settingsOnDeviceModel(String name);

  /// No description provided for @settingsReadyKept.
  ///
  /// In en, this message translates to:
  /// **'Ready · {mb} MB · kept in Downloads (survives reinstall)'**
  String settingsReadyKept(int mb);

  /// No description provided for @settingsReadyOffline.
  ///
  /// In en, this message translates to:
  /// **'Ready · {mb} MB · runs offline'**
  String settingsReadyOffline(int mb);

  /// No description provided for @settingsInstallingBundled.
  ///
  /// In en, this message translates to:
  /// **'Installing bundled model {pct}%'**
  String settingsInstallingBundled(int pct);

  /// No description provided for @settingsDownloadingPct.
  ///
  /// In en, this message translates to:
  /// **'Downloading {pct}%'**
  String settingsDownloadingPct(int pct);

  /// No description provided for @settingsBundledPreparing.
  ///
  /// In en, this message translates to:
  /// **'Bundled with the app · preparing'**
  String get settingsBundledPreparing;

  /// No description provided for @settingsNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded ({mb} MB)'**
  String settingsNotDownloaded(int mb);

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

  /// No description provided for @settingsInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get settingsInstall;

  /// No description provided for @settingsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get settingsDownload;

  /// No description provided for @settingsNoFilePicked.
  ///
  /// In en, this message translates to:
  /// **'No file picked yet'**
  String get settingsNoFilePicked;

  /// No description provided for @settingsScanHint.
  ///
  /// In en, this message translates to:
  /// **'Scan for a model file that is already on this phone.'**
  String get settingsScanHint;

  /// No description provided for @settingsCustomModelMeta.
  ///
  /// In en, this message translates to:
  /// **'{path} · {mb} MB · {tokens} tokens'**
  String settingsCustomModelMeta(String path, int mb, int tokens);

  /// No description provided for @settingsForget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get settingsForget;

  /// No description provided for @settingsAllFilesAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow \"All files access\" for Scam Shield in Android settings, then scan again.'**
  String get settingsAllFilesAccess;

  /// No description provided for @settingsNoModelFiles.
  ///
  /// In en, this message translates to:
  /// **'No .litertlm or .task files found.\n\nPut the model in Downloads (or type its path below) and scan again.'**
  String get settingsNoModelFiles;

  /// No description provided for @settingsFileSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{mb} MB'**
  String settingsFileSizeMb(int mb);

  /// No description provided for @settingsEnterPathFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter a model file path first'**
  String get settingsEnterPathFirst;

  /// No description provided for @settingsModelLoaded.
  ///
  /// In en, this message translates to:
  /// **'{name} loaded'**
  String settingsModelLoaded(String name);

  /// No description provided for @settingsModelForgotten.
  ///
  /// In en, this message translates to:
  /// **'Picked model forgotten — file kept on device'**
  String get settingsModelForgotten;

  /// No description provided for @settingsSizeFromDevice.
  ///
  /// In en, this message translates to:
  /// **'~{mb} MB · from this device'**
  String settingsSizeFromDevice(int mb);

  /// No description provided for @settingsSizeBundled.
  ///
  /// In en, this message translates to:
  /// **'~{mb} MB · bundled'**
  String settingsSizeBundled(int mb);

  /// No description provided for @settingsSizeDownload.
  ///
  /// In en, this message translates to:
  /// **'~{mb} MB · download'**
  String settingsSizeDownload(int mb);

  /// No description provided for @settingsFieldSaved.
  ///
  /// In en, this message translates to:
  /// **'{label} saved'**
  String settingsFieldSaved(String label);

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

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

  /// No description provided for @callRemovedReport.
  ///
  /// In en, this message translates to:
  /// **'Removed report for {number}'**
  String callRemovedReport(String number);

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

  /// No description provided for @callHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Call History'**
  String get callHistoryTitle;

  /// No description provided for @callBlockedNumbers.
  ///
  /// In en, this message translates to:
  /// **'Blocked numbers'**
  String get callBlockedNumbers;

  /// No description provided for @callNoUnknown.
  ///
  /// In en, this message translates to:
  /// **'No unknown-number calls found'**
  String get callNoUnknown;

  /// No description provided for @callPhonePermNeeded.
  ///
  /// In en, this message translates to:
  /// **'Phone permission needed'**
  String get callPhonePermNeeded;

  /// No description provided for @callPhonePermBody.
  ///
  /// In en, this message translates to:
  /// **'Call Manager needs the Phone permission to read your call history.'**
  String get callPhonePermBody;

  /// No description provided for @callGrantPhone.
  ///
  /// In en, this message translates to:
  /// **'Grant phone permission'**
  String get callGrantPhone;

  /// No description provided for @callCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load call history'**
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

  /// No description provided for @callBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get callBlock;

  /// No description provided for @callUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get callUnblock;

  /// No description provided for @callRemoveReport.
  ///
  /// In en, this message translates to:
  /// **'Remove report'**
  String get callRemoveReport;

  /// No description provided for @callBlockAndReport.
  ///
  /// In en, this message translates to:
  /// **'Block & Report'**
  String get callBlockAndReport;

  /// No description provided for @reportPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get reportPhone;

  /// No description provided for @reportUnknownApp.
  ///
  /// In en, this message translates to:
  /// **'Unknown app'**
  String get reportUnknownApp;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSent;

  /// No description provided for @reportNotSent.
  ///
  /// In en, this message translates to:
  /// **'Report not sent — reporting endpoint is not configured yet'**
  String get reportNotSent;

  /// No description provided for @reportAddAppFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an application first.'**
  String get reportAddAppFirst;

  /// No description provided for @reportAsScam.
  ///
  /// In en, this message translates to:
  /// **'Report this message as a scam?'**
  String get reportAsScam;

  /// No description provided for @reportSuspiciousMessages.
  ///
  /// In en, this message translates to:
  /// **'Suspicious messages'**
  String get reportSuspiciousMessages;

  /// No description provided for @reportTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap “Report this” on anything that looks like a scam.'**
  String get reportTapHint;

  /// No description provided for @reportNothingSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Nothing suspicious right now'**
  String get reportNothingSuspicious;

  /// No description provided for @reportVerdictSummary.
  ///
  /// In en, this message translates to:
  /// **'{label} · {pct}% sure'**
  String reportVerdictSummary(String label, int pct);

  /// No description provided for @reportRecentCalls.
  ///
  /// In en, this message translates to:
  /// **'Recent calls'**
  String get reportRecentCalls;

  /// No description provided for @reportNoCalls.
  ///
  /// In en, this message translates to:
  /// **'No calls recorded yet'**
  String get reportNoCalls;

  /// No description provided for @reportSomethingElse.
  ///
  /// In en, this message translates to:
  /// **'Report something else'**
  String get reportSomethingElse;

  /// No description provided for @reportWriteOwn.
  ///
  /// In en, this message translates to:
  /// **'Write your own report'**
  String get reportWriteOwn;

  /// No description provided for @reportNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Number (optional)'**
  String get reportNumberOptional;

  /// No description provided for @reportAppRequired.
  ///
  /// In en, this message translates to:
  /// **'Application (required)'**
  String get reportAppRequired;

  /// No description provided for @reportAppHint.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp, Telegram, Phone…'**
  String get reportAppHint;

  /// No description provided for @reportMarkAs.
  ///
  /// In en, this message translates to:
  /// **'Mark as'**
  String get reportMarkAs;

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

  /// No description provided for @reportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'What did they do or say?'**
  String get reportReasonHint;

  /// No description provided for @reportOtherComments.
  ///
  /// In en, this message translates to:
  /// **'Other comments'**
  String get reportOtherComments;

  /// No description provided for @reportOtherCommentsHint.
  ///
  /// In en, this message translates to:
  /// **'Anything else we should know (optional)'**
  String get reportOtherCommentsHint;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// No description provided for @reportSubjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {subject}?'**
  String reportSubjectTitle(String subject);

  /// No description provided for @reportReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reportReasonOptional;

  /// No description provided for @shieldTurnOnToRun.
  ///
  /// In en, this message translates to:
  /// **'Turn on protection to run the model'**
  String get shieldTurnOnToRun;

  /// No description provided for @shieldCheckingMessage.
  ///
  /// In en, this message translates to:
  /// **'Checking the message...'**
  String get shieldCheckingMessage;

  /// No description provided for @shieldScamAi.
  ///
  /// In en, this message translates to:
  /// **'Scam AI'**
  String get shieldScamAi;

  /// No description provided for @shieldModelReady.
  ///
  /// In en, this message translates to:
  /// **'On-device model ready'**
  String get shieldModelReady;

  /// No description provided for @shieldNoModel.
  ///
  /// In en, this message translates to:
  /// **'No on-device model installed'**
  String get shieldNoModel;

  /// No description provided for @shieldStats.
  ///
  /// In en, this message translates to:
  /// **'Checked {evaluated} messages, raised {alerts} alerts'**
  String shieldStats(int evaluated, int alerts);

  /// No description provided for @shieldTryMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a message'**
  String get shieldTryMessage;

  /// No description provided for @shieldPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a suspicious message...'**
  String get shieldPasteHint;

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
  /// **'Notification access'**
  String get permNotificationAccess;

  /// No description provided for @permNotificationAccessSub.
  ///
  /// In en, this message translates to:
  /// **'Reads messages from notifications'**
  String get permNotificationAccessSub;

  /// No description provided for @permOverlay.
  ///
  /// In en, this message translates to:
  /// **'Display over other apps'**
  String get permOverlay;

  /// No description provided for @permOverlaySub.
  ///
  /// In en, this message translates to:
  /// **'Shows the scam alert while a call is ringing'**
  String get permOverlaySub;

  /// No description provided for @permAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts allowed'**
  String get permAlerts;

  /// No description provided for @permAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Posts scam alerts as notifications'**
  String get permAlertsSub;

  /// No description provided for @permGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get permGranted;

  /// No description provided for @permGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get permGrant;

  /// No description provided for @permScreeningRole.
  ///
  /// In en, this message translates to:
  /// **'Call screening role'**
  String get permScreeningRole;

  /// No description provided for @permScreeningRoleSub.
  ///
  /// In en, this message translates to:
  /// **'Lets the app screen incoming calls and block numbers you mark as spam.'**
  String get permScreeningRoleSub;

  /// No description provided for @permScreeningActive.
  ///
  /// In en, this message translates to:
  /// **'Screening active'**
  String get permScreeningActive;

  /// No description provided for @permEnableScreening.
  ///
  /// In en, this message translates to:
  /// **'Enable call screening'**
  String get permEnableScreening;

  /// No description provided for @permScreeningNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Call screening is not granted yet'**
  String get permScreeningNotGranted;

  /// No description provided for @permScreeningTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Enable call screening\" above, otherwise calls will still ring through.'**
  String get permScreeningTapHint;

  /// No description provided for @permTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permTitle;

  /// No description provided for @permGrantFollowing.
  ///
  /// In en, this message translates to:
  /// **'Grant the following permissions for full access.'**
  String get permGrantFollowing;

  /// No description provided for @permPhoneCallLog.
  ///
  /// In en, this message translates to:
  /// **'Phone & Call Log'**
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
  /// **'Open the system settings for this app to manually assign the call screening role and permissions.'**
  String get permOpenSettingsBody;

  /// No description provided for @permOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get permOpenAppSettings;

  /// No description provided for @permNotChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked'**
  String get permNotChecked;

  /// No description provided for @permStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get permStatusDenied;

  /// No description provided for @permPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permanently denied'**
  String get permPermanentlyDenied;

  /// No description provided for @permNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get permNotGranted;

  /// No description provided for @contactsPermRequired.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is required to view contacts'**
  String get contactsPermRequired;

  /// No description provided for @contactsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contacts: {error}'**
  String contactsLoadFailed(String error);

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @contactsOpenMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get contactsOpenMenu;

  /// No description provided for @contactsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
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
  /// **'Could not initiate call'**
  String get contactsCouldNotCall;

  /// No description provided for @contactsCouldNotCallError.
  ///
  /// In en, this message translates to:
  /// **'Could not initiate call: {error}'**
  String contactsCouldNotCallError(String error);

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

  /// No description provided for @safetyDownloadFirstPeriod.
  ///
  /// In en, this message translates to:
  /// **'Download a model in the Settings tab first.'**
  String get safetyDownloadFirstPeriod;

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

  /// No description provided for @safetyNoScams.
  ///
  /// In en, this message translates to:
  /// **'No scams found'**
  String get safetyNoScams;

  /// No description provided for @safetyNoScamsBody.
  ///
  /// In en, this message translates to:
  /// **'Suspicious messages will show up here.'**
  String get safetyNoScamsBody;

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

  /// No description provided for @protectionReadsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Reads notifications from messaging apps'**
  String get protectionReadsNotifications;

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
  /// **'No messages captured yet.'**
  String get activityNoMessages;

  /// No description provided for @activityNotCheckedSuffix.
  ///
  /// In en, this message translates to:
  /// **' · not checked'**
  String get activityNotCheckedSuffix;

  /// No description provided for @activityCloudSuffix.
  ///
  /// In en, this message translates to:
  /// **' · cloud'**
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
  /// **'{wire} (escalated)'**
  String activityEscalatedSuffix(String wire);

  /// No description provided for @activityReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get activityReason;

  /// No description provided for @activityAiThinking.
  ///
  /// In en, this message translates to:
  /// **'AI thinking'**
  String get activityAiThinking;

  /// No description provided for @activityNoOutput.
  ///
  /// In en, this message translates to:
  /// **'(the model produced no readable output)'**
  String get activityNoOutput;

  /// No description provided for @blockedNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked Numbers'**
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

  /// No description provided for @settingsScreenModelInstalled.
  ///
  /// In en, this message translates to:
  /// **'{name} installed'**
  String settingsScreenModelInstalled(String name);

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @settingsScreenModelTab.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsScreenModelTab;

  /// No description provided for @settingsScreenPermissionsTab.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get settingsScreenPermissionsTab;

  /// No description provided for @loginAppName.
  ///
  /// In en, this message translates to:
  /// **'Call Manager'**
  String get loginAppName;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Keeps you safe from scam calls and messages.'**
  String get loginTagline;

  /// No description provided for @loginGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get loginGetStarted;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get onboardingTitle;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

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
  /// **'Join the community to share and learn about scams.'**
  String get authRegisterIntro;

  /// No description provided for @authLoginIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign in to post and join discussions.'**
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
  /// **'Scam reports shared by the community will show up here.'**
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
  /// **'Report a scam'**
  String get reportTabTitle;

  /// No description provided for @reportTabThankYou.
  ///
  /// In en, this message translates to:
  /// **'Shared with the community. Thank you!'**
  String get reportTabThankYou;

  /// No description provided for @reportTabTrackIt.
  ///
  /// In en, this message translates to:
  /// **'Shared with the community. Check My posts to track it.'**
  String get reportTabTrackIt;

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
  /// **'Pick what happened above to see steps you can take.'**
  String get guidanceNoAdviceBody;

  /// No description provided for @tourCallsTitle.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get tourCallsTitle;

  /// No description provided for @tourCallsBody.
  ///
  /// In en, this message translates to:
  /// **'This is where calls from unknown numbers show up. Tap a call to see details, and use the block icon in the top corner to manage numbers you never want to hear from again.'**
  String get tourCallsBody;

  /// No description provided for @tourSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get tourSafetyTitle;

  /// No description provided for @tourSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on protection here. Once a model is downloaded, Scam Shield reads incoming messages on your device and warns you about likely scams.'**
  String get tourSafetyBody;

  /// No description provided for @tourReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get tourReportTitle;

  /// No description provided for @tourReportBody.
  ///
  /// In en, this message translates to:
  /// **'Spotted a scam? Share it with the community from this tab so other people can recognise the same trick and stay safe.'**
  String get tourReportBody;

  /// No description provided for @tourMyPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get tourMyPostsTitle;

  /// No description provided for @tourMyPostsBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you report lands here. Track the discussion and see when a moderator has reviewed your post.'**
  String get tourMyPostsBody;

  /// No description provided for @tourSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tourSettingsTitle;

  /// No description provided for @tourSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Download a protection model, manage permissions, and replay this tour any time from the Account section.'**
  String get tourSettingsBody;

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
