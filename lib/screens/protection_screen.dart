import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/role_service.dart';

class ProtectionScreen extends StatefulWidget {
  const ProtectionScreen({super.key});

  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen> {
  bool _spamProtectionEnabled = false;
  bool _isCallScreening = false;
  String? _statusMessage;
  Map<Permission, PermissionStatus> _permissions = {};

  @override
  void initState() {
    super.initState();
    _loadSpamPreference();
    _checkPermissions();
    _refreshRoles();
  }

  Future<void> _refreshAll() async {
    await _refreshRoles();
    await _checkPermissions();
  }

  Future<void> _refreshRoles() async {
    final screening = await RoleService.isCallScreening();
    if (mounted) {
      setState(() {
        _isCallScreening = screening;
      });
    }
  }

  Future<void> _loadSpamPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _spamProtectionEnabled =
            prefs.getBool('spam_protection_enabled') ?? false;
      });
    }
  }

  Future<void> _saveSpamPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spam_protection_enabled', enabled);
  }

  Future<void> _checkPermissions() async {
    final permissions = <Permission, PermissionStatus>{
      Permission.phone: await Permission.phone.status,
      Permission.contacts: await Permission.contacts.status,
      Permission.notification: await Permission.notification.status,
    };
    if (mounted) {
      setState(() {
        _permissions = permissions;
        _statusMessage = 'Review the settings below';
      });
    }
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
  }

  Future<void> _enableCallScreening() async {
    final launched = await RoleService.requestCallScreening();
    if (!mounted) return;
    setState(() {
      _statusMessage = launched
          ? 'Confirm Call Manager for call screening'
          : 'Call screening is not available on this device';
    });
    await _refreshRoles();
  }

  Future<void> _onSpamToggled(bool value) async {
    if (value && !_isCallScreening) {
      await _enableCallScreening();
      final held = await RoleService.isCallScreening();
      if (!mounted) return;
      setState(() => _isCallScreening = held);
      if (!held) {
        setState(() {
          _statusMessage =
              'Grant call screening first: tap "Enable call screening" above.';
        });
        return;
      }
    }
    await _saveSpamPreference(value);
    if (!mounted) return;
    setState(() {
      _spamProtectionEnabled = value;
      _statusMessage =
          value ? 'Spam protection enabled' : 'Spam protection disabled';
    });
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
    return FScaffold(
      childPad: false,
      header: FHeader.nested(
        title: const Text('Protection'),
        titleAlignment: Alignment.centerLeft,
        prefixes: [
          FHeaderAction(
            icon: const Icon(Icons.menu),
            semanticsLabel: 'Open menu',
            onPress: () => Scaffold.of(context).openDrawer(),
          ),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(Icons.refresh),
            semanticsLabel: 'Refresh',
            onPress: _refreshAll,
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Icon(Icons.security, size: 100, color: colors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Call Protection',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage ?? 'Tap below to configure',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.mutedForeground),
            ),
            const SizedBox(height: 24),
            _buildRoleCard(context),
            const SizedBox(height: 16),
            _buildPermissionCard(context),
            const SizedBox(height: 16),
            _buildTroubleshootCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context) {
    final colors = context.theme.colors;
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Spam & Call Protection',
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
            const SizedBox(height: 12),
            const FDivider(),
            const SizedBox(height: 4),
            FSwitch(
              value: _spamProtectionEnabled,
              label: const Text('Spam Protection'),
              description: const Text(
                'Block calls from numbers you marked as spam.',
              ),
              onChange: _onSpamToggled,
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

  Widget _buildPermissionCard(BuildContext context) {
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
