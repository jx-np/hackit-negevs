import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:call_log_app/services/role_service.dart';
import 'package:call_log_app/services/scamshield_channels.dart';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Where a single permission currently stands.
enum StepStatus {
  /// The permission is on.
  granted,

  /// The permission is off, but the app can still ask for it.
  notGranted,

  /// The system will no longer show a prompt; the user has to turn it on in
  /// the phone's settings.
  blocked,
}

enum PermissionStepKind {
  phone,
  contacts,
  callScreening,
  notifications,
  messageAccess,
  overlay,
}

/// One page of the onboarding flow: a single permission, how to check it and
/// how to ask for it.
class PermissionStep {
  const PermissionStep._({
    required this.kind,
    required this.icon,
    required this.opensSettings,
    required Future<StepStatus> Function() check,
    required Future<void> Function() request,
  }) : _check = check,
       _request = request;

  final PermissionStepKind kind;
  final IconData icon;

  /// True when asking for this permission sends the user to a system settings
  /// page instead of showing a simple Allow / Deny prompt.
  final bool opensSettings;

  final Future<StepStatus> Function() _check;
  final Future<void> Function() _request;

  /// Current status. Platform errors (e.g. missing native plugin on a
  /// non-Android build) are treated as "not granted".
  Future<StepStatus> check() async {
    try {
      return await _check();
    } catch (_) {
      return StepStatus.notGranted;
    }
  }

  /// Shows the system prompt or settings page for this permission.
  Future<void> request() async {
    try {
      await _request();
    } catch (_) {
      // The follow-up check() reports the real state.
    }
  }

  String title(AppLocalizations l10n) => switch (kind) {
    PermissionStepKind.phone => l10n.onboardingPhoneTitle,
    PermissionStepKind.contacts => l10n.onboardingContactsTitle,
    PermissionStepKind.callScreening => l10n.onboardingScreeningTitle,
    PermissionStepKind.notifications => l10n.onboardingNotificationsTitle,
    PermissionStepKind.messageAccess => l10n.onboardingMessagesTitle,
    PermissionStepKind.overlay => l10n.onboardingOverlayTitle,
  };

  String body(AppLocalizations l10n) => switch (kind) {
    PermissionStepKind.phone => l10n.onboardingPhoneBody,
    PermissionStepKind.contacts => l10n.onboardingContactsBody,
    PermissionStepKind.callScreening => l10n.onboardingScreeningBody,
    PermissionStepKind.notifications => l10n.onboardingNotificationsBody,
    PermissionStepKind.messageAccess => l10n.onboardingMessagesBody,
    PermissionStepKind.overlay => l10n.onboardingOverlayBody,
  };
}

/// The full list of permissions the app needs, in the order they are shown.
class OnboardingPermissions {
  OnboardingPermissions._();

  static final List<PermissionStep> steps = [
    PermissionStep._(
      kind: PermissionStepKind.phone,
      icon: Icons.phone_outlined,
      opensSettings: false,
      check: () => _runtimeStatus(Permission.phone),
      request: () => Permission.phone.request(),
    ),
    PermissionStep._(
      kind: PermissionStepKind.contacts,
      icon: Icons.contacts_outlined,
      opensSettings: false,
      check: () => _runtimeStatus(Permission.contacts),
      request: () => Permission.contacts.request(),
    ),
    PermissionStep._(
      kind: PermissionStepKind.callScreening,
      icon: Icons.phone_callback_outlined,
      opensSettings: false,
      check: () async => _fromBool(await RoleService.isCallScreening()),
      request: RoleService.requestCallScreening,
    ),
    PermissionStep._(
      kind: PermissionStepKind.notifications,
      icon: Icons.notifications_outlined,
      opensSettings: false,
      check: () async {
        // Both the runtime permission and the Scam Shield alert channel must
        // be allowed for warnings to appear.
        final runtime = await _runtimeStatus(Permission.notification);
        if (runtime != StepStatus.granted) return runtime;
        return _fromBool(await ScamShieldController.hasNotificationPermission());
      },
      request: () async {
        await Permission.notification.request();
        if (!await ScamShieldController.hasNotificationPermission()) {
          await ScamShieldController.requestNotificationPermission();
        }
      },
    ),
    PermissionStep._(
      kind: PermissionStepKind.messageAccess,
      icon: Icons.sms_outlined,
      opensSettings: true,
      check: () async =>
          _fromBool(await NotificationListenerService.isPermissionGranted()),
      request: NotificationListenerService.requestPermission,
    ),
    PermissionStep._(
      kind: PermissionStepKind.overlay,
      icon: Icons.layers_outlined,
      opensSettings: true,
      check: () async =>
          _fromBool(await ScamShieldController.hasOverlayPermission()),
      request: ScamShieldController.requestOverlayPermission,
    ),
  ];

  /// True when every onboarding permission is on.
  static Future<bool> allGranted() async {
    for (final step in steps) {
      if (await step.check() != StepStatus.granted) return false;
    }
    return true;
  }

  static Future<StepStatus> _runtimeStatus(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return StepStatus.granted;
    if (status.isPermanentlyDenied) return StepStatus.blocked;
    return StepStatus.notGranted;
  }

  static StepStatus _fromBool(bool granted) =>
      granted ? StepStatus.granted : StepStatus.notGranted;
}
