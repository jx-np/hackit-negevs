import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/notification_record.dart';
import '../core/scam_prompt.dart';
import '../core/scam_verdict.dart';
import 'model_manager.dart';
import 'model_store.dart';
import 'scam_evaluator.dart';

class LocalLlmEvaluator implements ScamEvaluator {
  LocalLlmEvaluator(this._models);

  static const int _maxOutputTokens = 200;

  /// The on-device context window is 1024 tokens and the prompt already uses
  /// a few hundred, so a very long chat message is capped before it is fed to
  /// the model. The full text is still stored in the notification log.
  static const int _maxInputChars = 1200;

  final GemmaModelManager _models;

  InferenceModel? _model;

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
    _model = await FlutterGemma.getActiveModel(maxTokens: 1024);
  }

  @override
  Future<ScamVerdict> evaluate(NotificationRecord record) async {
    try {
      await warmUp();
      final model = _model!;
      final session = await model.createSession(temperature: 0.2, topK: 40);
      try {
        final prompt = buildScamPrompt(
          appLabel: record.appLabel,
          sender: record.title,
          message: _truncate(record.content, _maxInputChars),
        );
        await session.addQueryChunk(Message(text: prompt, isUser: true));
        final buffer = StringBuffer();
        var produced = 0;
        var stopping = false;
        // Keep consuming until the model reports done=true. Breaking out early
        // (or closing while it is still generating) makes MediaPipe throw
        // "Previous invocation still processing".
        final stream = session.getResponseAsync().timeout(
          const Duration(seconds: 30),
        );
        await for (final token in stream) {
          if (produced >= _maxOutputTokens) {
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
          await session.close();
        } catch (_) {}
      }
    } catch (error) {
      return ScamVerdict.unsure(reason: 'Local model error: $error');
    }
  }

  String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}… [message truncated]';
  }

  @override
  Future<void> dispose() async {
    _model = null;
  }
}
