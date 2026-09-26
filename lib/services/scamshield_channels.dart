import 'package:flutter/services.dart';

class ScamShieldChannels {
  static const MethodChannel native = MethodChannel('scamshield/native');
  static const MethodChannel control = MethodChannel('scamshield/control');
  static const MethodChannel ui = MethodChannel('scamshield/ui');
  static const MethodChannel storage = MethodChannel('scamshield/storage');
}

class ServiceStatus {
  const ServiceStatus({
    required this.running,
    required this.modelId,
    required this.modelLoading,
    required this.modelReady,
    required this.downloadProgress,
    required this.alertsRaised,
    required this.evaluated,
    required this.lastMessage,
  });

  factory ServiceStatus.fromMap(Map<dynamic, dynamic>? map) {
    final data = map ?? const {};
    return ServiceStatus(
      running: data['running'] as bool? ?? false,
      modelId: data['modelId'] as String? ?? '',
      modelLoading: data['modelLoading'] as bool? ?? false,
      modelReady: data['modelReady'] as bool? ?? false,
      downloadProgress: data['downloadProgress'] as int? ?? -1,
      alertsRaised: data['alertsRaised'] as int? ?? 0,
      evaluated: data['evaluated'] as int? ?? 0,
      lastMessage: data['lastMessage'] as String? ?? '',
    );
  }

  static const ServiceStatus idle = ServiceStatus(
    running: false,
    modelId: '',
    modelLoading: false,
    modelReady: false,
    downloadProgress: -1,
    alertsRaised: 0,
    evaluated: 0,
    lastMessage: '',
  );

  final bool running;
  final String modelId;
  final bool modelLoading;
  final bool modelReady;
  final int downloadProgress;
  final int alertsRaised;
  final int evaluated;
  final String lastMessage;
}

class ScamShieldController {
  static Future<bool> isServiceRunning() async =>
      await ScamShieldChannels.ui.invokeMethod<bool>('isServiceRunning') ??
      false;

  static Future<void> startService() =>
      ScamShieldChannels.ui.invokeMethod<void>('startService');

  static Future<void> stopService() =>
      ScamShieldChannels.ui.invokeMethod<void>('stopService');

  static Future<bool> ensureServiceRunning({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (await isServiceRunning()) return true;
    await startService();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (await isServiceRunning()) return true;
    }
    return false;
  }

  static Future<bool> hasOverlayPermission() async =>
      await ScamShieldChannels.ui.invokeMethod<bool>('hasOverlayPermission') ??
      false;

  static Future<void> requestOverlayPermission() =>
      ScamShieldChannels.ui.invokeMethod<void>('requestOverlayPermission');

  static Future<void> openNotificationAccessSettings() =>
      ScamShieldChannels.ui
          .invokeMethod<void>('openNotificationAccessSettings');

  static Future<bool> hasNotificationPermission() async =>
      await ScamShieldChannels.ui
          .invokeMethod<bool>('hasNotificationPermission') ??
      true;

  static Future<void> requestNotificationPermission() => ScamShieldChannels.ui
      .invokeMethod<void>('requestNotificationPermission');

  static Future<ServiceStatus> status() async {
    final map = await ScamShieldChannels.ui
        .invokeMethod<Map<dynamic, dynamic>>('getStatus');
    return ServiceStatus.fromMap(map);
  }

  static Future<void> warmUpModel() =>
      ScamShieldChannels.ui.invokeMethod<void>('warmUpModel');

  static Future<void> testEvaluate(String text) =>
      ScamShieldChannels.ui.invokeMethod<void>('testEvaluate', {'text': text});

  static Future<void> syncSettings() =>
      ScamShieldChannels.ui.invokeMethod<void>('syncSettings');

  static Future<void> setShieldEnabled(bool value) => ScamShieldChannels.ui
      .invokeMethod<void>('setShieldEnabled', {'enabled': value});
}
