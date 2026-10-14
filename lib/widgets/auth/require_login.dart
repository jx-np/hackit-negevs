import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/screens/auth/login_register_screen.dart';
import 'package:scamwatch_mobile_app/state/auth_controller.dart';

/// Ensures the user is signed in before running a feature that needs an account
/// (anything that calls the backend, or the on-device model path that requires
/// a session).
///
/// The app is usable without an account, so sign-in is only prompted on demand.
/// If the user is already signed in this returns `true` immediately. Otherwise
/// it pushes [LoginRegisterScreen]; that screen pops itself with `true` once
/// sign-in succeeds (see its listener). The returned future completes with
/// `true` when the user is signed in by the time the gate resolves, or `false`
/// if they backed out without signing in.
///
/// This is a standalone helper — call it from a feature's entry point when that
/// feature needs auth. It is intentionally not wired into any feature yet.
///
/// ```dart
/// if (await requireLogin(context)) {
///   // ...proceed with the account-gated action
/// }
/// ```
Future<bool> requireLogin(BuildContext context) async {
  final auth = context.read<AuthController>();
  if (auth.isSignedIn) return true;

  final navigator = Navigator.of(context);
  final result = await navigator.push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => const LoginRegisterScreen(),
    ),
  );

  // The screen pops `true` on success; a manual back-out pops `null`. Fall back
  // to the live auth state so we don't misreport if the pop value is lost.
  return result ?? auth.isSignedIn;
}
