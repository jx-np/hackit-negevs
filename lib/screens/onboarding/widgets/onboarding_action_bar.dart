import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

import 'step_indicator.dart';

/// Bottom of every onboarding page: progress, one big primary button and an
/// optional quieter secondary button. Nothing here has a fixed height, so it
/// grows with large text instead of clipping.
class OnboardingActionBar extends StatelessWidget {
  const OnboardingActionBar({
    super.key,
    required this.pageCount,
    required this.pageIndex,
    required this.primaryLabel,
    required this.onPrimary,
    this.stepLabel,
    this.busy = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  final int pageCount;
  final int pageIndex;
  final String? stepLabel;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool busy;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space.xl,
        tokens.space.sm,
        tokens.space.xl,
        tokens.space.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepIndicator(count: pageCount, index: pageIndex, label: stepLabel),
          SizedBox(height: tokens.space.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 56,
              minWidth: double.infinity,
            ),
            child: FilledButton(
              onPressed: busy ? null : onPrimary,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: busy
                    ? const SizedBox(
                        key: ValueKey('busy'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        primaryLabel,
                        key: ValueKey(primaryLabel),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: tokens.space.xs),
          // Reserve the secondary button's space so the layout does not jump
          // between pages that have one and pages that don't.
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 48,
              minWidth: double.infinity,
            ),
            child: secondaryLabel == null
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: onSecondary,
                    child: Text(
                      secondaryLabel!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
