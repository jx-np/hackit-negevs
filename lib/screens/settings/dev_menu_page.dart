import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/model_catalog.dart';
import '../../services/model_controller.dart';
import '../../services/model_store.dart';
import '../../services/protection_settings.dart';
import '../../services/scamshield_channels.dart';
import '../calls/high_risk_call_alert.dart';

/// Debug-only developer menu.
///
/// Everything technical that would confuse an everyday user lives here:
/// loading a model file off the device. This page is only reachable from
/// [SettingsPage] when the app is built in debug mode, so none of it ships to
/// end users in a release build.
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
  /// (model switch). The parent syncs the native side and refreshes.
  final Future<void> Function() onChanged;

  @override
  State<DevMenuPage> createState() => _DevMenuPageState();
}

class _DevMenuPageState extends State<DevMenuPage>
    with WidgetsBindingObserver {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _contextController = TextEditingController(
    text: kDefaultCustomModelContext.toString(),
  );

  bool _thinking = false;
  bool _scanning = false;

  /// Whether the app currently holds All files access. Only meaningful on
  /// Android; always true elsewhere so the gated controls stay enabled.
  bool _hasAllFilesAccess = !Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.model.addListener(_onModelChanged);
    _load();
    _refreshAllFilesAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.model.removeListener(_onModelChanged);
    _pathController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The grant screen is a separate system Settings activity, so re-check
    // when we come back to the foreground.
    if (state == AppLifecycleState.resumed) {
      _refreshAllFilesAccess();
    }
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshAllFilesAccess() async {
    if (!Platform.isAndroid) return;
    final granted = await ScamShieldController.hasAllFilesAccess();
    if (!mounted) return;
    setState(() => _hasAllFilesAccess = granted);
  }

  Future<void> _requestAllFilesAccess() async {
    await ScamShieldController.requestAllFilesAccess();
    // The result comes back via didChangeAppLifecycleState on resume.
  }

  Future<void> _load() async {
    final s = widget.settings;
    final path = await s.customModelPath();
    final context = await s.customModelContext();
    final thinking = await s.customModelThinking();
    if (!mounted) return;
    setState(() {
      _pathController.text = path;
      _contextController.text = context.toString();
      _thinking = thinking;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dev menu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _banner(theme),
          const SizedBox(height: 16),
          if (Platform.isAndroid) ...[
            _sectionTitle('Storage access', theme),
            _allFilesAccessCard(theme),
            const SizedBox(height: 16),
          ],
          _sectionTitle('Load a model file from this device', theme),
          Card(
            child: Column(
              children: [
                _customModelTile(theme),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.travel_explore),
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
                      : const Icon(Icons.chevron_right),
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
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Load model from file'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('High-risk call alert', theme),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
              ),
              title: const Text('Preview high-risk alert'),
              subtitle: const Text(
                'Show the full-screen warning shown when a reported scam '
                'number calls.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _previewHighRiskAlert,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewHighRiskAlert() async {
    await HighRiskCallAlert.show(
      context,
      phoneNumber: '+1 555 0100',
      trustScore: 12,
      reportCount: 47,
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
          const Icon(Icons.science_outlined, size: 20),
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

  Widget _allFilesAccessCard(ThemeData theme) {
    final granted = _hasAllFilesAccess;
    return Card(
      child: ListTile(
        leading: Icon(
          granted ? Icons.folder_open : Icons.folder_off_outlined,
          color: granted ? theme.colorScheme.primary : null,
        ),
        title: const Text('All files access'),
        subtitle: Text(
          granted
              ? 'Granted. Scanning can reach shared folders like Download.'
              : 'Needed to scan shared storage (Download, Documents) for '
                    'model files. Without it, only the app folder is searched.',
        ),
        trailing: granted
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : FilledButton.tonal(
                onPressed: _requestAllFilesAccess,
                child: const Text('Grant'),
              ),
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
      leading: const Icon(Icons.sd_card_outlined),
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

  Future<void> _scanForModels() async {
    setState(() => _scanning = true);
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
                      leading: const Icon(Icons.insert_drive_file_outlined),
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
