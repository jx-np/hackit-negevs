import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';

import '../../api/api_client.dart';
import '../../core/model_catalog.dart';
import '../../services/model_controller.dart';
import '../../services/model_store.dart';
import '../../services/notification_log.dart';
import '../../services/protection_settings.dart';
import '../../services/scamshield_channels.dart';
import '../../widgets/auth/require_login.dart';
import '../../widgets/tour/tour_models.dart';
import 'notifications_screen.dart';
import 'widgets/safety_hero.dart';
import '../community/report_tab_screen.dart';

SafetyHeroStatus _deriveHeroStatus({
  required bool enabled,
  required ServiceStatus status,
}) {
  if (!enabled) return SafetyHeroStatus.off;
  if (status.processing) return SafetyHeroStatus.checking;
  if (status.modelError) return SafetyHeroStatus.error;
  if (status.modelReady) return SafetyHeroStatus.on;
  return SafetyHeroStatus.off;
}

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen>
    with SingleTickerProviderStateMixin {
  final ProtectionSettings _settings = ProtectionSettings();
  final NotificationLog _log = NotificationLog();
  late final ModelController _model = ModelController(_settings);

  Timer? _poll;
  bool _protectionEnabled = false;
  bool _busy = false;
  bool _modelInstalled = false;
  ServiceStatus _status = ServiceStatus.idle;
  List<LoggedNotification> _entries = const [];

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  static const Duration _shimmerFloor = Duration(milliseconds: 1400);
  DateTime? _shimmerUntil;
  Timer? _shimmerTimer;
  double _shimmerHue = Random().nextDouble() * 360;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _shimmerTimer?.cancel();
    _pulse.dispose();
    _model.dispose();
    super.dispose();
  }

  bool get _shimmerLatched =>
      _shimmerUntil != null && DateTime.now().isBefore(_shimmerUntil!);

  void _syncShimmer(bool processing) {
    if (processing) {
      _shimmerUntil = DateTime.now().add(_shimmerFloor);
      _shimmerHue = Random().nextDouble() * 360;
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
      _shimmerTimer?.cancel();
      _shimmerTimer = Timer(_shimmerFloor, () {
        if (!mounted) return;
        setState(() {});
        if (!_shimmerLatched && _pulse.isAnimating) _pulse.stop();
      });
    } else if (!_shimmerLatched && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  Future<void> _bootstrap() async {
    // Crash recovery for the staged backend test. A pending marker means the
    // app died while warming up that backend (NPU can hard-kill the process),
    // so the attempt never confirmed. Discard it and keep whatever backend is
    // already persisted in modelBackend() — that is the last one that loaded
    // cleanly, which is exactly the "settings should still show GPU" behaviour.
    final pending = await _settings.pendingBackendTest();
    if (pending != null) {
      await _settings.setPendingBackendTest(null);
      debugPrint(
        '[ScamShield] Discarded crashed backend test for ${pending.name}; '
        'keeping last-good backend.',
      );
    }
    await _model.load();
    final enabled = await _settings.protectionEnabled();
    if (enabled) {
      await ScamShieldController.setShieldEnabled(true);
      await ScamShieldController.ensureServiceRunning();
    }
    if (!mounted) return;
    setState(() {
      _protectionEnabled = enabled;
      _modelInstalled = _model.installed;
    });
    await _refresh();
  }

  Future<void> _refresh() async {
    ServiceStatus status = _status;
    try {
      status = await ScamShieldController.status();
    } catch (_) {}
    List<LoggedNotification> entries = _entries;
    try {
      entries = await _log.all();
    } catch (_) {}
    bool modelInstalled = _modelInstalled;
    try {
      await _model.refreshInstalled();
      modelInstalled = _model.installed;
    } catch (_) {}
    if (!mounted) return;
    _syncShimmer(status.processing);
    setState(() {
      _status = status;
      _entries = entries;
      _modelInstalled = modelInstalled;
    });
  }

  /// Devices with this much RAM or less get the Small Model. The nominal
  /// threshold is 8 GB, but `totalMem` always reads a little under the spec
  /// because the kernel reserves a slice, so we subtract a 512 MB tolerance.
  /// A phone marketed as "8 GB" that reports ~7.4 GB still counts as 8-or-less
  /// and lands on the Small Model; only genuinely larger phones (12 GB+) clear
  /// the bar for the Big Model.
  static const int _ramTolerance = 512 * 1024 * 1024;
  static const int _bigModelRamThreshold =
      8 * 1024 * 1024 * 1024 - _ramTolerance;

  /// Picks the catalog model by device RAM: more than ~8 GB -> Big Model
  /// (modelCatalog[0]); 8 GB or less -> Small Model (modelCatalog[1]). When RAM
  /// cannot be read (returns 0) we fall back to the Small Model, the safe pick
  /// for constrained devices.
  Future<ScamModelSpec> _pickModelForDevice() async {
    final ramBytes = await ScamShieldController.deviceTotalRamBytes();
    final useBig = ramBytes > _bigModelRamThreshold;
    debugPrint(
      '[ScamShield] Device RAM ${ramBytes ~/ (1024 * 1024)} MB -> '
      '${useBig ? 'Big' : 'Small'} Model',
    );
    return useBig ? modelCatalog[0] : modelCatalog[1];
  }

  /// Whether the model the user has already selected is usable as-is, so
  /// activation can load it directly instead of downloading a RAM-auto-picked
  /// catalog model (which would also overwrite the selection).
  ///
  /// `_model.load()` resolves `selectedModelId()` into `_model.spec` and
  /// registers a picked/stored file during bootstrap, so by the time
  /// protection is toggled on `_model.spec` already reflects the user's choice.
  /// A model counts as ready when it is a file picked from this device
  /// (`filePath != null` — e.g. the Dev Menu NPU bundle), when it is a built-in
  /// OS model, when the plugin already lists it installed, or when its file is
  /// present in the ScamShield models folder. Only when none of these hold does
  /// activation fall back to auto-pick + download.
  Future<bool> _selectedModelIsReady() async {
    final spec = _model.spec;
    if (spec.filePath != null) return true;
    if (spec.isBuiltIn) return true;
    if (_model.installed) return true;
    try {
      await _model.refreshInstalled();
      if (_model.installed) return true;
    } catch (_) {}
    try {
      return await ModelStore.exists(spec);
    } catch (_) {
      return false;
    }
  }

  /// Warns before a metered-connection download of a multi-gigabyte model.
  /// Returns true when the download should proceed. On an unmetered network
  /// (or when the check fails) it returns true without prompting.
  Future<bool> _confirmMeteredDownload(ScamModelSpec spec) async {
    final metered = await ScamShieldController.isOnMeteredConnection();
    if (!metered) return true;
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.safetyMeteredTitle),
          content: Text(l10n.safetyMeteredBody(spec.approxSizeMb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.safetyNotNow),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.safetyDownload),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _toggleProtection(bool value) async {
    setState(() => _busy = true);
    try {
      await _settings.setProtectionEnabled(value);
      await ScamShieldController.setShieldEnabled(value);
      if (!value) {
        await ScamShieldController.stopService();
        if (!mounted) return;
        setState(() {
          _protectionEnabled = false;
          _busy = false;
        });
        await _refresh();
        return;
      }

      // Turning protection ON. Make sure a model exists first.
      //
      // The user may have already chosen a model (e.g. a file picked in the
      // Dev Menu, or a previously downloaded catalog model). That selection is
      // persisted to prefs (`selectedModelId`, plus the custom-model path), but
      // this screen's `ModelController` is a SEPARATE instance from the Dev
      // Menu's, and its `_model.load()` only ran once during bootstrap — before
      // any Dev Menu pick. Re-run `load()` now so `_model.spec` reflects the
      // latest persisted selection (and `hydrateCustomModel` repopulates the
      // custom spec) instead of a stale catalog default. Only fall back to the
      // auto-pick + download path when nothing usable is actually present.
      try {
        await _model.load();
        if (!mounted) return;
        setState(() => _modelInstalled = _model.installed);
      } catch (_) {
        // A load failure here shouldn't block activation; the readiness check
        // below still decides whether a download is needed.
      }
      var justDownloaded = false;
      if (!await _selectedModelIsReady()) {
        final spec = await _pickModelForDevice();
        final proceed = await _confirmMeteredDownload(spec);
        if (!proceed) {
          // User declined the metered download; roll protection back off.
          await _settings.setProtectionEnabled(false);
          await ScamShieldController.setShieldEnabled(false);
          if (!mounted) return;
          setState(() {
            _protectionEnabled = false;
            _busy = false;
          });
          return;
        }
        // Select first so the background isolate loads this model, then run the
        // plugin foreground download (native progress notification, survives
        // navigation, cancellable). This does not block the UI isolate.
        final ok = await _model.downloadViaPlugin(spec);
        if (!ok) {
          throw StateError(
            _model.error.isEmpty ? 'Model download failed.' : _model.error,
          );
        }
        justDownloaded = true;
        if (!mounted) return;
        setState(() => _modelInstalled = _model.installed);
      }

      final firstActivation = !await _settings.protectionSetupComplete();
      // A backend is pinned per model. If the selected model changed since the
      // last successful setup (e.g. the user picked a different file in the Dev
      // Menu), the old pin can be wrong for the new model — a generic GPU bundle
      // and an NPU-only SoC bundle need different backends — so re-probe.
      final modelChanged = await _settings.setupModelId() != _model.spec.id;

      final started = await ScamShieldController.ensureServiceRunning();
      if (!started) {
        throw StateError('Could not start scam protection.');
      }

      // Run the full CPU -> GPU -> NPU test on first setup, whenever a model was
      // just downloaded, OR whenever the selected model changed. A model that
      // has never been validated against this device's accelerators (fresh
      // download or a different pick) must re-probe to pin the right backend
      // instead of trusting a stale pick from a previously set-up model.
      if (firstActivation || justDownloaded || modelChanged) {
        final backend = await _runStagedWarmup();
        if (backend == null) {
          throw StateError('Could not load the on-device model.');
        }
        await _settings.setProtectionSetupComplete(true);
        await _settings.setSetupModelId(_model.spec.id);
      } else {
        // Already set up and model unchanged: re-apply persisted backend + warm.
        await ScamShieldController.syncSettings();
        await _warmUpAndCheck();
      }
    } catch (error) {
      debugPrint('[ScamShield] Protection setup failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).safetyCouldNotStart),
          ),
        );
      }
      // The setup failed, so protection must not be left reported as on.
      await _settings.setProtectionEnabled(false);
      await ScamShieldController.setShieldEnabled(false);
      if (!mounted) return;
      setState(() {
        _protectionEnabled = false;
        _busy = false;
      });
      await _refresh();
      return;
    }
    if (!mounted) return;
    setState(() {
      _protectionEnabled = true;
      _busy = false;
    });
    await _refresh();
  }

  /// Staged CPU -> GPU -> NPU warmup. Each backend is only persisted as the
  /// active one *after* it warms up cleanly, so the settings page always
  /// reflects the best backend that actually loaded. A transient
  /// [ProtectionSettings.pendingBackendTest] marker is written before each
  /// attempt and cleared after it returns; if the process is hard-killed
  /// mid-attempt (NPU can do this), the next launch (see [_bootstrap]) finds
  /// the marker, discards the crashed candidate, and keeps the last-good
  /// backend that is still persisted in `modelBackend()`.
  ///
  /// Returns the final working backend, or null if none loaded.
  ///
  /// For a normal model, escalation stops at the first failure: there is no
  /// point trying the riskier NPU on a device whose GPU already failed to
  /// initialise. But an NPU-only bundle (a file compiled for a specific NPU,
  /// e.g. `_qualcomm_`) physically cannot run on CPU or GPU — tried on either
  /// it fails instantly with "Input tensor not found". For those we skip
  /// straight to NPU so a CPU/GPU failure never strands them before the one
  /// backend that can actually load them.
  Future<ModelBackend?> _runStagedWarmup() async {
    final List<ModelBackend> candidates = _isNpuOnlyBundle(_model.spec.fileName)
        ? const [ModelBackend.npu]
        : const [ModelBackend.cpu, ModelBackend.gpu, ModelBackend.npu];
    ModelBackend? lastGood;
    for (final candidate in candidates) {
      final ok = await _tryBackend(candidate);
      if (!ok) break; // stop escalating once a backend fails
      lastGood = candidate;
    }
    if (lastGood != null) {
      // Pin the best working backend and push it to the running service.
      await _settings.setModelBackend(lastGood);
      await ScamShieldController.syncSettings();
    }
    return lastGood;
  }

  /// Whether [fileName] is a bundle pre-compiled for a specific NPU and so can
  /// only load on the NPU backend. Mirrors the detection in
  /// `local_llm_evaluator.dart`'s `_preferredBackend` so the staged warmup and
  /// the actual load agree on which files are NPU-only.
  bool _isNpuOnlyBundle(String fileName) {
    final String name = fileName.toLowerCase();
    return name.contains('_qualcomm_') ||
        name.contains('_google_tensor_') ||
        name.contains('_intel_');
  }

  /// Warms up a single [backend] and reports whether the model loaded. The
  /// backend is applied via setModelBackend + syncSettings (the background
  /// isolate rebuilds the model on it), then warmUp is polled through
  /// status(). The pending-test crash marker brackets the attempt.
  Future<bool> _tryBackend(ModelBackend backend) async {
    await _settings.setPendingBackendTest(backend);
    try {
      await _settings.setModelBackend(backend);
      await ScamShieldController.syncSettings();
      final ready = await _warmUpAndCheck();
      return ready;
    } catch (error) {
      debugPrint('[ScamShield] Backend ${backend.name} test failed: $error');
      return false;
    } finally {
      // Attempt returned without crashing, so the marker is no longer needed.
      await _settings.setPendingBackendTest(null);
    }
  }

  Future<bool> _warmUpAndCheck() async {
    try {
      await ScamShieldController.warmUpModel();
      // Poll status until the model settles. _warmUp() on the background side
      // loads with a 75s timeout, so give it room before giving up.
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final status = await ScamShieldController.status();
        if (status.modelError) return false;
        if (status.modelReady) return true;
      }
      return false;
    } catch (error) {
      debugPrint('[ScamShield] Model warm-up failed: $error');
      return false;
    }
  }

  Future<void> _clear() async {
    await _log.clear();
    await ScamShieldController.syncAlerts();
    await _refresh();
  }

  Future<void> _reportEntry(LoggedNotification entry) async {
    final record = entry.record;
    final client = context.read<ApiClient>();
    final title = record.title.isEmpty ? record.appLabel : record.title;
    final buffer = StringBuffer(record.content);
    final verdict = entry.verdict;
    if (verdict != null) {
      buffer
        ..write('\n\n')
        ..write(verdict.label.title);
      if (verdict.reason.isNotEmpty) {
        buffer
          ..write('\n')
          ..write(verdict.reason);
      }
    }
    if (!await requireLogin(context)) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportTabScreen(
          client: client,
          prefillTitle: title,
          prefillText: buffer.toString(),
          onReported: () async {
            await _log.removeThread(entry.id);
            await ScamShieldController.dismissScamAlert();
          },
        ),
      ),
    );
    await _refresh();
  }

  List<LoggedNotification> get _alerts =>
      _entries.where((e) => e.verdict?.shouldAlert ?? false).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final alerts = _alerts;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.safetyTitle),
        actions: kDebugMode
            ? [
                IconButton(
                  tooltip: l10n.notificationsTitle,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(
                        showTestCard: true,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _protectionCard(theme, l10n),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.safetyRecentAlerts,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (_entries.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.commonClear),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (alerts.isEmpty)
              _emptyCard(theme, l10n)
            else
              for (final entry in alerts) _alertCard(theme, l10n, entry),
          ],
        ),
      ),
    );
  }

  Widget _protectionCard(ThemeData theme, AppLocalizations l10n) {
    final on = _protectionEnabled;
    final status = _deriveHeroStatus(enabled: on, status: _status);

    SafetyHero hero({Color? accent}) => SafetyHero(
          key: CoachMarkTargets.keyOf(context, TourTarget.safetyStatus),
          status: status,
          accentOverride: accent,
          title: on ? l10n.safetyProtectedOn : l10n.safetyProtectedOff,
          // Before any model is installed (first run) we show no subtitle,
          // just the title and the "Press to start" button below.
          subtitle: !_modelInstalled
              ? null
              : on
                  ? l10n.safetyHeroOnBody
                  : l10n.safetyTurnOnToCheck,
          // Rebuilds on ModelController changes so the download progress
          // reflects live percent while a model is being fetched.
          action: AnimatedBuilder(
            animation: _model,
            builder: (context, _) => _protectionButton(theme, l10n, on),
          ),
        );

    if (status != SafetyHeroStatus.checking) return hero();
    // While a message is being checked the shield cycles through hues.
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final hue = (_shimmerHue + _pulse.value * 360) % 360;
        return hero(accent: HSVColor.fromAHSV(1, hue, 0.85, 0.9).toColor());
      },
    );
  }

  /// The main protection toggle. While a model download is in flight it turns
  /// into a progress button: a label plus a determinate bar driven by
  /// [ModelController.progress]. An unknown total (percent -1) falls back to an
  /// indeterminate bar.
  Widget _protectionButton(ThemeData theme, AppLocalizations l10n, bool on) {
    final scheme = theme.colorScheme;
    final downloading = _model.busy;
    if (downloading) {
      final percent = _model.progress;
      final hasPercent = percent >= 0;
      final received = _model.receivedBytes;
      final total = _model.totalBytes;
      return _progressBlock(
        theme,
        scheme,
        label: _downloadStatusLabel(l10n, percent, received, total),
        value: hasPercent ? percent / 100 : null,
      );
    }
    // Download finished but setup is still running (service start + staged
    // CPU/GPU/NPU warmup). Keep the user informed with an indeterminate bar
    // instead of a plain disabled button.
    if (_busy) {
      return _progressBlock(
        theme,
        scheme,
        label: l10n.safetySettingUpModel,
        value: null,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
        onPressed:
            _busy ? null : () => _toggleProtection(!_protectionEnabled),
        icon: Icon(on ? Icons.toggle_on : Icons.toggle_off, size: 28),
        label: Text(
          // First run (no model yet): invite the user to begin, which kicks
          // off the download + setup. Afterwards it is a plain on/off toggle.
          on
              ? l10n.safetyTurnOff
              : _modelInstalled
                  ? l10n.safetyTurnOn
                  : l10n.safetyPressToStart,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// A label with a spinner and a progress bar, used in place of the toggle
  /// button while a download or warmup is running. [value] is 0–1 for a
  /// determinate bar, or null for an indeterminate one.
  Widget _progressBlock(
    ThemeData theme,
    ColorScheme scheme, {
    required String label,
    required double? value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  /// Builds the download status line, e.g. "Downloading model… 42%" or, when a
  /// byte total is known, "Downloading model… 42% · 420 of 1000 MB". Falls back
  /// to a plain "Downloading model…" when no percentage is available yet.
  String _downloadStatusLabel(
    AppLocalizations l10n,
    int percent,
    int received,
    int total,
  ) {
    if (percent < 0) return l10n.safetyDownloadingModel;
    final pct = l10n.settingsPercent(percent);
    if (total > 0) {
      final gotMb = received ~/ (1024 * 1024);
      final totalMb = total ~/ (1024 * 1024);
      return '${l10n.safetyDownloadingModel} $pct · $gotMb/$totalMb MB';
    }
    return '${l10n.safetyDownloadingModel} $pct';
  }

  Widget _alertCard(ThemeData theme, AppLocalizations l10n, LoggedNotification entry) {
    final scheme = theme.colorScheme;
    final record = entry.record;
    final title = record.title.isEmpty ? record.appLabel : record.title;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gpp_bad, color: scheme.error, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (record.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              _AlertMessage(text: record.content),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => _reportEntry(entry),
                icon: const Icon(Icons.flag),
                label: Text(
                  l10n.commonReportThis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.gpp_good,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.safetyNoScams,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.safetyNoScamsBody,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The body of a scam alert. Messages that fit in a few lines are shown in
/// full straight away; only genuinely long messages are clipped, with a large
/// full-width "Show more" button that is easy to hit and read.
class _AlertMessage extends StatefulWidget {
  const _AlertMessage({required this.text});

  final String text;

  @override
  State<_AlertMessage> createState() => _AlertMessageState();
}

class _AlertMessageState extends State<_AlertMessage> {
  static const int _collapsedLines = 4;
  static const int _autoExpandLines = 8;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final style = theme.textTheme.bodyLarge;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure the real wrapped height at the current width and text scale:
        // anything that fits in eight lines is shown in full straight away.
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _autoExpandLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final isLong = painter.didExceedMaxLines;
        final collapsed = isLong && !_expanded;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: collapsed ? _collapsedLines : null,
              overflow: collapsed ? TextOverflow.ellipsis : null,
            ),
            if (isLong) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 26,
                  ),
                  label: Text(
                    _expanded ? l10n.safetyShowLess : l10n.safetyShowMore,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
