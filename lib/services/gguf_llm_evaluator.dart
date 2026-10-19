import 'dart:async';
import 'dart:io';

import 'package:llamadart/llamadart.dart';
import 'package:scamwatch_mobile_app/core/notification_record.dart';
import 'package:scamwatch_mobile_app/core/scam_hints.dart';
import 'package:scamwatch_mobile_app/core/scam_prompt.dart';
import 'package:scamwatch_mobile_app/core/scam_verdict.dart';
import 'package:scamwatch_mobile_app/services/scam_evaluator.dart';

/// On-device scam evaluator for a `.gguf` file, run through llama.cpp via
/// `llamadart`.
///
/// It mirrors [ScamEvaluator]'s contract and [LocalLlmEvaluator]'s prompt
/// shape exactly — the same [buildScamPrompt] and [parseScamVerdict] — so a
/// GGUF run is comparable with the Gemma/LiteRT-LM baseline and the existing
/// batch harness measures it without changes.
///
/// The model always runs on the CPU: llamadart's Android Vulkan backend is
/// experimental and returns wrong output on several GPUs, and no Qualcomm NPU
/// path exists for GGUF (that needs a `.litertlm`/QNN bundle).
class GgufLlmEvaluator implements ScamEvaluator {
  GgufLlmEvaluator({
    required this.modelPath,
    required this.contextTokens,
    this.thinking = false,
  });

  /// Absolute path of the `.gguf` file on this device. The file is read in
  /// place; it is never copied or registered with flutter_edge_ai.
  final String modelPath;

  /// Total context window (input + output) requested when the weights load.
  final int contextTokens;

  /// Whether the model's private reasoning block should be enabled. Qwen3.5
  /// toggles it through the chat template's `enable_thinking` argument, which
  /// llamadart forwards.
  final bool thinking;

  LlamaEngine? _engine;

  /// Plain-answer token cap, matching [LocalLlmEvaluator].
  static const int _maxOutputTokens = 200;

  /// A thinking turn spends most of its budget on the reasoning block before
  /// writing the JSON, so it needs a much larger cap.
  static const int _maxThinkingOutputTokens = 1500;

  /// Qwen/llama.cpp chat end markers, so generation stops at the turn
  /// boundary instead of running into the template's next turn.
  static const List<String> _stopSequences = ['<|im_end|>', '</s>'];

  /// Loading 2.5 GB of weights is slow on a phone, but it must still be
  /// bounded: it runs inside the background queue's own load timeout, and a
  /// stuck native load would otherwise stall detection silently.
  static const Duration _loadTimeout = Duration(seconds: 60);
  static const Duration _responseTimeout = Duration(seconds: 240);
  static const Duration _disposeTimeout = Duration(seconds: 15);

  static const int _baseInputChars = 1200;
  static const int _maxInputChars = 4000;
  static const int _priorTurnChars = 70;

  bool get _isThinking => scamThinkingEnabled(
        thinking: thinking,
        contextTokens: contextTokens,
      );

  int get _outputTokenCap =>
      _isThinking ? _maxThinkingOutputTokens : _maxOutputTokens;

  int get _inputTokenBudget => scamInputTokenBudget(
        thinking: _isThinking,
        contextTokens: contextTokens,
      );

  int get _inputCharCap => _inputTokenBudget <= 1024
      ? _baseInputChars
      : (_inputTokenBudget * 3).clamp(_baseInputChars, _maxInputChars);

  @override
  String get name => 'GGUF ${modelPath.split(RegExp(r'[\\/]')).last}';

  @override
  Future<void> warmUp() async {
    if (_engine != null) return;
    if (!await File(modelPath).exists()) {
      throw StateError(
        'GGUF model file not found at $modelPath. Pick it again in settings.',
      );
    }
    _engine = await LlamaEngine.load(
      LlamaModel(ModelSource.path(modelPath)),
      params: ModelParams(
        contextSize: contextTokens,
        // CPU only: the Android Vulkan backend is not safe here.
        device: ComputeDevice.cpu,
        gpuLayers: 0,
        preferredBackend: GpuBackend.cpu,
        batchSize: 512,
        microBatchSize: 256,
      ),
    ).timeout(_loadTimeout);
  }

  @override
  Future<ScamVerdict> evaluate(
    NotificationRecord record, {
    List<String>? priorMessages,
    ScamHints? hints,
    int? exampleCount,
  }) async {
    try {
      await warmUp();
      final engine = _engine!;
      final prompt = await _fittedPrompt(
        engine,
        record,
        priorMessages,
        hints,
        exampleCount,
      );
      // `create` applies the chat template the GGUF carries, which is exactly
      // what LocalLlmEvaluator's `addQueryChunk` does on the Gemma path. The
      // raw `generate` would skip the template and not be comparable.
      final text = await engine
          .create(
            [LlamaChatMessage.fromText(role: LlamaChatRole.user, text: prompt)],
            enableThinking: _isThinking,
            params: GenerationParams(
              maxTokens: _outputTokenCap,
              temp: 0.2,
              topK: 40,
              stopSequences: _stopSequences,
            ),
          )
          .text()
          .timeout(_responseTimeout);
      return parseScamVerdict(text, source: EvaluationSource.local);
    } catch (error) {
      return ScamVerdict.unsure(reason: 'GGUF model error: $error');
    }
  }

  /// Builds the compact prompt and, when the runtime can tokenize, verifies it
  /// fits [_inputTokenBudget]. Mirrors LocalLlmEvaluator so both runtimes see
  /// the same prompt shapes and get the same clipping rules.
  Future<String> _fittedPrompt(
    LlamaEngine engine,
    NotificationRecord record,
    List<String>? priorMessages,
    ScamHints? precomputedHints,
    int? exampleCount,
  ) async {
    final budget = _inputTokenBudget;
    final message = _truncate(record.content, _inputCharCap);
    // Reuse hints computed by the caller when available; recomputing here would
    // hit the device contacts DB a second time (see ScamHintBuilder.fromRecord).
    final hints =
        (precomputedHints ?? await ScamHintBuilder.fromRecord(record)).render();
    final prior = (priorMessages ?? const <String>[])
        .map((m) => _truncate(m.trim(), _priorTurnChars))
        .where((m) => m.isNotEmpty)
        .toList();
    String build(String text) => buildScamPrompt(
          compact: true,
          appLabel: record.appLabel,
          sender: record.title,
          message: text,
          hints: hints,
          priorMessages: prior,
          examples: exampleCount,
        );
    final prompt = build(message);
    final tokens = await _countTokens(engine, prompt);
    if (tokens <= budget) return prompt;
    final allowedChars = (message.length * budget / tokens).floor();
    return build(_truncate(message, allowedChars));
  }

  Future<int> _countTokens(LlamaEngine engine, String text) async {
    try {
      return await engine.getTokenCount(text);
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
    final engine = _engine;
    _engine = null;
    if (engine == null) return;
    // Bounded so a stuck teardown cannot block the evaluation queue.
    try {
      await engine.dispose().timeout(_disposeTimeout);
    } catch (_) {}
  }
}
