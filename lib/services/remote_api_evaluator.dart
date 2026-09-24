import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/notification_record.dart';
import '../core/scam_verdict.dart';
import 'scam_evaluator.dart';

class RemoteApiEvaluator implements ScamEvaluator {
  RemoteApiEvaluator({this.endpoint, this.apiKey});

  final String? endpoint;
  final String? apiKey;

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
      final response = await http
          .post(
            Uri.parse(endpoint!),
            headers: {
              'Content-Type': 'application/json',
              if ((apiKey ?? '').isNotEmpty) 'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'packageName': record.packageName,
              'appLabel': record.appLabel,
              'title': record.title,
              'content': record.content,
              'postedAt': record.postedAt.millisecondsSinceEpoch,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ScamVerdict(
          label: ScamLabel.unsure,
          confidence: 0.0,
          reason: 'Cloud review failed (HTTP ${response.statusCode})',
          source: EvaluationSource.remote,
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ScamVerdict(
        label: ScamLabel.fromWire(json['label'] as String?),
        confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.0)
            .clamp(0.0, 1.0),
        reason: (json['reason'] as String?) ?? 'Reviewed in the cloud',
        source: EvaluationSource.remote,
      );
    } catch (error) {
      return ScamVerdict(
        label: ScamLabel.unsure,
        confidence: 0.0,
        reason: 'Cloud review unavailable: $error',
        source: EvaluationSource.remote,
      );
    }
  }

  @override
  Future<void> dispose() async {}
}
