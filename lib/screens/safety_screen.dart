import 'dart:async';

import 'package:flutter/material.dart';

import '../services/model_controller.dart';
import '../services/notification_log.dart';
import '../services/protection_settings.dart';
import '../services/scamshield_channels.dart';
import 'report_screen.dart';
import '../main.dart' show ReportDeepLinkPayload;

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final ProtectionSettings _settings = ProtectionSettings();
  final NotificationLog _log = NotificationLog();
  late final ModelController _model = ModelController(_settings);

  Timer? _poll;
  bool _protectionEnabled = false;
  bool _busy = false;
  bool _modelInstalled = false;
  ServiceStatus _status = ServiceStatus.idle;
  List<LoggedNotification> _entries = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _model.dispose();
    super.dispose();
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
    setState(() {
      _status = status;
      _entries = entries;
      _modelInstalled = modelInstalled;
    });
  }

  Future<void> _toggleProtection(bool value) async {
    if (value && !_modelInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download a model in the Settings tab first'),
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
    final payload = ReportDeepLinkPayload(
      subject: record.title.isEmpty ? record.appLabel : record.title,
      content: record.content,
      source: 'notification',
      app: record.appLabel.isEmpty ? record.packageName : record.appLabel,
      notificationKey: record.key,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportScreen(initialLink: payload),
      ),
    );
    await _refresh();
  }

  List<LoggedNotification> get _alerts =>
      _entries.where((e) => e.verdict?.shouldAlert ?? false).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = _alerts;
    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _protectionCard(theme),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent alerts', style: theme.textTheme.titleLarge),
                if (_entries.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (alerts.isEmpty)
              _emptyCard(theme)
            else
              for (final entry in alerts) _alertCard(theme, entry),
          ],
        ),
      ),
    );
  }

  Widget _protectionCard(ThemeData theme) {
    final scheme = theme.colorScheme;
    final on = _protectionEnabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  on ? Icons.shield : Icons.shield_outlined,
                  size: 56,
                  color: on ? scheme.primary : scheme.outline,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        on ? 'You are protected' : 'Protection is off',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !_modelInstalled
                            ? 'Download a model in the Settings tab first.'
                            : on
                                ? 'We check your messages for scams.'
                                : 'Turn this on to check messages for scams.',
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
                  on ? 'Turn protection off' : 'Turn protection on',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertCard(ThemeData theme, LoggedNotification entry) {
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
                label: const Text(
                  'Report this',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(ThemeData theme) {
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
                'No scams found',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Suspicious messages will show up here.',
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
