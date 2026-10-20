import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

import 'onboarding_illustration.dart';
import 'onboarding_page_layout.dart';
import 'status_note.dart';

/// Offers the scam checker download once. The button itself lives in the
/// onboarding action bar; this page shows the short explanation and inline
/// progress.
class ModelPage extends StatelessWidget {
  const ModelPage({
    super.key,
    required this.controller,
    required this.index,
    required this.ready,
    required this.downloading,
    required this.progress,
    required this.failed,
  });

  final PageController controller;
  final int index;
  final bool ready;
  final bool downloading;

  /// 0–100, or below 0 when unknown.
  final int progress;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingPageLayout(
      controller: controller,
      index: index,
      illustration: OnboardingIllustration(
        icon: LucideIcons.download,
        done: ready,
      ),
      title: l10n.onboardingModelTitle,
      body: l10n.onboardingModelBody,
      footer: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStatus(context, l10n),
      ),
    );
  }

  Widget _buildStatus(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    if (ready) {
      return OnboardingStatusNote(
        key: const ValueKey('ready'),
        icon: LucideIcons.circleCheck,
        text: l10n.onboardingModelReady,
        color: tokens.risk.safe,
      );
    }
    if (downloading) {
      final pct = progress.clamp(0, 100);
      return Semantics(
        key: const ValueKey('downloading'),
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: tokens.radii.pillRadius,
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress < 0 ? null : pct / 100,
              ),
            ),
            SizedBox(height: tokens.space.md),
            Text(
              l10n.onboardingModelDownloading(pct),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.space.xs),
            Text(
              l10n.onboardingModelKeepGoing,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    if (failed) {
      return OnboardingStatusNote(
        key: const ValueKey('failed'),
        icon: LucideIcons.info,
        text: l10n.onboardingModelFailed,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return const SizedBox.shrink(key: ValueKey('idle'));
  }
}
