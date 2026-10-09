import 'dart:io';

import 'package:flutter/material.dart';
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
      setState(() {
        _permissions[permission] = status;
        _statusMessage = status.isGranted ? grantedMessage : 'Permission denied';
      });
    }
    await _refreshAll();
  }

  Future<void> _enableCallScreening() async {
    final launched = await RoleService.requestCallScreening();
    if (!mounted) return;
    setState(() {
      _statusMessage = launched
          ? 'Confirm Call Manager for call screening'
          : 'Call screening is not available on this device';
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
    return Card(
      child: Column(
        children: [
          _checkTile(
            'Notification access',
            'Reads messages from notifications',
            _notificationAccess,
            _requestNotificationAccess,
          ),
          const Divider(height: 1),
          _checkTile(
            'Display over other apps',
            'Shows the scam alert while a call is ringing',
            _overlayGranted,
            _requestOverlay,
          ),
          const Divider(height: 1),
          _checkTile(
            'Alerts allowed',
            'Posts scam alerts as notifications',
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
    return ListTile(
      leading: Icon(
        ok ? Icons.check_circle : Icons.error_outline,
        color: ok ? Colors.green : Colors.orange,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: ok
          ? const Text('Granted')
          : TextButton(onPressed: onFix, child: const Text('Grant')),
    );
  }

  Widget _buildCallScreeningCard(BuildContext context) {
    final colors = context.theme.colors;
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
                const Expanded(
                  child: Text(
                    'Call screening role',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const Text(
              'Lets the app screen incoming calls and block numbers you mark '
              'as spam.',
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: _isCallScreening ? null : _enableCallScreening,
              child: Text(
                _isCallScreening ? 'Screening active' : 'Enable call screening',
              ),
            ),
            if (!_isCallScreening) ...[
              const SizedBox(height: 12),
              const FAlert(
                variant: FAlertVariant.destructive,
                title: Text('Call screening is not granted yet'),
                subtitle: Text(
                  'Tap "Enable call screening" above, otherwise calls will '
                  'still ring through.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppPermissionsCard(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, size: 28),
                SizedBox(width: 12),
                Text(
                  'Permissions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Grant the following permissions for full access.'),
            const SizedBox(height: 8),
            _buildPermissionTile(
              permission: Permission.phone,
              icon: Icons.phone,
              title: 'Phone & Call Log',
              grantedMessage: 'Phone permission granted',
            ),
            const FDivider(),
            _buildPermissionTile(
              permission: Permission.contacts,
              icon: Icons.contact_mail,
              title: 'Contacts',
              grantedMessage: 'Contacts permission granted',
            ),
            const FDivider(),
            _buildPermissionTile(
              permission: Permission.notification,
              icon: Icons.notifications,
              title: 'Notifications',
              grantedMessage: 'Notification permission granted',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootCard(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Still not working?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open the system settings for this app to manually assign the '
              'call screening role and permissions.',
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: _openAppSettings,
              prefix: const Icon(Icons.settings),
              child: const Text('Open App Settings'),
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
    return FTile(
      prefix: Icon(icon),
      title: Text(title),
      subtitle: Text(
        _getPermissionStatus(permission),
        style: TextStyle(color: _getPermissionColor(permission)),
      ),
      suffix: FButton(
        onPress: () => _requestPermission(permission, grantedMessage),
        size: FButtonSizeVariant.sm,
        mainAxisSize: MainAxisSize.min,
        child: const Text('Grant'),
      ),
    );
  }

  String _getPermissionStatus(Permission permission) {
    final status = _permissions[permission];
    if (status == null) return 'Not checked';
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently denied';
      default:
        return 'Not granted';
    }
  }

  Color _getPermissionColor(Permission permission) {
    final status = _permissions[permission];
    if (status == PermissionStatus.granted) return Colors.green;
    if (status == PermissionStatus.permanentlyDenied) return Colors.red;
    return Colors.orange;
  }
}
