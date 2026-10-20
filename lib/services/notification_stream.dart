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
    this.key = '',
    this.conversationTitle,
    this.subText,
    this.isGroup = false,
  });

  factory IncomingNotification.fromMap(Map<dynamic, dynamic> map) {
    final postTime = (map['postTime'] as num?)?.toInt() ?? 0;
    final title = (map['title'] as String? ?? '').trim();
    final conversationTitle = (map['conversationTitle'] as String?)?.trim();
    return IncomingNotification(
      id: (map['id'] as num?)?.toInt() ?? 0,
      key: map['key'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      title: title,
      content: _stripRedundantSender(
        (map['content'] as String? ?? '').trim(),
        [title, conversationTitle],
      ),
      conversationTitle: conversationTitle,
      subText: (map['subText'] as String?)?.trim(),
      isGroup: map['isGroup'] as bool? ?? false,
      postedAt: postTime > 0
          ? DateTime.fromMillisecondsSinceEpoch(postTime)
          : DateTime.now(),
    );
  }

  /// The native listener prefixes each bundled message with its sender
  /// (`"Ywx: hello"`). In a one-to-one chat the notification title is already
  /// that same sender, so the name would reach the classifier twice (once as
  /// the Sender line, once inside the Message). Drop the prefix only when it
  /// matches the chat/sender name; distinct speakers in a group log are kept.
  static String _stripRedundantSender(
    String content,
    Iterable<String?> names,
  ) {
    final senders = names
        .map((name) => name?.trim().toLowerCase() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();
    if (senders.isEmpty || content.isEmpty) return content;
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final prefix = line.substring(0, colon).trim().toLowerCase();
      if (senders.contains(prefix)) {
        lines[i] = line.substring(colon + 1).trimLeft();
      }
    }
    return lines.join('\n').trim();
  }

  final int id;

  /// Stable Android notification key (`package|tag|id`), unchanged when an app
  /// updates the same notification (e.g. a Telegram thread gaining messages).
  final String key;
  final String packageName;
  final String title;
  final String content;
  final String? conversationTitle;
  final String? subText;

  /// Android marks the notification as a group conversation (API 28+, only
  /// for apps that use MessagingStyle). False when unknown.
  final bool isGroup;
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

  /// A fresh stream per call. A cached broadcast stream cannot be re-listened
  /// to after it completes, which would leave the background service deaf to
  /// notifications after any listener hiccup.
  static Stream<IncomingNotification> get stream =>
      _channel.receiveBroadcastStream().map(
            (event) => IncomingNotification.fromMap(event as Map),
          );
}
