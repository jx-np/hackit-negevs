import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// A single call event forwarded from the native Android layer.
class CallEvent {
  const CallEvent({required this.state, this.number, this.name});

  /// One of `incoming`, `outgoing`, `idle`.
  final String state;
  final String? number;
  final String? name;

  bool get isIncoming => state == 'incoming';
  bool get isOutgoing => state == 'outgoing';
  bool get isIdle => state == 'idle';

  static CallEvent fromMap(Object? event) {
    final map = (event as Map).cast<Object?, Object?>();
    return CallEvent(
      state: (map['state'] as String?) ?? 'unknown',
      number: map['number'] as String?,
      name: map['name'] as String?,
    );
  }
}

/// Bridges native call events (detected by the CallScreeningService /
/// PhoneStateReceiver) to Dart.
class CallEventService {
  static const EventChannel _events =
      EventChannel('com.scamwatch.negavsinparis/call_events');

  /// Emits an event whenever a call is detected or ends.
  /// Returns an empty stream on non-Android platforms.
  static Stream<CallEvent> get events {
    if (!Platform.isAndroid) return const Stream<CallEvent>.empty();
    return _events
        .receiveBroadcastStream()
        .map(CallEvent.fromMap)
        .handleError((Object _) {});
  }
}
