// LEGACY — cloud (remote) scam evaluator (no longer wired into the app).
//
// This posted message content to an OpenAI-compatible cloud endpoint for a
// second-opinion verdict. Scam checks are now on-device only and no message
// content leaves the device, so nothing in `lib/` constructs this anymore.
// It is kept here (unused) alongside `lib/legacy/evaluation_router.dart` so
// cloud review can be restored later if needed.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/notification_record.dart';
import '../core/scam_hints.dart';
import '../core/scam_prompt.dart';
import '../core/scam_verdict.dart';
import '../services/scam_evaluator.dart';

/// Calls an OpenAI-compatible `/v1/chat/completions` endpoint (the cloud
/// review server). The model may be a reasoning model; its private thinking is
/// returned in a separate `reasoning_content` field and is ignored, while the
/// final answer in `content` is parsed like any other model output.
class RemoteApiEvaluator implements ScamEvaluator {
  RemoteApiEvaluator({
    this.endpoint,
    this.apiKey,
    this.model = 'minicpm5-2b',
    this.reasoningBudget = 512,
    this.answerTokens = 300,
    this.maxTokensOverride = 0,
  });

  final String? endpoint;
  final String? apiKey;
  final String model;

  /// Cap on the model's private reasoning tokens.
  final int reasoningBudget;

  /// Tokens reserved for the final JSON answer.
  final int answerTokens;

  /// Explicit cap on generated tokens per request. When greater than zero it
  /// is used as-is; otherwise the cap is derived from the reasoning budget.
  final int maxTokensOverride;

  /// Reasoning tokens are counted towards `max_tokens`, so the cap must be
  /// larger than the reasoning budget or the answer gets truncated away.
  int get maxTokens =>
      maxTokensOverride > 0 ? maxTokensOverride : reasoningBudget + answerTokens;

  static const Duration _timeout = Duration(seconds: 60);

  @override
  String get name => 'Cloud review';

  bool get isConfigured => (endpoint ?? '').trim().isNotEmpty;

  @override
  Future<void> warmUp() async {}

  @override
  Future<ScamVerdict> evaluate(NotificationRecord record) async {
    if (!isConfigured) {
      return const ScamVerdict(
        label: ScamLabel.unsure,
        confidence: 0.0,
        reason: 'Cloud review is not configured yet',
        source: EvaluationSource.remote,
      );
    }
    try {
      final hints = (await ScamHintBuilder.fromRecord(record)).render();
      final prompt = buildScamPrompt(
        appLabel: record.appLabel,
        sender: record.title,
        message: record.content,
        hints: hints,
      );
      final response = await http
          .post(
            Uri.parse(endpoint!),
            headers: {
              'Content-Type': 'application/json',
              if ((apiKey ?? '').isNotEmpty) 'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content': 'You are a conservative scam-message classifier. '
                      'Reply with exactly one valid JSON object and nothing '
                      'else.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.2,
              'max_tokens': maxTokens,
              if (reasoningBudget > 0) 'reasoning_budget': reasoningBudget,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ScamVerdict(
          label: ScamLabel.unsure,
          confidence: 0.0,
          reason: 'Cloud review failed (HTTP ${response.statusCode})',
          source: EvaluationSource.remote,
        );
      }
      final content = _extractContent(response.body);
      if (content.trim().isEmpty) {
        return const ScamVerdict(
          label: ScamLabel.unsure,
          confidence: 0.0,
          reason: 'Cloud review returned an empty answer',
          source: EvaluationSource.remote,
        );
      }
      return parseScamVerdict(content, source: EvaluationSource.remote);
    } catch (error) {
      return ScamVerdict(
        label: ScamLabel.unsure,
        confidence: 0.0,
        reason: 'Cloud review unavailable: $error',
        source: EvaluationSource.remote,
      );
    }
  }

  String _extractContent(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) return '';
    final message = choices.first;
    if (message is! Map) return '';
    final content = message['message'];
    if (content is! Map) return '';
    return (content['content'] as String?) ?? '';
  }

  @override
  Future<void> dispose() async {}
}
