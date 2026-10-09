class ReportPayload {
  const ReportPayload({
    required this.kind,
    required this.application,
    this.number,
    required this.content,
    this.category,
    this.reason,
    this.verdict,
    this.sender,
    this.packageName,
    this.notificationKey,
    required this.createdAt,
  });

  static const String kindNotification = 'notification';
  static const String kindCall = 'call';

  static const String categorySpam = 'spam';
  static const String categoryScam = 'scam';
  static const String categoryOther = 'other';

  final String kind;

  /// The app the report is about. Always present: a number on its own is not
  /// enough, since unknown senders on apps such as Telegram only expose a
  /// nickname and the app is what can actually be acted on.
  final String application;

  /// Optional phone number, resolved from the sender when possible.
  final String? number;

  final String content;
  final String? category;
  final String? reason;
  final String? verdict;

  /// The sender shown on the notification (a number on WhatsApp, a nickname
  /// on Telegram, etc.), kept for reference even when no number resolves.
  final String? sender;
  final String? packageName;

  /// Stable Android notification key, used to drop the matching queue entry.
  final String? notificationKey;
  final DateTime createdAt;

  String get subject =>
      (number?.trim().isNotEmpty ?? false) ? number!.trim() : application;

  Map<String, Object?> toJson() => {
        'kind': kind,
        'application': application,
        'number': number,
        'subject': subject,
        'sender': sender,
        'packageName': packageName,
        'notificationKey': notificationKey,
        'content': content,
        'category': category,
        'reason': reason,
        'verdict': verdict,
        'createdAt': createdAt.toIso8601String(),
      };
}
