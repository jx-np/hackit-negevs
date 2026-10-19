import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/models/call_record.dart';
import 'package:scamwatch_mobile_app/screens/calls/widgets/call_record_tile.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/help/screen_help.dart';

/// Sample data for the Calls help sheet and tour. Numbers are fake.
int _sampleTime() => DateTime(2026, 1, 15, 9, 41).millisecondsSinceEpoch;

CallRecord sampleHighRiskCall() => CallRecord(
  rawNumber: '+60 11-0000 1234',
  normalizedNumber: '601100001234',
  timestamp: _sampleTime(),
  status: CallRecord.statusMissed,
  direction: CallRecord.directionIncoming,
  trustRating: CallRecord.ratingHighRisk,
);

CallRecord sampleNormalCall() => CallRecord(
  rawNumber: '+60 12-0000 5678',
  normalizedNumber: '601200005678',
  timestamp: _sampleTime(),
  status: CallRecord.statusAnswered,
  direction: CallRecord.directionIncoming,
  durationSeconds: 42,
  trustRating: CallRecord.ratingTrusted,
);

CallRecord sampleBlockedCall() => CallRecord(
  rawNumber: '+60 13-0000 9012',
  normalizedNumber: '601300009012',
  timestamp: _sampleTime(),
  status: CallRecord.statusBlocked,
  direction: CallRecord.directionIncoming,
);

/// The sample high-risk row shown inside the tour bubble.
Widget buildTourSampleCallRow(BuildContext context) => CallRecordTile(
  record: sampleHighRiskCall(),
  trailing: const CallMenuPreview(),
);

/// Legend for the Calls screen's help sheet.
List<HelpEntry> callsHelpEntries(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final tokens = context.tokens;
  final scheme = Theme.of(context).colorScheme;
  return [
    HelpEntry(
      visual: CallRecordTile(
        record: sampleHighRiskCall(),
        trailing: const CallMenuPreview(),
      ),
      title: l10n.helpCallsHighRiskTitle,
      body: l10n.helpCallsHighRiskBody,
    ),
    HelpEntry(
      visual: CallRecordTile(
        record: sampleNormalCall(),
        trailing: const CallMenuPreview(),
      ),
      title: l10n.helpCallsNormalTitle,
      body: l10n.helpCallsNormalBody,
    ),
    HelpEntry(
      visual: CallRecordTile(
        record: sampleBlockedCall(),
        isBlocked: true,
        trailing: const CallMenuPreview(),
      ),
      title: l10n.helpCallsBlockedRowTitle,
      body: l10n.helpCallsBlockedRowBody,
    ),
    HelpEntry(
      visual: const HelpIconChip(icon: LucideIcons.shieldBan),
      title: l10n.helpCallsBlockedListTitle,
      body: l10n.helpCallsBlockedListBody,
      inline: true,
    ),
    HelpEntry(
      visual: const HelpIconChip(icon: LucideIcons.ellipsis),
      title: l10n.helpCallsMenuTitle,
      body: l10n.helpCallsMenuBody,
      inline: true,
    ),
    HelpEntry(
      visual: const HelpIconChip(icon: LucideIcons.refreshCw),
      title: l10n.helpCallsRefreshTitle,
      body: l10n.helpCallsRefreshBody,
      inline: true,
    ),
    HelpEntry(
      visual: HelpIconChip(
        icon: LucideIcons.phoneMissed,
        color: tokens.risk.danger,
      ),
      title: l10n.callMissed,
      body: l10n.helpCallsMissedBody,
      inline: true,
    ),
    HelpEntry(
      visual: HelpIconChip(
        icon: LucideIcons.phoneIncoming,
        color: tokens.risk.safe,
      ),
      title: l10n.callAnswered,
      body: l10n.helpCallsAnsweredBody,
      inline: true,
    ),
    HelpEntry(
      visual: HelpIconChip(
        icon: LucideIcons.phoneOff,
        color: tokens.risk.warning,
      ),
      title: l10n.callRejected,
      body: l10n.helpCallsRejectedBody,
      inline: true,
    ),
    HelpEntry(
      visual: HelpIconChip(icon: LucideIcons.ban, color: scheme.error),
      title: l10n.callBlockedLabel,
      body: l10n.helpCallsBlockedIconBody,
      inline: true,
    ),
    HelpEntry(
      visual: const HelpIconChip(icon: LucideIcons.phoneOutgoing),
      title: l10n.callOutgoing,
      body: l10n.helpCallsOutgoingBody,
      inline: true,
    ),
  ];
}
