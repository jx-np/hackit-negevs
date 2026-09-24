import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges the Android call-screening role API, which is only reachable from
/// native code.
class RoleService {
  static const MethodChannel _channel =
      MethodChannel('com.example.call_log_app/roles');

  static bool get isSupported => Platform.isAndroid;

  static Future<bool> isCallScreening() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isCallScreening') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Triggers the system role request dialog for call screening.
  /// Returns true if the request activity was launched.
  static Future<bool> requestCallScreening() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestCallScreening') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
