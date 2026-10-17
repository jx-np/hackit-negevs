import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/models/call_record.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_card.dart';

/// One row in the call list: status icon, number, status line and an
/// optional [trailing] action (the "⋯" menu).
///
/// High-risk numbers get a red card, a red border and a "Likely scam" label,
/// so the warning does not rely on colour alone. The same widget renders the
/// sample rows in the tour and the Calls help sheet.
class CallRecordTile extends StatelessWidget {
  const CallRecordTile({
    super.key,
    required this.record,
    this.isBlocked = false,
    this.trailing,
  });

  final CallRecord record;
  final bool isBlocked;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final isHighRisk = record.isHighRisk;
    final accent = isBlocked
        ? scheme.error
        : isHighRisk
        ? tokens.risk.danger
        : callStatusColor(context, record);

    return AppCard(
      color: isHighRisk ? tokens.risk.dangerContainer : null,
      border: isHighRisk
          ? Border.all(color: tokens.risk.danger, width: 1.5)
          : null,
      padding: EdgeInsets.fromLTRB(
        tokens.space.lg,
        tokens.space.md,
        tokens.space.xs,
        tokens.space.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBlocked ? LucideIcons.ban : callStatusIcon(record),
                color: accent,
                size: 22,
              ),
            ),
          ),
          SizedBox(width: tokens.space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isHighRisk) ...[
                  _ScamLabel(text: l10n.callsLikelyScam),
                  SizedBox(height: tokens.space.xs),
                ],
                // Keep the number on one line; shrink it rather than wrap.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    record.rawNumber,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: tokens.space.xs),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: isBlocked
                            ? l10n.callBlockedLabel
                            : callStatusLabel(l10n, record),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (record.status == CallRecord.statusAnswered &&
                          record.durationSeconds > 0)
                        TextSpan(
                          text: l10n.callDurationSuffix(record.durationSeconds),
                        ),
                      if (record.reported)
                        TextSpan(
                          text: l10n.callReportedSuffix,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      TextSpan(
                        text: ' • ${formatCallTimestamp(l10n, record.timestamp)}',
                      ),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isHighRisk
                        ? tokens.risk.onDangerContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Look-alike of the row's "⋯" menu button, for sample rows.
class CallMenuPreview extends StatelessWidget {
  const CallMenuPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Icon(
        LucideIcons.ellipsis,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _ScamLabel extends StatelessWidget {
  const _ScamLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? tokens.risk.dangerContainer : Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tokens.risk.danger,
        borderRadius: tokens.radii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.octagonAlert, size: 14, color: foreground),
          SizedBox(width: tokens.space.xs),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Short label for a call's status ("Missed", "Answered", ...).
String callStatusLabel(AppLocalizations l10n, CallRecord record) {
  if (record.direction == CallRecord.directionOutgoing) {
    return l10n.callOutgoing;
  }
  switch (record.status) {
    case CallRecord.statusAnswered:
      return l10n.callAnswered;
    case CallRecord.statusRejected:
      return l10n.callRejected;
    case CallRecord.statusMissed:
      return l10n.callMissed;
    case CallRecord.statusBlocked:
      return l10n.callBlockedLabel;
    default:
      return l10n.commonUnknown;
  }
}

/// Accent colour for a call's status.
Color callStatusColor(BuildContext context, CallRecord record) {
  final tokens = context.tokens;
  final scheme = Theme.of(context).colorScheme;
  if (record.direction == CallRecord.directionOutgoing) {
    return scheme.primary;
  }
  switch (record.status) {
    case CallRecord.statusAnswered:
      return tokens.risk.safe;
    case CallRecord.statusRejected:
      return tokens.risk.warning;
    case CallRecord.statusMissed:
    case CallRecord.statusBlocked:
      return tokens.risk.danger;
    default:
      return scheme.onSurfaceVariant;
  }
}

/// Icon for a call's status.
IconData callStatusIcon(CallRecord record) {
  if (record.direction == CallRecord.directionOutgoing) {
    return LucideIcons.phoneOutgoing;
  }
  switch (record.status) {
    case CallRecord.statusAnswered:
      return LucideIcons.phoneIncoming;
    case CallRecord.statusRejected:
      return LucideIcons.phoneOff;
    case CallRecord.statusMissed:
      return LucideIcons.phoneMissed;
    case CallRecord.statusBlocked:
      return LucideIcons.ban;
    default:
      return LucideIcons.phone;
  }
}

/// "17/10/2026 09:41", or "Unknown" for a missing timestamp.
String formatCallTimestamp(AppLocalizations l10n, int timestamp) {
  if (timestamp <= 0) return l10n.commonUnknown;
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} $hour:$minute';
}
