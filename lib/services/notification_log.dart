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
  static const String _clearedKey = 'notification_thread_cleared';
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

  /// Removes [id] plus every other logged message from the same conversation.
  ///
  /// Reporting a scam must clear the whole thread, not just the reported row:
  /// the background runner feeds earlier logged messages from the same
  /// conversation back to the model as multi-turn context. Leaving them behind
  /// would keep handing the reported scam text to the model and bias the verdict
  /// on a later, legitimate message in that chat.
  ///
  /// Keyed notifications normally only keep one row per conversation (the id is
  /// the notification key), so this is usually equivalent to [remove]. It
  /// matters when the key is absent and rows accumulate per package+sender.
  Future<void> removeThread(String id) async {
    final raw = await _prefs.getStringList(_key) ?? <String>[];
    String? threadKey;
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        if (decoded['id'] == id) {
          threadKey =
              LoggedNotification.fromJson(decoded).record.conversationKey;
          break;
        }
      } catch (_) {}
    }
    if (threadKey == null) {
      // Nothing matched (e.g. a legacy id); fall back to the exact row.
      await remove(id);
      return;
    }
    raw.removeWhere((entry) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        return LoggedNotification.fromJson(decoded).record.conversationKey ==
            threadKey;
      } catch (_) {
        return false;
      }
    });
    await _prefs.setStringList(_key, raw);
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
    await _prefs.remove(_clearedKey);
  }

  /// Marks [id]'s conversation as context-cleared from now on.
  ///
  /// The logged messages stay in [all] so they continue to show under Recent
  /// alerts on the Safety tab, but the background runner stops feeding anything
  /// captured at or before this moment to the model as multi-turn context. Used
  /// when the user swipes the scam-alert notification away: they acknowledged
  /// the warning, so the reported text must not prime the next verdict, without
  /// hiding the alert from the safety list.
  Future<void> clearThreadContext(String id) async {
    if (id.isEmpty) return;
    final threadKey = await _conversationKeyFor(id) ?? id;
    final cleared = await _clearedThreads();
    cleared[threadKey] = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setString(_clearedKey, jsonEncode(cleared));
  }

  /// When [conversationKey]'s context was last cleared, or null if never.
  /// Messages captured at or before this instant are excluded from the
  /// multi-turn prompt; newer messages start a fresh thread.
  Future<DateTime?> threadClearedAt(String conversationKey) async {
    final cleared = await _clearedThreads();
    final millis = cleared[conversationKey];
    if (millis is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<Map<String, dynamic>> _clearedThreads() async {
    final raw = await _prefs.getString(_clearedKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<String?> _conversationKeyFor(String id) async {
    final raw = await _prefs.getStringList(_key) ?? const [];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        if (decoded['id'] == id) {
          return LoggedNotification.fromJson(decoded).record.conversationKey;
        }
      } catch (_) {}
    }
    return null;
  }
}
