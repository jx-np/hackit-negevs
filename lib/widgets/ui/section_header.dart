import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// A section title with an optional trailing action (e.g. a "Clear" button).
///
/// Used to introduce a group of content on a screen. The title uses
/// `titleLarge` (bold w700 per the Material text theme), and the optional
/// [caption] sits below in muted body text.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
  });

  final String title;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space.md), // 12
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (caption != null) ...[
                  SizedBox(height: tokens.space.xs), // 4
                  Text(
                    caption!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: tokens.space.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
