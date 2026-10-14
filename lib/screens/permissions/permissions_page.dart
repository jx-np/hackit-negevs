import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshAll();
    });
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
    final results = await Future.wait<dynamic>([
      Platform.isAndroid
          ? NotificationListenerService.isPermissionGranted()
          : Future<bool>.value(false),
      ScamShieldController.hasOverlayPermission(),
      ScamShieldController.hasNotificationPermission(),
      RoleService.isCallScreening(),
      Permission.phone.status,
      Permission.contacts.status,
      Permission.notification.status,
    ]);
    if (!mounted) return;
    final access = results[0] as bool;
    final overlay = results[1] as bool;
    final alerts = results[2] as bool;
    final screening = results[3] as bool;
    final permissions = <Permission, PermissionStatus>{
      Permission.phone: results[4] as PermissionStatus,
      Permission.contacts: results[5] as PermissionStatus,
      Permission.notification: results[6] as PermissionStatus,
    };
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
    try {
      await openAppSettings();
    } catch (_) {
      _showStatus('Could not open app settings.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: context.tokens.space.sm,
          vertical: context.tokens.space.lg,
        ),
        children: [
          _buildIntroCard(context),
          SizedBox(height: context.tokens.space.lg),
          _buildServiceCard(context),
          SizedBox(height: context.tokens.space.lg),
          _buildCallScreeningCard(context),
          SizedBox(height: context.tokens.space.lg),
          _buildAppPermissionsCard(context),
          SizedBox(height: context.tokens.space.lg),
          _buildTroubleshootCard(context),
        ],
      ),
    );
  }

  // Calm, plain-language intro that replaces the old floating status line.
  Widget _buildIntroCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.lg,
        vertical: tokens.space.xl,
      ),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.shieldCheck, size: 28, color: tokens.risk.safe),
            SizedBox(width: tokens.space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.permTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: tokens.space.xs),
                  Text(
                    l10n.permGrantFollowing,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.lg,
        vertical: tokens.space.xl,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _checkTile(
              l10n.permNotificationAccess,
              l10n.permNotificationAccessSub,
              _notificationAccess,
              _requestNotificationAccess,
            ),
            Divider(height: tokens.space.lg),
            _checkTile(
              l10n.permOverlay,
              l10n.permOverlaySub,
              _overlayGranted,
              _requestOverlay,
            ),
            Divider(height: tokens.space.lg),
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
    return _permissionRow(
      title: title,
      subtitle: subtitle,
      granted: ok,
      statusColor: ok ? context.tokens.risk.safe : context.tokens.risk.danger,
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
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(granted ? LucideIcons.circleCheck : LucideIcons.circleAlert,
            color: granted ? tokens.risk.safe : tokens.risk.danger),
        SizedBox(width: tokens.space.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: tokens.space.xs),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: statusColor)),
        ])),
        SizedBox(width: tokens.space.md),
        granted
          ? Icon(LucideIcons.check, size: 18, color: tokens.risk.safe)
          : FilledButton(
              onPressed: onGrant,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              child: Text(l10n.permGrant),
            ),
      ],
    );
  }

  Widget _buildCallScreeningCard(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.lg,
        vertical: tokens.space.xl,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.phoneCall, size: 28),
                SizedBox(width: tokens.space.md),
                Expanded(
                  child: Text(
                    l10n.permScreeningRole,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(
                  _isCallScreening
                       ? LucideIcons.circleCheck
                       : LucideIcons.circle,
                    color: _isCallScreening ? tokens.risk.safe : scheme.onSurfaceVariant,
                ),
              ],
            ),
            SizedBox(height: tokens.space.sm),
            Text(l10n.permScreeningRoleSub, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            SizedBox(height: tokens.space.lg),
            FilledButton(
              onPressed: _isCallScreening ? null : _enableCallScreening,
              child: Text(
                _isCallScreening
                    ? l10n.permScreeningActive
                    : l10n.permEnableScreening,
              ),
            ),
            if (!_isCallScreening) ...[
              SizedBox(height: tokens.space.md),
              Container(
                padding: EdgeInsets.all(tokens.space.lg),
                decoration: BoxDecoration(color: tokens.risk.warningContainer, borderRadius: tokens.radii.mdRadius),
                child: Row(children: [
                  Icon(LucideIcons.circleAlert, color: tokens.risk.onWarningContainer),
                  SizedBox(width: tokens.space.md),
                  Expanded(child: Text('${l10n.permScreeningNotGranted}\n${l10n.permScreeningTapHint}', style: TextStyle(color: tokens.risk.onWarningContainer))),
                ]),
              ),
            ],
          ],
      ),
    );
  }

  Widget _buildAppPermissionsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.lg,
        vertical: tokens.space.xl,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.settings, size: 28),
                SizedBox(width: tokens.space.md),
                Expanded(
                  child: Text(
                    l10n.permTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: scheme.onSurface),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space.sm),
            Text(l10n.permGrantFollowing, style: TextStyle(color: scheme.onSurfaceVariant)),
            SizedBox(height: tokens.space.sm),
            _buildPermissionTile(
              permission: Permission.phone,
              title: l10n.permPhoneCallLog,
              grantedMessage: l10n.permPhoneGranted,
            ),
            Divider(height: tokens.space.lg),
            _buildPermissionTile(
              permission: Permission.contacts,
              title: l10n.permContacts,
              grantedMessage: l10n.permContactsGranted,
            ),
            Divider(height: tokens.space.lg),
            _buildPermissionTile(
              permission: Permission.notification,
              title: l10n.permNotifications,
              grantedMessage: l10n.permNotificationsGranted,
            ),
          ],
      ),
    );
  }

  Widget _buildTroubleshootCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.lg,
        vertical: tokens.space.xl,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.wrench, size: 28),
                SizedBox(width: tokens.space.md),
                Expanded(
                  child: Text(
                    l10n.permStillNotWorking,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: scheme.onSurface),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space.sm),
            Text(l10n.permOpenSettingsBody, style: TextStyle(color: scheme.onSurfaceVariant)),
            SizedBox(height: tokens.space.lg),
            FilledButton.icon(
              onPressed: _openAppSettings,
              icon: const Icon(LucideIcons.settings),
              label: Text(l10n.permOpenAppSettings),
            ),
          ],
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
    if (status == PermissionStatus.granted) return context.tokens.risk.safe;
    if (status == PermissionStatus.permanentlyDenied || status == PermissionStatus.denied) {
      return context.tokens.risk.danger;
    }
    return context.tokens.risk.warning;
  }
}
