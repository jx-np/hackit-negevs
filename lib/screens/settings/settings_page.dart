import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import '../../core/model_catalog.dart';
import '../../services/model_controller.dart';
import '../../services/protection_settings.dart';
import '../../services/scamshield_channels.dart';
import '../../state/auth_controller.dart';
import '../../state/locale_controller.dart';
import '../../widgets/tour/tour_controller.dart';
import '../permissions_tab.dart';
import 'dev_menu_page.dart';
import 'widgets/settings_section.dart';

/// User-facing settings for the scam-protection app.
///
/// The audience is people who may have just been scammed and are looking for a
/// simple protection tool, so the copy stays plain and calm: no red warnings,
/// no jargon, no alarmist language. Anything technical (custom model files,
/// cloud review, raw endpoints) lives behind the debug-only Dev menu.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ProtectionSettings _settings = ProtectionSettings();
  late final ModelController _model = ModelController(_settings);

  ModelBackend _backend = kDefaultModelBackend;
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
    final backend = await _settings.modelBackend();
    final running = await ScamShieldController.isServiceRunning();
    if (!mounted) return;
    setState(() {
      _backend = backend;
      _serviceRunning = running;
    });
  }

  Future<void> _downloadModel() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _model.download();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? '${_model.spec.displayName} is ready' : _model.error,
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

  Future<void> _selectModel(ScamModelSpec spec) async {
    await _model.select(spec);
    await ScamShieldController.syncSettings();
    await _refresh();
  }

  Future<void> _setBackend(ModelBackend backend) async {
    setState(() => _backend = backend);
    await _settings.setModelBackend(backend);
    await ScamShieldController.syncSettings();
  }

  Future<void> _stopProtection() async {
    await _settings.setProtectionEnabled(false);
    await ScamShieldController.setShieldEnabled(false);
    await ScamShieldController.stopService();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _protectionSection(),
            const SizedBox(height: 24),
            _speedSection(),
            const SizedBox(height: 24),
            _appSection(),
            const SizedBox(height: 24),
            _accountSection(),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              _devSection(),
            ],
          ],
        ),
      ),
    );
  }

  // The on-device checker: what it is, whether it is ready, and how to get it.
  Widget _protectionSection() {
    final model = _model;
    final progress = model.progress;
    final downloading = model.busy && progress >= 0 && progress < 100;
    return SettingsSection(
      title: 'Scam checker',
      caption:
          'A small assistant runs on your phone and quietly reviews messages '
          'for common scam patterns. Nothing leaves your device.',
      children: [
        FTile(
          prefix: Icon(
            model.installed ? Icons.verified_outlined : Icons.download_outlined,
          ),
          title: Text(model.spec.displayName),
          subtitle: Text(
            model.installed
                ? 'Ready to protect you'
                : downloading
                    ? 'Setting up… $progress%'
                    : 'About ${model.spec.approxSizeMb} MB · one-time download',
          ),
          suffix: model.installed
              ? TextButton(
                  onPressed: model.busy ? null : _deleteModel,
                  child: const Text('Remove'),
                )
              : TextButton(
                  onPressed: model.busy ? null : _downloadModel,
                  child: Text(downloading ? '$progress%' : 'Download'),
                ),
        ),
        if (downloading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: LinearProgressIndicator(value: progress / 100),
          ),
        if (model.error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              model.error,
              style: TextStyle(color: context.theme.colors.error),
            ),
          ),
        for (final spec in allModels) ...[
          const FDivider(),
          _modelChoiceTile(spec),
        ],
      ],
    );
  }

  Widget _modelChoiceTile(ScamModelSpec spec) {
    final selected = spec.id == _model.spec.id;
    return FTile(
      enabled: !_model.busy,
      prefix: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? context.theme.colors.primary
            : context.theme.colors.mutedForeground,
      ),
      title: Text(spec.displayName),
      subtitle: Text('About ${spec.approxSizeMb} MB'),
      onPress: () => _selectModel(spec),
    );
  }

  // Speed: let people trade accuracy/compatibility for speed by using the GPU.
  Widget _speedSection() {
    return SettingsSection(
      title: 'Checking speed',
      caption:
          'The processor is the most compatible choice. The graphics chip can '
          'be faster on newer phones, but it is not supported everywhere.',
      children: [
        FTile(
          prefix: const Icon(Icons.memory_outlined),
          title: const Text('Processor (recommended)'),
          subtitle: const Text('Works on every phone'),
          suffix: _backend == ModelBackend.cpu
              ? Icon(Icons.check, color: context.theme.colors.primary)
              : null,
          onPress: () => _setBackend(ModelBackend.cpu),
        ),
        const FDivider(),
        FTile(
          prefix: const Icon(Icons.bolt_outlined),
          title: const Text('Graphics chip (faster)'),
          subtitle: const Text('For newer phones with a supported GPU'),
          suffix: _backend == ModelBackend.gpu
              ? Icon(Icons.check, color: context.theme.colors.primary)
              : null,
          onPress: () => _setBackend(ModelBackend.gpu),
        ),
      ],
    );
  }

  Widget _appSection() {
    final localeController = context.watch<LocaleController>();
    return SettingsSection(
      title: 'App',
      children: [
        FTile(
          prefix: const Icon(Icons.language_outlined),
          title: const Text('Language'),
          subtitle: Text(_languageLabel(localeController.locale?.languageCode)),
          suffix: const Icon(Icons.chevron_right),
          onPress: _showLanguagePicker,
        ),
        const FDivider(),
        FTile(
          prefix: const Icon(Icons.school_outlined),
          title: const Text('Show the tour again'),
          subtitle: const Text('Replay the quick walkthrough'),
          suffix: const Icon(Icons.chevron_right),
          onPress: () => context.read<TourController>().start(),
        ),
        const FDivider(),
        FTile(
          prefix: const Icon(Icons.shield_outlined),
          title: const Text('Permissions'),
          subtitle: const Text('Check what the app is allowed to do'),
          suffix: const Icon(Icons.chevron_right),
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Permissions')),
                body: const PermissionsTab(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountSection() {
    return SettingsSection(
      title: 'Protection',
      children: [
        FTile(
          enabled: _serviceRunning,
          prefix: Icon(
            _serviceRunning
                ? Icons.stop_circle_outlined
                : Icons.pause_circle_outlined,
          ),
          title: const Text('Pause protection'),
          subtitle: Text(
            _serviceRunning ? 'Currently running' : 'Currently paused',
          ),
          onPress: _serviceRunning ? _stopProtection : null,
        ),
        const FDivider(),
        FTile(
          prefix: const Icon(Icons.logout_outlined),
          title: const Text('Sign out'),
          subtitle: const Text('You can sign back in at any time'),
          onPress: () => context.read<AuthController>().logout(),
        ),
      ],
    );
  }

  // Debug-only: everything technical lives here so the normal UI stays simple.
  Widget _devSection() {
    return SettingsSection(
      title: 'Dev menu',
      caption: 'Debug build only. Not shown in release builds.',
      children: [
        FTile(
          prefix: const Icon(Icons.terminal_outlined),
          title: const Text('Open Dev menu'),
          subtitle: const Text('Custom models, cloud review, backend details'),
          suffix: const Icon(Icons.chevron_right),
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DevMenuPage(
                model: _model,
                settings: _settings,
                onChanged: () async {
                  await ScamShieldController.syncSettings();
                  await _refresh();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _languageLabel(String? code) {
    switch (code) {
      case 'zh':
        return '中文';
      case 'ta':
        return 'தமிழ்';
      case 'ms':
        return 'Melayu';
      case 'en':
        return 'English';
      default:
        return 'System default';
    }
  }

  Future<void> _showLanguagePicker() async {
    final controller = context.read<LocaleController>();
    final current = controller.locale?.languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<String>(
          groupValue: current ?? '__system__',
          onChanged: (value) {
            if (value != null) Navigator.of(sheetContext).pop(value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in const [
                MapEntry('__system__', 'System default'),
                MapEntry('en', 'English'),
                MapEntry('zh', '中文'),
                MapEntry('ta', 'தமிழ்'),
                MapEntry('ms', 'Melayu'),
              ])
                RadioListTile<String>(
                  value: entry.key,
                  title: Text(entry.value),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    if (selected == '__system__') {
      await controller.clearLocale();
    } else {
      await controller.setLocale(Locale(selected));
    }
  }
}
