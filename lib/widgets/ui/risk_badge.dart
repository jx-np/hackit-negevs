import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// The three risk states surfaced across the app: a message/number is safe,
/// suspicious, or a confirmed scam. Maps to [AppRiskColors].
enum RiskLevel { safe, warning, danger }

extension RiskLevelVisuals on RiskLevel {
  IconData get icon {
    switch (this) {
      case RiskLevel.safe:
        return LucideIcons.shieldCheck;
      case RiskLevel.warning:
        return LucideIcons.triangleAlert;
      case RiskLevel.danger:
        return LucideIcons.octagonAlert;
    }
  }
}

/// Resolve the strong / container / on-container colors for a [RiskLevel]
/// from the current theme's [AppRiskColors].
({Color strong, Color container, Color onContainer}) riskColorsFor(
  BuildContext context,
  RiskLevel level,
) {
  final r = context.tokens.risk;
  switch (level) {
    case RiskLevel.safe:
      return (
        strong: r.safe,
        container: r.safeContainer,
        onContainer: r.onSafeContainer,
      );
    case RiskLevel.warning:
      return (
        strong: r.warning,
        container: r.warningContainer,
        onContainer: r.onWarningContainer,
      );
    case RiskLevel.danger:
      return (
        strong: r.danger,
        container: r.dangerContainer,
        onContainer: r.onDangerContainer,
      );
  }
}

/// A compact pill that communicates a [RiskLevel] with an icon + label on a
/// soft tinted background. Use for verdicts, number reputations, post flairs.
class RiskBadge extends StatelessWidget {
  const RiskBadge({
    super.key,
    required this.level,
    required this.label,
    this.compact = false,
  });

  final RiskLevel level;
  final String label;

  /// Drop the icon and tighten padding for inline/dense placements.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = riskColorsFor(context, level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? tokens.space.sm : tokens.space.md,
        vertical: tokens.space.xs,
      ),
      decoration: BoxDecoration(
        color: c.container,
        borderRadius: tokens.radii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(level.icon, size: 15, color: c.onContainer),
            SizedBox(width: tokens.space.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: c.onContainer,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
