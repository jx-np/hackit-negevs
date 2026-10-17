import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_controller.dart';

/// Per-screen help: a "?" app-bar button that opens a bottom sheet legend.
///
/// Each screen describes what its icons, colours and rows mean as a list of
/// [HelpEntry]s, usually with a small sample of the real UI as the visual.
///
/// ```dart
/// AppScreen(
///   title: l10n.myScreenTitle,
///   actions: [
///     HelpButton(
///       title: l10n.helpMyScreenTitle,
///       entries: (context) => [
///         HelpEntry(
///           visual: const HelpIconChip(icon: LucideIcons.bell),
///           title: l10n.helpBellTitle,
///           body: l10n.helpBellBody,
///           inline: true,
///         ),
///       ],
///     ),
///   ],
///   body: ...,
/// );
/// ```
///
/// To spotlight the button in the app tour, pass a key from
/// `CoachMarkTargets.keyOf(context, TourTarget.x)` as [HelpButton.key].

/// One row in the help sheet: a picture plus a short title and body.
class HelpEntry {
  const HelpEntry({
    required this.visual,
    required this.title,
    required this.body,
    this.inline = false,
  });

  /// A sample card, an icon chip, or any small widget. It is shown
  /// non-interactive, so live widgets are safe to reuse here.
  final Widget visual;

  /// Bold, a few words.
  final String title;

  /// One short sentence.
  final String body;

  /// Put [visual] beside the text instead of above it. Use for small visuals
  /// such as [HelpIconChip].
  final bool inline;
}

/// A round, tinted chip holding one icon. Use as a [HelpEntry.visual] to
/// explain what an icon means.
class HelpIconChip extends StatelessWidget {
  const HelpIconChip({super.key, required this.icon, this.color});

  final IconData icon;

  /// Icon colour. Defaults to the theme's primary colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 24, color: accent),
    );
  }
}

/// App-bar "?" button that opens [showScreenHelp]. 48x48 dp, labelled "Help".
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, required this.title, required this.entries});

  /// Sheet heading, e.g. "What things mean".
  final String title;

  /// Builds the entries when the sheet opens, so they follow the locale.
  final List<HelpEntry> Function(BuildContext context) entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.helpTooltip,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: const Icon(LucideIcons.circleHelp),
      onPressed: () =>
          showScreenHelp(context, title: title, entries: entries(context)),
    );
  }
}

/// Opens the help sheet for a screen.
///
/// Shows [entries] in a scrollable, draggable bottom sheet with a large
/// "Got it" button. When a [TourController] is available (and
/// [showTourButton] is true) it also offers "Show the app tour again".
Future<void> showScreenHelp(
  BuildContext context, {
  required String title,
  required List<HelpEntry> entries,
  bool showTourButton = true,
}) {
  TourController? tour;
  if (showTourButton) {
    try {
      tour = Provider.of<TourController>(context, listen: false);
    } on ProviderNotFoundException {
      tour = null;
    }
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _HelpSheet(
      title: title,
      entries: entries,
      onStartTour: tour == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              tour!.start();
            },
    ),
  );
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet({
    required this.title,
    required this.entries,
    required this.onStartTour,
  });

  final String title;
  final List<HelpEntry> entries;
  final VoidCallback? onStartTour;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                tokens.space.xl,
                0,
                tokens.space.xl,
                tokens.space.lg,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final entry in entries) ...[
                  SizedBox(height: tokens.space.xl),
                  _HelpEntryView(entry: entry),
                ],
                if (onStartTour != null) ...[
                  SizedBox(height: tokens.space.xl2),
                  OutlinedButton.icon(
                    onPressed: onStartTour,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    icon: const Icon(LucideIcons.circlePlay),
                    label: Text(l10n.helpShowTour, textAlign: TextAlign.center),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.space.xl,
                tokens.space.sm,
                tokens.space.xl,
                tokens.space.lg,
              ),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(l10n.helpGotIt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpEntryView extends StatelessWidget {
  const _HelpEntryView({required this.entry});

  final HelpEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final visual = IgnorePointer(child: entry.visual);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.space.xs),
        Text(entry.body, style: theme.textTheme.bodyLarge),
      ],
    );

    return Semantics(
      container: true,
      child: entry.inline
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                visual,
                SizedBox(width: tokens.space.lg),
                Expanded(child: text),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [visual, SizedBox(height: tokens.space.md), text],
            ),
    );
  }
}
