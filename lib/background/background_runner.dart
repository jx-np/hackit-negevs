import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import '../core/messaging_apps.dart';
import '../core/model_catalog.dart';
import '../core/notification_record.dart';
import '../core/scam_hints.dart';
import '../core/scam_verdict.dart';
import '../services/local_llm_evaluator.dart';
import '../services/model_manager.dart';
import '../services/model_store.dart';
import '../services/notification_log.dart';
import '../services/notification_stream.dart';
import '../services/protection_settings.dart';
import '../services/scamshield_channels.dart';

class BackgroundRunner {
  BackgroundRunner()
      : _settings = ProtectionSettings(),
        _models = GemmaModelManager(),
        _log = NotificationLog();

  final ProtectionSettings _settings;
  final GemmaModelManager _models;
  final NotificationLog _log;

  late final LocalLlmEvaluator _local =
      LocalLlmEvaluator(_models, settings: _settings);

  StreamSubscription<IncomingNotification>? _subscription;
  final Map<String, _NotificationFingerprint> _lastNotification =
      <String, _NotificationFingerprint>{};

  final List<_PendingEvaluation> _queue = [];
  bool _draining = false;
  static const int _maxQueueLength = 25;

  bool _running = false;
  bool _modelLoading = false;
  bool _modelReady = false;
  bool _modelInstalled = false;
  bool _modelError = false;

  /// True while an evaluation is in flight. Used to avoid closing the native
  /// model (model switch / unload) mid-generation, which can deadlock it.
  bool _busy = false;
  bool _pendingModelSwitch = false;

  /// Backend the currently loaded model was built with. A change here (CPU
  /// vs GPU) means the native model has to be rebuilt, so it is treated like
  /// a selection change.
  ModelBackend? _loadedBackend;
  bool _relistening = false;
  int _alertsRaised = 0;
  int _evaluated = 0;
  String _lastMessage = '';

  /// How long the on-device model may sit idle after the last notification
  /// before its weights are released to free RAM. It is loaded again on the
  /// next notification.
  static const Duration _idleUnloadDelay = Duration(seconds: 90);
  Timer? _idleTimer;

  /// The OS may kill the whole process while a message is queued or the model
  /// is loading, which loses the in-memory queue and leaves the message
  /// "not checked" forever. On every start, re-evaluate the most recent
  /// messages that were captured but never got a verdict.
  static const int _maxCatchUp = 12;
  static const Duration _catchUpWindow = Duration(hours: 24);

  Future<void> start() async {
    if (_running) return;
    ScamShieldChannels.control.setMethodCallHandler(_onControl);
    _running = true;
    await _models.ensureInitialized();
    await _applySelectedModel();
    // The model is loaded lazily on the first notification, and released again
    // once the device is idle (see [_scheduleIdleUnload]).
    if (!_running) return;
    _setStatus('Waiting for messages');
    await _listen();
    unawaited(_catchUp());
  }

  Future<void> stop() async {
    _running = false;
    _cancelIdleUnload();
    await _subscription?.cancel();
    _subscription = null;
    await _local.dispose();
    _modelReady = false;
  }

  Future<void> _applySelectedModel() async {
    // This engine has its own isolate, so the picked-model entry has to be
    // rebuilt from storage here too or modelById would fall back to the first
    // catalog entry and silently evaluate with the wrong model.
    await _settings.hydrateCustomModel();
    final spec = modelById(await _settings.selectedModelId());
    final backend = await _settings.modelBackend();
    // A context or thinking change on the same id also needs a reload: the
    // window is requested from the runtime when the weights are opened, so the
    // already-open model would keep serving the old one. A backend change
    // (CPU vs GPU) also rebuilds the native model.
    final selectionChanged = _models.spec.id != spec.id ||
        _models.spec.contextTokens != spec.contextTokens ||
        _models.spec.thinking != spec.thinking ||
        (_loadedBackend != null && _loadedBackend != backend);
    _loadedBackend = backend;
    if (selectionChanged) {
      // Selection changed: drop the old weights before switching. If an
      // evaluation is in flight, closing the native model now can deadlock it,
      // so defer the teardown until the current evaluation finishes.
      if (_busy) {
        _pendingModelSwitch = true;
      } else {
        await _local.dispose();
      }
      _modelReady = false;
    }
    _models.spec = spec;
    _modelInstalled = await _models.isInstalled();
    _modelReady = false;
    try {
      if (_models.isBundled) {
        if (!_modelInstalled) {
          _setStatus('Installing bundled model');
          await _models.ensureInstalled();
          _modelInstalled = true;
        }
      } else if (await ModelStore.exists(spec)) {
        final path = await ModelStore.pathFor(spec);
        if (path != null) {
          await _models.registerFromFile(path);
          _modelInstalled = true;
        }
      }
    } catch (error) {
      _setStatus('Model setup failed: $error');
    }
  }

  Future<void> _warmUp() async {
    if (_modelReady || _modelLoading) return;
    _modelLoading = true;
    _setStatus('Loading on-device model');
    try {
      await _local.warmUp().timeout(const Duration(seconds: 75));
      _modelReady = true;
      _modelError = false;
      _modelInstalled = true;
      _setStatus('Watching for scam messages');
    } catch (error) {
      _modelError = true;
      _setStatus('Model load failed: $error');
    } finally {
      _modelLoading = false;
    }
  }

  Future<void> _listen() async {
    if (!await NotificationListenerService.isPermissionGranted()) {
      _setStatus('Notification access not granted');
      return;
    }
    _subscription = NotificationStream.stream.listen(
      _onNotification,
      onError: (Object error) {
        _trace('stream error: $error');
        _setStatus('Listener error: $error');
        _scheduleRelisten();
      },
      onDone: () {
        _trace('stream done, re-subscribing');
        _scheduleRelisten();
      },
    );
    _trace('subscribed to notification stream');
  }

  static void _trace(String message) => debugPrint('[ScamShield] $message');

  /// Keep the CPU awake while a native generation is in flight so a screen-off
  /// device can finish the evaluation instead of suspending mid-request.
  void _wakeLock(String method) {
    ScamShieldChannels.native
        .invokeMethod<void>(method)
        .catchError((Object _) {});
  }

  /// The event channel can complete or error out (for example when the engine
  /// is torn down and rebuilt). Re-subscribe so detection recovers on its own
  /// instead of going silent until the service is manually restarted.
  void _scheduleRelisten() {
    if (!_running || _relistening) return;
    _relistening = true;
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () async {
        try {
          await _subscription?.cancel();
          _subscription = null;
          await _listen();
        } finally {
          _relistening = false;
        }
      }),
    );
  }

  /// Re-check messages that were captured but never evaluated, e.g. because
  /// the process was killed while they sat in the queue or the model was still
  /// loading. Runs once per service start; anything already checked is skipped,
  /// so this is cheap when there is nothing to do.
  Future<void> _catchUp() async {
    List<LoggedNotification> unchecked;
    try {
      unchecked = (await _log.all())
          .where((entry) => !entry.isChecked)
          .toList();
    } catch (error) {
      _trace('catch-up read failed: $error');
      return;
    }
    if (unchecked.isEmpty) return;

    final cutoff = DateTime.now().subtract(_catchUpWindow);
    final pending = unchecked
        .where((entry) => entry.capturedAt.isAfter(cutoff))
        .take(_maxCatchUp)
        .toList()
        .reversed;
    if (pending.isEmpty) return;

    _trace('catch-up: re-checking ${pending.length} message(s)');
    for (final entry in pending) {
      _enqueue(entry.id, entry.record);
    }
  }

  Future<void> _onNotification(IncomingNotification event) async {
    _trace(
      'notify pkg=${event.packageName} key="${event.key}" '
      'title="${event.title}" len=${event.content.length}',
    );
    if (!isMessagingApp(event.packageName)) {
      _trace('ignored: not a messaging app');
      return;
    }
    if (event.title.trim().isEmpty && event.content.trim().isEmpty) {
      _trace('ignored: empty title and content');
      return;
    }

    final record = NotificationRecord.fromIncoming(
      event,
      appLabelFor(event.packageName),
    );
    final id = NotificationLog.idFor(record);
    final fingerprint = _NotificationFingerprint.from(record);
    if (_lastNotification[id] == fingerprint) {
      _trace('ignored: duplicate event for $id');
      return;
    }
    _lastNotification[id] = fingerprint;
    if (_lastNotification.length > 200) {
      _lastNotification.remove(_lastNotification.keys.first);
    }

    // A failed log write must never stop the notification from being
    // evaluated, otherwise detection silently stops.
    try {
      await _log.record(id, record);
      _trace('recorded $id | ${record.title} | ${record.content}');
    } catch (error) {
      _trace('record FAILED: $error');
    }
    _enqueue(id, record);
  }

  void _enqueue(String id, NotificationRecord record) {
    // Rapid successive messages in the same conversation replace the queued
    // evaluation for that conversation: only the latest content matters, so a
    // burst cannot build a backlog that lags behind real time.
    _queue.removeWhere((pending) => pending.id == id);
    if (_queue.length >= _maxQueueLength) {
      _queue.removeAt(0);
    }
    _queue.add(_PendingEvaluation(id, record));
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        final pending = _queue.removeAt(0);
        try {
          await _evaluateRecord(pending.id, pending.record);
        } catch (_) {}
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _evaluateRecord(String id, NotificationRecord record) async {
    _busy = true;
    _wakeLock('acquireWakeLock');
    try {
      // A notification arrived: keep the model alive and load it if this is
      // the first message since it was unloaded. Scam checks run entirely
      // on-device — the message is never sent off the device.
      _cancelIdleUnload();
      if (!_modelReady) {
        await _warmUp();
      }

      ScamVerdict verdict;
      try {
        verdict = await _local.evaluate(record);
      } catch (error) {
        // A failed on-device evaluation must not escalate off-device; surface
        // it as an inconclusive verdict instead.
        verdict = ScamVerdict.unsure(reason: 'On-device check failed: $error');
      }
      _evaluated++;
      await _log.attachVerdict(id, record, verdict);

      // Gate the alert on the cheap local hints, not just the model's verdict.
      // A small model misfires on short, vague or odd-looking messages, so an
      // alert also requires high confidence and at least two corroborating
      // signals computed independently of the model.
      final hints = await ScamHintBuilder.fromRecord(record);
      if (hints.shouldAlert(verdict.label.wire, verdict.confidence)) {
        await _raiseAlert(record, verdict);
      }
    } finally {
      _busy = false;
      _wakeLock('releaseWakeLock');
      if (_pendingModelSwitch) {
        _pendingModelSwitch = false;
        unawaited(_local.dispose());
      }
      _scheduleIdleUnload();
    }
  }

  void _cancelIdleUnload() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _scheduleIdleUnload() {
    _cancelIdleUnload();
    _idleTimer = Timer(_idleUnloadDelay, () => unawaited(_unloadModel()));
  }

  Future<void> _unloadModel() async {
    _cancelIdleUnload();
    // Never close the native model while a generation is running.
    if (_busy || _modelLoading) {
      _scheduleIdleUnload();
      return;
    }
    await _local.dispose();
    if (_modelReady) {
      _modelReady = false;
      _setStatus('Model unloaded while idle');
    }
  }

  Future<void> _raiseAlert(
    NotificationRecord record,
    ScamVerdict verdict,
  ) async {
    _alertsRaised++;
    _setStatus('Alert: ${verdict.label.title}');
    try {
      await ScamShieldChannels.native.invokeMethod<void>('showAlert', {
        'appLabel': record.appLabel,
        'packageName': record.packageName,
        'sender': record.title,
        'notificationKey': record.key,
        'headline': verdict.label.title,
        'message': record.body,
        'reason': verdict.reason,
        'confidence': verdict.confidence,
        'source': verdict.source.wire,
        'escalated': verdict.escalated,
      });
    } catch (error) {
      _setStatus('Could not show alert: $error');
    }
  }

  Future<dynamic> _onControl(MethodCall call) async {
    switch (call.method) {
      case 'start':
        await start();
        return _statusMap();
      case 'shutdown':
        await stop();
        return _statusMap();
      case 'status':
        _modelInstalled = await _models.isInstalled();
        return _statusMap();
      case 'warmUp':
        _modelInstalled = await _models.isInstalled();
        await _warmUp();
        return _statusMap();
      case 'syncSettings':
        await _applySelectedModel();
        return _statusMap();
      case 'testEvaluate':
        final text = (call.arguments as Map?)?['text'] as String? ?? '';
        final record = NotificationRecord(
          packageName: 'com.whatsapp',
          appLabel: 'WhatsApp',
          title: 'Unknown sender',
          content: text,
          postedAt: DateTime.now(),
        );
        final id = 'test|${DateTime.now().microsecondsSinceEpoch}';
        await _log.record(id, record);
        _enqueue(id, record);
        return _statusMap();
      case 'runBatch':
        // Debug-only: evaluate a pushed JSON batch of notifications through the
        // on-device model and write a results file. Triggered from a computer
        // via an adb broadcast to the debug BatchRunReceiver. See [_runBatch].
        final args = (call.arguments as Map?) ?? const {};
        final inputPath = args['inputPath'] as String? ?? '';
        final outputPath = args['outputPath'] as String? ?? '';
        return _runBatch(inputPath: inputPath, outputPath: outputPath);
      default:
        return null;
    }
  }

  /// Debug-only batch runner. Reads a JSON array of notifications from
  /// [inputPath], evaluates each one through the on-device model in order, and
  /// writes a JSON results file to [outputPath]. Each result carries the input,
  /// the model verdict, the computed hints and the per-item timing.
  ///
  /// The run is serialized against live notification handling with [_busy] so a
  /// batch item never overlaps a real evaluation (the native model cannot run
  /// two generations at once). Any per-item failure is captured as an error
  /// entry rather than aborting the whole batch.
  Future<Map<String, dynamic>> _runBatch({
    required String inputPath,
    required String outputPath,
  }) async {
    if (inputPath.isEmpty || outputPath.isEmpty) {
      return {'ok': false, 'error': 'inputPath and outputPath are required'};
    }

    // ignore: avoid_print
    print('[runBatch] start input=$inputPath output=$outputPath');

    List<dynamic> items;
    try {
      final raw = await File(inputPath).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return {'ok': false, 'error': 'input must be a JSON array'};
      }
      items = decoded;
    } catch (error) {
      // ignore: avoid_print
      print('[runBatch] read failed: $error');
      return {'ok': false, 'error': 'could not read input: $error'};
    }
    // ignore: avoid_print
    print('[runBatch] parsed ${items.length} item(s)');

    // Hold off the idle-unload timer and keep the model loaded for the whole
    // batch. The run blocks the control handler, so no live notification can be
    // evaluated concurrently, but _busy is still set per item to match the
    // model-switch/unload guards.
    _cancelIdleUnload();
    if (!_modelReady) {
      await _warmUp();
    }

    final results = <Map<String, dynamic>>[];
    final batchStarted = DateTime.now();
    for (var i = 0; i < items.length; i++) {
      final entry = <String, dynamic>{'index': i};
      final item = items[i];
      if (item is! Map) {
        entry['error'] = 'item is not a JSON object';
        results.add(entry);
        continue;
      }

      NotificationRecord record;
      try {
        record = NotificationRecord.fromJson(Map<String, dynamic>.from(item));
      } catch (error) {
        entry['error'] = 'could not parse notification: $error';
        results.add(entry);
        continue;
      }

      entry['input'] = record.toJson();
      _setStatus('Batch ${i + 1}/${items.length}');

      _busy = true;
      final started = DateTime.now();
      try {
        final hints = await ScamHintBuilder.fromRecord(record);
        final verdict = await _local.evaluate(record);
        final elapsedMs = DateTime.now().difference(started).inMilliseconds;
        entry['verdict'] = verdict.toJson();
        entry['hints'] = _hintsToJson(hints);
        entry['timing_ms'] = elapsedMs;
      } catch (error) {
        entry['error'] = 'evaluation failed: $error';
        entry['timing_ms'] = DateTime.now().difference(started).inMilliseconds;
      } finally {
        _busy = false;
      }
      results.add(entry);
    }

    final output = <String, dynamic>{
      'model_id': _models.spec.id,
      'count': results.length,
      'started_at': batchStarted.toIso8601String(),
      'finished_at': DateTime.now().toIso8601String(),
      'total_ms': DateTime.now().difference(batchStarted).inMilliseconds,
      'results': results,
    };

    try {
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(output),
      );
    } catch (error) {
      // ignore: avoid_print
      print('[runBatch] write failed: $error');
      _scheduleIdleUnload();
      return {'ok': false, 'error': 'could not write output: $error'};
    }

    // ignore: avoid_print
    print('[runBatch] done: ${results.length} result(s) -> $outputPath');
    _setStatus('Batch done: ${results.length} message(s)');
    _scheduleIdleUnload();
    return {'ok': true, 'count': results.length, 'outputPath': outputPath};
  }

  /// Serializes the full set of computed hints for a batch result, so a run can
  /// be inspected signal-by-signal rather than only through the rendered line.
  Map<String, dynamic> _hintsToJson(ScamHints hints) => {
        'rendered': hints.render(),
        'sender_type': hints.senderType.wire,
        'link_type': hints.linkType.wire,
        'asks_for_code': hints.asksForCode,
        'delivers_code': hints.deliversCode,
        'apk_or_remote_app': hints.apkOrRemoteApp,
        'urgency': hints.urgency,
        'money_ask': hints.moneyAsk,
        'moves_off_platform': hints.movesOffPlatform,
        'brand_mentioned': hints.brandMentioned,
        'strong_signal_count': hints.strongSignalCount,
      };

  void _setStatus(String message) {
    _lastMessage = message;
    ScamShieldChannels.native
        .invokeMethod<void>('updateStatus', {'message': message})
        .catchError((Object _) {});
  }

  Map<String, dynamic> _statusMap() => {
        'running': _running,
        'modelId': _models.spec.id,
        'modelInstalled': _modelInstalled,
        'modelLoading': _modelLoading,
        'modelReady': _modelReady,
        'modelError': _modelError,
        'processing': _busy,
        'downloadProgress': -1,
        'alertsRaised': _alertsRaised,
        'evaluated': _evaluated,
        'lastMessage': _lastMessage,
      };
}

/// One queued evaluation, keyed by notification id so a newer message in the
/// same conversation can replace an older pending one.
class _PendingEvaluation {
  _PendingEvaluation(this.id, this.record);

  final String id;
  final NotificationRecord record;
}

class _NotificationFingerprint {
  const _NotificationFingerprint(this.content, this.postedAt);

  factory _NotificationFingerprint.from(NotificationRecord record) =>
      _NotificationFingerprint(record.content, record.postedAt);

  final String content;
  final DateTime postedAt;

  @override
  bool operator ==(Object other) =>
      other is _NotificationFingerprint &&
      other.content == content &&
      other.postedAt == postedAt;

  @override
  int get hashCode => Object.hash(content, postedAt);
}
