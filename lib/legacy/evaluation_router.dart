// LEGACY — cloud escalation routing (no longer wired into the app).
//
// This file used to decide whether a message was checked on-device or
// escalated to the remote cloud model. Scam checks are now on-device only:
// the background runner evaluates every message against the local model and
// never sends message content off the device. See
// `lib/background/background_runner.dart`.
//
// It is kept here (unused) so the cloud-escalation behavior can be restored
// later if needed. Nothing in `lib/` imports this; it is intentionally
// excluded from the live code path. The companion
// `lib/legacy/remote_api_evaluator.dart` is the cloud evaluator it drove.

import '../core/notification_record.dart';
import '../core/scam_verdict.dart';
import '../services/scam_evaluator.dart';

class EvaluationRouter {
  EvaluationRouter({
    required this.local,
    required this.remote,
    this.confidenceThreshold = 0.6,
    this.forceCloud = false,
  });

  final ScamEvaluator local;
  final ScamEvaluator remote;
  final double confidenceThreshold;

  /// When true, skip the on-device model and send every message to the cloud.
  /// The local model is only used as a fallback if the cloud is unreachable.
  final bool forceCloud;

  Future<ScamVerdict> evaluate(NotificationRecord record) async {
    if (forceCloud) {
      final remoteVerdict = await remote.evaluate(record);
      if (_isUsable(remoteVerdict)) {
        return remoteVerdict.copyWith(escalated: true);
      }
      // Cloud unavailable: fall back to the on-device model so protection
      // still works, and report it as a local result.
      try {
        return await local.evaluate(record);
      } catch (error) {
        return ScamVerdict.unsure(
          reason: 'Cloud and local evaluation failed: $error',
        );
      }
    }

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
    if (!_isUsable(remoteVerdict)) {
      // The cloud could not produce a verdict, so the local result stands and
      // must not be labelled as cloud-checked.
      return verdict;
    }
    return remoteVerdict.copyWith(escalated: true);
  }

  bool _isUsable(ScamVerdict verdict) =>
      verdict.label != ScamLabel.unsure || verdict.confidence > 0;

  bool needsEscalation(ScamVerdict verdict) =>
      verdict.label == ScamLabel.unsure ||
      verdict.confidence < confidenceThreshold;
}
