import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';

import '../../services/notification_log.dart';
import '../../services/scamshield_channels.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_screen.dart';
import 'activity_tab.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationLog _log = NotificationLog();
  final TextEditingController _testController = TextEditingController();

  Timer? _poll;
  List<LoggedNotification> _entries = const [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _testController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await _log.all();
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  Future<void> _clear() async {
    await _log.clear();
    await _load();
  }

  /// Sends the typed message through the same evaluation pipeline a real
  /// notification uses. The background engine logs it as a `test|…` entry and
  /// attaches the model's verdict asynchronously; the 2-second poll above then
  /// surfaces it in the activity list below. The model only runs while the
  /// protection service is up, so a stopped service is surfaced instead of
  /// silently producing nothing.
  Future<void> _runTest() async {
    final l10n = AppLocalizations.of(context);
    final text = _testController.text.trim();
    if (text.isEmpty || _sending) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final running = await ScamShieldController.isServiceRunning();
      if (!mounted) return;
      if (!running) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationsTestServiceOff)),
        );
        return;
      }
      await ScamShieldController.testEvaluate(text);
      if (!mounted) return;
      _testController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationsTestSent)),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScreen(
      title: l10n.notificationsTitle,
      scrollable: false,
      padBody: false,
      body: Column(
        children: [
          _TestEvaluateCard(
            controller: _testController,
            sending: _sending,
            onRun: _runTest,
          ),
          Expanded(
            child: ActivityTab(
              entries: _entries,
              onClear: _clear,
              onRefresh: _load,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact input card that lets the user feed an arbitrary message to the
/// on-device model and watch the verdict land in the activity list below.
class _TestEvaluateCard extends StatelessWidget {
  const _TestEvaluateCard({
    required this.controller,
    required this.sending,
    required this.onRun,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space.lg,
        tokens.space.md,
        tokens.space.lg,
        0,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(tokens.space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.notificationsTestTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.space.md),
              TextField(
                controller: controller,
                enabled: !sending,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.notificationsTestHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: tokens.space.md),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: sending ? null : onRun,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Icon(Icons.science_outlined),
                  label: Text(
                    l10n.notificationsTestRun,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
