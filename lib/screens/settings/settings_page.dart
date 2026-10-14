import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/model_catalog.dart';
import '../../services/model_controller.dart';
import '../../services/protection_settings.dart';
import '../../services/scamshield_channels.dart';
import '../../state/auth_controller.dart';
import '../../state/locale_controller.dart';
import '../../widgets/tour/tour_controller.dart';
import '../permissions/permissions_page.dart';
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
        SettingsRow(
          leading: Icon(
            model.installed ? Icons.verified_outlined : Icons.download_outlined,
          ),
          title: model.spec.displayName,
          subtitle:
            model.spec.isBuiltIn
              ? 'Uses Android system AI when available'
              : model.installed
                ? 'Ready to protect you'
                : downloading
                    ? 'Setting up… $progress%'
                    : 'About ${model.spec.approxSizeMb} MB · one-time download',
          trailing: model.installed
              ? TextButton(
                  onPressed: model.busy ? null : _deleteModel,
                  child: const Text('Remove'),
                )
              : TextButton(
                  onPressed: model.busy ? null : _downloadModel,
                  child: Text(
                    downloading
                        ? '$progress%'
                        : model.spec.isBuiltIn
                            ? 'Prepare'
                            : 'Download',
                  ),
                ),
        ),
        if (downloading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: LinearProgressIndicator(value: progress / 100),
          ),
        if (model.error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              model.error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        for (final spec in allModels) ...[
          const Divider(height: 1),
          _modelChoiceTile(spec),
        ],
      ],
    );
  }

  Widget _modelChoiceTile(ScamModelSpec spec) {
    final selected = spec.id == _model.spec.id;
    return SettingsRow(
      enabled: !_model.busy,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: spec.displayName,
        subtitle: spec.isBuiltIn
          ? 'Android system model · no app download'
          : 'About ${spec.approxSizeMb} MB',
      onTap: () => _selectModel(spec),
    );
  }

  // Let the runtime choose the fastest available accelerator.
  Widget _speedSection() {
    return SettingsSection(
      title: 'Checking speed',
        caption: 'Automatic uses the phone\'s NPU, GPU, or processor and falls '
          'back when an accelerator is unavailable.',
      children: [
        SettingsRow(
          leading: const Icon(Icons.memory_outlined),
          title: 'Processor',
          subtitle: 'Most compatible fallback',
          trailing: _backend == ModelBackend.cpu
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => _setBackend(ModelBackend.cpu),
        ),
        const Divider(height: 1),
        SettingsRow(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: 'Automatic (recommended)',
          subtitle: 'NPU for matching models, then GPU or processor',
          trailing: _backend == ModelBackend.npu
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => _setBackend(ModelBackend.npu),
        ),
        if (kDebugMode) ...[
          const Divider(height: 1),
          SettingsRow(
            leading: const Icon(Icons.developer_mode_outlined),
            title: 'NPU test (force)',
            subtitle: 'Debug only: send the current model directly to NPU',
            trailing: _backend == ModelBackend.npuTest
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () => _setBackend(ModelBackend.npuTest),
          ),
        ],
        const Divider(height: 1),
        SettingsRow(
          leading: const Icon(Icons.bolt_outlined),
          title: 'Graphics chip (faster)',
          subtitle: 'For newer phones with a supported GPU',
          trailing: _backend == ModelBackend.gpu
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => _setBackend(ModelBackend.gpu),
        ),
      ],
    );
  }

  Widget _appSection() {
    final localeController = context.watch<LocaleController>();
    return SettingsSection(
      title: 'App',
      children: [
        SettingsRow(
          leading: const Icon(Icons.language_outlined),
          title: 'Language',
          subtitle: _languageLabel(localeController.locale?.languageCode),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showLanguagePicker,
        ),
        const Divider(height: 1),
        SettingsRow(
          leading: const Icon(Icons.school_outlined),
          title: 'Show the tour again',
          subtitle: 'Replay the quick walkthrough',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.read<TourController>().start(),
        ),
        const Divider(height: 1),
        SettingsRow(
          leading: const Icon(Icons.shield_outlined),
          title: 'Permissions',
          subtitle: 'Check what the app is allowed to do',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
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
        SettingsRow(
          enabled: _serviceRunning,
          leading: Icon(
            _serviceRunning
                ? Icons.stop_circle_outlined
                : Icons.pause_circle_outlined,
          ),
          title: 'Pause protection',
          subtitle:
            _serviceRunning ? 'Currently running' : 'Currently paused',
          onTap: _serviceRunning ? _stopProtection : null,
        ),
        const Divider(height: 1),
        SettingsRow(
          leading: const Icon(Icons.logout_outlined),
          title: 'Sign out',
          subtitle: 'You can sign back in at any time',
          onTap: () => context.read<AuthController>().logout(),
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
        SettingsRow(
          leading: const Icon(Icons.terminal_outlined),
          title: 'Open Dev menu',
          subtitle: 'Custom models, cloud review, backend details',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
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
