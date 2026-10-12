import 'dart:io';

import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/role_service.dart';
import '../services/scamshield_channels.dart';

/// Every permission the app can ask for, in one place: the Scam Shield
/// service checks (notification listener access, overlay, alerts), the
/// runtime permissions (phone, contacts, notifications), and the call
/// screening role.
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
  String? _statusMessage;
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
      setState(() {
        _permissions[permission] = status;
        _statusMessage = status.isGranted ? grantedMessage : l10n.permDenied;
      });
    }
    await _refreshAll();
  }

  Future<void> _enableCallScreening() async {
    final launched = await RoleService.requestCallScreening();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _statusMessage = launched
          ? l10n.permConfirmScreening
          : l10n.permScreeningUnavailable;
    });
    await _refreshAll();
  }

  Future<void> _openAppSettings() async {
    if (Platform.isAndroid) {
      final uri = Uri.parse('package:com.example.call_log_app');
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
    final colors = context.theme.colors;
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_statusMessage != null) ...[
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.mutedForeground),
            ),
            const SizedBox(height: 12),
          ],
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

  Widget _buildServiceCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Column(
        children: [
          _checkTile(
            l10n.permNotificationAccess,
            l10n.permNotificationAccessSub,
            _notificationAccess,
            _requestNotificationAccess,
          ),
          const Divider(height: 1),
          _checkTile(
            l10n.permOverlay,
            l10n.permOverlaySub,
            _overlayGranted,
            _requestOverlay,
          ),
          const Divider(height: 1),
          _checkTile(
            l10n.permAlerts,
            l10n.permAlertsSub,
            _notificationPermission,
            _requestAlerts,
          ),
        ],
      ),
    );
  }

  Widget _checkTile(
    String title,
    String subtitle,
    bool ok,
    Future<void> Function() onFix,
  ) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(
        ok ? Icons.check_circle : Icons.error_outline,
        color: ok ? Colors.green : Colors.orange,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: ok
          ? Text(l10n.permGranted)
          : TextButton(onPressed: onFix, child: Text(l10n.permGrant)),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  _isCallScreening
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _isCallScreening ? Colors.green : colors.mutedForeground,
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
                Text(
                  l10n.permTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.permGrantFollowing),
            const SizedBox(height: 8),
            _buildPermissionTile(
              permission: Permission.phone,
              icon: Icons.phone,
              title: l10n.permPhoneCallLog,
              grantedMessage: l10n.permPhoneGranted,
            ),
            const FDivider(),
            _buildPermissionTile(
              permission: Permission.contacts,
              icon: Icons.contact_mail,
              title: l10n.permContacts,
              grantedMessage: l10n.permContactsGranted,
            ),
            const FDivider(),
            _buildPermissionTile(
              permission: Permission.notification,
              icon: Icons.notifications,
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
            Text(
              l10n.permStillNotWorking,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
    required IconData icon,
    required String title,
    required String grantedMessage,
  }) {
    final l10n = AppLocalizations.of(context);
    return FTile(
      prefix: Icon(icon),
      title: Text(title),
      subtitle: Text(
        _getPermissionStatus(l10n, permission),
        style: TextStyle(color: _getPermissionColor(permission)),
      ),
      suffix: FButton(
        onPress: () => _requestPermission(permission, grantedMessage),
        size: FButtonSizeVariant.sm,
        mainAxisSize: MainAxisSize.min,
        child: Text(l10n.permGrant),
      ),
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
