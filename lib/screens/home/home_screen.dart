import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/api/api_client.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/models/api/news_models.dart';
import 'package:scamwatch_mobile_app/services/api/news_service.dart';
import 'package:scamwatch_mobile_app/services/protection_settings.dart';
import 'package:scamwatch_mobile_app/services/scamshield_channels.dart';
import 'package:scamwatch_mobile_app/state/auth_controller.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_card.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_models.dart';

/// Bottom-nav tab indices this screen links to. Kept in sync with the
/// `_items` list in `HomePage` (lib/main.dart).
const int _kCallsTab = 1;
const int _kSafetyTab = 2;
const int _kReportTab = 3;
const int _kProfileTab = 4;

/// The app's landing screen, designed for older users. Top to bottom:
///
/// 1. A protection status card that answers "am I safe right now?" at a
///    glance, with one clear button to see details or fix a problem.
/// 2. A swipeable scam-alerts carousel with big previous/next buttons, and a
///    "Read more" sheet for the full article.
/// 3. Large tappable cards that lead to the other main features.
///
/// Nothing here navigates by itself — it calls [onNavigate] with the
/// destination bottom-nav tab index so the shell ([HomePage]) stays the single
/// owner of tab selection.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Switches the app to the given bottom-nav tab index.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AppScreen(
      title: AppLocalizations.of(context).homeTitle,
      titleWidget: _HomeHeaderTitle(onNavigate: onNavigate),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyedSubtree(
            key: CoachMarkTargets.keyOf(context, TourTarget.homeStatus),
            child: _ProtectionStatusCard(onOpen: () => onNavigate(_kSafetyTab)),
          ),
          SizedBox(height: tokens.space.xl2),
          const _NewsBanner(),
          SizedBox(height: tokens.space.xl2),
          _QuickActions(onNavigate: onNavigate),
        ],
      ),
    );
  }
}

/// The greeting shown as the home app-bar title. One compact, tappable line
/// with three states:
///
/// * **Signed in with a name** — "Welcome, {name}", the name tinted.
/// * **Signed out** — just "Welcome" (no trailing comma, no guest label).
/// * **Loading** — while auth is still bootstrapping (status `unknown`), or
///   signed in but the display name hasn't arrived yet, the name is replaced
///   with a shimmering skeleton box so the header doesn't flicker between a
///   guest label and the real name.
///
/// Tapping it switches to the Profile tab, which owns both the signed-in
/// details and the signed-out login prompt itself.
///
/// Rendered inside [AppScreen]'s app bar, so it inherits the standard
/// `titleLarge` app-bar text style — the same header size every other page
/// uses. Only the person's name is tinted; the rest flows from the app bar.
class _HomeHeaderTitle extends StatelessWidget {
  const _HomeHeaderTitle({required this.onNavigate});

  /// Switches the app to the given bottom-nav tab index.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;

    final auth = context.watch<AuthController>();
    final name = auth.user?.displayName.trim() ?? '';
    final hasName = auth.isSignedIn && name.isNotEmpty;

    // Loading window: bootstrap hasn't resolved yet, or we're signed in but
    // the display name hasn't loaded. Stand a skeleton in for the name so we
    // don't briefly show the guest label to someone who is actually signed in.
    final isLoading =
        auth.status == AuthStatus.unknown ||
        (auth.isSignedIn && name.isEmpty);

    final Widget greeting;
    if (isLoading) {
      greeting = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: l10n.homeWelcomePrefix),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: const _HeaderNameSkeleton(),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (hasName) {
      greeting = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: l10n.homeWelcomePrefix),
            TextSpan(text: name, style: TextStyle(color: scheme.primary)),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      // Signed out: just "Welcome", with no trailing comma or guest label.
      greeting = Text(
        l10n.homeWelcomeGuest,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return InkWell(
      // The greeting taps through to the Profile tab, which owns both the
      // signed-in details and the signed-out login prompt itself.
      onTap: () => onNavigate(_kProfileTab),
      borderRadius: tokens.radii.mdRadius,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.space.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: greeting),
            SizedBox(width: tokens.space.xs),
            Icon(
              LucideIcons.chevronRight,
              color: scheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small shimmering placeholder that stands in for the user's name while
/// authentication is still loading. Sized to roughly match one line of the
/// app-bar title text, with a subtly animated highlight sweeping across a
/// muted rounded fill.
class _HeaderNameSkeleton extends StatefulWidget {
  const _HeaderNameSkeleton();

  @override
  State<_HeaderNameSkeleton> createState() => _HeaderNameSkeletonState();
}

class _HeaderNameSkeletonState extends State<_HeaderNameSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;

    // Match the placeholder height to the current app-bar text line so the
    // box sits on the baseline like real text would.
    final textStyle = DefaultTextStyle.of(context).style;
    final fontSize = textStyle.fontSize ?? 20;
    final height = fontSize * 0.9;

    final base = scheme.onSurfaceVariant.withValues(alpha: 0.18);
    final highlight = scheme.onSurfaceVariant.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sweep the highlight band from left to right across the box.
        final t = _controller.value;
        return Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            borderRadius: tokens.radii.smRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * t - 0.6, 0),
              end: Alignment(-1.0 + 2.0 * t + 0.6, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Protection status
// ---------------------------------------------------------------------------

/// What the status card tells the user, derived from the saved toggle and
/// the live background-service status.
enum _ProtectionState { loading, off, starting, on, problem }

_ProtectionState _deriveProtectionState({
  required bool enabled,
  required ServiceStatus status,
}) {
  if (!enabled) return _ProtectionState.off;
  if (status.modelError) return _ProtectionState.problem;
  // The model loads into memory lazily on the first message and is released
  // again after an idle period, so [modelReady] drops back to false during
  // normal operation. As long as the weights are on disk (or already loaded)
  // and nothing has errored, protection is up and working — only treat it as
  // "getting ready" when the model has yet to be downloaded.
  if (status.modelReady || status.modelInstalled) return _ProtectionState.on;
  return _ProtectionState.starting;
}

/// The first thing on the home page: a big, colour-coded card saying whether
/// Scam Shield is protecting the user right now. Polls the same sources as
/// the Safety screen, but only reads — turning protection on or off stays on
/// the Safety tab, which [onOpen] switches to.
class _ProtectionStatusCard extends StatefulWidget {
  const _ProtectionStatusCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  State<_ProtectionStatusCard> createState() => _ProtectionStatusCardState();
}

class _ProtectionStatusCardState extends State<_ProtectionStatusCard> {
  static const Duration _pollInterval = Duration(seconds: 3);

  final ProtectionSettings _settings = ProtectionSettings();
  Timer? _poll;

  bool _loaded = false;
  bool _enabled = false;
  ServiceStatus _status = ServiceStatus.idle;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    var enabled = _enabled;
    var status = _status;
    try {
      enabled = await _settings.protectionEnabled();
    } catch (_) {}
    try {
      status = await ScamShieldController.status();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _enabled = enabled;
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final risk = tokens.risk;

    final state = _loaded
        ? _deriveProtectionState(enabled: _enabled, status: _status)
        : _ProtectionState.loading;

    // Every state sits on the standard card surface (white in light mode, the
    // dark card in dark mode) so the card matches the rest of the app. The
    // state colour is carried only by the badge, the pill stats, and the
    // action button.
    final foreground = scheme.onSurface;

    final Color accent;
    final IconData icon;
    final String title;
    final String body;
    switch (state) {
      case _ProtectionState.loading:
      case _ProtectionState.starting:
        accent = scheme.primary;
        icon = LucideIcons.shield;
        title = l10n.homeStatusStartingTitle;
        body = l10n.homeStatusStartingBody;
      case _ProtectionState.on:
        accent = risk.safe;
        icon = LucideIcons.shieldCheck;
        title = l10n.safetyProtectedOn;
        body = l10n.homeStatusOnBody;
      case _ProtectionState.off:
        // "Off" is not an alarm: the user just hasn't switched protection on
        // yet, so the badge and button use the brand primary.
        accent = scheme.primary;
        icon = LucideIcons.shieldOff;
        title = l10n.safetyProtectedOff;
        body = l10n.homeStatusOffBody;
      case _ProtectionState.problem:
        accent = risk.danger;
        icon = LucideIcons.shieldAlert;
        title = l10n.homeStatusProblemTitle;
        body = l10n.homeStatusProblemBody;
    }

    // Stat panels. Light mode's token containers are very pale, so they barely
    // separate from the white card; deepen the tint there. Dark mode keeps the
    // token container, which already reads against the dark card.
    Color panelFill(Color accent, Color container) =>
        theme.brightness == Brightness.light
        ? Color.alphaBlend(accent.withValues(alpha: 0.16), container)
        : container;

    // Anything raised is worth a second look, so the alerts panel turns red as
    // soon as its count leaves zero.
    final hasAlerts = _status.alertsRaised > 0;
    final alertsAccent = hasAlerts ? risk.danger : risk.safe;
    final alertsContainer = hasAlerts
        ? risk.dangerContainer
        : risk.safeContainer;
    final alertsForeground = hasAlerts
        ? risk.onDangerContainer
        : risk.onSafeContainer;

    return AppCard(
      raised: true,
      onTap: widget.onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: _StatusBadge(
                  icon: icon,
                  accent: accent,
                  busy: state == _ProtectionState.loading ||
                      state == _ProtectionState.starting,
                ),
              ),
              SizedBox(width: tokens.space.lg),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: foreground,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: tokens.space.xs),
                      Text(
                        body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: foreground.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (state == _ProtectionState.on) ...[
            SizedBox(height: tokens.space.xl),
            Row(
              children: [
                Expanded(
                  child: _StatusStat(
                    icon: LucideIcons.messageSquareText,
                    value: '${_status.evaluated}',
                    label: l10n.protectionChecked,
                    background: panelFill(risk.safe, risk.safeContainer),
                    foreground: risk.onSafeContainer,
                  ),
                ),
                SizedBox(width: tokens.space.md),
                Expanded(
                  child: _StatusStat(
                    icon: LucideIcons.triangleAlert,
                    value: '${_status.alertsRaised}',
                    label: l10n.protectionAlerts,
                    background: panelFill(alertsAccent, alertsContainer),
                    foreground: alertsForeground,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: tokens.space.xl),
          _StatusButton(
            state: state,
            accent: accent,
            onPressed: widget.onOpen,
          ),
        ],
      ),
    );
  }
}

/// The round shield badge at the start of the status card: a flat, tinted
/// circle with no glow, plus a thin ring spinner while starting.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.accent,
    required this.busy,
  });

  final IconData icon;
  final Color accent;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 38, color: accent),
    );

    if (!busy) return badge;
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          badge,
          CircularProgressIndicator(strokeWidth: 3, color: accent),
        ],
      ),
    );
  }
}

/// One number on the status card ("Checked 42", "Alerts 3"). The value is
/// the biggest thing so it reads before the label. Sits in a soft tinted
/// panel so it reads as a distinct block on the standard card surface in both
/// light and dark mode.
class _StatusStat extends StatelessWidget {
  const _StatusStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space.lg,
            vertical: tokens.space.md,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: tokens.radii.mdRadius,
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: foreground),
              SizedBox(width: tokens.space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: foreground,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The single, full-width action on the status card. Filled (strong) when
/// the user needs to act; outlined (calm) when everything is fine.
class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.state,
    required this.accent,
    required this.onPressed,
  });

  final _ProtectionState state;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final risk = context.tokens.risk;
    final labelStyle = theme.textTheme.titleLarge;
    const size = Size.fromHeight(60);

    switch (state) {
      case _ProtectionState.off:
      case _ProtectionState.problem:
        final isOff = state == _ProtectionState.off;
        final foreground = isOff ? scheme.onPrimary : Colors.white;
        // Dark mode's danger token is a light salmon meant for text and icons;
        // as a full button fill it glares against the dark card. Pull it 35%
        // toward the deep danger container for a solid red that still reads as
        // "danger". Light mode's danger token is already dark enough to fill.
        final fill = isOff || theme.brightness == Brightness.light
            ? accent
            : Color.lerp(risk.danger, risk.dangerContainer, 0.40)!;
        return FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: size,
            backgroundColor: fill,
            foregroundColor: foreground,
          ),
          icon: Icon(
            isOff ? LucideIcons.shieldCheck : LucideIcons.wrench,
            size: 24,
          ),
          // The label style carries its own colour, so it must be told to
          // follow the button's foreground rather than the body text colour.
          label: Text(
            isOff ? l10n.safetyTurnOn : l10n.homeStatusFix,
            style: labelStyle?.copyWith(color: foreground),
          ),
        );
      case _ProtectionState.loading:
      case _ProtectionState.starting:
      case _ProtectionState.on:
        return OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: size,
            foregroundColor: accent,
            side: BorderSide(color: accent.withValues(alpha: 0.6), width: 1.5),
          ),
          icon: const Icon(LucideIcons.arrowRight, size: 24),
          label: Text(l10n.homeStatusOpen, style: labelStyle),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Scam alerts & news
// ---------------------------------------------------------------------------

/// Height of a news card in the carousel. Fits a two-line title and a
/// three-line preview at elderly-friendly sizes.
const double _kNewsCardHeight = 300;

/// A swipeable set of scam-alert cards. Fetches articles from [NewsService]
/// and shows loading, error-with-retry, and empty states. Big previous/next
/// buttons sit under the cards for anyone who finds swiping awkward.
class _NewsBanner extends StatefulWidget {
  const _NewsBanner();

  @override
  State<_NewsBanner> createState() => _NewsBannerState();
}

class _NewsBannerState extends State<_NewsBanner> {
  final PageController _controller = PageController();

  late final NewsService _service;

  late Future<List<NewsArticle>> _future;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _service = NewsService(context.read<ApiClient>());
    _future = _service.fetchNews();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _page = 0;
      _future = _service.fetchNews();
    });
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FutureBuilder<List<NewsArticle>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final articles = snapshot.data ?? const <NewsArticle>[];

        // Nothing to say and nothing went wrong: hide the whole section.
        if (!loading && !snapshot.hasError && articles.isEmpty) {
          return const SizedBox.shrink();
        }

        final page =
            articles.isEmpty ? 0 : _page.clamp(0, articles.length - 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: LucideIcons.newspaper,
              title: l10n.homeNewsTitle,
              trailing: articles.length > 1
                  ? Text(
                      l10n.homeNewsCount(page + 1, articles.length),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: tokens.space.lg),
            if (loading)
              const _NewsLoading()
            else if (snapshot.hasError)
              _NewsError(onRetry: _reload)
            else
              _buildCarousel(context, articles, page),
          ],
        );
      },
    );
  }

  Widget _buildCarousel(
    BuildContext context,
    List<NewsArticle> articles,
    int page,
  ) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final multiple = articles.length > 1;

    return Column(
      children: [
        SizedBox(
          height: _kNewsCardHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: articles.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final article = articles[i];
              final icon = newsIconFor(article.icon);
              final title = article.localizedTitle(locale);
              final body = article.localizedBody(locale);
              return Padding(
                // A small gutter so neighbouring cards don't touch mid-swipe.
                padding: EdgeInsets.symmetric(horizontal: tokens.space.xs),
                child: _NewsCard(
                  icon: icon,
                  title: title,
                  body: body,
                  onTap: () => _showArticle(
                    context,
                    icon: icon,
                    title: title,
                    body: body,
                  ),
                ),
              );
            },
          ),
        ),
        if (multiple) ...[
          SizedBox(height: tokens.space.lg),
          Row(
            children: [
              _CarouselArrow(
                icon: LucideIcons.chevronLeft,
                tooltip: l10n.homeNewsPrevious,
                onPressed: page > 0 ? () => _goTo(page - 1) : null,
              ),
              Expanded(
                child: ExcludeSemantics(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < articles.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(
                            horizontal: tokens.space.xs,
                          ),
                          width: i == page ? 28 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: i == page
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.2),
                            borderRadius: tokens.radii.pillRadius,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _CarouselArrow(
                icon: LucideIcons.chevronRight,
                tooltip: l10n.homeNewsNext,
                onPressed: page < articles.length - 1
                    ? () => _goTo(page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Opens the full article in a bottom sheet with large text and one big
  /// close button, so long alerts never need squinting at a truncated card.
  void _showArticle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _NewsArticleSheet(
        icon: icon,
        title: title,
        body: body,
      ),
    );
  }
}

/// A 56px round arrow button under the carousel. Disabled at either end.
class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 28,
      style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
      icon: Icon(icon),
    );
  }
}

/// Maps a backend icon key (snake_case) to a Lucide glyph. Falls back to a
/// generic newspaper icon for anything unrecognised, so a new backend icon
/// never crashes the UI.
IconData newsIconFor(String key) {
  switch (key) {
    case 'message_square_warning':
      return LucideIcons.messageSquareWarning;
    case 'package':
      return LucideIcons.package;
    case 'phone_call':
      return LucideIcons.phoneCall;
    case 'shield':
      return LucideIcons.shield;
    case 'triangle_alert':
      return LucideIcons.triangleAlert;
    case 'credit_card':
      return LucideIcons.creditCard;
    default:
      return LucideIcons.newspaper;
  }
}

/// Loading placeholder sized to match a news card so the layout doesn't jump.
class _NewsLoading extends StatelessWidget {
  const _NewsLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: _kNewsCardHeight,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: tokens.radii.xlRadius,
      ),
      alignment: Alignment.center,
      child: CircularProgressIndicator(color: scheme.primary),
    );
  }
}

/// Shown when the fetch fails. Keeps the large-tap-target style and offers a
/// single clear retry.
class _NewsError extends StatelessWidget {
  const _NewsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.wifiOff,
                size: 30,
                color: scheme.onSurfaceVariant,
              ),
              SizedBox(width: tokens.space.lg),
              Expanded(
                child: Text(
                  l10n.homeNewsError,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space.lg),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 22),
            label: Text(
              l10n.homeNewsRetry,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// One alert in the carousel: icon badge and bold title on top, a short
/// preview, and a clear "Read more" cue. The whole card is tappable.
class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onColor = scheme.onPrimaryContainer;

    return Semantics(
      button: true,
      label: '$title. ${l10n.homeNewsReadMore}',
      child: ExcludeSemantics(
        child: AppCard(
          color: scheme.primaryContainer,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: onColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 30, color: onColor),
                  ),
                  SizedBox(width: tokens.space.lg),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: onColor,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.space.md),
              Expanded(
                child: Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: onColor.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    l10n.homeNewsReadMore,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(width: tokens.space.sm),
                  Icon(LucideIcons.arrowRight, size: 22, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full article, shown in a bottom sheet. Scrolls if long; the close
/// button always stays visible at the bottom.
class _NewsArticleSheet extends StatelessWidget {
  const _NewsArticleSheet({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.space.xl,
          0,
          tokens.space.xl,
          tokens.space.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 34, color: scheme.primary),
                    ),
                    SizedBox(height: tokens.space.lg),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: tokens.space.lg),
                    Text(
                      body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: scheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.space.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              child: Text(
                l10n.homeNewsClose,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

/// A section heading: tinted icon, bold title, optional trailing widget.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: 26, color: scheme.primary),
          SizedBox(width: tokens.space.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: tokens.space.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Large tappable feature cards. Each routes to a bottom-nav tab via
/// [onNavigate]. Protection isn't listed: the status card above covers it.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;

    final actions = <_QuickAction>[
      _QuickAction(
        icon: LucideIcons.megaphone,
        title: l10n.homeActionReport,
        body: l10n.homeActionReportBody,
        tabIndex: _kReportTab,
      ),
      _QuickAction(
        icon: LucideIcons.phone,
        title: l10n.homeActionCalls,
        body: l10n.homeActionCallsBody,
        tabIndex: _kCallsTab,
      ),
      _QuickAction(
        icon: LucideIcons.circleUserRound,
        title: l10n.homeActionProfile,
        body: l10n.homeActionProfileBody,
        tabIndex: _kProfileTab,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          icon: LucideIcons.layoutGrid,
          title: l10n.homeQuickActionsTitle,
        ),
        SizedBox(height: tokens.space.lg),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) SizedBox(height: tokens.space.md),
          _QuickActionCard(
            action: actions[i],
            onTap: () => onNavigate(actions[i].tabIndex),
          ),
        ],
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.body,
    required this.tabIndex,
  });

  final IconData icon;
  final String title;
  final String body;
  final int tabIndex;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.onTap});

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '${action.title}. ${action.body}',
      child: ExcludeSemantics(
        child: AppCard(
          onTap: onTap,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space.xl,
            vertical: tokens.space.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, size: 32, color: scheme.primary),
              ),
              SizedBox(width: tokens.space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: theme.textTheme.titleLarge,
                    ),
                    SizedBox(height: tokens.space.xs),
                    Text(
                      action.body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: tokens.space.sm),
              Icon(
                LucideIcons.chevronRight,
                size: 28,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
