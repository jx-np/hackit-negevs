import 'package:flutter/material.dart';

import '../services/scamshield_channels.dart';

class ProtectionTab extends StatefulWidget {
  const ProtectionTab({
    super.key,
    required this.protectionEnabled,
    required this.modelInstalled,
    required this.status,
    required this.onToggleProtection,
    required this.onRefresh,
  });

  final bool protectionEnabled;
  final bool modelInstalled;
  final ServiceStatus status;
  final Future<void> Function(bool value) onToggleProtection;
  final Future<void> Function() onRefresh;

  @override
  State<ProtectionTab> createState() => _ProtectionTabState();
}

class _ProtectionTabState extends State<ProtectionTab> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = widget.status;
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
                    !widget.modelInstalled
                        ? 'Download a model in the Settings tab first'
                        : widget.status.lastMessage.isEmpty
                            ? 'Reads notifications from messaging apps'
                            : widget.status.lastMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: widget.protectionEnabled,
              onChanged:
                  widget.modelInstalled ? widget.onToggleProtection : null,
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
}
