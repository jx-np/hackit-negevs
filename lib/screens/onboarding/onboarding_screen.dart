import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:call_log_app/main.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_step.dart';
import 'widgets/done_page.dart';
import 'widgets/permission_page.dart';
import 'widgets/step_indicator.dart';
import 'widgets/welcome_page.dart';

/// First-run walkthrough that asks for each permission on its own page.
///
/// Pages: welcome, one page per [PermissionStep], then a summary. Users can
/// swipe or use the large buttons at the bottom; every permission can be
/// skipped and turned on later from Settings.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  static const _pageDuration = Duration(milliseconds: 450);
  static const _pageCurve = Curves.easeInOutCubic;

  final PageController _controller = PageController();
  final List<PermissionStep> _steps = OnboardingPermissions.steps;
  final Map<PermissionStepKind, StepStatus> _status = {};
  final Set<PermissionStepKind> _skipped = {};
  int _index = 0;
  bool _busy = false;

  // True while a button-driven page transition is running. Extra taps are
  // ignored so they can't restart (and visibly slow down) the animation.
  bool _animating = false;
  bool _navigating = false;

  int get _pageCount => _steps.length + 2;
  bool get _isWelcome => _index == 0;
  bool get _isDone => _index == _pageCount - 1;
  PermissionStep? get _currentStep =>
      _isWelcome || _isDone ? null : _steps[_index - 1];
  int get _grantedCount =>
      _steps.where((s) => _statusOf(s) == StepStatus.granted).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // Some permissions are turned on in a system settings page, so re-check
  // everything when the user comes back to the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final results = await Future.wait(_steps.map((s) => s.check()));
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _steps.length; i++) {
        _status[_steps[i].kind] = results[i];
        if (results[i] == StepStatus.granted) _skipped.remove(_steps[i].kind);
      }
    });
  }

  StepStatus _statusOf(PermissionStep step) =>
      _status[step.kind] ?? StepStatus.notGranted;

  Future<void> _goTo(int page) async {
    if (_animating || page < 0 || page >= _pageCount) return;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.jumpToPage(page);
      return;
    }
    _animating = true;
    try {
      await _controller.animateToPage(
        page,
        duration: _pageDuration,
        curve: _pageCurve,
      );
    } finally {
      _animating = false;
    }
  }

  void _next() => _goTo(_index + 1);
  void _back() => _goTo(_index - 1);

  Future<void> _allow(PermissionStep step) async {
    setState(() => _busy = true);
    if (_statusOf(step) == StepStatus.blocked) {
      await openAppSettings();
    } else {
      await step.request();
    }
    final status = await step.check();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status[step.kind] = status;
      if (status == StepStatus.granted) {
        _skipped.remove(step.kind);
      }
    });
  }

  void _skip(PermissionStep step) {
    if (_animating) return;
    setState(() => _skipped.add(step.kind));
    _next();
  }

  void _finish() {
    if (_navigating || !mounted) return;
    _navigating = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, _, _) => const HomePage(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: _isWelcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(l10n),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pageCount,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: _buildPage,
                ),
              ),
              _buildActions(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedOpacity(
          opacity: _isWelcome ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: _isWelcome,
            child: TextButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l10n.onboardingBack),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, int index) {
    if (index == 0) {
      return WelcomePage(controller: _controller, index: index);
    }
    if (index == _pageCount - 1) {
      return DonePage(
        controller: _controller,
        index: index,
        grantedCount: _grantedCount,
        total: _steps.length,
      );
    }
    final step = _steps[index - 1];
    return PermissionPage(
      controller: _controller,
      index: index,
      step: step,
      status: _statusOf(step),
      skipped: _skipped.contains(step.kind),
      stepNumber: index,
      stepTotal: _steps.length,
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final step = _currentStep;
    final String primaryLabel;
    final VoidCallback? onPrimary;
    String? secondaryLabel;
    VoidCallback? onSecondary;

    if (_isWelcome) {
      primaryLabel = l10n.onboardingStart;
      onPrimary = _next;
    } else if (_isDone) {
      primaryLabel = l10n.onboardingFinish;
      onPrimary = _finish;
    } else {
      final status = _statusOf(step!);
      if (status == StepStatus.granted) {
        primaryLabel = l10n.onboardingNext;
        onPrimary = _next;
      } else {
        primaryLabel = status == StepStatus.blocked || step.opensSettings
            ? l10n.onboardingOpenSettings
            : l10n.onboardingAllow;
        onPrimary = _busy ? null : () => _allow(step);
        secondaryLabel = l10n.onboardingNotNow;
        onSecondary = () => _skip(step);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepIndicator(count: _pageCount, index: _index),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 68,
              minWidth: double.infinity,
            ),
            child: FilledButton(
              onPressed: onPrimary,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _busy
                    ? const SizedBox(
                        key: ValueKey('busy'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        primaryLabel,
                        key: ValueKey(primaryLabel),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Fixed minimum height so the layout does not jump between pages.
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 56,
              minWidth: double.infinity,
            ),
            child: secondaryLabel == null
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: onSecondary,
                    child: Text(
                      secondaryLabel,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
