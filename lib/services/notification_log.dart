import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/notification_record.dart';
import '../core/scam_verdict.dart';

class LoggedNotification {
  LoggedNotification({
    required this.id,
    required this.record,
    required this.capturedAt,
    this.verdict,
  });

  factory LoggedNotification.fromJson(Map<String, dynamic> json) {
    final rawVerdict = json['verdict'];
    return LoggedNotification(
      id: json['id'] as String? ?? '',
      record: NotificationRecord.fromJson(
        Map<String, dynamic>.from(json['record'] as Map),
      ),
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        json['capturedAt'] as int? ?? 0,
      ),
      verdict: rawVerdict == null
          ? null
          : ScamVerdict.fromJson(Map<String, dynamic>.from(rawVerdict as Map)),
    );
  }

  final String id;
  final NotificationRecord record;
  final DateTime capturedAt;
  final ScamVerdict? verdict;

  bool get isChecked => verdict != null;

  LoggedNotification withVerdict(ScamVerdict value) => LoggedNotification(
        id: id,
        record: record,
        capturedAt: capturedAt,
        verdict: value,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'record': record.toJson(),
        'capturedAt': capturedAt.millisecondsSinceEpoch,
        'verdict': verdict?.toJson(),
      };
}

class NotificationLog {
  static const String _key = 'notification_log';
  static const int _maxEntries = 200;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static String idFor(NotificationRecord record) {
    if (record.key.isNotEmpty) return record.key;
    return '${record.packageName}|${record.title}|${record.content}';
  }

  Future<List<LoggedNotification>> all() async {
    final raw = await _prefs.getStringList(_key) ?? const [];
    final items = <LoggedNotification>[];
    for (final entry in raw) {
      try {
        items.add(
          LoggedNotification.fromJson(
            jsonDecode(entry) as Map<String, dynamic>,
          ),
        );
      } catch (_) {}
    }
    return items;
  }

  Future<void> record(String id, NotificationRecord record) async {
    final raw = await _prefs.getStringList(_key) ?? <String>[];
    raw.removeWhere((entry) {
      try {
        return (jsonDecode(entry) as Map<String, dynamic>)['id'] == id;
      } catch (_) {
        return false;
      }
    });
    final item = LoggedNotification(id: id, record: record, capturedAt: DateTime.now());
    raw.insert(0, jsonEncode(item.toJson()));
    while (raw.length > _maxEntries) {
      raw.removeLast();
    }
    await _prefs.setStringList(_key, raw);
  }

  Future<void> attachVerdict(
    String id,
    NotificationRecord record,
    ScamVerdict verdict,
  ) async {
    final raw = await _prefs.getStringList(_key) ?? <String>[];
    var found = false;
    for (var i = 0; i < raw.length; i++) {
      try {
        final decoded = jsonDecode(raw[i]) as Map<String, dynamic>;
        if (decoded['id'] == id) {
          raw[i] = jsonEncode(
            LoggedNotification.fromJson(decoded).withVerdict(verdict).toJson(),
          );
          found = true;
          break;
        }
      } catch (_) {}
    }
    if (!found) {
      // A large burst can evict the oldest entries, including one still queued
      // for evaluation. Re-insert the record with its verdict instead of
      // silently dropping the result and leaving the row "not checked".
      raw.insert(
        0,
        jsonEncode(
          LoggedNotification(
            id: id,
            record: record,
            capturedAt: DateTime.now(),
            verdict: verdict,
          ).toJson(),
        ),
      );
      while (raw.length > _maxEntries) {
        raw.removeLast();
      }
    }
    await _prefs.setStringList(_key, raw);
  }

  Future<void> remove(String id) async {
    final raw = await _prefs.getStringList(_key) ?? <String>[];
    raw.removeWhere((entry) {
      try {
        return (jsonDecode(entry) as Map<String, dynamic>)['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await _prefs.setStringList(_key, raw);
  }

  Future<void> clear() => _prefs.remove(_key);
}
