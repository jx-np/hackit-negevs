import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

import '../permission_step.dart';
import 'onboarding_illustration.dart';
import 'onboarding_page_layout.dart';
import 'status_note.dart';

/// A single permission in one short sentence, with a status note underneath
/// that updates as the permission changes. Extra detail, when there is any,
/// sits behind a small "Why?" button.
class PermissionPage extends StatelessWidget {
  const PermissionPage({
    super.key,
    required this.controller,
    required this.index,
    required this.step,
    required this.status,
    required this.skipped,
  });

  final PageController controller;
  final int index;
  final PermissionStep step;
  final StepStatus status;

  /// The user tapped "Not now" or declined the system prompt.
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final why = step.why(l10n);
    final note = _buildNote(context, l10n);
    return OnboardingPageLayout(
      controller: controller,
      index: index,
      illustration: OnboardingIllustration(
        icon: step.icon,
        done: status == StepStatus.granted,
      ),
      title: step.title(l10n),
      body: step.body(l10n),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: note,
          ),
          if (why != null && status != StepStatus.granted) ...[
            SizedBox(height: context.tokens.space.sm),
            _WhyButton(text: why),
          ],
        ],
      ),
    );
  }

  Widget _buildNote(BuildContext context, AppLocalizations l10n) {
    if (status == StepStatus.granted) {
      return OnboardingStatusNote(
        key: const ValueKey('granted'),
        icon: LucideIcons.circleCheck,
        text: l10n.onboardingStatusOn,
        color: context.tokens.risk.safe,
      );
    }
    final String text;
    if (status == StepStatus.blocked) {
      text = l10n.onboardingStatusBlocked;
    } else if (skipped) {
      text = l10n.onboardingStatusSkipped;
    } else if (step.opensSettings) {
      text = step.settingsHint(l10n);
    } else {
      return const SizedBox.shrink(key: ValueKey('none'));
    }
    return OnboardingStatusNote(
      key: ValueKey(text),
      icon: LucideIcons.info,
      text: text,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

/// Small "Why?" text button that reveals one extra sentence.
class _WhyButton extends StatefulWidget {
  const _WhyButton({required this.text});

  final String text;

  @override
  State<_WhyButton> createState() => _WhyButtonState();
}

class _WhyButtonState extends State<_WhyButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: Icon(
              _open ? LucideIcons.chevronUp : LucideIcons.circleHelp,
            ),
            label: Text(l10n.onboardingWhy),
          ),
          if (_open)
            Semantics(
              liveRegion: true,
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
