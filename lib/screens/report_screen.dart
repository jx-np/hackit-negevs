import 'package:flutter/material.dart';

import '../core/contact_directory.dart';
import '../main.dart' show ReportDeepLinkPayload;
import '../models/call_record.dart';
import '../models/report_payload.dart';
import '../services/call_database.dart';
import '../services/notification_log.dart';
import '../services/report_service.dart';
import '../services/scamshield_channels.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.initialLink});

  static const int queueLimit = 5;
  static const int recentLimit = 2;

  final ReportDeepLinkPayload? initialLink;

  @override
  State<ReportScreen> createState() => ReportScreenState();
}

class ReportScreenState extends State<ReportScreen> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _applicationController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  String _category = ReportPayload.categorySpam;
  bool _loading = true;
  bool _sending = false;
  List<CallRecord> _recentCalls = const [];
  List<LoggedNotification> _queue = const [];

  String _linkSender = '';
  String _linkNotificationKey = '';

  @override
  void initState() {
    super.initState();
    _load();
    final link = widget.initialLink;
    if (link != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => prefillFromLink(link));
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _applicationController.dispose();
    _reasonController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    List<CallRecord> recent = const [];
    List<LoggedNotification> queue = const [];
    try {
      final records = await CallDatabase.instance.all();
      recent = records.take(ReportScreen.recentLimit).toList();
    } catch (_) {}
    try {
      final entries = await NotificationLog().all();
      queue = entries
          .where((e) => e.verdict?.shouldAlert ?? false)
          .take(ReportScreen.queueLimit)
          .toList();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _recentCalls = recent;
      _queue = queue;
      _loading = false;
    });
  }

  Future<String?> _resolveNumber(String sender) async {
    final trimmed = sender.trim();
    if (trimmed.isEmpty) return null;
    if (ContactDirectory.looksLikePhone(trimmed)) return trimmed;
    return ContactDirectory.phoneForName(trimmed);
  }

  Future<void> prefillFromLink(ReportDeepLinkPayload payload) async {
    _linkSender = payload.subject;
    _linkNotificationKey = payload.notificationKey;
    _reasonController.text = payload.content;

    if (payload.source == 'call') {
      _numberController.text = payload.subject;
      _applicationController.text = 'Phone';
    } else {
      _applicationController.text =
          payload.app.trim().isEmpty ? 'Unknown app' : payload.app.trim();
      final number = await _resolveNumber(payload.subject);
      if (number != null) _numberController.text = number;
    }
    if (!mounted) return;
    setState(() {});
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _CategoryDialog(
        source: payload.source,
        subject: payload.subject,
        content: payload.content,
        onDone: (category, reason) {
          setState(() {
            _category = category;
            if (reason.trim().isNotEmpty) {
              _reasonController.text = reason.trim();
            }
          });
        },
      ),
    );
  }

  Future<void> _send(ReportPayload payload) async {
    setState(() => _sending = true);
    final ok = await ReportService.submitPayload(payload);
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Report sent'
              : 'Report not sent — reporting endpoint is not configured yet',
        ),
      ),
    );
  }

  /// A reported message must leave the queue and its alert must go away, so the
  /// user is not asked about the same notification twice.
  Future<void> _dismissReported(String logId) async {
    try {
      await NotificationLog().remove(logId);
    } catch (_) {}
    try {
      await ScamShieldController.dismissScamAlert();
    } catch (_) {}
    if (_linkNotificationKey.isNotEmpty) _linkNotificationKey = '';
    await _load();
  }

  Future<void> _reportNotification(LoggedNotification entry) async {
    final verdict = entry.verdict;
    final record = entry.record;
    final sender = record.title.trim();
    final application =
        record.appLabel.trim().isEmpty ? record.packageName : record.appLabel.trim();
    final number = await _resolveNumber(sender);
    await _send(
      ReportPayload(
        kind: ReportPayload.kindNotification,
        application: application,
        number: number,
        sender: sender.isEmpty ? null : sender,
        packageName: record.packageName,
        notificationKey: record.key,
        content: record.content,
        reason: verdict?.reason,
        verdict: verdict?.label.wire,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    await _dismissReported(entry.id);
  }

  Future<void> _submitForm() async {
    final number = _numberController.text.trim();
    final application = _applicationController.text.trim();
    if (application.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an application first.')),
      );
      return;
    }
    final reason = _reasonController.text.trim();
    final isCall = number.isNotEmpty &&
        _recentCalls.any((r) => r.rawNumber == number);
    await _send(
      ReportPayload(
        kind: isCall ? ReportPayload.kindCall : ReportPayload.kindNotification,
        application: application,
        number: number.isEmpty ? null : number,
        content: reason,
        category: _category,
        reason: _commentsController.text.trim(),
        sender: _linkSender.isEmpty ? null : _linkSender,
        notificationKey:
            _linkNotificationKey.isEmpty ? null : _linkNotificationKey,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    if (_linkNotificationKey.isNotEmpty) {
      await _dismissReported(_linkNotificationKey);
    }
  }

  Future<void> _confirmReport(LoggedNotification entry) async {
    final theme = Theme.of(context);
    final content = entry.record.content.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.gpp_bad, size: 40, color: theme.colorScheme.error),
        title: Text(
          'Report this message as a scam?',
          style: theme.textTheme.titleLarge,
        ),
        content: content.isEmpty
            ? null
            : Text(
                content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            height: 56,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel', style: theme.textTheme.titleMedium),
            ),
          ),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Report', style: theme.textTheme.titleMedium),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _reportNotification(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Suspicious messages',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap “Report this” on anything that looks like a scam.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  if (_queue.isEmpty)
                    _emptyCard(
                      Icons.verified_user_outlined,
                      'Nothing suspicious right now',
                    )
                  else
                    for (final entry in _queue) ...[
                      _queueCard(theme, entry),
                      const SizedBox(height: 16),
                    ],
                  const SizedBox(height: 12),
                  _recentCard(theme),
                  const SizedBox(height: 24),
                  _composeCard(theme),
                ],
              ),
      ),
    );
  }

  Widget _queueCard(ThemeData theme, LoggedNotification entry) {
    final verdict = entry.verdict;
    final title = entry.record.title.isEmpty
        ? entry.record.appLabel
        : entry.record.title;
    final appLabel = entry.record.appLabel.trim();
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.gpp_bad,
                  size: 36,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      if (appLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          appLabel,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (verdict != null) ...[
              const SizedBox(height: 12),
              Text(
                '${verdict.label.title} · ${(verdict.confidence * 100).round()}% sure',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (entry.record.content.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entry.record.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: _sending ? null : () => _confirmReport(entry),
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag, size: 24),
                label: Text(
                  'Report this',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onError,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent calls',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (_recentCalls.isEmpty)
              Text('No calls recorded yet', style: theme.textTheme.bodyLarge)
            else
              for (var i = 0; i < _recentCalls.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _recentCalls[i].rawNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: () {
                          _numberController.text = _recentCalls[i].rawNumber;
                          _applicationController.text = 'Phone';
                          setState(() => _category = ReportPayload.categorySpam);
                        },
                        child: Text(
                          'Report',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _composeCard(ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Icon(
          Icons.edit_outlined,
          size: 28,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          'Report something else',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Write your own report',
          style: theme.textTheme.bodyLarge,
        ),
        children: [
          TextField(
            controller: _numberController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: theme.textTheme.titleMedium,
            decoration: const InputDecoration(
              labelText: 'Number (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _applicationController,
            textInputAction: TextInputAction.next,
            style: theme.textTheme.titleMedium,
            decoration: const InputDecoration(
              labelText: 'Application (required)',
              hintText: 'WhatsApp, Telegram, Phone…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            style: theme.textTheme.titleMedium,
            decoration: const InputDecoration(
              labelText: 'Mark as',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: ReportPayload.categorySpam,
                child: Text('Spam'),
              ),
              DropdownMenuItem(
                value: ReportPayload.categoryScam,
                child: Text('Scam'),
              ),
              DropdownMenuItem(
                value: ReportPayload.categoryOther,
                child: Text('Other'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: theme.textTheme.titleMedium,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'What did they do or say?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentsController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: theme.textTheme.titleMedium,
            decoration: const InputDecoration(
              labelText: 'Other comments',
              hintText: 'Anything else we should know (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton.icon(
              onPressed: _sending ? null : _submitForm,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined, size: 24),
              label: Text(
                'Submit report',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(IconData icon, String message) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({
    required this.source,
    required this.subject,
    required this.content,
    required this.onDone,
  });

  final String source;
  final String subject;
  final String content;
  final void Function(String category, String reason) onDone;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late String _category = ReportPayload.categorySpam;
  final TextEditingController _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason.text = widget.content;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.source == 'call'
            ? 'Report ${widget.subject}?'
            : 'Report this message as a scam?',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Mark as'),
            items: const [
              DropdownMenuItem(
                value: ReportPayload.categorySpam,
                child: Text('Spam'),
              ),
              DropdownMenuItem(
                value: ReportPayload.categoryScam,
                child: Text('Scam'),
              ),
              DropdownMenuItem(
                value: ReportPayload.categoryOther,
                child: Text('Other'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onDone(_category, _reason.text);
            Navigator.of(context).pop();
          },
          child: const Text('Report'),
        ),
      ],
    );
  }
}
