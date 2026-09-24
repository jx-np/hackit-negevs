import '../models/call_record.dart';
import 'call_database.dart';

abstract class ReportBackend {
  Future<bool> send(CallRecord record, String? reason);
}

class LocalOnlyReportBackend implements ReportBackend {
  @override
  Future<bool> send(CallRecord record, String? reason) async => false;
}

class ReportService {
  static ReportBackend backend = LocalOnlyReportBackend();

  static Future<bool> submitReport(CallRecord record, {String? reason}) async {
    final id = record.id;
    if (id != null) {
      await CallDatabase.instance
          .setReported(id, reported: true, reason: reason);
    }
    return backend.send(record, reason);
  }

  static Future<void> withdrawReport(CallRecord record) async {
    final id = record.id;
    if (id != null) {
      await CallDatabase.instance.setReported(id, reported: false);
    }
  }
}
