import 'package:flutter/widgets.dart';

/// A single step in the interactive app tour.
///
/// Each step switches the app to [tabIndex] and spotlights the widget whose
/// [GlobalKey] is registered for that step (resolved at runtime by the overlay
/// via [CoachMarkTargets]). The spotlight falls back to centring the tooltip
/// when no target is available (e.g. the target has not been laid out yet).
class TourStep {
  const TourStep({required this.tabIndex});

  /// The bottom-navigation tab this step belongs to. The tour switches to this
  /// tab before showing the step so the highlighted element is on screen.
  ///
  /// The step's identity for localized text lookup is its index within
  /// [kTourSteps] (0=Calls, 1=Safety, 2=Report, 3=My Posts, 4=Settings), which
  /// the overlay resolves against [AppLocalizations] at display time.
  final int tabIndex;
}

/// The ordered list of tour steps. One step per tab, walked front to back.
///
/// Steps carry only their [TourStep.tabIndex]; the display copy is resolved at
/// render time in the overlay via [AppLocalizations], keyed off each step's
/// position in this list. The spotlight is anchored to the matching bottom-nav
/// destination (see [CoachMarkTargets]).
const List<TourStep> kTourSteps = [
  TourStep(tabIndex: 0),
  TourStep(tabIndex: 1),
  TourStep(tabIndex: 2),
  TourStep(tabIndex: 3),
  TourStep(tabIndex: 4),
];

/// Holds the [GlobalKey]s for each tab's spotlight target.
///
/// [HomePage] attaches one key per bottom-navigation destination and exposes
/// them to the overlay so each step can measure the on-screen rect of the tab
/// it is describing.
class CoachMarkTargets {
  CoachMarkTargets(int tabCount)
      : navKeys = List.generate(tabCount, (_) => GlobalKey());

  /// One key per bottom-navigation destination, indexed by tab.
  final List<GlobalKey> navKeys;

  /// Returns the key for [tabIndex], or null when out of range.
  GlobalKey? keyForTab(int tabIndex) {
    if (tabIndex < 0 || tabIndex >= navKeys.length) return null;
    return navKeys[tabIndex];
  }
}
