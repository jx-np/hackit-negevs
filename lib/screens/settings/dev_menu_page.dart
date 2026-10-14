import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';
import '../../core/model_catalog.dart';
import '../../services/model_controller.dart';
import '../../services/model_store.dart';
import '../../services/protection_settings.dart';

/// Debug-only developer menu.
///
/// Everything technical that would confuse an everyday user lives here:
/// loading a model file off the device, the hardware backend, the confidence
/// threshold, and the raw cloud-review endpoint. This page is only reachable
/// from [SettingsPage] when the app is built in debug mode, so none of it ships
/// to end users in a release build.
class DevMenuPage extends StatefulWidget {
  const DevMenuPage({
    super.key,
    required this.model,
    required this.settings,
    required this.onChanged,
  });

  final ModelController model;
  final ProtectionSettings settings;

  /// Called after any change that the background service needs to pick up
  /// (model switch, endpoint edit, threshold, backend). The parent syncs the
  /// native side and refreshes.
  final Future<void> Function() onChanged;

  @override
  State<DevMenuPage> createState() => _DevMenuPageState();
}

class _DevMenuPageState extends State<DevMenuPage> {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _contextController = TextEditingController(
    text: kDefaultCustomModelContext.toString(),
  );
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _remoteModelController = TextEditingController();

  double _threshold = 0.6;
  bool _forceCloud = false;
  bool _thinking = false;
  bool _scanning = false;
  ModelBackend _backend = kDefaultModelBackend;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);
    _load();
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    _pathController.dispose();
    _contextController.dispose();
    _endpointController.dispose();
    _remoteModelController.dispose();
    super.dispose();
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final s = widget.settings;
    final path = await s.customModelPath();
    final context = await s.customModelContext();
    final thinking = await s.customModelThinking();
    final threshold = await s.confidenceThreshold();
    final endpoint = await s.remoteEndpoint();
    final remoteModel = await s.remoteModel();
    final forceCloud = await s.forceCloud();
    final backend = await s.modelBackend();
    if (!mounted) return;
    setState(() {
      _pathController.text = path;
      _contextController.text = context.toString();
      _thinking = thinking;
      _threshold = threshold;
      _endpointController.text = endpoint;
      _remoteModelController.text = remoteModel;
      _forceCloud = forceCloud;
      _backend = backend;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return AppScreen(
      title: 'Dev menu',
      scrollable: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.space.lg,
          tokens.space.lg,
          tokens.space.lg,
          tokens.space.xl2,
        ),
        children: [
          _banner(theme),
          const SizedBox(height: 16),
          _sectionTitle('Hardware backend', theme),
          Card(
            child: RadioGroup<ModelBackend>(
              groupValue: _backend,
              onChanged: _setBackend,
              child: Column(
                children: [
                  RadioListTile<ModelBackend>(
                    value: ModelBackend.cpu,
                    title: const Text('CPU'),
                    subtitle: const Text('Most compatible'),
                  ),
                  RadioListTile<ModelBackend>(
                    value: ModelBackend.gpu,
                    title: const Text('GPU'),
                    subtitle: const Text('Faster on supported devices'),
                  ),
                  RadioListTile<ModelBackend>(
                    value: ModelBackend.npu,
                    title: const Text('Automatic'),
                    subtitle: const Text(
                      'NPU for matching models, then GPU or CPU',
                    ),
                  ),
                  if (kDebugMode)
                    RadioListTile<ModelBackend>(
                      value: ModelBackend.npuTest,
                      title: const Text('NPU test (force)'),
                      subtitle: const Text(
                        'Send the current model directly to the NPU',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Load a model file from this device', theme),
          Card(
            child: Column(
              children: [
                _customModelTile(theme),
                const Divider(height: 1),
                ListTile(
                   leading: const Icon(LucideIcons.search),
                  title: const Text('Scan for model files'),
                  subtitle: Text(
                    _scanning
                        ? 'Scanning storage…'
                        : 'Look for .task / .litertlm files',
                  ),
                  trailing: _scanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                       : const Icon(LucideIcons.chevronRight),
                  onTap: _scanning ? null : _scanForModels,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _pathController,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Model file path',
                      hintText: '/storage/emulated/0/Download/model.litertlm',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _contextController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Context window',
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Thinking'),
                  subtitle: const Text(
                    'Give reasoning models room to think before answering',
                  ),
                  value: _thinking,
                  onChanged: (value) => setState(() => _thinking = value),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.model.busy ? null : _loadFromTypedPath,
                       icon: const Icon(LucideIcons.fileUp),
                      label: const Text('Load model from file'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(
            'Cloud review threshold (${(_threshold * 100).round()}%)',
            theme,
          ),
          Slider(
            value: _threshold,
            min: 0,
            max: 1,
            divisions: 20,
            label: '${(_threshold * 100).round()}%',
            onChanged: (value) => setState(() => _threshold = value),
            onChangeEnd: (value) async {
              await widget.settings.setConfidenceThreshold(value);
              await widget.onChanged();
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle('Cloud review', theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Always use cloud review'),
                  subtitle: const Text(
                    'Send every message to the cloud model first',
                  ),
                  value: _forceCloud,
                  onChanged: (value) async {
                    setState(() => _forceCloud = value);
                    await widget.settings.setForceCloud(value);
                    await widget.onChanged();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _endpointController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Endpoint',
                    ),
                    onSubmitted: (value) async {
                      await widget.settings.setRemoteEndpoint(value.trim());
                      await widget.onChanged();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: TextField(
                    controller: _remoteModelController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Model name',
                    ),
                    onSubmitted: (value) async {
                      await widget.settings.setRemoteModel(value.trim());
                      await widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
           const Icon(LucideIcons.flaskConical, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Debug build only. These controls are hidden in release builds.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: theme.textTheme.titleMedium),
    );
  }

  Widget _customModelTile(ThemeData theme) {
    final spec = customModelSpec;
    return ListTile(
       leading: const Icon(LucideIcons.hardDrive),
      title: Text(spec == null ? 'No file picked' : spec.displayName),
      subtitle: Text(
        spec == null
            ? 'Scan or paste a path below'
            : '${spec.filePath}\n~${spec.approxSizeMb} MB · ${spec.contextTokens} tokens',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: spec == null
          ? null
          : TextButton(
              onPressed: widget.model.busy ? null : _forget,
              child: const Text('Forget'),
            ),
    );
  }

  Future<void> _setBackend(ModelBackend? backend) async {
    if (backend == null) return;
    setState(() => _backend = backend);
    await widget.settings.setModelBackend(backend);
    await widget.onChanged();
  }

  Future<void> _scanForModels() async {
    setState(() => _scanning = true);
    if (!await ModelStore.hasAccess() && !await ModelStore.ensureAccess()) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grant all-files access to scan.')),
      );
      return;
    }
    List<FoundModelFile> files;
    try {
      files = await ModelStore.scanForModels();
    } catch (_) {
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
                    'No model files found.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (_, index) {
                    final file = files[index];
                    return ListTile(
                       leading: const Icon(LucideIcons.file),
                      title: Text(file.fileName, maxLines: 1),
                      subtitle: Text('~${file.sizeMb} MB'),
                      onTap: () => Navigator.of(sheetContext).pop(file.path),
                    );
                  },
                ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _pathController.text = picked;
    await _loadPath(picked);
  }

  Future<void> _loadFromTypedPath() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a path first.')),
      );
      return;
    }
    await _loadPath(path);
  }

  Future<void> _loadPath(String path) async {
    final parsed =
        int.tryParse(_contextController.text.trim()) ??
        kDefaultCustomModelContext;
    await widget.model.loadFromDevice(
      path,
      contextTokens: parsed,
      thinking: _thinking,
    );
    if (!mounted) return;
    final error = widget.model.error;
    if (error.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await widget.onChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded ${widget.model.spec.displayName}')),
    );
  }

  Future<void> _forget() async {
    await widget.model.clearCustomModel();
    if (!mounted) return;
    setState(() => _pathController.clear());
    await widget.onChanged();
  }
}
