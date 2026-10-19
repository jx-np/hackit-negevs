import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/auth/require_login.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_controller.dart';

import '../../state/auth_controller.dart';

/// Wraps a screen that needs an account. When the user is signed in the [child]
/// is shown as-is. When signed out the child is rendered underneath a blurred,
/// dimmed overlay with a centered card prompting sign-in — so the feature is
/// visible but locked until they authenticate.
///
/// This replaces the old top-of-app sign-in banner: instead of nagging on every
/// screen, each account-gated screen (Safety, Report, My Posts) gates itself.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.select<AuthController, bool>(
      (auth) => auth.isSignedIn,
    );

    if (isSignedIn) return child;

    // While the app tour runs, show the real screen unblurred so the coach
    // mark can spotlight its content. The tour scrim already blocks input.
    // The child stays at the same position in the Stack either way, so its
    // state survives the overlay appearing or disappearing.
    final tourActive = _isTourActive(context);

    return Stack(
      children: [
        // The real screen, kept visible but non-interactive behind the gate.
        Positioned.fill(
          child: IgnorePointer(child: child),
        ),
        if (!tourActive) const Positioned.fill(child: _AuthGateOverlay()),
      ],
    );
  }

  /// True while the tour is running. False when no [TourController] is
  /// provided (e.g. in tests).
  static bool _isTourActive(BuildContext context) {
    try {
      return context.select<TourController, bool>((tour) => tour.active);
    } on ProviderNotFoundException {
      return false;
    }
  }
}

class _AuthGateOverlay extends StatelessWidget {
  const _AuthGateOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        // Soft scrim tinted toward the surface so the blur reads as frosted
        // glass rather than a flat gray wash.
        color: scheme.surface.withValues(alpha: isDark ? 0.55 : 0.6),
        alignment: Alignment.center,
        padding: EdgeInsets.all(tokens.space.xl), // 24
        child: SingleChildScrollView(
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: EdgeInsets.all(tokens.space.xl2), // 32
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: tokens.radii.xlRadius,
              boxShadow: tokens.elevation.raised,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accent glow behind the lock glyph for a confident peak moment.
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.lock,
                    size: 40,
                    color: scheme.primary,
                  ),
                ),
                SizedBox(height: tokens.space.xl), // 24
                Text(
                  l10n.authGateTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.space.sm), // 8
                Text(
                  l10n.authGateBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: tokens.space.xl2), // 32
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: () => requireLogin(context),
                    icon: const Icon(LucideIcons.logIn, size: 22),
                    label: Text(
                      l10n.authGateAction,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
