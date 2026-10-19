import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// A friendly empty state: icon in a soft tinted circle, a title, a supporting
/// line, and an optional call to action. Turns dead ends into guidance.
///
/// Reads [AppTokens] so spacing and color adapt to light/dark automatically.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.tint,
  });

  /// Leading glyph shown inside the soft circle.
  final IconData icon;

  /// Short, encouraging headline.
  final String title;

  /// Optional supporting sentence under the title.
  final String? message;

  /// Optional CTA (usually a button) shown under the message.
  final Widget? action;

  /// Override the accent tint for the icon circle. Defaults to the primary.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = tint ?? scheme.primary;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.space.xl2), // 32
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: accent),
            ),
            SizedBox(height: tokens.space.lg), // 16
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            if (message != null) ...[
              SizedBox(height: tokens.space.sm), // 8
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: tokens.space.xl), // 24
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
