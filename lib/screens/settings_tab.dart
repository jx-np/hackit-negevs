import 'package:flutter/material.dart';

import '../core/model_catalog.dart';
import '../services/model_controller.dart';
import '../services/model_store.dart';
import '../services/protection_settings.dart';

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Detection model', style: Theme.of(context).textTheme.titleLarge),
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
        Text('Protection', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Clear captured notifications'),
                onTap: widget.onClearLog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.stop_circle_outlined),
                title: const Text('Stop background protection'),
                subtitle: Text(
                  widget.serviceRunning ? 'Service running' : 'Service stopped',
                ),
                onTap: widget.serviceRunning ? widget.onStopService : null,
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
              'Advanced',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: const Text('Developer and model-tuning options'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Model from this device (testing)',
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
                      title: const Text('Scan for model files'),
                      subtitle: Text(
                        _scanning
                            ? 'Scanning storage…'
                            : 'Finds .litertlm and .task files in Downloads and Documents',
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
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Model file path',
                          hintText: '/storage/emulated/0/Download/model.litertlm',
                          helperText:
                              'Typed paths work too. The file is used in place — it is never copied.',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _SaveableField(
                        controller: _customContextController,
                        label: 'Context window (tokens)',
                        hint: kDefaultCustomModelContext.toString(),
                        helper:
                            'Context to request when loading. Must not exceed what '
                            'your conversion baked in as kv_cache_max_len '
                            '(MiniCPM5-2B supports up to $kMaxCustomModelContext). '
                            'Larger windows cost roughly 40 KB of RAM per token.',
                        keyboardType: TextInputType.number,
                        onSave: (value) async {
                          final parsed = int.tryParse(value);
                          if (parsed == null ||
                              parsed < 1024 ||
                              parsed > kMaxCustomModelContext) {
                            return 'Enter between 1024 and $kMaxCustomModelContext';
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
                      title: const Text('Thinking (reasoning)'),
                      subtitle: const Text(
                        'Lets the model reason before answering. Uses more tokens '
                        'and is slower; needs a 3000+ token context to be useful.',
                      ),
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
                          label: const Text('Load model from file'),
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
                  'Cloud escalation threshold — escalate below ${(_threshold * 100).round()}%',
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
                  'Cloud review',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Force cloud'),
                      subtitle: const Text(
                        'Send every message to the cloud model and skip the '
                        'on-device model. Falls back to on-device only if the cloud '
                        'is unreachable.',
                      ),
                      value: widget.forceCloud,
                      onChanged: (value) => widget.onForceCloud(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SaveableField(
                controller: _endpointController,
                label: 'Endpoint',
                hint: 'https://.../v1/chat/completions (empty = disabled)',
                keyboardType: TextInputType.url,
                onSave: (value) async {
                  await widget.onEndpoint(value);
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _SaveableField(
                controller: _remoteModelController,
                label: 'Model name',
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
            title: Text('On-device model — ${model.spec.displayName}'),
            subtitle: Text(
              model.installed
                  ? (model.persistent
                      ? 'Ready · ${model.spec.approxSizeMb} MB · kept in Downloads (survives reinstall)'
                      : 'Ready · ${model.spec.approxSizeMb} MB · runs offline')
                  : downloading
                      ? (model.isBundled
                          ? 'Installing bundled model $progress%'
                          : 'Downloading $progress%')
                      : model.isBundled
                          ? 'Bundled with the app · preparing'
                          : 'Not downloaded (${model.spec.approxSizeMb} MB)',
            ),
            trailing: model.installed
                ? TextButton(
                    onPressed: model.busy ? null : widget.onDeleteModel,
                    child: const Text('Remove'),
                  )
                : TextButton(
                    onPressed: model.busy ? null : widget.onDownloadModel,
                    child: Text(
                      downloading
                          ? '$progress%'
                          : model.isBundled
                              ? 'Install'
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
                style: TextStyle(color: scheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _customModelTile() {
    final spec = customModelSpec;
    return ListTile(
      leading: const Icon(Icons.sd_card_outlined),
      title: Text(
        spec == null ? 'No file picked yet' : spec.displayName,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        spec == null
            ? 'Scan for a model file that is already on this phone.'
            : '${spec.filePath} · ${spec.approxSizeMb} MB · '
                '${spec.contextTokens} tokens',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          spec == null
              ? null
              : TextButton(
                  onPressed: widget.model.busy ? null : _forgetCustomModel,
                  child: const Text('Forget'),
                ),
    );
  }

  Future<void> _scanForModels() async {
    setState(() => _scanning = true);
    if (!await ModelStore.hasAccess() && !await ModelStore.ensureAccess()) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Allow "All files access" for Scam Shield in Android settings, '
            'then scan again.',
          ),
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
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No .litertlm or .task files found.\n\n'
                    'Put the model in Downloads (or type its path below) and '
                    'scan again.',
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
                      subtitle: Text('${file.sizeMb} MB'),
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
        const SnackBar(content: Text('Enter a model file path first')),
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
      SnackBar(content: Text('${widget.model.spec.displayName} loaded')),
    );
  }

  Future<void> _forgetCustomModel() async {
    await widget.model.clearCustomModel();
    if (!mounted) return;
    setState(() => _customPathController.clear());
    await widget.onModelChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Picked model forgotten — file kept on device')),
    );
  }

  Widget _modelTile(ScamModelSpec spec) {
    final selected = spec.id == widget.model.spec.id;
    final subtitle =
        spec.filePath != null
            ? '~${spec.approxSizeMb} MB · from this device'
            : spec.assetPath != null
                ? '~${spec.approxSizeMb} MB · bundled'
                : '~${spec.approxSizeMb} MB · download';
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
        content: Text('${widget.label} saved'),
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
          tooltip: 'Save',
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
