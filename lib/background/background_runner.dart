import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import '../core/messaging_apps.dart';
import '../core/model_catalog.dart';
import '../core/notification_record.dart';
import '../core/scam_verdict.dart';
import '../services/evaluation_router.dart';
import '../services/local_llm_evaluator.dart';
import '../services/model_manager.dart';
import '../services/model_store.dart';
import '../services/notification_log.dart';
import '../services/notification_stream.dart';
import '../services/protection_settings.dart';
import '../services/remote_api_evaluator.dart';
import '../services/scamshield_channels.dart';

class BackgroundRunner {
  BackgroundRunner()
      : _settings = ProtectionSettings(),
        _models = GemmaModelManager(),
        _log = NotificationLog();

  final ProtectionSettings _settings;
  final GemmaModelManager _models;
  final NotificationLog _log;

  late final LocalLlmEvaluator _local = LocalLlmEvaluator(_models);
  EvaluationRouter? _router;
  bool _forceCloud = false;

  StreamSubscription<IncomingNotification>? _subscription;
  final Map<String, String> _lastContent = <String, String>{};

  final List<_PendingEvaluation> _queue = [];
  bool _draining = false;
  static const int _maxQueueLength = 25;

  bool _running = false;
  bool _modelLoading = false;
  bool _modelReady = false;
  bool _modelInstalled = false;

  /// True while an evaluation is in flight. Used to avoid closing the native
  /// model (model switch / unload) mid-generation, which can deadlock it.
  bool _busy = false;
  bool _pendingModelSwitch = false;
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
    await _refreshRouter();
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
    // A context or thinking change on the same id also needs a reload: the
    // window is requested from the runtime when the weights are opened, so the
    // already-open model would keep serving the old one.
    final selectionChanged = _models.spec.id != spec.id ||
        _models.spec.contextTokens != spec.contextTokens ||
        _models.spec.thinking != spec.thinking;
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
      _modelInstalled = true;
      _setStatus('Watching for scam messages');
    } catch (error) {
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
    if (_lastContent[id] == record.content) {
      _trace('ignored: duplicate content for $id');
      return;
    }
    _lastContent[id] = record.content;
    if (_lastContent.length > 200) {
      _lastContent.remove(_lastContent.keys.first);
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
    final router = _router;
    if (router == null) return;

    _busy = true;
    _wakeLock('acquireWakeLock');
    try {
      // A notification arrived: keep the model alive and load it if this is
      // the first message since it was unloaded. In force-cloud mode the
      // on-device model is not needed unless the cloud fails (handled by the
      // router).
      _cancelIdleUnload();
      if (!_forceCloud && !_modelReady) {
        await _warmUp();
      }

      final verdict = await router.evaluate(record);
      _evaluated++;
      await _log.attachVerdict(id, record, verdict);

      if (verdict.shouldAlert) {
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
        await _refreshRouter();
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
      default:
        return null;
    }
  }

  Future<void> _refreshRouter() async {
    final endpoint = (await _settings.remoteEndpoint()).trim();
    final apiKey = (await _settings.remoteApiKey()).trim();
    final model = (await _settings.remoteModel()).trim();
    _forceCloud = await _settings.forceCloud();
    _router = EvaluationRouter(
      local: _local,
      remote: RemoteApiEvaluator(
        endpoint: endpoint.isEmpty ? null : endpoint,
        apiKey: apiKey.isEmpty ? null : apiKey,
        model: model.isEmpty ? kDefaultRemoteModel : model,
        reasoningBudget: await _settings.reasoningBudget(),
        maxTokensOverride: await _settings.remoteMaxTokens(),
      ),
      confidenceThreshold: await _settings.confidenceThreshold(),
      forceCloud: _forceCloud,
    );
  }

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
