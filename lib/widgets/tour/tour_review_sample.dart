import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// A ticked copy of the Report tab's review checkbox, shown in the tour bubble
/// because the real one only exists once photos are attached. Non-interactive.
Widget buildTourSampleReviewTick(BuildContext context) {
  final theme = Theme.of(context);
  final tokens = context.tokens;
  final scheme = theme.colorScheme;
  return ExcludeSemantics(
    child: Container(
      padding: EdgeInsets.all(tokens.space.md),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: tokens.radii.mdRadius,
        border: Border.all(color: scheme.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Checkbox(value: true, onChanged: (_) {}),
          SizedBox(width: tokens.space.sm),
          Expanded(
            child: Text(
              AppLocalizations.of(context).reportTabReviewCheckbox,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
