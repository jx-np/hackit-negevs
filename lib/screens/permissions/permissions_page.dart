import 'dart:io';

import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/role_service.dart';
import '../../services/scamshield_channels.dart';

class PermissionsTab extends StatefulWidget {
  const PermissionsTab({super.key});

  @override
  State<PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<PermissionsTab>
    with WidgetsBindingObserver {
  bool _notificationAccess = false;
  bool _overlayGranted = false;
  bool _notificationPermission = true;
  bool _isCallScreening = false;
  Map<Permission, PermissionStatus> _permissions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _refreshAll() async {
    final access = Platform.isAndroid
        ? await NotificationListenerService.isPermissionGranted()
        : false;
    final overlay = await ScamShieldController.hasOverlayPermission();
    final alerts = await ScamShieldController.hasNotificationPermission();
    final screening = await RoleService.isCallScreening();
    final permissions = <Permission, PermissionStatus>{
      Permission.phone: await Permission.phone.status,
      Permission.contacts: await Permission.contacts.status,
      Permission.notification: await Permission.notification.status,
    };
    if (!mounted) return;
    setState(() {
      _notificationAccess = access;
      _overlayGranted = overlay;
      _notificationPermission = alerts;
      _isCallScreening = screening;
      _permissions = permissions;
    });
  }

  Future<void> _requestNotificationAccess() async {
    await NotificationListenerService.requestPermission();
    await _refreshAll();
  }

  Future<void> _requestOverlay() async {
    await ScamShieldController.requestOverlayPermission();
    await _refreshAll();
  }

  Future<void> _requestAlerts() async {
    await ScamShieldController.requestNotificationPermission();
    await _refreshAll();
  }

  Future<void> _requestPermission(
    Permission permission,
    String grantedMessage,
  ) async {
    final status = await permission.request();
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      setState(() => _permissions[permission] = status);
      _showStatus(status.isGranted ? grantedMessage : l10n.permDenied);
    }
    await _refreshAll();
  }

  Future<void> _enableCallScreening() async {
    final launched = await RoleService.requestCallScreening();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    _showStatus(
      launched ? l10n.permConfirmScreening : l10n.permScreeningUnavailable,
    );
    await _refreshAll();
  }

  void _showStatus(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openAppSettings() async {
    if (Platform.isAndroid) {
      final uri = Uri.parse('package:com.scamwatch.negavsinparis');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final fallback = Uri.parse('app-settings:');
    if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntroCard(context),
          const SizedBox(height: 16),
          _buildServiceCard(context),
          const SizedBox(height: 16),
          _buildCallScreeningCard(context),
          const SizedBox(height: 16),
          _buildAppPermissionsCard(context),
          const SizedBox(height: 16),
          _buildTroubleshootCard(context),
        ],
      ),
    );
  }

  // Calm, plain-language intro that replaces the old floating status line.
  Widget _buildIntroCard(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context);
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, size: 28, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.permTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.permGrantFollowing,
                    style: TextStyle(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _checkTile(
              l10n.permNotificationAccess,
              l10n.permNotificationAccessSub,
              _notificationAccess,
              _requestNotificationAccess,
            ),
            const FDivider(),
            _checkTile(
              l10n.permOverlay,
              l10n.permOverlaySub,
              _overlayGranted,
              _requestOverlay,
            ),
            const FDivider(),
            _checkTile(
              l10n.permAlerts,
              l10n.permAlertsSub,
              _notificationPermission,
              _requestAlerts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkTile(
    String title,
    String subtitle,
    bool ok,
    Future<void> Function() onFix,
  ) {
    final colors = context.theme.colors;
    return _permissionRow(
      title: title,
      subtitle: subtitle,
      granted: ok,
      statusColor: ok ? colors.primary : colors.secondaryForeground,
      onGrant: onFix,
    );
  }

  Widget _permissionRow({
    required String title,
    required String subtitle,
    required bool granted,
    required Color statusColor,
    required Future<void> Function() onGrant,
  }) {
    final l10n = AppLocalizations.of(context);
    return FTile(
      prefix: Icon(
        granted ? Icons.check_circle : Icons.error_outline,
        color: granted ? context.theme.colors.primary : statusColor,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: statusColor),
      ),
      suffix: granted
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 18, color: context.theme.colors.primary),
                const SizedBox(width: 4),
                Text(l10n.permGranted),
              ],
            )
          : FButton(
              onPress: onGrant,
              size: FButtonSizeVariant.sm,
              mainAxisSize: MainAxisSize.min,
              child: Text(l10n.permGrant),
            ),
    );
  }

  Widget _buildCallScreeningCard(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context);
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_in_talk, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.permScreeningRole,
                      style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Icon(
                  _isCallScreening
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                    color: _isCallScreening
                      ? colors.primary
                      : colors.mutedForeground,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.permScreeningRoleSub),
            const SizedBox(height: 16),
            FButton(
              onPress: _isCallScreening ? null : _enableCallScreening,
              child: Text(
                _isCallScreening
                    ? l10n.permScreeningActive
                    : l10n.permEnableScreening,
              ),
            ),
            if (!_isCallScreening) ...[
              const SizedBox(height: 12),
              FAlert(
                variant: FAlertVariant.destructive,
                title: Text(l10n.permScreeningNotGranted),
                subtitle: Text(l10n.permScreeningTapHint),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppPermissionsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.permTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.permGrantFollowing),
            const SizedBox(height: 8),
            _buildPermissionTile(
              permission: Permission.phone,
              title: l10n.permPhoneCallLog,
              grantedMessage: l10n.permPhoneGranted,
            ),
            const FDivider(),
            _buildPermissionTile(
              permission: Permission.contacts,
              title: l10n.permContacts,
              grantedMessage: l10n.permContactsGranted,
            ),
            const FDivider(),
            _buildPermissionTile(
              permission: Permission.notification,
              title: l10n.permNotifications,
              grantedMessage: l10n.permNotificationsGranted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.permStillNotWorking,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.permOpenSettingsBody),
            const SizedBox(height: 16),
            FButton(
              onPress: _openAppSettings,
              prefix: const Icon(Icons.settings),
              child: Text(l10n.permOpenAppSettings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required Permission permission,
    required String title,
    required String grantedMessage,
  }) {
    final l10n = AppLocalizations.of(context);
    return _permissionRow(
      title: title,
      subtitle: _getPermissionStatus(l10n, permission),
      granted: _permissions[permission] == PermissionStatus.granted,
      statusColor: _getPermissionColor(permission),
      onGrant: () => _requestPermission(permission, grantedMessage),
    );
  }

  String _getPermissionStatus(AppLocalizations l10n, Permission permission) {
    final status = _permissions[permission];
    if (status == null) return l10n.permNotChecked;
    switch (status) {
      case PermissionStatus.granted:
        return l10n.permGranted;
      case PermissionStatus.denied:
        return l10n.permStatusDenied;
      case PermissionStatus.permanentlyDenied:
        return l10n.permPermanentlyDenied;
      default:
        return l10n.permNotGranted;
    }
  }

  Color _getPermissionColor(Permission permission) {
    final status = _permissions[permission];
    if (status == PermissionStatus.granted) return Colors.green;
    if (status == PermissionStatus.permanentlyDenied) return Colors.red;
    return Colors.orange;
  }
}
