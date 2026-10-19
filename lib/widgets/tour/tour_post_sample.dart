import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/models/api/community_models.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// A comment box with `@help` typed in, shown in the post tour bubble.
/// Non-interactive.
Widget buildTourSampleHelpComment(BuildContext context) {
  final theme = Theme.of(context);
  final tokens = context.tokens;
  final scheme = theme.colorScheme;
  return ExcludeSemantics(
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.lg,
        vertical: tokens.space.md,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: tokens.radii.mdRadius,
        border: Border.all(color: scheme.outlineVariant, width: 1.5),
      ),
      child: Text(
        '@help',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// A sample reply from the AI helper, with the "AI" badge, shown in the post
/// tour bubble. Non-interactive.
Widget buildTourSampleAiReply(BuildContext context) {
  final theme = Theme.of(context);
  final tokens = context.tokens;
  final scheme = theme.colorScheme;
  final l10n = AppLocalizations.of(context);
  return ExcludeSemantics(
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.space.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: tokens.radii.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  PostComment.botDisplayName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: tokens.space.xs),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space.sm,
                  vertical: tokens.space.xs,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: tokens.radii.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 14,
                      color: scheme.onSecondaryContainer,
                    ),
                    SizedBox(width: tokens.space.xs),
                    Text(
                      l10n.postDetailAiBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space.sm),
          Text(l10n.tourPostSampleReply, style: theme.textTheme.bodyLarge),
        ],
      ),
    ),
  );
}
