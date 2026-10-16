import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/api/api_client.dart';
import 'package:scamwatch_mobile_app/api/api_exception.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/models/api/auth_models.dart';
import 'package:scamwatch_mobile_app/models/api/community_models.dart';
import 'package:scamwatch_mobile_app/screens/community/post_detail_screen.dart';
import 'package:scamwatch_mobile_app/screens/settings/settings_page.dart';
import 'package:scamwatch_mobile_app/services/api/community_service.dart';
import 'package:scamwatch_mobile_app/state/auth_controller.dart';
import 'package:scamwatch_mobile_app/state/posts_refresh_signal.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/auth/require_login.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_card.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';
import 'package:scamwatch_mobile_app/widgets/ui/empty_state.dart';

/// Signed-in user's profile. Lives in the bottom navigation bar and folds in
/// the old "My posts" and "Settings" entries.
///
/// The screen is split in two: a compact header with the user's details (small
/// initials avatar, name, email, post count, member-since), and a lower section
/// that lists the user's own posts. Settings and sign-out live as actions on
/// the app bar. The screen leans elderly-friendly: big text, generous spacing,
/// and large tap targets.
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late final CommunityService _community = CommunityService(widget.client);

  bool _loading = true;
  String? _error;
  List<FeedPost> _posts = const [];

  /// First-image preview URL per post id, for the small thumbnail on each card.
  /// Only populated for the few newest posts (see [_kPreviewCount]) because the
  /// `/me/posts` list response carries no image URLs — we fetch each post's
  /// detail to learn its images, which is costly, so we cap it.
  Map<String, String> _previewUrls = const {};

  /// Auth headers for loading owner-only redacted post images via
  /// `Image.network`. Fetched alongside the previews.
  Map<String, String> _imageHeaders = const {};

  /// Tags per post id, sourced from the fetched post detail for the newest
  /// posts. The `/me/posts` list response often omits tags, so we take them
  /// from the same detail fetch that powers the image previews.
  Map<String, List<ScamTag>> _postTags = const {};

  /// How many of the newest posts get a thumbnail preview.
  static const int _kPreviewCount = 3;

  /// Post IDs with a vote request in flight. Used to disable that card's vote
  /// buttons so a double-tap can't fire two reaction calls at once.
  final Set<String> _votingPostIds = <String>{};

  /// The posts list is fetched once in [initState], then only reloaded when a
  /// post is made (via [PostsRefreshSignal]) or the user pulls to refresh. We
  /// track the signal and the revision we last handled so a new post triggers
  /// exactly one reload.
  PostsRefreshSignal? _postsSignal;
  int _handledRevision = 0;

  @override
  void initState() {
    super.initState();
    // Initial open: load the list and the newest previews.
    _load(fetchPreviews: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = context.read<PostsRefreshSignal>();
    if (!identical(signal, _postsSignal)) {
      _postsSignal?.removeListener(_onPostsSignal);
      _postsSignal = signal;
      _handledRevision = signal.revision;
      signal.addListener(_onPostsSignal);
    }
  }

  @override
  void dispose() {
    _postsSignal?.removeListener(_onPostsSignal);
    super.dispose();
  }

  void _onPostsSignal() {
    final signal = _postsSignal;
    if (signal == null) return;
    // Coalesce rapid signals: only reload if the revision advanced past the
    // last one we handled.
    if (signal.revision == _handledRevision) return;
    _handledRevision = signal.revision;
    _load();
  }

  /// Loads the posts list. When [fetchPreviews] is true, also fetches the
  /// newest few posts' detail to learn their first image and show an 86px
  /// thumbnail on the card. The `/me/posts` list carries no image URLs, so
  /// previews cost one detail request per post — we only pay that on initial
  /// open and pull-to-refresh, and only for the [_kPreviewCount] newest posts.
  Future<void> _load({bool fetchPreviews = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _community.myPosts();
      if (!mounted) return;
      setState(() {
        _posts = page.items;
        _loading = false;
      });
      if (fetchPreviews) {
        await _loadPreviews(page.items);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// Fetches the first-image preview and tags for the newest [_kPreviewCount]
  /// posts, plus the auth headers needed to load those owner-only images. The
  /// `/me/posts` list carries no image URLs and often omits tags, so we read
  /// both from each post's detail. Posts without an image simply get no preview
  /// entry. Failures per post are ignored so one bad post never blocks the rest.
  Future<void> _loadPreviews(List<FeedPost> posts) async {
    final newest = posts.take(_kPreviewCount).toList(growable: false);
    if (newest.isEmpty) return;
    final headers = await widget.client.authHeaders();
    final previews = <String, String>{};
    final tags = <String, List<ScamTag>>{};
    for (final post in newest) {
      try {
        final detail = await _community.post(post.postId);
        if (detail.imageUrls.isNotEmpty) {
          previews[post.postId] = detail.imageUrls.first;
        }
        if (detail.tags.isNotEmpty) {
          tags[post.postId] = detail.tags;
        }
      } on ApiException {
        // Ignore: a post whose detail fails just shows no thumbnail or tags.
      }
    }
    if (!mounted) return;
    setState(() {
      _previewUrls = previews;
      _imageHeaders = headers;
      _postTags = tags;
    });
  }

  /// Tags to show on a post card. Prefers the tags the list endpoint returned,
  /// falling back to the detail-fetched tags for the newest posts (the
  /// `/me/posts` list often omits tags, so the detail fetch is the reliable
  /// source for the few cards that have a preview).
  List<ScamTag> _tagsFor(FeedPost post) {
    if (post.tags.isNotEmpty) return post.tags;
    return _postTags[post.postId] ?? const [];
  }

  Future<void> _openPost(FeedPost post) async {
    // Just view the post; returning from the detail screen does not refetch the
    // list. "My posts" only reloads when a post is made or the user asks for it
    // (pull-to-refresh), per the one-fetch-on-open behavior.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PostDetailScreen(client: widget.client, postId: post.postId),
      ),
    );
  }

  Future<void> _deletePost(FeedPost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.myPostsDeleteConfirm),
        content: Text(l10n.myPostsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel, style: const TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.myPostsDelete,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _community.deletePost(post.postId);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Casts (or clears) the caller's vote on [post] and updates just that card
  /// in place. Tapping the vote you already hold clears it; any other tap sets
  /// the new vote. Mirrors the post-detail behavior so the two stay consistent.
  Future<void> _vote(FeedPost post, int vote) async {
    if (_votingPostIds.contains(post.postId)) return;
    setState(() => _votingPostIds.add(post.postId));
    try {
      final result = post.myVote == vote
          ? await _community.clearReaction(post.postId)
          : await _community.setReaction(postId: post.postId, vote: vote);
      if (!mounted) return;
      setState(() {
        _posts = [
          for (final p in _posts)
            if (p.postId == post.postId)
              p.copyWithVote(
                reactions: PostReactions(up: result.upCount, down: result.downCount),
                myVote: result.myVote,
              )
            else
              p,
        ];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _votingPostIds.remove(post.postId));
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.user;

    // Signed-out fallback. The nav normally routes signed-out users to login,
    // but guard here too so the screen never looks broken.
    if (!auth.isSignedIn || user == null) {
      return AppScreen(
        title: l10n.myProfileTitle,
        scrollable: false,
        actions: [_SettingsAction(onPressed: _openSettings)],
        body: EmptyState(
          icon: LucideIcons.circleUserRound,
          title: l10n.myProfileNotSignedInTitle,
          message: l10n.myProfileNotSignedInBody,
          action: FilledButton.icon(
            onPressed: () => requireLogin(context),
            icon: const Icon(LucideIcons.logIn),
            label: Text(l10n.myProfileSignIn),
          ),
        ),
      );
    }

    return AppScreen(
      title: l10n.myProfileTitle,
      scrollable: false,
      actions: [
        _SettingsAction(onPressed: _openSettings),
        _LogOutAction(onPressed: () => context.read<AuthController>().logout()),
      ],
      body: RefreshIndicator(
        // Pull-to-refresh is user-triggered, so refresh the newest previews too.
        onRefresh: () => _load(fetchPreviews: true),
        child: _buildBody(l10n, user),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, AuthUser user) {
    final tokens = context.tokens;
    return ListView(
      padding: EdgeInsets.only(
        top: tokens.space.sm,
        bottom: tokens.space.xl2,
      ),
      children: [
        _ProfileHeader(user: user, postCount: _posts.length),
        SizedBox(height: tokens.space.xl2),
        const _PostsSectionHeader(),
        SizedBox(height: tokens.space.md),
        ..._buildPosts(l10n),
      ],
    );
  }

  List<Widget> _buildPosts(AppLocalizations l10n) {
    final tokens = context.tokens;
    if (_loading && _posts.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.space.xl2),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    return [
      if (_error != null) ...[
        _errorCard(),
        SizedBox(height: tokens.space.md),
      ],
      if (_posts.isEmpty && _error == null) _emptyCard(l10n),
      for (var index = 0; index < _posts.length; index++) ...[
        if (index > 0) SizedBox(height: tokens.space.md),
        _postCard(l10n, _posts[index]),
      ],
    ];
  }

  Widget _postCard(AppLocalizations l10n, FeedPost post) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return AppCard(
      onTap: () => _openPost(post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (post.isReviewed) ...[
                SizedBox(width: tokens.space.sm),
                _reviewedBadge(l10n),
              ],
            ],
          ),
          if (_tagsFor(post).isNotEmpty) ...[
            SizedBox(height: tokens.space.xs),
            _PostTagChips(tags: _tagsFor(post)),
          ],
          if (_previewUrls[post.postId] != null) ...[
            SizedBox(height: tokens.space.sm),
            _PostThumbnail(
              url: _previewUrls[post.postId]!,
              headers: _imageHeaders,
            ),
          ],
          SizedBox(height: tokens.space.sm),
          Text(
            post.redactedExcerpt,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: tokens.space.md),
          Row(
            children: [
              _voteButton(
                theme,
                icon: LucideIcons.thumbsUp,
                label: '${post.reactions.up}',
                active: post.myVote == 1,
                onTap: () => _vote(post, 1),
                enabled: !_votingPostIds.contains(post.postId),
              ),
              SizedBox(width: tokens.space.sm),
              _voteButton(
                theme,
                icon: LucideIcons.thumbsDown,
                label: '${post.reactions.down}',
                active: post.myVote == -1,
                onTap: () => _vote(post, -1),
                enabled: !_votingPostIds.contains(post.postId),
              ),
              SizedBox(width: tokens.space.lg),
              Icon(
                LucideIcons.messageCircle,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: tokens.space.xs),
              Text(
                '${post.commentCount}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _deletePost(post),
                icon: const Icon(LucideIcons.trash2, size: 20),
                label: Text(l10n.myPostsDelete),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.space.md,
                    vertical: tokens.space.sm,
                  ),
                  textStyle: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact upvote/downvote control for a post card. Highlights with the
  /// primary color when it's the caller's current vote; disabled while a
  /// reaction request for this post is in flight.
  Widget _voteButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final scheme = theme.colorScheme;
    final Color foreground = active ? scheme.primary : scheme.onSurfaceVariant;
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.symmetric(
          horizontal: context.tokens.space.md,
          vertical: context.tokens.space.sm,
        ),
        backgroundColor:
            active ? scheme.primary.withValues(alpha: 0.12) : null,
        foregroundColor: foreground,
        side: BorderSide(
          color: active ? scheme.primary : scheme.outlineVariant,
        ),
      ),
    );
  }

  Widget _reviewedBadge(AppLocalizations l10n) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.sm,
        vertical: tokens.space.xs,
      ),
      decoration: BoxDecoration(
        color: tokens.risk.safeContainer,
        borderRadius: tokens.radii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.badgeCheck, size: 18, color: tokens.risk.safe),
          SizedBox(width: tokens.space.xs),
          Text(
            l10n.commonReviewed,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: tokens.risk.onSafeContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(AppLocalizations l10n) {
    return AppCard(
      child: EmptyState(
        icon: LucideIcons.messageSquarePlus,
        title: l10n.commonNoPostsYet,
        message: l10n.myPostsNoneBody,
      ),
    );
  }

  Widget _errorCard() {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return AppCard(
      color: tokens.risk.dangerContainer,
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, color: tokens.risk.danger),
          SizedBox(width: tokens.space.md),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: tokens.risk.onDangerContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small 86px rounded preview of a post's first redacted image, shown on the
/// "My posts" card. Falls back to nothing visible on error (the parent only
/// renders this when a preview URL exists, but the image fetch can still fail).
/// Small pill chips for a post's scam tags, shown beneath the title on each
/// "My posts" card. Renders nothing when the post has no tags.
class _PostTagChips extends StatelessWidget {
  const _PostTagChips({required this.tags});

  final List<ScamTag> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    return Wrap(
      spacing: tokens.space.xs,
      runSpacing: tokens.space.xs,
      children: [
        for (final tag in tags)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space.sm,
              vertical: tokens.space.xs,
            ),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: tokens.radii.pillRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.tag, size: 14, color: scheme.primary),
                SizedBox(width: tokens.space.xs),
                Text(
                  tag.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PostThumbnail extends StatelessWidget {
  const _PostThumbnail({required this.url, required this.headers});

  final String url;
  final Map<String, String> headers;

  static const double _size = 86;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: context.tokens.radii.mdRadius,
      child: Image.network(
        url,
        headers: headers.isEmpty ? null : headers,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: _size,
            height: _size,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: _size,
          height: _size,
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.imageOff,
            size: 28,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// App-bar action: open settings.
class _SettingsAction extends StatelessWidget {
  const _SettingsAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(LucideIcons.settings, size: 26),
      iconSize: 26,
      tooltip: l10n.settingsScreenTitle,
    );
  }
}

/// App-bar action: sign out.
class _LogOutAction extends StatelessWidget {
  const _LogOutAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(LucideIcons.logOut, size: 22),
        label: Text(
          l10n.myProfileSignOut,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: TextButton.styleFrom(
          foregroundColor: scheme.error,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

/// Compact header: small tinted initials avatar, name, email, and two
/// at-a-glance stats (post count and member-since). No photo upload, so
/// initials stand in for a picture.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.postCount});

  final AuthUser user;
  final int postCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = user.displayName.trim();
    final initials = _initialsFor(name, user.email);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: tokens.space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : user.email,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (name.isNotEmpty) ...[
                      SizedBox(height: tokens.space.xs),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 17,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space.lg),
          const Divider(height: 1),
          SizedBox(height: tokens.space.lg),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: LucideIcons.fileText,
                  value: '$postCount',
                  label: AppLocalizations.of(context).myProfilePosts,
                ),
              ),
              if (user.createdAt != null)
                Expanded(
                  child: _StatTile(
                    icon: LucideIcons.calendar,
                    value: _formatMemberSince(context, user.createdAt!),
                    label: AppLocalizations.of(context).myProfileMemberSince,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single at-a-glance stat: big value on top, muted label below.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: scheme.primary),
        SizedBox(height: tokens.space.xs),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.space.xs),
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Section title above the posts list.
class _PostsSectionHeader extends StatelessWidget {
  const _PostsSectionHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(left: tokens.space.xs),
      child: Text(
        l10n.myPostsTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatMemberSince(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return intl.DateFormat.yMMM(locale).format(date.toLocal());
}

String _initialsFor(String name, String email) {
  final source = name.isNotEmpty ? name : email;
  final parts = source
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return p.characters.take(2).toString().toUpperCase();
  }
  final first = parts.first.characters.first;
  final last = parts.last.characters.first;
  return '$first$last'.toUpperCase();
}
