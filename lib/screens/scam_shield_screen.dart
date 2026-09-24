import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import '../services/model_controller.dart';
import '../services/protection_settings.dart';
import '../services/scamshield_channels.dart';
import 'protection_tab.dart';
import 'settings_tab.dart';

class ScamShieldScreen extends StatefulWidget {
  const ScamShieldScreen({super.key});

  @override
  State<ScamShieldScreen> createState() => _ScamShieldScreenState();
}

class _ScamShieldScreenState extends State<ScamShieldScreen> {
  final ProtectionSettings _settings = ProtectionSettings();
  late final ModelController _model = ModelController(_settings);

  Timer? _poll;
  bool _notificationAccess = false;
  bool _overlayGranted = false;
  bool _notificationPermission = true;
  bool _protectionEnabled = false;
  double _threshold = 0.6;
  String _endpoint = '';
  String _token = '';
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
    if (await _settings.protectionEnabled() &&
        !await ScamShieldController.isServiceRunning()) {
      await ScamShieldController.startService();
      await ScamShieldController.syncSettings();
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    final access = Platform.isAndroid
        ? await NotificationListenerService.isPermissionGranted()
        : false;
    final overlay = await ScamShieldController.hasOverlayPermission();
    final permission = await ScamShieldController.hasNotificationPermission();
    final enabled = await _settings.protectionEnabled();
    final threshold = await _settings.confidenceThreshold();
    final endpoint = await _settings.remoteEndpoint();
    final token = await _settings.hfToken();
    final status = await ScamShieldController.status();
    if (!mounted) return;
    setState(() {
      _notificationAccess = access;
      _overlayGranted = overlay;
      _notificationPermission = permission;
      _protectionEnabled = enabled;
      _threshold = threshold;
      _endpoint = endpoint;
      _token = token;
      _status = status;
    });
  }

  Future<void> _toggleProtection(bool value) async {
    await _settings.setProtectionEnabled(value);
    if (value) {
      await ScamShieldController.ensureServiceRunning();
    } else {
      await ScamShieldController.stopService();
    }
    await ScamShieldController.syncSettings();
    await _refresh();
  }

  Future<void> _downloadModel() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_notificationPermission) {
      await ScamShieldController.requestNotificationPermission();
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    final ok = await _model.download();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? '${_model.spec.displayName} installed' : _model.error),
      ),
    );
    if (ok) await ScamShieldController.syncSettings();
    await _refresh();
  }

  Future<void> _deleteModel() async {
    await _model.delete();
    await ScamShieldController.syncSettings();
    await _refresh();
  }

  Future<void> _runTest(String text) async {
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!_model.installed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Download a model in the Model tab first'),
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
          title: const Text('Scam Shield'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Protection'),
              Tab(text: 'Model'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProtectionTab(
              notificationAccess: _notificationAccess,
              overlayGranted: _overlayGranted,
              notificationPermission: _notificationPermission,
              protectionEnabled: _protectionEnabled,
              status: _status,
              model: _model,
              onToggleProtection: _toggleProtection,
              onRequestNotificationAccess: () async {
                await NotificationListenerService.requestPermission();
                await _refresh();
              },
              onRequestOverlay: ScamShieldController.requestOverlayPermission,
              onRequestNotificationPermission: () async {
                await ScamShieldController.requestNotificationPermission();
                await _refresh();
              },
              onDownloadModel: _downloadModel,
              onDeleteModel: _deleteModel,
              onTestMessage: _runTest,
              onRefresh: _refresh,
            ),
            SettingsTab(
              model: _model,
              hfToken: _token,
              threshold: _threshold,
              endpoint: _endpoint,
              serviceRunning: _status.running,
              onSelectModel: (spec) async {
                await _model.select(spec);
                await ScamShieldController.syncSettings();
              },
              onHfToken: _settings.setHfToken,
              onThreshold: _settings.setConfidenceThreshold,
              onEndpoint: _settings.setRemoteEndpoint,
              onStopService: () async {
                await _settings.setProtectionEnabled(false);
                await ScamShieldController.stopService();
                await _refresh();
              },
              onClearLog: () async {},
            ),
          ],
        ),
      ),
    );
  }
}
