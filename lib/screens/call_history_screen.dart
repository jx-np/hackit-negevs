import 'dart:async';

import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:forui/forui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/call_record.dart';
import '../services/call_database.dart';
import '../services/call_event_service.dart';
import '../services/report_service.dart';
import 'blocked_numbers_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  static const String _blockedPrefsKey = 'spam_blocked_numbers';

  List<CallRecord> _records = const [];
  final Set<String> _blockedNumbers = {};
  bool _isLoading = false;
  String? _error;
  StreamSubscription<CallEvent>? _callEventSub;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _listenToCallEvents();
  }

  @override
  void dispose() {
    _callEventSub?.cancel();
    super.dispose();
  }

  void _listenToCallEvents() {
    _callEventSub = CallEventService.events.listen((event) {
      if (event.isIncoming && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
            content: Text(
              'Incoming call: ${event.name ?? event.number ?? "Unknown"}',
            ),
          ),
        );
      }
      _loadHistory();
    });
  }

  String _canonical(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final hasUsCountryCode = digits.length == 11 && digits.startsWith('1');
    return hasUsCountryCode ? digits.substring(1) : digits;
  }

  Future<void> _loadBlockedNumbers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_blockedPrefsKey) ?? '';
      if (!mounted) return;
      setState(() {
        _blockedNumbers
          ..clear()
          ..addAll(stored.split(',').where((e) => e.isNotEmpty));
      });
    } catch (_) {}
  }

  Future<void> _saveBlockedNumbers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_blockedPrefsKey, _blockedNumbers.join(','));
    } catch (_) {}
  }

  Future<Set<String>> _loadContactNumbers() async {
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) return <String>{};
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        deduplicateProperties: true,
      );
      final numbers = <String>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = _canonical(phone.number);
          if (normalized.isNotEmpty) numbers.add(normalized);
        }
      }
      return numbers;
    } catch (_) {
      return <String>{};
    }
  }

  String _statusFromType(CallType? type) {
    switch (type) {
      case CallType.incoming:
      case CallType.outgoing:
      case CallType.answeredExternally:
      case CallType.wifiIncoming:
      case CallType.wifiOutgoing:
        return CallRecord.statusAnswered;
      case CallType.missed:
      case CallType.voiceMail:
        return CallRecord.statusMissed;
      case CallType.rejected:
        return CallRecord.statusRejected;
      case CallType.blocked:
        return CallRecord.statusBlocked;
      case CallType.unknown:
      case null:
        return CallRecord.statusUnknown;
    }
  }

  String _directionFromType(CallType? type) {
    if (type == CallType.outgoing || type == CallType.wifiOutgoing) {
      return CallRecord.directionOutgoing;
    }
    return CallRecord.directionIncoming;
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final status = await Permission.phone.status;
      if (!status.isGranted) {
        final result = await Permission.phone.request();
        if (!result.isGranted) {
          if (!mounted) return;
          setState(() {
            _error = 'Phone permission is required to view call history';
            _isLoading = false;
          });
          return;
        }
      }

      await _loadBlockedNumbers();
      final contactNumbers = await _loadContactNumbers();
      final entries = await CallLog.get();

      for (final entry in entries) {
        final raw = entry.number ?? entry.formattedNumber;
        if (raw == null || raw.trim().isEmpty) continue;
        final normalized = _canonical(raw);
        if (normalized.isEmpty || contactNumbers.contains(normalized)) continue;
        await CallDatabase.instance.insertIfAbsent(
          CallRecord(
            rawNumber: raw,
            normalizedNumber: normalized,
            timestamp: entry.timestamp ?? 0,
            status: _statusFromType(entry.callType),
            direction: _directionFromType(entry.callType),
            durationSeconds: entry.duration ?? 0,
          ),
        );
      }

      final records = await CallDatabase.instance.all();
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load call history: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFromDb() async {
    try {
      final records = await CallDatabase.instance.all();
      if (mounted) setState(() => _records = records);
    } catch (_) {}
  }

  Future<void> _block(CallRecord record) async {
    setState(() => _blockedNumbers.add(record.normalizedNumber));
    await _saveBlockedNumbers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Blocked ${record.rawNumber}')),
    );
  }

  Future<void> _unblock(CallRecord record) async {
    setState(() => _blockedNumbers.remove(record.normalizedNumber));
    await _saveBlockedNumbers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unblocked ${record.rawNumber}')),
    );
  }

  Future<void> _report(CallRecord record) async {
    await ReportService.submitReport(record, reason: 'user_reported');
    await _refreshFromDb();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reported ${record.rawNumber}')),
    );
  }

  Future<void> _withdrawReport(CallRecord record) async {
    await ReportService.withdrawReport(record);
    await _refreshFromDb();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed report for ${record.rawNumber}')),
    );
  }

  Future<void> _blockAndReport(CallRecord record) async {
    await _block(record);
    await _report(record);
  }

  Future<void> _onMenuAction(String action, CallRecord record) async {
    switch (action) {
      case 'block':
        await _block(record);
        break;
      case 'unblock':
        await _unblock(record);
        break;
      case 'report':
        await _report(record);
        break;
      case 'unreport':
        await _withdrawReport(record);
        break;
      case 'block_report':
        await _blockAndReport(record);
        break;
    }
  }

  Future<void> _openBlockedNumbers() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BlockedNumbersScreen()),
    );
    await _loadBlockedNumbers();
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp <= 0) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }

  String _statusLabel(CallRecord record) {
    if (record.direction == CallRecord.directionOutgoing) return 'Outgoing';
    switch (record.status) {
      case CallRecord.statusAnswered:
        return 'Answered';
      case CallRecord.statusRejected:
        return 'Rejected';
      case CallRecord.statusMissed:
        return 'Missed';
      case CallRecord.statusBlocked:
        return 'Blocked';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(CallRecord record) {
    if (record.direction == CallRecord.directionOutgoing) return Colors.blue;
    switch (record.status) {
      case CallRecord.statusAnswered:
        return Colors.green;
      case CallRecord.statusRejected:
        return Colors.orange;
      case CallRecord.statusMissed:
        return Colors.red;
      case CallRecord.statusBlocked:
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(CallRecord record) {
    if (record.direction == CallRecord.directionOutgoing) {
      return Icons.call_made;
    }
    switch (record.status) {
      case CallRecord.statusAnswered:
        return Icons.call_received;
      case CallRecord.statusRejected:
        return Icons.call_end;
      case CallRecord.statusMissed:
        return Icons.call_missed;
      case CallRecord.statusBlocked:
        return Icons.block;
      default:
        return Icons.call;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: const Text('Call History'),
        titleAlignment: Alignment.centerLeft,
        prefixes: [
          FHeaderAction(
            icon: const Icon(Icons.menu),
            semanticsLabel: 'Open menu',
            onPress: () => Scaffold.of(context).openDrawer(),
          ),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(Icons.block),
            semanticsLabel: 'Blocked numbers',
            onPress: _openBlockedNumbers,
          ),
          FHeaderAction(
            icon: const Icon(Icons.refresh),
            semanticsLabel: 'Refresh',
            onPress: _loadHistory,
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _records.isEmpty
          ? const Center(child: Text('No unknown-number calls found'))
          : _buildList(context),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FAlert(
              variant: FAlertVariant.destructive,
              title: const Text('Could not load call history'),
              subtitle: Text(_error!),
            ),
            const SizedBox(height: 16),
            FButton(onPress: _loadHistory, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return FTileGroup.builder(
      count: _records.length,
      tileBuilder: (context, index) {
        final record = _records[index];
        final isBlocked = _blockedNumbers.contains(record.normalizedNumber);
        return FTile(
          variant: isBlocked ? FItemVariant.destructive : FItemVariant.primary,
          prefix: FAvatar.raw(
            size: 40,
            child: Icon(
              isBlocked ? Icons.block : _statusIcon(record),
              size: 20,
              color: isBlocked
                  ? context.theme.colors.error
                  : _statusColor(record),
            ),
          ),
          title: Text(record.rawNumber),
          subtitle: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _statusLabel(record),
                  style: TextStyle(
                    color: _statusColor(record),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (record.status == CallRecord.statusAnswered &&
                    record.durationSeconds > 0)
                  TextSpan(text: ' • ${record.durationSeconds}s'),
                if (record.reported)
                  TextSpan(
                    text: ' • Reported',
                    style: TextStyle(
                      color: context.theme.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                TextSpan(text: ' • ${_formatTimestamp(record.timestamp)}'),
              ],
            ),
          ),
          suffix: _buildMenu(record, isBlocked),
        );
      },
    );
  }

  Widget _buildMenu(CallRecord record, bool isBlocked) {
    return FPopoverMenu.tiles(
      builder: (context, controller, _) => FButton.icon(
        onPress: controller.toggle,
        variant: FButtonVariant.ghost,
        size: FButtonSizeVariant.sm,
        child: context.theme.icons.ellipsis(context),
      ),
      menuBuilder: (context, controller, _) => [
        FTileGroup(
          children: [
            if (!isBlocked)
              FTile(
                variant: FItemVariant.destructive,
                prefix: const Icon(Icons.block),
                title: const Text('Block'),
                onPress: () => _runMenu(controller, 'block', record),
              ),
            if (isBlocked)
              FTile(
                prefix: const Icon(Icons.lock_open),
                title: const Text('Unblock'),
                onPress: () => _runMenu(controller, 'unblock', record),
              ),
            if (!record.reported)
              FTile(
                prefix: const Icon(Icons.flag),
                title: const Text('Report'),
                onPress: () => _runMenu(controller, 'report', record),
              ),
            if (record.reported)
              FTile(
                prefix: const Icon(Icons.flag_outlined),
                title: const Text('Remove report'),
                onPress: () => _runMenu(controller, 'unreport', record),
              ),
            if (!isBlocked && !record.reported)
              FTile(
                variant: FItemVariant.destructive,
                prefix: const Icon(Icons.report),
                title: const Text('Block & Report'),
                onPress: () => _runMenu(controller, 'block_report', record),
              ),
          ],
        ),
      ],
    );
  }

  void _runMenu(
    FPopoverController controller,
    String action,
    CallRecord record,
  ) {
    controller.hide();
    _onMenuAction(action, record);
  }
}
