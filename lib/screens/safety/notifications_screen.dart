import 'dart:async';

import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';

import '../../services/notification_log.dart';
import 'activity_tab.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationLog _log = NotificationLog();

  Timer? _poll;
  List<LoggedNotification> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: ActivityTab(
        entries: _entries,
        onClear: _clear,
        onRefresh: _load,
      ),
    );
  }
}
