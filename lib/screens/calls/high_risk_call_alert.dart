import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// A full-screen, hard-to-miss warning shown when a caller's number is rated
/// `high_risk` by the trust-score API.
///
/// Shown for an incoming/ongoing call from a high-risk number (see the call
/// history screen's call-event hook) and previewable from the dev menu. The
/// screen is intentionally loud: a saturated danger background, a large shield
/// icon, the offending number, and a single dismiss action.
class HighRiskCallAlert extends StatelessWidget {
  const HighRiskCallAlert({
    super.key,
    required this.phoneNumber,
    this.trustScore,
    this.reportCount,
  });

  /// The caller's number as dialed (shown verbatim to the user).
  final String phoneNumber;

  /// Trust score 0-100 (0 = risky). Null hides the score line.
  final int? trustScore;

  /// How many times the number was reported. Null/0 hides the count line.
  final int? reportCount;

  /// Pushes the alert as an opaque full-screen route. Returns when dismissed.
  static Future<void> show(
    BuildContext context, {
    required String phoneNumber,
    int? trustScore,
    int? reportCount,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => HighRiskCallAlert(
          phoneNumber: phoneNumber,
          trustScore: trustScore,
          reportCount: reportCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final risk = tokens.risk;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: risk.danger,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(tokens.space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  width: 112,
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.octagonAlert,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: tokens.space.xl),
                Text(
                  l10n.callHighRiskTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: tokens.space.md),
                Text(
                  l10n.callHighRiskBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                ),
                SizedBox(height: tokens.space.xl),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.space.lg,
                    vertical: tokens.space.md,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: tokens.radii.lgRadius,
                  ),
                  child: Column(
                    children: [
                      Text(
                        phoneNumber,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      if (trustScore != null) ...[
                        SizedBox(height: tokens.space.xs),
                        Text(
                          l10n.callHighRiskScore(trustScore!),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                        ),
                      ],
                      if (reportCount != null && reportCount! > 0) ...[
                        SizedBox(height: tokens.space.xs),
                        Text(
                          l10n.callHighRiskReports(reportCount!),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 60,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: risk.danger,
                      textStyle: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    child: Text(l10n.callHighRiskDismiss),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
