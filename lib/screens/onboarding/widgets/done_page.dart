import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'onboarding_illustration.dart';
import 'onboarding_page_layout.dart';

/// Last page: a short summary of how many protections are on.
class DonePage extends StatelessWidget {
  const DonePage({
    super.key,
    required this.controller,
    required this.index,
    required this.grantedCount,
    required this.total,
  });

  final PageController controller;
  final int index;
  final int grantedCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allOn = grantedCount >= total;
    return OnboardingPageLayout(
      controller: controller,
      index: index,
      illustration: OnboardingIllustration(
         icon: LucideIcons.shieldCheck,
        done: allOn,
      ),
      title: allOn ? l10n.onboardingDoneTitle : l10n.onboardingDonePartialTitle,
      body: allOn ? l10n.onboardingDoneBody : l10n.onboardingDonePartialBody,
      footer: allOn
          ? null
          : Text(
              l10n.onboardingGrantedCount(grantedCount, total),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
