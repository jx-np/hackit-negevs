import 'package:flutter/widgets.dart';

import '../../services/protection_settings.dart';
import 'tour_models.dart';

/// Drives the interactive coach-mark tour.
///
/// The controller owns the active state and the current step index. It does not
/// know how to switch tabs itself; [HomePage] supplies an [onShowTab] callback
/// so the controller can bring each step's tab on screen before highlighting
/// it. The overlay widget listens to this controller and rebuilds as the tour
/// advances.
class TourController extends ChangeNotifier {
  TourController({required this.steps, ProtectionSettings? settings})
      : _settings = settings ?? ProtectionSettings();

  final List<TourStep> steps;
  final ProtectionSettings _settings;

  /// Invoked with the tab index each step wants on screen. Set by [HomePage].
  void Function(int tabIndex)? onShowTab;

  bool _active = false;
  int _index = 0;

  bool get active => _active;
  int get index => _index;

  /// The step currently being shown, or null when the tour is inactive.
  TourStep? get currentStep =>
      _active && _index >= 0 && _index < steps.length ? steps[_index] : null;

  bool get isLastStep => _index >= steps.length - 1;

  /// Starts the tour from the first step and shows that step's tab.
  void start() {
    if (steps.isEmpty) return;
    _active = true;
    _index = 0;
    _showCurrentTab();
    notifyListeners();
  }

  /// Advances to the next step, or finishes when past the last step.
  void next() {
    if (!_active) return;
    if (_index >= steps.length - 1) {
      finish();
      return;
    }
    _index += 1;
    _showCurrentTab();
    notifyListeners();
  }

  /// Ends the tour early. Still marks the tour as seen so it does not reappear
  /// on the next launch.
  void skip() => finish();

  /// Ends the tour and persists that the user has seen it.
  void finish() {
    if (!_active) return;
    _active = false;
    _index = 0;
    // Fire-and-forget: persisting the flag must not block the UI teardown.
    _settings.setSeenTutorial(true);
    notifyListeners();
  }

  /// Returns true when the first-launch tour has not been shown yet.
  Future<bool> shouldAutoStart() async {
    final seen = await _settings.seenTutorial();
    return !seen;
  }

  void _showCurrentTab() {
    final step = currentStep;
    if (step != null) onShowTab?.call(step.tabIndex);
  }
}
