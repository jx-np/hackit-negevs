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
import '../services/gguf_llm_evaluator.dart';
import '../services/local_llm_evaluator.dart';
import '../services/model_manager.dart';
import '../services/model_store.dart';
import '../services/notification_log.dart';
import '../services/notification_stream.dart';
import '../services/protection_settings.dart';
import '../services/scam_evaluator.dart';
import '../services/scamshield_channels.dart';

class BackgroundRunner {
  BackgroundRunner()
      : _settings = ProtectionSettings(),
        _models = GemmaModelManager(),
        _log = NotificationLog();

  final ProtectionSettings _settings;
  final GemmaModelManager _models;
  final NotificationLog _log;

  /// The Gemma / LiteRT-LM evaluator. Always constructed (it owns the
  /// flutter_edge_ai engine registration) but only used when the selected spec
  /// is not a `.gguf` file.
  late final LocalLlmEvaluator _edge =
      LocalLlmEvaluator(_models, settings: _settings);

  /// The GGUF evaluator, built on first use from the currently selected spec
  /// and dropped again whenever the evaluators are disposed. Kept alongside
  /// [_edge] rather than replacing it so switching back to a Gemma model does
  /// not lose the registered flutter_edge_ai engine.
  GgufLlmEvaluator? _gguf;

  /// The evaluator matching the loaded spec's file type, so the debug batch,
  /// live notifications and the settings test path all agree on the runtime.
  ScamEvaluator get _local {
    final spec = _models.spec;
    final path = spec.filePath;
    if (spec.isGguf && path != null && path.isNotEmpty) {
      return _gguf ??= GgufLlmEvaluator(
        modelPath: path,
        contextTokens: spec.contextTokens,
        thinking: spec.thinking,
      );
    }
    return _edge;
  }

  /// Releases both runtimes. The GGUF engine holds ~3 GB of native weights, so
  /// it must be dropped on model switch and on idle unload too, not only at
  /// shutdown.
  Future<void> _disposeEvaluators() async {
    await _edge.dispose();
    final gguf = _gguf;
    _gguf = null;
    await gguf?.dispose();
  }

  StreamSubscription<IncomingNotification>? _subscription;
  final Map<String, _NotificationFingerprint> _lastNotification =
      <String, _NotificationFingerprint>{};

  final List<_PendingEvaluation> _queue = [];
  bool _draining = false;
  static const int _maxQueueLength = 25;

  /// Messages shorter than this (after trimming) skip the on-device model
  /// entirely: a scam needs both an ask and pressure, which cannot fit in a
  /// handful of characters, so running the model would only waste a load and a
  /// generation on replies like "ok" or "see you".
  static const int _minAnalyzableChars = 10;

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

  /// Minimum model confidence for raising the scam alert overlay. The label
  /// must also be a scam; `not_scam` and `unsure` never alert. The model emits
  /// 0.95 / 0.8 / 0.6 in practice, so this excludes only its weakest guesses.
  static const double _alertMinConfidence = 0.7;

  /// Multi-turn context window: earlier messages from the same conversation
  /// within this span are fed into the prompt so a slow-burn scam spread across
  /// several messages is judged together. Older messages are ignored — a scam's
  /// ask and pressure arrive close together, and a wider window only adds
  /// prefill cost and risks pulling in an unrelated earlier chat.
  static const Duration _threadWindow = Duration(hours: 6);

  /// Most prior messages fed into the multi-turn prompt. Capped so a long,
  /// chatty thread cannot blow up prefill time; the latest message is always
  /// the one classified, these are only context.
  static const int _maxThreadTurns = 4;

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
    await _disposeEvaluators();
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
        await _disposeEvaluators();
      }
      _modelReady = false;
    }
    _models.spec = spec;
    if (spec.isGguf) {
      // GGUF files are read in place by llamadart, so the flutter_edge_ai
      // bookkeeping (ModelStore, registerFromFile, bundled install) does not
      // apply — and running it would report the file as uninstalled.
      _modelInstalled = await _installedFor(spec);
      _modelReady = false;
      return;
    }
    _modelInstalled = await _installedFor(spec);
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

  /// Whether the selected model's weights are actually available. A GGUF is
  /// just a file at the picked path; everything else goes through the
  /// flutter_edge_ai model store.
  Future<bool> _installedFor(ScamModelSpec spec) async {
    if (spec.isGguf) {
      final path = spec.filePath;
      return path != null && path.isNotEmpty && await File(path).exists();
    }
    return _models.isInstalled();
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
      // Very short messages ("ok", "hi", "👍") cannot carry a scam's ask plus
      // its pressure, so they are not worth a model load or a generation.
      // Skip the model entirely and record a not_scam verdict so the message
      // still shows as checked. Measured on the trimmed text so leading or
      // trailing whitespace does not pad a one-word reply over the threshold.
      if (record.content.trim().length < _minAnalyzableChars) {
        final verdict = ScamVerdict(
          label: ScamLabel.notScam,
          confidence: 0.95,
          reason: 'Message too short to be a scam',
          source: EvaluationSource.local,
        );
        _evaluated++;
        await _log.attachVerdict(id, record, verdict);
        return;
      }

      // A notification arrived: keep the model alive and load it if this is
      // the first message since it was unloaded. Scam checks run entirely
      // on-device — the message is never sent off the device.
      _cancelIdleUnload();
      if (!_modelReady) {
        await _warmUp();
      }

      // Pull a short rolling window of earlier messages from the SAME
      // conversation so a slow-burn, multi-turn scam — where the ask and the
      // pressure are spread across several messages — is judged in context
      // rather than one message at a time. Empty for a first/one-off message,
      // which then keeps today's single-message prompt cost.
      final priorMessages = await _recentThread(id, record);

      // Compute the cheap local hints once: they involve a contact-directory
      // lookup, and the model prompt needs them. The thread is passed in so
      // tells from earlier messages ("click now") count towards signals.
      final hints = await ScamHintBuilder.fromRecord(
        record,
        priorMessages: priorMessages,
      );

      ScamVerdict verdict;
      try {
        verdict = await _local.evaluate(
          record,
          priorMessages: priorMessages,
          hints: hints,
        );
      } catch (error) {
        // A failed on-device evaluation must not escalate off-device; surface
        // it as an inconclusive verdict instead.
        verdict = ScamVerdict.unsure(reason: 'On-device check failed: $error');
      }
      _evaluated++;
      _trace(
        'verdict ${verdict.label.name} '
        '${verdict.confidence.toStringAsFixed(2)} | '
        'hints: ${hints.render()} | ${verdict.reason}',
      );
      await _log.attachVerdict(id, record, verdict);

      // Alert on every scam verdict the model is reasonably sure about. The
      // local hints are still computed for the prompt, but they are not an
      // alert gate: a real scam can carry a single code-detected signal (for
      // example an unsolicited "call this number" notice), and suppressing
      // those made the overlay disappear for cases the model correctly flags.
      // Only `not_scam`, `unsure`, and low-confidence guesses stay quiet.
      if (verdict.isScam && verdict.confidence > _alertMinConfidence) {
        await _raiseAlert(record, verdict);
      }
    } finally {
      _busy = false;
      _wakeLock('releaseWakeLock');
      if (_pendingModelSwitch) {
        _pendingModelSwitch = false;
        // Await the teardown here rather than firing it unawaited. The drain
        // loop calls _evaluateRecord again as soon as this returns, and that
        // path warms the model back up (FlutterEdgeAi.getActiveModel). On the
        // NPU/QNN backend, building a new context while the old one is still
        // being deregistered races the handle release — the source of the
        // "Failed to get context from memHandle" / "Invalid context" errors.
        // Each close is already bounded by _closeTimeout inside dispose(), so
        // awaiting here cannot stall the queue indefinitely.
        await _disposeEvaluators();
      }
      _scheduleIdleUnload();
    }
  }

  /// Earlier messages from the same conversation as [record], oldest first,
  /// for the multi-turn prompt. Groups by [NotificationRecord.conversationKey]
  /// (the stable Android notification key, falling back to package|sender),
  /// keeps only entries within [_threadWindow], excludes the current message
  /// ([currentId]) and returns at most [_maxThreadTurns] message bodies.
  ///
  /// Returns an empty list for a first or one-off message, so the evaluator
  /// falls back to the single-message prompt at its usual cost — the
  /// multi-turn path only fires when there is real prior context.
  Future<List<String>> _recentThread(
    String currentId,
    NotificationRecord record,
  ) async {
    final key = record.conversationKey;
    final List<LoggedNotification> entries;
    try {
      entries = await _log.all();
    } catch (error) {
      _trace('thread read failed: $error');
      return const [];
    }
    final cutoff = DateTime.now().subtract(_threadWindow);
    // _log.all() is newest-first. Collect the matching earlier messages, then
    // reverse to oldest-first for the prompt.
    final prior = <String>[];
    for (final entry in entries) {
      if (entry.id == currentId) continue;
      if (entry.record.conversationKey != key) continue;
      if (entry.capturedAt.isBefore(cutoff)) continue;
      final text = entry.record.content.trim();
      if (text.isEmpty) continue;
      prior.add(text);
      if (prior.length >= _maxThreadTurns) break;
    }
    return prior.reversed.toList();
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
    await _disposeEvaluators();
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
        // The notification text on its own. The overlay renders `sender`
        // separately, so passing `body` (sender + text) would duplicate the
        // name. `message` stays the full body for the report hand-off.
        'text': record.content,
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
        _modelInstalled = await _installedFor(_models.spec);
        return _statusMap();
      case 'warmUp':
        _modelInstalled = await _installedFor(_models.spec);
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
      // Optional per-item prior turns. When a measurement input carries a
      // `priorMessages` list, the message is judged twice — once on its own
      // and once with that earlier context — so a single batch run yields a
      // paired single-vs-multi comparison on the same message, plus the prefill
      // cost of each path. Absent the field, behaviour is unchanged. An empty
      // list is a deliberate control that still runs the multi-turn path.
      final prior = _priorFromItem(item);
      if (prior != null) {
        entry['prior_messages'] = prior;
      }
      // Optional per-item cap on how many worked examples the prompt carries,
      // read from an input's `examples` field. Absent the field the default set
      // is used, so behaviour is unchanged; 0 measures the instructions alone.
      final exampleCount = _exampleCountFromItem(item);
      if (exampleCount != null) {
        entry['examples'] = exampleCount;
      }
      _setStatus('Batch ${i + 1}/${items.length}');

      _busy = true;
      final started = DateTime.now();
      try {
        final hints = await ScamHintBuilder.fromRecord(record);
        final multiHints = prior == null
            ? hints
            : await ScamHintBuilder.fromRecord(record, priorMessages: prior);
        final singleStarted = DateTime.now();
        final single = await _evaluateForBatch(
          record,
          hints: hints,
          exampleCount: exampleCount,
        );
        entry['verdict'] = single.toJson();
        entry['timing_ms'] =
            DateTime.now().difference(singleStarted).inMilliseconds;

        if (prior != null) {
          final multiStarted = DateTime.now();
          final multi = await _evaluateForBatch(
            record,
            priorMessages: prior,
            hints: multiHints,
            exampleCount: exampleCount,
          );
          entry['verdict_multi'] = multi.toJson();
          entry['timing_multi_ms'] =
              DateTime.now().difference(multiStarted).inMilliseconds;
        }

        entry['hints'] = _hintsToJson(hints);
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

  /// Evaluates [record] through whichever on-device runtime is selected, with
  /// the batch harness's prompt-sizing knob.
  ///
  /// [ScamEvaluator] only carries the multi-turn argument; `exampleCount` (how
  /// many worked examples the prompt carries) is exposed by the two on-device
  /// evaluators alone, so it is dispatched on the concrete type here. Both
  /// branches build the same prompt shape, which is what makes a GGUF run
  /// comparable with the Gemma baseline.
  Future<ScamVerdict> _evaluateForBatch(
    NotificationRecord record, {
    List<String>? priorMessages,
    ScamHints? hints,
    int? exampleCount,
  }) {
    final evaluator = _local;
    if (evaluator is GgufLlmEvaluator) {
      return evaluator.evaluate(
        record,
        priorMessages: priorMessages,
        hints: hints,
        exampleCount: exampleCount,
      );
    }
    return _edge.evaluate(
      record,
      priorMessages: priorMessages,
      hints: hints,
      exampleCount: exampleCount,
    );
  }

  /// Optional per-item prior turns for multi-turn measurement, read from a
  /// batch input's `priorMessages` array. Returns null when the field is absent
  /// (judge the message alone) or the cleaned list when it is present — an
  /// empty list is a deliberate control that still runs the multi-turn path
  /// with no context. Blank entries are dropped.
  List<String>? _priorFromItem(dynamic item) {
    if (item is! Map) return null;
    final raw = item['priorMessages'];
    if (raw is! List) return null;
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Optional per-item cap on how many worked examples the prompt carries, read
  /// from a batch input's `examples` field. Returns null when the field is
  /// absent (use the default set), else the non-negative count — 0 measures the
  /// instructions with no examples at all.
  int? _exampleCountFromItem(dynamic item) {
    if (item is! Map) return null;
    final raw = item['examples'];
    if (raw is int) return raw < 0 ? 0 : raw;
    if (raw is num) return raw.toInt().clamp(0, 1 << 20);
    return null;
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
