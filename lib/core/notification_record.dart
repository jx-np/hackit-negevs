import '../services/notification_stream.dart';
import 'scam_verdict.dart';

class NotificationRecord {
  NotificationRecord({
    required this.packageName,
    required this.appLabel,
    required this.title,
    required this.content,
    required this.postedAt,
    this.id = 0,
    this.key = '',
  });

  factory NotificationRecord.fromIncoming(
    IncomingNotification event,
    String appLabel,
  ) {
    final title = event.title.trim();
    final content = event.content.trim();
    return NotificationRecord(
      id: event.id,
      key: event.key,
      packageName: event.packageName,
      appLabel: appLabel,
      title: title,
      content: content.isNotEmpty
          ? content
          : (event.subText?.trim().isNotEmpty ?? false)
              ? event.subText!.trim()
              : title,
      postedAt: event.postedAt,
    );
  }

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      id: json['id'] as int? ?? 0,
      key: json['key'] as String? ?? '',
      packageName: json['packageName'] as String? ?? '',
      appLabel: json['appLabel'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      postedAt: DateTime.fromMillisecondsSinceEpoch(
        json['postedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  final int id;
  final String key;
  final String packageName;
  final String appLabel;
  final String title;
  final String content;
  final DateTime postedAt;

  String get body {
    final parts = <String>[];
    if (title.trim().isNotEmpty) parts.add(title.trim());
    if (content.trim().isNotEmpty) parts.add(content.trim());
    return parts.join('\n');
  }

  /// Stable per-conversation identity used to group a sender's recent messages
  /// into a thread. Prefers the Android notification [key] (package|tag|id),
  /// which stays constant as an app updates the same conversation's
  /// notification and does not depend on the display title — so it survives a
  /// masked sender such as "Unknown sender" that would otherwise collapse every
  /// unknown-sender chat into one bogus thread. Falls back to package+title
  /// only when the key is absent.
  String get conversationKey =>
      key.isNotEmpty ? key : '$packageName|$title';

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'packageName': packageName,
        'appLabel': appLabel,
        'title': title,
        'content': content,
        'postedAt': postedAt.millisecondsSinceEpoch,
      };
}

class EvaluatedNotification {
  EvaluatedNotification({
    required this.record,
    required this.verdict,
    required this.evaluatedAt,
  });

  factory EvaluatedNotification.fromJson(Map<String, dynamic> json) {
    return EvaluatedNotification(
      record: NotificationRecord.fromJson(
        Map<String, dynamic>.from(json['record'] as Map),
      ),
      verdict: ScamVerdict.fromJson(
        Map<String, dynamic>.from(json['verdict'] as Map),
      ),
      evaluatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['evaluatedAt'] as int? ?? 0,
      ),
    );
  }

  final NotificationRecord record;
  final ScamVerdict verdict;
  final DateTime evaluatedAt;

  Map<String, dynamic> toJson() => {
        'record': record.toJson(),
        'verdict': verdict.toJson(),
        'evaluatedAt': evaluatedAt.millisecondsSinceEpoch,
      };
}
