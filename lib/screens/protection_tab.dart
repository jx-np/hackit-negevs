import 'package:flutter/material.dart';

import '../services/model_controller.dart';
import '../services/scamshield_channels.dart';

class ProtectionTab extends StatefulWidget {
  const ProtectionTab({
    super.key,
    required this.notificationAccess,
    required this.overlayGranted,
    required this.notificationPermission,
    required this.protectionEnabled,
    required this.status,
    required this.model,
    required this.onToggleProtection,
    required this.onRequestNotificationAccess,
    required this.onRequestOverlay,
    required this.onRequestNotificationPermission,
    required this.onDownloadModel,
    required this.onDeleteModel,
    required this.onTestMessage,
    required this.onRefresh,
  });

  final bool notificationAccess;
  final bool overlayGranted;
  final bool notificationPermission;
  final bool protectionEnabled;
  final ServiceStatus status;
  final ModelController model;
  final Future<void> Function(bool value) onToggleProtection;
  final Future<void> Function() onRequestNotificationAccess;
  final Future<void> Function() onRequestOverlay;
  final Future<void> Function() onRequestNotificationPermission;
  final Future<void> Function() onDownloadModel;
  final Future<void> Function() onDeleteModel;
  final Future<void> Function(String text) onTestMessage;
  final Future<void> Function() onRefresh;

  @override
  State<ProtectionTab> createState() => _ProtectionTabState();
}

class _ProtectionTabState extends State<ProtectionTab> {
  final TextEditingController _testController = TextEditingController();

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = widget.status;
    final model = widget.model;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _protectionCard(scheme),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile('Checked', '${status.evaluated}', Icons.forum_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile('Alerts', '${status.alertsRaised}', Icons.warning_amber_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _setupCard(scheme, model),
          const SizedBox(height: 12),
          _testCard(scheme),
        ],
      ),
    );
  }

  Widget _protectionCard(ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              widget.protectionEnabled ? Icons.shield : Icons.shield_outlined,
              color: widget.protectionEnabled ? Colors.green : scheme.outline,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.protectionEnabled ? 'Protection is on' : 'Protection is off',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.status.lastMessage.isEmpty
                        ? 'Reads notifications from messaging apps'
                        : widget.status.lastMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: widget.protectionEnabled,
              onChanged: widget.onToggleProtection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _setupCard(ColorScheme scheme, ModelController model) {
    final progress = model.progress;
    final downloading = model.busy && progress >= 0 && progress < 100;
    return Card(
      child: Column(
        children: [
          _checkTile(
            'Notification access',
            widget.notificationAccess,
            widget.onRequestNotificationAccess,
          ),
          const Divider(height: 1),
          _checkTile(
            'Display over other apps',
            widget.overlayGranted,
            widget.onRequestOverlay,
          ),
          const Divider(height: 1),
          _checkTile(
            'Alerts allowed',
            widget.notificationPermission,
            widget.onRequestNotificationPermission,
          ),
          const Divider(height: 1),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _checkTile(String title, bool ok, Future<void> Function() onFix) {
    return ListTile(
      leading: Icon(
        ok ? Icons.check_circle : Icons.error_outline,
        color: ok ? Colors.green : Colors.orange,
      ),
      title: Text(title),
      subtitle: Text(ok ? 'Granted' : 'Required'),
      trailing: ok ? null : TextButton(onPressed: onFix, child: const Text('Grant')),
    );
  }

  Widget _testCard(ColorScheme scheme) {
    return Card(
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
    );
  }
}
