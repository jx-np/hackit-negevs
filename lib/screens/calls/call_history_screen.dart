import 'dart:async';

import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:call_log/call_log.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:forui/forui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/call_record.dart';
import '../../services/api/detection_service.dart';
import '../../services/call_database.dart';
import '../../services/call_event_service.dart';
import '../../services/report_service.dart';
import '../../services/role_service.dart';
import 'blocked_numbers_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with WidgetsBindingObserver {
  static const String _blockedPrefsKey = 'spam_blocked_numbers';
  static const String _protectionEnabledPrefsKey = 'spam_protection_enabled';

  List<CallRecord> _records = const [];
  final Set<String> _blockedNumbers = {};
  bool _isLoading = false;
  bool _needsPhonePermission = false;
  String? _error;
  StreamSubscription<CallEvent>? _callEventSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
    _listenToCallEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callEventSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadHistory();
    }
  }

  void _listenToCallEvents() {
    _callEventSub = CallEventService.events.listen((event) {
      if (event.isIncoming && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
            content: Text(
              l10n.callIncoming(
                event.name ?? event.number ?? l10n.commonUnknown,
              ),
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
      await prefs.setBool(
        _protectionEnabledPrefsKey,
        _blockedNumbers.isNotEmpty,
      );
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
        if (!mounted) return;
        setState(() {
          _needsPhonePermission = true;
          _isLoading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _needsPhonePermission = false;
      });

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

  Future<void> _grantPhonePermission() async {
    final result = await Permission.phone.request();
    if (!mounted) return;
    if (result.isGranted) {
      await _loadHistory();
    } else {
      setState(() {
        _needsPhonePermission = true;
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
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.callBlocked(record.rawNumber))),
    );
    // Blocking only takes effect at the OS level when the app holds the
    // call-screening role. Without it, SpamCallScreeningService never runs and
    // the phone keeps ringing. Prompt for the role the first time it is needed.
    await _ensureCallScreeningRole();
  }

  Future<void> _ensureCallScreeningRole() async {
    if (!RoleService.isSupported) return;
    final held = await RoleService.isCallScreening();
    if (held || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final launched = await RoleService.requestCallScreening();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          launched ? l10n.permConfirmScreening : l10n.callBlockNeedsScreening,
        ),
      ),
    );
  }

  Future<void> _unblock(CallRecord record) async {
    setState(() => _blockedNumbers.remove(record.normalizedNumber));
    await _saveBlockedNumbers();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.callUnblocked(record.rawNumber))),
    );
  }

  Future<void> _report(CallRecord record) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final detection = DetectionService(context.read<ApiClient>());
    try {
      await detection.reportPhoneNumber(
        phoneNumber: record.rawNumber,
        reason: 'scam',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message.isNotEmpty ? e.message : l10n.reportNotSent)),
      );
      return;
    }
    await ReportService.submitReport(record, reason: 'user_reported');
    await _refreshFromDb();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.callReported(record.rawNumber))),
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
    if (timestamp <= 0) return AppLocalizations.of(context).commonUnknown;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }

  String _statusLabel(CallRecord record) {
    final l10n = AppLocalizations.of(context);
    if (record.direction == CallRecord.directionOutgoing) {
      return l10n.callOutgoing;
    }
    switch (record.status) {
      case CallRecord.statusAnswered:
        return l10n.callAnswered;
      case CallRecord.statusRejected:
        return l10n.callRejected;
      case CallRecord.statusMissed:
        return l10n.callMissed;
      case CallRecord.statusBlocked:
        return l10n.callBlockedLabel;
      default:
        return l10n.commonUnknown;
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
    final l10n = AppLocalizations.of(context);
    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.callHistoryTitle),
        titleAlignment: Alignment.centerLeft,
        suffixes: [
          FHeaderAction(
            icon: const Icon(Icons.block),
            semanticsLabel: l10n.callBlockedNumbers,
            onPress: _openBlockedNumbers,
          ),
          FHeaderAction(
            icon: const Icon(Icons.refresh),
            semanticsLabel: l10n.commonRefresh,
            onPress: _loadHistory,
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _needsPhonePermission
          ? _buildPermissionGate()
          : _error != null
          ? _buildError()
          : _records.isEmpty
          ? Center(child: Text(l10n.callNoUnknown))
          : _buildList(context),
    );
  }

  Widget _buildPermissionGate() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FAlert(
              variant: FAlertVariant.destructive,
              title: Text(l10n.callPhonePermNeeded),
              subtitle: Text(l10n.callPhonePermBody),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: _grantPhonePermission,
              prefix: const Icon(Icons.phone),
              child: Text(l10n.callGrantPhone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FAlert(
              variant: FAlertVariant.destructive,
              title: Text(l10n.callCouldNotLoad),
              subtitle: Text(_error!),
            ),
            const SizedBox(height: 16),
            FButton(onPress: _loadHistory, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return FTileGroup.builder(
      count: _records.length,
      tileBuilder: (context, index) {
        final l10n = AppLocalizations.of(context);
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
                  TextSpan(text: l10n.callDurationSuffix(record.durationSeconds)),
                if (record.reported)
                  TextSpan(
                    text: l10n.callReportedSuffix,
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
    final l10n = AppLocalizations.of(context);
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
                title: Text(l10n.callBlock),
                onPress: () => _runMenu(controller, 'block', record),
              ),
            if (isBlocked)
              FTile(
                prefix: const Icon(Icons.lock_open),
                title: Text(l10n.callUnblock),
                onPress: () => _runMenu(controller, 'unblock', record),
              ),
            if (!record.reported)
              FTile(
                prefix: const Icon(Icons.flag),
                title: Text(l10n.commonReport),
                onPress: () => _runMenu(controller, 'report', record),
              ),
            if (!isBlocked && !record.reported)
              FTile(
                variant: FItemVariant.destructive,
                prefix: const Icon(Icons.report),
                title: Text(l10n.callBlockAndReport),
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
