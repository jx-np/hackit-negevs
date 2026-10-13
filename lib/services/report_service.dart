import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/call_record.dart';
import '../models/report_payload.dart';
import 'call_database.dart';

const String kDefaultReportEndpoint = '';

abstract class ReportBackend {
  Future<bool> send(CallRecord record, String? reason);
  Future<bool> sendPayload(ReportPayload payload);
}

class LocalOnlyReportBackend implements ReportBackend {
  @override
  Future<bool> send(CallRecord record, String? reason) async => false;

  @override
  Future<bool> sendPayload(ReportPayload payload) async => false;
}

class HttpReportBackend implements ReportBackend {
  HttpReportBackend({this.endpoint = kDefaultReportEndpoint, this.apiKey = ''});

  static const Duration _timeout = Duration(seconds: 30);

  final String endpoint;
  final String apiKey;

  bool get isConfigured => endpoint.trim().isNotEmpty;

  @override
  Future<bool> send(CallRecord record, String? reason) {
    return sendPayload(
      ReportPayload(
        kind: ReportPayload.kindCall,
        application: 'Phone',
        number: record.rawNumber,
        content: record.status,
        reason: reason,
        verdict: record.reportReason,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> sendPayload(ReportPayload payload) async {
    if (!isConfigured) return false;
    try {
      final response = await http
          .post(
            Uri.parse(endpoint.trim()),
            headers: {
              'Content-Type': 'application/json',
              if (apiKey.trim().isNotEmpty)
                'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode(payload.toJson()),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ReportService {
  static ReportBackend backend = HttpReportBackend();

  static Future<bool> submitReport(CallRecord record, {String? reason}) async {
    await CallDatabase.instance.setReportedByNumber(
      record.normalizedNumber,
      reported: true,
      reason: reason,
    );
    return backend.send(record, reason);
  }

  static Future<bool> submitPayload(ReportPayload payload) =>
      backend.sendPayload(payload);
}
