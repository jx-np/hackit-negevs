import 'package:flutter/widgets.dart';
import 'package:scamwatch_mobile_app/services/protection_settings.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_models.dart';

/// Drives the interactive coach-mark tour.
///
/// Owns the active state and the current step index. It does not switch tabs
/// itself; `HomePage` supplies [onShowTab] so each step's tab is on screen
/// before the overlay spotlights it. `CoachMarkOverlay` listens and rebuilds.
class TourController extends ChangeNotifier {
  /// [readSeen] and [writeSeen] let a secondary tour (e.g. the post screen's)
  /// keep its own "already shown" flag. They default to the app-wide tour flag.
  TourController({
    required this.steps,
    ProtectionSettings? settings,
    Future<bool> Function()? readSeen,
    Future<void> Function()? writeSeen,
  })  : _settings = settings ?? ProtectionSettings(),
        _readSeen = readSeen,
        _writeSeen = writeSeen;

  final List<TourStep> steps;
  final ProtectionSettings _settings;
  final Future<bool> Function()? _readSeen;
  final Future<void> Function()? _writeSeen;

  /// Invoked with the tab index each step wants on screen. Set by `HomePage`.
  void Function(int tabIndex)? onShowTab;

  bool _active = false;
  int _index = 0;

  bool get active => _active;
  int get index => _index;

  /// The step currently being shown, or null when the tour is inactive.
  TourStep? get currentStep =>
      _active && _index >= 0 && _index < steps.length ? steps[_index] : null;

  bool get isFirstStep => _index <= 0;
  bool get isLastStep => _index >= steps.length - 1;

  /// Starts the tour from the first step and shows that step's tab.
  void start() {
    if (steps.isEmpty) return;
    _active = true;
    _index = 0;
    _showCurrentTab();
    notifyListeners();
  }

  /// Advances to the next step, or finishes after the last one.
  void next() {
    if (!_active) return;
    if (isLastStep) {
      finish();
      return;
    }
    _index += 1;
    _showCurrentTab();
    notifyListeners();
  }

  /// Goes back one step. No-op on the first step.
  void back() {
    if (!_active || isFirstStep) return;
    _index -= 1;
    _showCurrentTab();
    notifyListeners();
  }

  /// Ends the tour early. Still marks it as seen so it does not reappear.
  void skip() => finish();

  /// Ends the tour and persists that the user has seen it.
  void finish() {
    if (!_active) return;
    _active = false;
    _index = 0;
    // Fire-and-forget: persisting the flag must not block the UI teardown.
    final writeSeen = _writeSeen;
    if (writeSeen != null) {
      writeSeen();
    } else {
      _settings.setSeenTutorial(true);
    }
    notifyListeners();
  }

  /// Returns true when the first-launch tour has not been shown yet.
  Future<bool> shouldAutoStart() async {
    final seen = await (_readSeen?.call() ?? _settings.seenTutorial());
    return !seen;
  }

  void _showCurrentTab() {
    final step = currentStep;
    if (step != null) onShowTab?.call(step.tabIndex);
  }
}
