import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'onboarding_illustration.dart';
import 'onboarding_page_layout.dart';

/// First page: explains what is about to happen before any prompt appears.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.controller, required this.index});

  final PageController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OnboardingPageLayout(
      controller: controller,
      index: index,
       illustration: const OnboardingIllustration(icon: LucideIcons.shield),
      title: l10n.onboardingWelcomeTitle,
      body: l10n.onboardingWelcomeBody,
      footer: Text(
        l10n.onboardingWelcomeNote,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
