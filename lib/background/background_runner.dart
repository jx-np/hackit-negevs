import 'dart:async';

import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_event.dart';
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

  StreamSubscription<ServiceNotificationEvent>? _subscription;
  final Set<String> _seen = <String>{};

  final List<Future<void> Function()> _queue = [];
  bool _draining = false;
  static const int _maxQueueLength = 25;

  bool _running = false;
  bool _modelLoading = false;
  bool _modelReady = false;
  bool _modelInstalled = false;
  int _alertsRaised = 0;
  int _evaluated = 0;
  String _lastMessage = '';

  Future<void> start() async {
    ScamShieldChannels.control.setMethodCallHandler(_onControl);
    _running = true;
    await _models.ensureInitialized();
    await _applySelectedModel();
    await _refreshRouter();
    _setStatus('Waiting for messages');
    unawaited(_warmUpIfInstalled());
    await _listen();
  }

  Future<void> stop() async {
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _applySelectedModel() async {
    final spec = modelById(await _settings.selectedModelId());
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

  Future<void> _warmUpIfInstalled() async {
    if (await _models.isInstalled()) {
      _modelInstalled = true;
      await _warmUp();
    }
  }

  Future<void> _warmUp() async {
    if (_modelReady || _modelLoading) return;
    _modelLoading = true;
    _setStatus('Loading on-device model');
    try {
      await _local.warmUp();
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
    _subscription = NotificationListenerService.notificationsStream.listen(
      _onNotification,
      onError: (Object error) => _setStatus('Listener error: $error'),
    );
  }

  Future<void> _onNotification(ServiceNotificationEvent event) async {
    if (event.hasRemoved || event.onGoing) return;
    if (!isMessagingApp(event.packageName)) return;
    if (event.title.trim().isEmpty && event.content.trim().isEmpty) return;

    final record = NotificationRecord.fromServiceEvent(
      event,
      appLabelFor(event.packageName),
    );
    final id = NotificationLog.idFor(record);
    if (_seen.contains(id)) return;
    _seen.add(id);
    if (_seen.length > 200) {
      _seen.remove(_seen.first);
    }

    await _log.record(id, record);
    _enqueue(() => _evaluateRecord(id, record));
  }

  void _enqueue(Future<void> Function() job) {
    if (_queue.length >= _maxQueueLength) {
      _queue.removeAt(0);
    }
    _queue.add(job);
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.removeAt(0);
        try {
          await job();
        } catch (_) {}
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _evaluateRecord(String id, NotificationRecord record) async {
    final router = _router;
    if (router == null) return;

    final verdict = await router.evaluate(record);
    _evaluated++;
    await _log.attachVerdict(id, verdict);

    if (verdict.shouldAlert) {
      await _raiseAlert(record, verdict);
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
        unawaited(_warmUpIfInstalled());
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
        _enqueue(() => _evaluateRecord(id, record));
        return _statusMap();
      default:
        return null;
    }
  }

  Future<void> _refreshRouter() async {
    final endpoint = await _settings.remoteEndpoint();
    _router = EvaluationRouter(
      local: _local,
      remote: RemoteApiEvaluator(endpoint: endpoint.isEmpty ? null : endpoint),
      confidenceThreshold: await _settings.confidenceThreshold(),
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
