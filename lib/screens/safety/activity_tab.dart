import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';

import '../../core/scam_verdict.dart';
import '../../services/notification_log.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/empty_state.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({
    super.key,
    required this.entries,
    required this.onClear,
    required this.onRefresh,
  });

  final List<LoggedNotification> entries;
  final Future<void> Function() onClear;
  final Future<void> Function() onRefresh;

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

enum _Filter { all, scams, unchecked }

class _ActivityTabState extends State<ActivityTab> {
  _Filter _filter = _Filter.all;

  List<LoggedNotification> get _visible {
    switch (_filter) {
      case _Filter.all:
        return widget.entries;
      case _Filter.scams:
        return widget.entries
            .where((e) => e.verdict?.shouldAlert ?? false)
            .toList();
      case _Filter.unchecked:
        return widget.entries.where((e) => !e.isChecked).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = _visible;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.activityAll(widget.entries.length)),
                      selected: _filter == _Filter.all,
                      onSelected: (_) => setState(() => _filter = _Filter.all),
                    ),
                    ChoiceChip(
                      label: Text(
                        l10n.activityScams(widget.entries
                            .where((e) => e.verdict?.shouldAlert ?? false)
                            .length),
                      ),
                      selected: _filter == _Filter.scams,
                      onSelected: (_) => setState(() => _filter = _Filter.scams),
                    ),
                    ChoiceChip(
                      label: Text(
                        l10n.activityUnchecked(widget.entries
                            .where((e) => !e.isChecked)
                            .length),
                      ),
                      selected: _filter == _Filter.unchecked,
                      onSelected: (_) =>
                          setState(() => _filter = _Filter.unchecked),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.commonClear,
                onPressed: widget.entries.isEmpty ? null : widget.onClear,
                 icon: const Icon(LucideIcons.trash2),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: entries.isEmpty
                 ? ListView(
                     children: [
                       SizedBox(height: context.tokens.space.xl3),
                       EmptyState(
                         icon: LucideIcons.inbox,
                         title: l10n.activityNoMessages,
                       ),
                     ],
                   )
                 : ListView.separated(
                     padding: EdgeInsets.fromLTRB(
                       context.tokens.space.lg,
                       context.tokens.space.sm,
                       context.tokens.space.lg,
                       context.tokens.space.xl2,
                     ),
                     itemCount: entries.length,
                     separatorBuilder: (_, _) =>
                         SizedBox(height: context.tokens.space.md),
                    itemBuilder: (context, index) =>
                        _ActivityTile(entry: entries[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatefulWidget {
  const _ActivityTile({required this.entry});

  final LoggedNotification entry;

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    final verdict = entry.verdict;
    final scam = verdict?.shouldAlert ?? false;
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final icon = !entry.isChecked
        ? LucideIcons.clock
        : scam
            ? LucideIcons.shieldAlert
            : LucideIcons.shieldCheck;
    final color = !entry.isChecked
        ? scheme.onSurfaceVariant
        : scam
            ? tokens.risk.danger
            : tokens.risk.safe;
    final iconBackground = !entry.isChecked
        ? scheme.surfaceContainerHighest
        : scam
            ? tokens.risk.dangerContainer
            : tokens.risk.safeContainer;
    final meta = StringBuffer()
      ..write('${entry.record.appLabel} · ${_time(entry.capturedAt)}');
    if (verdict == null) {
      meta.write(l10n.activityNotCheckedSuffix);
    } else {
      meta.write(' · ${verdict.label.title}');
      if (verdict.escalated) meta.write(l10n.activityCloudSuffix);
      meta.write(' · ${(verdict.confidence * 100).round()}%');
    }
    return AppCard(
      padding: EdgeInsets.all(tokens.space.lg),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: tokens.space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.record.title.isEmpty
                          ? entry.record.appLabel
                          : entry.record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (entry.record.content.isNotEmpty) ...[
                      SizedBox(height: tokens.space.xs),
                      Text(
                        entry.record.content,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    SizedBox(height: tokens.space.xs),
                    Text(
                      meta.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _expanded ? l10n.safetyShowLess : l10n.safetyShowMore,
                icon: Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
          if (_expanded) _details(context, verdict),
        ],
      ),
    );
  }

  Widget _details(BuildContext context, ScamVerdict? verdict) {
    final l10n = AppLocalizations.of(context);
    if (verdict == null) {
      return Padding(
        padding: EdgeInsets.only(top: context.tokens.space.lg),
        child: Text(
          l10n.activityNotCheckedYet,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: context.tokens.space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(context, l10n.activityVerdict, verdict.label.title),
          _row(
            context,
            l10n.activityConfidence,
            '${(verdict.confidence * 100).round()}%',
          ),
          _row(
            context,
            l10n.activityCheckedBy,
            verdict.escalated
                ? l10n.activityEscalatedSuffix(verdict.source.wire)
                : verdict.source.wire,
          ),
          _row(context, l10n.activityReason, verdict.reason),
          SizedBox(height: context.tokens.space.md),
          Text(l10n.activityAiThinking, style: theme.textTheme.labelLarge),
          SizedBox(height: context.tokens.space.xs),
          Container(
            width: double.infinity,
             padding: EdgeInsets.all(context.tokens.space.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
               borderRadius: context.tokens.radii.smRadius,
            ),
            child: SelectableText(
              verdict.raw.trim().isEmpty
                  ? l10n.activityNoOutput
                  : verdict.raw.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: context.tokens.space.xs),
      child: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
