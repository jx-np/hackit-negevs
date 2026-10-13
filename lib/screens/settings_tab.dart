// DEPRECATED — replaced by lib/screens/settings/settings_page.dart and
// lib/screens/settings/dev_menu_page.dart. Nothing references this file; it is
// kept only because the workspace host could not delete it over Live Share.
// Safe to delete.
import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../core/model_catalog.dart';
import '../services/model_controller.dart';
import '../services/model_store.dart';
import '../services/protection_settings.dart';
import '../state/auth_controller.dart';
import '../state/locale_controller.dart';
import '../widgets/tour/tour_controller.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    required this.model,
    required this.onDownloadModel,
    required this.onDeleteModel,
    required this.threshold,
    required this.endpoint,
    required this.remoteModel,
    required this.forceCloud,
    required this.serviceRunning,
    required this.onSelectModel,
    required this.onModelChanged,
    required this.onThreshold,
    required this.onEndpoint,
    required this.onRemoteModel,
    required this.onForceCloud,
    required this.onStopService,
    required this.onClearLog,
  });

  final ModelController model;
  final Future<void> Function() onDownloadModel;
  final Future<void> Function() onDeleteModel;
  final double threshold;
  final String endpoint;
  final String remoteModel;
  final bool forceCloud;
  final bool serviceRunning;
  final Future<void> Function(ScamModelSpec spec) onSelectModel;
  final Future<void> Function() onModelChanged;
  final Future<void> Function(double value) onThreshold;
  final Future<void> Function(String value) onEndpoint;
  final Future<void> Function(String value) onRemoteModel;
  final Future<void> Function(bool value) onForceCloud;
  final Future<void> Function() onStopService;
  final Future<void> Function() onClearLog;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _endpointController =
      TextEditingController(text: widget.endpoint);
  late final TextEditingController _remoteModelController =
      TextEditingController(text: widget.remoteModel);
  final TextEditingController _customPathController = TextEditingController();
  final TextEditingController _customContextController = TextEditingController(
    text: kDefaultCustomModelContext.toString(),
  );
  late double _threshold = widget.threshold;
  bool _customThinking = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _loadCustomSettings();
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _remoteModelController.dispose();
    _customPathController.dispose();
    _customContextController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomSettings() async {
    final settings = ProtectionSettings();
    final path = await settings.customModelPath();
    final context = await settings.customModelContext();
    final thinking = await settings.customModelThinking();
    if (!mounted) return;
    _customPathController.text = path;
    _customContextController.text = context.toString();
    setState(() => _customThinking = thinking);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.settingsDetectionModel, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final spec in allModels) _modelTile(spec),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.model.spec.note,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _installedModelCard(),
        const SizedBox(height: 24),
        Text(l10n.settingsProtection, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(l10n.settingsClearNotifications),
                onTap: widget.onClearLog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.stop_circle_outlined),
                title: Text(l10n.settingsStopProtection),
                subtitle: Text(
                  widget.serviceRunning ? l10n.settingsServiceRunning : l10n.settingsServiceStopped,
                ),
                onTap: widget.serviceRunning ? widget.onStopService : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.settingsAccount, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(l10n.settingsShowTutorial),
                subtitle: Text(l10n.settingsReplayTour),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.read<TourController>().start(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context).settingsLanguage),
                subtitle: Text(_languageLabel(context)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showLanguagePicker,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.settingsLogOut),
                subtitle: Text(l10n.settingsSignOutSubtitle),
                onTap: () => context.read<AuthController>().logout(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            initiallyExpanded: false,
            leading: const Icon(Icons.tune),
            title: Text(
              l10n.settingsAdvanced,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(l10n.settingsAdvancedSubtitle),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.settingsModelFromDevice,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    _customModelTile(),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.travel_explore),
                      title: Text(l10n.settingsScanForModels),
                      subtitle: Text(
                        _scanning
                            ? l10n.settingsScanningStorage
                            : l10n.settingsScanSubtitle,
                      ),
                      trailing:
                          _scanning
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                      onTap: _scanning ? null : _scanForModels,
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _customPathController,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: l10n.settingsModelFilePath,
                          hintText: '/storage/emulated/0/Download/model.litertlm',
                          helperText: l10n.settingsModelFilePathHelper,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _SaveableField(
                        controller: _customContextController,
                        label: l10n.settingsContextWindow,
                        hint: kDefaultCustomModelContext.toString(),
                        helper: l10n.settingsContextWindowHelper(
                          kMaxCustomModelContext,
                        ),
                        keyboardType: TextInputType.number,
                        onSave: (value) async {
                          final parsed = int.tryParse(value);
                          if (parsed == null ||
                              parsed < 1024 ||
                              parsed > kMaxCustomModelContext) {
                            return l10n.settingsContextRange(
                              kMaxCustomModelContext,
                            );
                          }
                          final settings = ProtectionSettings();
                          await settings.setCustomModelContext(parsed);
                          await settings.hydrateCustomModel();
                          await widget.onModelChanged();
                          return null;
                        },
                      ),
                    ),
                    SwitchListTile(
                      title: Text(l10n.settingsThinking),
                      subtitle: Text(l10n.settingsThinkingHelper),
                      value: _customThinking,
                      onChanged: (value) async {
                        setState(() => _customThinking = value);
                        final settings = ProtectionSettings();
                        await settings.setCustomModelThinking(value);
                        await settings.hydrateCustomModel();
                        await widget.onModelChanged();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              widget.model.busy ? null : _loadFromTypedPath,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: Text(l10n.settingsLoadModelFromFile),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.settingsCloudThreshold((_threshold * 100).round()),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Slider(
                value: _threshold,
                min: 0,
                max: 1,
                divisions: 20,
                label: '${(_threshold * 100).round()}%',
                onChanged: (value) => setState(() => _threshold = value),
                onChangeEnd: widget.onThreshold,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.settingsCloudReview,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.settingsForceCloud),
                      subtitle: Text(l10n.settingsForceCloudHelper),
                      value: widget.forceCloud,
                      onChanged: (value) => widget.onForceCloud(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SaveableField(
                controller: _endpointController,
                label: l10n.settingsEndpoint,
                hint: l10n.settingsEndpointHint,
                keyboardType: TextInputType.url,
                onSave: (value) async {
                  await widget.onEndpoint(value);
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _SaveableField(
                controller: _remoteModelController,
                label: l10n.settingsModelName,
                hint: 'minicpm5-2b',
                onSave: (value) async {
                  await widget.onRemoteModel(value);
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _installedModelCard() {
    final l10n = AppLocalizations.of(context);
    final model = widget.model;
    final scheme = Theme.of(context).colorScheme;
    final progress = model.progress;
    final downloading = model.busy && progress >= 0 && progress < 100;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              model.installed ? Icons.check_circle : Icons.memory,
              color: model.installed ? Colors.green : scheme.outline,
            ),
            title: Text(l10n.settingsOnDeviceModel(model.spec.displayName)),
            subtitle: Text(
              model.installed
                  ? (model.persistent
                      ? l10n.settingsReadyKept(model.spec.approxSizeMb)
                      : l10n.settingsReadyOffline(model.spec.approxSizeMb))
                  : downloading
                      ? (model.isBundled
                          ? l10n.settingsInstallingBundled(progress)
                          : l10n.settingsDownloadingPct(progress))
                      : model.isBundled
                          ? l10n.settingsBundledPreparing
                          : l10n.settingsNotDownloaded(model.spec.approxSizeMb),
            ),
            trailing: model.installed
                ? TextButton(
                    onPressed: model.busy ? null : widget.onDeleteModel,
                    child: Text(l10n.settingsRemove),
                  )
                : TextButton(
                    onPressed: model.busy ? null : widget.onDownloadModel,
                    child: Text(
                      downloading
                          ? l10n.settingsPercent(progress)
                          : model.isBundled
                              ? l10n.settingsInstall
                              : l10n.settingsDownload,
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
                style: TextStyle(color: scheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _customModelTile() {
    final l10n = AppLocalizations.of(context);
    final spec = customModelSpec;
    return ListTile(
      leading: const Icon(Icons.sd_card_outlined),
      title: Text(
        spec == null ? l10n.settingsNoFilePicked : spec.displayName,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        spec == null
            ? l10n.settingsScanHint
            : l10n.settingsCustomModelMeta(
                spec.filePath ?? '',
                spec.approxSizeMb,
                spec.contextTokens,
              ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          spec == null
              ? null
              : TextButton(
                  onPressed: widget.model.busy ? null : _forgetCustomModel,
                  child: Text(l10n.settingsForget),
                ),
    );
  }

  Future<void> _scanForModels() async {
    setState(() => _scanning = true);
    if (!await ModelStore.hasAccess() && !await ModelStore.ensureAccess()) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsAllFilesAccess),
        ),
      );
      return;
    }
    List<FoundModelFile> files;
    try {
      files = await ModelStore.scanForModels();
    } catch (error) {
      debugPrint('[Scan] failed: $error');
      files = const [];
    }
    if (!mounted) return;
    setState(() => _scanning = false);
    await _showPicker(files);
  }

  Future<void> _showPicker(List<FoundModelFile> files) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          child: files.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.settingsNoModelFiles,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (_, index) {
                    final file = files[index];
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file_outlined),
                      title: Text(file.fileName, maxLines: 1),
                      subtitle: Text(l10n.settingsFileSizeMb(file.sizeMb)),
                      onTap: () => Navigator.of(sheetContext).pop(file.path),
                    );
                  },
                ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _customPathController.text = picked;
    await _loadPath(picked);
  }

  Future<void> _loadFromTypedPath() async {
    final path = _customPathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsEnterPathFirst),
        ),
      );
      return;
    }
    await _loadPath(path);
  }

  Future<void> _loadPath(String path) async {
    final parsed = int.tryParse(_customContextController.text.trim()) ??
        kDefaultCustomModelContext;
    await widget.model.loadFromDevice(
      path,
      contextTokens: parsed,
      thinking: _customThinking,
    );
    if (!mounted) return;
    final error = widget.model.error;
    if (error.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await widget.onModelChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).settingsModelLoaded(widget.model.spec.displayName),
        ),
      ),
    );
  }

  Future<void> _forgetCustomModel() async {
    await widget.model.clearCustomModel();
    if (!mounted) return;
    setState(() => _customPathController.clear());
    await widget.onModelChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).settingsModelForgotten),
      ),
    );
  }

  String _languageLabel(BuildContext context) {
    final code = context.watch<LocaleController>().locale?.languageCode;
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
        return AppLocalizations.of(context).settingsLanguageSystem;
    }
  }

  Future<void> _showLanguagePicker() async {
    final controller = context.read<LocaleController>();
    final l10n = AppLocalizations.of(context);
    final current = controller.locale?.languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<String?>(
          groupValue: current,
          onChanged: (value) =>
              Navigator.of(sheetContext).pop(value ?? '__system__'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                value: null,
                title: Text(l10n.settingsLanguageSystem),
              ),
              RadioListTile<String?>(
                value: 'en',
                title: const Text('English'),
              ),
              RadioListTile<String?>(
                value: 'zh',
                title: const Text('中文'),
              ),
              RadioListTile<String?>(
                value: 'ta',
                title: const Text('தமிழ்'),
              ),
              RadioListTile<String?>(
                value: 'ms',
                title: const Text('Melayu'),
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

  Widget _modelTile(ScamModelSpec spec) {
    final l10n = AppLocalizations.of(context);
    final selected = spec.id == widget.model.spec.id;
    final subtitle =
        spec.filePath != null
            ? l10n.settingsSizeFromDevice(spec.approxSizeMb)
            : spec.assetPath != null
                ? l10n.settingsSizeBundled(spec.approxSizeMb)
                : l10n.settingsSizeDownload(spec.approxSizeMb);
    return ListTile(
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
      title: Text(spec.displayName),
      subtitle: Text(subtitle),
      trailing: spec.requiresToken
          ? const Icon(Icons.lock_outline, size: 18)
          : null,
      onTap: () => widget.onSelectModel(spec),
    );
  }
}

class _SaveableField extends StatefulWidget {
  const _SaveableField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onSave,
    this.helper,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Future<String?> Function(String value) onSave;
  final String? helper;
  final TextInputType? keyboardType;

  @override
  State<_SaveableField> createState() => _SaveableFieldState();
}

class _SaveableFieldState extends State<_SaveableField> {
  final FocusNode _focus = FocusNode();
  late String _savedText = widget.controller.text.trim();
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) _save();
  }

  Future<void> _save() async {
    final value = widget.controller.text.trim();
    if (value == _savedText) return;
    final error = await widget.onSave(value);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {
      _savedText = value;
      _justSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).settingsFieldSaved(widget.label),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justSaved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      obscureText: false,
      keyboardType: widget.keyboardType,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _save(),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        suffixIcon: IconButton(
          tooltip: AppLocalizations.of(context).settingsSave,
          onPressed: _save,
          icon: Icon(
            _justSaved ? Icons.check_circle : Icons.save_outlined,
            color: _justSaved ? Colors.green : null,
          ),
        ),
      ),
    );
  }
}
