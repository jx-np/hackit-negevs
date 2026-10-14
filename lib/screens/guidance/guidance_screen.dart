import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/guidance_models.dart';
import '../../services/api/guidance_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_screen.dart';
import '../../widgets/ui/empty_state.dart';

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
    return AppScreen(
      title: l10n.guidanceTitle,
      scrollable: false,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    if (_loading && _items.isEmpty && _resources.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: EdgeInsets.only(
        top: tokens.space.sm,
        bottom: tokens.space.xl2,
      ),
      children: [
        Text(
          l10n.guidanceWhatHappened,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: tokens.space.md),
        _scenarioChips(theme),
        SizedBox(height: tokens.space.xl),
        if (_error != null) ...[
          _errorCard(theme),
          SizedBox(height: tokens.space.md),
        ],
        for (final item in _items) ...[
          _guidanceCard(theme, item),
          SizedBox(height: tokens.space.md),
        ],
        if (_items.isEmpty && _error == null) _emptyGuidance(theme),
        if (_resources.isNotEmpty) ...[
          SizedBox(height: tokens.space.md),
          Text(
            l10n.guidanceWhoToContact,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: tokens.space.md),
          for (final resource in _resources) ...[
            _resourceCard(theme, resource),
            SizedBox(height: tokens.space.md),
          ],
        ],
      ],
    );
  }

  Widget _scenarioChips(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Wrap(
      spacing: tokens.space.sm,
      runSpacing: tokens.space.sm,
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
    final tokens = context.tokens;
    final Color accent = item.isEmergency
        ? tokens.risk.danger
        : item.isUrgent
            ? tokens.risk.warning
            : theme.colorScheme.primary;
    return AppCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    item.isEmergency || item.isUrgent
                       ? LucideIcons.triangleAlert
                       : LucideIcons.lightbulb,
                   size: 32,
                   color: accent,
                 ),
                 SizedBox(width: tokens.space.md),
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
             SizedBox(height: tokens.space.md),
             Text(item.body, style: theme.textTheme.bodyLarge),
             for (final resource in item.resources) ...[
               SizedBox(height: tokens.space.md),
               _resourceActions(theme, resource),
             ],
           ],
      ),
    );
  }

  Widget _resourceCard(ThemeData theme, HelpResource resource) {
    final tokens = context.tokens;
    return AppCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if ((resource.description ?? '').isNotEmpty) ...[
              SizedBox(height: tokens.space.sm),
              Text(resource.description!, style: theme.textTheme.bodyLarge),
            ],
            SizedBox(height: tokens.space.md),
            _resourceActions(theme, resource),
          ],
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
            icon: const Icon(LucideIcons.phone, size: 24),
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
            icon: const Icon(LucideIcons.externalLink, size: 24),
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
    return AppCard(
      child: EmptyState(
        icon: LucideIcons.circleHelp,
        title: l10n.guidanceNoAdvice,
        message: l10n.guidanceNoAdviceBody,
      ),
    );
  }

  Widget _errorCard(ThemeData theme) {
    final tokens = context.tokens;
    return AppCard(
      color: tokens.risk.dangerContainer,
      child: Row(
          children: [
            Icon(LucideIcons.circleAlert, size: 28, color: tokens.risk.danger),
            SizedBox(width: tokens.space.md),
            Expanded(
              child: Text(
                _error!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.risk.onDangerContainer,
                ),
              ),
            ),
          ],
      ),
    );
  }
}
