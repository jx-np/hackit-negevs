import 'dart:async';

import 'package:flutter/services.dart';

/// A notification as forwarded by the native [ScamNotificationListener].
class IncomingNotification {
  const IncomingNotification({
    required this.id,
    required this.packageName,
    required this.title,
    required this.content,
    required this.postedAt,
    this.conversationTitle,
    this.subText,
  });

  factory IncomingNotification.fromMap(Map<dynamic, dynamic> map) {
    final postTime = (map['postTime'] as num?)?.toInt() ?? 0;
    return IncomingNotification(
      id: (map['id'] as num?)?.toInt() ?? 0,
      packageName: map['packageName'] as String? ?? '',
      title: (map['title'] as String? ?? '').trim(),
      content: (map['content'] as String? ?? '').trim(),
      conversationTitle: (map['conversationTitle'] as String?)?.trim(),
      subText: (map['subText'] as String?)?.trim(),
      postedAt: postTime > 0
          ? DateTime.fromMillisecondsSinceEpoch(postTime)
          : DateTime.now(),
    );
  }

  final int id;
  final String packageName;
  final String title;
  final String content;
  final String? conversationTitle;
  final String? subText;
  final DateTime postedAt;

  /// The chat/sender name plus the extracted message content. Falls back to
  /// the subtitle when the content could not be read.
  String get body {
    final parts = <String>[];
    final chat = conversationTitle?.trim();
    if (chat != null && chat.isNotEmpty && chat != title.trim()) {
      parts.add(chat);
    }
    if (title.trim().isNotEmpty) parts.add(title.trim());
    if (content.trim().isNotEmpty) {
      parts.add(content.trim());
    } else if (subText != null && subText!.isNotEmpty) {
      parts.add(subText!);
    }
    return parts.join('\n');
  }
}

/// Streams notifications from the native listener service.
class NotificationStream {
  NotificationStream._();

  static const EventChannel _channel = EventChannel('scamshield/notifications');

  static Stream<IncomingNotification>? _stream;

  static Stream<IncomingNotification> get stream =>
      _stream ??= _channel.receiveBroadcastStream().map(
            (event) => IncomingNotification.fromMap(event as Map),
          );
}
