import '../core/notification_record.dart';
import '../core/scam_hints.dart';
import '../core/scam_verdict.dart';

abstract class ScamEvaluator {
  String get name;

  Future<void> warmUp();

  /// Evaluates [record]. [priorMessages] carries recent earlier messages from
  /// the same sender (oldest first) so a multi-turn scam whose ask and pressure
  /// are split across messages can be judged in context; it defaults to empty,
  /// in which case the evaluation is single-message as before.
  ///
  /// [hints] may be supplied by the caller when they have already been computed
  /// (they involve a contact-directory lookup); when null the evaluator computes
  /// them itself.
  Future<ScamVerdict> evaluate(
    NotificationRecord record, {
    List<String>? priorMessages,
    ScamHints? hints,
  });

  Future<void> dispose();
}
