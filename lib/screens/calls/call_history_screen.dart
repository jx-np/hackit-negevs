import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:call_log/call_log.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/detection_models.dart';
import '../../models/call_record.dart';
import '../../services/api/detection_service.dart';
import '../../services/call_database.dart';
import '../../services/call_event_service.dart';
import '../../services/report_service.dart';
import '../../services/role_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_screen.dart';
import '../../widgets/ui/empty_state.dart';
import 'package:scamwatch_mobile_app/screens/calls/widgets/call_record_tile.dart';
import 'package:scamwatch_mobile_app/screens/calls/widgets/calls_help.dart';
import 'package:scamwatch_mobile_app/widgets/help/screen_help.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_models.dart';
import 'blocked_numbers_screen.dart';
import 'high_risk_call_alert.dart';
import 'number_check_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with WidgetsBindingObserver {
  static const String _blockedPrefsKey = 'spam_blocked_numbers';
  static const String _protectionEnabledPrefsKey = 'spam_protection_enabled';

  /// How many of the most-recent unique numbers to auto-check for trust score.
  static const int _trustCheckLimit = 10;

  /// Only auto-check numbers seen within this window (the "last week").
  static const Duration _trustCheckWindow = Duration(days: 7);

  List<CallRecord> _records = const [];
  final Set<String> _blockedNumbers = {};
  bool _isLoading = false;
  bool _needsPhonePermission = false;
  String? _error;
  StreamSubscription<CallEvent>? _callEventSub;

  /// Number from the most recent incoming call event, used to avoid showing the
  /// high-risk full-screen alert more than once for the same ringing call.
  String? _lastAlertedNumber;

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
      // The native high-risk alert can block a number while the app was in the
      // background; pull it into the in-memory set so rows color correctly.
      _loadBlockedNumbers();
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
        // Check the live caller against the trust-score database and, if it
        // comes back high risk, raise the full-screen alert.
        unawaited(_checkIncomingCall(event.number));
      } else if (event.isIdle) {
        // The ringing call ended; allow a future call from the same number to
        // alert again.
        _lastAlertedNumber = null;
      }
      _loadHistory();
    });
  }

  /// Checks the currently-ringing caller against the trust-score database and,
  /// when it is high risk, shows the full-screen [HighRiskCallAlert]. Guards
  /// against alerting twice for the same ringing call. Errors are swallowed so
  /// a failed lookup never interrupts an incoming call.
  Future<void> _checkIncomingCall(String? number) async {
    final normalized = _canonical(number);
    if (normalized.isEmpty) return;
    if (_lastAlertedNumber == normalized) return;
    final detection = DetectionService(context.read<ApiClient>());
    PhoneTrustScore score;
    try {
      score = await detection.phoneTrustScore(number!);
    } on ApiException {
      return;
    } catch (_) {
      return;
    }
    // Persist so the matching row in the list reflects the live-call verdict.
    await CallDatabase.instance.setTrustByNumber(
      normalized,
      trustScore: score.trustScore,
      trustRating: score.rating,
    );
    if (!mounted || !score.isHighRisk) return;
    _lastAlertedNumber = normalized;
    final action = await HighRiskCallAlert.show(
      context,
      phoneNumber: number,
      trustScore: score.trustScore,
      reportCount: score.reportCount,
    );
    if (action == HighRiskCallAction.blocked && mounted) {
      await _blockAndReportNumber(number);
    }
  }

  String _canonical(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final hasUsCountryCode = digits.length == 11 && digits.startsWith('1');
    return hasUsCountryCode ? digits.substring(1) : digits;
  }

  Future<void> _loadBlockedNumbers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // The native overlay can block numbers while the UI is closed.
      await prefs.reload();
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

  Future<void> _loadHistory({bool forceRecheck = false}) async {
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

      // Check trust scores for the most recent unique numbers from the last
      // week. New numbers are always checked; previously-checked numbers are
      // skipped unless the user explicitly refreshes (forceRecheck).
      await _checkRecentTrustScores(records, forceRecheck: forceRecheck);
    } catch (e) {
      debugPrint('Failed to load call history: $e');
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).callsLoadFailedBody;
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

  /// Checks trust scores for the most recent unique numbers (up to
  /// [_trustCheckLimit]) seen within [_trustCheckWindow]. New numbers are
  /// always checked; numbers that already have a cached rating are skipped
  /// unless [forceRecheck] is set (the user pulled-to-refresh or tapped the
  /// refresh action). Each lookup is persisted so the row keeps its color
  /// across reloads without hitting the network again.
  Future<void> _checkRecentTrustScores(
    List<CallRecord> records, {
    bool forceRecheck = false,
  }) async {
    final cutoff = DateTime.now()
        .subtract(_trustCheckWindow)
        .millisecondsSinceEpoch;

    // Records come back newest-first; walk them and keep the first occurrence
    // of each unique number that falls inside the window, up to the limit.
    final seen = <String>{};
    final toCheck = <CallRecord>[];
    for (final record in records) {
      if (record.timestamp < cutoff) continue;
      if (!seen.add(record.normalizedNumber)) continue;
      // Skip numbers we already have a verdict for unless forcing a recheck.
      if (!forceRecheck && record.hasTrustCheck) continue;
      toCheck.add(record);
      if (seen.length >= _trustCheckLimit) break;
    }
    if (toCheck.isEmpty) return;

    final detection = DetectionService(context.read<ApiClient>());
    var anyChanged = false;
    for (final record in toCheck) {
      final changed = await _lookupAndPersist(detection, record);
      anyChanged = anyChanged || changed;
    }
    if (anyChanged) await _refreshFromDb();
  }

  /// Looks up a single number's trust score and persists it. Returns true when
  /// a rating was stored so the caller knows to refresh the list. Network and
  /// API errors are swallowed here so one bad lookup never breaks the loop or
  /// the whole history load.
  Future<bool> _lookupAndPersist(
    DetectionService detection,
    CallRecord record,
  ) async {
    try {
      final score = await detection.phoneTrustScore(record.rawNumber);
      await CallDatabase.instance.setTrustByNumber(
        record.normalizedNumber,
        trustScore: score.trustScore,
        trustRating: score.rating,
      );
      return true;
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Manually checks one number from the overflow menu by opening a dedicated
  /// result screen that shows the number being checked and a clear verdict.
  /// The screen performs the lookup and persists the rating like the automatic
  /// check (via [CallDatabase.setTrustByNumber]); its [onResult] callback
  /// refreshes this list so the matching row's color stays in sync.
  Future<void> _checkNumber(CallRecord record) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NumberCheckScreen(
          rawNumber: record.rawNumber,
          normalizedNumber: record.normalizedNumber,
          onResult: () {
            if (mounted) _refreshFromDb();
          },
        ),
      ),
    );
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

  /// Blocks (and reports) a number chosen from the full-screen high-risk
  /// warning, where no [CallRecord] exists yet.
  Future<void> _blockAndReportNumber(String rawNumber) async {
    final normalized = _canonical(rawNumber);
    if (normalized.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final detection = DetectionService(context.read<ApiClient>());
    setState(() => _blockedNumbers.add(normalized));
    await _saveBlockedNumbers();
    try {
      await detection.reportPhoneNumber(
        phoneNumber: rawNumber,
        reason: 'scam',
      );
    } catch (_) {
      // The local block still stands even if the report couldn't be sent.
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.callBlocked(rawNumber))),
    );
    await _refreshFromDb();
    await _ensureCallScreeningRole();
  }

  Future<void> _onMenuAction(String action, CallRecord record) async {
    switch (action) {
      case 'check':
        await _checkNumber(record);
        break;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScreen(
      title: l10n.callHistoryTitle,
      scrollable: false,
      actions: [
        IconButton(
          key: CoachMarkTargets.keyOf(context, TourTarget.callsBlockedButton),
          tooltip: l10n.callBlockedNumbers,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(LucideIcons.shieldBan),
          onPressed: _openBlockedNumbers,
        ),
        IconButton(
          tooltip: l10n.commonRefresh,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(LucideIcons.refreshCw),
          onPressed: () => _loadHistory(forceRecheck: true),
        ),
        HelpButton(
          key: CoachMarkTargets.keyOf(context, TourTarget.callsHelpButton),
          title: l10n.helpCallsTitle,
          entries: callsHelpEntries,
        ),
      ],
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_needsPhonePermission) {
      return _buildPermissionGate();
    }
    if (_error != null) {
      return _buildError();
    }
    if (_records.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          children: [
            SizedBox(height: context.tokens.space.xl4),
            EmptyState(
              icon: LucideIcons.phoneCall,
              title: l10n.callNoUnknown,
            ),
          ],
        ),
      );
    }
    return _buildList(context);
  }

  Widget _buildPermissionGate() {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Center(
      child: SingleChildScrollView(
        child: EmptyState(
          icon: LucideIcons.phoneOff,
          tint: Theme.of(context).colorScheme.error,
          title: l10n.callPhonePermNeeded,
          message: l10n.callPhonePermBody,
          action: Padding(
            padding: EdgeInsets.only(top: tokens.space.lg),
            child: FilledButton.icon(
              onPressed: _grantPhonePermission,
              icon: const Icon(LucideIcons.phone),
              label: Text(l10n.callGrantPhone),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Center(
      child: SingleChildScrollView(
        child: EmptyState(
          icon: LucideIcons.circleAlert,
          tint: Theme.of(context).colorScheme.error,
          title: l10n.callCouldNotLoad,
          message: _error,
          action: Padding(
            padding: EdgeInsets.only(top: tokens.space.lg),
            child: FilledButton(
              onPressed: _loadHistory,
              child: Text(l10n.commonRetry),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final tokens = context.tokens;
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: EdgeInsets.only(
          top: tokens.space.sm,
          bottom: tokens.space.xl2,
        ),
        itemCount: _records.length,
        separatorBuilder: (_, _) => SizedBox(height: tokens.space.md),
        itemBuilder: (context, index) {
          final record = _records[index];
          final isBlocked = _blockedNumbers.contains(record.normalizedNumber);
          return _recordCard(context, record, isBlocked);
        },
      ),
    );
  }

  Widget _recordCard(BuildContext context, CallRecord record, bool isBlocked) {
    return CallRecordTile(
      record: record,
      isBlocked: isBlocked,
      trailing: _buildMenu(record, isBlocked),
    );
  }

  Widget _buildMenu(CallRecord record, bool isBlocked) {
    final l10n = AppLocalizations.of(context);
    return FPopoverMenu.tiles(
      builder: (context, controller, _) => IconButton(
        onPressed: controller.toggle,
        tooltip: l10n.callsMoreOptions,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: const Icon(LucideIcons.ellipsis),
      ),
      menuBuilder: (context, controller, _) => [
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(LucideIcons.shieldQuestion),
              title: Text(l10n.callsCheckNumber),
              onPress: () => _runMenu(controller, 'check', record),
            ),
            if (!isBlocked)
              FTile(
                variant: FItemVariant.destructive,
                prefix: const Icon(LucideIcons.ban),
                title: Text(l10n.callsBlockNumber),
                onPress: () => _runMenu(controller, 'block', record),
              ),
            if (isBlocked)
              FTile(
                prefix: const Icon(LucideIcons.lockOpen),
                title: Text(l10n.callUnblock),
                onPress: () => _runMenu(controller, 'unblock', record),
              ),
            if (!record.reported)
              FTile(
                prefix: const Icon(LucideIcons.flag),
                title: Text(l10n.callsReportScam),
                onPress: () => _runMenu(controller, 'report', record),
              ),
            if (!isBlocked && !record.reported)
              FTile(
                variant: FItemVariant.destructive,
                prefix: const Icon(LucideIcons.octagonAlert),
                title: Text(l10n.callsBlockAndReport),
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
