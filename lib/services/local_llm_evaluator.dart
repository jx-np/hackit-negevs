import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/notification_record.dart';
import '../core/scam_prompt.dart';
import '../core/scam_verdict.dart';
import 'model_manager.dart';
import 'model_store.dart';
import 'protection_settings.dart';
import 'scam_evaluator.dart';

class LocalLlmEvaluator implements ScamEvaluator {
  LocalLlmEvaluator(this._models, {ProtectionSettings? settings})
      : _settings = settings ?? ProtectionSettings();

  final ProtectionSettings _settings;

  static const int _maxOutputTokens = 200;

  /// Reasoning models spend most of their budget on the ` thinking` block before
  /// writing the JSON, so they need a much larger cap. On-device this is still
  /// bounded by the model's context window (see [ScamModelSpec.contextTokens]).
  static const int _maxThinkingOutputTokens = 5000;

  /// Budget for a model that reasons whether or not it was asked to. The
  /// runtime only forwards `enable_thinking` when it is enabled, so a hybrid
  /// model left switched off still thinks — at 200 tokens it is cut off
  /// mid-reasoning and never reaches the JSON answer.
  static const int _maxReasoningOutputTokens = 1500;

  static const Duration _responseTimeout = Duration(seconds: 30);
  static const Duration _thinkingResponseTimeout = Duration(seconds: 180);

  /// Native model load / teardown must be bounded: if either hangs it would
  /// stall the background evaluation queue and silently stop detection until
  /// the service is restarted.
  static const Duration _loadTimeout = Duration(seconds: 60);
  static const Duration _closeTimeout = Duration(seconds: 15);

  /// Smallest input cap, used when the model only has a small window (the
  /// `.task` catalog models are 1024-1280 tokens). The full text is still
  /// stored in the notification log regardless.
  static const int _baseInputChars = 1200;

  /// Ceiling on the input cap. A picked model may advertise a very large
  /// window, but feeding megabytes of chat log only slows generation down and
  /// the classifier reads the same short excerpt either way.
  static const int _maxInputChars = 4000;

  final GemmaModelManager _models;

  InferenceModel? _model;

  bool get _isThinking => scamThinkingEnabled(
        thinking: _models.spec.thinking,
        contextTokens: _models.spec.contextTokens,
      );

  /// True when the model will emit a thinking block even though thinking was
  /// not enabled: hybrid models reason by default and the runtime sends no
  /// `enable_thinking` flag at all when the toggle is off.
  bool get _reasonsAnyway =>
      !_isThinking &&
      _models.spec.contextTokens >= kMinThinkingContextTokens;

  int get _outputTokenCap => _isThinking
      ? _maxThinkingOutputTokens
      : _reasonsAnyway
          ? _maxReasoningOutputTokens
          : _maxOutputTokens;
  Duration get _responseTimeoutFor => _isThinking
      ? _thinkingResponseTimeout
      : _reasonsAnyway
          ? const Duration(seconds: 90)
          : _responseTimeout;

  /// Tokens available for the prompt after reserving room for the answer. The
  /// MediaPipe `.task` path has no output cap (it ignores `maxOutputTokens`), so
  /// the answer can only fit if the prompt leaves room for it.
  int get _inputTokenBudget => scamInputTokenBudget(
        thinking: _models.spec.thinking || _reasonsAnyway,
        contextTokens: _models.spec.contextTokens,
      );

  /// How much of the incoming message is actually sent to the model. It grows
  /// with the window so a large-context model is not starved by a cap that was
  /// chosen for a 1024-token one, but stays well under the window.
  int get _inputCharCap =>
      _inputTokenBudget <= 1024
          ? _baseInputChars
          : (_inputTokenBudget * 3).clamp(_baseInputChars, _maxInputChars);

  @override
  String get name => _models.spec.displayName;

  @override
  Future<void> warmUp() async {
    await _models.ensureInitialized();
    if (_model != null) return;
    final spec = _models.spec;
    if (await ModelStore.exists(spec)) {
      final path = await ModelStore.pathFor(spec);
      if (path != null) await _models.registerFromFile(path);
    }
    if (!await _models.isInstalled()) {
      throw StateError(
        'No on-device model installed. Open Scam Shield and download one.',
      );
    }
    final backend = await _settings.modelBackend();
    _model = await FlutterGemma.getActiveModel(
      maxTokens: _models.spec.contextTokens,
      preferredBackend: backend == ModelBackend.gpu
          ? PreferredBackend.gpu
          : PreferredBackend.cpu,
    ).timeout(_loadTimeout);
  }

  @override
  Future<ScamVerdict> evaluate(NotificationRecord record) async {
    try {
      await warmUp();
      final model = _model!;
      final session = await model.createSession(
        temperature: 0.2,
        topK: 40,
        enableThinking: _isThinking,
        maxOutputTokens: _outputTokenCap,
      );
      try {
        final prompt = await _fittedPrompt(session, record);
        await session.addQueryChunk(Message(text: prompt, isUser: true));
        final buffer = StringBuffer();
        var produced = 0;
        var stopping = false;
        // Keep consuming until the model reports done=true. Breaking out early
        // (or closing while it is still generating) makes MediaPipe throw
        // "Previous invocation still processing".
        final stream = session.getResponseAsync().timeout(
          _responseTimeoutFor,
        );
        await for (final token in stream) {
          if (produced >= _outputTokenCap) {
            if (!stopping) {
              stopping = true;
              try {
                await session.stopGeneration();
              } catch (_) {}
            }
            continue;
          }
          buffer.write(token);
          produced++;
        }
        return parseScamVerdict(
          buffer.toString(),
          source: EvaluationSource.local,
        );
      } finally {
        try {
          await session.close().timeout(_closeTimeout);
        } catch (_) {}
      }
    } catch (error) {
      return ScamVerdict.unsure(reason: 'Local model error: $error');
    }
  }

  /// Builds the compact prompt and, if the runtime exposes a tokenizer,
  /// verifies it fits [_inputTokenBudget]. When the fixed instructions plus the
  /// message overflow the window the message is scaled down to the remaining
  /// share so generation still has room for the JSON answer.
  Future<String> _fittedPrompt(
    InferenceModelSession session,
    NotificationRecord record,
  ) async {
    final budget = _inputTokenBudget;
    final message = _truncate(record.content, _inputCharCap);
    String build(String text) => buildScamPrompt(
          compact: true,
          appLabel: record.appLabel,
          sender: record.title,
          message: text,
        );
    final prompt = build(message);
    final tokens = await _countTokens(session, prompt);
    if (tokens <= budget) return prompt;
    final allowedChars = (message.length * budget / tokens).floor();
    return build(_truncate(message, allowedChars));
  }

  Future<int> _countTokens(
    InferenceModelSession session,
    String text,
  ) async {
    try {
      return await session.sizeInTokens(text);
    } catch (_) {
      return estimatePromptTokens(text);
    }
  }

  String _truncate(String text, int maxChars) {
    if (maxChars <= 0) return '';
    if (text.length <= maxChars) return text;
    final head = maxChars ~/ 2;
    final tail = maxChars - head;
    return '${text.substring(0, head)}\n… [middle omitted] …\n'
        '${text.substring(text.length - tail)}';
  }

  @override
  Future<void> dispose() async {
    final model = _model;
    _model = null;
    if (model == null) return;
    // Actually release the native weights. The plugin's close listener resets
    // its cached singleton, so a later warmUp() rebuilds the model cleanly.
    // Bounded so a stuck teardown can never block the evaluation queue.
    try {
      await model.close().timeout(_closeTimeout);
    } catch (_) {}
  }
}
