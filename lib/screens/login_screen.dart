import 'dart:io';

import 'package:call_log_app/main.dart';
import 'package:call_log_app/screens/permissions_onboarding_screen.dart';
import 'package:call_log_app/services/role_service.dart';
import 'package:call_log_app/services/scamshield_channels.dart';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    final ready = await _allPermissionsGranted();
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => ready
            ? const HomePage()
            : const PermissionsOnboardingScreen(),
      ),
    );
  }

  Future<bool> _allPermissionsGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final listener = await NotificationListenerService.isPermissionGranted();
      final overlay = await ScamShieldController.hasOverlayPermission();
      final alerts = await ScamShieldController.hasNotificationPermission();
      final screening = await RoleService.isCallScreening();
      final phone = await Permission.phone.isGranted;
      final contacts = await Permission.contacts.isGranted;
      final notifications = await Permission.notification.isGranted;
      return listener &&
          overlay &&
          alerts &&
          screening &&
          phone &&
          contacts &&
          notifications;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.shield, size: 96, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Call Manager',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Keeps you safe from scam calls and messages.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 68,
                child: FilledButton(
                  onPressed: _busy ? null : _start,
                  child: _busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
