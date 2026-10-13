import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';

import '../../core/scam_verdict.dart';
import '../../services/notification_log.dart';

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
                icon: const Icon(Icons.delete_outline),
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
                      const SizedBox(height: 120),
                      Center(child: Text(l10n.activityNoMessages)),
                    ],
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
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
    final icon = !entry.isChecked
        ? Icons.hourglass_empty
        : scam
            ? Icons.gpp_bad
            : Icons.gpp_good;
    final color = !entry.isChecked
        ? Colors.grey
        : scam
            ? Colors.red
            : Colors.green;
    final meta = StringBuffer()
      ..write('${entry.record.appLabel} · ${_time(entry.capturedAt)}');
    if (verdict == null) {
      meta.write(l10n.activityNotCheckedSuffix);
    } else {
      meta.write(' · ${verdict.label.title}');
      if (verdict.escalated) meta.write(l10n.activityCloudSuffix);
      meta.write(' · ${(verdict.confidence * 100).round()}%');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            entry.record.title.isEmpty
                ? entry.record.appLabel
                : entry.record.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.record.content.isNotEmpty)
                Text(
                  entry.record.content,
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Text(meta.toString(), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded) _details(context, verdict),
      ],
    );
  }

  Widget _details(BuildContext context, ScamVerdict? verdict) {
    final l10n = AppLocalizations.of(context);
    if (verdict == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
        child: Text(
          l10n.activityNotCheckedYet,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(theme, l10n.activityVerdict, verdict.label.title),
          _row(
            theme,
            l10n.activityConfidence,
            '${(verdict.confidence * 100).round()}%',
          ),
          _row(
            theme,
            l10n.activityCheckedBy,
            verdict.escalated
                ? l10n.activityEscalatedSuffix(verdict.source.wire)
                : verdict.source.wire,
          ),
          _row(theme, l10n.activityReason, verdict.reason),
          const SizedBox(height: 8),
          Text(l10n.activityAiThinking, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              verdict.raw.trim().isEmpty
                  ? l10n.activityNoOutput
                  : verdict.raw.trim(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
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
