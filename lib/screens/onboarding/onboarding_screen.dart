import 'package:scamwatch_mobile_app/core/model_catalog.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/main.dart';
import 'package:scamwatch_mobile_app/services/model_controller.dart';
import 'package:scamwatch_mobile_app/services/protection_settings.dart';
import 'package:scamwatch_mobile_app/services/scamshield_channels.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

import 'permission_step.dart';
import 'widgets/done_page.dart';
import 'widgets/model_page.dart';
import 'widgets/onboarding_action_bar.dart';
import 'widgets/permission_page.dart';
import 'widgets/welcome_page.dart';

/// First-run walkthrough that asks for each permission on its own page.
///
/// Pages: welcome, one page per [PermissionStep], the scam checker download,
/// then a summary. Each page has one big button. Once a permission is granted
/// the flow moves on by itself, so the user never has to tap twice. Every
/// step can be skipped and turned on later from Settings.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  static const _pageDuration = Duration(milliseconds: 450);
  static const _pageCurve = Curves.easeInOutCubic;

  /// Short pause after a permission turns on, so the check mark is seen
  /// before the next page slides in.
  static const _autoAdvanceDelay = Duration(milliseconds: 700);

  /// Devices with more RAM than this get the bigger model. Mirrors the pick
  /// made when protection is first turned on in the Safety tab.
  static const int _bigModelRamThreshold =
      8 * 1024 * 1024 * 1024 - 512 * 1024 * 1024;

  final PageController _controller = PageController();
  final List<PermissionStep> _steps = OnboardingPermissions.steps;
  final Map<PermissionStepKind, StepStatus> _status = {};
  final Set<PermissionStepKind> _skipped = {};
  final ProtectionSettings _settings = ProtectionSettings();
  late final ModelController _model = ModelController(_settings);

  int _index = 0;
  bool _busy = false;

  ScamModelSpec? _modelSpec;
  bool _modelFailed = false;

  // Set once the user taps Download. ModelController.load() also flips busy
  // while it registers an existing file, which must not look like a download.
  bool _downloadStarted = false;

  // True while a button-driven page transition is running. Extra taps are
  // ignored so they can't restart (and visibly slow down) the animation.
  bool _animating = false;
  bool _navigating = false;

  int get _pageCount => _steps.length + 3;
  int get _modelPage => _steps.length + 1;
  bool get _isWelcome => _index == 0;
  bool get _isDone => _index == _pageCount - 1;
  bool get _isModel => _index == _modelPage;
  PermissionStep? get _currentStep =>
      _index >= 1 && _index <= _steps.length ? _steps[_index - 1] : null;
  int get _grantedCount =>
      _steps.where((s) => _statusOf(s) == StepStatus.granted).length;

  bool get _modelDownloading => _downloadStarted && _model.busy;
  bool get _modelReady => _model.installed && !_model.busy;

  /// Whether [page] can be passed over when moving forward: a permission
  /// that is already on, or a scam checker that is already ready.
  bool _alreadyDone(int page) {
    if (page >= 1 && page <= _steps.length) {
      return _statusOf(_steps[page - 1]) == StepStatus.granted;
    }
    if (page == _modelPage) return _modelReady;
    return false;
  }

  /// The next page after [page] that still needs the user. Pages that are
  /// already done are skipped so nobody taps "Continue" on them.
  int _nextPageFrom(int page) {
    var next = page + 1;
    while (next < _pageCount - 1 && _alreadyDone(next)) {
      next++;
    }
    return next;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model.addListener(_onModelChanged);
    _refresh();
    _prepareModel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.removeListener(_onModelChanged);
    // A running download keeps going after setup ends and still reports to
    // the controller, so only dispose it when nothing is in flight.
    if (!_model.busy) _model.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
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
    final current = _currentStep;
    final wasGranted =
        current != null && _statusOf(current) == StepStatus.granted;
    setState(() {
      for (var i = 0; i < _steps.length; i++) {
        _status[_steps[i].kind] = results[i];
        if (results[i] == StepStatus.granted) _skipped.remove(_steps[i].kind);
      }
    });
    // Coming back from a settings page with the permission now on: move on.
    if (current != null &&
        !wasGranted &&
        _statusOf(current) == StepStatus.granted) {
      _autoAdvanceFrom(_index);
    }
  }

  Future<void> _prepareModel() async {
    try {
      await _model.load();
    } catch (_) {
      // Not fatal: the page just offers the download.
    }
    try {
      final ram = await ScamShieldController.deviceTotalRamBytes();
      final id = ram > _bigModelRamThreshold ? 'gemma-4-e2b' : 'qwen3-1-7B';
      _modelSpec = modelById(id);
    } catch (_) {
      _modelSpec = modelById('qwen3-1-7B');
    }
    if (mounted) setState(() {});
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

  void _next() => _goTo(_nextPageFrom(_index));
  void _back() => _goTo(_index - 1);

  /// Moves past [page] after a short pause, but only if the user is still on
  /// it. Calls from both the prompt result and the app-resume check collapse
  /// into a single page change.
  void _autoAdvanceFrom(int page) {
    Future<void>.delayed(_autoAdvanceDelay, () {
      if (!mounted || _index != page || _animating) return;
      _goTo(_nextPageFrom(page));
    });
  }

  Future<void> _allow(PermissionStep step) async {
    final page = _index;
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
      } else if (!step.opensSettings) {
        // Declined a normal prompt: show the "not on yet" note.
        _skipped.add(step.kind);
      }
    });
    if (status == StepStatus.granted) _autoAdvanceFrom(page);
  }

  void _skip(PermissionStep step) {
    if (_animating) return;
    setState(() => _skipped.add(step.kind));
    _next();
  }

  Future<void> _downloadModel() async {
    final spec = _modelSpec;
    if (spec == null || _model.busy) return;
    final l10n = AppLocalizations.of(context);
    var metered = false;
    try {
      metered = await ScamShieldController.isOnMeteredConnection();
    } catch (_) {}
    if (metered) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.onboardingModelMeteredTitle),
          content: Text(l10n.onboardingModelMeteredBody(_sizeLabel(spec))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.onboardingNotNow),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.onboardingModelDownloadShort),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    setState(() {
      _modelFailed = false;
      _downloadStarted = true;
    });
    final ok = await _model.downloadViaPlugin(spec);
    if (ok) {
      try {
        await ScamShieldController.syncSettings();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _modelFailed = !ok);
    if (ok) _autoAdvanceFrom(_modelPage);
  }

  /// "1.0 GB" style size for the download button.
  static String _sizeLabel(ScamModelSpec spec) {
    final mb = spec.approxSizeMb;
    if (mb < 1000) return '$mb MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }

  void _finish() {
    if (_navigating || !mounted) return;
    _navigating = true;
    // Remember that onboarding is done so future launches skip straight to the
    // app. Fire-and-forget: navigation shouldn't wait on the write.
    ProtectionSettings().setOnboardingComplete(true);
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
    final space = context.tokens.space;
    return Padding(
      padding: EdgeInsets.fromLTRB(space.sm, space.sm, space.sm, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedOpacity(
          opacity: _isWelcome ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: _isWelcome,
            child: ExcludeSemantics(
              excluding: _isWelcome,
              child: TextButton.icon(
                onPressed: _back,
                icon: const Icon(LucideIcons.arrowLeft),
                label: Text(l10n.onboardingBack),
              ),
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
    if (index == _modelPage) {
      return ModelPage(
        controller: _controller,
        index: index,
        ready: _modelReady,
        downloading: _modelDownloading,
        progress: _model.progress,
        failed: _modelFailed,
      );
    }
    final step = _steps[index - 1];
    return PermissionPage(
      controller: _controller,
      index: index,
      step: step,
      status: _statusOf(step),
      skipped: _skipped.contains(step.kind),
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    final step = _currentStep;
    final String primaryLabel;
    final VoidCallback? onPrimary;
    String? secondaryLabel;
    VoidCallback? onSecondary;
    var busy = false;

    if (_isWelcome) {
      primaryLabel = l10n.onboardingStart;
      onPrimary = _next;
    } else if (_isDone) {
      primaryLabel = l10n.onboardingFinish;
      onPrimary = _finish;
    } else if (_isModel) {
      final spec = _modelSpec;
      if (_modelReady || _modelDownloading) {
        primaryLabel = l10n.onboardingContinue;
        onPrimary = _next;
      } else {
        primaryLabel = spec == null
            ? l10n.onboardingModelDownloadShort
            : l10n.onboardingModelDownload(_sizeLabel(spec));
        onPrimary = spec == null ? null : _downloadModel;
        secondaryLabel = l10n.onboardingNotNow;
        onSecondary = _next;
      }
    } else {
      final status = _statusOf(step!);
      if (status == StepStatus.granted) {
        primaryLabel = l10n.onboardingContinue;
        onPrimary = _next;
      } else {
        primaryLabel = status == StepStatus.blocked || step.opensSettings
            ? l10n.onboardingOpenSettings
            : l10n.onboardingAllow;
        onPrimary = () => _allow(step);
        busy = _busy;
        secondaryLabel = l10n.onboardingNotNow;
        onSecondary = () => _skip(step);
      }
    }

    final numbered = !_isWelcome && !_isDone;
    return OnboardingActionBar(
      pageCount: _pageCount,
      pageIndex: _index,
      stepLabel: numbered
          ? l10n.onboardingStepCount(_index, _steps.length + 1)
          : null,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      busy: busy,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    );
  }
}
