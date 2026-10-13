import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:call_log_app/l10n/app_localizations.dart';

import '../../api/api_client.dart';
import '../../services/model_controller.dart';
import '../../services/notification_log.dart';
import '../../services/protection_settings.dart';
import '../../services/scamshield_channels.dart';
import 'notifications_screen.dart';
import '../community/report_tab_screen.dart';

enum _ShieldState { grey, green, red, shimmer }

_ShieldState _deriveShieldState({
  required bool enabled,
  required ServiceStatus status,
}) {
  if (!enabled) return _ShieldState.grey;
  if (status.processing) return _ShieldState.shimmer;
  if (status.modelError) return _ShieldState.red;
  if (status.modelReady) return _ShieldState.green;
  return _ShieldState.grey;
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

  Future<void> _toggleProtection(bool value) async {
    if (value && !_modelInstalled) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.commonDownloadModelFirst),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _settings.setProtectionEnabled(value);
      await ScamShieldController.setShieldEnabled(value);
      if (value) {
        await ScamShieldController.ensureServiceRunning();
      } else {
        await ScamShieldController.stopService();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _protectionEnabled = value;
      _busy = false;
    });
    await _refresh();
  }

  Future<void> _clear() async {
    await _log.clear();
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportTabScreen(
          client: client,
          prefillTitle: title,
          prefillText: buffer.toString(),
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
                      builder: (_) => const NotificationsScreen(),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.safetyRecentAlerts, style: theme.textTheme.titleLarge),
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
    final scheme = theme.colorScheme;
    final on = _protectionEnabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _shield(scheme),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        on ? l10n.safetyProtectedOn : l10n.safetyProtectedOff,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !_modelInstalled
                            ? l10n.safetyDownloadFirstPeriod
                            : on
                                ? l10n.safetyWeCheck
                                : l10n.safetyTurnOnToCheck,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton.icon(
                onPressed: (_busy || (!_modelInstalled && !on))
                    ? null
                    : () => _toggleProtection(!_protectionEnabled),
                icon: Icon(on ? Icons.toggle_on : Icons.toggle_off, size: 28),
                label: Text(
                  on ? l10n.safetyTurnOff : l10n.safetyTurnOn,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shield(ColorScheme scheme) {
    final state = _deriveShieldState(
      enabled: _protectionEnabled,
      status: _status,
    );
    final Color fill;
    switch (state) {
      case _ShieldState.grey:
        fill = scheme.outline;
      case _ShieldState.green:
        fill = const Color(0xFF2E7D32);
      case _ShieldState.red:
        fill = scheme.error;
      case _ShieldState.shimmer:
        fill = const Color(0xFF2E7D32);
    }
    final shieldStack = Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.shield, size: 56, color: fill),
        Icon(Icons.shield_outlined, size: 56, color: scheme.onSurface),
      ],
    );
    if (state != _ShieldState.shimmer) return shieldStack;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final hue = (_shimmerHue + _pulse.value * 360) % 360;
        final shimmerColor =
            HSVColor.fromAHSV(1, hue, 0.85, 0.9).toColor();
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.shield, size: 56, color: shimmerColor),
            Icon(Icons.shield_outlined, size: 56, color: scheme.onSurface),
          ],
        );
      },
    );
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
              Text(record.content, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
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
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
