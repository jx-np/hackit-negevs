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
    required this.modelInstalled,
    required this.modelLoading,
    required this.modelReady,
    required this.processing,
    required this.modelError,
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
      modelInstalled: data['modelInstalled'] as bool? ?? false,
      modelLoading: data['modelLoading'] as bool? ?? false,
      modelReady: data['modelReady'] as bool? ?? false,
      processing: data['processing'] as bool? ?? false,
      modelError: data['modelError'] as bool? ?? false,
      downloadProgress: data['downloadProgress'] as int? ?? -1,
      alertsRaised: data['alertsRaised'] as int? ?? 0,
      evaluated: data['evaluated'] as int? ?? 0,
      lastMessage: data['lastMessage'] as String? ?? '',
    );
  }

  static const ServiceStatus idle = ServiceStatus(
    running: false,
    modelId: '',
    modelInstalled: false,
    modelLoading: false,
    modelReady: false,
    processing: false,
    modelError: false,
    downloadProgress: -1,
    alertsRaised: 0,
    evaluated: 0,
    lastMessage: '',
  );

  final bool running;
  final String modelId;

  /// True once the model weights are present on disk. The model is loaded
  /// into memory lazily (on the first message) and released again after an
  /// idle period, so this stays true even when [modelReady] is false.
  final bool modelInstalled;
  final bool modelLoading;
  final bool modelReady;
  final bool processing;
  final bool modelError;
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

  /// True when the app may launch full-screen intents, which is how scam and
  /// high-risk-call alerts wake the screen over the lock screen. Android 14+
  /// withholds this by default; below Android 14 it is always true.
  static Future<bool> hasFullScreenIntent() async =>
      await ScamShieldChannels.ui.invokeMethod<bool>('hasFullScreenIntent') ??
      false;

  /// Opens the system "Full screen notifications" settings screen for this app
  /// so the user can grant [hasFullScreenIntent]. No-op on Android < 14.
  static Future<void> requestFullScreenIntent() =>
      ScamShieldChannels.ui.invokeMethod<void>('requestFullScreenIntent');

  /// True when the app holds "All files access" (`MANAGE_EXTERNAL_STORAGE`),
  /// which lets the dev menu scan shared storage (Download, Documents, the
  /// external-storage root) for model files. On Android < R this is always
  /// true. This permission is only declared in the debug manifest, so release
  /// builds report false and keep scanning only the app-private directory.
  static Future<bool> hasAllFilesAccess() async =>
      await ScamShieldChannels.ui.invokeMethod<bool>('hasAllFilesAccess') ??
      false;

  /// Opens the system "All files access" settings screen for this app so the
  /// user can grant [hasAllFilesAccess]. No-op on Android < R.
  static Future<void> requestAllFilesAccess() =>
      ScamShieldChannels.ui.invokeMethod<void>('requestAllFilesAccess');

  /// True when the app is exempt from battery optimization (Doze). Without
  /// this exemption the system eventually stops the background foreground
  /// service, so on-device scam screening quietly dies after a while. On
  /// Android < M (no Doze) this is always true.
  static Future<bool> hasIgnoreBatteryOptimizations() async =>
      await ScamShieldChannels.ui
          .invokeMethod<bool>('hasIgnoreBatteryOptimizations') ??
      false;

  /// Shows the direct battery-optimization exemption dialog so the user can
  /// let the app keep running in the background. Falls back to the system
  /// battery-optimization list screen if the direct dialog is unavailable.
  /// No-op on Android < M or when the exemption is already held.
  static Future<void> requestIgnoreBatteryOptimizations() => ScamShieldChannels
      .ui
      .invokeMethod<void>('requestIgnoreBatteryOptimizations');

  /// Opens the full system battery-optimization list (every app), where the
  /// user can pick this app and set it to "Don't optimize". This is the manual
  /// route for aggressive OEM ROMs that ignore or never show the direct
  /// one-tap exemption dialog from [requestIgnoreBatteryOptimizations]. Falls
  /// back to this app's details screen if the list screen is unavailable.
  /// No-op on Android < M.
  static Future<void> openBatteryOptimizationSettings() => ScamShieldChannels.ui
      .invokeMethod<void>('openBatteryOptimizationSettings');

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

  /// Dismisses the scam-alert notification and any overlay after the user has
  /// acted on it (reported the message). Also re-syncs the background engine's
  /// raised-alert count with the notifications still in the log, so the number
  /// on the protected screen drops as soon as the reported alert is removed.
  static Future<void> dismissScamAlert() async {
    await ScamShieldChannels.ui.invokeMethod<void>('dismissScamAlert');
    await syncAlerts();
  }

  /// Asks the background engine to recompute its raised-alert count from the
  /// notification log. Call after removing or clearing logged alerts so the
  /// count matches the list the user is looking at.
  ///
  /// This goes through the UI channel, which forwards to the background
  /// engine's control channel natively: the UI engine cannot invoke
  /// `scamshield/control` directly because that handler lives in the separate
  /// background engine.
  static Future<void> syncAlerts() async {
    try {
      await ScamShieldChannels.ui.invokeMethod<void>('syncAlerts');
    } catch (_) {
      // The background engine may be stopped; its in-memory count is gone with
      // it, so there is nothing to sync.
    }
  }

  /// Total physical RAM in bytes as reported by the OS
  /// (`ActivityManager.MemoryInfo.totalMem`). Returns 0 when the value cannot
  /// be read, which callers treat as "assume the smaller model".
  static Future<int> deviceTotalRamBytes() async =>
      await ScamShieldChannels.storage.invokeMethod<int>(
        'getDeviceTotalRamBytes',
      ) ??
      0;

  /// True when the active network is metered (mobile data or a Wi-Fi network
  /// the user flagged as metered). Returns false on read failure so a failed
  /// check never blocks a download behind a warning dialog.
  static Future<bool> isOnMeteredConnection() async =>
      await ScamShieldChannels.storage.invokeMethod<bool>(
        'isOnMeteredConnection',
      ) ??
      false;
}
