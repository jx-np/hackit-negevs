import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/api/api_client.dart';
import 'package:scamwatch_mobile_app/api/api_exception.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/models/api/detection_models.dart';
import 'package:scamwatch_mobile_app/services/api/detection_service.dart';
import 'package:scamwatch_mobile_app/services/call_database.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_card.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';
import 'package:scamwatch_mobile_app/widgets/ui/risk_badge.dart';

/// A dedicated screen that checks one phone number's trust score and shows the
/// result in large, unambiguous text — the number being checked and a clear
/// verdict (high risk / no reports / looks safe). Replaces the old bottom
/// snackbar so the outcome is impossible to miss.
///
/// The screen performs the lookup itself so it can render a loading state,
/// then the verdict. It persists the rating via [CallDatabase.setTrustByNumber]
/// (keyed on [normalizedNumber]) exactly like the automatic history check, so
/// the matching row's color stays in sync. Pass [onResult] to let the opener
/// refresh its list after the verdict lands.
class NumberCheckScreen extends StatefulWidget {
  const NumberCheckScreen({
    super.key,
    required this.rawNumber,
    required this.normalizedNumber,
    this.onResult,
  });

  /// The number as dialed, shown verbatim to the user.
  final String rawNumber;

  /// The digits-only key used to cache the verdict in the call database.
  final String normalizedNumber;

  /// Called once a verdict is stored so the opener can refresh its rows.
  final VoidCallback? onResult;

  @override
  State<NumberCheckScreen> createState() => _NumberCheckScreenState();
}

/// What the lookup produced, used to pick the headline + colors.
enum _CheckOutcome { loading, highRisk, trusted, unknown, failed }

class _NumberCheckScreenState extends State<NumberCheckScreen> {
  _CheckOutcome _outcome = _CheckOutcome.loading;
  PhoneTrustScore? _score;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _outcome = _CheckOutcome.loading;
      _score = null;
    });
    final detection = DetectionService(context.read<ApiClient>());
    PhoneTrustScore? score;
    try {
      score = await detection.phoneTrustScore(widget.rawNumber);
      await CallDatabase.instance.setTrustByNumber(
        widget.normalizedNumber,
        trustScore: score.trustScore,
        trustRating: score.rating,
      );
    } on ApiException {
      score = null;
    } catch (_) {
      score = null;
    }
    if (!mounted) return;
    // Let the opener refresh its list so the cached verdict shows on the row.
    widget.onResult?.call();
    setState(() {
      _score = score;
      if (score == null) {
        _outcome = _CheckOutcome.failed;
      } else if (score.isHighRisk) {
        _outcome = _CheckOutcome.highRisk;
      } else if (score.isTrusted) {
        _outcome = _CheckOutcome.trusted;
      } else {
        _outcome = _CheckOutcome.unknown;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScreen(
      title: l10n.callCheckTitle,
      scrollable: true,
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    // The number under inspection, always shown at the top.
    final numberCard = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.callCheckNumberLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.space.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              widget.rawNumber,
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: tokens.space.md),
        numberCard,
        SizedBox(height: tokens.space.lg),
        if (_outcome == _CheckOutcome.loading)
          _loadingCard(context, l10n)
        else
          _resultCard(context, l10n),
      ],
    );
  }

  Widget _loadingCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return AppCard(
      child: Column(
        children: [
          SizedBox(height: tokens.space.lg),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: tokens.space.lg),
          Text(
            l10n.callChecking,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.space.lg),
        ],
      ),
    );
  }

  Widget _resultCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    // Pick colors, icon, headline and detail per outcome.
    final RiskLevel? level = switch (_outcome) {
      _CheckOutcome.highRisk => RiskLevel.danger,
      _CheckOutcome.unknown => RiskLevel.warning,
      _CheckOutcome.trusted => RiskLevel.safe,
      _ => null,
    };

    final ({Color strong, Color container, Color onContainer}) colors =
        level == null
            ? (
                strong: theme.colorScheme.onSurfaceVariant,
                container: theme.colorScheme.surfaceContainerHighest,
                onContainer: theme.colorScheme.onSurface,
              )
            : riskColorsFor(context, level);

    final IconData icon = switch (_outcome) {
      _CheckOutcome.highRisk => RiskLevel.danger.icon,
      _CheckOutcome.unknown => RiskLevel.warning.icon,
      _CheckOutcome.trusted => RiskLevel.safe.icon,
      _ => Icons.help_outline,
    };

    final String headline = switch (_outcome) {
      _CheckOutcome.highRisk => l10n.callCheckResultHighRisk,
      _CheckOutcome.unknown => l10n.callCheckResultUnknown,
      _CheckOutcome.trusted => l10n.callCheckResultSafe,
      _ => l10n.callCheckResultFailed,
    };

    final String detail = switch (_outcome) {
      _CheckOutcome.highRisk => l10n.callCheckDetailHighRisk,
      _CheckOutcome.unknown => l10n.callCheckDetailUnknown,
      _CheckOutcome.trusted => l10n.callCheckDetailSafe,
      _ => l10n.callCheckDetailFailed,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: colors.container,
          child: Column(
            children: [
              SizedBox(height: tokens.space.sm),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.strong.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: colors.strong),
              ),
              SizedBox(height: tokens.space.lg),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.onContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: tokens.space.md),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onContainer.withValues(alpha: 0.9),
                ),
              ),
              if (_score != null && _score!.known) ...[
                SizedBox(height: tokens.space.lg),
                _scoreStats(context, l10n, colors.onContainer),
              ],
              SizedBox(height: tokens.space.sm),
            ],
          ),
        ),
        if (_outcome == _CheckOutcome.failed) ...[
          SizedBox(height: tokens.space.lg),
          FilledButton.icon(
            onPressed: _check,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.commonRetry),
          ),
        ],
      ],
    );
  }

  Widget _scoreStats(
    BuildContext context,
    AppLocalizations l10n,
    Color onContainer,
  ) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final score = _score!;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: onContainer.withValues(alpha: 0.9),
      fontWeight: FontWeight.w600,
    );
    return Column(
      children: [
        Text(l10n.callCheckScore(score.trustScore), style: style),
        if (score.reportCount > 0) ...[
          SizedBox(height: tokens.space.xs),
          Text(l10n.callCheckReports(score.reportCount), style: style),
        ],
      ],
    );
  }
}
