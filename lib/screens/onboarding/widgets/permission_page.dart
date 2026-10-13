import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../permission_step.dart';
import 'onboarding_illustration.dart';
import 'onboarding_page_layout.dart';

/// A single permission explained in plain words, with a short status note
/// underneath that updates as the permission changes.
class PermissionPage extends StatelessWidget {
  const PermissionPage({
    super.key,
    required this.controller,
    required this.index,
    required this.step,
    required this.status,
    required this.skipped,
    required this.stepNumber,
    required this.stepTotal,
  });

  final PageController controller;
  final int index;
  final PermissionStep step;
  final StepStatus status;

  /// The user tapped "Not now" or declined the system prompt.
  final bool skipped;
  final int stepNumber;
  final int stepTotal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingPageLayout(
      controller: controller,
      index: index,
      label: l10n.onboardingStepCount(stepNumber, stepTotal),
      illustration: OnboardingIllustration(
        icon: step.icon,
        done: status == StepStatus.granted,
      ),
      title: step.title(l10n),
      body: step.body(l10n),
      footer: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildNote(context, l10n),
      ),
    );
  }

  Widget _buildNote(BuildContext context, AppLocalizations l10n) {
    if (status == StepStatus.granted) {
      return _StatusNote(
        key: const ValueKey('granted'),
        icon: Icons.check_circle_rounded,
        text: l10n.onboardingStatusOn,
        color: kOnboardingDoneColor,
      );
    }
    final String text;
    if (status == StepStatus.blocked) {
      text = l10n.onboardingStatusBlocked;
    } else if (skipped) {
      text = l10n.onboardingStatusSkipped;
    } else if (step.opensSettings) {
      text = l10n.onboardingSettingsHint;
    } else {
      return const SizedBox.shrink(key: ValueKey('none'));
    }
    return _StatusNote(
      key: ValueKey(text),
      icon: Icons.info_outline_rounded,
      text: text,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({
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
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
