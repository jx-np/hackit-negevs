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
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ready = await _allPermissionsGranted();
    if (!mounted) return;
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.phone, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Call Manager',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email or username',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
