import '../core/notification_record.dart';
import '../core/scam_verdict.dart';

abstract class ScamEvaluator {
  String get name;

  Future<void> warmUp();

  Future<ScamVerdict> evaluate(NotificationRecord record);

  Future<void> dispose();
}
