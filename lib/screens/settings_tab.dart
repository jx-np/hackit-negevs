import 'package:flutter/material.dart';

import '../core/model_catalog.dart';
import '../services/model_controller.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    required this.model,
    required this.hfToken,
    required this.threshold,
    required this.endpoint,
    required this.serviceRunning,
    required this.onSelectModel,
    required this.onHfToken,
    required this.onThreshold,
    required this.onEndpoint,
    required this.onStopService,
    required this.onClearLog,
  });

  final ModelController model;
  final String hfToken;
  final double threshold;
  final String endpoint;
  final bool serviceRunning;
  final Future<void> Function(ScamModelSpec spec) onSelectModel;
  final Future<void> Function(String value) onHfToken;
  final Future<void> Function(double value) onThreshold;
  final Future<void> Function(String value) onEndpoint;
  final Future<void> Function() onStopService;
  final Future<void> Function() onClearLog;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _tokenController =
      TextEditingController(text: widget.hfToken);
  late final TextEditingController _endpointController =
      TextEditingController(text: widget.endpoint);
  late double _threshold = widget.threshold;

  @override
  void dispose() {
    _tokenController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Detection model', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final spec in modelCatalog) _modelTile(spec),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.model.spec.note,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text('HuggingFace token', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _tokenController,
          obscureText: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'hf_... (only for gated models)',
          ),
          onSubmitted: widget.onHfToken,
          onEditingComplete: () => widget.onHfToken(_tokenController.text.trim()),
        ),
        const SizedBox(height: 20),
        Text(
          'Cloud escalation threshold — escalate below ${(_threshold * 100).round()}%',
          style: Theme.of(context).textTheme.titleMedium,
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
        Text('Cloud review endpoint', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _endpointController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'https://... (empty = disabled)',
          ),
          onSubmitted: widget.onEndpoint,
          onEditingComplete: () =>
              widget.onEndpoint(_endpointController.text.trim()),
        ),
        const SizedBox(height: 24),
        Text('Danger zone', style: Theme.of(context).textTheme.titleMedium),
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
      ],
    );
  }

  Widget _modelTile(ScamModelSpec spec) {
    final selected = spec.id == widget.model.spec.id;
    return ListTile(
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
      title: Text(spec.displayName),
      subtitle: Text(
        spec.assetPath != null
            ? '~${spec.approxSizeMb} MB · bundled'
            : '~${spec.approxSizeMb} MB · download',
      ),
      trailing: spec.requiresToken
          ? const Icon(Icons.lock_outline, size: 18)
          : null,
      onTap: () => widget.onSelectModel(spec),
    );
  }
}
