import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_card.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';
import 'package:scamwatch_mobile_app/widgets/ui/empty_state.dart';
import 'package:scamwatch_mobile_app/widgets/ui/risk_badge.dart';
import 'package:scamwatch_mobile_app/widgets/ui/section_header.dart';

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
    final firstActivation =
        value && !await _settings.protectionSetupComplete();
    setState(() => _busy = true);
    try {
      if (firstActivation) {
        await _settings.setModelBackend(ModelBackend.npu);
      }
      await _settings.setProtectionEnabled(value);
      await ScamShieldController.setShieldEnabled(value);
      if (value) {
        final started = await ScamShieldController.ensureServiceRunning();
        if (!started) {
          throw StateError('Could not start scam protection.');
        }
        await ScamShieldController.syncSettings();
        if (firstActivation) {
          final gpuReady = await _warmUpAndCheck();
          if (!gpuReady) {
            await _settings.setModelBackend(ModelBackend.cpu);
            await ScamShieldController.syncSettings();
            final cpuReady = await _warmUpAndCheck();
            if (!cpuReady) {
              throw StateError('Could not load the on-device model.');
            }
          }
          await _settings.setProtectionSetupComplete(true);
        }
      } else {
        await ScamShieldController.stopService();
      }
    } catch (error) {
      debugPrint('[ScamShield] Protection setup failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Protection could not start: $error')),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _protectionEnabled = value;
      _busy = false;
    });
    await _refresh();
  }

  Future<bool> _warmUpAndCheck() async {
    try {
      await ScamShieldController.warmUpModel();
      final status = await ScamShieldController.status();
      return status.modelReady && !status.modelError;
    } catch (error) {
      debugPrint('[ScamShield] Model warm-up failed: $error');
      return false;
    }
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
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final alerts = _alerts;
    return AppScreen(
      title: l10n.safetyTitle,
      scrollable: false,
      actions: kDebugMode
          ? [
              IconButton(
                tooltip: l10n.notificationsTitle,
                icon: const Icon(LucideIcons.info),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
            ]
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.only(
            top: tokens.space.sm,
            bottom: tokens.space.xl2,
          ),
          children: [
            _protectionCard(theme, tokens, l10n),
            SizedBox(height: tokens.space.xl),
            SectionHeader(
              title: l10n.safetyRecentAlerts,
              trailing: _entries.isNotEmpty
                  ? TextButton.icon(
                      onPressed: _clear,
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      label: Text(l10n.commonClear),
                    )
                  : null,
            ),
            if (alerts.isEmpty)
              _emptyCard(l10n)
            else
              for (final entry in alerts) ...[
                _alertCard(theme, tokens, l10n, entry),
                SizedBox(height: tokens.space.md),
              ],
          ],
        ),
      ),
    );
  }

  Widget _protectionCard(
    ThemeData theme,
    AppTokens tokens,
    AppLocalizations l10n,
  ) {
    final on = _protectionEnabled;
    return AppCard(
      raised: true,
      child: Column(
        children: [
          Row(
            children: [
              ExcludeSemantics(child: _shield(context)),
              SizedBox(width: tokens.space.lg),
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
                    SizedBox(height: tokens.space.xs),
                    Text(
                      !_modelInstalled
                          ? l10n.safetyDownloadFirstPeriod
                          : on
                              ? l10n.safetyWeCheck
                              : l10n.safetyTurnOnToCheck,
                      style: theme.textTheme.bodyMedium,
                      semanticsLabel: on
                          ? l10n.safetyWeCheck
                          : !_modelInstalled
                              ? l10n.safetyDownloadFirstPeriod
                              : l10n.safetyTurnOnToCheck,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space.xl),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton.icon(
              onPressed: (_busy || (!_modelInstalled && !on))
                  ? null
                  : () => _toggleProtection(!_protectionEnabled),
              icon: Icon(
                on ? LucideIcons.shieldCheck : LucideIcons.shieldOff,
                size: 24,
              ),
              label: Text(
                on ? l10n.safetyTurnOff : l10n.safetyTurnOn,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lucide ships a single outline shield, so the "filled"/active look is
  /// simulated with a tinted circular container keyed to the risk tokens.
  Widget _shield(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final state = _deriveShieldState(
      enabled: _protectionEnabled,
      status: _status,
    );

    Color container;
    Color icon;
    IconData glyph = LucideIcons.shieldCheck;
    switch (state) {
      case _ShieldState.grey:
        container = scheme.surfaceContainerHighest;
        icon = scheme.onSurfaceVariant;
        glyph = LucideIcons.shieldOff;
      case _ShieldState.green:
        container = tokens.risk.safeContainer;
        icon = tokens.risk.safe;
      case _ShieldState.red:
        container = tokens.risk.dangerContainer;
        icon = tokens.risk.danger;
        glyph = LucideIcons.shieldAlert;
      case _ShieldState.shimmer:
        container = tokens.risk.safeContainer;
        icon = tokens.risk.safe;
    }

    Widget circle(Color bg, Color fg, IconData g) => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(g, size: 32, color: fg),
        );

    if (state != _ShieldState.shimmer) return circle(container, icon, glyph);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final hue = (_shimmerHue + _pulse.value * 360) % 360;
        final shimmerColor = HSVColor.fromAHSV(1, hue, 0.6, 0.95).toColor();
        final shimmerBg = HSVColor.fromAHSV(0.18, hue, 0.6, 0.95).toColor();
        return circle(shimmerBg, shimmerColor, LucideIcons.shieldCheck);
      },
    );
  }

  Widget _alertCard(
    ThemeData theme,
    AppTokens tokens,
    AppLocalizations l10n,
    LoggedNotification entry,
  ) {
    final record = entry.record;
    final title = record.title.isEmpty ? record.appLabel : record.title;
    final danger = riskColorsFor(context, RiskLevel.danger);
    return AppCard(
      border: Border.all(color: danger.strong.withValues(alpha: 0.25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: tokens.space.sm),
              const RiskBadge(level: RiskLevel.danger, label: 'Scam', compact: true),
            ],
          ),
          if (record.content.isNotEmpty) ...[
            SizedBox(height: tokens.space.sm),
            Text(record.content, style: theme.textTheme.bodyMedium),
          ],
          SizedBox(height: tokens.space.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _reportEntry(entry),
              icon: const Icon(LucideIcons.flag, size: 20),
              label: Text(
                l10n.commonReportThis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(AppLocalizations l10n) {
    return AppCard(
      child: EmptyState(
        icon: LucideIcons.shieldCheck,
        title: l10n.safetyNoScams,
        message: l10n.safetyNoScamsBody,
      ),
    );
  }
}
