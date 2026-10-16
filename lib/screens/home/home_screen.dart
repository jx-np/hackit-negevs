import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/models/api/news_models.dart';
import 'package:scamwatch_mobile_app/screens/profile/my_profile_screen.dart';
import 'package:scamwatch_mobile_app/services/api/news_service.dart';
import 'package:scamwatch_mobile_app/state/auth_controller.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/auth/require_login.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_card.dart';

/// The app's landing screen, designed for older users: a large, friendly
/// greeting, a prominent news/alerts banner across the top, and big tappable
/// cards that lead to the main features.
///
/// Quick actions don't navigate themselves — they call [onNavigate] with the
/// destination bottom-nav tab index so the shell ([HomePage]) stays the single
/// owner of tab selection.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Switches the app to the given bottom-nav tab index.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HomeHeader(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.space.lg),
                child: const _NewsBanner(),
              ),
              SizedBox(height: tokens.space.xl2),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.space.lg),
                child: _QuickActions(onNavigate: onNavigate),
              ),
              SizedBox(height: tokens.space.xl2),
            ],
          ),
        ),
      ),
    );
  }
}

/// The greeting at the very top. One compact, tappable line:
/// "Welcome, {name}" when signed in (taps through to My Profile), or
/// "Welcome, not signed in" when signed out (taps through to the login flow).
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final auth = context.watch<AuthController>();
    final isSignedIn = auth.isSignedIn;
    final name = auth.user?.displayName.trim() ?? '';
    final hasName = isSignedIn && name.isNotEmpty;

    // Who the greeting names, and where tapping it leads.
    final who = hasName ? name : l10n.homeWelcomeGuestLabel;
    final whoColor = hasName ? scheme.primary : scheme.onSurfaceVariant;

    Future<void> onTap() async {
      if (isSignedIn) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MyProfileScreen(),
          ),
        );
      } else {
        await requireLogin(context);
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space.lg,
        tokens.space.lg,
        tokens.space.lg,
        tokens.space.xl,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: tokens.radii.mdRadius,
        child: Padding(
          padding: EdgeInsets.all(tokens.space.sm),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(text: l10n.homeWelcomePrefix),
                      TextSpan(
                        text: who,
                        style: TextStyle(color: whoColor),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: tokens.space.sm),
              Icon(
                LucideIcons.chevronRight,
                color: scheme.onSurfaceVariant,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontally swipeable set of scam-alert cards across the top of the home
/// page. Fetches articles from [NewsService] (currently backed by sample data)
/// and shows loading, error-with-retry, and empty states.
class _NewsBanner extends StatefulWidget {
  const _NewsBanner();

  @override
  State<_NewsBanner> createState() => _NewsBannerState();
}

class _NewsBannerState extends State<_NewsBanner> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  final NewsService _service = NewsService();

  late Future<List<NewsArticle>> _future;
  int _page = 0;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.newspaper, size: 26, color: scheme.primary),
            SizedBox(width: tokens.space.sm),
            Text(
              l10n.homeNewsTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.space.md),
        FutureBuilder<List<NewsArticle>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _NewsLoading();
            }
            if (snapshot.hasError) {
              return _NewsError(onRetry: _reload);
            }
            final articles = snapshot.data ?? const <NewsArticle>[];
            if (articles.isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildCarousel(context, articles);
          },
        ),
      ],
    );
  }

  Widget _buildCarousel(BuildContext context, List<NewsArticle> articles) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Clamp the active page if the list shrank between loads.
    final page = _page.clamp(0, articles.length - 1);

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _controller,
            itemCount: articles.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final article = articles[i];
              return Padding(
                padding: EdgeInsets.only(right: tokens.space.md),
                child: _NewsCard(
                  icon: newsIconFor(article.icon),
                  title: article.localizedTitle(locale),
                  body: article.localizedBody(locale),
                ),
              );
            },
          ),
        ),
        SizedBox(height: tokens.space.md),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < articles.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: tokens.space.xs),
                  width: i == page ? 24 : 8,
                  height: 8,
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
      ],
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 260,
      child: Center(
        child: CircularProgressIndicator(color: scheme.primary),
      ),
    );
  }
}

/// Shown when the fetch fails. Keeps the elderly-friendly large-tap-target
/// style and offers a single clear retry.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.wifiOff,
                size: 28,
                color: scheme.onSurfaceVariant,
              ),
              SizedBox(width: tokens.space.md),
              Expanded(
                child: Text(
                  l10n.homeNewsError,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 20),
              label: Text(l10n.homeNewsRetry),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      color: scheme.primaryContainer,
      padding: EdgeInsets.all(tokens.space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The icon sits inline at the start of the title so the text runs
          // right after it and wraps underneath — no wasted column of space
          // beside a lone glyph.
          Text.rich(
            TextSpan(
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
                height: 1.25,
              ),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(right: tokens.space.sm),
                    child: Icon(
                      icon,
                      size: 30,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                TextSpan(text: title),
              ],
            ),
          ),
          SizedBox(height: tokens.space.sm),
          Expanded(
            child: Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
                height: 1.35,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large tappable feature cards. Each routes to a bottom-nav tab via
/// [onNavigate]. Sized and spaced generously for easy reading and tapping.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final actions = <_QuickAction>[
      _QuickAction(
        icon: LucideIcons.shield,
        title: l10n.homeActionSafety,
        body: l10n.homeActionSafetyBody,
        tabIndex: 2,
      ),
      _QuickAction(
        icon: LucideIcons.phone,
        title: l10n.homeActionCalls,
        body: l10n.homeActionCallsBody,
        tabIndex: 1,
      ),
      _QuickAction(
        icon: LucideIcons.megaphone,
        title: l10n.homeActionReport,
        body: l10n.homeActionReportBody,
        tabIndex: 3,
      ),
      _QuickAction(
        icon: LucideIcons.fileText,
        title: l10n.homeActionMyPosts,
        body: l10n.homeActionMyPostsBody,
        tabIndex: 4,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeQuickActionsTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
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

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(action.icon, size: 34, color: scheme.primary),
          ),
          SizedBox(width: tokens.space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.space.xs),
                Text(
                  action.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 28,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
