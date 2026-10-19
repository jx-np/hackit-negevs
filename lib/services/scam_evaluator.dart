import '../core/notification_record.dart';
import '../core/scam_verdict.dart';

abstract class ScamEvaluator {
  String get name;

  Future<void> warmUp();

  /// Evaluates [record]. [priorMessages] carries recent earlier messages from
  /// the same sender (oldest first) so a multi-turn scam whose ask and pressure
  /// are split across messages can be judged in context; it defaults to empty,
  /// in which case the evaluation is single-message as before.
  Future<ScamVerdict> evaluate(
    NotificationRecord record, {
    List<String> priorMessages,
  });

  Future<void> dispose();
}
