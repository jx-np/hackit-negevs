import 'dart:async';

import 'package:flutter/material.dart';

import '../services/model_controller.dart';
import '../services/protection_settings.dart';
import '../services/scamshield_channels.dart';
import 'protection_tab.dart';

class ScamShieldScreen extends StatefulWidget {
  const ScamShieldScreen({super.key});

  @override
  State<ScamShieldScreen> createState() => _ScamShieldScreenState();
}

class _ScamShieldScreenState extends State<ScamShieldScreen> {
  final ProtectionSettings _settings = ProtectionSettings();
  late final ModelController _model = ModelController(_settings);

  Timer? _poll;
  bool _protectionEnabled = false;
  ServiceStatus _status = ServiceStatus.idle;

  @override
  void initState() {
    super.initState();
    _model.addListener(_onModelChanged);
    _bootstrap();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _poll?.cancel();
    _model.removeListener(_onModelChanged);
    _model.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _model.load();
    final enabled = await _settings.protectionEnabled();
    await ScamShieldController.setShieldEnabled(enabled);
    if (enabled && !await ScamShieldController.isServiceRunning()) {
      await ScamShieldController.startService();
      await ScamShieldController.syncSettings();
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await _settings.protectionEnabled();
    final status = await ScamShieldController.status();
    if (!mounted) return;
    setState(() {
      _protectionEnabled = enabled;
      _status = status;
    });
  }

  Future<void> _toggleProtection(bool value) async {
    if (value && !_model.installed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download a model in the Settings tab first'),
        ),
      );
      return;
    }
    await _settings.setProtectionEnabled(value);
    await ScamShieldController.setShieldEnabled(value);
    if (value) {
      await ScamShieldController.ensureServiceRunning();
    } else {
      await ScamShieldController.stopService();
    }
    await ScamShieldController.syncSettings();
    await _refresh();
  }

  Future<void> _runTest(String text) async {
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!_model.installed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Download a model in the Settings tab first'),
        ),
      );
      return;
    }
    final running = await ScamShieldController.ensureServiceRunning();
    if (!running) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Turn on protection to run the model')),
      );
      return;
    }
    await ScamShieldController.testEvaluate(text);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Checking the message...')),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scam AI'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Protection'),
              Tab(text: 'Scam AI'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProtectionTab(
              protectionEnabled: _protectionEnabled,
              modelInstalled: _model.installed,
              status: _status,
              onToggleProtection: _toggleProtection,
              onRefresh: _refresh,
            ),
            ScamAiTab(
              modelInstalled: _model.installed,
              status: _status,
              onTestMessage: _runTest,
              onRefresh: _refresh,
            ),
          ],
        ),
      ),
    );
  }
}

class ScamAiTab extends StatefulWidget {
  const ScamAiTab({
    super.key,
    required this.modelInstalled,
    required this.status,
    required this.onTestMessage,
    required this.onRefresh,
  });

  final bool modelInstalled;
  final ServiceStatus status;
  final Future<void> Function(String text) onTestMessage;
  final Future<void> Function() onRefresh;

  @override
  State<ScamAiTab> createState() => _ScamAiTabState();
}

class _ScamAiTabState extends State<ScamAiTab> {
  final TextEditingController _testController = TextEditingController();

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.modelInstalled ? Icons.smart_toy : Icons.smart_toy_outlined,
                        color: widget.modelInstalled ? Colors.green : Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.modelInstalled
                              ? 'On-device model ready'
                              : 'No on-device model installed',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.status.lastMessage.isEmpty
                        ? 'Checked ${widget.status.evaluated} messages, '
                            'raised ${widget.status.alertsRaised} alerts'
                        : widget.status.lastMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Try a message', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _testController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Paste a suspicious message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => widget.onTestMessage(_testController.text.trim()),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Check'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
