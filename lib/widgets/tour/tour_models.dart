import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/screens/calls/widgets/calls_help.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_post_sample.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_review_sample.dart';

/// Resolves a localized string for a tour step.
typedef TourText = String Function(AppLocalizations l10n);

/// Everything the tour can spotlight.
///
/// The `nav*` values map to the bottom-navigation tabs and are always
/// attached by `HomePage` (see [CoachMarkTargets.keyForTab]). The others are
/// attached by the screen that owns the widget, via
/// `CoachMarkTargets.keyOf(context, TourTarget.x)`.
enum TourTarget {
  navHome(tabIndex: 0),
  navCalls(tabIndex: 1),
  navSafety(tabIndex: 2),
  navReport(tabIndex: 3),
  navProfile(tabIndex: 4),

  /// The protection status card at the top of Home.
  homeStatus,

  /// The "blocked numbers" (shield with a slash) button in the Calls app bar.
  callsBlockedButton,

  /// The "?" help button in the Calls app bar.
  callsHelpButton,

  /// The protection on/off card on the Safety tab.
  safetyStatus,

  /// The main "report a scam" action on the Report tab.
  reportCreate,

  /// The "I checked the photos" tick on the Report tab. Only mounted once
  /// photos are attached, so the step falls back to the Report nav tab.
  reportReview,

  /// The comment box on the post screen, where `@help` summons the AI helper.
  postCommentField,

  /// The "Comments" heading on the post screen, above the replies.
  postComments,

  /// The settings button on the Profile tab.
  profileSettings;

  const TourTarget({this.tabIndex});

  /// The bottom-nav tab index for `nav*` targets, null for in-screen targets.
  final int? tabIndex;
}

/// A single step in the interactive app tour.
///
/// The tour switches to [tabIndex], then spotlights [target]. When [target]
/// is not on screen, the overlay falls back to the [tabIndex] nav tab, and
/// then to a centred bubble with no spotlight.
class TourStep {
  const TourStep({
    required this.tabIndex,
    required this.target,
    required this.title,
    required this.body,
    this.illustration,
  });

  /// The bottom-navigation tab shown while this step is active.
  final int tabIndex;

  /// What to spotlight.
  final TourTarget target;

  /// Short headline, resolved at display time so it follows the app locale.
  final TourText title;

  /// One or two short sentences.
  final TourText body;

  /// Optional picture shown in the bubble above [body] (e.g. a sample row).
  final WidgetBuilder? illustration;
}

String _homeTitle(AppLocalizations l) => l.tourHomeTitle;
String _homeBody(AppLocalizations l) => l.tourHomeBody;
String _callsTitle(AppLocalizations l) => l.tourCallsTitle;
String _callsBody(AppLocalizations l) => l.tourCallsBody;
String _blockedTitle(AppLocalizations l) => l.tourBlockedTitle;
String _blockedBody(AppLocalizations l) => l.tourBlockedBody;
String _helpTitle(AppLocalizations l) => l.tourHelpTitle;
String _helpBody(AppLocalizations l) => l.tourHelpBody;
String _safetyTitle(AppLocalizations l) => l.tourSafetyTitle;
String _safetyBody(AppLocalizations l) => l.tourSafetyBody;
String _reportTitle(AppLocalizations l) => l.tourReportTitle;
String _reportBody(AppLocalizations l) => l.tourReportBody;
String _reviewTitle(AppLocalizations l) => l.tourReviewTitle;
String _reviewBody(AppLocalizations l) => l.tourReviewBody;
String _postHelpTitle(AppLocalizations l) => l.tourPostHelpTitle;
String _postHelpBody(AppLocalizations l) => l.tourPostHelpBody;
String _postAiTitle(AppLocalizations l) => l.tourPostAiTitle;
String _postAiBody(AppLocalizations l) => l.tourPostAiBody;
String _profileTitle(AppLocalizations l) => l.tourProfileTitle;
String _profileBody(AppLocalizations l) => l.tourProfileBody;

/// Number of bottom-navigation tabs in `HomePage`.
const int kTourTabCount = 5;

/// The ordered tour. Kept short on purpose: one idea per step.
const List<TourStep> kTourSteps = [
  TourStep(
    tabIndex: 0,
    target: TourTarget.homeStatus,
    title: _homeTitle,
    body: _homeBody,
  ),
  TourStep(
    tabIndex: 1,
    target: TourTarget.navCalls,
    title: _callsTitle,
    body: _callsBody,
    illustration: buildTourSampleCallRow,
  ),
  TourStep(
    tabIndex: 1,
    target: TourTarget.callsBlockedButton,
    title: _blockedTitle,
    body: _blockedBody,
  ),
  TourStep(
    tabIndex: 1,
    target: TourTarget.callsHelpButton,
    title: _helpTitle,
    body: _helpBody,
  ),
  TourStep(
    tabIndex: 2,
    target: TourTarget.safetyStatus,
    title: _safetyTitle,
    body: _safetyBody,
  ),
  TourStep(
    tabIndex: 3,
    target: TourTarget.reportCreate,
    title: _reportTitle,
    body: _reportBody,
  ),
  TourStep(
    tabIndex: 3,
    target: TourTarget.reportReview,
    title: _reviewTitle,
    body: _reviewBody,
    illustration: buildTourSampleReviewTick,
  ),
  TourStep(
    tabIndex: 4,
    target: TourTarget.profileSettings,
    title: _profileTitle,
    body: _profileBody,
  ),
];

/// Tab index for steps that are not tied to a bottom-nav tab (the post
/// screen's tour). `CoachMarkTargets.keyForTab` returns null for it.
const int kNoTab = -1;

/// The short tour shown the first time a post is opened. It runs on the post
/// screen itself, with its own overlay and its own "already seen" flag.
const List<TourStep> kPostTourSteps = [
  TourStep(
    tabIndex: kNoTab,
    target: TourTarget.postCommentField,
    title: _postHelpTitle,
    body: _postHelpBody,
    illustration: buildTourSampleHelpComment,
  ),
  TourStep(
    tabIndex: kNoTab,
    target: TourTarget.postComments,
    title: _postAiTitle,
    body: _postAiBody,
    illustration: buildTourSampleAiReply,
  ),
];

/// Holds the [GlobalKey]s the tour can spotlight.
///
/// `HomePage` attaches [keyForTab] to each bottom-nav destination. Screens
/// attach [keyFor] (or the null-safe [keyOf]) to their own widgets. Each key
/// must be attached to exactly one mounted widget at a time.
class CoachMarkTargets {
  CoachMarkTargets(int tabCount)
      : navKeys = List.generate(tabCount, (_) => GlobalKey());

  /// One key per bottom-navigation destination, indexed by tab.
  final List<GlobalKey> navKeys;

  final Map<TourTarget, GlobalKey> _keys = {};

  /// Returns the key for [tabIndex], or null when out of range.
  GlobalKey? keyForTab(int tabIndex) {
    if (tabIndex < 0 || tabIndex >= navKeys.length) return null;
    return navKeys[tabIndex];
  }

  /// Returns the key for [target]. `nav*` targets share the nav-tab keys.
  GlobalKey keyFor(TourTarget target) {
    final tab = target.tabIndex;
    if (tab != null) {
      final navKey = keyForTab(tab);
      if (navKey != null) return navKey;
    }
    return _keys.putIfAbsent(target, () => GlobalKey());
  }

  /// Key for [target] from the nearest [CoachMarkTargets] provider, or null
  /// when there is none (e.g. in tests or a screen opened outside HomePage).
  static GlobalKey? keyOf(BuildContext context, TourTarget target) {
    try {
      return Provider.of<CoachMarkTargets>(context, listen: false)
          .keyFor(target);
    } on ProviderNotFoundException {
      return null;
    }
  }
}
