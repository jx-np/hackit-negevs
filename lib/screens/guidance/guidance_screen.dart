import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/guidance_models.dart';
import '../../services/api/guidance_service.dart';

class GuidanceScreen extends StatefulWidget {
  const GuidanceScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  late final GuidanceService _guidance = GuidanceService(widget.client);

  bool _loading = true;
  String? _error;
  List<GuidanceItem> _items = const [];
  List<HelpResource> _resources = const [];
  String? _activeScenario;

  static const List<String> _scenarioSlugs = [
    'clicked_link',
    'just_received',
    'shared_credentials',
    'sent_money',
  ];

  String _scenarioLabel(AppLocalizations l10n, String slug) {
    switch (slug) {
      case 'clicked_link':
        return l10n.guidanceClickedLink;
      case 'just_received':
        return l10n.guidanceGotMessage;
      case 'shared_credentials':
        return l10n.guidanceSharedPassword;
      case 'sent_money':
        return l10n.guidanceSentMoney;
      default:
        return slug;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _guidance.guidance(scenario: _activeScenario);
      List<HelpResource> resources = _resources;
      if (resources.isEmpty) {
        try {
          resources = await _guidance.resources(country: 'SG');
        } on ApiException {
          resources = const [];
        }
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _resources = resources;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _selectScenario(String? scenario) {
    setState(() => _activeScenario = scenario);
    _load();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.guidanceCouldNotOpenLink)),
      );
    }
  }

  Future<void> _callNumber(String raw) async {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.guidanceCouldNotCall)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guidanceTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (_loading && _items.isEmpty && _resources.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.guidanceWhatHappened,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _scenarioChips(theme),
        const SizedBox(height: 20),
        if (_error != null) _errorCard(theme),
        for (final item in _items) _guidanceCard(theme, item),
        if (_items.isEmpty && _error == null) _emptyGuidance(theme),
        if (_resources.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.guidanceWhoToContact,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final resource in _resources) _resourceCard(theme, resource),
        ],
      ],
    );
  }

  Widget _scenarioChips(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ChoiceChip(
          label: Text(l10n.guidanceShowAll),
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          selected: _activeScenario == null,
          onSelected: (_) => _selectScenario(null),
        ),
        for (final slug in _scenarioSlugs)
          ChoiceChip(
            label: Text(_scenarioLabel(l10n, slug)),
            labelStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            selected: _activeScenario == slug,
            onSelected: (_) => _selectScenario(slug),
          ),
      ],
    );
  }

  Widget _guidanceCard(ThemeData theme, GuidanceItem item) {
    final Color accent = item.isEmergency
        ? theme.colorScheme.error
        : item.isUrgent
            ? Colors.orange.shade800
            : theme.colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.isEmergency || item.isUrgent
                      ? Icons.priority_high
                      : Icons.lightbulb_outline,
                  size: 32,
                  color: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.body, style: theme.textTheme.bodyLarge),
            for (final resource in item.resources) ...[
              const SizedBox(height: 12),
              _resourceActions(theme, resource),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resourceCard(ThemeData theme, HelpResource resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if ((resource.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(resource.description!, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 12),
            _resourceActions(theme, resource),
          ],
        ),
      ),
    );
  }

  Widget _resourceActions(ThemeData theme, HelpResource resource) {
    final l10n = AppLocalizations.of(context);
    final buttons = <Widget>[];
    if (resource.hasContact) {
      buttons.add(
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: () => _callNumber(resource.contactInstructions!),
            icon: const Icon(Icons.call, size: 24),
            label: Text(
              resource.contactInstructions!,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }
    if (resource.hasUrl) {
      buttons.add(
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _openUrl(resource.url!),
            icon: const Icon(Icons.open_in_new, size: 24),
            label: Text(
              l10n.guidanceOpenWebsite,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 12, runSpacing: 12, children: buttons);
  }

  Widget _emptyGuidance(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.help_outline,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              l10n.guidanceNoAdvice,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.guidanceNoAdviceBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                size: 28, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
