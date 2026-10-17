import '../core/notification_record.dart';
import '../core/scam_hints.dart';
import '../core/scam_verdict.dart';

abstract class ScamEvaluator {
  String get name;

  Future<void> warmUp();

  /// Evaluates [record]. [hints] may be supplied by the caller when they have
  /// already been computed (they involve a contact-directory lookup); when null
  /// the evaluator computes them itself.
  Future<ScamVerdict> evaluate(NotificationRecord record, {ScamHints? hints});

  Future<void> dispose();
}
