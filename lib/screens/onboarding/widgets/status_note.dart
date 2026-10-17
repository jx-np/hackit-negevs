import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// Short status line in a soft tinted box (e.g. "Turned on."). Announced to
/// screen readers when it changes.
class OnboardingStatusNote extends StatelessWidget {
  const OnboardingStatusNote({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(tokens.space.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: tokens.radii.lgRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(width: tokens.space.md),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
