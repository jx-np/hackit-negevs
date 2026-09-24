import '../core/notification_record.dart';
import '../core/scam_verdict.dart';
import 'scam_evaluator.dart';

class EvaluationRouter {
  EvaluationRouter({
    required this.local,
    required this.remote,
    this.confidenceThreshold = 0.6,
  });

  final ScamEvaluator local;
  final ScamEvaluator remote;
  final double confidenceThreshold;

  Future<ScamVerdict> evaluate(NotificationRecord record) async {
    ScamVerdict verdict;
    try {
      verdict = await local.evaluate(record);
    } catch (error) {
      verdict = ScamVerdict.unsure(reason: 'Local evaluation failed: $error');
    }

    if (!needsEscalation(verdict)) {
      return verdict;
    }

    final remoteVerdict = await remote.evaluate(record);
    if (remoteVerdict.label == ScamLabel.unsure &&
        remoteVerdict.confidence == 0) {
      // The cloud could not produce a verdict, so the local result stands and
      // must not be labelled as cloud-checked.
      return verdict;
    }
    return remoteVerdict.copyWith(escalated: true);
  }

  bool needsEscalation(ScamVerdict verdict) =>
      verdict.label == ScamLabel.unsure ||
      verdict.confidence < confidenceThreshold;
}
