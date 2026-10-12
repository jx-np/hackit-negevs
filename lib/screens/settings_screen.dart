import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';

import '../services/model_controller.dart';
import '../services/protection_settings.dart';
import '../services/scamshield_channels.dart';
import 'permissions_tab.dart';
import 'settings_tab.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProtectionSettings _settings = ProtectionSettings();
  late final ModelController _model = ModelController(_settings);

  double _threshold = 0.6;
  String _endpoint = '';
  String _remoteModel = kDefaultRemoteModel;
  bool _forceCloud = false;
  bool _serviceRunning = false;

  @override
  void initState() {
    super.initState();
    _model.addListener(_onModelChanged);
    _model.load();
    _refresh();
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _model.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final threshold = await _settings.confidenceThreshold();
    final endpoint = await _settings.remoteEndpoint();
    final remoteModel = await _settings.remoteModel();
    final forceCloud = await _settings.forceCloud();
    final running = await ScamShieldController.isServiceRunning();
    if (!mounted) return;
    setState(() {
      _threshold = threshold;
      _endpoint = endpoint;
      _remoteModel = remoteModel;
      _forceCloud = forceCloud;
      _serviceRunning = running;
    });
  }

  Future<void> _saveAndSync(Future<void> Function() save) async {
    await save();
    await ScamShieldController.syncSettings();
    await _refresh();
  }

  Future<void> _downloadModel() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _model.download();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.settingsScreenModelInstalled(_model.spec.displayName)
              : _model.error,
        ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsScreenTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.settingsScreenModelTab),
              Tab(text: l10n.settingsScreenPermissionsTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SettingsTab(
              model: _model,
              onDownloadModel: _downloadModel,
              onDeleteModel: _deleteModel,
              threshold: _threshold,
              endpoint: _endpoint,
              remoteModel: _remoteModel,
              forceCloud: _forceCloud,
              serviceRunning: _serviceRunning,
              onSelectModel: (spec) async {
                await _model.select(spec);
                await ScamShieldController.syncSettings();
              },
              onModelChanged: () async {
                await ScamShieldController.syncSettings();
                await _refresh();
              },
              onThreshold: (value) =>
                  _saveAndSync(() => _settings.setConfidenceThreshold(value)),
              onEndpoint: (value) =>
                  _saveAndSync(() => _settings.setRemoteEndpoint(value)),
              onRemoteModel: (value) =>
                  _saveAndSync(() => _settings.setRemoteModel(value)),
              onForceCloud: (value) =>
                  _saveAndSync(() => _settings.setForceCloud(value)),
              onStopService: () async {
                await _settings.setProtectionEnabled(false);
                await ScamShieldController.setShieldEnabled(false);
                await ScamShieldController.stopService();
                await _refresh();
              },
              onClearLog: () async {},
            ),
            const PermissionsTab(),
          ],
        ),
      ),
    );
  }
}
